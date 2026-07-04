/**
 * Firebase Cloud Functions - Emerge App (Gen 2)
 *
 * Cost-optimized for scale:
 * - Gen 2 concurrency enabled
 * - Managed Secrets for Groq API
 * - Shorter cold starts via global options
 */


import { onSchedule } from "firebase-functions/v2/scheduler";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { setGlobalOptions } from "firebase-functions/v2";
import * as admin from "firebase-admin";

import { recalcTribesInternal } from "./recalcTribes";
export { fillNarratorSlots } from "./narrator";

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

/**
 * Daily behavioral decay: Increases entropy and resets daily flags.
 * Runs at midnight UTC.
 */
export const applyDailyDecayScheduled = onSchedule("0 0 * * *", async (event) => {
  console.log("Applying daily behavioral decay at midnight UTC");
  
  const usersSnapshot = await db.collection("user_stats").get();
  const batch = db.batch();
  
  usersSnapshot.forEach((doc: admin.firestore.QueryDocumentSnapshot) => {
    const data = doc.data();
    const currentWorldState = data.worldState || {};
    const currentEntropy = currentWorldState.entropy || 0;
    
    // Increase entropy by 0.05 daily (approx 20 days to full decay if inactive)
    const newEntropy = Math.min(1.0, currentEntropy + 0.05);
    
    batch.set(doc.ref, {
      worldState: {
        ...currentWorldState,
        entropy: newEntropy,
      }
    }, { merge: true });
  });
  
  await batch.commit();
  console.log(`Successfully applied decay to ${usersSnapshot.size} users.`);
});

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
export const applyDailyTribeRecalculation = onSchedule("0 3 * * *", async (event) => {
  console.log("Starting scheduled tribe recalculation...");
  await recalcTribesInternal(db);
});

export * from "./challenges";
// export * from "./seed_templates";
export * from "./refreshQuarterlyChallenges";
export * from "./habit_notifications";
// export * from "./seedReviewerAccount";
export * from "./accountDeletion";
export * from "./cleanupUserData";
export * from "./rateLimiter";
export * from "./ai_recap";
export * from "./revenuecat_events";
export * from "./payments/paystack";
export { setUserRole } from "./setUserRole";
export { purgeOrphanedUserData } from "./purgeOrphanedUserData";
