/**
 * Unit tests for Firebase Cloud Functions (Offline Mode)
 * Run with: cd functions && npm test
 *
 * These tests use firebase-functions-test in offline mode,
 * which does NOT require a service account key file.
 *
 * Note: v2 onCall functions receive a single `request` object
 * with { auth, data } properties, not (data, context) like v1.
 * We call the function's .run() method directly with the request object.
 *
 * Scheduled functions that access Firestore require the emulator
 * and are tested separately in integration tests.
 */

// eslint-disable-next-line @typescript-eslint/no-require-imports
const ft = require("firebase-functions-test")();

describe("Cloud Functions", () => {
  afterAll(() => {
    ft.cleanup();
  });

  describe("getAuraInsight", () => {
    const getAuraInsight =
      // eslint-disable-next-line @typescript-eslint/no-require-imports
      require("../lib/index").getAuraInsight;

    it("should reject unauthenticated requests", async () => {
      await expect(
        getAuraInsight.run({ auth: undefined, data: {} })
      ).rejects.toHaveProperty("code", "unauthenticated");
    });
  });

  describe("getGroqCoachAdvice", () => {
    const getGroqCoachAdvice =
      // eslint-disable-next-line @typescript-eslint/no-require-imports
      require("../lib/index").getGroqCoachAdvice;

    it("should reject unauthenticated requests", async () => {
      await expect(
        getGroqCoachAdvice.run({ auth: undefined, data: { userMessage: "test" } })
      ).rejects.toHaveProperty("code", "unauthenticated");
    });

    it("should reject missing userMessage when authenticated", async () => {
      await expect(
        getGroqCoachAdvice.run({ auth: { uid: "test_user" }, data: {} })
      ).rejects.toHaveProperty("code", "invalid-argument");
    });
  });
});
