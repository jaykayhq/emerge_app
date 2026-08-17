import { aggregateTribeStats, recalcTribesInternal } from "../src/recalcTribes";

class FakeDoc {
  constructor(
    readonly id: string,
    private readonly raw: Record<string, unknown>,
    readonly path?: string,
  ) {}
  data(): Record<string, unknown> {
    return this.raw;
  }
  get ref(): { path: string } {
    return { path: this.path ?? `users/${this.id}/tribes/unknown` };
  }
}

class FakeQuery {
  constructor(private readonly docs: FakeDoc[]) {}
  select(): FakeQuery {
    return this;
  }
  stream(): FakeQuery {
    return this;
  }
  on(event: "data" | "end" | "error", cb: (doc?: FakeDoc) => void): FakeQuery {
    if (event === "data") {
      for (const doc of this.docs) cb(doc);
    } else if (event === "end") {
      cb();
    }
    return this;
  }
}

interface RecordedWrite {
  op: "set" | "update";
  ref: { path: string };
  data: Record<string, unknown>;
  merge?: boolean;
}

function makeFakeDb(docs: {
  users?: FakeDoc[];
  tribes?: FakeDoc[];
  userStats?: FakeDoc[];
  globalActivities?: FakeDoc[];
  contributors?: FakeDoc[];
}): {
  db: Parameters<typeof recalcTribesInternal>[0];
  committed: RecordedWrite[][];
  writeCount: () => number;
  findWrite: (path: string) => RecordedWrite | undefined;
} {
  const committed: RecordedWrite[][] = [];
  const collections: Record<string, FakeDoc[]> = {
    users: docs.users ?? [],
    tribes: docs.tribes ?? [],
    user_stats: docs.userStats ?? [],
    global_activities: docs.globalActivities ?? [],
    contributors: docs.contributors ?? [],
  };
  const db = {
    collection(name: string) {
      if (name === "tribes") {
        return { doc: (id: string) => ({ path: `tribes/${id}` }) };
      }
      return new FakeQuery(collections[name]);
    },
    collectionGroup(name: string) {
      return new FakeQuery(collections[name] ?? []);
    },
    batch() {
      const writes: RecordedWrite[] = [];
      return {
        set(
          ref: { path: string },
          data: Record<string, unknown>,
          options?: { merge?: boolean },
        ) {
          writes.push({ op: "set", ref, data, merge: options?.merge });
        },
        update(ref: { path: string }, data: Record<string, unknown>) {
          writes.push({ op: "update", ref, data });
        },
        async commit() {
          committed.push([...writes]);
        },
      };
    },
  };
  return {
    db: db as unknown as Parameters<typeof recalcTribesInternal>[0],
    committed,
    writeCount: () => committed.flat().length,
    findWrite: (path: string) => committed.flat().find((w) => w.ref.path === path),
  };
}

describe("aggregateTribeStats", () => {
  it("uses explicit membership over the archetype club", () => {
    const out = aggregateTribeStats({
      membershipMap: new Map([["u1", "creative_collective"]]),
      archetypeMap: new Map([["u1", "athlete"]]),
      clubMap: { athlete: "morning_warriors" },
      userStatsXp: new Map([["u1", 100]]),
      contributorXpByTribe: new Map(),
    });
    expect(out.get("creative_collective")?.members).toEqual(["u1"]);
    expect(out.get("creative_collective")?.totalXp).toBe(100);
    expect(out.has("morning_warriors")).toBe(false);
  });

  it("falls back to the official archetype club for users without explicit membership", () => {
    const out = aggregateTribeStats({
      membershipMap: new Map(),
      archetypeMap: new Map([["u2", "stoic"]]),
      clubMap: { stoic: "mindful_masters" },
      userStatsXp: new Map([["u2", 42]]),
      contributorXpByTribe: new Map(),
    });
    expect(out.get("mindful_masters")?.members).toEqual(["u2"]);
    expect(out.get("mindful_masters")?.totalXp).toBe(42);
  });

  it("drops users with no explicit membership and no official club (archetype none/unknown)", () => {
    const out = aggregateTribeStats({
      membershipMap: new Map(),
      archetypeMap: new Map([["u3", "none"]]),
      clubMap: {},
      userStatsXp: new Map([["u3", 7]]),
      contributorXpByTribe: new Map(),
    });
    expect(out.size).toBe(0);
  });

  it("aggregates XP per member directly, not by archetype bucket", () => {
    const out = aggregateTribeStats({
      membershipMap: new Map([["a1", "creative_collective"], ["a2", "creative_collective"]]),
      archetypeMap: new Map([["a1", "athlete"], ["a2", "stoic"]]),
      clubMap: { athlete: "morning_warriors", stoic: "mindful_masters" },
      userStatsXp: new Map([["a1", 10], ["a2", 20]]),
      contributorXpByTribe: new Map(),
    });
    expect(out.get("creative_collective")?.totalXp).toBe(30);
    expect(out.get("morning_warriors")).toBeUndefined();
    expect(out.get("mindful_masters")).toBeUndefined();
  });

  it("members without user_stats docs contribute 0 XP", () => {
    const out = aggregateTribeStats({
      membershipMap: new Map([["u5", "deep_work_society"]]),
      archetypeMap: new Map(),
      clubMap: {},
      userStatsXp: new Map(),
      contributorXpByTribe: new Map(),
    });
    expect(out.get("deep_work_society")?.totalXp).toBe(0);
  });

  it("uses contributor records over user_stats sums (historical attribution)", () => {
    const out = aggregateTribeStats({
      membershipMap: new Map([["u1", "creative_collective"]]),
      archetypeMap: new Map(),
      clubMap: {},
      userStatsXp: new Map([["u1", 100]]),
      contributorXpByTribe: new Map([["creative_collective", 500]]),
    });
    // XP earned in a previous tribe stays there — the contributor record
    // (500) is authoritative, not the user's total stats (100).
    expect(out.get("creative_collective")?.totalXp).toBe(500);
  });
});

