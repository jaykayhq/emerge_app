/**
 * Pure snapshot helpers — no Firebase imports, unit-tested in
 * test/snapshot.test.mjs. Mirrors email-worker's split: SDK lives in the
 * entry point, logic lives here so tests stay fast and dependency-free.
 *
 * Mirrors the Dart aggregation exactly (sums of contributor fields, 7-day
 * windows for active/new members) so server and client numbers agree.
 */

/** yyyy-MM-dd in UTC — the snapshot's date key (matches the Dart dateKey). */
export function dateKey(dt) {
  const y = String(dt.getUTCFullYear()).padStart(4, "0");
  const m = String(dt.getUTCMonth() + 1).padStart(2, "0");
  const d = String(dt.getUTCDate()).padStart(2, "0");
  return `${y}-${m}-${d}`;
}

/**
 * True when we should write a snapshot: none exists yet, or the latest one
 * is older than 24h (same staleness gate as the client service).
 */
export function isStale(latestDate, now) {
  if (latestDate == null) return true;
  const parsed = Date.parse(latestDate);
  if (Number.isNaN(parsed)) return true;
  return now.getTime() - parsed > 24 * 60 * 60 * 1000;
}

/**
 * Parses a contributor date field. Firestore Timestamps expose `toDate()`;
 * duck-typing keeps the helpers testable without the admin SDK.
 */
function parseDate(value) {
  if (value == null) return null;
  if (typeof value.toDate === "function") return value.toDate();
  if (typeof value === "string") {
    const parsed = Date.parse(value);
    return Number.isNaN(parsed) ? null : new Date(parsed);
  }
  return null;
}

/**
 * Aggregates contributor docs into the snapshot counters.
 * `now` is injected so tests can pin the 7-day windows.
 */
export function aggregateContributors(contributorDocs, now) {
  let totalXp = 0;
  let totalHabits = 0;
  let totalChallenges = 0;
  let newMembers = 0;
  let activeMembers = 0;
  const weekAgo = now.getTime() - 7 * 24 * 60 * 60 * 1000;

  for (const doc of contributorDocs) {
    const data = doc.data ? doc.data() : doc;
    totalXp += Number(data.totalXpContributed) || 0;
    totalHabits += Number(data.totalHabitsCompleted) || 0;
    totalChallenges += Number(data.totalChallengesCompleted) || 0;

    const joinedAt = parseDate(data.joinedAt);
    if (joinedAt != null && joinedAt.getTime() > weekAgo) newMembers++;

    const lastActivity = parseDate(data.lastActivity);
    if (lastActivity != null && lastActivity.getTime() > weekAgo) {
      activeMembers++;
    }
  }

  return { totalXp, totalHabits, totalChallenges, newMembers, activeMembers };
}

/** Builds the full snapshot payload for one tribe. */
export function buildSnapshot(tribeDoc, contributorDocs, now, timestampFactory) {
  const data = tribeDoc.data ? tribeDoc.data() : tribeDoc;
  const agg = aggregateContributors(contributorDocs, now);
  return {
    tribeId: data.tribeId ?? tribeDoc.id,
    date: dateKey(now),
    memberCount: Number(data.memberCount) || 0,
    totalXp: agg.totalXp,
    totalHabitsCompleted: agg.totalHabits,
    totalChallengesCompleted: agg.totalChallenges,
    activeMembers: agg.activeMembers,
    newMembersThisWeek: agg.newMembers,
    createdAt: timestampFactory(),
  };
}
