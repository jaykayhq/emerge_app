import { onDocumentCreated, onDocumentWritten } from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";

const db = admin.firestore();

/**
 * Trigger: When a user's challenge membership changes (Joined or Left)
 */
export const onChallengeMembershipChanged = onDocumentWritten("users/{userId}/challenges/{challengeId}", async (event) => {
  const { challengeId, userId } = event.params;
  const before = event.data?.before.exists;
  const after = event.data?.after.exists;

  if (!before && after) {
    // Joined
    console.log(`User ${userId} joined challenge ${challengeId}`);
    try {
      await db.collection("challenges").doc(challengeId).update({
        participants: admin.firestore.FieldValue.increment(1),
      });
    } catch (error) {
      console.error("Error incrementing participant count:", error);
    }
  } else if (before && !after) {
    // Left
    console.log(`User ${userId} left challenge ${challengeId}`);
    try {
      await db.collection("challenges").doc(challengeId).update({
        participants: admin.firestore.FieldValue.increment(-1),
      });
    } catch (error) {
      console.error("Error decrementing participant count:", error);
    }
  }
  return;
});

/**
 * Trigger: When a new challenge request is created (Gen 2)
 */
export const onChallengeRequestCreated = onDocumentCreated("challenge_requests/{requestId}", async (event) => {
  const request = event.data?.data();
  if (!request) return;

  // Logic for notifications would go here
  console.log(`Challenge request created: ${event.params.requestId}`);
  return;
});

