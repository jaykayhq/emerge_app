/**
 * Firebase Cloud Functions - Emerge App (Gen 1)
 * 
 * Cost-optimized for scale:
 * - Single XP/Level trigger (no duplicates)
 * - Batched operations where possible
 * - Minimal reads per invocation
 * - Lazy initialization to avoid deployment timeouts
 */

import * as functionsV1 from 'firebase-functions/v1';
import * as admin from 'firebase-admin';

// Lazy initialization pattern
let db: admin.firestore.Firestore | null = null;

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
  habit_completion: 50,
  joined_challenge: 25,
  joined_tribe: 50,
  reflection_saved: 15,
};

const MAX_STREAK_MULTIPLIER = 2.0;

interface UserActivity {
  userId: string;
  habitId?: string;
  type: string;
  difficulty?: 'easy' | 'medium' | 'hard';
  streakDay?: number;
}

function calculateLevel(totalXp: number): number {
  return Math.floor(Math.sqrt(totalXp / 100)) + 1;
}

function calculateXpGain(activity: UserActivity): number {
  const baseXp = XP_CONFIG[activity.type] || 0;
  if (baseXp === 0) return 0;

  let xp = baseXp;

  // Apply difficulty multiplier for habits
  if (activity.type === 'habit_completion' && activity.difficulty) {
    const mult = activity.difficulty === 'hard' ? 1.5 : activity.difficulty === 'medium' ? 1.0 : 0.7;
    xp = Math.round(baseXp * mult);
  }

  // Apply streak bonus (capped)
  if (activity.streakDay && activity.streakDay > 1) {
    const streakMult = Math.min(1 + (activity.streakDay - 1) * 0.1, MAX_STREAK_MULTIPLIER);
    xp = Math.round(xp * streakMult);
  }

  return xp;
}

/**
 * Main trigger: Updates user stats when activity is logged
 */
export const onUserActivityCreated = functionsV1.firestore
  .document('user_activity/{activityId}')
  .onCreate(async (snapshot, context) => {
    const activity = snapshot.data() as UserActivity;
    const firestore = getDb();

    if (!activity.userId || !activity.type) {
      console.warn(`Invalid activity: ${context.params.activityId}`);
      return null;
    }

    const xpToAdd = calculateXpGain(activity);
    if (xpToAdd === 0) {
      console.log(`No XP for activity type: ${activity.type}`);
      return null;
    }

    const userStatsRef = firestore.collection('user_stats').doc(activity.userId);

    try {
      await firestore.runTransaction(async (transaction) => {
        const userStatsDoc = await transaction.get(userStatsRef);

        if (!userStatsDoc.exists) {
          transaction.set(userStatsRef, {
            userId: activity.userId,
            currentXp: xpToAdd,
            currentLevel: 1,
            totalCompletions: activity.type === 'habit_completion' ? 1 : 0,
            currentStreak: activity.streakDay || 0,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          return;
        }

        const data = userStatsDoc.data()!;
        const currentXp = (data.currentXp || 0) as number;
        const currentLevel = (data.currentLevel || 1) as number;
        const newXp = currentXp + xpToAdd;
        const newLevel = calculateLevel(newXp);

        const updates: Record<string, unknown> = {
          currentXp: newXp,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        };

        if (activity.type === 'habit_completion') {
          updates.totalCompletions = admin.firestore.FieldValue.increment(1);
        }

        if (activity.streakDay !== undefined) {
          updates.currentStreak = activity.streakDay;
        }

        if (newLevel > currentLevel) {
          updates.currentLevel = newLevel;
          console.log(`User ${activity.userId} leveled up to ${newLevel}!`);
        }

        transaction.update(userStatsRef, updates);
        transaction.update(
          firestore.collection('user_activity').doc(context.params.activityId),
          { xpEarned: xpToAdd }
        );
      });

      console.log(`Processed ${activity.type} for ${activity.userId}: +${xpToAdd} XP`);
    } catch (error) {
      console.error('Error updating user stats:', error);
    }

    return null;
  });

/**
 * Reset daily challenges at midnight UTC
 */
export const resetDailyChallenges = functionsV1.pubsub
  .schedule('0 0 * * *')
  .timeZone('UTC')
  .onRun(async () => {
    const firestore = getDb();
    const snapshot = await firestore.collection('challenges').where('type', '==', 'daily').get();

    if (snapshot.empty) {
      console.log('No daily challenges to reset');
      return null;
    }

    const batch = firestore.batch();
    snapshot.forEach((doc) => {
      batch.update(doc.ref, {
        participants: [],
        startDate: admin.firestore.FieldValue.serverTimestamp(),
        endDate: admin.firestore.Timestamp.now().toMillis() + 86400000,
      });
    });

    await batch.commit();
    console.log(`Reset ${snapshot.size} daily challenges`);
    return null;
  });

/**
 * Get AI coach insight based on user stats
 */
export const getAiCoachInsight = functionsV1.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functionsV1.https.HttpsError('unauthenticated', 'User must be logged in');
  }

  const userId = context.auth.uid;
  const firestore = getDb();

  try {
    const userStatsDoc = await firestore.collection('user_stats').doc(userId).get();

    if (!userStatsDoc.exists) {
      return { insight: 'Start your journey by completing your first habit!' };
    }

    const stats = userStatsDoc.data()!;
    const level = stats.currentLevel || 1;
    const streak = stats.currentStreak || 0;

    let insight = '';
    if (streak >= 7) {
      insight = `Amazing! Your ${streak}-day streak shows real commitment.`;
    } else if (streak >= 3) {
      insight = `${streak} days strong! Keep building momentum.`;
    } else if (level > 1) {
      insight = `Level ${level} achieved! Progress over perfection.`;
    } else {
      insight = 'Every expert was once a beginner. Start with one habit.';
    }

    return { insight, level, streak };
  } catch (error) {
    console.error('Error generating insight:', error);
    throw new functionsV1.https.HttpsError('internal', 'Failed to generate insight');
  }
});

// ============================================================================
// CHALLENGE TRIGGERS (Automated & Hybrid)
// ============================================================================
export * from './challenges';
export * from './seed_templates';
