/**
 * One-off backfill: claim usernames for existing users deterministically.
 * Run: cd functions && npm run backfill:usernames
 * Requires GOOGLE_APPLICATION_CREDENTIALS pointing at a service account with
 * Firestore write access (runs OUTSIDE the security rules via Admin SDK).
 */
import * as admin from "firebase-admin";
import { validateUsername } from "./usernames";

if (admin.apps.length === 0) {
  admin.initializeApp();
}

const db = admin.firestore();

async function run(): Promise<void> {
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
        batch.set(nameRef, { uid, claimedAt: admin.firestore.FieldValue.serverTimestamp() });
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
  console.log(`[backfill] claimed=${claimed} skipped=${skipped} collisions=${collisions}`);
}

run()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error("[backfill] failed:", err);
    process.exit(1);
  });
