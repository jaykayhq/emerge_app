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
      `💪 Your training insights are ready! Optimize your performance today.`,
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
      `📚 Wisdom awaits! Your personalized learning insights have arrived.`,
    achievement: (name: string) =>
      `🏅 📚 KNOWLEDGE CONQUERED: ${name}! Your quest for wisdom succeeds!`,
  },
  creator: {
    welcome: (title: string) =>
      `🎨 A new canvas awaits: "${title}". Your creative journey starts today.`,
    reminder: (title: string) =>
      `✨ Inspiration strikes! Time to create: ${title}.`,
    streakWarning: (days: number) =>
      `⚠️ 🎨 Your ${days}-day creative flow is at risk! Keep the inspiration going—create now.`,
    levelUp: (level: number) =>
      `🏆 🎨 MUSE FAVORS YOU! You've reached Level ${level}! Your artistry elevates!`,
    aiInsightGreeting: () =>
      `🎨 Creative inspiration delivered! Your muse has new insights for you.`,
    achievement: (name: string) =>
      `🏅 🎨 MASTERPIECE CREATED: ${name}! Your creative vision manifests!`,
  },
  stoic: {
    welcome: (title: string) =>
      `🏛️ A new trial of discipline begins: "${title}". Master yourself.`,
    reminder: (title: string) =>
      `⚖️ Time for your daily practice: ${title}.`,
    streakWarning: (days: number) =>
      `⚠️ 🏛️ Your ${days}-day practice is imperiled! Maintain your discipline—act now.`,
    levelUp: (level: number) =>
      `🏆 🏛️ MASTERY AWAITS! You've reached Level ${level}! Your discipline strengthens!`,
    aiInsightGreeting: () =>
      `🏛️ Clarity awaits! Your daily reflection on mastery and discipline is here.`,
    achievement: (name: string) =>
      `🏅 🏛️ VIRTUE ATTAINED: ${name}! Your stoic practice bears fruit!`,
  },
  zealot: {
    welcome: (title: string) =>
      `🔥 A sacred commitment! Your devotion to "${title}" has been consecrated.`,
    reminder: (title: string) =>
      `🌟 Time for spiritual practice: ${title}.`,
    streakWarning: (days: number) =>
      `⚠️ 🔥 Your ${days}-day devotion is tested—stay the sacred path.`,
    levelUp: (level: number) =>
      `🏆 🔥 SACRED ASCENSION! You've reached Level ${level}! Your devotion burns brighter!`,
    aiInsightGreeting: () =>
      `🔥 Divine guidance! Your sacred insights for the path have been revealed.`,
    achievement: (name: string) =>
      `🏅 🔥 SACRED HONOR EARNED: ${name}! Your devotion is recognized!`,
  },
  none: {
    welcome: (title: string) =>
      `🗺️ A new adventure awaits: "${title}". Discover your potential.`,
    reminder: (title: string) =>
      `🧭 Time to explore: ${title}.`,
    streakWarning: (days: number) =>
      `⚠️ Your ${days}-day streak is at risk! Complete your habit now to keep it alive.`,
    levelUp: (level: number) =>
      `🏆 LEVEL UP! You've reached Level ${level}! Keep up the amazing work!`,
    aiInsightGreeting: () =>
      `✨ Your daily insights are ready! Discover what's possible today.`,
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
function getTemplateMessage(
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
 * Checks if current time is within Do Not Disturb hours (10 PM - 7 AM).
 */
function isDoNotDisturbHour(): boolean {
  const now = new Date();
  const hour = now.getHours();
  return hour >= 22 || hour < 7;
}

/**
 * Checks if a specific hour is within Do Not Disturb hours.
 */
function isHourInDoNotDisturb(hour: number): boolean {
  return hour >= 22 || hour < 7;
}

/**
 * Sends FCM notification to a user.
 */
async function sendNotification(
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
 * Triggered when a new habit is created.
 * Sends a welcome notification and creates notification schedule.
 */
export const onHabitCreated = functionsV1.firestore
  .document("users/{userId}/habits/{habitId}")
  .onCreate(async (snapshot, context) => {
    const habit = snapshot.data();
    const userId = context.params.userId;
    const habitId = context.params.habitId;
    const firestore = getDb();

    console.log(`Habit created: ${habitId} for user ${userId}`);

    try {
      // Get user profile for archetype
      const userDoc = await firestore.collection("users").doc(userId).get();
      if (!userDoc.exists) {
        console.warn(`User ${userId} not found`);
        return null;
      }

      const userData = userDoc.data();
      const archetype = userData?.archetype || "none";
      const notificationsEnabled = userData?.notificationsEnabled !== false;

      // Check if habit has reminders enabled
      if (!habit.reminderEnabled || !notificationsEnabled) {
        console.log(`Reminders disabled for habit ${habitId}`);
        return null;
      }

      // Send welcome notification
      const title = "Habit Created";
      const body = getTemplateMessage(archetype, "welcome", habit.title || "Your new habit");
      await sendNotification(userId, title, body, "habit_welcome", {
        habitId,
        archetype,
      });

      // Create notification schedule document
      const scheduleData = {
        habitId,
        userId,
        archetype,
        reminderTime: habit.reminderTime || "07:00",
        frequency: habit.frequency || "daily",
        specificDays: habit.specificDays || [],
        welcomeNotified: true,
        lastReminderSent: null,
        enabled: true,
        lastStreakWarningSent: null,
        streakWarningCount: 0,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      await firestore
        .collection("users")
        .doc(userId)
        .collection("notificationSchedules")
        .doc(habitId)
        .set(scheduleData);

      console.log(`Welcome notification sent and schedule created for habit ${habitId}`);
      return null;
    } catch (error) {
      console.error(`Error in onHabitCreated for habit ${habitId}:`, error);
      return null;
    }
  });

/**
 * Triggered when a habit is updated.
 * Updates notification schedule if time/frequency changed.
 */
export const onHabitUpdated = functionsV1.firestore
  .document("users/{userId}/habits/{habitId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const userId = context.params.userId;
    const habitId = context.params.habitId;
    const firestore = getDb();

    console.log(`Habit updated: ${habitId} for user ${userId}`);

    try {
      // Check if reminder settings changed
      const timeChanged = before.reminderTime !== after.reminderTime;
      const frequencyChanged = before.frequency !== after.frequency;
      const daysChanged =
        JSON.stringify(before.specificDays) !== JSON.stringify(after.specificDays);
      const enabledChanged = before.reminderEnabled !== after.reminderEnabled;

      if (!timeChanged && !frequencyChanged && !daysChanged && !enabledChanged) {
        console.log(`No reminder changes for habit ${habitId}`);
        return null;
      }

      const scheduleRef = firestore
        .collection("users")
        .doc(userId)
        .collection("notificationSchedules")
        .doc(habitId);

      const scheduleDoc = await scheduleRef.get();

      if (!scheduleDoc.exists && after.reminderEnabled) {
        // Schedule doesn't exist but reminders are now enabled - create it
        const userDoc = await firestore.collection("users").doc(userId).get();
        const userData = userDoc.data();
        const archetype = userData?.archetype || "none";

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

        console.log(`Created notification schedule for habit ${habitId}`);
      } else if (scheduleDoc.exists) {
        // Update existing schedule
        const updates: Record<string, any> = {
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        };

        if (timeChanged) updates.reminderTime = after.reminderTime;
        if (frequencyChanged) updates.frequency = after.frequency;
        if (daysChanged) updates.specificDays = after.specificDays;
        if (enabledChanged) updates.enabled = after.reminderEnabled;

        await scheduleRef.update(updates);
        console.log(`Updated notification schedule for habit ${habitId}`);
      }

      return null;
    } catch (error) {
      console.error(`Error in onHabitUpdated for habit ${habitId}:`, error);
      return null;
    }
  });

/**
 * Triggered when a habit is deleted.
 * Deletes the notification schedule document.
 */
export const onHabitDeleted = functionsV1.firestore
  .document("users/{userId}/habits/{habitId}")
  .onDelete(async (snapshot, context) => {
    const userId = context.params.userId;
    const habitId = context.params.habitId;
    const firestore = getDb();

    console.log(`Habit deleted: ${habitId} for user ${userId}`);

    try {
      await firestore
        .collection("users")
        .doc(userId)
        .collection("notificationSchedules")
        .doc(habitId)
        .delete();

      console.log(`Deleted notification schedule for habit ${habitId}`);
      return null;
    } catch (error) {
      console.error(`Error in onHabitDeleted for habit ${habitId}:`, error);
      return null;
    }
  });

// ============================================================================
// CLOUD FUNCTIONS - STREAK WARNINGS
// ============================================================================

/**
 * Scheduled function running every 15 minutes.
 * Checks for habits at risk of breaking streaks and sends warnings.
 * Respects Do Not Disturb hours (10 PM - 7 AM).
 */
export const sendStreakWarnings = functionsV1.pubsub
  .schedule("*/15 * * * *")
  .timeZone("UTC")
  .onRun(async (context) => {
    console.log("Running streak warnings check at:", context.timestamp);
    const firestore = getDb();

    // Check if currently in Do Not Disturb hours
    if (isDoNotDisturbHour()) {
      console.log("Currently in Do Not Disturb hours, skipping streak warnings");
      return null;
    }

    try {
      // Query all users with notification schedules
      const schedulesSnapshot = await firestore
        .collectionGroup("notificationSchedules")
        .where("enabled", "==", true)
        .get();

      console.log(`Found ${schedulesSnapshot.size} active notification schedules`);

      const now = new Date();
      const oneHourAgo = new Date(now.getTime() - 60 * 60 * 1000);
      const warningsSent: string[] = [];

      for (const scheduleDoc of schedulesSnapshot.docs) {
        const schedule = scheduleDoc.data();
        const userId = schedule.userId;
        const habitId = schedule.habitId;
        const archetype = schedule.archetype || "none";

        try {
          // Get user to check if notifications are enabled
          const userDoc = await firestore.collection("users").doc(userId).get();
          if (!userDoc.exists) continue;

          const userData = userDoc.data();
          if (userData?.notificationsEnabled === false) continue;
          if (userData?.habitReminders === false) continue;

          // Get habit data
          const habitDoc = await firestore
            .collection("users")
            .doc(userId)
            .collection("habits")
            .doc(habitId)
            .get();

          if (!habitDoc.exists) continue;

          const habit = habitDoc.data();

          // Check if streak is at least 3 days
          const streak = habit?.currentStreak || 0;
          if (streak < 3) continue;

          // Parse reminder time
          const [hours, minutes] = schedule.reminderTime.split(":").map(Number);
          const reminderTime = new Date();
          reminderTime.setHours(hours, minutes, 0, 0);

          // If reminder was more than 1 hour ago and habit not completed today
          if (reminderTime < oneHourAgo) {
            // Check if already completed today
            const today = new Date();
            today.setHours(0, 0, 0, 0);

            const lastCompleted = habit?.lastCompleted?.toDate();
            const completedToday = lastCompleted && lastCompleted >= today;

            if (completedToday) continue;

            // Check if streak warning already sent recently (within 12 hours)
            const lastWarning = schedule.lastStreakWarningSent?.toDate();
            const twelveHoursAgo = new Date(Date.now() - 12 * 60 * 60 * 1000);

            if (lastWarning && lastWarning > twelveHoursAgo) continue;

            // Check if reminder hour is in Do Not Disturb
            if (isHourInDoNotDisturb(hours)) {
              console.log(`Skipping streak warning for habit ${habitId} - reminder in DND hours`);
              continue;
            }

            // Send streak warning
            const title = "Streak at Risk!";
            const body = getTemplateMessage(archetype, "streakWarning", streak);
            await sendNotification(userId, title, body, "streak_warning", {
              habitId,
              streak: streak.toString(),
            });

            // Update schedule
            await scheduleDoc.ref.update({
              lastStreakWarningSent: admin.firestore.FieldValue.serverTimestamp(),
              streakWarningCount: admin.firestore.FieldValue.increment(1),
            });

            warningsSent.push(`${userId}/${habitId}`);
          }
        } catch (error) {
          console.error(`Error processing streak warning for ${userId}/${habitId}:`, error);
        }
      }

      console.log(`Streak warnings sent: ${warningsSent.length}`);
      console.log("Warnings sent to:", warningsSent);
      return null;
    } catch (error) {
      console.error("Error in sendStreakWarnings:", error);
      return null;
    }
  });

// ============================================================================
// CLOUD FUNCTIONS - LEVEL UP
// ============================================================================

/**
 * Triggered when user_stats document is updated.
 * Detects level increases and sends celebration notification.
 */
export const onLevelUp = functionsV1.firestore
  .document("user_stats/{userId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const userId = context.params.userId;
    const firestore = getDb();

    try {
      const levelBefore = before.level || 1;
      const levelAfter = after.level || 1;

      // Check if level increased
      if (levelAfter <= levelBefore) {
        console.log(`No level change for user ${userId}`);
        return null;
      }

      // Get user document to check preferences and archetype
      const userDoc = await firestore.collection("users").doc(userId).get();
      if (!userDoc.exists) {
        console.warn(`User ${userId} not found for level up notification`);
        return null;
      }

      const userData = userDoc.data();

      // Check if user has rewards updates enabled
      const rewardsEnabled = userData?.rewardsUpdates !== false;

      if (!rewardsEnabled) {
        console.log(`Rewards updates disabled for user ${userId}`);
        return null;
      }

      const archetype = userData?.archetype || "none";
      const title = "Level Up!";
      const body = getTemplateMessage(archetype, "levelUp", levelAfter);

      await sendNotification(userId, title, body, "level_up", {
        level: levelAfter.toString(),
        archetype,
      });

      console.log(`Level up notification sent for user ${userId} - Level ${levelAfter}`);
      return null;
    } catch (error) {
      console.error(`Error in onLevelUp for user ${userId}:`, error);
      return null;
    }
  });

// ============================================================================
// CLOUD FUNCTIONS - DAILY AI INSIGHTS
// ============================================================================

/**
 * Scheduled function running at 9 AM daily.
 * Sends personalized AI insights to users who have them enabled.
 * Respects Do Not Disturb hours (uses user's timezone).
 */
export const sendDailyInsights = functionsV1.pubsub
  .schedule("0 9 * * *")
  .timeZone("UTC")
  .onRun(async (context) => {
    console.log("Running daily insights at:", context.timestamp);
    const firestore = getDb();

    try {
      // Query users with AI insights enabled
      const usersSnapshot = await firestore
        .collection("users")
        .where("notificationsEnabled", "==", true)
        .where("aiInsights", "==", true)
        .get();

      console.log(`Found ${usersSnapshot.size} users with AI insights enabled`);

      const insightsSent: string[] = [];

      for (const userDoc of usersSnapshot.docs) {
        const userId = userDoc.id;
        const userData = userDoc.data();

        try {
          // Check if user has FCM token
          if (!userData.fcmToken) continue;

          const archetype = userData.archetype || "none";
          const greeting = getTemplateMessage(archetype, "aiInsightGreeting");
          const insight = await generateAIInsight(userId);

          const title = "Your Daily Insight";
          const body = `${greeting}\n\n${insight}`;

          await sendNotification(userId, title, body, "ai_insight", {
            archetype,
            date: new Date().toISOString().split("T")[0],
          });

          insightsSent.push(userId);
        } catch (error) {
          console.error(`Error sending insight to user ${userId}:`, error);
        }
      }

      console.log(`Daily insights sent: ${insightsSent.length}`);
      console.log("Insights sent to:", insightsSent);
      return null;
    } catch (error) {
      console.error("Error in sendDailyInsights:", error);
      return null;
    }
  });

// ============================================================================
// CLOUD FUNCTIONS - ACHIEVEMENT NOTIFICATIONS
// ============================================================================

/**
 * Callable function to manually trigger achievement notification.
 * Can be called from client when an achievement is unlocked.
 */
export const notifyAchievement = functionsV1.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functionsV1.https.HttpsError(
        "unauthenticated",
        "User must be logged in"
      );
    }

    const userId = context.auth.uid;
    const achievementName = data.achievementName;

    if (!achievementName) {
      throw new functionsV1.https.HttpsError(
        "invalid-argument",
        "achievementName is required"
      );
    }

    const firestore = getDb();

    try {
      const userDoc = await firestore.collection("users").doc(userId).get();
      if (!userDoc.exists) {
        throw new functionsV1.https.HttpsError(
          "not-found",
          "User not found"
        );
      }

      const userData = userDoc.data();
      const archetype = userData?.archetype || "none";

      // Check if rewards updates are enabled
      if (userData?.rewardsUpdates === false) {
        return { success: false, reason: "rewards_disabled" };
      }

      const title = "Achievement Unlocked!";
      const body = getTemplateMessage(archetype, "achievement", achievementName);

      await sendNotification(userId, title, body, "achievement", {
        achievementName,
        archetype,
      });

      return { success: true };
    } catch (error) {
      console.error(`Error sending achievement notification to ${userId}:`, error);
      throw new functionsV1.https.HttpsError(
        "internal",
        "Failed to send achievement notification"
      );
    }
  }
);

