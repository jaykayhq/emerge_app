import * as admin from "firebase-admin";

const PROJECT_ID = "tradeflash-l2966";

admin.initializeApp({
  projectId: PROJECT_ID,
});
const db = admin.firestore();

const clubMap: Record<string, string> = {
  athlete: "morning_warriors",
  scholar: "deep_work_society",
  stoic: "mindful_masters",
  creator: "creative_collective",
  zealot: "lunar_seekers",
  mystic: "lunar_seekers",
};

async function recalcTribes(): Promise<void> {
  console.log("Starting full tribe recalculation...");
  
  // Prepare aggregators
  const clubData: Record<string, {
    members: string[],
    totalXp: number,
  }> = {};

  for (const clubId of Object.values(clubMap)) {
    clubData[clubId] = { members: [], totalXp: 0 };
  }

  // 1. Scan all users and user_stats
  const usersSnapshot = await db.collection("users").get();
  
  for (const doc of usersSnapshot.docs) {
    const userData = doc.data();
    const archetype = userData.archetype;
    const userId = doc.id;

    if (archetype && archetype !== "none") {
      const clubId = clubMap[archetype.toLowerCase()];
      if (clubId && clubData[clubId]) {
        clubData[clubId].members.push(userId);

        // Fetch user stats to get XP
        const statsDoc = await db.collection("user_stats").doc(userId).get();
        if (statsDoc.exists) {
          const stats = statsDoc.data() || {};
          let xp = 0;
          if (stats.avatarStats && typeof stats.avatarStats.totalXp === "number") {
            xp = stats.avatarStats.totalXp;
          } else if (typeof stats.totalXp === "number") {
            xp = stats.totalXp;
          }
          clubData[clubId].totalXp += xp;
        }
      }
    }
  }

  // 2. Count actual habits and challenges completed per club
  // Reset counts first
  const clubActivityCounts: Record<string, { habits: number, challenges: number }> = {};
  for (const clubId of Object.values(clubMap)) {
    clubActivityCounts[clubId] = { habits: 0, challenges: 0 };
  }

  const globalActivities = await db.collection("global_activities").get();
  for (const doc of globalActivities.docs) {
    const act = doc.data();
    const clubId = act.clubId;
    if (clubId && clubActivityCounts[clubId]) {
      if (act.type === "habit_complete" || act.type === "habit_completion") {
        clubActivityCounts[clubId].habits++;
      } else if (act.type === "challenge_complete") {
        clubActivityCounts[clubId].challenges++;
      }
    }
  }

  // 3. Apply updates to the 'tribes' collection
  let updatedCount = 0;
  for (const [clubId, data] of Object.entries(clubData)) {
    const tribeRef = db.collection("tribes").doc(clubId);
    const tribeDoc = await tribeRef.get();

    if (tribeDoc.exists) {
      await tribeRef.update({
        members: data.members,
        memberCount: data.members.length,
        totalXp: data.totalXp,
        totalHabitsCompleted: clubActivityCounts[clubId].habits,
        totalChallengesCompleted: clubActivityCounts[clubId].challenges
      });
      console.log(`Updated ${clubId}: ${data.members.length} members, ${data.totalXp} XP, ${clubActivityCounts[clubId].habits} habits.`);
      updatedCount++;
    }
  }

  console.log(`✓ Tribe recalculation finished. Updated ${updatedCount} official clubs.`);
  process.exit(0);
}

recalcTribes().catch(console.error);
