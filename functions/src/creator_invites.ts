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
/**
 * Cap on docs fetched when locating a creator's tribe. The lookup queries
 * the single auto-indexed `type == 'creator'` field (no composite index
 * exists for createdBy+type, SP-H §5.1) and filters createdBy in memory, so
 * the scan must be bounded.
 */
export const CREATOR_TRIBE_SCAN_LIMIT = 100;

/**
 * Expiry timestamp (ms) of a doc field that is a Firestore Timestamp or a
 * JS Date. Returns 0 when absent/unparseable — callers decide how to treat
 * unknown expiry (redeem: expired; generate: expired, so garbage codes never
 * hold quota forever).
 */
export function codeExpiryMs(value: unknown): number {
  if (value instanceof Date) return value.getTime();
  const ts = value as { toMillis?: () => number } | undefined;
  return ts?.toMillis?.() ?? 0;
}

/**
 * Finds the id of a creator's own tribe among fetched `type == 'creator'`
 * docs. Pure in-memory filter (SP-H §5.1) so the query never needs a
 * composite index: the callable queries one auto-indexed field and applies
 * the createdBy equality here.
 */
export function findCreatorTribe(
  docs: Array<{ id: string; data: () => Record<string, unknown> }>,
  uid: string
): string | null {
  const match = docs.find((doc) => doc.data().createdBy === uid);
  return match ? match.id : null;
}

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

/**
 * Whether the account holds the `admin: true` custom claim. Invite-code
 * generation is an admin-only capability (the default creator account seeded
 * by seedCreatorAccount carries it) — ordinary verified creators can only
 * redeem codes, not mint them.
 */
export async function isAdminUser(uid: string): Promise<boolean> {
  const userRecord = await admin.auth().getUser(uid);
  return userRecord.customClaims?.admin === true;
}

export const generateCreatorInviteCode = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be logged in.");
  }
  const uid = request.auth.uid;
  if (!(await isAdminUser(uid))) {
    throw new HttpsError(
      "permission-denied",
      "Only the admin creator can generate invite codes."
    );
  }

  // Outstanding count: query by creatorUid (Firestore cannot filter
  // `== null`), filter redeemedBy AND expiry in memory (SP-H review: expired
  // codes must not hold quota forever — a creator who generated 10 codes and
  // let them lapse can generate again). Expired codes for this creator are
  // also deleted best-effort below so the quota frees itself.
  const snapshot = await db
    .collection("creator_invite_codes")
    .where("creatorUid", "==", uid)
    .get();
  const nowMs = Date.now();
  const expiredIds: string[] = [];
  let outstanding = 0;
  snapshot.forEach((doc) => {
    const data = doc.data();
    // A code without a parseable expiresAt is un-redeemable garbage (the
    // redeem path treats it as expired) — count it as expired so it can
    // neither hold quota nor linger.
    if (codeExpiryMs(data.expiresAt) <= nowMs) {
      expiredIds.push(doc.id);
      return;
    }
    if (data.redeemedBy == null) outstanding++;
  });
  if (outstanding >= MAX_OUTSTANDING_CODES) {
    throw new HttpsError(
      "resource-exhausted",
      `You have ${MAX_OUTSTANDING_CODES} outstanding invite codes — redeem them or wait for expiry.`
    );
  }

  // Best-effort cleanup of this creator's expired codes (the count above
  // already excludes them; a failed delete just retries next generate).
  if (expiredIds.length > 0) {
    const batch = db.batch();
    for (const id of expiredIds) {
      batch.delete(db.collection("creator_invite_codes").doc(id));
    }
    try {
      await batch.commit();
    } catch (err) {
      console.warn(
        `[generateCreatorInviteCode] expired-code cleanup failed: ${err}`
      );
    }
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
  const existingClaims = userRecord.customClaims ?? {};
  if (existingProfile.exists || existingClaims.role === "creator") {
    // Recovery path (SP-H review): setCustomUserClaims runs AFTER the
    // transaction commits, so a claim-set failure leaves a committed profile
    // with no claim — retry would otherwise be bricked by this branch (the
    // code is already consumed and the profile already exists). If the
    // committed profile is this user's own verified creator profile and the
    // claim is missing, re-issue the claim and succeed. The profile shape
    // below is exactly what the transaction writes (ownerId == uid,
    // isVerifiedCreator: true), so a foreign profile can never be claimed.
    if (
      existingClaims.role !== "creator" &&
      existingProfile.exists &&
      existingProfile.data()?.ownerId === uid &&
      existingProfile.data()?.isVerifiedCreator === true
    ) {
      await admin.auth().setCustomUserClaims(uid, {
        ...existingClaims,
        role: "creator",
      });
      return { ok: true, uid, recovered: true };
    }
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
    if (codeExpiryMs(doc.expiresAt) < Date.now()) {
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

  // SP-H §5.1: no composite index exists for (createdBy, type), so query the
  // single auto-indexed `type` field over a bounded set and filter createdBy
  // in memory. A creator owns at most one tribe, so the scan is safe.
  const snapshot = await db
    .collection("tribes")
    .where("type", "==", "creator")
    .limit(CREATOR_TRIBE_SCAN_LIMIT)
    .get();
  const existingTribeId = findCreatorTribe(snapshot.docs, uid);

  let tribeId: string;
  let created = false;
  if (existingTribeId == null) {
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
    tribeId = existingTribeId;
  }

  // Explicit membership doc for the creator (SP-H review): aggregateTribeStats
  // builds tribe members EXCLUSIVELY from users/{uid}/tribes membership docs,
  // so without this the recalc drops the creator from their own tribe the
  // moment a second user joins. Same shape as the client join path
  // (tribe_membership_service.dart: {tribeId, joinedAt, membershipType,
  // isActive}); merge keeps a re-run idempotent and repairs legacy creators.
  await db
    .collection("users")
    .doc(uid)
    .collection("tribes")
    .doc(tribeId)
    .set(
      {
        tribeId,
        joinedAt: admin.firestore.FieldValue.serverTimestamp(),
        membershipType: "creator",
        isActive: true,
      },
      { merge: true }
    );

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
