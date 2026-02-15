/**
 * Firebase Cloud Function: Weekly Challenge Generator
 *
 * Automatically generates a new challenge every Monday at 9:00 AM UTC
 * from unused challenge templates in the challengeTemplates collection.
 *
 * Schedule: Every Monday 09:00 UTC
 * Trigger: Pub/Sub scheduling
 */

import * as functionsV1 from "firebase-functions/v1";
import * as admin from "firebase-admin";

if (admin.apps.length === 0) {
  admin.initializeApp();
}
const db = admin.firestore();

interface ChallengeTemplate {
  name: string;
  description: string;
  imageUrl: string;
  category: string;
  archetypeId?: string;
  daysRequired: number;
  habitType: string;
  xpReward: number;
  rewardDescription?: string;
  affiliatePartnerId?: string;
  difficulty: string;
}

/**
 * Weekly Challenge Generator
 * Runs every Monday at 9:00 AM UTC
 */
export const generateWeeklyChallenge = functionsV1.pubsub
  .schedule("every monday 09:00")
  .timeZone("UTC")
  .onRun(async () => {
    console.log("Starting weekly challenge generation...");

    try {
      // 1. Get unused template
      const templatesSnapshot = await db
        .collection("challengeTemplates")
        .where("used", "==", false)
        .orderBy("createdAt", "asc")
        .limit(1)
        .get();

      if (templatesSnapshot.empty) {
        console.log("No unused templates available");
        return null;
      }

      const templateDoc = templatesSnapshot.docs[0];
      const template = templateDoc.data() as ChallengeTemplate;
      const templateId = templateDoc.id;

      console.log(`Using template: ${template.name}`);

      // 2. Calculate challenge dates (runs for 7 days from now)
      const startDate = admin.firestore.Timestamp.now();
      const endDate = new Date();
      endDate.setDate(endDate.getDate() + 7);

      // 3. Create challenge from template
      const challengeRef = await db.collection("challenges").add({
        name: template.name,
        title: template.name,
        description: template.description,
        imageUrl: template.imageUrl,
        category: template.category,
        archetypeId: template.archetypeId || null,
        totalDays: template.daysRequired,
        currentDay: 0,
        daysLeft: template.daysRequired,
        participants: 0,
        status: "active",
        xpReward: template.xpReward,
        reward: template.rewardDescription || `+${template.xpReward} XP`,
        isFeatured: true,
        isTeamChallenge: false,
        buddyValidationRequired: false,
        affiliateUrl: template.affiliatePartnerId || null,
        sponsor: template.affiliatePartnerId || null,
        sponsorLogoUrl: template.affiliatePartnerId || null,
        // New fields
        isSponsored: template.affiliatePartnerId !== undefined,
        rewardDescription: template.rewardDescription || null,
        affiliatePartnerId: template.affiliatePartnerId || null,
        // Challenge dates
        startDate: startDate,
        endDate: admin.firestore.Timestamp.fromDate(endDate),
        type: "weekly",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        // Steps template
        steps: generateSteps(template.daysRequired),
      });

      console.log(`Created challenge: ${challengeRef.id}`);

      // 4. Mark template as used
      await templateDoc.ref.update({
        used: true,
        usedAt: admin.firestore.FieldValue.serverTimestamp(),
        challengeId: challengeRef.id,
      });

      console.log(`Marked template ${templateId} as used`);

      // 5. Send FCM notification to all users
      const message = {
        notification: {
          title: "🔥 New Weekly Challenge!",
          body: template.name,
        },
        data: {
          challengeId: challengeRef.id,
          type: "weekly_challenge",
          clickAction: "FLUTTER_NOTIFICATION_CLICK",
        },
        topic: "all_users",
      };

      await admin.messaging().send(message);
      console.log("Sent push notification to all users");

      // 6. Log analytics event
      await db.collection("analytics").add({
        event: "weekly_challenge_generated",
        challengeId: challengeRef.id,
        templateId: templateId,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log("Weekly challenge generation completed successfully");
      return null;
    } catch (error) {
      console.error("Error generating weekly challenge:", error);
      throw error;
    }
  });

/**
 * Helper function to generate challenge steps
 * @param {number} daysRequired - Number of days in challenge.
 * @return {Array<any>} Calculated steps.
 */
function generateSteps(daysRequired: number): Array<{
  day: number;
  title: string;
  description: string;
  isCompleted: boolean;
}> {
  const steps = [];

  // Start step
  steps.push({
    day: 1,
    title: "Start Your Journey",
    description: "Complete your first session",
    isCompleted: false,
  });

  // Milestone steps
  if (daysRequired >= 7) {
    steps.push({
      day: 7,
      title: "One Week Strong",
      description: "You've built momentum!",
      isCompleted: false,
    });
  }

  if (daysRequired >= 14) {
    steps.push({
      day: 14,
      title: "Two Weeks Down",
      description: "Halfway there!",
      isCompleted: false,
    });
  }

  if (daysRequired >= 21) {
    steps.push({
      day: 21,
      title: "Three Week Streak",
      description: "Habit formation in progress!",
      isCompleted: false,
    });
  }

  if (daysRequired >= 30) {
    steps.push({
      day: 30,
      title: "30-Day Champion",
      description: "You've built a life-changing habit!",
      isCompleted: false,
    });
  }

  // Final step
  if (!steps.some((s) => s.day === daysRequired)) {
    steps.push({
      day: daysRequired,
      title: "Challenge Complete",
      description: "Congratulations!",
      isCompleted: false,
    });
  }

  return steps;
}
