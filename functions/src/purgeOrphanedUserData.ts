/**
 * purgeOrphanedUserData — admin-only callable function.
 *
 * Finds Firestore documents whose UID no longer exists in Firebase Auth.
 * Defaults to dry-run mode — pass { dryRun: false } to actually delete.
 *
 * Collections scanned:
 *   - users/{uid}
 *   - user_stats/{uid}
 *   - creator_profiles/{uid}
 *   - insight_cache/{uid}
 *   - customers/{uid}
 *
 * Auth: caller must have admin custom claim (request.auth.token.admin === true).
 *
 * ALTERNATIVE — standalone script (no deploy needed):
 *   node scripts/purge_orphaned_data.js
 *   (defaults to dry-run; pass --execute to delete)
 *
 * Usage from app (admin user only):
 *   const result = await firebase.functions().httpsCallable('purgeOrphanedUserData')({ dryRun: false });
 *   console.log(result.data.summary);
 *
 * WARNING: Top-level document deletion does NOT clean subcollections.
 * Orphaned subcollection data must be cleaned up separately (e.g. by
 * recursively deleting subcollections or using a Cloud Function that
 * iterates all subcollections per document).
 */
import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { removeUserFromTribesInternal } from "./cleanupUserData";

if (admin.apps.length === 0) {
  admin.initializeApp();
}

const db = admin.firestore();

/** Collections to scan for orphaned docs — each mapped by document ID = uid. */
const COLLECTIONS_TO_SCAN = [
  "users",
  "user_stats",
  "creator_profiles",
  "insight_cache",
  "customers",
] as const;

/**
 * User-keyed collections: docs are matched by a FIELD (not doc id), the same
 * list deleteMyAccount cleans for a self-deleting user. Without this, an
 * orphaned account's habits/activity/leaderboard docs survive the purge and
 * could be picked up again by a stale client cache or a re-claimed doc id.
 */
const USER_KEYED_COLLECTIONS: ReadonlyArray<readonly [string, string]> = [
  ["habits", "userId"],
  ["user_activity", "userId"],
  ["global_activities", "userId"],
  ["club_leaderboards", "userId"],
  ["challenge_leaderboards", "userId"],
  ["contracts", "userId"],
  ["contracts", "partnerId"],
  ["partner_requests", "senderId"],
  ["partner_requests", "recipientId"],
  ["security_logs", "userId"],
  ["revenuecat_events", "app_user_id"],
  ["usernames", "uid"],
];

/**
 * Deletes every doc in the user-keyed collections whose field matches the
 * orphaned uid. Dry-run counts without writing. Returns the count.
 * Exported for tests (the onCall wrapper is exercised via the emulator).
 */
export async function purgeUserKeyedData(
  db: admin.firestore.Firestore,
  uid: string,
  dryRun: boolean,
): Promise<number> {
  let total = 0;
  for (const [collectionPath, field] of USER_KEYED_COLLECTIONS) {
    const snap = await db
      .collection(collectionPath)
      .where(field, "==", uid)
      .get();
    if (snap.empty) continue;

    const docs = snap.docs.map((d) => d.ref);
    total += docs.length;
    if (dryRun) continue;

    for (let i = 0; i < docs.length; i += 400) {
      const batch = db.batch();
      for (const ref of docs.slice(i, i + 400)) {
        batch.delete(ref);
      }
      await batch.commit();
    }
  }
  return total;
}

export const purgeOrphanedUserData = onCall(async (request) => {
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
      "Only admins can purge orphaned user data.",
    );
  }

  // ── Dry-run mode: default true to prevent accidental deletion. ──
  // Pass { dryRun: false } to actually delete orphaned documents.
  const dryRun: boolean = request.data?.dryRun !== false;

  // ── 1. Build the set of valid Auth UIDs ──
  const validUids = new Set<string>();
  let nextPageToken: string | undefined;
  do {
    const listResult = await admin.auth().listUsers(1000, nextPageToken);
    for (const user of listResult.users) {
      validUids.add(user.uid);
    }
    nextPageToken = listResult.pageToken;
  } while (nextPageToken);

  console.log(`purgeOrphanedUserData: ${validUids.size} active Auth users.`);

  // ── 2. Scan each collection for orphaned docs ──
  const summary: Record<string, { scanned: number; deleted: number; skipped: number }> = {};
  let totalDeleted = 0;

  for (const collectionName of COLLECTIONS_TO_SCAN) {
    const snap = await db.collection(collectionName).get();
    const scanned = snap.size;
    let deleted = 0;
    let skipped = 0;

    if (scanned === 0) {
      summary[collectionName] = { scanned: 0, deleted: 0, skipped: 0 };
      continue;
    }

    let candidateCount = 0;
    let batch = db.batch();
    let batchOps = 0;

    for (const doc of snap.docs) {
      const docId = doc.id;

      // Skip if the UID still exists in Auth.
      if (validUids.has(docId)) {
        continue;
      }

      // Orphaned found — count it.
      candidateCount++;

      // In dry-run mode, only count; do not delete.
      if (dryRun) {
        continue;
      }

      // User docs need recursive delete: the top-level `users/{uid}` delete
      // can't reach subcollections, and the orphan's `users/{uid}/tribes/*`
      // membership docs would otherwise survive and keep them counted as a
      // tribe member (and in the nightly recalc).
      if (collectionName === "users") {
        await db.recursiveDelete(db.collection("users").doc(docId));
        // Derived, idempotent removal from tribe members arrays. Covers
        // orphans present in `members` without a membership doc (the
        // membership-doc deletes above fire maintainTribeMembership when
        // deployed, which writes the same derived value — ordering can
        // never double-decrement).
        await removeUserFromTribesInternal(db, docId);
        // Also purge user-keyed collections (habits, activity, leaderboards,
        // contracts, usernames...) so a deleted account's data can never
        // resurface through a stale client cache or re-claimed doc id.
        await purgeUserKeyedData(db, docId, dryRun);
        deleted++;
        continue;
      }

      // Mark for deletion.
      batch.delete(doc.ref);
      batchOps++;

      // Firestore batches are limited to 500 writes. A committed batch can
      // never be reused — a new WriteBatch must be created or every further
      // delete throws "Cannot modify a WriteBatch that has already been
      // committed" and aborts the whole purge.
      if (batchOps >= 400) {
        await batch.commit();
        deleted += batchOps;
        batch = db.batch();
        batchOps = 0;
      }
    }

    // Flush remaining batch (non-dry-run only).
    if (!dryRun && batchOps > 0) {
      await batch.commit();
      deleted += batchOps;
    }

    totalDeleted += deleted;
    summary[collectionName] = { scanned, deleted, skipped };

    const label = dryRun ? "candidates" : "deleted";
    console.log(
      `  ${collectionName}: scanned=${scanned}, ${label}=${dryRun ? candidateCount : deleted}, skipped=${skipped}`,
    );
  }

  const verb = dryRun ? "found (dry-run)" : "deleted";
  console.log(`purgeOrphanedUserData: DONE — ${totalDeleted} orphaned docs ${verb}.`);

  return {
    ok: true,
    totalDeleted,
    dryRun,
    collections: summary,
    note: dryRun
      ? "Dry-run mode — no data was deleted. Call with { dryRun: false } to delete."
      : "WARNING: users/{uid} docs are recursively deleted (subcollections included). Other collections are top-level deletes only — their subcollection data must be cleaned up separately.",
  };
});
