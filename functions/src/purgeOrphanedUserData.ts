/**
 * purgeOrphanedUserData — admin-only callable function.
 *
 * Finds Firestore documents whose UID no longer exists in Firebase Auth.
 * Defaults to dry-run mode — pass { dryRun: false } to actually delete.
 *
 * Collections scanned:
 *   - users/{uid}
 *   - user_stats/{uid}
 *   - creator_profiles/{uid}    (skips system-seeded IDs starting with "creator_")
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

/** Doc IDs with this prefix are system-seeded, not user-owned. */
const SYSTEM_PREFIXES = ["creator_"];

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
    const batch = db.batch();
    let batchOps = 0;

    for (const doc of snap.docs) {
      const docId = doc.id;

      // Skip system-seeded IDs (e.g. creator_aria_chen).
      const isSystem = SYSTEM_PREFIXES.some((prefix) => docId.startsWith(prefix));
      if (isSystem) {
        skipped++;
        continue;
      }

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

      // Mark for deletion.
      batch.delete(doc.ref);
      batchOps++;

      // Firestore batches are limited to 500 writes.
      if (batchOps >= 400) {
        await batch.commit();
        deleted += batchOps;
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
      : "WARNING: Top-level document deletion does not clean subcollections. Orphaned subcollection data must be cleaned up separately.",
  };
});
