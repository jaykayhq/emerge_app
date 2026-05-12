/**
 * Firebase Cloud Functions - Habit Notification System
 *
 * Archetype-based notification system for the Emerge habit formation app.
 * Provides smart, cross-device notifications with streak warnings,
 * AI insights, and level-up celebrations.
 *
 * Features:
 * - Habit creation welcome notifications
 * - Streak at-risk warnings (respects Do Not Disturb)
 * - Level-up achievement notifications
 * - Daily AI insights
 * - FCM push notifications with archetype-themed messaging
 */

import { onDocumentCreated, onDocumentWritten } from "firebase-functions/v2/firestore";
import { onSchedule } from "firebase-functions/v2/scheduler";
// import { onCall, HttpsError } from "firebase-functions/v2/https";
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
// NOTIFICATION TEMPLATES (TypeScript port of Flutter templates)
// ============================================================================

/**
 * Archetype-themed notification templates.
 * Each archetype has unique messaging that reinforces identity-based habit formation.
 */
const NOTIFICATION_TEMPLATES = {
  athlete: {
    welcome: (title: string) =>
      `💪 Your journey to greatness begins! "${title}" is now part of your training.`,
    reminder: (title: string) =>
      `💪 Time to train! Your "${title}" session awaits. Make yourself proud!`,
    streakWarning: (days: number) =>
      `⚠️ 💪 Your ${days}-day training streak is at risk! Don't lose your momentum—train now!`,
    levelUp: (level: number) =>
      `🏆 💪 LEVEL UP! You've reached Level ${level}! Your training yields greatness!`,
    aiInsightGreeting: () =>
      "💪 Your training insights are ready! Optimize your performance today.",
    achievement: (name: string) =>
      `🏅 💪 ACHIEVEMENT UNLOCKED: ${name}! Your dedication knows no bounds!`,
  },
  scholar: {
    welcome: (title: string) =>
      `📚 A new quest for knowledge begins! Mastering "${title}" starts now.`,
    reminder: (title: string) =>
      `📚 Knowledge calls! Your "${title}" study session is ready. Begin the quest.`,
    streakWarning: (days: number) =>
      `⚠️ 📚 Your ${days}-day knowledge quest is fading! Protect your streak—learn now.`,
    levelUp: (level: number) =>
      `🏆 📚 WISDOM GROWS! You've reached Level ${level}! Knowledge expands within you.`,
    aiInsightGreeting: () =>
      "📚 Wisdom awaits! Your personalized learning insights have arrived.",
    achievement: (name: string) =>
      `🏅 📚 KNOWLEDGE CONQUERED: ${name}! Your quest for wisdom succeeds!`,
  },
  creator: {
    welcome: (title: string) =>
      `🎨 Inspiration strikes! Your creative journey with "${title}" starts today.`,
    reminder: (title: string) =>
      `🎨 Inspiration strikes! Time for your "${title}" creative flow. Create today.`,
    streakWarning: (days: number) =>
      `⚠️ 🎨 Your ${days}-day creative flow is at risk! Keep the inspiration going—create now.`,
    levelUp: (level: number) =>
      `🏆 🎨 MUSE FAVORS YOU! You've reached Level ${level}! Your artistry elevates!`,
    aiInsightGreeting: () =>
      "🎨 Creative inspiration delivered! Your muse has new insights for you.",
    achievement: (name: string) =>
      `🏅 🎨 MASTERPIECE CREATED: ${name}! Your creative vision manifests!`,
  },
  stoic: {
    welcome: (title: string) =>
      `🏛️ The path to mastery begins with a single step. "${title}" is your practice.`,
    reminder: (title: string) =>
      `🏛️ Master yourself! Your "${title}" practice awaits. Show your discipline.`,
    streakWarning: (days: number) =>
      `⚠️ 🏛️ Your ${days}-day practice is imperiled! Maintain your discipline—act now.`,
    levelUp: (level: number) =>
      `🏆 🏛️ MASTERY AWAITS! You've reached Level ${level}! Your discipline strengthens!`,
    aiInsightGreeting: () =>
      "🏛️ Clarity awaits! Your daily reflection on mastery and discipline is here.",
    achievement: (name: string) =>
      `🏅 🏛️ VIRTUE ATTAINED: ${name}! Your stoic practice bears fruit!`,
  },
  zealot: {
    welcome: (title: string) =>
      `🔥 A sacred commitment! Your devotion to "${title}" has been consecrated.`,
    reminder: (title: string) =>
      `🔥 Stay the path! Your sacred "${title}" devotion calls. Honor your commitment.`,
    streakWarning: (days: number) =>
      `⚠️ 🔥 Your ${days}-day sacred devotion wavers! Rekindle your flame—act now.`,
    levelUp: (level: number) =>
      `🏆 🔥 SACRED ASCENSION! You've reached Level ${level}! Your devotion burns brighter!`,
    aiInsightGreeting: () =>
      "🔥 Divine guidance! Your sacred insights for the path have been revealed.",
    achievement: (name: string) =>
      `🏅 🔥 SACRED HONOR EARNED: ${name}! Your devotion is recognized!`,
  },
  none: {
    welcome: (title: string) =>
      `✨ New habit started! "${title}" is now part of your journey.`,
    reminder: (title: string) =>
      `⏰ Time to focus! Complete "${title}" to stay on track with your goals.`,
    streakWarning: (days: number) =>
      `⚠️ Your ${days}-day streak is at risk! Complete your habit now to keep it alive.`,
    levelUp: (level: number) =>
      `🏆 LEVEL UP! You've reached Level ${level}! Keep up the amazing work!`,
    aiInsightGreeting: () =>
      "✨ Your daily insights are ready! Discover what's possible today.",
    achievement: (name: string) =>
      `🏅 ACHIEVEMENT UNLOCKED: ${name}! You're making incredible progress!`,
  },
};

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

