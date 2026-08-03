/**
 * Tests for repairBlueprintCatalog.ts (offline).
 * Tests the exported inner handler directly with a mocked firebase-admin,
 * mirroring seedCreatorAccount.test.ts.
 */
const batchUpdate = jest.fn();
const batchDelete = jest.fn();
const batchCommit = jest.fn().mockResolvedValue(undefined);
const docGet = jest.fn();

const listDocuments = jest.fn();
const collection = jest.fn((name: string) => ({
  listDocuments,
}));

const firestoreMock = jest.fn(() => ({ collection, batch: () => ({
  update: batchUpdate,
  delete: batchDelete,
  commit: batchCommit,
}) }));

jest.mock("firebase-admin", () => ({
  apps: [],
  initializeApp: jest.fn(),
  firestore: firestoreMock,
}));

// eslint-disable-next-line @typescript-eslint/no-require-imports
const { repairBlueprintCatalogHandler } = require("../src/repairBlueprintCatalog");

function makeRes() {
  const res = {
    statusCode: 0,
    body: null as unknown,
    status(code: number) {
      this.statusCode = code;
      return { json: (body: unknown) => { this.body = body; } };
    },
  };
  return res;
}

function makeReq(token?: string) {
  return { headers: token ? { authorization: `Bearer ${token}` } : {} };
}

describe("repairBlueprintCatalog", () => {
  const OLD_ENV = process.env;

  beforeEach(() => {
    jest.clearAllMocks();
    process.env = { ...OLD_ENV, ADMIN_SECRET: "test-secret" };
    // Default: two seed docs (one wrong owner), one stale doc.
    listDocuments.mockResolvedValue([
      { id: "morning_1", get: jest.fn().mockResolvedValue({ data: () => ({ creatorUserId: "alex_hormozi" }) }) },
      { id: "learning_5", get: jest.fn().mockResolvedValue({ data: () => ({ creatorUserId: "system" }) }) },
      { id: "blueprint_legacy_1", get: jest.fn() },
    ]);
  });

  afterEach(() => {
    process.env = OLD_ENV;
  });

  it("fails closed without ADMIN_SECRET", async () => {
    process.env = { ...OLD_ENV };
    const res = makeRes();
    await repairBlueprintCatalogHandler(makeReq("anything"), res);
    expect(res.statusCode).toBe(500);
  });

  it("rejects a wrong secret", async () => {
    const res = makeRes();
    await repairBlueprintCatalogHandler(makeReq("wrong"), res);
    expect(res.statusCode).toBe(403);
    expect(batchCommit).not.toHaveBeenCalled();
  });

  it("re-owns wrong-owner seeds and purges non-seed docs", async () => {
    const res = makeRes();
    await repairBlueprintCatalogHandler(makeReq("test-secret"), res);
    expect(batchUpdate).toHaveBeenCalledTimes(1);
    expect(batchUpdate).toHaveBeenCalledWith(
      { id: "morning_1", get: expect.any(Function) },
      { creatorUserId: "system" }
    );
    // system-owned seed untouched; stale doc deleted
    expect(batchDelete).toHaveBeenCalledTimes(1);
    expect(batchDelete).toHaveBeenCalledWith({ id: "blueprint_legacy_1", get: expect.any(Function) });
    expect(batchCommit).toHaveBeenCalledTimes(1);
    expect(res.body).toEqual({ ok: true, repaired: 1, purged: 1 });
  });

  it("is a no-op once everything is system-owned and clean", async () => {
    listDocuments.mockResolvedValue([
      { id: "morning_1", get: jest.fn().mockResolvedValue({ data: () => ({ creatorUserId: "system" }) }) },
    ]);
    const res = makeRes();
    await repairBlueprintCatalogHandler(makeReq("test-secret"), res);
    expect(batchUpdate).not.toHaveBeenCalled();
    expect(batchDelete).not.toHaveBeenCalled();
    expect(res.body).toEqual({ ok: true, repaired: 0, purged: 0 });
  });
});
