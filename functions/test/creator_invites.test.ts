/**
 * Tests for creator_invites.ts — offline mode (no emulator).
 * Run with: cd functions && npm run build && npx jest test/creator_invites.test.ts
 *
 * NOTE: the firebase-admin mock MUST be registered before
 * firebase-functions-test loads (it imports firebase-admin at require time).
 */
// Stub admin so no real Firebase is contacted.
const setCustomUserClaims = jest.fn().mockResolvedValue(undefined);
const getUser = jest.fn();
const docGet = jest.fn(); // (collectionName, docId) -> Promise<snapshot>
const docSet = jest.fn();
const docDelete = jest.fn();
const queryGet = jest.fn();
const runTransaction = jest.fn();
const batchDelete = jest.fn();
const batchCommit = jest.fn().mockResolvedValue(undefined);
const batch = jest.fn(() => ({ delete: batchDelete, commit: batchCommit }));
const collection = jest.fn((name: string) => ({
  doc: jest.fn((id?: string) => ({
    id: id ?? "tribe-auto-1", // deterministic auto-id for .doc() with no arg
    get: jest.fn(() => docGet(name, id)),
    set: docSet,
    delete: docDelete,
    // subcollection chain (users/{uid}/tribes/{tribeId})
    collection: jest.fn((sub: string) => ({
      doc: jest.fn((subId?: string) => ({
        id: subId ?? "sub-auto-1",
        get: jest.fn(() => docGet(`${name}/${id}/${sub}`, subId)),
        set: docSet,
        delete: docDelete,
      })),
    })),
  })),
  where: jest.fn(() => ({
    where: jest.fn(() => ({
      limit: jest.fn(() => ({ get: queryGet })),
      get: queryGet,
    })),
    limit: jest.fn(() => ({ get: queryGet })),
    get: queryGet,
  })),
}));

const firestoreMock = jest.fn(() => ({ collection, runTransaction, batch }));
// admin.firestore.FieldValue / .Timestamp are statics on the function.
(
  firestoreMock as unknown as {
    FieldValue: { serverTimestamp: () => string };
    Timestamp: { now: () => Date; fromDate: (d: Date) => Date };
  }
).FieldValue = { serverTimestamp: () => "SERVER_TIMESTAMP" };
(
  firestoreMock as unknown as {
    Timestamp: { now: () => Date; fromDate: (d: Date) => Date };
  }
).Timestamp = { now: () => new Date(), fromDate: (d: Date) => d };

jest.mock("firebase-admin", () => ({
  apps: [],
  initializeApp: jest.fn(),
  firestore: firestoreMock,
  auth: () => ({ getUser, setCustomUserClaims }),
}));

// eslint-disable-next-line @typescript-eslint/no-require-imports
const ft = require("firebase-functions-test")();

// eslint-disable-next-line @typescript-eslint/no-require-imports
const { generateCreatorInviteCode } = require("../src/creator_invites");

const CODE_PATTERN = /^[A-Z2-9]{8}$/;

beforeEach(() => {
  jest.clearAllMocks();
  // Default: u1 is the admin creator (role + admin claim); any other uid is a
  // plain user with no profile (redeem/ensure tests drive non-creator callers).
  getUser.mockImplementation((uid: string) =>
    Promise.resolve({
      customClaims:
        uid === "u1" ? { role: "creator", admin: true } : { role: "user" },
    })
  );
  docGet.mockImplementation((name: string, id: string) =>
    Promise.resolve(
      name === "creator_profiles" && id === "u1"
        ? {
            exists: true,
            data: () => ({
              isVerifiedCreator: true,
              displayName: "Aria",
              archetype: "none",
            }),
          }
        : { exists: false, data: () => null }
    )
  );
  queryGet.mockResolvedValue({ size: 0, empty: true, docs: [], forEach: jest.fn() });
});