/**
 * Gets notification template message for archetype and type.
 */
export function getTemplateMessage(
  archetype: string,
  type: keyof typeof NOTIFICATION_TEMPLATES.athlete,
  ...args: any[]
): string {
  const templates = (NOTIFICATION_TEMPLATES as any)[archetype] || NOTIFICATION_TEMPLATES.none;
  const templateFunc = templates[type] as (...args: any[]) => string;
  if (templateFunc) {
    return templateFunc(...args);
  }
  const fallbackFunc = NOTIFICATION_TEMPLATES.none[type] as ((...args: any[]) => string) | undefined;
  return fallbackFunc ? fallbackFunc(...args) : "";
}



/**
 * Sends FCM notification to a user.
 */
export async function sendNotification(
  userId: string,
  title: string,
  body: string,
  type: string,
  data?: Record<string, any>
): Promise<void> {
  const firestore = getDb();

  try {
    // Get user's FCM token
    const userDoc = await firestore.collection("users").doc(userId).get();
    if (!userDoc.exists) {
      console.warn(`User ${userId} not found for notification`);
      return;
    }

    const userData = userDoc.data();
    const fcmToken = userData?.fcmToken;

    if (!fcmToken) {
      console.log(`No FCM token for user ${userId}, skipping notification`);
      return;
    }

    // Check if notifications are enabled
    if (userData?.notificationsEnabled === false) {
      console.log(`Notifications disabled for user ${userId}, skipping`);
      return;
    }

    // Send notification
    const message: admin.messaging.Message = {
      notification: {
        title,
        body,
      },
      data: {
        type,
        ...data,
        userId,
        timestamp: Date.now().toString(),
      },
      token: fcmToken,
    };

    const response = await admin.messaging().send(message);
    console.log(`Notification sent to user ${userId}:`, response);
  } catch (error) {
    console.error(`Error sending notification to user ${userId}:`, error);
    // Don't throw - allow function to continue
  }
}

/**
 * Generates an AI insight message based on user stats.
 * In production, this would call the Groq AI service.
 */
