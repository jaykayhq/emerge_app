// Unit tests for the pure snapshot helpers (no Firestore needed).
// Firestore values are duck-typed ({ toDate() }) — mirroring email-worker's
// fake-db convention — so the heavy admin SDK stays out of tests.
import { test } from "node:test";
import assert from "node:assert/strict";
import {
  dateKey,
  isStale,
  aggregateContributors,
  buildSnapshot,
} from "../snapshot.js";

const NOW = new Date("2026-08-18T12:00:00Z");

function ts(iso) {
  return { toDate: () => new Date(iso) }; // duck-typed Firestore Timestamp
}

// Stand-in for firebase-admin's Timestamp.now(), which the real entry injects.
const fakeTimestampNow = () => ({ toDate: () => NOW });

test("dateKey formats yyyy-MM-dd in UTC", () => {
  assert.equal(dateKey(new Date("2026-08-18T23:59:59Z")), "2026-08-18");
  assert.equal(dateKey(new Date("2026-08-18T00:00:00Z")), "2026-08-18");
  assert.equal(dateKey(new Date("2026-01-05T00:00:00Z")), "2026-01-05");
});

test("isStale: no snapshot -> write", () => {
  assert.equal(isStale(null, NOW), true);
});

test("isStale: fresh snapshot (<24h) -> skip", () => {
  assert.equal(isStale("2026-08-18", NOW), false);
});

test("isStale: stale snapshot (>24h) -> write", () => {
  assert.equal(isStale("2026-08-17", NOW), true); // 36h ago
  assert.equal(isStale("2026-08-15", NOW), true); // 3.5 days ago
});

test("isStale: snapshot under 24h old -> skip", () => {
  assert.equal(isStale("2026-08-18T00:00:00Z", NOW), false); // 12h ago
  assert.equal(isStale("2026-08-17T13:00:00Z", NOW), false); // 23h ago
});

test("isStale: unparseable date -> write", () => {
  assert.equal(isStale("not-a-date", NOW), true);
});

test("isStale: future-dated snapshot -> write", () => {
  assert.equal(isStale("2026-08-19", NOW), true); // tomorrow must not suppress today
  assert.equal(isStale("2030-01-01T00:00:00Z", NOW), true);
});

test("aggregateContributors sums fields and 7-day windows", () => {
  const docs = [
    {
      data: () => ({
        totalXpContributed: 3000,
        totalHabitsCompleted: 40,
        totalChallengesCompleted: 2,
        joinedAt: "2026-07-19T00:00:00Z", // 30d ago
        lastActivity: "2026-08-18T00:00:00Z", // today
      }),
    },
    {
      data: () => ({
        totalXpContributed: 2000,
        totalHabitsCompleted: 20,
        totalChallengesCompleted: 1,
        joinedAt: "2026-08-16T00:00:00Z", // 2d ago -> new
        lastActivity: "2026-08-17T00:00:00Z", // active
      }),
    },
    {
      data: () => ({
        totalXpContributed: 0,
        totalHabitsCompleted: 0,
        totalChallengesCompleted: 0,
        joinedAt: "2026-06-01T00:00:00Z",
        lastActivity: "2026-07-01T00:00:00Z", // 48d ago -> inactive
      }),
    },
  ];
  const agg = aggregateContributors(docs, NOW);
  assert.equal(agg.totalXp, 5000);
  assert.equal(agg.totalHabits, 60);
  assert.equal(agg.totalChallenges, 3);
  assert.equal(agg.newMembers, 1);
  assert.equal(agg.activeMembers, 2);
});

test("aggregateContributors handles Timestamp dates", () => {
  const docs = [
    {
      data: () => ({
        totalXpContributed: 10,
        joinedAt: ts("2026-08-17T00:00:00Z"),
        lastActivity: ts("2026-08-17T00:00:00Z"),
      }),
    },
  ];
  const agg = aggregateContributors(docs, NOW);
  assert.equal(agg.newMembers, 1);
  assert.equal(agg.activeMembers, 1);
});

test("aggregateContributors is empty-safe", () => {
  const agg = aggregateContributors([], NOW);
  assert.deepEqual(agg, {
    totalXp: 0,
    totalHabits: 0,
    totalChallenges: 0,
    newMembers: 0,
    activeMembers: 0,
  });
});

test("buildSnapshot assembles the full payload", () => {
  const tribe = { id: "t1", data: () => ({ memberCount: 3, createdBy: "creator1" }) };
  const contrib = [
    { data: () => ({ totalXpContributed: 5000, totalHabitsCompleted: 60, totalChallengesCompleted: 3 }) },
  ];
  const snap = buildSnapshot(tribe, contrib, NOW, fakeTimestampNow);
  assert.equal(snap.tribeId, "t1");
  assert.equal(snap.date, "2026-08-18");
  assert.equal(snap.memberCount, 3);
  assert.equal(snap.totalXp, 5000);
  assert.equal(snap.totalHabitsCompleted, 60);
  assert.equal(snap.totalChallengesCompleted, 3);
  assert.equal(typeof snap.createdAt.toDate, "function"); // Firestore Timestamp
});
