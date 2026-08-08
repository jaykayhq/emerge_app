/**
 * Offline tests for email_verification.ts.
 * Run with: cd functions && npm run build && npx jest test/email_verification.test.ts
 */
// Stub axios (same pattern as email.test.ts) so sendEmail resolves offline;
// the failed-send test below rejects a single call to prove the code doc is
// cleaned up when delivery fails.
const axiosPost = jest.fn().mockResolvedValue({ status: 200 });
jest.mock("axios", () => ({
  post: (...args: unknown[]) => axiosPost(...args),
}));

const updateUser = jest.fn().mockResolvedValue(undefined);
const getUser = jest.fn();
const docGet = jest.fn();
const docSet = jest.fn();
const docUpdate = jest.fn();
const docDelete = jest.fn();
const queryGet = jest.fn();
const runTransaction = jest.fn();
const batchSet = jest.fn();
const batchCommit = jest.fn().mockResolvedValue(undefined);
const batch = jest.fn(() => ({ set: batchSet, commit: batchCommit }));

const collection = jest.fn((name: string) => ({
  doc: jest.fn((id?: string) => ({
    id: id ?? "auto-1",
    get: jest.fn(() => docGet(name, id)),
    set: docSet,
    update: docUpdate,
    delete: docDelete,
  })),
  where: jest.fn(() => ({
    where: jest.fn(() => ({
      get: queryGet,
      limit: jest.fn(() => ({
        get: queryGet,
        startAfter: jest.fn(() => ({ get: queryGet })),
      })),
    })),
    limit: jest.fn(() => ({
      get: queryGet,
      startAfter: jest.fn(() => ({ get: queryGet })),
    })),
    get: queryGet,
  })),
}));

const firestoreMock = jest.fn(() => ({ collection, runTransaction, batch }));
(
  firestoreMock as unknown as {
    FieldValue: {
      serverTimestamp: () => string;
      delete: () => string;
      increment: (n: number) => { __increment: number };
    };
    Timestamp: { fromDate: (d: Date) => Date; now: () => Date };
  }
).FieldValue = {
  serverTimestamp: () => "SERVER_TIMESTAMP",
  delete: () => "FIELD_DELETE",
  increment: (n: number) => ({ __increment: n }),
};
(
  firestoreMock as unknown as {
    Timestamp: { fromDate: (d: Date) => Date; now: () => Date };
  }
).Timestamp = { fromDate: (d: Date) => d, now: () => new Date() };

jest.mock("firebase-admin", () => ({
  apps: [],
  initializeApp: jest.fn(),
  firestore: firestoreMock,
  auth: () => ({ getUser, updateUser }),
}));

// eslint-disable-next-line @typescript-eslint/no-require-imports
const ft = require("firebase-functions-test")();

// eslint-disable-next-line @typescript-eslint/no-require-imports
const {
  sendEmailVerificationCode,
  verifyEmailCode,
  enforceEmailGracePeriodInternal,
  hashCodeForTest,
} = require("../src/email_verification");

beforeEach(() => {
  jest.clearAllMocks();
  process.env.RESEND_API_KEY = "re_test_123";
  docGet.mockImplementation((name: string, id: string) =>
    Promise.resolve({ exists: false, data: () => null })
  );
  queryGet.mockResolvedValue({ size: 0, empty: true, docs: [], forEach: jest.fn() });
});

