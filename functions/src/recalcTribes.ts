import * as admin from "firebase-admin";

const clubMap: Record<string, string> = {
  athlete: "morning_warriors",
  scholar: "deep_work_society",
  stoic: "mindful_masters",
  creator: "creative_collective",
  zealot: "lunar_seekers",
  mystic: "lunar_seekers",
};

/**
 * Recalculates all tribe statistics by scanning user_stats and global activities.
 * Uses streams to process large collections efficiently without memory overflow.
 */
export async function recalcTribesInternal(db: admin.firestore.Firestore): Promise<number> {
  console.log("Starting scalable tribe recalculation...");
  
  // 1. Map users to tribes based on archetype
  // We store this in memory. For 100k users, this is ~10-20MB.
  const userToTribeMap = new Map<string, string>();
  const tribeMembers = new Map<string, string[]>();
  
  // Initialize tribe member lists
  for (const clubId of Object.values(clubMap)) {
    tribeMembers.set(clubId, []);
  }

  console.log("Mapping users to archetypes...");
  await new Promise((resolve, reject) => {
    db.collection("users")
      .select("archetype") // Only fetch needed field
      .stream()
      .on("data", (doc: admin.firestore.QueryDocumentSnapshot) => {
        const userData = doc.data();
        const archetype = userData.archetype;
        if (archetype && archetype !== "none") {
          const clubId = clubMap[archetype.toLowerCase()];
          if (clubId) {
            userToTribeMap.set(doc.id, clubId);
            const members = tribeMembers.get(clubId);
            if (members) members.push(doc.id);
          }
        }
      })
      .on("end", resolve)
      .on("error", reject);
  });

  // 2. Aggregate XP from user_stats using stream
  const tribeXp = new Map<string, number>();
  for (const clubId of Object.values(clubMap)) {
    tribeXp.set(clubId, 0);
  }

  console.log("Aggregating XP from user_stats...");
  await new Promise((resolve, reject) => {
    db.collection("user_stats")
      .stream()
      .on("data", (doc: admin.firestore.QueryDocumentSnapshot) => {
        const tribeId = userToTribeMap.get(doc.id);
        if (tribeId) {
          const stats = doc.data();
          let xp = 0;
          const avatarStats = stats.avatarStats || {};
          
          if (typeof avatarStats.totalXp === "number") {
            xp = avatarStats.totalXp;
          } else if (typeof stats.totalXp === "number") {
            xp = stats.totalXp;
          }
          
          const currentXp = tribeXp.get(tribeId) || 0;
          tribeXp.set(tribeId, currentXp + xp);
        }
      })
      .on("end", resolve)
      .on("error", reject);
  });

  // 3. Aggregate activity counts from global_activities using stream
  const tribeActivities = new Map<string, { habits: number, challenges: number }>();
  for (const clubId of Object.values(clubMap)) {
    tribeActivities.set(clubId, { habits: 0, challenges: 0 });
  }

  console.log("Aggregating activity counts...");
  await new Promise((resolve, reject) => {
    db.collection("global_activities")
      .stream()
      .on("data", (doc: admin.firestore.QueryDocumentSnapshot) => {
        const act = doc.data();
        const clubId = act.clubId;
        const counts = tribeActivities.get(clubId);
        
        if (clubId && counts) {
          if (act.type === "habit_complete" || act.type === "habit_completion") {
            counts.habits++;
          } else if (act.type === "challenge_complete") {
            counts.challenges++;
          }
        }
      })
      .on("end", resolve)
      .on("error", reject);
  });

  // 4. Update tribe documents in batches
  let updatedCount = 0;
  const batch = db.batch();
  
  // Use a Set to avoid duplicate official club IDs if multiple archetypes map to same club
  const officialClubIds = Array.from(new Set(Object.values(clubMap)));

  for (const clubId of officialClubIds) {
    const members = tribeMembers.get(clubId) || [];
    const totalXp = tribeXp.get(clubId) || 0;
    const activities = tribeActivities.get(clubId) || { habits: 0, challenges: 0 };
    
    const tribeRef = db.collection("tribes").doc(clubId);
    
    batch.update(tribeRef, {
      members: members,
      memberCount: members.length,
      totalXp: totalXp,
      totalHabitsCompleted: activities.habits,
      totalChallengesCompleted: activities.challenges,
      lastStatsSync: admin.firestore.FieldValue.serverTimestamp()
    });
    
    updatedCount++;
    console.log(`Queued update for ${clubId}: ${members.length} members, ${totalXp} XP.`);
  }

  await batch.commit();
  console.log(`✓ Scalable tribe recalculation finished. Updated ${updatedCount} official clubs.`);
  return updatedCount;
}
