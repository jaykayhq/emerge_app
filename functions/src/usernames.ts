/**
 * Server-authoritative username claims. `usernames/{normalized}` is a
 * doc-as-lock: the doc id is the lowercased username, so Firestore's
 * transaction retry + existence check make claims race-free. Clients have
 * NO write access to this collection (firestore.rules).
 */
import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

if (admin.apps.length === 0) {
  admin.initializeApp();
}

const db = admin.firestore();

const BLOCKED_USERNAMES = new Set([
  "admin", "administrator", "root", "system", "moderator", "support", "help",
  "info", "contact", "api", "test", "user", "guest", "anonymous", "null",
  "undefined",
]);

export function validateUsername(
  value: string | null | undefined
): string | null {
  if (typeof value !== "string" || value.trim().length === 0) {
    return "Username is required";
  }
  const username = value.trim();
  if (username.length < 3) return "Username must be at least 3 characters long";
  if (username.length > 30) return "Username is too long";
  if (!/^[a-zA-Z0-9_-]+$/.test(username)) {
    return (
      "Username can only contain letters, numbers, underscores, and hyphens"
    );
  }
  if (BLOCKED_USERNAMES.has(username.toLowerCase())) {
    return "This username is not allowed";
  }
  if (/^[_-]|[_-]$/.test(username)) {
    return "Username cannot start or end with underscore or hyphen";
  }
  return null;
}

export const claimUsername = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be logged in.");
  }
  const uid = request.auth.uid;
  const data = request.data ?? {};
  const username =
    typeof data.username === "string" ? data.username.trim() : "";

  const validationError = validateUsername(username);
  if (validationError) {
    throw new HttpsError("invalid-argument", validationError);
  }

  const normalized = username.toLowerCase();
  const nameRef = db.collection("usernames").doc(normalized);
  const userRef = db.collection("users").doc(uid);

  await db.runTransaction(async (tx) => {
    const existing = await tx.get(nameRef);
    const owner = existing.data()?.uid;
    // Own-claim retries after an ambiguous network failure must succeed, not
    // hit already-exists on a doc the caller already owns.
    if (existing.exists && owner !== uid) {
      throw new HttpsError(
        "already-exists",
        "This username is already taken. Please choose another."
      );
    }
    tx.set(nameRef, {
      uid,
      claimedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    tx.set(userRef, { displayName: username }, { merge: true });
  });

  // Best-effort: users/{uid}.displayName (committed in the tx) is the app's
  // source of truth; the Auth displayName is cosmetic, so a failure here must
  // not strand the claim — the lock doc is already committed.
  try {
    await admin.auth().updateUser(uid, { displayName: username });
  } catch (err) {
    console.error(
      `[claimUsername] auth displayName update failed for ${uid}:`,
      err
    );
  }

  return { ok: true, username };
});
