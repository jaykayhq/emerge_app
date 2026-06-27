/**
 * purge_orphaned_data.js
 *
 * Standalone script — no Cloud Function deploy needed.
 *
 * Finds Firestore docs whose UID no longer exists in Firebase Auth.
 * Defaults to dry-run mode — pass --execute to actually delete.
 *
 * Usage:
 *   1. Download your service-account key from Firebase Console →
 *      Project Settings → Service Accounts → "Generate new private key".
 *   2. Save it as service-account-key.json in this directory (or set
 *      GOOGLE_APPLICATION_CREDENTIALS env var to its path).
 *   3. Run:
 *        node scripts/purge_orphaned_data.js          # dry-run only
 *        node scripts/purge_orphaned_data.js --execute  # actual deletion
 *
 * Collections scanned:
 *   - users/{uid}
 *   - user_stats/{uid}
 *   - creator_profiles/{uid}    (skips system-seeded IDs like "creator_*")
 *   - insight_cache/{uid}
 *   - customers/{uid}
 *
 * WARNING: This permanently deletes data. Make a Firestore backup first.
 * WARNING: Top-level document deletion does NOT clean subcollections.
 */

const admin = require("firebase-admin");
const path = require("path");

// ── 1. Init Admin SDK ──
const serviceAccountPath =
  process.env.GOOGLE_APPLICATION_CREDENTIALS ||
  path.join(__dirname, "service-account-key.json");

// Try explicit service-account key first (robust against ADC without
// a quota project). Fall back to ADC for environments like Cloud Run.
let keyLoaded = false;
try {
  const key = require(serviceAccountPath);
  admin.initializeApp({ credential: admin.credential.cert(key) });
  keyLoaded = true;
  console.log("Initialized with service-account key:", serviceAccountPath);
} catch (e) {
  // Key file missing or invalid — fall through to ADC.
}

if (!keyLoaded) {
  try {
    admin.initializeApp({ credential: admin.credential.applicationDefault() });
    console.log("Initialized with Application Default Credentials.");
  } catch (e2) {
    console.error("Could not initialize Firebase Admin SDK.");
    console.error("  Tried key file:", serviceAccountPath);
    console.error("  Tried ADC as well.");
    throw e2;
  }
}

const db = admin.firestore();

/** Collections to scan — each keyed by document ID which should be a uid. */
const COLLECTIONS = ["users", "user_stats", "creator_profiles", "insight_cache", "customers"];

/** Doc IDs with these prefixes are system-seeded, not user-owned. */
const SYSTEM_PREFIXES = ["creator_"];

async function main() {
  // ── Dry-run mode: default true unless --execute is passed. ──
  const execute = process.argv.includes("--execute");
  const mode = execute ? "EXECUTION" : "DRY-RUN";
  console.log(`=== purge_orphaned_data [${mode}] ===\n`);

  // ── 2. Build set of valid Auth UIDs ──
  console.log("Fetching all Firebase Auth users...");
  const validUids = new Set();
  let nextPageToken;
  do {
    const list = await admin.auth().listUsers(1000, nextPageToken);
    for (const user of list.users) validUids.add(user.uid);
    nextPageToken = list.pageToken;
    console.log(`  ...${validUids.size} users fetched`);
  } while (nextPageToken);
  console.log(`  Total active Auth users: ${validUids.size}\n`);

  // ── 3. Scan collections ──
  let totalDeleted = 0;
  for (const colName of COLLECTIONS) {
    const snap = await db.collection(colName).get();
    if (snap.empty) {
      console.log(`  ${colName}: 0 docs (empty)`);
      continue;
    }

    const orphans = [];
    for (const doc of snap.docs) {
      const docId = doc.id;

      // Skip system-seeded IDs
      if (SYSTEM_PREFIXES.some((p) => docId.startsWith(p))) continue;

      // Skip if UID still exists in Auth
      if (validUids.has(docId)) continue;

      orphans.push(docId);
    }

    const deletedCount = orphans.length;

    if (deletedCount === 0) {
      console.log(`  ${colName}: scanned=${snap.size}, ${execute ? "deleted" : "candidates"}=0`);
      continue;
    }

    if (execute) {
      // Delete in batches of 400
      for (let i = 0; i < orphans.length; i += 400) {
        const batch = db.batch();
        const chunk = orphans.slice(i, i + 400);
        for (const id of chunk) {
          batch.delete(db.collection(colName).doc(id));
        }
        await batch.commit();
      }
    }

    totalDeleted += deletedCount;
    const label = execute ? "deleted" : "candidates";
    console.log(`  ${colName}: scanned=${snap.size}, ${label}=${deletedCount}, skipped=${snap.size - deletedCount}`);
  }

  const verb = execute ? "deleted" : "found (dry-run)";
  if (!execute && totalDeleted > 0) {
    console.log(`\n=== DONE: ${totalDeleted} orphaned docs ${verb} ===`);
    console.log("Pass --execute to actually delete these documents.");
  } else {
    console.log(`\n=== DONE: ${totalDeleted} orphaned docs ${verb} ===`);
  }
  if (!execute) {
    console.log("WARNING: Top-level document deletion does not clean subcollections.");
  }
  process.exit(0);
}

main().catch((err) => {
  console.error("Fatal error:", err);
  process.exit(1);
});
