/**
 * Cloud Function: Seed a Google Play Reviewer Test Account
 *
 * Creates (or resets) a Firebase Auth user with known credentials
 * and populates Firestore with a fully-fleshed UserProfile so
 * Google reviewers can access all restricted areas of the app.
 *
 * SECURITY: These credentials MUST be set via Firebase Secrets Manager in production:
 *   REVIEWER_EMAIL - The email for the reviewer account
 *   REVIEWER_PASSWORD - The password for the reviewer account
 *
 * Invoke via:
 *   firebase functions:shell → seedReviewerAccount()
 *   OR deploy and call via the Firebase Console "Run in Cloud Shell"
 */

import * as functionsV1 from "firebase-functions/v1";
import * as admin from "firebase-admin";

// Ensure admin is initialized (lazy — other modules may have done it)
if (admin.apps.length === 0) {
  admin.initializeApp();
}

// Validate required environment variables - fail fast in production
function getRequiredEnvVar(name: string): string {
  const value = process.env[name];
  if (!value) {
    throw new Error(
      `Required environment variable ${name} is not set. ` +
      `Please set it via Firebase Secrets Manager: ` +
      `firebase secrets:create ${name}`
    );
  }
  return value;
}

// Use environment variables - no fallbacks for production safety
const REVIEWER_EMAIL = getRequiredEnvVar("REVIEWER_EMAIL");
const REVIEWER_PASSWORD = getRequiredEnvVar("REVIEWER_PASSWORD");
const REVIEWER_DISPLAY_NAME = process.env.REVIEWER_DISPLAY_NAME || "Play Reviewer";

/**
 * Creates or resets the reviewer account in Firebase Auth + Firestore.
 */
export const seedReviewerAccount = functionsV1.https.onRequest(
  async (_req, res) => {
    try {
      const auth = admin.auth();
      const db = admin.firestore();

      // ── 1. Create or get the Auth user ──────────────────────────
      let uid: string;
      try {
        const existing = await auth.getUserByEmail(REVIEWER_EMAIL);
        uid = existing.uid;
        // Reset password in case it was changed
        await auth.updateUser(uid, {
          password: REVIEWER_PASSWORD,
          displayName: REVIEWER_DISPLAY_NAME,
        });
        console.log(`Reviewer account already exists: ${uid}. Password reset.`);
      } catch (err: any) {
        if (err.code === "auth/user-not-found") {
          const newUser = await auth.createUser({
            email: REVIEWER_EMAIL,
            password: REVIEWER_PASSWORD,
            displayName: REVIEWER_DISPLAY_NAME,
            emailVerified: true,
          });
          uid = newUser.uid;
          console.log(`Created new reviewer account: ${uid}`);
        } else {
          throw err;
        }
      }

      // ── 2. Seed UserProfile in 'users' collection ───────────────
      const now = new Date().toISOString();

      const userProfile: Record<string, any> = {
        uid: uid,
        email: REVIEWER_EMAIL,
        displayName: REVIEWER_DISPLAY_NAME,
        archetype: "athlete", // Give reviewer a concrete archetype
        identityVotes: {Runner: 15, "Early Riser": 10, Reader: 5},
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
            garden: {
              zoneId: "garden",
              level: 2,
              health: 0.9,
              milestone: 1,
              activeElements: [],
            },
            library: {
              zoneId: "library",
              level: 1,
              health: 1.0,
              milestone: 0,
              activeElements: [],
            },
            forge: {
              zoneId: "forge",
              level: 2,
              health: 0.85,
              milestone: 1,
              activeElements: [],
            },
            studio: {
              zoneId: "studio",
              level: 1,
              health: 1.0,
              milestone: 0,
              activeElements: [],
            },
            shrine: {
              zoneId: "shrine",
              level: 1,
              health: 1.0,
              milestone: 0,
              activeElements: [],
            },
            temple: {
              zoneId: "temple",
              level: 1,
              health: 1.0,
              milestone: 0,
              activeElements: [],
            },
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
        habitStacks: [],
        onboardingProgress: 3,
        skippedOnboardingSteps: [],
        onboardingStartedAt: now,
        onboardingCompletedAt: now,
        equipment: [],
        characterClass: null,
        avatar: {
          skinTone: 3,
          hairStyle: 1,
          hairColor: 2,
          outfit: 0,
          accessory: 0,
          expression: 0,
          evolutionStage: 1,
        },
        worldTheme: null,
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

      await db.collection("users").doc(uid).set(userProfile, {merge: true});

      // ── 3. Seed user_stats (mirrored for legacy compat) ─────────
      await db.collection("user_stats").doc(uid).set(userProfile, {merge: true});

      // ── 4. Seed a couple of sample habits ───────────────────────
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
          integrationType: "none",
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
          integrationType: "none",
          isActive: true,
          createdAt: now,
          completedDates: [],
          currentStreak: 5,
          bestStreak: 5,
          totalCompletions: 10,
        },
      ];

      for (const habit of sampleHabits) {
        await habitsRef.doc(habit.id).set(habit, {merge: true});
      }

      // ── 5. Auto-join the Athlete tribe ──────────────────────────
      const tribeQuery = await db
        .collection("tribes")
        .where("archetype", "==", "athlete")
        .limit(1)
        .get();

      if (!tribeQuery.empty) {
        const tribeDoc = tribeQuery.docs[0];
        await tribeDoc.ref.update({
          memberIds: admin.firestore.FieldValue.arrayUnion(uid),
          memberCount: admin.firestore.FieldValue.increment(1),
        });
        console.log(`Added reviewer to Athlete tribe: ${tribeDoc.id}`);
      }

      res.status(200).json({
        success: true,
        message: "Reviewer account seeded successfully",
        credentials: {
          email: REVIEWER_EMAIL,
          password: REVIEWER_PASSWORD,
        },
        uid: uid,
      });
    } catch (error) {
      console.error("Error seeding reviewer account:", error);
      res.status(500).json({
        success: false,
        error: (error as Error).message,
      });
    }
  }
);
