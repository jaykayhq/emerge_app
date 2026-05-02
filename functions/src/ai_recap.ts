import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

/**
 * AI-Driven Weekly Recap & Difficulty Calibration
 * 
 * Analyzes the last 14 days of habit velocity and automatically
 * updates habit difficulty to maintain the 'Goldilocks Zone'.
 */
export const generateAiRecap = onCall({
  secrets: ["GROQ_API_KEY"],
  memory: "512MiB",
  timeoutSeconds: 60,
}, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated.");
  }

  const userId = request.auth.uid;
  const db = admin.firestore();
  
  console.log(`[generateAiRecap] Starting for user: ${userId}`);

  try {
    // 1. Fetch User Data & Habits
    const userDoc = await db.collection("user_stats").doc(userId).get();
    const habitsSnap = await db.collection("habits").where("userId", "==", userId).get();
    
    if (habitsSnap.empty) {
      console.log(`[generateAiRecap] No habits found for user: ${userId}`);
      return { success: false, reason: "no_habits" };
    }

    const habitMap: Record<string, any> = {};
    habitsSnap.docs.forEach((doc: any) => {
      habitMap[doc.id] = doc.data();
    });

    // 2. Fetch Last 14 Days of Activity
    const fourteenDaysAgo = new Date();
    fourteenDaysAgo.setDate(fourteenDaysAgo.getDate() - 14);

    const activitySnap = await db.collection("user_activity")
      .where("userId", "==", userId)
      .where("type", "==", "habit_completion")
      .where("date", ">=", admin.firestore.Timestamp.fromDate(fourteenDaysAgo))
      .get();

    console.log(`[generateAiRecap] Found ${activitySnap.size} activities for the last 14 days`);

    // 3. Analyze Activity
    const completionsPerHabit: Record<string, number> = {};
    let totalCompletions = 0;

    activitySnap.docs.forEach((doc: any) => {
      const data = doc.data();
      const habitId = data.habitId;
      if (habitId) {
        completionsPerHabit[habitId] = (completionsPerHabit[habitId] || 0) + 1;
        totalCompletions++;
      }
    });

    // Find top habit
    let topHabitId = null;
    let maxCompletions = 0;
    for (const [id, count] of Object.entries(completionsPerHabit)) {
      if (count > maxCompletions) {
        maxCompletions = count;
        topHabitId = id;
      }
    }

    const topHabitTitle = topHabitId ? (habitMap[topHabitId]?.title || "Unknown Habit") : "None";

    // 4. Recommendation Logic (Recalibrations)
    const recalibrations: string[] = [];
    const habitUpdates: Promise<any>[] = [];

    for (const [habitId, count] of Object.entries(completionsPerHabit)) {
      const habitData = habitMap[habitId];
      if (!habitData) continue;

      const velocity = count / 14.0;
      
      // If performing exceptionally well on a non-hard habit, suggest hardening
      if (velocity > 0.8 && habitData.difficulty !== "hard") {
        const difficultyOrder: ("easy" | "medium" | "hard")[] = ["easy", "medium", "hard"];
        const currentIndex = difficultyOrder.indexOf(habitData.difficulty as any);
        const nextDifficulty = currentIndex !== -1 && currentIndex < 2 ? difficultyOrder[currentIndex + 1] : habitData.difficulty;
        
        if (nextDifficulty !== habitData.difficulty) {
          recalibrations.push(`Upgraded ${habitData.title} to ${nextDifficulty} to match your momentum.`);
          habitUpdates.push(db.collection("habits").doc(habitId).update({
            difficulty: nextDifficulty,
            lastCalibrated: admin.firestore.FieldValue.serverTimestamp(),
          }));
        }
      }
    }

    if (habitUpdates.length > 0) {
      await Promise.all(habitUpdates);
      console.log(`[generateAiRecap] Applied ${habitUpdates.length} habit difficulty updates`);
    }

    // 5. AI Insight Generation
    let insightHeadline = "Identity Emerging";
    let insightBody = "You're building momentum. Every completion is a vote for the person you wish to become.";
    
    const groqApiKey = process.env.GROQ_API_KEY;
    if (groqApiKey && totalCompletions > 0) {
      try {
        console.log("[generateAiRecap] Requesting Groq AI Insight...");
        const response = await fetch("https://api.groq.com/openai/v1/chat/completions", {
          method: "POST",
          headers: {
            "Authorization": `Bearer ${groqApiKey}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            model: "llama-3.1-8b-instant",
            messages: [
              {
                role: "system",
                content: "You are the Emerge Identity Coach. You analyze a user's habit performance and provide a short (4-6 words) punchy headline and a 1-2 sentence deep identity-first insight. Focus on WHO they are becoming, not just what they did.",
              },
              {
                role: "user",
                content: `Last 14 days activity: ${JSON.stringify(completionsPerHabit)}. Top habit: ${topHabitTitle}. Total completions: ${totalCompletions}. Provide JSON: {"headline": "...", "insight": "..."}`,
              },
            ],
            response_format: { type: "json_object" },
          }),
        });

        if (response.ok) {
          const aiData = await response.json() as any;
          const content = JSON.parse(aiData.choices[0]?.message?.content || "{}");
          insightHeadline = content.headline || insightHeadline;
          insightBody = content.insight || insightBody;
          console.log("[generateAiRecap] Groq AI Insight generated successfully");
        } else {
          console.error("[generateAiRecap] Groq API Error:", await response.text());
        }
      } catch (aiError) {
        console.error("[generateAiRecap] Failed to call AI service:", aiError);
      }
    }

    // 6. Assemble & Save Recap
    const now = new Date();
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(now.getDate() - 7);

    const recapId = `recap_${now.getTime()}`;
    const recapData = {
      id: recapId,
      userId: userId,
      startDate: sevenDaysAgo.toISOString(),
      endDate: now.toISOString(),
      totalHabitsCompleted: totalCompletions,
      perfectDays: Math.floor(totalCompletions / 2), // Simplified for now
      totalXpEarned: totalCompletions * 20,
      topHabitName: topHabitTitle,
      currentLevel: userDoc.data()?.level || 1,
      worldGrowthPercentage: 0.05, // Placeholder
      dominantIdentityThisWeek: userDoc.data()?.archetype || "Explorer",
      identityHeadline: insightHeadline,
      aiInsight: insightBody,
      velocityInsights: recalibrations,
      recommendedDifficultyAdjustment: recalibrations.length > 0 ? "medium" : null,
      isComplete: true,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    // Save to user's stats subcollection (where the app expects it)
    await db.collection("user_stats").doc(userId).collection("recaps").doc(recapId).set(recapData);
    
    // Also keep the global collection for auditing
    await db.collection("weekly_recaps").doc(recapId).set(recapData);

    console.log(`[generateAiRecap] Success! Recap saved with ID: ${recapId}`);
    return { 
      success: true, 
      recapId: recapId,
      insight: insightBody,
      adjustments: recalibrations,
    };

  } catch (error: any) {
    console.error("[generateAiRecap] CRITICAL ERROR:", error);
    throw new HttpsError("internal", error.message || "An unexpected error occurred during recap generation.");
  }
});
