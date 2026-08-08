/**
 * Offline tests for email_verification.ts (grace-period lock only).
 * Run with: cd functions && npm run build && npx jest \
 * test/email_verification.test.ts
 */
const queryGet = jest.fn();
const batchSet = jest.fn();
const batchCommit = jest.fn().mockResolvedValue(undefined);
const batch = jest.fn(() => ({ set: batchSet, commit: batchCommit }));

const limit = jest.fn();
const startAfter = jest.fn();
const makeQuery = (): {
  get: jest.Mock;
  limit: jest.Mock;
  startAfter: jest.Mock;
} => ({ get: queryGet, limit, startAfter });
limit.mockImplementation(() => makeQuery());
startAfter.mockImplementation(() => makeQuery());

const collection = jest.fn((name: string) => ({
  doc: jest.fn((id?: string) => ({ id: id ?? "auto-1" })),
  where: jest.fn(() => makeQuery()),
}));

const firestoreMock = jest.fn(() => ({ collection, batch }));
(firestoreMock as unknown as { FieldValue: { serverTimestamp: () => string } })
  .FieldValue = {
  serverTimestamp: () => "SERVER_TIMESTAMP",
};

jest.mock("firebase-admin", () => ({
  apps: [],
  initializeApp: jest.fn(),
  firestore: firestoreMock,
}));

// eslint-disable-next-line @typescript-eslint/no-require-imports
const ft = require("firebase-functions-test")();

// eslint-disable-next-line @typescript-eslint/no-require-imports
const { enforceEmailGracePeriodInternal } = require(
  "../src/email_verification"
);

const GRACE_PAGE_SIZE = 400;

const makeDoc = (id: string, data: Record<string, unknown>) => ({
  id,
  data: () => data,
});

const unverifiedOld = () =>
  makeDoc("u1", { createdAt: new Date(Date.now() - 8 * 86400_000) });

beforeEach(() => {
  jest.clearAllMocks();
  queryGet.mockResolvedValue({ size: 0, empty: true, docs: [] });
});

describe("enforceEmailGracePeriodInternal", () => {
  // The injected database must be the firestoreMock() instance so that
  // database.batch() (the paginated batch seam) resolves to the shared mock.
  const database = firestoreMock() as never;

  it("locks unverified users older than the grace period", async () => {
    queryGet.mockResolvedValue({
      size: 1,
      empty: false,
      docs: [unverifiedOld()],
    });
    await enforceEmailGracePeriodInternal(database, Date.now());
    expect(batch).toHaveBeenCalled();
    expect(batchSet).toHaveBeenCalledWith(
      expect.objectContaining({ id: "u1" }),
      { emailLockedAt: "SERVER_TIMESTAMP" },
      { merge: true }
    );
    expect(batchCommit).toHaveBeenCalled();
  });

  it("skips verified users", async () => {
    queryGet.mockResolvedValue({
      size: 1,
      empty: false,
      docs: [
        makeDoc("u1", {
          createdAt: new Date(Date.now() - 8 * 86400_000),
          emailVerified: true,
        }),
      ],
    });
    await enforceEmailGracePeriodInternal(database, Date.now());
    expect(batchSet).not.toHaveBeenCalled();
    expect(batchCommit).not.toHaveBeenCalled();
  });

  it("skips users already locked", async () => {
    queryGet.mockResolvedValue({
      size: 1,
      empty: false,
      docs: [
        makeDoc("u1", {
          createdAt: new Date(Date.now() - 8 * 86400_000),
          emailLockedAt: "SERVER_TIMESTAMP",
        }),
      ],
    });
    await enforceEmailGracePeriodInternal(database, Date.now());
    expect(batchSet).not.toHaveBeenCalled();
    expect(batchCommit).not.toHaveBeenCalled();
  });

  it("pages through full pages via limit and startAfter", async () => {
    const firstPage = Array.from({ length: GRACE_PAGE_SIZE }, (_, i) =>
      makeDoc(`u${i}`, { createdAt: new Date(Date.now() - 8 * 86400_000) })
    );
    queryGet
      .mockResolvedValueOnce({
        size: GRACE_PAGE_SIZE,
        empty: false,
        docs: firstPage,
      })
      .mockResolvedValueOnce({
        size: 1,
        empty: false,
        docs: [unverifiedOld()],
      });
    await enforceEmailGracePeriodInternal(database, Date.now());
    expect(queryGet).toHaveBeenCalledTimes(2);
    expect(limit).toHaveBeenCalledWith(GRACE_PAGE_SIZE);
    expect(startAfter).toHaveBeenCalled();
    expect(batchCommit).toHaveBeenCalledTimes(2);
  });

  it("stops when a page comes back short", async () => {
    queryGet.mockResolvedValue({
      size: 1,
      empty: false,
      docs: [unverifiedOld()],
    });
    await enforceEmailGracePeriodInternal(database, Date.now());
    expect(queryGet).toHaveBeenCalledTimes(1);
  });
});
