import { onRequest } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

// Ensure admin is initialized
if (admin.apps.length === 0) {
  admin.initializeApp();
}

// Validate required environment variables
function getRequiredEnvVar(name: string): string {
  const value = process.env[name];
  if (!value) {
    throw new Error(`Required environment variable ${name} is not set.`);
  }
  return value;
}

/**
 * Creates or resets the reviewer account in Firebase Auth + Firestore (Gen 2).
 */
export const seedReviewerAccount = onRequest({
  secrets: ["REVIEWER_EMAIL", "REVIEWER_PASSWORD"],
}, async (req, res) => {
  try {
    const REVIEWER_EMAIL = getRequiredEnvVar("REVIEWER_EMAIL");
    const REVIEWER_PASSWORD = getRequiredEnvVar("REVIEWER_PASSWORD");
    const REVIEWER_DISPLAY_NAME = process.env.REVIEWER_DISPLAY_NAME || "Play Reviewer";

    const auth = admin.auth();
    const db = admin.firestore();

    let uid: string;
    try {
      const existing = await auth.getUserByEmail(REVIEWER_EMAIL);
      uid = existing.uid;
      await auth.updateUser(uid, {
        password: REVIEWER_PASSWORD,
        displayName: REVIEWER_DISPLAY_NAME,
      });
    } catch (err: any) {
      if (err.code === "auth/user-not-found") {
        const newUser = await auth.createUser({
          email: REVIEWER_EMAIL,
          password: REVIEWER_PASSWORD,
          displayName: REVIEWER_DISPLAY_NAME,
          emailVerified: true,
        });
        uid = newUser.uid;
      } else {
        throw err;
      }
    }

    const now = new Date().toISOString();
    const userProfile: Record<string, any> = {
      uid: uid,
      email: REVIEWER_EMAIL,
      displayName: REVIEWER_DISPLAY_NAME,
      archetype: "athlete",
      identityVotes: { Runner: 15, "Early Riser": 10, Reader: 5 },
      avatarStats: {
        strengthXp: 350,
        intellectXp: 200,
        vitalityXp: 180,
        creativityXp: 120,
        focusXp: 250,
        spiritXp: 100,
        challengeXp: 0,
        level: 3,
        streak: 7,
        attributeXp: {},
        totalXp: 1200,
        lastUpdate: admin.firestore.FieldValue.serverTimestamp(),
      },
      worldState: {
        cityLevel: 2,
        forestLevel: 2,
        entropy: 0.05,
        worldAge: 14,
        zones: {
          garden: { zoneId: "garden", level: 2, health: 0.9, milestone: 1, activeElements: [] },
          library: { zoneId: "library", level: 1, health: 1.0, milestone: 0, activeElements: [] },
          forge: { zoneId: "forge", level: 2, health: 0.85, milestone: 1, activeElements: [] },
          studio: { zoneId: "studio", level: 1, health: 1.0, milestone: 0, activeElements: [] },
          shrine: { zoneId: "shrine", level: 1, health: 1.0, milestone: 0, activeElements: [] },
          temple: { zoneId: "temple", level: 1, health: 1.0, milestone: 0, activeElements: [] },
        },
        unlockedBuildings: ["garden_fountain", "forge_anvil"],
        buildingPlacements: [],
        unlockedLandPlots: [],
        totalBuildingsConstructed: 2,
        lastActiveDate: admin.firestore.FieldValue.serverTimestamp(),
        worldTheme: "sanctuary",
        seasonalState: "spring",
        claimedNodes: ["node_1", "node_2"],
        activeNodes: [],
        highestCompletedNodeLevel: 2,
      },
      reframeMode: false,
      motive: "Build lasting healthy habits",
      why: "To become the best version of myself",
      anchors: ["Morning Coffee", "After Lunch"],
      onboardingProgress: 3,
      onboardingStartedAt: now,
      onboardingCompletedAt: now,
      avatar: {
        skinTone: 3,
        hairStyle: 1,
        hairColor: 2,
        outfit: 0,
        accessory: 0,
        expression: 0,
        evolutionStage: 1,
      },
      settings: {
        notificationsEnabled: true,
        healthKitConnected: false,
        screenTimeConnected: false,
        soundsEnabled: true,
        hapticsEnabled: true,
        habitReminders: true,
        streakWarnings: true,
        aiInsights: true,
        communityUpdates: false,
        rewardsUpdates: true,
        doNotDisturb: false,
      },
      accountCreatedAt: now,
      hasEmerged: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    await db.collection("users").doc(uid).set(userProfile, { merge: true });
    await db.collection("user_stats").doc(uid).set(userProfile, { merge: true });

    const habitsRef = db.collection("users").doc(uid).collection("habits");
    const sampleHabits = [
      {
        id: "reviewer_habit_1",
        title: "Morning Run",
        description: "Run for 30 minutes every morning",
        frequency: "daily",
        reminderTime: "06:30",
        specificDays: [],
        attribute: "strength",
        difficulty: "medium",
        isActive: true,
        createdAt: now,
        completedDates: [],
        currentStreak: 7,
        bestStreak: 7,
        totalCompletions: 14,
      },
      {
        id: "reviewer_habit_2",
        title: "Read for 20 Minutes",
        description: "Read a chapter of a book",
        frequency: "daily",
        reminderTime: "21:00",
        specificDays: [],
        attribute: "intellect",
        difficulty: "easy",
        isActive: true,
        createdAt: now,
        completedDates: [],
        currentStreak: 5,
        bestStreak: 5,
        totalCompletions: 10,
      },
    ];

    for (const habit of sampleHabits) {
      await habitsRef.doc(habit.id).set(habit, { merge: true });
    }

    const tribeQuery = await db.collection("tribes").where("archetype", "==", "athlete").limit(1).get();
    if (!tribeQuery.empty) {
      const tribeDoc = tribeQuery.docs[0];
      await tribeDoc.ref.update({
        memberIds: admin.firestore.FieldValue.arrayUnion(uid),
        memberCount: admin.firestore.FieldValue.increment(1),
      });
    }

    res.status(200).json({ success: true, message: "Reviewer account seeded successfully", credentials: { email: REVIEWER_EMAIL, password: REVIEWER_PASSWORD }, uid: uid });
  } catch (error) {
    console.error("Error seeding reviewer account:", error);
    res.status(500).json({ success: false, error: (error as Error).message });
  }
});

