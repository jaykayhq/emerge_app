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

const DEFAULT_XP_CONFIG: Record<string, number> = {
  habit_completion: 10,
  joined_challenge: 25,
  joined_tribe: 50,
  reflection_saved: 15,
};

const MAX_STREAK_BONUS = 0.5; // Match 50% max bonus

// Global cache for XP_CONFIG
let cachedXpConfig: Record<string, number> | null = null;
let lastXpConfigFetchTime = 0;
const XP_CONFIG_CACHE_TTL_MS = 1000 * 60 * 5; // 5 minutes cache

/**
 * Fetches the XP configuration from Firestore with in-memory caching.
 * @param {admin.firestore.Firestore} firestore - The Firestore instance.
 * @return {Promise<Record<string, number>>} The XP configuration.
 */
async function getXpConfig(
  firestore: admin.firestore.Firestore
): Promise<Record<string, number>> {
  const now = Date.now();
  if (cachedXpConfig && now - lastXpConfigFetchTime < XP_CONFIG_CACHE_TTL_MS) {
    return cachedXpConfig;
  }

  try {
    const docRef = await firestore
      .collection("config")
      .doc("xp_settings")
      .get();
    if (docRef.exists) {
      cachedXpConfig = docRef.data() as Record<string, number>;
      lastXpConfigFetchTime = now;
      return cachedXpConfig;
    }
  } catch (err) {
    console.error("Error fetching XP config:", err);
  }

  // Fallback to default and don't cache failure heavily to allow recovery
  return DEFAULT_XP_CONFIG;
}

interface UserActivity {
  userId: string;
  habitId?: string;
  type: string;
  difficulty?: "easy" | "medium" | "hard";
  attribute?: string;
  streakDay?: number;
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
 * @param {Record<string, number>} xpConfig - The XP configuration mapping.
 * @return {number} The XP to be awarded.
 */
function calculateXpGain(
  activity: UserActivity,
  xpConfig: Record<string, number>
): number {
  const baseXp = xpConfig[activity.type] || 0;
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

    const xpConfig = await getXpConfig(firestore);
    const xpGain = calculateXpGain(activity, xpConfig);
    if (xpGain === 0) return null;

    const statsRef = firestore.collection("user_stats").doc(activity.userId);

    return firestore.runTransaction(
      async (transaction: admin.firestore.Transaction) => {
        const statsDoc = await transaction.get(statsRef);
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        const currentData = statsDoc.exists ? (statsDoc.data() as any) : {};

        // Get current avatarStats or initialize empty
        const currentAvatarStats = currentData.avatarStats || {};

        // Calculate new values
        const currentTotalXp = currentAvatarStats.totalXp || 0;
        const newTotalXp = currentTotalXp + xpGain;

        // Calculate global streak and update lastActiveDate
        let newStreak = currentAvatarStats.streak || 0;
        let newLastActiveDate = null;
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        let worldStateUpdates: any = null;

        if (activity.type === "habit_completion") {
          const currentWorldState = currentData.worldState || {};
          const lastActiveDate = currentWorldState.lastActiveDate as
            | admin.firestore.Timestamp
            | undefined;
          const now = admin.firestore.Timestamp.now();
          const nowDate = now.toDate();

          if (lastActiveDate) {
            const lastDate = lastActiveDate.toDate();

            // Use YYYY-MM-DD for simple UTC day comparisons
            const lastDateStr = lastDate.toISOString().split("T")[0];
            const todayStr = nowDate.toISOString().split("T")[0];

            const yesterday = new Date(nowDate);
            yesterday.setUTCDate(yesterday.getUTCDate() - 1);
            const yesterdayStr = yesterday.toISOString().split("T")[0];

            if (lastDateStr === yesterdayStr) {
              newStreak += 1; // Continued streak
            } else if (lastDateStr !== todayStr && lastDateStr < yesterdayStr) {
              newStreak = 1; // Missed a day, reset and start over
            }
            // If lastDateStr === todayStr, streak remains the same (already counted for today)
          } else {
            newStreak = 1; // First habit completion ever
          }

          newLastActiveDate = admin.firestore.FieldValue.serverTimestamp();
          worldStateUpdates = {
            ...currentWorldState,
            lastActiveDate: newLastActiveDate,
          };
        }

        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        const updates: any = {
          avatarStats: {
            ...currentAvatarStats,
            totalXp: newTotalXp,
            streak: newStreak,
            lastUpdate: admin.firestore.FieldValue.serverTimestamp(),
          },
        };

        if (worldStateUpdates) {
          updates.worldState = worldStateUpdates;
        }

        // Update specific attribute XP
        if (activity.attribute) {
          const attrXpKey = `${activity.attribute}Xp`;
          const currentAttrXp = (currentAvatarStats[attrXpKey] as number) || 0;
          updates.avatarStats[attrXpKey] = currentAttrXp + xpGain;
        }

        // Update level if needed
        const newLevel = calculateLevel(newTotalXp);
        if (newLevel !== (currentAvatarStats.level || 1)) {
          updates.avatarStats.level = newLevel;
        }

        transaction.set(statsRef, updates, { merge: true });
      }
    );
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
    const CACHE_DURATION_MS = parseInt(process.env.INSIGHT_CACHE_DURATION_MS || "900000"); // Default: 15 minutes

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
  // Support both new nested structure (avatarStats) and legacy root fields
  const avatarStats = stats.avatarStats || {};
  const level = avatarStats.level || stats.level || 1;
  const streak = avatarStats.streak || stats.streak || 0;

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
// AI COACH - GROQ PROXY (Callable — no CORS issues)
// ============================================================================

/**
 * Firebase Callable function that proxies requests to the Groq AI API.
 * Using a callable instead of an HTTP function means CORS is handled
 * automatically by the Firebase SDK on both web and mobile clients.
 */
export const getGroqCoachAdvice = functionsV1.runWith({
  secrets: ["GROQ_API_KEY"],
}).https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functionsV1.https.HttpsError(
        "unauthenticated",
        "User must be logged in to use the AI coach."
      );
    }

