/**
 * Creator invite-code system (SP-E). Server-authoritative: clients have NO
 * access to creator_invite_codes; every code is generated here and redeemed
 * here. Verification (claim + profile) is always checked server-side.
 */
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { randomInt } from "node:crypto";
import * as admin from "firebase-admin";

if (admin.apps.length === 0) {
  admin.initializeApp();
}

const db = admin.firestore();

export const CODE_CHARS = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"; // no 0/O/1/I/L
export const CODE_LENGTH = 8;
export const CODE_TTL_MS = 7 * 24 * 60 * 60 * 1000; // 7 days
export const MAX_OUTSTANDING_CODES = 10;
export const CODE_PATTERN = /^[A-Z2-9]{8}$/;

export async function isVerifiedCreator(uid: string): Promise<boolean> {
  const [userRecord, profile] = await Promise.all([
    admin.auth().getUser(uid),
    db.collection("creator_profiles").doc(uid).get(),
  ]);
  const claims = userRecord.customClaims ?? {};
  return (
    claims.role === "creator" &&
    profile.exists &&
    profile.data()?.isVerifiedCreator === true
  );
}

export function generateCode(): string {
  let code = "";
  for (let i = 0; i < CODE_LENGTH; i++) {
    code += CODE_CHARS[randomInt(CODE_CHARS.length)];
  }
  return code;
}

export const generateCreatorInviteCode = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be logged in.");
  }
  const uid = request.auth.uid;
  if (!(await isVerifiedCreator(uid))) {
    throw new HttpsError(
      "permission-denied",
      "Only verified creators can generate invite codes."
    );
  }

  // Outstanding count: query by creatorUid (Firestore cannot filter
  // `== null`), filter redeemedBy in memory. Redeemed codes are deleted,
  // so in practice every doc under creatorUid is outstanding.
  const snapshot = await db
    .collection("creator_invite_codes")
    .where("creatorUid", "==", uid)
    .get();
  let outstanding = 0;
  snapshot.forEach((doc) => {
    if (doc.data().redeemedBy == null) outstanding++;
  });
  if (outstanding >= MAX_OUTSTANDING_CODES) {
    throw new HttpsError(
      "resource-exhausted",
      `You have ${MAX_OUTSTANDING_CODES} outstanding invite codes — redeem them or wait for expiry.`
    );
  }

  // Collision-retry (≤5 attempts; 32^8 space makes this vanishingly rare).
  let code = generateCode();
  for (let attempt = 0; attempt < 5; attempt++) {
    const existing = await db.collection("creator_invite_codes").doc(code).get();
    if (!existing.exists) break;
    code = generateCode();
    if (attempt === 4) {
      throw new HttpsError("internal", "Could not generate a unique code.");
    }
  }

  await db.collection("creator_invite_codes").doc(code).set({
    creatorUid: uid,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    expiresAt: new Date(Date.now() + CODE_TTL_MS),
    redeemedBy: null,
  });

  return { code };
});

export const redeemCreatorInvite = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be logged in.");
  }
  const uid = request.auth.uid;
  const data = request.data ?? {};
  const code = typeof data.code === "string" ? data.code.trim().toUpperCase() : "";
  if (!CODE_PATTERN.test(code)) {
    throw new HttpsError("invalid-argument", "Invalid invite code format.");
  }
  const displayName =
    typeof data.displayName === "string" && data.displayName.trim() !== ""
      ? data.displayName.trim().slice(0, 50)
      : "Creator";

  // Already a creator? (best-effort; the transaction's single-use code is
  // the real guard against double consumption).
  const [existingProfile, userRecord] = await Promise.all([
    db.collection("creator_profiles").doc(uid).get(),
    admin.auth().getUser(uid),
  ]);
  if (
    existingProfile.exists ||
    (userRecord.customClaims ?? {}).role === "creator"
  ) {
    throw new HttpsError("already-exists", "This account is already a creator.");
  }

  const codeRef = db.collection("creator_invite_codes").doc(code);
  const profileRef = db.collection("creator_profiles").doc(uid);

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(codeRef);
    if (!snap.exists) {
      throw new HttpsError("not-found", "Invalid or expired invite code.");
    }
    const doc = snap.data()!;
    if (doc.redeemedBy != null) {
      throw new HttpsError(
        "failed-precondition",
        "This invite code has already been used."
      );
    }
    const expiresAt = doc.expiresAt as admin.firestore.Timestamp | Date | undefined;
    const expiryMs =
      expiresAt instanceof Date
        ? expiresAt.getTime()
        : expiresAt?.toMillis?.() ?? 0;
    if (expiryMs < Date.now()) {
      throw new HttpsError(
        "failed-precondition",
        "This invite code has expired."
      );
    }

    // Mark + delete in the same transaction (doc-as-lock: a replayed or
    // failed delete still leaves the redeemedBy marker blocking reuse).
    tx.set(
      codeRef,
      { redeemedBy: uid, redeemedAt: admin.firestore.FieldValue.serverTimestamp() },
      { merge: true }
    );
    tx.delete(codeRef);

    tx.set(profileRef, {
      userId: uid,
      ownerId: uid,
      role: "creator",
      displayName,
      isVerifiedCreator: true,
      bio: "",
      specialityTags: [],
      blueprintCount: 0,
      creatorOnboardingProgress: 0,
      archetype: "none",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

  await admin.auth().setCustomUserClaims(uid, {
    ...(userRecord.customClaims ?? {}),
    role: "creator",
  });

  return { ok: true, uid };
});

export const ensureCreatorTribe = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be logged in.");
  }
  const uid = request.auth.uid;
  if (!(await isVerifiedCreator(uid))) {
    throw new HttpsError(
      "permission-denied",
      "Only verified creators can create tribes."
    );
  }
  const data = request.data ?? {};
  const blueprintId =
    typeof data.blueprintId === "string" && data.blueprintId.trim() !== ""
      ? data.blueprintId.trim()
      : null;

  const existing = await db
    .collection("tribes")
    .where("createdBy", "==", uid)
    .where("type", "==", "creator")
    .limit(1)
    .get();

  let tribeId: string;
  let created = false;
  if (existing.empty) {
    const profile = await db.collection("creator_profiles").doc(uid).get();
    const displayName = (profile.data()?.displayName as string) ?? "Creator";
    const archetype = (profile.data()?.archetype as string) ?? "none";
    const tribeRef = db.collection("tribes").doc();
    const tribeDoc: Record<string, unknown> = {
      name: `${displayName}'s Tribe`,
      type: "creator",
      createdBy: uid,
      members: [uid],
      memberCount: 1,
      description: "",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    if (archetype && archetype !== "none") {
      tribeDoc.archetypeId = archetype;
    }
    await tribeRef.set(tribeDoc);
    tribeId = tribeRef.id;
    created = true;
    await db
      .collection("creator_profiles")
      .doc(uid)
      .set({ tribeId, ownerId: uid }, { merge: true });
  } else {
    tribeId = existing.docs[0].id;
  }

  if (blueprintId) {
    const bp = await db.collection("blueprints").doc(blueprintId).get();
    if (bp.exists && bp.data()?.creatorUserId === uid) {
      await db
        .collection("blueprints")
        .doc(blueprintId)
        .set({ creatorTribeId: tribeId }, { merge: true });
    }
  }

  return { tribeId, created };
});
