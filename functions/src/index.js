/**
 * XP CALCULATION & PROGRESSION SYSTEM
 *
 * This function triggers on new user_activity documents (habit completions)
 * and updates the user's XP, level, and world state.
 *
 * Flow:
 * 1. User completes habit → FirestoreHabitRepository logs activity
 * 2. This function triggers on user_activity onCreate
 * 3. Fetch habit details (difficulty, attribute, streak)
 * 4. Calculate XP gain
 * 5. Update user_stats with new XP/level
 * 6. Update world state (zone health, milestones)
 * 7. Check for level up
 */

const admin = require('firebase-admin');
const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { onCall, onRequest, HttpsError } = require('firebase-functions/v2/https');
const { defineSecret } = require('firebase-functions/params');
const logger = require('firebase-functions/v1').logger;

// Define Secrets from Cloud Secret Manager
const GROQ_SECRET = defineSecret('GROQ');
const REVENUECAT_SECRET = defineSecret('RevenueCAT');

// Initialize Firebase Admin
admin.initializeApp();

const db = admin.firestore();
const BASE_XP_PER_HABIT = 10;
const XP_PER_LEVEL = 100;

exports.onHabitActivity = onDocumentCreated('user_activity/{activityId}', async (event) => {
  const snap = event.data;
  const activity = snap.data();

  // Only process habit completion events
  if (activity.type !== "habit_completion") {
    return null;
  }

  const userId = activity.userId;
  const habitId = activity.habitId;

  // Validate required fields
  if (!userId || !habitId) {
    logger.error("Invalid activity document:", activity);
    return null;
  }

  try {
    // Fetch habit to get difficulty, attribute, and streak
    const habitDoc = await db.collection("habits").doc(habitId).get();

    if (!habitDoc.exists) {
      logger.warn(`Habit ${habitId} not found`);
      return null;
    }

    const habit = habitDoc.data();
    if (!habit) {
      logger.warn(`Habit ${habitId} has no data`);
      return null;
    }

    const difficulty = habit.difficulty || "medium";
    const attribute = habit.attribute || "vitality";
    const currentStreak = habit.currentStreak || 0;

    // Calculate XP gain
    const xpGain = calculateXpGain(difficulty, currentStreak);
    logger.info(
      `User ${userId}: +${xpGain} XP (${attribute}, ${difficulty}, ` +
      `streak ${currentStreak})`
    );

    // Fetch current user stats
    const userStatsRef = db.collection("user_stats").doc(userId);
    const userStatsDoc = await userStatsRef.get();

    if (!userStatsDoc.exists) {
      logger.warn(
        `User stats for ${userId} not found. Creating initial stats.`
      );
      // Create initial stats if not exists
      await userStatsRef.set({
        uid: userId,
        archetype: "none",
        avatarStats: {
          strengthXp: 0,
          intellectXp: 0,
          vitalityXp: 0,
          creativityXp: 0,
          focusXp: 0,
          level: 1,
          streak: 0,
        },
        worldState: {
          cityLevel: 1,
          forestLevel: 1,
          entropy: 0.0,
          worldAge: 0,
          zones: {},
          unlockedBuildings: [],
          buildingPlacements: [],
          lastActiveDate: new Date().toISOString(),
        },
        identityVotes: {},
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      return null;
    }

    const userStats = userStatsDoc.data();
    if (!userStats) {
      logger.warn(`User stats for ${userId} is empty`);
      return null;
    }

    // Update avatar stats with new XP
    const avatarStats = userStats.avatarStats || {};
    const oldLevel = avatarStats.level || 1;
    const oldTotalXp = getTotalXp(avatarStats);

    // Add XP to appropriate attribute
    const attributeKey = `${attribute}Xp`;
    const currentAttributeXp = avatarStats[attributeKey] || 0;
    avatarStats[attributeKey] = currentAttributeXp + xpGain;

    // Calculate new level
    const newTotalXp = getTotalXp(avatarStats);
    const newLevel = Math.floor(newTotalXp / XP_PER_LEVEL) + 1;

    avatarStats.level = newLevel;

    // Update streak if needed (global streak across all habits)
    if (!avatarStats.streak) avatarStats.streak = 0;

    // Update world state
    const worldState = userStats.worldState || {};
    const updatedWorldState = updateWorldFromHabit(
      worldState,
      attribute,
      true // completed
    );

    // Check for level up
    const leveledUp = newLevel > oldLevel;
    if (leveledUp) {
      logger.info(
        `🎉 USER ${userId} LEVELED UP from ${oldLevel} to ${newLevel}!`
      );

      // Trigger level up celebration notification
      await sendLevelUpNotification(userId, newLevel, oldLevel);
    }

    // Commit updates to user_stats
    await userStatsRef.update({
      avatarStats: avatarStats,
      worldState: updatedWorldState,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    logger.info(
      `✅ Updated stats for ${userId}: Lvl ${oldLevel} → ${newLevel}, ` +
      `${oldTotalXp} → ${newTotalXp} XP`
    );

    return null;
  } catch (error) {
    logger.error("Error processing habit activity:", error);
    throw error;
  }
});

/**
 * Calculate XP gain based on difficulty and streak
 * Mirrors GamificationService.calculateXpGain() in Flutter app
 */
function calculateXpGain(difficulty, streak) {
  let multiplier = 1;
  switch (difficulty) {
    case "easy":
      multiplier = 1;
      break;
    case "medium":
      multiplier = 2;
      break;
    case "hard":
      multiplier = 3;
      break;
    default:
      multiplier = 2;
  }

  // Streak bonus: +10% per 7 days, capped at 50%
  const streakBonus = Math.min((streak / 7) * 0.1, 0.5);

  return Math.round(BASE_XP_PER_HABIT * multiplier * (1 + streakBonus));
}

/**
 * Calculate total XP from all attributes
 */
function getTotalXp(avatarStats) {
  return (
    (avatarStats.strengthXp || 0) +
    (avatarStats.intellectXp || 0) +
    (avatarStats.vitalityXp || 0) +
    (avatarStats.creativityXp || 0) +
    (avatarStats.focusXp || 0)
  );
}

/**
 * Update world state when habit is completed
 * Mirrors GamificationService.updateWorldFromHabit()
 */
function updateWorldFromHabit(worldState, attribute, completed) {
  const zones = worldState.zones || {};

  // Map attribute to zone ID
  const zoneMap = {
    strength: "strength_training",
    intellect: "library",
    vitality: "park",
    creativity: "studio",
    focus: "shrine",
  };

  const zoneId = zoneMap[attribute] || "park";
  const zoneData = zones[zoneId] || {
    zoneId: zoneId,
    level: 1,
    health: 1.0,
    milestone: 0,
    activeElements: [],
  };

  let health = zoneData.health || 1.0;
  let milestone = zoneData.milestone || 0;
  let level = zoneData.level || 1;

  if (completed) {
    // Increase health and milestone
    health = Math.min(health + 0.1, 1.0);
    milestone += 1;

    // Check for level up (every 10 milestones per level)
    const milestonesNeeded = level * 10;
    if (milestone >= milestonesNeeded) {
      level += 1;
      milestone = 0;
    }
  }

  // Update zone
  zones[zoneId] = {
    ...zoneData,
    level: level,
    health: health,
    milestone: milestone,
    lastUpdated: new Date().toISOString(),
  };

  // Recalculate global entropy (inverse of average zone health)
  let totalHealth = 0;
  let zoneCount = 0;
  for (const z of Object.values(zones)) {
    totalHealth += z.health || 1.0;
    zoneCount++;
  }
  const avgHealth = zoneCount > 0 ? totalHealth / zoneCount : 1.0;
  const entropy = Math.max(0, 1.0 - avgHealth);

  return {
    ...worldState,
    zones: zones,
    entropy: entropy,
    lastActiveDate: new Date().toISOString(),
  };
}

/**
 * Send level up notification
 */
async function sendLevelUpNotification(userId, newLevel, oldLevel) {
  // Create notification document
  const notificationsRef = db
    .collection("users")
    .doc(userId)
    .collection("notifications");

  await notificationsRef.add({
    type: "level_up",
    title: "🎉 Level Up!",
    body: `Congratulations! You've reached level ${newLevel}!`,
    data: {
      oldLevel: oldLevel,
      newLevel: newLevel,
    },
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    read: false,
  });

  logger.info(`🔔 Sent level up notification to ${userId}`);
}

/**
 * REVENUECAT WEBHOOK HANDLER
 * 
 * Securely processes purchase events from RevenueCat via HTTP POST.
 * Integrated with Secret Manager for validation.
 */
exports.revenueCatWebhook = onRequest({ secrets: [REVENUECAT_SECRET] }, async (req, res) => {
  const apiKey = REVENUECAT_SECRET.value();

  // Verify RevenueCat auth header if configured
  const authHeader = req.headers.authorization;
  if (apiKey && authHeader !== `Bearer ${apiKey}`) {
    logger.warn("Unauthorized RevenueCat webhook attempt");
    return res.status(401).send("Unauthorized");
  }

  const event = req.body.event;
  logger.info("RevenueCat Event:", event.type, event.app_user_id);

  try {
    // Implement custom logic here (e.g., updating user_stats for premium features)
    if (event.type === 'INITIAL_PURCHASE' || event.type === 'RENEWAL') {
      const userId = event.app_user_id;
      await admin.firestore().collection('user_stats').doc(userId).update({
        isPremium: true,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
    }

    res.status(200).send({ status: "success" });
  } catch (error) {
    logger.error("Error processing RevenueCat webhook:", error);
    res.status(500).send("Internal Server Error");
  }
});

/**
 * AI COACH ADVICE - SECURE BACKEND IMPLEMENTATION
 * 
 * Uses the GROQ secret to provide habit coaching advice without exposing keys to the client.
 */
exports.getGroqCoachAdvice = onCall({ secrets: [GROQ_SECRET] }, async (request) => {
  // Validate authentication
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'The function must be called while authenticated.');
  }

  const { userContext, userMessage } = request.data;
  const apiKey = GROQ_SECRET.value();

  if (!apiKey) {
    logger.error("GROQ_SECRET is not configured");
    throw new HttpsError('failed-precondition', 'AI Service is temporarily unavailable.');
  }

  try {
    const response = await fetch('https://api.groq.com/openai/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'llama-3.1-8b-instant',
        messages: [
          {
            role: 'system',
            content: `You are an expert Habit Coach based on Atomic Habits principles. 
                     Keep your answers short (under 2 sentences) and motivating. 
                     Context: ${userContext || 'General habit improvement'}`,
          },
          { role: 'user', content: userMessage },
        ],
        temperature: 0.7,
        max_tokens: 150,
      }),
    });

    if (!response.ok) {
      const errorData = await response.json();
      logger.error('Groq API Error:', errorData);
      throw new HttpsError('internal', 'AI Service failed to respond.');
    }

    const data = await response.json();
    const advice = data.choices[0].message.content.trim();

    return { advice };
  } catch (error) {
    logger.error('Error in getGroqCoachAdvice:', error);
    throw new HttpsError('internal', 'Internal error occurred while fetching advice.');
  }
});
