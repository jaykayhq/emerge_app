/**
 * Firebase Cloud Function: Quarterly Challenge Refresh
 *
 * Refreshes sponsored challenges every quarter (3 months)
 * Creates brand-sponsored challenges aligned with quarterly themes
 *
 * Schedule: First day of each quarter at 00:00 UTC
 * - Q1 (Jan 1): New Year Transformation
 * - Q2 (Apr 1): Spring Energy
 * - Q3 (Jul 1): Summer Consistency
 * - Q4 (Oct 1): Year-End Reflection
 */

import * as functionsV1 from "firebase-functions/v1";
import * as admin from "firebase-admin";

if (admin.apps.length === 0) {
  admin.initializeApp();
}
const db = admin.firestore();

/**
 * Quarterly themes from affiliate strategy
 * Each quarter focuses on different affiliate partnerships
 */
const QUARTERLY_THEMES: Record<number, QuarterlyTheme> = {
  1: {
    name: "New Year Transformation",
    partners: ["fitbit", "myfitnesspal", "mealpal", "nike"],
    revenueTarget: 10000,
  },
  2: {
    name: "Spring Energy",
    partners: ["strava", "nike", "underarmour", "peloton"],
    revenueTarget: 8000,
  },
  3: {
    name: "Summer Consistency",
    partners: ["myfitnesspal", "sleepcycle", "calm", "headspace"],
    revenueTarget: 6000,
  },
  4: {
    name: "Year-End Reflection",
    partners: ["dayone", "blinkist", "audible", "headspace"],
    revenueTarget: 12000,
  },
};

interface QuarterlyTheme {
  name: string;
  partners: string[];
  revenueTarget?: number;
}

interface AffiliatePartner {
  id: string;
  name: string;
  logoUrl: string;
  category: string;
  network: string;
  commissionRate: number;
}

/**
 * Quarterly Challenge Refresh
 * Runs on the first day of each quarter at midnight UTC
 */
