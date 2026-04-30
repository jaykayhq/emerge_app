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
  memory: "256MiB",
}, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated.");
  }

  const userId = request.auth.uid;
  const db = admin.firestore();
  
  // 1. Fetch Habits
  const habitsSnap = await db.collection("habits")
    .where("userId", "==", userId)
    .where("isArchived", "==", false)
    .get();

  if (habitsSnap.empty) {
    return { success: false, message: "No active habits found." };
  }

  // 2. Fetch Activity for last 14 days
  const fourteenDaysAgo = new Date();
  fourteenDaysAgo.setDate(fourteenDaysAgo.getDate() - 14);
  
  const activitySnap = await db.collection("user_activity")
    .where("userId", "==", userId)
    .where("type", "==", "habit_completion")
    .where("timestamp", ">=", fourteenDaysAgo)
    .get();

  const activityCounts: Record<string, number> = {};
  activitySnap.docs.forEach((doc: admin.firestore.QueryDocumentSnapshot) => {
    const data = doc.data();
    const habitId = data.habitId;
    if (habitId) {
      activityCounts[habitId] = (activityCounts[habitId] || 0) + 1;
    }
  });

  // 3. Process Habits & Calibration
  const habitUpdates: Promise<any>[] = [];
  const recalibrations: string[] = [];

  for (const doc of habitsSnap.docs) {
    const habitData = doc.data();
    const habitId = doc.id;
    const completions = activityCounts[habitId] || 0;
    const velocity = completions / 14.0; // Daily average over 14 days

    let newDifficulty = habitData.difficulty;
    let calibrated = false;

    if (velocity >= 0.9 && habitData.difficulty !== "hard") {
      newDifficulty = "hard";
      calibrated = true;
    } else if (velocity <= 0.3 && habitData.difficulty !== "easy") {
      newDifficulty = "easy";
      calibrated = true;
    }

    if (calibrated) {
      habitUpdates.push(db.collection("habits").doc(habitId).update({
        difficulty: newDifficulty,
        lastCalibrated: admin.firestore.FieldValue.serverTimestamp(),
      }));
      recalibrations.push(`${habitData.title}: ${habitData.difficulty} -> ${newDifficulty}`);
    }
  }

  // Execute habit updates
  if (habitUpdates.length > 0) {
    await Promise.all(habitUpdates);
  }

  // 4. Generate AI Insight via Groq
  const groqApiKey = process.env.GROQ_API_KEY;
  let insight = "Your journey continues. Stay focused on your small wins.";

  if (groqApiKey) {
    try {
      const prompt = `
        User is building habits in Emerge (Identity-First habit tracker).
        Last 14 days velocity: ${JSON.stringify(activityCounts)}
        Adjustments made: ${recalibrations.join(", ")}
        Provide a 2-sentence motivational insight focusing on their 'Identity' (e.g. Creator, Athlete).
      `;

      const response = await fetch("https://api.groq.com/openai/v1/chat/completions", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${groqApiKey}`,
        },
        body: JSON.stringify({
          model: "llama3-8b-8192",
          messages: [{ role: "user", content: prompt }],
          max_tokens: 150,
        }),
      });

      if (response.ok) {
        const result = await response.json();
        insight = result.choices?.[0]?.message?.content?.trim() || insight;
      }
    } catch (e) {
      console.error("Groq AI Error:", e);
    }
  }

  // 5. Create Weekly Recap Document
  const recapData = {
    userId,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    insight,
    recalibrations,
    velocity: activityCounts,
    identityFocus: "Evolving Identity", // Simplified for now
  };

  const recapRef = await db.collection("weekly_recaps").add(recapData);

  return {
    success: true,
    recapId: recapRef.id,
    insight,
    adjustments: recalibrations,
  };
});
