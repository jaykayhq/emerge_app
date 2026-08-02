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
const collection = jest.fn((name: string) => ({
  doc: jest.fn((id: string) => ({
    get: jest.fn(() => docGet(name, id)),
    set: docSet,
    delete: docDelete,
  })),
  where: jest.fn(() => ({ get: queryGet })),
}));

const firestoreMock = jest.fn(() => ({ collection, runTransaction }));
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
  // Default: u1 is a verified creator; any other uid is a plain user with
  // no profile (redeem/ensure tests drive non-creator callers).
  getUser.mockImplementation((uid: string) =>
    Promise.resolve({ customClaims: { role: uid === "u1" ? "creator" : "user" } })
  );
  docGet.mockImplementation((name: string, id: string) =>
    Promise.resolve(
      name === "creator_profiles" && id === "u1"
        ? { exists: true, data: () => ({ isVerifiedCreator: true }) }
        : { exists: false, data: () => null }
    )
  );
  queryGet.mockResolvedValue({ size: 0, docs: [], forEach: jest.fn() });
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

  it("rejects a creator claim with no verified profile doc", async () => {
    docGet.mockImplementation(() =>
      Promise.resolve({ exists: false, data: () => null })
    );
    await expect(
      generateCreatorInviteCode.run({ auth: { uid: "u1" }, data: {} })
    ).rejects.toHaveProperty("code", "permission-denied");
  });

  it("rejects when 10 codes are already outstanding", async () => {
    queryGet.mockResolvedValue({
      size: 10,
      docs: Array.from({ length: 10 }, (_, i) => ({ data: () => ({ redeemedBy: null }) })),
      forEach: jest.fn((cb) => {
        for (let i = 0; i < 10; i++) cb({ data: () => ({ redeemedBy: null }) });
      }),
    });
    await expect(
      generateCreatorInviteCode.run({ auth: { uid: "u1" }, data: {} })
    ).rejects.toHaveProperty("code", "resource-exhausted");
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
