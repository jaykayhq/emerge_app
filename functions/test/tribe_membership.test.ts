import { maintainTribeMembershipInternal } from "../src/tribe_membership";

class FakeDocRef {
  constructor(
    readonly id: string,
    private store: Map<string, Record<string, unknown>>,
    private sharedWrites: Array<{ op: string; data: Record<string, unknown> }>,
  ) {}
  get path(): string {
    return `tribes/${this.id}`;
  }
  async get(): Promise<FakeDocSnap> {
    const raw = this.store.get(this.id);
    return new FakeDocSnap(this.id, raw ? { ...raw } : undefined);
  }
  update(data: Record<string, unknown>): void {
    const current = this.store.get(this.id) ?? {};
    this.store.set(this.id, { ...current, ...data });
    this.sharedWrites.push({ op: "update", data });
  }
}

class FakeDocSnap {
  constructor(
    readonly id: string,
    private readonly raw: Record<string, unknown> | undefined,
  ) {}
  get exists(): boolean {
    return this.raw !== undefined;
  }
  data(): Record<string, unknown> {
    return this.raw ?? {};
  }
}

interface FakeDb {
  collection(path: string): { doc(id: string): FakeDocRef };
  runTransaction<T>(
    fn: (t: {
      get: (r: FakeDocRef) => Promise<FakeDocSnap>;
      update: (r: FakeDocRef, data: Record<string, unknown>) => void;
    }) => Promise<T>,
  ): Promise<T>;
}

function makeDb(
  store: Map<string, Record<string, unknown>>,
): { db: FakeDb; writes: Array<{ op: string; data: Record<string, unknown> }> } {
  const writes: Array<{ op: string; data: Record<string, unknown> }> = [];
  const refs = new Map<string, FakeDocRef>();
  const getRef = (id: string): FakeDocRef => {
    let ref = refs.get(id);
    if (!ref) {
      ref = new FakeDocRef(id, store, writes);
      refs.set(id, ref);
    }
    return ref;
  };
  return {
    db: {
      collection: () => ({ doc: getRef }),
      runTransaction: async (fn) =>
        fn({
          get: async (r: FakeDocRef) => r.get(),
          update: (r: FakeDocRef, data: Record<string, unknown>) => r.update(data),
        }),
    },
    writes,
  };
}


describe("maintainTribeMembershipInternal", () => {
  it("adds the member and derives memberCount on join", async () => {
    const store = new Map<string, Record<string, unknown>>([
      ["morning_warriors", { name: "Morning Warriors", members: [], memberCount: 0 }],
    ]);
    const { db, writes } = makeDb(store);

    await maintainTribeMembershipInternal(
      db as unknown as Parameters<typeof maintainTribeMembershipInternal>[0],
      { userId: "user1", tribeId: "morning_warriors" },
      undefined,
      { tribeId: "morning_warriors" },
    );

    expect(writes).toHaveLength(1);
    expect(writes[0].data).toEqual({ members: ["user1"], memberCount: 1 });
  });

  it("is idempotent on join replay (member already present -> no write)", async () => {
    const store = new Map<string, Record<string, unknown>>([
      ["morning_warriors", { members: ["user1"], memberCount: 1 }],
    ]);
    const { db, writes } = makeDb(store);

    await maintainTribeMembershipInternal(
      db as unknown as Parameters<typeof maintainTribeMembershipInternal>[0],
      { userId: "user1", tribeId: "morning_warriors" },
      undefined,
      { tribeId: "morning_warriors" },
    );

    expect(writes).toHaveLength(0);
  });

  it("removes the member and derives memberCount on leave", async () => {
    const store = new Map<string, Record<string, unknown>>([
      ["morning_warriors", { members: ["user1", "user2"], memberCount: 2 }],
    ]);
    const { db, writes } = makeDb(store);

    await maintainTribeMembershipInternal(
      db as unknown as Parameters<typeof maintainTribeMembershipInternal>[0],
      { userId: "user1", tribeId: "morning_warriors" },
      { tribeId: "morning_warriors" },
      undefined,
    );

    expect(writes).toHaveLength(1);
    expect(writes[0].data).toEqual({ members: ["user2"], memberCount: 1 });
  });

  it("is idempotent on leave replay (member absent -> no write)", async () => {
    const store = new Map<string, Record<string, unknown>>([
      ["morning_warriors", { members: ["user2"], memberCount: 1 }],
    ]);
    const { db, writes } = makeDb(store);

    await maintainTribeMembershipInternal(
      db as unknown as Parameters<typeof maintainTribeMembershipInternal>[0],
      { userId: "user1", tribeId: "morning_warriors" },
      { tribeId: "morning_warriors" },
      undefined,
    );

    expect(writes).toHaveLength(0);
  });

  it("handles seeded official clubs without a members array", async () => {
    const store = new Map<string, Record<string, unknown>>([
      ["morning_warriors", { name: "Morning Warriors", memberCount: 1250 }],
    ]);
    const { db, writes } = makeDb(store);

    await maintainTribeMembershipInternal(
      db as unknown as Parameters<typeof maintainTribeMembershipInternal>[0],
      { userId: "user1", tribeId: "morning_warriors" },
      undefined,
      { tribeId: "morning_warriors" },
    );

    // Derives the array from scratch — the count becomes the real member
    // count (matching recalcTribes), never the fake seeded 1250.
    expect(writes[0].data).toEqual({ members: ["user1"], memberCount: 1 });
  });

  it("skips when the tribe doc does not exist", async () => {
    const store = new Map<string, Record<string, unknown>>();
    const { db, writes } = makeDb(store);

    await maintainTribeMembershipInternal(
      db as unknown as Parameters<typeof maintainTribeMembershipInternal>[0],
      { userId: "user1", tribeId: "missing_club" },
      undefined,
      { tribeId: "missing_club" },
    );

    expect(writes).toHaveLength(0);
  });

  it("ignores membership doc updates (no count change)", async () => {
    const store = new Map<string, Record<string, unknown>>([
      ["morning_warriors", { members: ["user1"], memberCount: 1 }],
    ]);
    const { db, writes } = makeDb(store);

    await maintainTribeMembershipInternal(
      db as unknown as Parameters<typeof maintainTribeMembershipInternal>[0],
      { userId: "user1", tribeId: "morning_warriors" },
      { tribeId: "morning_warriors", membershipType: "archetype" },
      { tribeId: "morning_warriors", membershipType: "custom" },
    );

    expect(writes).toHaveLength(0);
  });
});
