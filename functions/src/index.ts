/**
 * Firebase Cloud Functions - Emerge App (Gen 1)
 *
 * Cost-optimized for scale:
 * - Single XP/Level trigger (no duplicates)
 * - Batched operations where possible
 * - Minimal reads per invocation
 * - Lazy initialization to avoid deployment timeouts
 */

import * as functionsV1 from "firebase-functions/v1";
import * as admin from "firebase-admin";

// Lazy initialization pattern
let db: admin.firestore.Firestore | null = null;

/**
 * Lazy-loads the Firestore database instance.
 * @return {admin.firestore.Firestore} The Firestore instance.
 */
function getDb(): admin.firestore.Firestore {
  if (!db) {
    if (admin.apps.length === 0) {
      admin.initializeApp();
    }
    db = admin.firestore();
  }
  return db;
}

// ============================================================================
// XP & LEVEL CONFIGURATION
// ============================================================================

const XP_CONFIG: Record<string, number> = {
  habit_completion: 10,
  joined_challenge: 25,
  joined_tribe: 50,
  reflection_saved: 15,
};

const MAX_STREAK_BONUS = 0.5; // Match 50% max bonus

interface UserActivity {
  userId: string;
  habitId?: string;
  type: string;
  difficulty?: "easy" | "medium" | "hard";
  attribute?: string;
  streakDay?: number;
}

interface AvatarStats {
  strengthXp?: number;
  intellectXp?: number;
  vitalityXp?: number;
  creativityXp?: number;
  focusXp?: number;
  spiritXp?: number;
  level?: number;
  streak?: number;
  totalXp?: number;
  lastUpdate?: admin.firestore.FieldValue;
  [key: string]: number | admin.firestore.FieldValue | undefined;
}

/**
 * Calculates user level using 500 XP linear scaling.
 * @param {number} totalXp - The total experience points.
 * @return {number} The calculated level.
 */
function calculateLevel(totalXp: number): number {
  return Math.floor(totalXp / 500) + 1;
}

/**
 * Calculates XP gain for a given user activity.
 * @param {UserActivity} activity - The activity data.
 * @return {number} The XP to be awarded.
 */
function calculateXpGain(activity: UserActivity): number {
  const baseXp = XP_CONFIG[activity.type] || 0;
  if (baseXp === 0) return 0;

  let xp = baseXp;

  // Apply difficulty multiplier for habits
  if (activity.type === "habit_completion" && activity.difficulty) {
    const isHard = activity.difficulty === "hard";
    const isMedium = activity.difficulty === "medium";
    const mult = isHard ? 3.0 : (isMedium ? 2.0 : 1.0);
    xp = Math.round(baseXp * mult);
  }

  // Apply streak bonus (+10% every 7 days, capped at 50%)
  if (activity.streakDay && activity.streakDay >= 7) {
    const streakMultSteps = Math.floor(activity.streakDay / 7);
    const streakBonus = Math.min(streakMultSteps * 0.1, MAX_STREAK_BONUS);
    xp = Math.round(xp * (1 + streakBonus));
  }

  return xp;
}

/**
 * Main trigger: Updates user stats when activity is logged
 */
export const onUserActivityCreated = functionsV1.firestore
  .document("user_activity/{activityId}")
  .onCreate(async (snapshot, context) => {
    const activity = snapshot.data() as UserActivity;
    const firestore = getDb();

    if (!activity.userId || !activity.type) {
      console.warn(`Invalid activity: ${context.params.activityId}`);
      return null;
    }

    const xpGain = calculateXpGain(activity);
    if (xpGain === 0) return null;

    const statsRef = firestore.collection("user_stats").doc(activity.userId);

    return firestore.runTransaction(async (transaction) => {
      const statsDoc = await transaction.get(statsRef);
      const currentStats = statsDoc.exists ? (statsDoc.data() as AvatarStats) : {};

      const updates: AvatarStats = {
        totalXp: (currentStats.totalXp || 0) + xpGain,
        lastUpdate: admin.firestore.FieldValue.serverTimestamp(),
      };

      if (activity.attribute) {
        const attrXpKey = `${activity.attribute}Xp`;
        const currentAttrXp = (currentStats[attrXpKey] as number) || 0;
        updates[attrXpKey] = currentAttrXp + xpGain;
      }

      const newLevel = calculateLevel(updates.totalXp as number);
      if (newLevel !== currentStats.level) {
        updates.level = newLevel;
      }

      transaction.set(statsRef, updates, { merge: true });
    });
  });

/**
 * Provides personalized aura insights based on user stats.
 */
export const getAuraInsight = functionsV1.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functionsV1.https.HttpsError("unauthenticated", "User must be logged in");
  }

  const userId = context.auth.uid;
  const firestore = getDb();

  // Check cache first to reduce reads
  const cacheDoc = await firestore.collection("insight_cache").doc(userId).get();

  if (cacheDoc.exists) {
    const cacheData = cacheDoc.data()!;
    const now = Date.now();
    const CACHE_DURATION_MS = 15 * 60 * 1000; // 15 minutes

    if (cacheData.timestamp && (now - cacheData.timestamp.toDate().getTime()) < CACHE_DURATION_MS) {
      return {
        insight: cacheData.insight,
        level: cacheData.level,
        streak: cacheData.streak
      };
    }
  }

  const userStatsDoc = await firestore.collection("user_stats").doc(userId).get();

  if (!userStatsDoc.exists) {
    return { insight: "Start your journey by completing your first habit!", level: 1, streak: 0 };
  }

  const stats = userStatsDoc.data()!;
  const level = stats.level || 1;
  const streak = stats.streak || 0;

  let insight = "";
  if (streak >= 7) {
    insight = `Amazing! Your ${streak}-day streak shows real commitment.`;
  } else if (streak >= 3) {
    insight = `${streak} days strong! Keep building momentum.`;
  } else if (level > 1) {
    insight = `Level ${level} achieved! Progress over perfection.`;
  } else {
    insight = "Every expert was once a beginner. Start with one habit.";
  }

  // Cache the result
  const result = { insight, level, streak };
  await firestore.collection("insight_cache").doc(userId).set({
    ...result,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });

  return result;
});

/**
 * Reset daily challenges/status at midnight UTC
 */
export const resetDailyChallengesOptimized = functionsV1.pubsub
  .schedule("0 0 * * *")
  .timeZone("UTC")
  .onRun(async (context) => {
    console.log("Resetting daily challenges status at:", context.timestamp);
    // Add logic here if global challenge resets are needed
    return null;
  });

// ============================================================================
// SUB-MODULE EXPORTS
// ============================================================================
export * from "./challenges";
export * from "./seed_templates";
export * from "./generateWeeklyChallenge";
export * from "./refreshQuarterlyChallenges";
export * from "./revenuecat_webhook";
