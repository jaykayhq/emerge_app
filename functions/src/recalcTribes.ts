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
 * Recalculates tribe statistics for every tribe (official clubs + creator
 * tribes with explicit membership docs) from user_stats and global activities.
 * Uses streams to process large collections efficiently without memory overflow.
 * Non-transactional by design: a failed run simply reruns at the next 3AM (spec §8).
 */
export async function recalcTribesInternal(db: admin.firestore.Firestore): Promise<number> {
  console.log("Starting scalable tribe recalculation...");

  // 1. uid -> archetype. The archetype club is only a fallback for users
  // without an explicit membership doc (aggregateTribeStats enforces this).
  const archetypeMap = new Map<string, string>();

  console.log("Mapping users to archetypes...");
  await new Promise((resolve, reject) => {
    db.collection("users")
      .select("archetype") // Only fetch needed field
      .stream()
      .on("data", (doc: admin.firestore.QueryDocumentSnapshot) => {
        const archetype = doc.data().archetype;
        if (archetype && archetype !== "none") {
          archetypeMap.set(doc.id, archetype);
        }
      })
      .on("end", resolve)
      .on("error", reject);
  });

  // 2. Explicit membership records from users/{uid}/tribes subcollections
  const membershipMap = new Map<string, string>();

  console.log("Querying explicit tribe membership records...");
  await new Promise((resolve, reject) => {
    db.collectionGroup("tribes")
      .stream()
      .on("data", (doc: admin.firestore.QueryDocumentSnapshot) => {
        const ref = doc.ref.path;
        const parts = ref.split("/");
        if (parts.length === 4 && parts[0] === "users" && parts[2] === "tribes") {
          membershipMap.set(parts[1], parts[3]);
        }
      })
      .on("end", resolve)
      .on("error", reject);
  });

  // 3. uid -> xp from user_stats (per-member XP, no archetype bucketing)
  const userStatsXp = new Map<string, number>();

  console.log("Aggregating XP from user_stats...");
  await new Promise((resolve, reject) => {
    db.collection("user_stats")
      .stream()
      .on("data", (doc: admin.firestore.QueryDocumentSnapshot) => {
        const stats = doc.data();
        let xp = 0;
        const avatarStats = stats.avatarStats || {};

        if (typeof avatarStats.totalXp === "number") {
          xp = avatarStats.totalXp;
        } else if (typeof stats.totalXp === "number") {
          xp = stats.totalXp;
        }

        userStatsXp.set(doc.id, xp);
      })
      .on("end", resolve)
      .on("error", reject);
  });

  // 4. Aggregate activity counts from global_activities using stream
  const tribeActivities = new Map<string, { habits: number, challenges: number }>();

  console.log("Aggregating activity counts...");
  await new Promise((resolve, reject) => {
    db.collection("global_activities")
      .stream()
      .on("data", (doc: admin.firestore.QueryDocumentSnapshot) => {
        const act = doc.data();
        const clubId = act.clubId;

        if (clubId) {
          const counts = tribeActivities.get(clubId) ?? { habits: 0, challenges: 0 };
          if (act.type === "habit_complete" || act.type === "habit_completion") {
            counts.habits++;
          } else if (act.type === "challenge_complete") {
            counts.challenges++;
          }
          tribeActivities.set(clubId, counts);
        }
      })
      .on("end", resolve)
      .on("error", reject);
  });

  // 5. Pure aggregation: members = explicit membership docs, official-club
  // fallback for legacy users; XP summed per member.
  const byTribe = aggregateTribeStats({ membershipMap, archetypeMap, clubMap, userStatsXp });

  // 6. Union with the official club ids so clubs with zero members still get
  // their stale memberCount/members/stats reset by the daily recalc.
  const tribeIds = new Set([...byTribe.keys(), ...Object.values(clubMap)]);

  // 7. Merge-set writes preserve creator-tribe ownerId/name/type and create
  // missing docs. Chunked because Firestore batches cap at 500 ops.
  let updatedCount = 0;
  const batchSize = 500;
  let batch = db.batch();
  let opsInBatch = 0;

  for (const tribeId of tribeIds) {
    const entry = byTribe.get(tribeId);
    const members = entry?.members ?? [];
    const totalXp = entry?.totalXp ?? 0;
    const activities = tribeActivities.get(tribeId) ?? { habits: 0, challenges: 0 };

    const tribeRef = db.collection("tribes").doc(tribeId);

    batch.set(tribeRef, {
      members: members,
      memberCount: members.length,
      totalXp: totalXp,
      totalHabitsCompleted: activities.habits,
      totalChallengesCompleted: activities.challenges,
      lastStatsSync: admin.firestore.FieldValue.serverTimestamp()
    }, { merge: true });

    updatedCount++;
    opsInBatch++;
    console.log(`Queued update for ${tribeId}: ${members.length} members, ${totalXp} XP.`);

    if (opsInBatch === batchSize) {
      await batch.commit();
      batch = db.batch();
      opsInBatch = 0;
    }
  }

  if (opsInBatch > 0) {
    await batch.commit();
  }
  console.log(`✓ Scalable tribe recalculation finished. Updated ${updatedCount} tribes.`);
  return updatedCount;
}

export interface TribeAggregationInput {
  /** uid -> explicit tribeId from users/{uid}/tribes (collectionGroup). */
  membershipMap: Map<string, string>;
  /** uid -> lowercase archetype (may be 'none'). */
  archetypeMap: Map<string, string>;
  /** archetype -> official clubId (the 6 official clubs). */
  clubMap: Record<string, string>;
  /** uid -> user_stats.avatarStats.totalXp. */
  userStatsXp: Map<string, number>;
}

/**
 * Pure SP-G D10 aggregation: members = explicit membership docs, plus the
 * official archetype club as a fallback ONLY for users without explicit
 * membership. XP is summed per member directly (no archetype bucketing).
 */
export function aggregateTribeStats(
  input: TribeAggregationInput,
): Map<string, { members: string[]; totalXp: number }> {
  const byTribe = new Map<string, { members: string[]; totalXp: number }>();
  const ensure = (tribeId: string) => {
    let entry = byTribe.get(tribeId);
    if (!entry) {
      entry = { members: [], totalXp: 0 };
      byTribe.set(tribeId, entry);
    }
    return entry;
  };

  const uids = new Set([...input.membershipMap.keys(), ...input.archetypeMap.keys()]);
  for (const uid of uids) {
    const tribeId =
      input.membershipMap.get(uid) ??
      input.clubMap[input.archetypeMap.get(uid) ?? ""];
    if (!tribeId) continue; // no explicit membership and no official club
    const entry = ensure(tribeId);
    entry.members.push(uid);
    entry.totalXp += input.userStatsXp.get(uid) ?? 0;
  }
  return byTribe;
}