async function generateAIInsight(userId: string): Promise<string> {
  const firestore = getDb();

  try {
    const statsDoc = await firestore.collection("user_stats").doc(userId).get();
    if (!statsDoc.exists) {
      return "Start your journey by completing your first habit!";
    }

    const stats = statsDoc.data();
    const level = stats?.level || 1;
    const streak = stats?.streak || 0;
    const totalXp = stats?.totalXp || 0;

    // Simple insight generation (replace with Groq AI in production)
    if (streak >= 30) {
      return `Extraordinary! Your ${streak}-day streak demonstrates exceptional consistency. You're building lasting change.`;
    } else if (streak >= 14) {
      return `Impressive dedication! ${streak} days of progress. You've established a strong foundation.`;
    } else if (streak >= 7) {
      return `${streak} days strong! Research shows this is when habits start to feel automatic. Keep going!`;
    } else if (streak >= 3) {
      return `${streak} days of momentum! You're building the neural pathways for lasting change.`;
    } else if (level > 5) {
      return `Level ${level} achieved! Your consistency is paying off. Focus on maintaining quality over quantity.`;
    } else if (totalXp > 500) {
      return `You've accumulated ${totalXp} XP! Every action is a vote for the identity you're becoming.`;
    } else {
      return "Progress over perfection. Even small steps compound into remarkable transformations.";
    }
  } catch (error) {
    console.error(`Error generating AI insight for user ${userId}:`, error);
    return "Your daily insight: Keep showing up, even when it's hard.";
  }
}

// ============================================================================
// CLOUD FUNCTIONS - HABIT LIFECYCLE
// ============================================================================

/**
 * Triggered when a habit is created, updated, or deleted.
 */
