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
 * tribes with explicit membership docs) from user_stats, contributor docs
 * and global activities. Uses streams to process large collections
 * efficiently without memory overflow.
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

  // 3. uid -> xp from user_stats (per-member XP, no archetype bucketing).
  //    FALLBACK ONLY: tribes without contributor docs (pre-trigger data)
  //    fall back to the sum of current members' user_stats.
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

  // 3b. tribeId -> totalXpContributed from the contributors subcollection.
  //     PRIMARY SOURCE: contributor docs are the historical attribution
  //     record (XP earned in a tribe stays there after leaving/switching),
  //     and the maintainTribeXp trigger writes tribe.totalXp from the same
  //     numbers — so the daily recalc reconciles to exactly the same value.
  const contributorXpByTribe = new Map<string, number>();

  // 3c. tribeId -> habit/challenge completion counts from the contributors
  //     subcollection. PRIMARY SOURCE for totalHabitsCompleted /
  //     totalChallengesCompleted: the client increments these on every
  //     completion AND decrements them on undo, so the sum is the exact
  //     live count. Counting global_activities events instead is wrong —
  //     the undo path cannot always delete those docs (e.g. after a fresh
  //     install), leaving the tribe total inflated forever.
  const contributorCountsByTribe = new Map<string, { habits: number, challenges: number }>();

  console.log("Aggregating XP from contributor records...");
  await new Promise((resolve, reject) => {
    db.collectionGroup("contributors")
      .stream()
      .on("data", (doc: admin.firestore.QueryDocumentSnapshot) => {
        const ref = doc.ref.path;
        const parts = ref.split("/");
        if (parts.length === 4 && parts[0] === "tribes" && parts[2] === "contributors") {
          const data = doc.data();
          const contributed = data.totalXpContributed;
          if (typeof contributed === "number") {
            const tribeId = parts[1];
            contributorXpByTribe.set(
              tribeId,
              (contributorXpByTribe.get(tribeId) ?? 0) + contributed,
            );
          }
          const habits = data.totalHabitsCompleted;
          const challenges = data.totalChallengesCompleted;
          if (typeof habits === "number" || typeof challenges === "number") {
            const tribeId = parts[1];
            const counts = contributorCountsByTribe.get(tribeId) ?? { habits: 0, challenges: 0 };
            counts.habits += typeof habits === "number" ? habits : 0;
            counts.challenges += typeof challenges === "number" ? challenges : 0;
            contributorCountsByTribe.set(tribeId, counts);
          }
        }
      })
      .on("end", resolve)
      .on("error", reject);
  });

  // 4. Aggregate activity counts from global_activities using stream.
  //    FALLBACK ONLY: tribes without contributor docs (e.g. legacy users
  //    whose completions predate contributor records, or archetype-club
  //    completions with no explicit membership) fall back to the feed.
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
  // fallback for legacy users; XP from contributor records (primary) with a
  // user_stats fallback for tribes that have no contributor docs.
  const byTribe = aggregateTribeStats({
    membershipMap,
    archetypeMap,
    clubMap,
    userStatsXp,
    contributorXpByTribe,
  });

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
    const contributorCounts = contributorCountsByTribe.get(tribeId);
    const activities = tribeActivities.get(tribeId) ?? { habits: 0, challenges: 0 };

    const tribeRef = db.collection("tribes").doc(tribeId);

    batch.set(tribeRef, {
      members: members,
      memberCount: members.length,
      totalXp: totalXp,
      totalHabitsCompleted: contributorCounts ? contributorCounts.habits : activities.habits,
      totalChallengesCompleted: contributorCounts ? contributorCounts.challenges : activities.challenges,
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
  /** uid -> user_stats.avatarStats.totalXp (fallback only). */
  userStatsXp: Map<string, number>;
  /** tribeId -> sum of contributors.totalXpContributed (primary source). */
  contributorXpByTribe: Map<string, number>;
}

/**
 * Pure SP-G D10 aggregation: members = explicit membership docs, plus the
 * official archetype club as a fallback ONLY for users without explicit
 * membership. XP comes from the contributors subcollection (historical
 * per-tribe attribution — XP earned in a tribe stays there after leaving)
 * and only falls back to user_stats sums for tribes with no contributor
 * docs at all.
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

  // Contributor records win when present — same source as the real-time
  // maintainTribeXp trigger, so the daily pass reconciles to the same value.
  for (const [tribeId, entry] of byTribe) {
    const contributed = input.contributorXpByTribe.get(tribeId);
    if (contributed !== undefined) {
      entry.totalXp = contributed;
    }
  }

  return byTribe;
}