describe("generateCreatorInviteCode", () => {
  it("rejects unauthenticated calls", async () => {
    await expect(
      generateCreatorInviteCode.run({ auth: undefined, data: {} })
    ).rejects.toHaveProperty("code", "unauthenticated");
  });

  it("rejects non-creator claims", async () => {
    getUser.mockResolvedValue({ customClaims: { role: "user" } });
    await expect(
      generateCreatorInviteCode.run({ auth: { uid: "u1" }, data: {} })
    ).rejects.toHaveProperty("code", "permission-denied");
  });

  it("rejects a verified creator without the admin claim", async () => {
    getUser.mockResolvedValue({ customClaims: { role: "creator" } });
    await expect(
      generateCreatorInviteCode.run({ auth: { uid: "u1" }, data: {} })
    ).rejects.toHaveProperty("code", "permission-denied");
  });

  it("rejects when 10 codes are already outstanding", async () => {
    const codes = Array.from({ length: 10 }, (_, i) => ({
      id: `CODE00${i}`,
      data: () => ({
        redeemedBy: null,
        expiresAt: new Date(Date.now() + 100000), // still valid
      }),
    }));
    queryGet.mockResolvedValue({
      size: 10,
      docs: codes,
      forEach: jest.fn((cb: (d: { id: string; data: () => object }) => void) =>
        codes.forEach(cb)
      ),
    });
    await expect(
      generateCreatorInviteCode.run({ auth: { uid: "u1" }, data: {} })
    ).rejects.toHaveProperty("code", "resource-exhausted");
  });

  it("frees quota from expired codes and deletes them best-effort (Fix 5)", async () => {
    // 10 codes, 3 expired (past expiresAt), 7 outstanding and valid.
    const expired = [0, 1, 2].map((i) => ({
      id: `EXPIRED${i}`,
      data: () => ({
        redeemedBy: null,
        expiresAt: new Date(Date.now() - 1000),
      }),
    }));
    const active = Array.from({ length: 7 }, (_, i) => ({
      id: `ACTIVE0${i}`,
      data: () => ({
        redeemedBy: null,
        expiresAt: new Date(Date.now() + 100000),
      }),
    }));
    const codes = [...expired, ...active];
    queryGet.mockResolvedValue({
      size: 10,
      docs: codes,
      forEach: jest.fn((cb: (d: { id: string; data: () => object }) => void) =>
        codes.forEach(cb)
      ),
    });

    const result = await generateCreatorInviteCode.run({
      auth: { uid: "u1" },
      data: {},
    });

    expect(CODE_PATTERN.test(result.code)).toBe(true);
    expect(batch).toHaveBeenCalled();
    expect(batchDelete).toHaveBeenCalledTimes(3);
    for (const id of ["EXPIRED0", "EXPIRED1", "EXPIRED2"]) {
      expect(batchDelete).toHaveBeenCalledWith(
        expect.objectContaining({ id })
      );
    }
    expect(batchCommit).toHaveBeenCalled();
  });

  it("creates a doc and returns an 8-char ambiguity-free code", async () => {
    // Default mock already makes the profile verified and code reads miss.
    const result = await generateCreatorInviteCode.run({ auth: { uid: "u1" }, data: {} });
    expect(CODE_PATTERN.test(result.code)).toBe(true);
    expect(docSet).toHaveBeenCalled();
    const written = docSet.mock.calls[0][0];
    expect(written.creatorUid).toBe("u1");
    expect(written.redeemedBy).toBeNull();
    expect(written.expiresAt).toBeInstanceOf(Date);
  });
});

// eslint-disable-next-line @typescript-eslint/no-require-imports
const { redeemCreatorInvite } = require("../src/creator_invites");

