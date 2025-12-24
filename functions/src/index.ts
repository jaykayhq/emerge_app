/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";

admin.initializeApp();

// Start writing functions
// https://firebase.google.com/docs/functions/typescript

// For cost control, you can set the maximum number of containers that can be
// running at the same time. This helps mitigate the impact of unexpected
// traffic spikes by instead downgrading performance. This limit is a
// per-function limit. You can override the limit for each function using the
// `maxInstances` option in the function's options, e.g.
// `onRequest({ maxInstances: 5 }, (req, res) => { ... })`.
// NOTE: setGlobalOptions does not apply to functions using the v1 API. V1
// functions should each use functions.runWith({ maxInstances: 10 }) instead.
// In the v1 API, each function can only serve one request per container, so
// this will be the maximum concurrent request count.
// setGlobalOptions({ maxInstances: 10 });

/**
 * Triggered when a new user is created in Firebase Auth.
 * Initializes the user_stats document in Firestore.
 */
export const onUserCreated = functions.auth.user().onCreate(async (user) => {
  const db = admin.firestore();
  const userStatsRef = db.collection("user_stats").doc(user.uid);

  try {
    await userStatsRef.set({
      currentXp: 0,
      currentLevel: 1,
      currentStreak: 0,
      unlockedBadges: [],
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    console.log(`Initialized user_stats for user ${user.uid}`);
  } catch (error) {
    console.error(`Error initializing user_stats for user ${user.uid}:`, error);
  }
});

export * from "./triggers/activity_triggers";
