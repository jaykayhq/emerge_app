/**
 * Email verification grace period (SP sub-project 1).
 *
 * Email delivery switched to Firebase Auth's native link flow:
 * `sendEmailVerification()` emails a click-to-verify link and sets the
 * `emailVerified` flag server-side — no custom email sending remains.
 * This module only enforces the daily grace-period lock for accounts whose
 * email still hasn't been verified.
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

/**
 * Testable body of the scheduled lock: locks accounts whose email hasn't been
 * verified (Firebase Auth's native `emailVerified` flag) within the grace
 * period by setting `emailLockedAt` on users/{uid}. Wrapped by onSchedule.
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
      .where("createdAt", "<=", cutoff)
      .limit(GRACE_PAGE_SIZE);
    if (lastDoc) {
      query = query.startAfter(lastDoc);
    }
    const snap = await query.get();
    if (snap.empty) {
      break;
    }
    const batch = database.batch();
    let changed = 0;
    for (const doc of snap.docs) {
      const data = doc.data();
      if (data.emailVerified !== true && data.emailLockedAt == null) {
        batch.set(
          database.collection("users").doc(doc.id),
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
      `[enforceEmailGracePeriod] page ${page + 1}: ${changed} locked`
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
