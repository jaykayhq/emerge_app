import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

if (admin.apps.length === 0) {
  admin.initializeApp();
}

const db = admin.firestore();

/** Deletes every doc matched by `field == uid` in `collection`. */
async function deleteWhere(collectionPath: string, field: string, value: any): Promise<void> {
  const snap = await db.collection(collectionPath).where(field, "==", value).get();
  if (snap.empty) return;

  const chunks: FirebaseFirestore.DocumentReference[][] = [];
  const docs = snap.docs.map(d => d.ref);
  for (let i = 0; i < docs.length; i += 499) {
    chunks.push(docs.slice(i, i + 499));
  }
  for (const chunk of chunks) {
    const batch = db.batch();
    chunk.forEach(ref => batch.delete(ref));
    await batch.commit();
  }
}

/**
 * Removes a user from every tribe's `members` array with a DERIVED
 * `memberCount = members.length` write — never a raw increment.
 *
 * Why derived (idempotent): the recursiveDelete of `users/{uid}` fires
 * `maintainTribeMembership` for each `users/{uid}/tribes/*` doc, which ALSO
 * writes a derived `memberCount: next.length`. A raw `increment(-1)` in the
 * batch would double-decrement (or race) with the trigger; a derived write
 * lands on the same value regardless of ordering, and when the trigger
 * already removed the uid the arrays match and nothing is written at all.
 *
 * The trigger covers users WITH membership docs; this batch is the safety
 * net for users present in `members` without one (e.g. fixTribes-reset
 * arrays) — the query matches on the array, not the subcollection.
 */
export async function removeUserFromTribesInternal(
  db: admin.firestore.Firestore,
  uid: string,
): Promise<void> {
  const tribesSnap = await db
    .collection("tribes")
    .where("members", "array-contains", uid)
    .get();
  if (tribesSnap.empty) return;

  const docs = tribesSnap.docs;
  for (let i = 0; i < docs.length; i += 499) {
    const chunk = docs.slice(i, i + 499);
    const batch = db.batch();
    for (const doc of chunk) {
      const members: string[] = Array.isArray(doc.data().members)
        ? doc.data().members
        : [];
      const next = members.filter((m) => m !== uid);
      if (next.length === members.length) continue; // already removed
      batch.update(doc.ref, { members: next, memberCount: next.length });
    }
    await batch.commit();
  }
}

/**
 * Callable function: Deletes the calling user's Auth account and
 * ALL associated data across Firestore collections.
 *
 * Called from the app when user taps "Delete Account".
 * Uses Admin SDK to bypass security rules.
 *
 * NOTE: overrides the project-wide setGlobalOptions (cpu: 0.1) because
 * a purge is CPU/IO heavy and must finish inside the client's timeout.
 * concurrency must be 1 when cpu < 1, so we pin a full CPU here.
 */
export const deleteMyAccount = onCall(
  { cpu: 1, memory: "512MiB", timeoutSeconds: 120, concurrency: 1 },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "You must be logged in to delete your account.");
    }

    const uid = request.auth.uid;
    console.log(`deleteMyAccount: Starting cleanup for user ${uid}`);

    // ── Recursive deletes: user doc + user_stats (covers all subcollections:
    // friends/*, challenges/*, tribes/*, notificationSchedules/*, presence/*,
    // habit_completions/*, habit_reflections/*, recaps/*, reflections/* …) ──
    await Promise.all([
      db.recursiveDelete(db.collection("users").doc(uid)),
      db.recursiveDelete(db.collection("user_stats").doc(uid)),
      db.recursiveDelete(db.collection("pulse_feed_cards").doc(uid)),
    ]);

    // ── Single-doc deletes + query-based purges, in parallel ──
    await Promise.all([
      db.collection("insight_cache").doc(uid).delete().catch(() => {}),
      db.collection("customers").doc(uid).delete().catch(() => {}),
      deleteWhere("habits", "userId", uid),
      deleteWhere("user_activity", "userId", uid),
      deleteWhere("global_activities", "userId", uid),
      deleteWhere("club_leaderboards", "userId", uid),
      deleteWhere("challenge_leaderboards", "userId", uid),
      deleteWhere("contracts", "userId", uid),
      deleteWhere("contracts", "partnerId", uid),
      deleteWhere("partner_requests", "senderId", uid),
      deleteWhere("partner_requests", "recipientId", uid),
      deleteWhere("security_logs", "userId", uid),
      deleteWhere("revenuecat_events", "app_user_id", uid),
      // Release any claimed usernames so they can be re-claimed by new users.
      deleteWhere("usernames", "uid", uid),
    ]);

    // ── Remove membership from tribes (update, not delete) ──
    // Derived + idempotent write: the recursiveDelete above already fired
    // maintainTribeMembership for each membership doc, and this batch is the
    // safety net for members-in-array without a membership doc. Both write
    // `memberCount = members.length`, so ordering can never double-decrement.
    await removeUserFromTribesInternal(db, uid);

    // ── Delete the Firebase Auth user last ──
    try {
      await admin.auth().deleteUser(uid);
    } catch (authErr) {
      console.error(`deleteMyAccount: Failed to delete auth user ${uid}:`, authErr);
      // Don't throw — data is already cleaned up
    }

    console.log(`deleteMyAccount: Finished cleanup for user ${uid}`);
    return { success: true };
  });