describe("recalcTribesInternal", () => {
  it("writes every tribe from membership docs, not just official clubs", async () => {
    const { db, findWrite, writeCount } = makeFakeDb({
      users: [new FakeDoc("u1", { archetype: "athlete" })],
      tribes: [
        new FakeDoc("m1", {}, "users/u1/tribes/creator_tribe_42"),
        // nested path shape is ignored by the guard
        new FakeDoc("m2", {}, "users/u1/tribes/creator_tribe_42/deeper"),
      ],
      userStats: [new FakeDoc("u1", { avatarStats: { totalXp: 300 } })],
      globalActivities: [],
    });

    const count = await recalcTribesInternal(db);

    // creator_tribe_42 + the 5 unique official club ids
    expect(count).toBe(6);
    expect(writeCount()).toBe(6);

    const creator = findWrite("tribes/creator_tribe_42");
    expect(creator).toBeDefined();
    expect(creator!.data).toEqual({
      members: ["u1"],
      memberCount: 1,
      totalXp: 300,
      totalHabitsCompleted: 0,
      totalChallengesCompleted: 0,
      lastStatsSync: expect.anything(),
    });

    // u1's archetype club is refreshed (union with official ids) but must NOT
    // receive u1 or their XP
    const morning = findWrite("tribes/morning_warriors");
    expect(morning).toBeDefined();
    expect(morning!.data.members).not.toContain("u1");
    expect(morning!.data.totalXp).toBe(0);

    // malformed subcollection paths are ignored
    expect(findWrite("tribes/creator_tribe_42/deeper")).toBeUndefined();
  });

  it("uses merge-set writes so creator tribe fields are preserved", async () => {
    const { db, committed } = makeFakeDb({
      users: [new FakeDoc("u1", { archetype: "athlete" })],
      tribes: [new FakeDoc("m1", {}, "users/u1/tribes/creator_tribe_42")],
      userStats: [new FakeDoc("u1", { avatarStats: { totalXp: 300 } })],
      globalActivities: [],
    });

    await recalcTribesInternal(db);

    const writes = committed.flat();
    expect(writes.length).toBeGreaterThan(0);
    for (const write of writes) {
      expect(write.op).toBe("set");
      expect(write.merge).toBe(true);
    }
  });

  it("writes totalXp from contributor records when present", async () => {
    const { db, findWrite } = makeFakeDb({
      users: [new FakeDoc("u1", { archetype: "athlete" })],
      tribes: [new FakeDoc("m1", {}, "users/u1/tribes/creator_tribe_42")],
      userStats: [new FakeDoc("u1", { avatarStats: { totalXp: 999 } })],
      contributors: [
        new FakeDoc("u1", { totalXpContributed: 250 }, "tribes/creator_tribe_42/contributors/u1"),
        new FakeDoc("u2", { totalXpContributed: 125 }, "tribes/creator_tribe_42/contributors/u2"),
      ],
      globalActivities: [],
    });

    const count = await recalcTribesInternal(db);

    expect(count).toBe(6);
    const creator = findWrite("tribes/creator_tribe_42");
    expect(creator).toBeDefined();
    // Contributor records win over the user_stats fallback (999).
    expect(creator!.data.totalXp).toBe(375);
    expect(creator!.data.members).toEqual(["u1"]);
  });

  it("derives totalHabitsCompleted from contributor docs, not global_activities", async () => {
    const { db, findWrite } = makeFakeDb({
      users: [new FakeDoc("u1", { archetype: "athlete" })],
      tribes: [new FakeDoc("m1", {}, "users/u1/tribes/creator_tribe_42")],
      userStats: [new FakeDoc("u1", { avatarStats: { totalXp: 300 } })],
      // Inflated feed: the global_activities events for u1 were never deleted
      // on undo, so counting them would report 10 habits.
      globalActivities: [
        new FakeDoc("g1", { type: "habit_complete", clubId: "creator_tribe_42" }),
        new FakeDoc("g2", { type: "habit_complete", clubId: "creator_tribe_42" }),
        new FakeDoc("g3", { type: "habit_complete", clubId: "creator_tribe_42" }),
        new FakeDoc("g4", { type: "habit_complete", clubId: "creator_tribe_42" }),
        new FakeDoc("g5", { type: "habit_complete", clubId: "creator_tribe_42" }),
        new FakeDoc("g6", { type: "habit_complete", clubId: "creator_tribe_42" }),
        new FakeDoc("g7", { type: "habit_complete", clubId: "creator_tribe_42" }),
        new FakeDoc("g8", { type: "habit_complete", clubId: "creator_tribe_42" }),
        new FakeDoc("g9", { type: "habit_complete", clubId: "creator_tribe_42" }),
        new FakeDoc("g10", { type: "habit_complete", clubId: "creator_tribe_42" }),
        new FakeDoc("c1", { type: "challenge_complete", clubId: "creator_tribe_42" }),
        new FakeDoc("c2", { type: "challenge_complete", clubId: "creator_tribe_42" }),
        new FakeDoc("c3", { type: "challenge_complete", clubId: "creator_tribe_42" }),
      ],
      // Contributor docs ARE debited on undo — they are the exact count.
      contributors: [
        new FakeDoc("u1", { totalHabitsCompleted: 4, totalChallengesCompleted: 2 },
          "tribes/creator_tribe_42/contributors/u1"),
        new FakeDoc("u2", { totalHabitsCompleted: 1, totalChallengesCompleted: 0 },
          "tribes/creator_tribe_42/contributors/u2"),
      ],
    });

    const count = await recalcTribesInternal(db);

    expect(count).toBe(6);
    const creator = findWrite("tribes/creator_tribe_42");
    expect(creator).toBeDefined();
    expect(creator!.data.totalHabitsCompleted).toBe(5);
    expect(creator!.data.totalChallengesCompleted).toBe(2);
  });

  it("falls back to global_activities counts for tribes without contributor docs", async () => {
    const { db, findWrite } = makeFakeDb({
      users: [new FakeDoc("u1", { archetype: "athlete" })],
      tribes: [new FakeDoc("m1", {}, "users/u1/tribes/legacy_tribe")],
      userStats: [new FakeDoc("u1", { avatarStats: { totalXp: 300 } })],
      globalActivities: [
        new FakeDoc("g1", { type: "habit_complete", clubId: "legacy_tribe" }),
        new FakeDoc("g2", { type: "habit_complete", clubId: "legacy_tribe" }),
        new FakeDoc("c1", { type: "challenge_complete", clubId: "legacy_tribe" }),
      ],
      contributors: [],
    });

    await recalcTribesInternal(db);

    const legacy = findWrite("tribes/legacy_tribe");
    expect(legacy).toBeDefined();
    expect(legacy!.data.totalHabitsCompleted).toBe(2);
    expect(legacy!.data.totalChallengesCompleted).toBe(1);
  });

  it("chunks tribe writes into batches of 500", async () => {
    const tribes: FakeDoc[] = [];
    for (let i = 0; i < 501; i++) {
      tribes.push(new FakeDoc(`m${i}`, {}, `users/u${i}/tribes/tribe_${i}`));
    }
    const { db, committed } = makeFakeDb({
      users: [],
      tribes,
      userStats: [],
      globalActivities: [],
    });

    const count = await recalcTribesInternal(db);

    expect(count).toBe(506); // 501 explicit + 5 unique official club ids
    expect(committed).toHaveLength(2);
    expect(committed[0]).toHaveLength(500);
    expect(committed[1]).toHaveLength(6);
  });
});