export const refreshQuarterlyChallenges = functionsV1.pubsub
  .schedule("0 0 1 */3 *")
  .timeZone("UTC")
  .onRun(async () => {
    const now = new Date();
    const month = now.getMonth() + 1; // 1-12
    const quarter = Math.ceil(month / 3);

    console.log(`Starting quarterly challenge refresh for Q${quarter}...`);

    try {
      const theme = QUARTERLY_THEMES[quarter];
      if (!theme) {
        console.log(`No theme found for quarter ${quarter}`);
        return null;
      }

      console.log(`Theme: ${theme.name}`);
      console.log(`Partners: ${theme.partners.join(", ")}`);

      // Calculate end of quarter
      const endOfQuarter = getEndOfQuarter(now);

      for (const partnerId of theme.partners) {
        await createPartnerChallenge(
          partnerId, quarter, theme.name, endOfQuarter
        );
      }

      // Log analytics
      await db.collection("analytics").add({
        event: "quarterly_refresh_completed",
        quarter: quarter,
        theme: theme.name,
        partners: theme.partners,
        challengesCreated: theme.partners.length,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(`Q${quarter} challenge refresh completed successfully`);
      return null;
    } catch (error) {
      console.error(`Error in quarterly refresh for Q${quarter}:`, error);
      throw error;
    }
  });

/**
 * Creates a sponsored challenge for a specific partner
 * @param {string} partnerId - The ID of the partner.
 * @param {number} quarter - Current quarter (1-4).
 * @param {string} themeName - Theme name for the quarter.
 * @param {Date} endDate - Challenge end date.
 * @return {Promise<void>}
 */
async function createPartnerChallenge(
  partnerId: string,
  quarter: number,
  themeName: string,
  endDate: Date
): Promise<void> {
  // Get partner details
  const partnerDoc = await db.collection("affiliatePartners")
    .doc(partnerId).get();

  if (!partnerDoc.exists) {
    console.log(`Partner ${partnerId} not found, skipping...`);
    return;
  }

  const partner = partnerDoc.data() as AffiliatePartner;

  // Check if partner has the required fields
  if (!partner.category) {
    console.log(`Partner ${partnerId} missing category, skipping...`);
    return;
  }

  // Create challenge
  const challengeData = {
    name: `${themeName}: ${partner.name} Challenge`,
    title: `${themeName}: ${partner.name} Challenge`,
    description: `Complete this ${themeName.toLowerCase()} challenge with ` +
      `${partner.name} and earn exclusive rewards!`,
    imageUrl: partner.logoUrl ||
      "https://images.unsplash.com/photo-1552664730-d307ca884978?w=800",
    category: partner.category,
    totalDays: 30,
    currentDay: 0,
    daysLeft: 30,
    participants: 0,
    status: "active",
    xpReward: 1000,
    reward: `Exclusive ${partner.name} reward`,
    isFeatured: true,
    isTeamChallenge: false,
    buddyValidationRequired: false,
    affiliateUrl: partnerId,
    sponsor: partner.name,
    sponsorLogoUrl: partner.logoUrl,
    // New affiliate fields
    isSponsored: true,
    rewardDescription: `Exclusive ${partner.name} discount`,
    affiliatePartnerId: partnerId,
    affiliateNetwork: partner.network,
    commissionRate: partner.commissionRate,
    sponsorshipStartDate: admin.firestore.Timestamp.now(),
    sponsorshipEndDate: admin.firestore.Timestamp.fromDate(endDate),
    type: "quarterly",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    steps: generateQuarterlySteps(partner.name, 30),
  };

  const challengeRef = await db.collection("challenges").add(challengeData);

  console.log(`Created quarterly challenge: ${challengeRef.id} ` +
    `for ${partner.name}`);

  // Send push notification for this challenge
  await sendQuarterlyChallengeNotification(challengeRef.id, challengeData.name);
}

/**
 * Sends push notification for new quarterly challenge
 * @param {string} challengeId - The ID of the challenge.
 * @param {string} challengeName - Name of the challenge.
 * @return {Promise<void>}
 */
async function sendQuarterlyChallengeNotification(
  challengeId: string,
  challengeName: string
): Promise<void> {
  const message = {
    notification: {
      title: "🎯 New Quarterly Challenge!",
      body: challengeName,
    },
    data: {
      challengeId: challengeId,
      type: "quarterly_challenge",
      clickAction: "FLUTTER_NOTIFICATION_CLICK",
    },
    topic: "all_users",
  };

  await admin.messaging().send(message);
  console.log(`Sent notification for quarterly challenge: ${challengeName}`);
}

/**
 * Generates challenge steps for quarterly challenges
 * @param {string} partnerName - Name of the partner.
 * @param {number} days - Number of days in challenge.
 * @return {Array<any>} Calculated steps.
 */
function generateQuarterlySteps(partnerName: string, _days: number): Array<{
  day: number;
  title: string;
  description: string;
  isCompleted: boolean;
}> {
  const steps = [];

  steps.push({
    day: 1,
    title: "Start Your Journey",
    description: `Begin your ${partnerName} challenge`,
    isCompleted: false,
  });

  steps.push({
    day: 7,
    title: "First Week Complete",
    description: "You're building momentum!",
    isCompleted: false,
  });

  steps.push({
    day: 14,
    title: "Two Week Milestone",
    description: "Halfway to transformation",
    isCompleted: false,
  });

  steps.push({
    day: 21,
    title: "Three Week Strong",
    description: "The habit is forming!",
    isCompleted: false,
  });

  steps.push({
    day: 30,
    title: "30-Day Champion",
    description: `You've completed the ${partnerName} challenge!`,
    isCompleted: false,
  });

  return steps;
}

/**
 * Helper function to get end of quarter
 * @param {Date} date - The current date.
 * @return {Date} End of the current quarter.
 */
function getEndOfQuarter(date: Date): Date {
  const month = date.getMonth();
  const quarter = Math.floor(month / 3);
  const endMonth = (quarter + 1) * 3; // First month of next quarter
  const endOfQuarter = new Date(date.getFullYear(), endMonth, 0);
  return endOfQuarter;
}
