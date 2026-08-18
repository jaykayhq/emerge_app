/**
 * Daily tribe-analytics snapshot job.
 *
 * Server-side backstop to the client-side `TribeAnalyticsSnapshotService`
 * (lib/features/social/data/services/tribe_analytics_snapshot_service.dart):
 * ensures every tribe has today's doc in `tribe_analytics/{tribeId}/daily/{date}`
 * even when no creator opened the app that day. Both writers are idempotent —
 * same doc id per date, and this job skips dates that are already fresh.
 *
 * Pure logic lives in snapshot.js (unit-tested); this entry holds the
 * Firestore driver only.
 *
 * Run locally:
 *   FIREBASE_SERVICE_ACCOUNT=path/to/service-account.json node index.js --dry-run
 *   GOOGLE_APPLICATION_CREDENTIALS=path/to/service-account.json node index.js
 *
 * In GitHub Actions the workflow passes FIREBASE_SERVICE_ACCOUNT_JSON inline.
 */
import { cert, initializeApp } from "firebase-admin/app";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { readFileSync } from "node:fs";
import { dateKey, isStale, buildSnapshot } from "./snapshot.js";

const PROJECT_ID = "tradeflash-l2966";

function initDb() {
  const inline = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  const path = process.env.FIREBASE_SERVICE_ACCOUNT;
  if (inline) {
    initializeApp({
      projectId: PROJECT_ID,
      credential: cert(JSON.parse(inline)),
    });
  } else if (path) {
    initializeApp({
      projectId: PROJECT_ID,
      credential: cert(JSON.parse(readFileSync(path, "utf8"))),
    });
  } else {
    initializeApp({ projectId: PROJECT_ID }); // GOOGLE_APPLICATION_CREDENTIALS
  }
  return getFirestore();
}

async function latestSnapshotDate(db, tribeId) {
  const snap = await db
    .collection("tribe_analytics")
    .doc(tribeId)
    .collection("daily")
    .orderBy("date", "desc")
    .limit(1)
    .get();
  if (snap.empty) return null;
  return snap.docs[0].data().date ?? null;
}

async function main() {
  const dryRun = process.argv.includes("--dry-run");
  const db = initDb();
  const now = new Date();
  const today = dateKey(now);
  const write = dryRun ? () => {} : (ref, data) => ref.set(data);

  const tribes = await db.collection("tribes").get();
  console.log(`Scanning ${tribes.size} tribes (date=${today}${dryRun ? ", DRY RUN" : ""})`);

  let written = 0;
  let skipped = 0;
  for (const tribe of tribes.docs) {
    const data = tribe.data();
    // Only tribes with a creator own the analytics surface; official clubs
    // have no createdBy and don't need snapshots.
    if (!data.createdBy || typeof data.createdBy !== "string") {
      skipped++;
      continue;
    }

    const latest = await latestSnapshotDate(db, tribe.id);
    if (!isStale(latest, now)) {
      skipped++;
      continue;
    }

    const contributors = await db
      .collection("tribes")
      .doc(tribe.id)
      .collection("contributors")
      .get();
    const snapshot = buildSnapshot(tribe, contributors.docs, now, Timestamp.now);

    const ref = db
      .collection("tribe_analytics")
      .doc(tribe.id)
      .collection("daily")
      .doc(today);
    await write(ref, snapshot);
    console.log(
      `✓ ${tribe.id}: members=${snapshot.memberCount} xp=${snapshot.totalXp} ` +
        `habits=${snapshot.totalHabitsCompleted} challenges=${snapshot.totalChallengesCompleted} ` +
        `active=${snapshot.activeMembers} new=${snapshot.newMembersThisWeek}`,
    );
    written++;
  }

  console.log(`Done: ${written} snapshot(s) written, ${skipped} skipped.`);
  if (written === 0 && skipped === 0) {
    console.error("No tribes found — check the tribes collection.");
    process.exit(1);
  }
  process.exit(0);
}

main().catch((err) => {
  console.error("Snapshot job failed:", err);
  process.exit(1);
});
