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

    it("allows when users/{uid}.isPremium is true (Paystack path)", async () => {
        mockStore["users/u2"] = { isPremium: true };

        const result = await generateAiRecap.run({ auth: { uid: "u2" }, data: {} } as any);

        expect(result).toBeDefined();
        expect(result).toEqual({ success: false, reason: "no_habits" });
    });

    it("allows when users/{uid}.subscriptionStatus is 'active' (RevenueCat path)", async () => {
        mockStore["users/u3"] = { subscriptionStatus: "active" };

        const result = await generateAiRecap.run({ auth: { uid: "u3" }, data: {} } as any);

        expect(result).toBeDefined();
        expect(result).toEqual({ success: false, reason: "no_habits" });
    });
});
