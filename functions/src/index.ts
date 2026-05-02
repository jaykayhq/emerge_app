/**
 * Firebase Cloud Functions - Emerge App (Gen 2)
 *
 * Cost-optimized for scale:
 * - Gen 2 concurrency enabled
 * - Managed Secrets for Groq API
 * - Shorter cold starts via global options
 */

import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { setGlobalOptions } from "firebase-functions/v2";
import * as admin from "firebase-admin";
import { sendNotification, getTemplateMessage } from "./habit_notifications";

// Global configuration for all v2 functions
setGlobalOptions({
  maxInstances: 5,
  region: "us-central1",
  memory: "256MiB",
  cpu: 0.1,
});

// Initialize Admin SDK once
if (admin.apps.length === 0) {
  admin.initializeApp();
}

const db = admin.firestore();

// ============================================================================
// XP & LEVEL CONFIGURATION
// ============================================================================

const DEFAULT_XP_CONFIG: Record<string, number> = {
  habit_completion: 10,
  joined_challenge: 25,
  joined_tribe: 50,
  reflection_saved: 15,
};

const MAX_STREAK_BONUS = 0.5;

// Global cache for XP_CONFIG
let cachedXpConfig: Record<string, number> | null = null;
let lastXpConfigFetchTime = 0;
const XP_CONFIG_CACHE_TTL_MS = 1000 * 60 * 5;

/**
 * Fetches the XP configuration from Firestore with in-memory caching.
 */
