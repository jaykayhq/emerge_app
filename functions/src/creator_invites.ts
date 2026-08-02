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
