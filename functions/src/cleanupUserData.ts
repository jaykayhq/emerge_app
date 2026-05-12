import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

if (admin.apps.length === 0) {
  admin.initializeApp();
}

const db = admin.firestore();

/**
 * Callable function: Deletes the calling user's Auth account and
 * ALL associated data across Firestore collections.
 *
 * Called from the app when user taps "Delete Account".
 * Uses Admin SDK to bypass security rules.
 */
export const deleteMyAccount = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "You must be logged in to delete your account.");
  }

  const uid = request.auth.uid;
  console.log(`deleteMyAccount: Starting cleanup for user ${uid}`);

  // ── Step 1: Delete user document + all subcollections ──
  // recursiveDelete handles: friends/*, challenges/*, tribes/*,
  // achievements/*, notificationSchedules/*, presence/*,
  // habit_completions/*, etc.
  await db.recursiveDelete(db.collection("users").doc(uid));

  // ── Step 2: Delete user_stats + subcollections ──
  await db.recursiveDelete(db.collection("user_stats").doc(uid));

  // ── Step 3: Cached insight ──
  await db.collection("insight_cache").doc(uid).delete().catch(() => {});

  // ── Step 4: RevenueCat customer data ──
  await db.collection("customers").doc(uid).delete().catch(() => {});

  // ── Step 5: Top-level habits ──
  const habitsSnap = await db
    .collection("habits")
    .where("userId", "==", uid)
    .get();
  if (!habitsSnap.empty) {
    const batch = db.batch();
    habitsSnap.docs.forEach((doc: admin.firestore.QueryDocumentSnapshot) => batch.delete(doc.ref));
    await batch.commit();
  }

  // ── Step 6: user_activity ──
  const activitySnap = await db
    .collection("user_activity")
    .where("userId", "==", uid)
    .get();
  if (!activitySnap.empty) {
    const batch = db.batch();
    activitySnap.docs.forEach((doc: admin.firestore.QueryDocumentSnapshot) => batch.delete(doc.ref));
    await batch.commit();
  }

  // ── Step 7: global_activities ──
  const globalSnap = await db
    .collection("global_activities")
    .where("userId", "==", uid)
    .get();
  if (!globalSnap.empty) {
    const batch = db.batch();
    globalSnap.docs.forEach((doc: admin.firestore.QueryDocumentSnapshot) => batch.delete(doc.ref));
    await batch.commit();
  }

  // ── Step 8: Remove from tribes ──
  const tribesSnap = await db
    .collection("tribes")
    .where("members", "array-contains", uid)
    .get();
  if (!tribesSnap.empty) {
    const batch = db.batch();
    tribesSnap.docs.forEach((doc: admin.firestore.QueryDocumentSnapshot) => {
      batch.update(doc.ref, {
        members: admin.firestore.FieldValue.arrayRemove(uid),
        memberCount: admin.firestore.FieldValue.increment(-1),
      });
    });
    await batch.commit();
  }

  // ── Step 9: club_leaderboards ──
  const clubLbSnap = await db.collection("club_leaderboards").get();
  if (!clubLbSnap.empty) {
    const batch = db.batch();
    clubLbSnap.docs.forEach((doc: admin.firestore.QueryDocumentSnapshot) => {
      if (doc.data().userId === uid) batch.delete(doc.ref);
    });
    await batch.commit();
  }

  // ── Step 10: challenge_leaderboards ──
  const chalLbSnap = await db.collection("challenge_leaderboards").get();
  if (!chalLbSnap.empty) {
    const batch = db.batch();
    chalLbSnap.docs.forEach((doc: admin.firestore.QueryDocumentSnapshot) => {
      if (doc.data().userId === uid) batch.delete(doc.ref);
    });
    await batch.commit();
  }

  // ── Step 11: contracts (userId or partnerId) ──
  for (const field of ["userId", "partnerId"] as const) {
    const snap = await db.collection("contracts").where(field, "==", uid).get();
    if (!snap.empty) {
      const batch = db.batch();
      snap.docs.forEach((doc: admin.firestore.QueryDocumentSnapshot) => batch.delete(doc.ref));
      await batch.commit();
    }
  }

  // ── Step 12: partner_requests ──
  for (const field of ["senderId", "recipientId"] as const) {
    const snap = await db.collection("partner_requests").where(field, "==", uid).get();
    if (!snap.empty) {
      const batch = db.batch();
      snap.docs.forEach((doc: admin.firestore.QueryDocumentSnapshot) => batch.delete(doc.ref));
      await batch.commit();
    }
  }

  // ── Step 13: security_logs ──
  const secSnap = await db
    .collection("security_logs")
    .where("userId", "==", uid)
    .get();
  if (!secSnap.empty) {
    const batch = db.batch();
    secSnap.docs.forEach((doc: admin.firestore.QueryDocumentSnapshot) => batch.delete(doc.ref));
    await batch.commit();
  }

  // ── Step 14: revenuecat_events ──
  const rcSnap = await db
    .collection("revenuecat_events")
    .where("app_user_id", "==", uid)
    .get();
  if (!rcSnap.empty) {
    const batch = db.batch();
    rcSnap.docs.forEach((doc: admin.firestore.QueryDocumentSnapshot) => batch.delete(doc.ref));
    await batch.commit();
  }

  // ── Step 15: Delete the Firebase Auth user last ──
  try {
    await admin.auth().deleteUser(uid);
  } catch (authErr) {
    console.error(`deleteMyAccount: Failed to delete auth user ${uid}:`, authErr);
    // Don't throw — data is already cleaned up
  }

  console.log(`deleteMyAccount: Finished cleanup for user ${uid}`);
  return { success: true };
});
