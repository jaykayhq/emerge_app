import * as functionsV1 from "firebase-functions/v1";
import * as admin from "firebase-admin";

/**
 * Tracks user writes and sets a rateLimitUntil custom claim if they exceed
 * the allowed 10 writes per minute.
 */
export const manageRateLimit = functionsV1.firestore
  .document("posts/{postId}")
  .onWrite(async (change, context) => {
    const data = change.after.exists ?
      change.after.data() : change.before.data();
    const userId = data?.userId;

    if (!userId) {
      console.warn(`No userId found for post ${context.params.postId}`);
      return null;
    }

    const db = admin.firestore();
    const trackerRef = db.collection("rate_limits").doc(userId);

    try {
      await db.runTransaction(async (t: admin.firestore.Transaction) => {
        const doc = await t.get(trackerRef);
        const now = Date.now();
        let count = 1;
        let windowStart = now;

        if (doc.exists) {
          const tracker = doc.data()!;
          if (now - tracker.windowStart < 60000) {
            count = (tracker.count || 0) + 1;
            windowStart = tracker.windowStart;
          }
        }

        t.set(trackerRef, { count, windowStart });

        if (count > 10) {
          const user = await admin.auth().getUser(userId);
          const currentClaims = user.customClaims || {};
          const currentLimit = currentClaims.rateLimitUntil || 0;

          // Only update the claim if we haven't already set a future limit
          if (currentLimit < now) {
            const rateLimitUntil = now + 60000; // Block for 1 minute
            await admin.auth().setCustomUserClaims(userId, {
              ...currentClaims,
              rateLimitUntil,
            });
            console.log(
              `Rate limit exceeded for user ${userId}. Claim updated.`
            );
          }
        }
      });
    } catch (error) {
      console.error(`Error managing rate limit for user ${userId}:`, error);
    }

    return null;
  });
