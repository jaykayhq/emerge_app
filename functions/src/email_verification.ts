/**
 * Email verification grace period (SP sub-project 1).
 *
 * Email delivery switched to Firebase Auth's native link flow:
 * `sendEmailVerification()` emails a click-to-verify link and sets the
 * `emailVerified` flag server-side — no custom email sending remains.
 * This module enforces the daily grace-period lock for accounts whose email
 * still hasn't been verified within 7 days of the verification email being
 * sent.
 *
 * The client records `emailVerificationSentAt` (timestamp) on users/{uid}
 * when it sends the verification email. This function queries only those
 * accounts, checks the authoritative Firebase Auth `emailVerified` flag per
 * candidate (the Firestore mirror is not client-maintainable and cannot be
 * trusted for the decision), locks genuinely unverified accounts, and clears
 * stale locks for accounts that verified after being locked.
 */
import { onSchedule } from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";

if (admin.apps.length === 0) {
  admin.initializeApp();
}

const db = admin.firestore();

export const GRACE_PERIOD_MS = 7 * 24 * 60 * 60 * 1000; // 7 days

// Page size stays under Firestore's 500-write batch cap; the bounded loop
// guards against a runaway job on a pathological dataset.
const GRACE_PAGE_SIZE = 400;
const GRACE_MAX_PAGES = 100;
// Auth lookups are chunked to stay within Identity Platform rate limits.
const AUTH_CHUNK_SIZE = 20;

interface Candidate {
  id: string;
  emailLockedAt: unknown;
}

async function getVerifiedMap(
  candidates: Candidate[]
): Promise<Map<string, boolean>> {
  const result = new Map<string, boolean>();
  for (let i = 0; i < candidates.length; i += AUTH_CHUNK_SIZE) {
    const chunk = candidates.slice(i, i + AUTH_CHUNK_SIZE);
    const records = await Promise.all(
      chunk.map((c) =>
        admin
          .auth()
          .getUser(c.id)
          .then(
            (u) => ({ id: c.id, verified: u.emailVerified }),
            () => null // deleted/missing user — skip
          )
      )
    );
    records.forEach((r) => {
      if (r != null) {
        result.set(r.id, r.verified);
      }
    });
  }
  return result;
}

/**
 * Testable body of the scheduled lock. `emailVerified` comes from Firebase
 * Auth (authoritative); the Firestore doc only supplies the sent-at marker
 * and the current lock state. Wrapped by onSchedule.
 */
export async function enforceEmailGracePeriodInternal(
  database: typeof db,
  nowMs: number
): Promise<void> {
  const cutoff = new Date(nowMs - GRACE_PERIOD_MS);
  let lastDoc: admin.firestore.QueryDocumentSnapshot | undefined;
  for (let page = 0; page < GRACE_MAX_PAGES; page++) {
    let query = database
      .collection("users")
      .where("emailVerificationSentAt", "<=", cutoff)
      .limit(GRACE_PAGE_SIZE);
    if (lastDoc) {
      query = query.startAfter(lastDoc);
    }
    const snap = await query.get();
    if (snap.empty) {
      break;
    }
    const candidates: Candidate[] = snap.docs.map((doc) => ({
      id: doc.id,
      emailLockedAt: doc.data().emailLockedAt,
    }));
    const verifiedMap = await getVerifiedMap(candidates);

    const batch = database.batch();
    let changed = 0;
    for (const doc of snap.docs) {
      const id = doc.id;
      const verified = verifiedMap.get(id);
      if (verified == null) {
        continue; // auth record missing — leave as-is
      }
      const locked = candidates.find((c) => c.id === id)?.emailLockedAt != null;
      if (verified) {
        // Clear stale locks so a past lock can't linger after verification.
        if (locked) {
          batch.set(
            database.collection("users").doc(id),
            { emailLockedAt: admin.firestore.FieldValue.delete() },
            { merge: true }
          );
          changed++;
        }
      } else if (!locked) {
        batch.set(
          database.collection("users").doc(id),
          { emailLockedAt: admin.firestore.FieldValue.serverTimestamp() },
          { merge: true }
        );
        changed++;
      }
    }
    if (changed > 0) {
      await batch.commit();
    }
    console.log(
      `[enforceEmailGracePeriod] page ${page + 1}: ${changed} updated`
    );
    lastDoc = snap.docs[snap.docs.length - 1];
    if (snap.docs.length < GRACE_PAGE_SIZE) {
      break;
    }
  }
}

export const enforceEmailGracePeriod = onSchedule("0 4 * * *", async () => {
  console.log("Enforcing email verification grace period");
  await enforceEmailGracePeriodInternal(db, Date.now());
});