export const onHabitChanged = onDocumentWritten("users/{userId}/habits/{habitId}", async (event) => {
  const userId = event.params.userId;
  const habitId = event.params.habitId;
  const firestore = getDb();

  const before = event.data?.before.exists ? event.data?.before.data() : null;
  const after = event.data?.after.exists ? event.data?.after.data() : null;

  try {
    // HANDLE DELETION
    if (before && !after) {
      console.log(`Habit deleted: ${habitId} for user ${userId}`);
      await firestore
        .collection("users")
        .doc(userId)
        .collection("notificationSchedules")
        .doc(habitId)
        .delete();
      return;
    }

    // HANDLE CREATION
    if (!before && after) {
      console.log(`Habit created: ${habitId} for user ${userId}`);
      const userDoc = await firestore.collection("users").doc(userId).get();
      if (!userDoc.exists) return;

      const userData = userDoc.data();
      const archetype = userData?.archetype || "none";
      const settings = userData?.settings || {};
      const notificationsEnabled = userData?.notificationsEnabled !== false;
      const archetypeNudges = settings.archetypeNudges !== false;

      if (after.reminderEnabled && notificationsEnabled && archetypeNudges) {
        const title = "Habit Created";
        const body = getTemplateMessage(archetype, "welcome", after.title || "Your new habit");
        await sendNotification(userId, title, body, "habit_welcome", { habitId, archetype });
      }

      await firestore
        .collection("users")
        .doc(userId)
        .collection("notificationSchedules")
        .doc(habitId)
        .set({
          habitId,
          userId,
          archetype: userData?.archetype || "none",
          reminderTime: after.reminderTime || "07:00",
          frequency: after.frequency || "daily",
          specificDays: after.specificDays || [],
          welcomeNotified: true,
          lastReminderSent: null,
          enabled: after.reminderEnabled || false,
          lastStreakWarningSent: null,
          streakWarningCount: 0,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      return;
    }

    // HANDLE UPDATE
    if (before && after) {
      const timeChanged = before.reminderTime !== after.reminderTime;
      const frequencyChanged = before.frequency !== after.frequency;
      const daysChanged = JSON.stringify(before.specificDays) !== JSON.stringify(after.specificDays);
      const enabledChanged = before.reminderEnabled !== after.reminderEnabled;

      if (!timeChanged && !frequencyChanged && !daysChanged && !enabledChanged) return;

      const scheduleRef = firestore
        .collection("users")
        .doc(userId)
        .collection("notificationSchedules")
        .doc(habitId);

      const scheduleDoc = await scheduleRef.get();

      if (!scheduleDoc.exists && after.reminderEnabled) {
        const userDoc = await firestore.collection("users").doc(userId).get();
        const archetype = userDoc.data()?.archetype || "none";

        await scheduleRef.set({
          habitId,
          userId,
          archetype,
          reminderTime: after.reminderTime || "07:00",
          frequency: after.frequency || "daily",
          specificDays: after.specificDays || [],
          welcomeNotified: true,
          lastReminderSent: null,
          enabled: true,
          lastStreakWarningSent: null,
          streakWarningCount: 0,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      } else if (scheduleDoc.exists) {
        const updates: Record<string, any> = {
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        };
        if (timeChanged) updates.reminderTime = after.reminderTime;
        if (frequencyChanged) updates.frequency = after.frequency;
        if (daysChanged) updates.specificDays = after.specificDays;
        if (enabledChanged) updates.enabled = after.reminderEnabled;
        await scheduleRef.update(updates);
      }
    }
    return;
  } catch (error) {
    console.error(`Error in onHabitChanged:`, error);
    return;
  }
});

// ============================================================================
// CLOUD FUNCTIONS - LEVEL UP
// ============================================================================

// Level up logic moved to onUserActivityCreated in index.ts for efficiency.

// ============================================================================
// CLOUD FUNCTIONS - DAILY AI INSIGHTS
// ============================================================================

/**
 * Daily scheduled function for AI insights.
 */
export const sendDailyInsights = onSchedule({
  schedule: "0 8 * * *",
  timeZone: "UTC",
  memory: "256MiB",
}, async (event) => {
  const firestore = getDb();
  console.log("Running daily insights at:", event.scheduleTime);

  try {
    const usersSnapshot = await firestore.collection("users").get();
    for (const userDoc of usersSnapshot.docs) {
      const userData = userDoc.data();
      const settings = userData?.settings || {};
      if (userData.notificationsEnabled === false || settings.aiInsights === false) continue;

      const userId = userDoc.id;
      const archetype = userData.archetype || "none";
      const insight = await generateAIInsight(userId);

      await sendNotification(userId, "Daily Growth Insight", `${getTemplateMessage(archetype, "aiInsightGreeting")}\n\n${insight}`, "daily_insight", {
        archetype,
      });
    }
    return;
  } catch (error) {
    console.error("Error in sendDailyInsights:", error);
    return;
  }
});

// ============================================================================
// CLOUD FUNCTIONS - ACHIEVEMENT NOTIFICATIONS
// ============================================================================

/**
 * Triggered when an achievement is earned.
 */
export const notifyAchievement = onDocumentCreated("users/{userId}/achievements/{achievementId}", async (event) => {
  const achievement = event.data?.data();
  if (!achievement) return;

  const userId = event.params.userId;
  const firestore = getDb();

  try {
    const userDoc = await firestore.collection("users").doc(userId).get();
    const userData = userDoc.data();
    const settings = userData?.settings || {};
    const archetype = userData?.archetype || "none";

    if (userData?.notificationsEnabled === false || settings.rewardsUpdates === false) {
      return;
    }

    await sendNotification(userId, "Achievement Earned!", `${achievement.title}: ${achievement.description}`, "achievement", {
      achievementId: event.params.achievementId,
      archetype,
    });
    return;
  } catch (error) {
    console.error(`Error in notifyAchievement:`, error);
    return;
  }
});

// ============================================================================
// CLOUD FUNCTIONS - TEST FUNCTIONS
// ============================================================================

/*
export const testNotificationTemplates = onCall(async (request) => {
  const { archetype = "none", type = "welcome", userId } = request.data;

  if (!userId) {
    throw new HttpsError("invalid-argument", "The function must be called with a userId.");
  }

  const message = getTemplateMessage(archetype, type as any, "Test Habit/3");
  await sendNotification(userId, `Test: ${type}`, message, "test_notification", { archetype, type });

  return { success: true, message: `Notification of type ${type} sent to ${userId} using ${archetype} archetype.` };
});
*/

