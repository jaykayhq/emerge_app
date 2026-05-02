import { onDocumentCreated } from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";

// Ensure admin is initialized
if (admin.apps.length === 0) {
  admin.initializeApp();
}

/**
 * Monitors habit completions and enforces rate limiting via custom claims (Gen 2).
 * This prevents users from spamming completions to artificially inflate stats.
 */
export const enforceRateLimit = onDocumentCreated(
  "users/{userId}/habits/{habitId}/completions/{completionId}",
  async (event) => {
    const userId = event.params.userId;
    const db = admin.firestore();

    try {
      // 1. Get recent completions count (last 24 hours)
      const oneDayAgo = new Date();
      oneDayAgo.setDate(oneDayAgo.getDate() - 1);

      const completionsSnapshot = await db
        .collection("users")
        .doc(userId)
        .collection("habits")
        .doc(event.params.habitId)
        .collection("completions")
        .where("timestamp", ">", oneDayAgo)
        .get();

      const completionCount = completionsSnapshot.size;

      // 2. If count exceeds limit (e.g., 50 completions per day per habit)
      if (completionCount > 50) {
        console.warn(`Rate limit exceeded for user ${userId} on habit ${event.params.habitId}`);

        // Set a custom claim to flag the user for review
        const auth = admin.auth();
        const user = await auth.getUser(userId);
        const currentClaims = user.customClaims || {};

        await auth.setCustomUserClaims(userId, {
          ...currentClaims,
          rateLimited: true,
          flaggedAt: new Date().toISOString(),
        });

        // Log to security collection
        await db.collection("security_logs").add({
          userId: userId,
          type: "rate_limit_exceeded",
          habitId: event.params.habitId,
          count: completionCount,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
    } catch (error) {
      console.error(`Error enforcing rate limit for user ${userId}:`, error);
    }
  }
);
