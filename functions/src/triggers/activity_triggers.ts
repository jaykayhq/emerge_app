
import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";

// Define interface for data structure
interface UserActivity {
    userId: string;
    habitId?: string;
    type: string;
    date: admin.firestore.Timestamp;
    xpEarned?: number; // Only used for legacy or manual overrides, usually calculated here
}

/**
 * Triggered when a new user activity is created.
 * Calculates XP based on the activity and updates the user's stats and level.
 */
export const onUserActivityCreated = functions.firestore
    .document("user_activity/{activityId}")
    .onCreate(async (snapshot, context) => {
        const activity = snapshot.data() as UserActivity;
        const db = admin.firestore();
        const userStatsRef = db.collection("user_stats").doc(activity.userId);

        // Fetch Remote Config or use defaults for XP values
        // Note: In Cloud Functions Gen 1, fetching Remote Config constantly can be slow.
        // For production, consider caching or using a dedicated Firestore config doc.
        // For now, we will use hardcoded defaults that match the plan,
        // which can be easily swapped for Remote Config fetch later.
        const XP_CONFIG = {
            base_habit_xp: 50,
            level_formula_constant: 100,
            attribute_bonus_multiplier: 1.1,
            level_exponent: 1.5, // Level = Constant * (XP ^ Exponent) inverse... XP = Level^Exponent * Constant?
            // Simple formula: Level = floor(sqrt(totalXP / 100)) + 1
            // OR Linear/Exponential as desired.
            // Let's go with: Level = floor(sqrt(totalXP / 50)) + 1 for faster early progression
        };

        let xpToAdd = 0;

        if (activity.type === "habit_completion") {
            xpToAdd = XP_CONFIG.base_habit_xp;
        } else if (activity.type === "joined_challenge") {
            xpToAdd = 25;
        } else if (activity.type === "joined_tribe") {
            xpToAdd = 50;
        }

        if (xpToAdd === 0) {
            console.log(`No XP to add for activity type: ${activity.type}`);
            return null;
        }

        try {
            await db.runTransaction(async (transaction) => {
                const userStatsDoc = await transaction.get(userStatsRef);

                if (!userStatsDoc.exists) {
                    // Initialize if missing (should be handled by onUserCreated, but safe to allow)
                    console.warn(`User stats missing for ${activity.userId}, creating new.`);
                    transaction.set(userStatsRef, {
                        currentXp: xpToAdd,
                        currentLevel: 1,
                        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                    });
                    return;
                }

                const data = userStatsDoc.data()!;
                const currentXp = (data.currentXp || 0) as number;
                const currentLevel = (data.currentLevel || 1) as number;

                const newXp = currentXp + xpToAdd;

                // Level Formula: Level = floor(sqrt(newXp / 100)) + 1
                // 100 XP = lvl 2
                // 400 XP = lvl 3
                // 900 XP = lvl 4
                const newLevel = Math.floor(Math.sqrt(newXp / 100)) + 1;

                const updates: any = {
                    currentXp: newXp,
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                };

                if (newLevel > currentLevel) {
                    updates.currentLevel = newLevel;
                    // Trigger any level-up notifications or rewards here
                    console.log(`User ${activity.userId} leveled up to ${newLevel}!`);
                }

                transaction.update(userStatsRef, updates);

                // Write back the earned XP to the activity log for history/recaps
                const activityRef = db.collection("user_activity").doc(context.params.activityId);
                transaction.update(activityRef, { xpEarned: xpToAdd });
            });
            console.log(`Processed activity ${context.params.activityId} for user ${activity.userId}. Added ${xpToAdd} XP.`);
        } catch (error) {
            console.error("Error updating user stats:", error);
            // Consider wether to retry or alerting
        }
        return null;
    });
