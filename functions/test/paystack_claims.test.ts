import * as admin from "firebase-admin";
import { paystackWebhook } from "../src/payments/paystack";
import * as crypto from "crypto";

jest.mock("firebase-admin", () => {
    const firestoreMock = {
        collection: jest.fn().mockReturnThis(),
        doc: jest.fn().mockReturnThis(),
        set: jest.fn().mockResolvedValue(true),
        get: jest.fn().mockResolvedValue({ exists: false }),
    };
    const firestore = jest.fn(() => firestoreMock);
    (firestore as any).FieldValue = {
        serverTimestamp: jest.fn(() => "mockTimestamp"),
    };
    // Singleton: the handler and the test must observe the same mocks
    const authMock = {
        getUser: jest.fn().mockResolvedValue({ customClaims: {} }),
        setCustomUserClaims: jest.fn().mockResolvedValue(true),
    };
    return {
        apps: [],
        initializeApp: jest.fn(),
        firestore,
        auth: jest.fn(() => authMock),
        FieldValue: (firestore as any).FieldValue,
    };
});

describe("Paystack Webhook claim sync (SP-H)", () => {
    const mockSecret = "sk_test_mockkey";
    process.env.PAYSTACK_SECRET_KEY = mockSecret;

    beforeEach(() => {
        const auth = admin.auth() as any;
        auth.getUser.mockReset().mockResolvedValue({ customClaims: {} });
        auth.setCustomUserClaims.mockReset().mockResolvedValue(true);
        const firestore = admin.firestore() as any;
        firestore.get.mockReset().mockResolvedValue({ exists: false });
    });

    function signedRequest(reference: string, uid = "test_uid") {
        const body = {
            event: "charge.success",
            id: `evt_${reference}`,
            data: {
                reference,
                metadata: {
                    custom_fields: [
                        { variable_name: "user_id", value: uid },
                        { variable_name: "identity_type", value: "scholar" }
                    ]
                }
            }
        };
        const hash = crypto.createHmac("sha512", mockSecret)
            .update(JSON.stringify(body))
            .digest("hex");
        return {
            body: body,
            req: {
                body: body,
                headers: { "x-paystack-signature": hash },
            } as any,
        };
    }

    it("should sync activeEntitlements into custom claims on charge.success, preserving existing claims", async () => {
        const { req } = signedRequest("ref_claims_1");
        const res = {
            status: jest.fn().mockReturnThis(),
            send: jest.fn(),
        } as any;

        const auth = admin.auth() as any;
        auth.getUser.mockResolvedValue({ customClaims: { role: "user" } });

        await paystackWebhook(req, res);

        // Exactly one claim write, role preserved (merge, not clobber)
        expect(auth.setCustomUserClaims).toHaveBeenCalledTimes(1);
        expect(auth.setCustomUserClaims).toHaveBeenCalledWith("test_uid", {
            role: "user",
            activeEntitlements: ["premium"],
        });
    });

    it("should not write claims again for a duplicate webhook (same reference)", async () => {
        const { req } = signedRequest("ref_dup_1");
        const res = {
            status: jest.fn().mockReturnThis(),
            send: jest.fn(),
        } as any;

        const auth = admin.auth() as any;
        const firestore = admin.firestore() as any;

        // First delivery: processed_webhooks marker absent -> claims written
        firestore.get.mockResolvedValueOnce({ exists: false });
        await paystackWebhook(req, res);
        expect(auth.setCustomUserClaims).toHaveBeenCalledTimes(1);

        // Duplicate delivery: marker exists -> short-circuit, no second write
        firestore.get.mockResolvedValueOnce({ exists: true });
        await paystackWebhook(req, res);
        expect(auth.setCustomUserClaims).toHaveBeenCalledTimes(1);
        expect(res.send).toHaveBeenCalledWith("duplicate");
    });
});
