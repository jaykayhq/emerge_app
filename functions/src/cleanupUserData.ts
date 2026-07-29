import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

if (admin.apps.length === 0) {
  admin.initializeApp();
}

const db = admin.firestore();

/** Deletes every doc matched by `field == uid` in `collection`. */
async function deleteWhere(collection: string, field: string, uid: string): Promise<void> {
  const snap = await db.collection(collection).where(field, "==", uid).get();
  if (snap.empty) return;
  const batch = db.batch();
  snap.docs.forEach((doc) => batch.delete(doc.ref));
  await batch.commit();
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
    ]);

    // ── Remove membership from tribes (update, not delete) ──
    const tribesSnap = await db
      .collection("tribes")
      .where("members", "array-contains", uid)
      .get();
    if (!tribesSnap.empty) {
      const batch = db.batch();
      tribesSnap.docs.forEach((doc) => {
        batch.update(doc.ref, {
          members: admin.firestore.FieldValue.arrayRemove(uid),
          memberCount: admin.firestore.FieldValue.increment(-1),
        });
      });
      await batch.commit();
    }

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
