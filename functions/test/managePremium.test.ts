/**
 * Tests for managePremium.ts — offline mode (no emulator).
 * Run with: cd functions && npm run build && npx jest test/managePremium.test.ts
 *
 * NOTE: the firebase-admin mock MUST be registered before
 * firebase-functions-test loads (it imports firebase-admin at require time).
 */
const setCustomUserClaims = jest.fn().mockResolvedValue(undefined);
const getUser = jest.fn();
const docSet = jest.fn();
const docGet = jest.fn();
const collection = jest.fn((name: string) => ({
  doc: jest.fn((id?: string) => ({
    id: id ?? "auto-1",
    get: jest.fn(() => docGet(name, id)),
    set: docSet,
  })),
}));

const firestoreMock = jest.fn(() => ({ collection }));
(
  firestoreMock as unknown as {
    FieldValue: { serverTimestamp: () => string };
    Timestamp: { fromDate: (d: Date) => Date };
  }
).FieldValue = { serverTimestamp: () => "SERVER_TIMESTAMP" };
(
  firestoreMock as unknown as {
    Timestamp: { fromDate: (d: Date) => Date };
  }
).Timestamp = { fromDate: (d: Date) => d };

jest.mock("firebase-admin", () => ({
  apps: [],
  initializeApp: jest.fn(),
  firestore: firestoreMock,
  auth: () => ({ getUser, setCustomUserClaims }),
}));

// eslint-disable-next-line @typescript-eslint/no-require-imports
const ft = require("firebase-functions-test")();

// eslint-disable-next-line @typescript-eslint/no-require-imports
const { managePremium } = require("../src/managePremium");

beforeEach(() => {
  jest.clearAllMocks();
  getUser.mockResolvedValue({
    customClaims: { role: "user", activeEntitlements: ["premium"] },
  });
  docGet.mockResolvedValue({ exists: true, data: () => ({ isPremium: true }) });
});

describe("managePremium", () => {
  it("rejects unauthenticated calls", async () => {
    await expect(
      managePremium.run({ auth: undefined, data: { action: "cancel" } })
    ).rejects.toHaveProperty("code", "unauthenticated");
  });

  it("rejects invalid action values", async () => {
    await expect(
      managePremium.run({ auth: { uid: "u1" }, data: { action: "refund" } })
    ).rejects.toHaveProperty("code", "invalid-argument");
  });

  it("cancel writes isPremium=false and removes the premium claim (merge-safe)", async () => {
    const result = await managePremium.run({
      auth: { uid: "u1" },
      data: { action: "cancel" },
    });

    expect(result).toEqual({ ok: true, action: "cancel", premium: false });
    expect(docSet).toHaveBeenCalledWith(
      {
        isPremium: false,
        subscriptionStatus: "cancelled",
        cancelledAt: "SERVER_TIMESTAMP",
      },
      { merge: true }
    );
    expect(setCustomUserClaims).toHaveBeenCalledWith("u1", {
      role: "user",
      activeEntitlements: [],
    });
  });

  it("cancel preserves unrelated claims", async () => {
    getUser.mockResolvedValue({
      customClaims: { role: "user", activeEntitlements: ["premium"], other: 1 },
    });
    await managePremium.run({
      auth: { uid: "u1" },
      data: { action: "cancel" },
    });
    expect(setCustomUserClaims).toHaveBeenCalledWith("u1", {
      role: "user",
      activeEntitlements: [],
      other: 1,
    });
  });

  it("pause writes paused status + 30-day end, leaves claims untouched", async () => {
    const result = await managePremium.run({
      auth: { uid: "u1" },
      data: { action: "pause" },
    });

    expect(result).toEqual({ ok: true, action: "pause", premium: true });
    const call = docSet.mock.calls[0][0];
    expect(call.subscriptionStatus).toBe("paused");
    expect(call.isPremium).toBeUndefined();
    expect(call.premiumEndsAt).toBeInstanceOf(Date);
    expect(setCustomUserClaims).not.toHaveBeenCalled();
  });

  it("cancel is idempotent — a second call succeeds identically", async () => {
    docGet.mockResolvedValue({
      exists: true,
      data: () => ({ isPremium: false, subscriptionStatus: "cancelled" }),
    });
    const first = await managePremium.run({
      auth: { uid: "u1" },
      data: { action: "cancel" },
    });
    const second = await managePremium.run({
      auth: { uid: "u1" },
      data: { action: "cancel" },
    });
    expect(first).toEqual({ ok: true, action: "cancel", premium: false });
    expect(second).toEqual(first);
  });
});
