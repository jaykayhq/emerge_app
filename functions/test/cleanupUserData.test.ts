/**
 * Tests for cleanupUserData.ts.
 *
 * deleteMyAccount must remove the user from every tribe's `members` array
 * with a DERIVED memberCount write — not a raw increment — so the result is
 * identical regardless of whether maintainTribeMembership already removed
 * the uid (recursiveDelete of users/{uid} fires the trigger). Both writers
 * derive memberCount from the array, so ordering can never double-decrement.
 */
import * as admin from "firebase-admin";
import {
  deleteMyAccount,
  removeUserFromTribesInternal,
} from "../src/cleanupUserData";

// The live fake Firestore instance captured by the module-level
// `admin.firestore()` call in cleanupUserData.ts. Tests mutate it per-case.
const fakeDb = (admin as unknown as { __fakeDb: any }).__fakeDb;
const chainable = (admin as unknown as { __chainable: any }).__chainable;

interface FakeTribeDoc {
  ref: { path: string };
  data(): { members?: unknown };
}

function makeTribesFake(tribeDocs: FakeTribeDoc[]) {
  const writes: Array<{ ref: { path: string }; data: Record<string, unknown> }> = [];
  const db = {
    collection(_name: string) {
      return {
        where() {
          return {
            get: async () => ({
              empty: tribeDocs.length === 0,
              docs: tribeDocs,
            }),
          };
        },
      };
    },
    batch() {
      return {
        update(ref: { path: string }, data: Record<string, unknown>) {
          writes.push({ ref, data });
        },
        async commit() {},
      };
    },
  };
  return {
    db: db as unknown as Parameters<typeof removeUserFromTribesInternal>[0],
    writes,
  };
}

describe("removeUserFromTribesInternal", () => {
  it("removes the uid from members and derives memberCount", async () => {
    const { db, writes } = makeTribesFake([
      {
        ref: { path: "tribes/morning_warriors" },
        data: () => ({ members: ["u1", "u2", "u3"] }),
      },
    ]);

    await removeUserFromTribesInternal(db, "u1");

    expect(writes).toHaveLength(1);
    expect(writes[0].ref.path).toBe("tribes/morning_warriors");
    expect(writes[0].data).toEqual({
      members: ["u2", "u3"],
      memberCount: 2,
    });
  });

  it("is idempotent when the membership trigger already removed the uid", async () => {
    const { db, writes } = makeTribesFake([
      {
        ref: { path: "tribes/morning_warriors" },
        data: () => ({ members: ["u2"], memberCount: 1 }),
      },
    ]);

    await removeUserFromTribesInternal(db, "u1");

    expect(writes).toHaveLength(0);
  });

  it("removes a member whose membership doc no longer exists (members-array-only)", async () => {
    const { db, writes } = makeTribesFake([
      {
        ref: { path: "tribes/creator_tribe" },
        // u1 appears in members but their users/{uid}/tribes doc is gone —
        // the array is the only remaining record, and it must be cleaned.
        data: () => ({ members: ["u1", "u9"] }),
      },
    ]);

    await removeUserFromTribesInternal(db, "u1");

    expect(writes).toHaveLength(1);
    expect(writes[0].data).toEqual({
      members: ["u9"],
      memberCount: 1,
    });
  });

  it("does nothing when the uid is in no tribe", async () => {
    const { db, writes } = makeTribesFake([]);

    await removeUserFromTribesInternal(db, "u1");

    expect(writes).toHaveLength(0);
  });
});

describe("deleteMyAccount", () => {
  it("removes the uid from tribe members arrays with a derived count", async () => {
    const tribeDocs: FakeTribeDoc[] = [
      {
        ref: { path: "tribes/morning_warriors" },
        data: () => ({ members: ["u1", "u2"] }),
      },
      {
        ref: { path: "tribes/deep_work_society" },
        data: () => ({ members: ["u1", "u5", "u6"] }),
      },
    ];
    const writes: Array<{ ref: { path: string }; data: Record<string, unknown> }> = [];

    fakeDb.collection = (name: string) => {
      if (name === "tribes") {
        return {
          where() {
            return {
              get: async () => ({
                empty: tribeDocs.length === 0,
                docs: tribeDocs,
              }),
            };
          },
        };
      }
      return chainable;
    };
    fakeDb.batch = () => ({
      update(ref: { path: string }, data: Record<string, unknown>) {
        writes.push({ ref, data });
      },
      async commit() {},
    });

    const result = await deleteMyAccount.run({
      auth: { uid: "u1", token: {}, rawToken: "" } as any,
      data: {},
    } as any);

    expect(result).toEqual({ success: true });
    expect(writes).toHaveLength(2);
    expect(writes.map((w) => w.ref.path).sort()).toEqual([
      "tribes/deep_work_society",
      "tribes/morning_warriors",
    ]);
    expect(writes.find((w) => w.ref.path === "tribes/morning_warriors")!.data)
      .toEqual({ members: ["u2"], memberCount: 1 });
    expect(writes.find((w) => w.ref.path === "tribes/deep_work_society")!.data)
      .toEqual({ members: ["u5", "u6"], memberCount: 2 });
  });
});

// ── firebase-admin stub. Everything the module-level `admin.firestore()`
//    capture needs is constructed INSIDE the factory (no outer references),
//    and the live fakes are exposed so tests can reconfigure them. ──
jest.mock("firebase-admin", () => {
  const chainable = {
    where: () => chainable,
    doc: () => chainable,
    get: async () => ({ empty: true, docs: [] }),
    delete: async () => {},
    recursiveDelete: async () => {},
    set: async () => {},
    update: async () => {},
  };
  const db: Record<string, unknown> = {
    collection: () => chainable,
    batch: () => ({
      update: () => {},
      async commit() {},
    }),
    recursiveDelete: async () => {},
  };
  return {
    apps: [],
    initializeApp: jest.fn(),
    firestore: () => db,
    auth: () => ({ deleteUser: jest.fn().mockResolvedValue(undefined) }),
    __fakeDb: db,
    __chainable: chainable,
  };
});