describe("sendEmailVerificationCode", () => {
  it("rejects unauthenticated calls", async () => {
    await expect(
      sendEmailVerificationCode.run({ auth: undefined, data: {} })
    ).rejects.toHaveProperty("code", "unauthenticated");
  });

  it("rejects when over the hourly resend limit", async () => {
    getUser.mockResolvedValue({ email: "a@b.com", emailVerified: false });
    docGet.mockImplementation((name: string, id: string) =>
      Promise.resolve({
        exists: true,
        data: () => ({
          resendCount: 5,
          lastSentAt: new Date(Date.now() - 60_000),
          attempts: 0,
        }),
      })
    );
    await expect(
      sendEmailVerificationCode.run({
        auth: { uid: "u1", token: {} },
        data: {},
      })
    ).rejects.toHaveProperty("code", "resource-exhausted");
  });

  it("writes a hashed code doc with TTL and returns ok", async () => {
    getUser.mockResolvedValue({ email: "a@b.com", emailVerified: false });
    const res = await sendEmailVerificationCode.run({
      auth: { uid: "u1", token: {} },
      data: {},
    });
    expect(res).toMatchObject({ ok: true });
    expect(docSet).toHaveBeenCalledTimes(1);
    const [data] = docSet.mock.calls[0];
    expect(data.codeHash).toBeDefined();
    expect(data.codeHash).not.toContain(data.codeSalt);
    expect(typeof data.codeHash).toBe("string");
    expect(data.expiresAt).toBeInstanceOf(Date);
    expect(data.attempts).toBe(0);
    // resendCount is bumped atomically so concurrent sends can't clobber it.
    expect(data.resendCount).toEqual({ __increment: 1 });
  });

  it("rejects when over the daily-window resend limit", async () => {
    getUser.mockResolvedValue({ email: "a@b.com", emailVerified: false });
    docGet.mockImplementation((name: string, id: string) =>
      Promise.resolve({
        exists: true,
        data: () => ({
          resendCount: 20,
          lastSentAt: new Date(Date.now() - 60_000),
          attempts: 0,
        }),
      })
    );
    await expect(
      sendEmailVerificationCode.run({
        auth: { uid: "u1", token: {} },
        data: {},
      })
    ).rejects.toHaveProperty("code", "resource-exhausted");
  });

  it("allows a resend once the last send is older than the day window", async () => {
    getUser.mockResolvedValue({ email: "a@b.com", emailVerified: false });
    // resendCount is a lifetime accumulator; the day window is bounded by
    // lastSentAt, so 20 lifetime sends with the last one > 24h ago pass.
    docGet.mockImplementation((name: string, id: string) =>
      Promise.resolve({
        exists: true,
        data: () => ({
          resendCount: 20,
          lastSentAt: new Date(Date.now() - 2 * 86400_000),
          attempts: 0,
        }),
      })
    );
    const res = await sendEmailVerificationCode.run({
      auth: { uid: "u1", token: {} },
      data: {},
    });
    expect(res).toMatchObject({ ok: true });
  });

  it("rejects when the email is already verified", async () => {
    getUser.mockResolvedValue({ email: "a@b.com", emailVerified: true });
    await expect(
      sendEmailVerificationCode.run({
        auth: { uid: "u1", token: {} },
        data: {},
      })
    ).rejects.toHaveProperty("code", "already-exists");
  });

  it("deletes the code doc and fails when the email cannot be sent", async () => {
    getUser.mockResolvedValue({ email: "a@b.com", emailVerified: false });
    axiosPost.mockRejectedValueOnce(new Error("Resend down"));
    await expect(
      sendEmailVerificationCode.run({
        auth: { uid: "u1", token: {} },
        data: {},
      })
    ).rejects.toHaveProperty("code", "internal");
    expect(docDelete).toHaveBeenCalledTimes(1);
  });
});

