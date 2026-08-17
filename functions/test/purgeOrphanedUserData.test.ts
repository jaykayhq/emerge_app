/**
 * Tests for purgeOrphanedUserData.ts.
 *
 * purgeUserKeyedData must delete every doc in user-keyed collections
 * (habits, user_activity, global_activities, club_leaderboards,
 * challenge_leaderboards, contracts, partner_requests, security_logs,
 * revenuecat_events, usernames) whose field matches an orphaned uid —
 * mirroring what deleteMyAccount cleans for a self-deleting user, so a
 * deleted account can never be resurrected by the client.
 */
import { purgeUserKeyedData } from "../src/purgeOrphanedUserData";

interface FakeQueryDoc {
  ref: { path: string };
}

function makeDbFake(byCollection: Record<string, FakeQueryDoc[]>) {
  const deletes: string[] = [];
  const seenPairs = new Set<string>();
  const db = {
    collection(name: string) {
      return {
        where(field: string, op: string, value: string) {
          return {
            get: async () => {
              // Real Firestore filters by the field, so a doc with
              // userId=X only matches the userId query — never the
              // partnerId/senderId query on the same collection. The fake
              // simulates that by serving each collection's docs once.
              if (seenPairs.has(name)) {
                return { empty: true, docs: [] };
              }
              seenPairs.add(name);
              const docs = byCollection[name] ?? [];
              return {
                empty: docs.length === 0,
                docs: docs.map((d) => ({ ref: d.ref })),
              };
            },
          };
        },
      };
    },
    batch() {
      const ops: Array<() => void> = [];
      return {
        delete(ref: { path: string }) {
          ops.push(() => deletes.push(ref.path));
        },
        async commit() {
          ops.forEach((fn) => fn());
        },
      };
    },
  };
  return { db: db as unknown as Parameters<typeof purgeUserKeyedData>[0], deletes };
}

describe("purgeUserKeyedData", () => {
  it("deletes docs across all user-keyed collections for the orphan uid", async () => {
    const { db, deletes } = makeDbFake({
      habits: [{ ref: { path: "habits/h1" } }, { ref: { path: "habits/h2" } }],
      user_activity: [{ ref: { path: "user_activity/a1" } }],
      global_activities: [{ ref: { path: "global_activities/g1" } }],
      club_leaderboards: [{ ref: { path: "club_leaderboards/c1" } }],
      challenge_leaderboards: [{ ref: { path: "challenge_leaderboards/ch1" } }],
      contracts: [{ ref: { path: "contracts/ct1" } }],
      partner_requests: [{ ref: { path: "partner_requests/p1" } }],
      security_logs: [{ ref: { path: "security_logs/s1" } }],
      revenuecat_events: [{ ref: { path: "revenuecat_events/r1" } }],
      usernames: [{ ref: { path: "usernames/foo" } }],
    });

    const count = await purgeUserKeyedData(db, "orphanUid", false);

    expect(count).toBe(11);
    expect(deletes).toEqual([
      "habits/h1",
      "habits/h2",
      "user_activity/a1",
      "global_activities/g1",
      "club_leaderboards/c1",
      "challenge_leaderboards/ch1",
      "contracts/ct1",
      "partner_requests/p1",
      "security_logs/s1",
      "revenuecat_events/r1",
      "usernames/foo",
    ]);
  });

  it("returns zero and writes nothing when no docs match", async () => {
    const { db, deletes } = makeDbFake({ habits: [] });

    const count = await purgeUserKeyedData(db, "orphanUid", false);

    expect(count).toBe(0);
    expect(deletes).toEqual([]);
  });

  it("counts but never deletes in dry-run mode", async () => {
    const { db, deletes } = makeDbFake({
      habits: [{ ref: { path: "habits/h1" } }],
    });

    const count = await purgeUserKeyedData(db, "orphanUid", true);

    expect(count).toBe(1);
    expect(deletes).toEqual([]);
  });
});