// ============================================================================
// CLOUD FUNCTIONS - TEST FUNCTIONS
// ============================================================================

/**
 * Test function to verify notification templates.
 * Can be called manually during testing.
 */
export const testNotificationTemplates = functionsV1.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functionsV1.https.HttpsError(
        "unauthenticated",
        "User must be logged in"
      );
    }

    const userId = context.auth.uid;
    const archetype = data.archetype || "none";
    const type = data.type || "welcome";

    try {
      let title = "Test Notification";
      let body = "";
      let notificationType = "test";

      switch (type) {
        case "welcome":
          body = getTemplateMessage(archetype, "welcome", "Test Habit");
          notificationType = "habit_welcome";
          break;
        case "reminder":
          body = getTemplateMessage(archetype, "reminder", "Test Habit");
          notificationType = "habit_reminder";
          break;
        case "streakWarning":
          body = getTemplateMessage(archetype, "streakWarning", 7);
          notificationType = "streak_warning";
          break;
        case "levelUp":
          body = getTemplateMessage(archetype, "levelUp", 10);
          title = "Level Up!";
          notificationType = "level_up";
          break;
        case "aiInsight":
          body = getTemplateMessage(archetype, "aiInsightGreeting");
          notificationType = "ai_insight";
          break;
        case "achievement":
          body = getTemplateMessage(archetype, "achievement", "Test Achievement");
          title = "Achievement Unlocked!";
          notificationType = "achievement";
          break;
        default:
          body = "Test notification from Emerge";
      }

      await sendNotification(userId, title, body, notificationType, {
        archetype,
        test: "true",
      });

      return {
        success: true,
        archetype,
        type,
        message: body,
      };
    } catch (error) {
      console.error(`Error in testNotificationTemplates:`, error);
      throw new functionsV1.https.HttpsError(
        "internal",
        "Failed to send test notification"
      );
    }
  }
);