    const { userContext, userMessage } = data as {
      userContext?: string;
      userMessage?: string;
    };

    if (!userMessage) {
      throw new functionsV1.https.HttpsError(
        "invalid-argument",
        "userMessage is required."
      );
    }

    const groqApiKey = process.env.GROQ_API_KEY;
    if (!groqApiKey) {
      console.warn("GROQ_API_KEY not configured. Returning fallback response.");
      return { advice: "Keep building consistent habits — progress over perfection." };
    }

    try {
      const payload = {
        model: "llama3-8b-8192",
        messages: [
          {
            role: "system",
            content:
              userContext ||
              "You are a motivational habit coach. Be concise and encouraging. Max 2 sentences.",
          },
          {
            role: "user",
            content: userMessage,
          },
        ],
        max_tokens: 256,
        temperature: 0.7,
      };

      const response = await fetch("https://api.groq.com/openai/v1/chat/completions", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${groqApiKey}`,
        },
        body: JSON.stringify(payload),
      });

      if (!response.ok) {
        const errorText = await response.text();
        console.error(`Groq API error ${response.status}: ${errorText}`);
        return { advice: "Your consistency is your superpower. Keep going!" };
      }

      const result = (await response.json()) as {
        choices?: { message?: { content?: string } }[];
      };
      const advice =
        result.choices?.[0]?.message?.content?.trim() ??
        "Every small step counts. Stay the course!";

      return { advice };
    } catch (error) {
      console.error("Groq proxy error:", error);
      return { advice: "Focus on progress, not perfection. You've got this!" };
    }
  }
);

// ============================================================================
// SUB-MODULE EXPORTS
// ============================================================================
export * from "./challenges";
export * from "./seed_templates";
export * from "./refreshQuarterlyChallenges";
export * from "./revenuecat_webhook";
export * from "./habit_notifications";
export * from "./seedReviewerAccount";
export * from "./accountDeletion";
export * from "./rateLimiter";
export * from "./ai_recap";

// ============================================================================
// DAILY MOMENTUM DECAY (Behavioral Entropy Engine)
// ============================================================================

/**
 * Daily scheduled function: applies momentum decay to all habits
 * that were NOT completed today. This is the core of the behavioral
 * entropy system — without it, momentum only ever increases.
 *
 * Runs at 02:00 UTC daily (after midnight in most user timezones).
 */
export const applyDailyMomentumDecay = functionsV1.pubsub
  .schedule("0 2 * * *")
  .timeZone("UTC")
  .onRun(async (context) => {
    console.log("Daily momentum decay starting at:", context.timestamp);
    const firestore = getDb();
    const today = new Date(context.timestamp);
    const todayStr = today.toISOString().split("T")[0];

    // Query all non-archived habits
    const habitsSnap = await firestore
      .collection("habits")
      .where("isArchived", "==", false)
      .get();

    if (habitsSnap.empty) {
      console.log("No active habits to process.");
      return null;
    }

    const BATCH_SIZE = 450; // Firestore batch limit is 500
    let batch = firestore.batch();
    let batchCount = 0;
    let decayedCount = 0;
    let skippedCount = 0;

    for (const doc of habitsSnap.docs) {
      const data = doc.data();
      const lastCompletedDate = data.lastCompletedDate as
        | admin.firestore.Timestamp
        | undefined;

      // Check if habit was completed today
      let completedToday = false;
      if (lastCompletedDate) {
        const lastDateStr = lastCompletedDate.toDate().toISOString().split("T")[0];
        completedToday = lastDateStr === todayStr;
      }

      if (completedToday) {
        skippedCount++;
        continue; // No decay — user completed the habit today
      }

      // Apply decay: miss penalty if consecutiveMisses > 0, else idle penalty
      const currentMomentum = (data.momentumScore as number) ?? 0;
      const consecutiveMisses = (data.consecutiveMisses as number) ?? 0;
      const contractActive = (data.contractActive as boolean) ?? false;

      // Penalty: 15 for missed contract, else standard (5 for miss, 2 for idle)
      const missDecay = contractActive ? 15 : (consecutiveMisses > 0 ? 5 : 2);
      const newMomentum = Math.max(0, currentMomentum - missDecay);
      const newConsecutiveMisses = consecutiveMisses + 1;

      batch.update(doc.ref, {
        momentumScore: newMomentum,
        consecutiveMisses: newConsecutiveMisses,
      });

      // SOCIAL CONTRACT ENFORCEMENT: XP and Entropy Penalties
      // Only trigger on the FIRST day a contract is broken (consecutiveMisses transitions 0 -> 1)
      if (contractActive && consecutiveMisses === 0) {
        const userId = data.userId;
        const statsRef = firestore.collection("user_stats").doc(userId);
        
        // We'll use a separate set operation for stats to avoid complex transaction 
        // logic inside a loop, but in a production environment with high concurrency, 
        // a transaction or specific increment field would be preferred.
        // For now, we use FieldValue.increment for safety.
        
        // XP Penalty: -5% of current level XP (approx level * 500 * 0.05)
        // Since we don't have the level here without a read, we'll fetch or use a safe heuristic.
        // Better: Fetch user_stats for broken contracts.
        try {
          const statsDoc = await statsRef.get();
          if (statsDoc.exists) {
            const statsData = statsDoc.data()!;
            const level = statsData.avatarStats?.level ?? 1;
            const currentTotalXp = statsData.avatarStats?.totalXp ?? 0;
            const xpLoss = Math.floor(level * 500 * 0.05);
            const levelMinXp = (level - 1) * 500;
            const newTotalXp = Math.max(levelMinXp, currentTotalXp - xpLoss);

            batch.update(statsRef, {
              "avatarStats.totalXp": newTotalXp,
              "worldState.entropy": admin.firestore.FieldValue.increment(0.1),
              "worldState.activeEvents": admin.firestore.FieldValue.arrayUnion({
                type: "contract_broken",
                timestamp: admin.firestore.FieldValue.serverTimestamp(),
                habitId: doc.id,
                title: "Identity Breach",
                description: `Social contract for '${data.title}' broken. Identity stability compromised.`
              })
            });
          }
        } catch (err) {
          console.error(`Error applying contract penalty for user ${userId}:`, err);
        }
      }

      decayedCount++;
      batchCount++;

      // Commit batch when approaching limit
      if (batchCount >= BATCH_SIZE) {
        await batch.commit();
        batch = firestore.batch();
        batchCount = 0;
        console.log(`Committed batch of ${BATCH_SIZE} decay updates.`);
      }
    }

    // Commit final batch
    if (batchCount > 0) {
      await batch.commit();
    }

    console.log(
      `Momentum decay complete. Decayed: ${decayedCount}, Skipped (completed today): ${skippedCount}`
    );
    return null;
  });

