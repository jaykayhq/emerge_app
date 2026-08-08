const axiosPost = jest.fn().mockResolvedValue({ status: 200 });
jest.mock("axios", () => ({ post: (...args: unknown[]) => axiosPost(...args) }));

// firebase-functions-test's makeDocumentSnapshot must return a real admin
// DocumentSnapshot (the event generator checks instanceof), so firebase-admin
// is used unmocked — offline snapshot construction makes no network calls.
// eslint-disable-next-line @typescript-eslint/no-require-imports
const ft = require("firebase-functions-test")();

// eslint-disable-next-line @typescript-eslint/no-require-imports
const { sendWelcomeEmail } = require("../src/marketing_email");

beforeEach(() => {
  jest.clearAllMocks();
  process.env.RESEND_API_KEY = "re_test_123";
});

describe("sendWelcomeEmail", () => {
  it("sends a welcome email for a valid new user", async () => {
    const wrapped = ft.wrap(sendWelcomeEmail);
    await wrapped(
      {
        params: { uid: "u1" },
        data: ft.firestore.makeDocumentSnapshot(
          { email: "a@b.com", displayName: "Aria" },
          "users/u1"
        ),
      }
    );
    expect(axiosPost).toHaveBeenCalledTimes(1);
    const [, body] = axiosPost.mock.calls[0];
    expect(body.to).toBe("a@b.com");
    expect(body.subject).toContain("Welcome to Emerge");
  });

  it("skips users without a valid email", async () => {
    const wrapped = ft.wrap(sendWelcomeEmail);
    await wrapped(
      {
        params: { uid: "u2" },
        data: ft.firestore.makeDocumentSnapshot(
          { email: "", displayName: "NoEmail" },
          "users/u2"
        ),
      }
    );
    expect(axiosPost).not.toHaveBeenCalled();
  });

  it("skips system/seed creator docs", async () => {
    const wrapped = ft.wrap(sendWelcomeEmail);
    await wrapped(
      {
        params: { uid: "system" },
        data: ft.firestore.makeDocumentSnapshot(
          { email: "system@emerge.app", creatorUserId: "system" },
          "users/system"
        ),
      }
    );
    expect(axiosPost).not.toHaveBeenCalled();
  });

  it("swallows send failures without throwing", async () => {
    axiosPost.mockRejectedValueOnce(new Error("500 down"));
    const wrapped = ft.wrap(sendWelcomeEmail);
    await expect(
      wrapped({
        params: { uid: "u3" },
        data: ft.firestore.makeDocumentSnapshot(
          { email: "c@d.com", displayName: "C" },
          "users/u3"
        ),
      })
    ).resolves.toBeUndefined();
  });
});

// ---- Re-engagement drip --------------------------------------------------------

// eslint-disable-next-line @typescript-eslint/no-require-imports
const { enforceReengagementDripInternal } = require("../src/marketing_email");

const queryGet = jest.fn();
const batchSet = jest.fn();
const batchCommit = jest.fn().mockResolvedValue(undefined);
const batch = jest.fn(() => ({ set: batchSet, commit: batchCommit }));

interface QueryMock {
  get: jest.Mock;
  limit: jest.Mock;
  startAfter: jest.Mock;
}

const makeQuery = (): QueryMock => ({
  get: queryGet,
  limit: jest.fn(() => makeQuery()),
  startAfter: jest.fn(() => makeQuery()),
});

const firestoreMock = () => ({
  collection: jest.fn(() => ({
    where: jest.fn(() => makeQuery()),
    doc: jest.fn((id: string) => ({ id })),
  })),
  batch,
});

function makeDoc(id: string, data: Record<string, unknown>) {
  return { id, data: () => data };
}

describe("enforceReengagementDripInternal", () => {
  const nowMs = Date.now();

  beforeEach(() => {
    queryGet.mockReset();
    queryGet.mockResolvedValue({ size: 0, empty: true, docs: [] });
    batchSet.mockClear();
    batchCommit.mockClear();
    process.env.RESEND_API_KEY = "re_test_123";
  });

  it("sends and marks users past the drip age who are active and not yet dripped", async () => {
    queryGet.mockResolvedValue({
      size: 1,
      empty: false,
      docs: [makeDoc("u1", {
        email: "a@b.com",
        displayName: "Aria",
        createdAt: new Date(nowMs - 4 * 86400_000),
        lastActivity: new Date(nowMs - 2 * 86400_000),
      })],
    });
    await enforceReengagementDripInternal(firestoreMock(), nowMs);
    expect(axiosPost).toHaveBeenCalledTimes(1);
    const [, body] = axiosPost.mock.calls[0];
    expect(body.to).toBe("a@b.com");
    expect(body.subject).toContain("We miss you");
    expect(batchSet).toHaveBeenCalledWith(
      expect.objectContaining({ id: "u1" }),
      expect.objectContaining({ reengagementEmailSentAt: expect.anything() }),
      { merge: true }
    );
    expect(batchCommit).toHaveBeenCalled();
  });

  it("skips users already dripped", async () => {
    queryGet.mockResolvedValue({
      size: 1,
      empty: false,
      docs: [makeDoc("u1", {
        email: "a@b.com",
        reengagementEmailSentAt: "SERVER_TIMESTAMP",
        lastActivity: new Date(nowMs - 2 * 86400_000),
      })],
    });
    await enforceReengagementDripInternal(firestoreMock(), nowMs);
    expect(axiosPost).not.toHaveBeenCalled();
    expect(batchSet).not.toHaveBeenCalled();
  });

  it("skips users who churned (last activity older than 7 days)", async () => {
    queryGet.mockResolvedValue({
      size: 1,
      empty: false,
      docs: [makeDoc("u1", {
        email: "a@b.com",
        createdAt: new Date(nowMs - 10 * 86400_000),
        lastActivity: new Date(nowMs - 8 * 86400_000),
      })],
    });
    await enforceReengagementDripInternal(firestoreMock(), nowMs);
    expect(axiosPost).not.toHaveBeenCalled();
  });

  it("skips users with no valid email", async () => {
    queryGet.mockResolvedValue({
      size: 1,
      empty: false,
      docs: [makeDoc("u1", {
        email: "",
        lastActivity: new Date(nowMs - 2 * 86400_000),
      })],
    });
    await enforceReengagementDripInternal(firestoreMock(), nowMs);
    expect(axiosPost).not.toHaveBeenCalled();
  });

  it("does not mark users whose send failed", async () => {
    axiosPost.mockRejectedValueOnce(new Error("500"));
    queryGet.mockResolvedValue({
      size: 1,
      empty: false,
      docs: [makeDoc("u1", {
        email: "a@b.com",
        createdAt: new Date(nowMs - 4 * 86400_000),
        lastActivity: new Date(nowMs - 2 * 86400_000),
      })],
    });
    await enforceReengagementDripInternal(firestoreMock(), nowMs);
    expect(batchSet).not.toHaveBeenCalled();
    expect(batchCommit).not.toHaveBeenCalled();
  });
});