describe("redeemCreatorInvite", () => {
  it("rejects unauthenticated calls", async () => {
    await expect(
      redeemCreatorInvite.run({ auth: undefined, data: { code: "ABCDEFGH" } })
    ).rejects.toHaveProperty("code", "unauthenticated");
  });

  it("rejects a malformed code", async () => {
    await expect(
      redeemCreatorInvite.run({ auth: { uid: "u2" }, data: { code: "abc!" } })
    ).rejects.toHaveProperty("code", "invalid-argument");
  });

  it("rejects when the caller is already a creator", async () => {
    docGet.mockImplementation((name: string, id: string) =>
      Promise.resolve(
        name === "creator_profiles" && id === "u2"
          ? { exists: true, data: () => ({ isVerifiedCreator: true }) }
          : { exists: false, data: () => null }
      )
    );
    await expect(
      redeemCreatorInvite.run({ auth: { uid: "u2" }, data: { code: "ABCDEFGH" } })
    ).rejects.toHaveProperty("code", "already-exists");
  });

  it("recovers when the transaction committed but the claim was never set (Fix 7)", async () => {
    // First attempt: profile committed (ownerId == uid, verified) but
    // setCustomUserClaims failed AFTER the transaction — retry must repair
    // the missing claim instead of bricking the signup.
    docGet.mockImplementation((name: string, id: string) =>
      Promise.resolve(
        name === "creator_profiles" && id === "u2"
          ? {
              exists: true,
              data: () => ({ ownerId: "u2", isVerifiedCreator: true }),
            }
          : { exists: false, data: () => null }
      )
    );
    getUser.mockResolvedValue({ customClaims: { role: "user" } });

    const result = await redeemCreatorInvite.run({
      auth: { uid: "u2" },
      data: { code: "ABCDEFGH" },
    });

    expect(result).toEqual({ ok: true, uid: "u2", recovered: true });
    expect(setCustomUserClaims).toHaveBeenCalledWith(
      "u2",
      expect.objectContaining({ role: "creator" })
    );
    // The code is consumed by the first (committed) transaction — no new
    // transaction runs on the recovery path.
    expect(runTransaction).not.toHaveBeenCalled();
  });

  it("does not recover a verified profile owned by someone else (Fix 7)", async () => {
    docGet.mockImplementation((name: string, id: string) =>
      Promise.resolve(
        name === "creator_profiles" && id === "u2"
          ? {
              exists: true,
              data: () => ({ ownerId: "u1", isVerifiedCreator: true }),
            }
          : { exists: false, data: () => null }
      )
    );
    getUser.mockResolvedValue({ customClaims: { role: "user" } });
    await expect(
      redeemCreatorInvite.run({ auth: { uid: "u2" }, data: { code: "ABCDEFGH" } })
    ).rejects.toHaveProperty("code", "already-exists");
    expect(setCustomUserClaims).not.toHaveBeenCalled();
  });

  it("rejects an unknown code", async () => {
    runTransaction.mockImplementation(async (fn: (tx: unknown) => Promise<void>) => {
      const tx = {
        get: jest.fn().mockResolvedValue({ exists: false, data: () => null }),
        set: jest.fn(),
        delete: jest.fn(),
      };
      await fn(tx);
    });
    await expect(
      redeemCreatorInvite.run({ auth: { uid: "u2" }, data: { code: "ABCDEFGH" } })
    ).rejects.toHaveProperty("code", "not-found");
  });

  it("rejects an already-redeemed code", async () => {
    runTransaction.mockImplementation(async (fn: (tx: unknown) => Promise<void>) => {
      const tx = {
        get: jest.fn().mockResolvedValue({
          exists: true,
          data: () => ({ creatorUid: "u1", redeemedBy: "other", expiresAt: new Date(Date.now() + 100000) }),
        }),
        set: jest.fn(),
        delete: jest.fn(),
      };
      await fn(tx);
    });
    await expect(
      redeemCreatorInvite.run({ auth: { uid: "u2" }, data: { code: "ABCDEFGH" } })
    ).rejects.toHaveProperty("code", "failed-precondition");
  });

  it("rejects an expired code", async () => {
    runTransaction.mockImplementation(async (fn: (tx: unknown) => Promise<void>) => {
      const tx = {
        get: jest.fn().mockResolvedValue({
          exists: true,
          data: () => ({ creatorUid: "u1", redeemedBy: null, expiresAt: new Date(Date.now() - 1000) }),
        }),
        set: jest.fn(),
        delete: jest.fn(),
      };
      await fn(tx);
    });
    await expect(
      redeemCreatorInvite.run({ auth: { uid: "u2" }, data: { code: "ABCDEFGH" } })
    ).rejects.toHaveProperty("code", "failed-precondition");
  });

  it("redeems: creates profile, deletes code, sets the role claim", async () => {
    const txSet = jest.fn();
    const txDelete = jest.fn();
    runTransaction.mockImplementation(async (fn: (tx: unknown) => Promise<void>) => {
      const tx = {
        get: jest.fn().mockResolvedValue({
          exists: true,
          data: () => ({ creatorUid: "u1", redeemedBy: null, expiresAt: new Date(Date.now() + 100000) }),
        }),
        set: txSet,
        delete: txDelete,
      };
      await fn(tx);
    });
    const result = await redeemCreatorInvite.run({
      auth: { uid: "u2" },
      data: { code: "abcdeFGH", displayName: "New Creator" },
    });
    expect(result.ok).toBe(true);
    expect(txDelete).toHaveBeenCalled();
    const profileWrite = txSet.mock.calls.find(
      ([, data]: [unknown, Record<string, unknown>]) =>
        data?.userId === "u2" && data?.isVerifiedCreator === true
    );
    expect(profileWrite).toBeDefined();
    expect(setCustomUserClaims).toHaveBeenCalledWith(
      "u2",
      expect.objectContaining({ role: "creator" })
    );
  });
});

