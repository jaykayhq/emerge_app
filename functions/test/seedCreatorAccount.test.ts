/**
 * Tests for seedCreatorAccount.ts guard logic (offline).
 * The handler is an onRequest — test the exported inner function directly.
 *
 * NOTE: the firebase-admin mock MUST be registered before anything else
 * requires it (firebase-functions-test imports it at require time).
 */
// Stub admin so no real Firebase is contacted.
const setCustomUserClaims = jest.fn().mockResolvedValue(undefined);
const getUserByEmail = jest.fn();
const createUser = jest.fn();
const updateUser = jest.fn();
const docSet = jest.fn();
const collection = jest.fn((name: string) => ({
  doc: jest.fn((id: string) => ({
    id: id ?? "code-abcdefgh",
    set: docSet,
  })),
}));
const firestoreMock = jest.fn(() => ({ collection }));
(
  firestoreMock as unknown as { FieldValue: { serverTimestamp: () => string } }
).FieldValue = { serverTimestamp: () => "SERVER_TIMESTAMP" };
(
  firestoreMock as unknown as { Timestamp: { now: () => Date } }
).Timestamp = { now: () => new Date() };

jest.mock("firebase-admin", () => ({
  apps: [],
  initializeApp: jest.fn(),
  firestore: firestoreMock,
  auth: () => ({
    getUserByEmail,
    createUser,
    updateUser,
    setCustomUserClaims,
  }),
}));

// eslint-disable-next-line @typescript-eslint/no-require-imports
const { seedCreatorAccountHandler } = require("../src/seedCreatorAccount");

const OLD_SECRET = process.env.ADMIN_SECRET;
const OLD_EMAIL = process.env.CREATOR_EMAIL;
const OLD_PASSWORD = process.env.CREATOR_PASSWORD;

afterAll(() => {
  if (OLD_SECRET !== undefined) process.env.ADMIN_SECRET = OLD_SECRET;
  if (OLD_EMAIL !== undefined) process.env.CREATOR_EMAIL = OLD_EMAIL;
  if (OLD_PASSWORD !== undefined) process.env.CREATOR_PASSWORD = OLD_PASSWORD;
});

beforeEach(() => {
  jest.clearAllMocks();
});

describe("seedCreatorAccountHandler", () => {
  it("rejects a missing bearer token", async () => {
    process.env.ADMIN_SECRET = "s3cret";
    const res = { status: jest.fn().mockReturnThis(), json: jest.fn() };
    await seedCreatorAccountHandler({ headers: {} }, res);
    expect(res.status).toHaveBeenCalledWith(403);
  });

  it("fails closed when ADMIN_SECRET is not configured (Fix 4)", async () => {
    delete process.env.ADMIN_SECRET;
    const res = { status: jest.fn().mockReturnThis(), json: jest.fn() };
    await seedCreatorAccountHandler(
      { headers: { authorization: "Bearer anything" } },
      res
    );
    expect(res.status).toHaveBeenCalledWith(500);
    expect(res.json).toHaveBeenCalledWith(
      expect.objectContaining({ error: expect.any(String) })
    );
    // Never proceeds to auth/profile/code work.
    expect(getUserByEmail).not.toHaveBeenCalled();
    expect(docSet).not.toHaveBeenCalled();
  });

  it("rejects a wrong admin secret", async () => {
    process.env.ADMIN_SECRET = "s3cret";
    const res = { status: jest.fn().mockReturnThis(), json: jest.fn() };
    await seedCreatorAccountHandler(
      { headers: { authorization: "Bearer wrong" } },
      res
    );
    expect(res.status).toHaveBeenCalledWith(403);
  });

  it("creates the user, profile, claim, and one invite code", async () => {
    process.env.ADMIN_SECRET = "s3cret";
    process.env.CREATOR_EMAIL = "founder@emerge.app";
    process.env.CREATOR_PASSWORD = "hunter2outofband";
    getUserByEmail.mockRejectedValue({ code: "auth/user-not-found" });
    createUser.mockResolvedValue({ uid: "seed-uid" });
    const res = { status: jest.fn().mockReturnThis(), json: jest.fn() };
    await seedCreatorAccountHandler(
      { headers: { authorization: "Bearer s3cret" } },
      res
    );
    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith(
      expect.objectContaining({ ok: true, uid: "seed-uid" })
    );
    expect(setCustomUserClaims).toHaveBeenCalledWith(
      "seed-uid",
      expect.objectContaining({ role: "creator", admin: true })
    );
    expect(docSet).toHaveBeenCalled();
    // Invite code comes from the shared crypto-secure generator
    // (generateCode in creator_invites.ts) — 8 ambiguity-free chars.
    const call = res.json.mock.calls[0][0] as { inviteCode: string };
    expect(call.inviteCode).toMatch(/^[A-Z2-9]{8}$/);
  });

  it("reuses an existing account and rotates its password", async () => {
    process.env.ADMIN_SECRET = "s3cret";
    process.env.CREATOR_EMAIL = "founder@emerge.app";
    process.env.CREATOR_PASSWORD = "rotated";
    getUserByEmail.mockResolvedValue({ uid: "existing-uid" });
    const res = { status: jest.fn().mockReturnThis(), json: jest.fn() };
    await seedCreatorAccountHandler(
      { headers: { authorization: "Bearer s3cret" } },
      res
    );
    expect(updateUser).toHaveBeenCalledWith(
      "existing-uid",
      expect.objectContaining({ password: "rotated" })
    );
    expect(res.json).toHaveBeenCalledWith(
      expect.objectContaining({ ok: true, uid: "existing-uid" })
    );
  });
});
