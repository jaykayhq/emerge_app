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
  // Default: caller is a verified creator; every invite-code doc read misses
  // (no collisions). Tests override per-case.
  getUser.mockResolvedValue({ customClaims: { role: "creator" } });
  docGet.mockImplementation((name: string) =>
    Promise.resolve(
      name === "creator_profiles"
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