async function getXpConfig(): Promise<Record<string, number>> {
  const now = Date.now();
  if (cachedXpConfig && now - lastXpConfigFetchTime < XP_CONFIG_CACHE_TTL_MS) {
    return cachedXpConfig;
  }

  try {
    const docRef = await db.collection("config").doc("xp_settings").get();
    if (docRef.exists) {
      cachedXpConfig = docRef.data() as Record<string, number>;
      lastXpConfigFetchTime = now;
      return cachedXpConfig;
    }
  } catch (err) {
    console.error("Error fetching XP config:", err);
  }
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

function calculateLevel(totalXp: number): number {
  return Math.floor(totalXp / 500) + 1;
}

function calculateXpGain(
  activity: UserActivity,
  xpConfig: Record<string, number>
): number {
  const baseXp = xpConfig[activity.type] || 0;
  if (baseXp === 0) return 0;

  let xp = baseXp;
  if (activity.type === "habit_completion" && activity.difficulty) {
    const isHard = activity.difficulty === "hard";
    const isMedium = activity.difficulty === "medium";
    const mult = isHard ? 3.0 : (isMedium ? 2.0 : 1.0);
    xp = Math.round(baseXp * mult);
  }

  if (activity.streakDay && activity.streakDay >= 7) {
    const streakMultSteps = Math.floor(activity.streakDay / 7);
    const streakBonus = Math.min(streakMultSteps * 0.1, MAX_STREAK_BONUS);
    xp = Math.round(xp * (1 + streakBonus));
  }
  return xp;
}

/**
 * Main trigger: Updates user stats when activity is logged (Gen 2)
 */
export const onUserActivityCreated = onDocumentCreated("user_activity/{activityId}", async (event) => {
  const activity = event.data?.data() as UserActivity;
  if (!activity || !activity.userId || !activity.type) {
    console.warn(`Invalid activity document: ${event.params.activityId}`);
    return;
  }

  const xpConfig = await getXpConfig();
  const xpGain = calculateXpGain(activity, xpConfig);
  if (xpGain === 0) return;

  const statsRef = db.collection("user_stats").doc(activity.userId);

  return db.runTransaction(async (transaction: any) => {
    const statsDoc = await transaction.get(statsRef);
    const currentData = statsDoc.exists ? (statsDoc.data() as any) : {};
    const currentAvatarStats = currentData.avatarStats || {};

    const currentTotalXp = currentAvatarStats.totalXp || 0;
    const newTotalXp = currentTotalXp + xpGain;

    let newStreak = currentAvatarStats.streak || 0;
    let worldStateUpdates: any = null;

    if (activity.type === "habit_completion") {
      const currentWorldState = currentData.worldState || {};
      const lastActiveDate = currentWorldState.lastActiveDate as admin.firestore.Timestamp | undefined;
      const now = admin.firestore.Timestamp.now();
      const nowDate = now.toDate();

      if (lastActiveDate) {
        const lastDate = lastActiveDate.toDate();
        const lastDateStr = lastDate.toISOString().split("T")[0];
        const todayStr = nowDate.toISOString().split("T")[0];
        const yesterday = new Date(nowDate);
        yesterday.setUTCDate(yesterday.getUTCDate() - 1);
        const yesterdayStr = yesterday.toISOString().split("T")[0];

        if (lastDateStr === yesterdayStr) {
          newStreak += 1;
        } else if (lastDateStr !== todayStr && lastDateStr < yesterdayStr) {
          newStreak = 1;
        }
      } else {
        newStreak = 1;
      }

      worldStateUpdates = {
        ...currentWorldState,
        lastActiveDate: admin.firestore.FieldValue.serverTimestamp(),
      };
    }

    const updates: any = {
      avatarStats: {
        ...currentAvatarStats,
        totalXp: newTotalXp,
        streak: newStreak,
        lastUpdate: admin.firestore.FieldValue.serverTimestamp(),
      },
    };

    if (worldStateUpdates) updates.worldState = worldStateUpdates;

    if (activity.attribute) {
      const attrXpKey = `${activity.attribute}Xp`;
      const currentAttrXp = (currentAvatarStats[attrXpKey] as number) || 0;
      updates.avatarStats[attrXpKey] = currentAttrXp + xpGain;
    }

    const calculatedLevel = calculateLevel(newTotalXp);
    if (calculatedLevel !== (currentAvatarStats.level || 1)) {
      updates.avatarStats.level = calculatedLevel;
    }

    transaction.set(statsRef, updates, { merge: true });

    // Handle Level Up Notification (Consolidated from onLevelUp)
    const notifiedLevel = updates.avatarStats.level;
    if (notifiedLevel && notifiedLevel !== (currentAvatarStats.level || 1)) {
      (async () => {
        try {
          const userDoc = await db.collection("users").doc(activity.userId).get();
          const userData = userDoc.data();
          const archetype = userData?.archetype || "none";
          
          // Consolidated from onLevelUp: Send notification
          const body = getTemplateMessage(archetype, "levelUp", notifiedLevel);
          await sendNotification(activity.userId, "Level Up!", body, "level_up", {
            level: notifiedLevel.toString(),
          });
          console.log(`Level up notification sent for user ${activity.userId}: ${notifiedLevel}`);
        } catch (err) {
          console.error("Error in level up notification:", err);
        }
      })();
    }
  });
});

/**
 * Provides personalized aura insights (Gen 2)
 */
export const getAuraInsight = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be logged in");
  }

  const userId = request.auth.uid;
  const cacheDoc = await db.collection("insight_cache").doc(userId).get();

  if (cacheDoc.exists) {
    const cacheData = cacheDoc.data()!;
    const now = Date.now();
    const CACHE_DURATION_MS = 900000; // 15 mins

    if (cacheData.timestamp && (now - cacheData.timestamp.toDate().getTime()) < CACHE_DURATION_MS) {
      return {
        insight: cacheData.insight,
        level: cacheData.level,
        streak: cacheData.streak
      };
    }
  }

  const userStatsDoc = await db.collection("user_stats").doc(userId).get();
  if (!userStatsDoc.exists) {
    return { insight: "Start your journey by completing your first habit!", level: 1, streak: 0 };
  }

  const stats = userStatsDoc.data()!;
  const avatarStats = stats.avatarStats || {};
  const level = avatarStats.level || stats.level || 1;
  const streak = avatarStats.streak || stats.streak || 0;

  let insight = "";
  if (streak >= 7) insight = `Amazing! Your ${streak}-day streak shows real commitment.`;
  else if (streak >= 3) insight = `${streak} days strong! Keep building momentum.`;
  else if (level > 1) insight = `Level ${level} achieved! Progress over perfection.`;
  else insight = "Every expert was once a beginner. Start with one habit.";

  const result = { insight, level, streak };
  await db.collection("insight_cache").doc(userId).set({
    ...result,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });

  return result;
});

