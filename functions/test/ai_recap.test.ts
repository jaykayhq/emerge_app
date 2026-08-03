import { generateAiRecap } from "../src/ai_recap";

// In-memory Firestore fake seeded per test. Mirrors paystack.test.ts's
// offline mocking style: jest.mock("firebase-admin"), no emulator.
// Path-keyed store so each read resolves to whatever the test seeded.
const mockStore: Record<string, any> = {};

jest.mock("firebase-admin", () => {
    let currentPath = "";

    const chain: any = {
        collection: jest.fn((name: string) => {
            currentPath = currentPath ? `${currentPath}/${name}` : name;
            return chain;
        }),
        doc: jest.fn((id: string) => {
            currentPath = `${currentPath}/${id}`;
            return chain;
        }),
        where: jest.fn(() => chain),
        get: jest.fn(async () => {
            const path = currentPath;
            currentPath = "";
            return {
                data: () => mockStore[path],
                exists: mockStore[path] !== undefined,
                empty: true,
                size: 0,
                docs: [],
            };
        }),
        set: jest.fn(async (data: any) => {
            mockStore[currentPath] = data;
            currentPath = "";
            return true;
        }),
        update: jest.fn(async (data: any) => {
            mockStore[currentPath] = { ...mockStore[currentPath], ...data };
            currentPath = "";
            return true;
        }),
    };

    const firestoreMock: any = jest.fn(() => chain);
    firestoreMock.FieldValue = { serverTimestamp: jest.fn(() => "mockTimestamp") };
    firestoreMock.Timestamp = { fromDate: jest.fn(() => "mockTimestamp") };

    return {
        apps: [],
        initializeApp: jest.fn(),
        firestore: firestoreMock,
    };
});

describe("generateAiRecap premium gate (SP-H-3)", () => {
    beforeEach(() => {
        Object.keys(mockStore).forEach((key) => delete mockStore[key]);
    });

    it("denies when users/{uid}.isPremium is not set", async () => {
        mockStore["users/u1"] = { displayName: "Test User" };

        await expect(
            generateAiRecap.run({ auth: { uid: "u1" }, data: {} } as any)
        ).rejects.toHaveProperty("code", "permission-denied");
    });

    it("denies when only subscriptionStatus is active but isPremium is not set (client parity, Fix 9)", async () => {
        mockStore["users/u1"] = { subscriptionStatus: "active" };

        await expect(
            generateAiRecap.run({ auth: { uid: "u1" }, data: {} } as any)
        ).rejects.toHaveProperty("code", "permission-denied");
    });

    it("allows when users/{uid}.isPremium is true (Paystack path)", async () => {
        mockStore["users/u2"] = { isPremium: true };

        const result = await generateAiRecap.run({ auth: { uid: "u2" }, data: {} } as any);

        expect(result).toBeDefined();
        expect(result).toEqual({ success: false, reason: "no_habits" });
    });

    it("allows when users/{uid}.isPremium is true and subscriptionStatus is 'active' (RevenueCat path)", async () => {
        mockStore["users/u3"] = { isPremium: true, subscriptionStatus: "active" };

        const result = await generateAiRecap.run({ auth: { uid: "u3" }, data: {} } as any);

        expect(result).toBeDefined();
        expect(result).toEqual({ success: false, reason: "no_habits" });
    });

    it("denies a paused-and-expired web user whose isPremium is still true (Fix 9)", async () => {
        // Paystack wrote isPremium: true; managePremium paused it with a
        // premiumEndsAt that has since passed — the client's
        // computePremiumState shows free, so the callable must too.
        mockStore["users/u4"] = {
            isPremium: true,
            subscriptionStatus: "paused",
            premiumEndsAt: new Date(Date.now() - 1000),
        };

        await expect(
            generateAiRecap.run({ auth: { uid: "u4" }, data: {} } as any)
        ).rejects.toHaveProperty("code", "permission-denied");
    });

    it("allows a paused user whose premiumEndsAt is still in the future (Fix 9)", async () => {
        mockStore["users/u5"] = {
            isPremium: true,
            subscriptionStatus: "paused",
            premiumEndsAt: new Date(Date.now() + 24 * 60 * 60 * 1000),
        };

        const result = await generateAiRecap.run({ auth: { uid: "u5" }, data: {} } as any);

        expect(result).toBeDefined();
        expect(result).toEqual({ success: false, reason: "no_habits" });
    });

    it("allows a paused user with no premiumEndsAt (client parity, Fix 9)", async () => {
        mockStore["users/u6"] = { isPremium: true, subscriptionStatus: "paused" };

        const result = await generateAiRecap.run({ auth: { uid: "u6" }, data: {} } as any);

        expect(result).toBeDefined();
        expect(result).toEqual({ success: false, reason: "no_habits" });
    });
});