// eslint-disable-next-line @typescript-eslint/no-require-imports
const { ensureCreatorTribe } = require("../src/creator_invites");

describe("ensureCreatorTribe", () => {
  it("rejects unauthenticated calls", async () => {
    await expect(
      ensureCreatorTribe.run({ auth: undefined, data: {} })
    ).rejects.toHaveProperty("code", "unauthenticated");
  });

  it("rejects unverified creators", async () => {
    docGet.mockImplementation(() =>
      Promise.resolve({ exists: false, data: () => null })
    );
    await expect(
      ensureCreatorTribe.run({ auth: { uid: "u1" }, data: {} })
    ).rejects.toHaveProperty("code", "permission-denied");
  });

  it("creates a tribe on first publish and links the blueprint", async () => {
    // u1 verified (default mock), no existing tribe, blueprint owned by u1.
    docGet.mockImplementation((name: string, id: string) =>
      Promise.resolve(
        name === "creator_profiles" && id === "u1"
          ? {
              exists: true,
              data: () => ({ isVerifiedCreator: true, displayName: "Aria", archetype: "none" }),
            }
          : name === "blueprints" && id === "bp1"
            ? { exists: true, data: () => ({ creatorUserId: "u1" }) }
            : { exists: false, data: () => null }
      )
    );

    const result = await ensureCreatorTribe.run({
      auth: { uid: "u1" },
      data: { blueprintId: "bp1" },
    });
    expect(result.tribeId).toBeTruthy();
    expect(result.created).toBe(true);
    const tribeWrite = docSet.mock.calls.find((args) =>
      args.some(
        (a: unknown) =>
          a !== null &&
          typeof a === "object" &&
          (a as Record<string, unknown>).type === "creator"
      )
    );
    expect(tribeWrite).toBeDefined();
    const tribeData = tribeWrite!.find(
      (a: unknown) =>
        a !== null &&
        typeof a === "object" &&
        (a as Record<string, unknown>).type === "creator"
    ) as Record<string, unknown>;
    expect(tribeData.name).toBe("Aria's Tribe");
    expect(tribeData.createdBy).toBe("u1");
    expect(tribeData.members).toEqual(["u1"]);
    expect(tribeData.memberCount).toBe(1);
    // profile merge: creator_profiles/{uid}.tribeId
    const profileMerge = docSet.mock.calls.find((args) =>
      args.some(
        (a: unknown) =>
          a !== null &&
          typeof a === "object" &&
          (a as Record<string, unknown>).tribeId === result.tribeId &&
          (a as Record<string, unknown>).ownerId === "u1"
      )
    );
    expect(profileMerge).toBeDefined();
    // blueprint linked
    const bpLink = docSet.mock.calls.find((args) =>
      args.some(
        (a: unknown) =>
          a !== null &&
          typeof a === "object" &&
          (a as Record<string, unknown>).creatorTribeId === result.tribeId
      )
    );
    expect(bpLink).toBeDefined();
  });

  it("writes the creator's explicit membership doc (Fix 2)", async () => {
    const result = await ensureCreatorTribe.run({
      auth: { uid: "u1" },
      data: {},
    });

    const membershipWrite = docSet.mock.calls.find((args) =>
      args.some(
        (a: unknown) =>
          a !== null &&
          typeof a === "object" &&
          (a as Record<string, unknown>).isActive === true &&
          (a as Record<string, unknown>).tribeId === result.tribeId
      )
    );
    expect(membershipWrite).toBeDefined();
    const membershipData = membershipWrite!.find(
      (a: unknown) =>
        a !== null &&
        typeof a === "object" &&
        (a as Record<string, unknown>).isActive === true
    ) as Record<string, unknown>;
    // Same shape as the client join path (tribe_membership_service.dart):
    // {tribeId, joinedAt, membershipType, isActive} — recalcTribes aggregates
    // members exclusively from these docs.
    expect(membershipData).toEqual({
      tribeId: result.tribeId,
      joinedAt: "SERVER_TIMESTAMP",
      membershipType: "creator",
      isActive: true,
    });
    // Merge-set, so a re-run is idempotent and repairs legacy creators.
    expect(membershipWrite![1]).toEqual({ merge: true });
  });

  it("queries creator tribes by type only and filters createdBy in memory (Fix 1)", async () => {
    queryGet.mockResolvedValue({
      empty: false,
      size: 2,
      docs: [
        { id: "tribe-other", data: () => ({ createdBy: "someone-else" }) },
        { id: "tribe-mine", data: () => ({ createdBy: "u1" }) },
      ],
      forEach: jest.fn(),
    });

    const result = await ensureCreatorTribe.run({ auth: { uid: "u1" }, data: {} });
    expect(result.tribeId).toBe("tribe-mine");
    expect(result.created).toBe(false);

    // No composite index: the ONLY where() on the tribes collection is the
    // single auto-indexed field filter — never (createdBy, type).
    const whereMocks = collection.mock.results
      .map((r) => r.value?.where)
      .filter((w): w is jest.Mock => typeof w === "function" && w.mock);
    expect(whereMocks.length).toBeGreaterThan(0);
    for (const w of whereMocks) {
      for (const call of w.mock.calls) {
        expect(call[0]).toBe("type");
        expect(call[1]).toBe("==");
        expect(call[2]).toBe("creator");
      }
    }
  });

  it("reuses an existing tribe on second publish", async () => {
    queryGet.mockResolvedValue({
      empty: false,
      docs: [{ id: "tribe-1", data: () => ({ createdBy: "u1" }) }],
      size: 1,
      forEach: jest.fn((cb: (doc: { id: string; data: () => object }) => void) =>
        cb({ id: "tribe-1", data: () => ({ createdBy: "u1" }) })
      ),
    });
    const result = await ensureCreatorTribe.run({ auth: { uid: "u1" }, data: {} });
    expect(result.tribeId).toBe("tribe-1");
    expect(result.created).toBe(false);
    // Membership doc is written on the reuse path too (repairs legacy
    // creators who predate the explicit-membership fix).
    const membershipWrite = docSet.mock.calls.find((args) =>
      args.some(
        (a: unknown) =>
          a !== null &&
          typeof a === "object" &&
          (a as Record<string, unknown>).isActive === true &&
          (a as Record<string, unknown>).tribeId === "tribe-1"
      )
    );
    expect(membershipWrite).toBeDefined();
  });
});