/*
export const resetDailyChallengesOptimized = onSchedule("0 0 * * *", async () => {
  console.log("Resetting daily challenges status at midnight UTC");
});
*/

/**
 * AI Coach - Groq Proxy (Gen 2)
 */
export const getGroqCoachAdvice = onCall({
  secrets: ["GROQ_API_KEY"],
}, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be logged in.");
  }

  const { userContext, userMessage } = request.data as {
    userContext?: string;
    userMessage?: string;
  };

  if (!userMessage) {
    throw new HttpsError("invalid-argument", "userMessage is required.");
  }

  const groqApiKey = process.env.GROQ_API_KEY;
  if (!groqApiKey) return { advice: "Keep building consistent habits — progress over perfection." };

  try {
    const response = await fetch("https://api.groq.com/openai/v1/chat/completions", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${groqApiKey}`,
      },
      body: JSON.stringify({
        model: "llama-3.1-8b-instant",
        messages: [
          { role: "system", content: userContext || "You are a motivational habit coach. Be concise. Max 2 sentences." },
          { role: "user", content: userMessage },
        ],
        max_tokens: 256,
        temperature: 0.7,
      }),
    });

    if (!response.ok) return { advice: "Your consistency is your superpower. Keep going!" };

    const result = await response.json() as any;
    const advice = result.choices?.[0]?.message?.content?.trim() ?? "Every small step counts.";
    return { advice };
  } catch (error) {
    console.error("Groq proxy error:", error);
    return { advice: "Focus on progress, not perfection. You've got this!" };
  }
});

/**
 * Daily momentum decay (Behavioral Entropy Engine - Gen 2)
 */
export const applyDailyMomentumDecay = onSchedule("0 2 * * *", async (event) => {
  console.log("Daily momentum decay starting at:", event.scheduleTime);
  const today = new Date(event.scheduleTime);
  const todayStr = today.toISOString().split("T")[0];

  const habitsSnap = await db.collection("habits").where("isArchived", "==", false).get();
  if (habitsSnap.empty) return;

  const BATCH_SIZE = 450;
  let batch = db.batch();
  let batchCount = 0;

  for (const doc of habitsSnap.docs) {
    const data = doc.data();
    const lastCompletedDate = data.lastCompletedDate as admin.firestore.Timestamp | undefined;

    let completedToday = false;
    if (lastCompletedDate) {
      completedToday = lastCompletedDate.toDate().toISOString().split("T")[0] === todayStr;
    }

    if (completedToday) continue;

    const currentMomentum = (data.momentumScore as number) ?? 0;
    const consecutiveMisses = (data.consecutiveMisses as number) ?? 0;
    const contractActive = (data.contractActive as boolean) ?? false;

    const missDecay = contractActive ? 15 : (consecutiveMisses > 0 ? 5 : 2);
    const newMomentum = Math.max(0, currentMomentum - missDecay);
    const newConsecutiveMisses = consecutiveMisses + 1;

    batch.update(doc.ref, {
      momentumScore: newMomentum,
      consecutiveMisses: newConsecutiveMisses,
    });

    if (contractActive && consecutiveMisses === 0) {
      const statsRef = db.collection("user_stats").doc(data.userId);
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
        console.error(`Error applying penalty: ${err}`);
      }
    }

    batchCount++;
    if (batchCount >= BATCH_SIZE) {
      await batch.commit();
      batch = db.batch();
      batchCount = 0;
    }
  }

  if (batchCount > 0) await batch.commit();
});

// ============================================================================
// SUB-MODULE EXPORTS
// ============================================================================
export * from "./challenges";
// export * from "./seed_templates";
export * from "./refreshQuarterlyChallenges";
export * from "./habit_notifications";
// export * from "./seedReviewerAccount";
export * from "./accountDeletion";
export * from "./rateLimiter";
export * from "./ai_recap";
export * from "./revenuecat_events";