describe("verifyEmailCode", () => {
  it("rejects unauthenticated calls", async () => {
    await expect(
      verifyEmailCode.run({ auth: undefined, data: { code: "123456" } })
    ).rejects.toHaveProperty("code", "unauthenticated");
  });

  it("rejects a malformed code", async () => {
    await expect(
      verifyEmailCode.run({ auth: { uid: "u1", token: {} }, data: { code: "ab12" } })
    ).rejects.toHaveProperty("code", "invalid-argument");
  });

  it("sets emailVerified, mirrors users/{uid}, and consumes the code", async () => {
    const salt = "test-salt-0123456789abcdef";
    const code = "123456";
    const expectedHash = hashCodeForTest(code, salt);
    docGet.mockImplementation((name: string, id: string) =>
      Promise.resolve({
        exists: true,
        data: () => ({
          codeHash: expectedHash,
          codeSalt: salt,
          expiresAt: new Date(Date.now() + 60_000),
          attempts: 0,
          resendCount: 1,
        }),
      })
    );
    getUser.mockResolvedValue({ email: "a@b.com", emailVerified: false });

    const res = await verifyEmailCode.run({
      auth: { uid: "u1", token: {} },
      data: { code },
    });
    expect(res).toMatchObject({ ok: true });
    expect(updateUser).toHaveBeenCalledWith("u1", { emailVerified: true });
    expect(docDelete).toHaveBeenCalled();
  });

  it("rejects an expired code", async () => {
    docGet.mockResolvedValue({
      exists: true,
      data: () => ({
        codeHash: "x",
        codeSalt: "y",
        expiresAt: new Date(Date.now() - 1000),
        attempts: 0,
        resendCount: 1,
      }),
    });
    await expect(
      verifyEmailCode.run({ auth: { uid: "u1", token: {} }, data: { code: "123456" } })
    ).rejects.toHaveProperty("code", "failed-precondition");
  });

  it("rejects a wrong code and increments attempts atomically", async () => {
    docGet.mockResolvedValue({
      exists: true,
      data: () => ({
        codeHash: hashCodeForTest("999999", "salt"),
        codeSalt: "salt",
        expiresAt: new Date(Date.now() + 60_000),
        attempts: 0,
        resendCount: 1,
      }),
    });
    await expect(
      verifyEmailCode.run({ auth: { uid: "u1", token: {} }, data: { code: "111111" } })
    ).rejects.toHaveProperty("code", "invalid-argument");
    // The attempt counter is bumped atomically via update(), so concurrent
    // wrong guesses can't both write the same N+1.
    expect(docUpdate).toHaveBeenCalledWith({
      attempts: { __increment: 1 },
    });
  });

  it("rejects once the max attempt count is reached", async () => {
    docGet.mockResolvedValue({
      exists: true,
      data: () => ({
        codeHash: "x",
        codeSalt: "y",
        expiresAt: new Date(Date.now() + 60_000),
        attempts: 5,
        resendCount: 1,
      }),
    });
    await expect(
      verifyEmailCode.run({ auth: { uid: "u1", token: {} }, data: { code: "123456" } })
    ).rejects.toHaveProperty("code", "resource-exhausted");
  });
});

describe("enforceEmailGracePeriodInternal", () => {
  // The injected database must be the firestoreMock() instance so that
  // database.batch() (the paginated batch seam) resolves to the shared mock.
  const database = firestoreMock() as never;

  it("locks unverified users older than the grace period", async () => {
    queryGet.mockResolvedValue({
      size: 1,
      empty: false,
      docs: [
        {
          id: "u1",
          data: () => ({ createdAt: new Date(Date.now() - 8 * 86400_000) }),
        },
      ],
      forEach: jest.fn(),
    });
    await enforceEmailGracePeriodInternal(database, Date.now());
    expect(batch).toHaveBeenCalled();
    expect(batchSet).toHaveBeenCalled();
    expect(batchCommit).toHaveBeenCalled();
  });

  it("skips verified users", async () => {
    queryGet.mockResolvedValue({
      size: 1,
      empty: false,
      docs: [
        {
          id: "u1",
          data: () => ({ createdAt: new Date(Date.now() - 8 * 86400_000), emailVerified: true }),
        },
      ],
      forEach: jest.fn(),
    });
    await enforceEmailGracePeriodInternal(database, Date.now());
    expect(batchSet).not.toHaveBeenCalled();
    expect(batchCommit).not.toHaveBeenCalled();
  });
});
