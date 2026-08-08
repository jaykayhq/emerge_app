/**
 * backfillUsernames — admin-only callable (SP sub-project 1).
 *
 * One-off backfill: claim globally-unique usernames for EXISTING users so the
 * new `usernames/{lowercased}` doc-as-lock collection is fully populated.
 * Deterministic and idempotent — safe to re-run:
 *   - skips users whose displayName is missing/invalid (validateUsername)
 *   - skips names already claimed by the same uid
 *   - on collision with a different uid appends `_2`, `_3`, … suffixes
 *
 * Auth: caller must have admin custom claim
 * (request.auth.token.admin === true), mirroring purgeOrphanedUserData.
 * Usage from app (admin user only):
 *   const result = await firebase.functions()
 *     .httpsCallable('backfillUsernames')();
 *   console.log(result.data.summary);
 */
import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { validateUsername } from "./usernames";

if (admin.apps.length === 0) {
  admin.initializeApp();
}

const db = admin.firestore();

export const backfillUsernames = onCall(
  { timeoutSeconds: 120, memory: "512MiB", cpu: 1 },
  async (request) => {
    // ── Auth guard: only admins may run this. ──
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "You must be logged in.",
      );
    }
    if (request.auth.token?.admin !== true) {
      throw new HttpsError(
        "permission-denied",
        "Only admins can backfill usernames.",
      );
    }

    const snap = await db.collection("users").orderBy("createdAt", "asc").get();
    let batch = db.batch();
    let claimed = 0;
    let skipped = 0;
    let collisions = 0;

    for (const doc of snap.docs) {
      const uid = doc.id;
      const raw = (doc.data().displayName as string) ?? "";
      const base = raw.trim();
      if (!base || validateUsername(base) !== null) {
        skipped++;
        continue;
      }
      let candidate = base.toLowerCase();
      for (let attempt = 2; ; attempt++) {
        const nameRef = db.collection("usernames").doc(candidate);
        const existing = await nameRef.get();
        if (!existing.exists) {
          batch.set(nameRef, {
            uid,
            claimedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          claimed++;
          break;
        }
        if (existing.data()?.uid === uid) {
          skipped++; // already claimed by this uid — idempotent re-run
          break;
        }
        collisions++;
        candidate = `${base.toLowerCase()}_${attempt}`;
        if (attempt > 1000) {
          console.warn(`[backfill] could not claim for ${uid} (${base})`);
          break;
        }
      }
      if (claimed % 400 === 0) {
        await batch.commit();
        batch = db.batch();
      }
    }
    await batch.commit();
    const summary = { claimed, skipped, collisions };
    console.log(
      `[backfill] claimed=${claimed} skipped=${skipped} ` +
        `collisions=${collisions}`
    );
    return summary;
  }
);
