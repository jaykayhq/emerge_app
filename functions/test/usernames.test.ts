const updateUser = jest.fn().mockResolvedValue(undefined);
const docGet = jest.fn();
const docSet = jest.fn();
const runTransaction = jest.fn();

const collection = jest.fn((name: string) => ({
  doc: jest.fn((id?: string) => ({
    id: id ?? "auto-1",
    get: jest.fn(() => docGet(name, id)),
    set: docSet,
  })),
}));

const firestoreMock = jest.fn(() => ({ collection, runTransaction }));
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
  auth: () => ({ updateUser }),
}));

// eslint-disable-next-line @typescript-eslint/no-require-imports
const ft = require("firebase-functions-test")();

// eslint-disable-next-line @typescript-eslint/no-require-imports
const { claimUsername, validateUsername } = require("../src/usernames");

beforeEach(() => {
  jest.clearAllMocks();
  docGet.mockImplementation((name: string, id: string) =>
    Promise.resolve({ exists: false, data: () => null })
  );
});

describe("validateUsername", () => {
  it("requires a non-empty value", () => {
    expect(validateUsername("")).toBe("Username is required");
    expect(validateUsername("   ")).toBe("Username is required");
    expect(validateUsername(null)).toBe("Username is required");
    expect(validateUsername(undefined)).toBe("Username is required");
  });
});

describe("claimUsername", () => {
  it("rejects unauthenticated calls", async () => {
    await expect(
      claimUsername.run({ auth: undefined, data: { username: "Aria" } })
    ).rejects.toHaveProperty("code", "unauthenticated");
  });

  it("rejects invalid usernames", async () => {
    await expect(
      claimUsername.run({ auth: { uid: "u1", token: {} }, data: { username: "ab" } })
    ).rejects.toHaveProperty("code", "invalid-argument");
    await expect(
      claimUsername.run({ auth: { uid: "u1", token: {} }, data: { username: "bad name!" } })
    ).rejects.toHaveProperty("code", "invalid-argument");
    await expect(
      claimUsername.run({ auth: { uid: "u1", token: {} }, data: { username: "admin" } })
    ).rejects.toHaveProperty("code", "invalid-argument");
  });

  it("normalizes case and claims the username", async () => {
    runTransaction.mockImplementation(async (cb: (tx: unknown) => Promise<void>) => {
      const tx = {
        get: () => Promise.resolve({ exists: false, data: () => null }),
        set: docSet,
      };
      await cb(tx);
    });

    await claimUsername.run({
      auth: { uid: "u1", token: {} },
      data: { username: "  Aria_Star " },
    });

    expect(runTransaction).toHaveBeenCalled();
    const [, data] = docSet.mock.calls[0];
    expect(data).toMatchObject({ uid: "u1" });
    expect(updateUser).toHaveBeenCalledWith("u1", { displayName: "Aria_Star" });
  });

  it("still returns ok when the auth displayName update fails", async () => {
    runTransaction.mockImplementation(async (cb: (tx: unknown) => Promise<void>) => {
      const tx = {
        get: () => Promise.resolve({ exists: false, data: () => null }),
        set: docSet,
      };
      await cb(tx);
    });
    updateUser.mockRejectedValueOnce(new Error("Auth API down"));

    const res = await claimUsername.run({
      auth: { uid: "u1", token: {} },
      data: { username: "Aria_Star" },
    });

    expect(res).toEqual({ ok: true, username: "Aria_Star" });
    expect(updateUser).toHaveBeenCalledTimes(1);
  });

  it("rejects when the username is taken by someone else", async () => {
    runTransaction.mockImplementation(async (cb: (tx: unknown) => Promise<void>) => {
      const tx = {
        get: () => Promise.resolve({ exists: true, data: () => ({ uid: "other" }) }),
        set: docSet,
      };
      await cb(tx);
    });
    await expect(
      claimUsername.run({ auth: { uid: "u1", token: {} }, data: { username: "Aria_Star" } })
    ).rejects.toHaveProperty("code", "already-exists");
  });

  it("succeeds idempotently when the caller already owns the username", async () => {
    runTransaction.mockImplementation(async (cb: (tx: unknown) => Promise<void>) => {
      const tx = {
        get: () => Promise.resolve({ exists: true, data: () => ({ uid: "u1" }) }),
        set: docSet,
      };
      await cb(tx);
    });

    const res = await claimUsername.run({
      auth: { uid: "u1", token: {} },
      data: { username: "Aria_Star" },
    });

    expect(res).toEqual({ ok: true, username: "Aria_Star" });
    expect(updateUser).toHaveBeenCalledWith("u1", { displayName: "Aria_Star" });
  });
});
