import { maintainTribeXpInternal } from "../src/tribe_contributions";

class FakeDocRef {
  constructor(
    readonly id: string,
    private store: Map<string, Record<string, unknown>>,
    private sharedWrites: Array<{ data: Record<string, unknown> }>,
  ) {}
  async get(): Promise<FakeDocSnap> {
    const raw = this.store.get(this.id);
    return new FakeDocSnap(this.id, raw ? { ...raw } : undefined);
  }
  update(data: Record<string, unknown>): void {
    const current = this.store.get(this.id) ?? {};
    this.store.set(this.id, { ...current, ...data });
    this.sharedWrites.push({ data });
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

function makeDb(
  store: Map<string, Record<string, unknown>>,
): { db: unknown; writes: Array<{ data: Record<string, unknown> }> } {
  const writes: Array<{ data: Record<string, unknown> }> = [];
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
      runTransaction: async (fn: unknown) =>
        (
          fn as (t: {
            get: (r: FakeDocRef) => Promise<FakeDocSnap>;
            update: (r: FakeDocRef, data: Record<string, unknown>) => void;
          }) => Promise<void>
        )({
          get: async (r: FakeDocRef) => r.get(),
          update: (r: FakeDocRef, data: Record<string, unknown>) => r.update(data),
        }),
    },
    writes,
  };
}

describe("maintainTribeXpInternal", () => {
  it("applies the contributor delta to the tribe totalXp", async () => {
    const store = new Map<string, Record<string, unknown>>([
      ["morning_warriors", { members: ["user1"], totalXp: 500 }],
    ]);
    const { db, writes } = makeDb(store);

    await maintainTribeXpInternal(
      db as Parameters<typeof maintainTribeXpInternal>[0],
      { tribeId: "morning_warriors", memberId: "user1" },
      { totalXpContributed: 100 },
      { totalXpContributed: 150 },
    );

    expect(writes).toHaveLength(1);
    expect(writes[0].data).toEqual({ totalXp: 550 });
  });

  it("creates a contributor record with an initial contribution", async () => {
    const store = new Map<string, Record<string, unknown>>([
      ["morning_warriors", { members: ["user1"], totalXp: 0 }],
    ]);
    const { db, writes } = makeDb(store);

    await maintainTribeXpInternal(
      db as Parameters<typeof maintainTribeXpInternal>[0],
      { tribeId: "morning_warriors", memberId: "user1" },
      undefined,
      { totalXpContributed: 40 },
    );

    expect(writes[0].data).toEqual({ totalXp: 40 });
  });

  it("subtracts on contributor delete (account cleanup)", async () => {
    const store = new Map<string, Record<string, unknown>>([
      ["morning_warriors", { members: ["user1"], totalXp: 300 }],
    ]);
    const { db, writes } = makeDb(store);

    await maintainTribeXpInternal(
      db as Parameters<typeof maintainTribeXpInternal>[0],
      { tribeId: "morning_warriors", memberId: "user1" },
      { totalXpContributed: 250 },
      undefined,
    );

    expect(writes[0].data).toEqual({ totalXp: 50 });
  });

  it("clamps at zero and skips zero-delta writes", async () => {
    const store = new Map<string, Record<string, unknown>>([
      ["morning_warriors", { totalXp: 10 }],
    ]);
    const { db, writes } = makeDb(store);

    await maintainTribeXpInternal(
      db as Parameters<typeof maintainTribeXpInternal>[0],
      { tribeId: "morning_warriors", memberId: "user1" },
      { totalXpContributed: 200 },
      undefined,
    );

    expect(writes).toHaveLength(1);
    expect(writes[0].data).toEqual({ totalXp: 0 });

    // Zero delta (e.g. join-time contributor set without totals) → no write.
    await maintainTribeXpInternal(
      db as Parameters<typeof maintainTribeXpInternal>[0],
      { tribeId: "morning_warriors", memberId: "user2" },
      undefined,
      { joinedAt: new Date() },
    );
    expect(writes).toHaveLength(1);
  });

  it("skips when the tribe doc is missing", async () => {
    const store = new Map<string, Record<string, unknown>>();
    const { db, writes } = makeDb(store);

    await maintainTribeXpInternal(
      db as Parameters<typeof maintainTribeXpInternal>[0],
      { tribeId: "missing", memberId: "user1" },
      { totalXpContributed: 50 },
      { totalXpContributed: 100 },
    );

    expect(writes).toHaveLength(0);
  });
});
