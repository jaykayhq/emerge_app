/**
 * purge_orphaned_data.js
 *
 * Standalone script — no Cloud Function deploy needed. Mirrors
 * functions/src/purgeOrphanedUserData.ts so local runs behave identically
 * to the deployed callable.
 *
 * Finds Firestore docs whose UID no longer exists in Firebase Auth.
 * Defaults to dry-run mode — pass --execute to actually delete.
 *
 * For each orphaned user it deletes:
 *   - users/{uid} recursively (subcollections included) + tribe membership
 *   - user_stats/{uid}, creator_profiles/{uid}, insight_cache/{uid},
 *     customers/{uid}
 *   - ALL user-keyed docs (habits, user_activity, global_activities,
 *     club_leaderboards, challenge_leaderboards, contracts,
 *     partner_requests, security_logs, revenuecat_events, usernames) so a
 *     deleted account's data can never resurface through a stale client
 *     cache or a re-claimed doc id.
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
 * WARNING: This permanently deletes data. Make a Firestore backup first.
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

/**
 * User-keyed collections: docs matched by a FIELD (not doc id) — the same
 * list deleteMyAccount and the deployed purgeOrphanedUserData clean.
 */
const USER_KEYED_COLLECTIONS = [
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

/** Doc IDs with these prefixes are system-seeded, not user-owned. */
const SYSTEM_PREFIXES = ["creator_"];

/** Removes a uid from every tribe's members array (derived count). */
async function removeUserFromTribes(uid) {
  const snap = await db.collectionGroup("tribes").get();
  for (const d of snap.docs) {
    const parts = d.ref.path.split("/");
    if (parts.length !== 4 || parts[0] !== "users" || parts[2] !== "tribes") continue;
    const tribeRef = db.collection("tribes").doc(parts[3]);
    const tribeDoc = await tribeRef.get();
    if (!tribeDoc.exists) continue;
    const members = Array.isArray(tribeDoc.data().members) ? tribeDoc.data().members : [];
    const next = members.filter((m) => m !== uid);
    if (next.length === members.length) continue;
    await tribeRef.update({ members: next, memberCount: next.length });
  }
}

/** Deletes every doc in user-keyed collections whose field == uid. */
async function purgeUserKeyedData(uid) {
  let total = 0;
  for (const [collectionPath, field] of USER_KEYED_COLLECTIONS) {
    const snap = await db.collection(collectionPath).where(field, "==", uid).get();
    if (snap.empty) continue;
    const docs = snap.docs.map((d) => d.ref);
    total += docs.length;
    for (let i = 0; i < docs.length; i += 400) {
      const batch = db.batch();
      for (const ref of docs.slice(i, i + 400)) batch.delete(ref);
      await batch.commit();
    }
  }
  return total;
}

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

    if (orphans.length === 0) {
      console.log(`  ${colName}: scanned=${snap.size}, ${execute ? "deleted" : "candidates"}=0`);
      continue;
    }

    if (execute) {
      for (const id of orphans) {
        if (colName === "users") {
          // Recursive delete covers subcollections (memberships, etc.).
          await db.recursiveDelete(db.collection("users").doc(id));
          await removeUserFromTribes(id);
          const extra = await purgeUserKeyedData(id);
          console.log(`    users/${id}: recursive delete + ${extra} user-keyed docs`);
          totalDeleted += 1 + extra;
        } else {
          // Delete in batches of 400
          for (let i = 0; i < orphans.length; i += 400) {
            const batch = db.batch();
            const chunk = orphans.slice(i, i + 400);
            for (const id of chunk) {
              batch.delete(db.collection(colName).doc(id));
            }
            await batch.commit();
          }
          totalDeleted += orphans.length;
        }
      }
    }

    const label = execute ? "deleted" : "candidates";
    console.log(`  ${colName}: scanned=${snap.size}, ${label}=${orphans.length}`);
  }

  const verb = execute ? "deleted" : "found (dry-run)";
  console.log(`\n=== DONE: ${totalDeleted} orphaned docs ${verb} ===`);
  if (!execute && totalDeleted > 0) {
    console.log("Pass --execute to actually delete these documents.");
  }
  process.exit(0);
}

main().catch((err) => {
  console.error("Fatal error:", err);
  process.exit(1);
});
