import * as admin from "firebase-admin";
import { paystackWebhook } from "../src/payments/paystack";
import * as crypto from "crypto";

jest.mock("firebase-admin", () => {
    const firestoreMock = {
        collection: jest.fn().mockReturnThis(),
        doc: jest.fn().mockReturnThis(),
        set: jest.fn().mockResolvedValue(true),
    };
    return {
        apps: [],
        initializeApp: jest.fn(),
        firestore: jest.fn(() => firestoreMock),
        FieldValue: {
            serverTimestamp: jest.fn(() => "mockTimestamp"),
        },
    };
});

describe("Paystack Webhook", () => {
    const mockSecret = "sk_test_mockkey";
    process.env.PAYSTACK_SECRET_KEY = mockSecret;

    it("should process charge.success event and update firestore", async () => {
        const payload = {
            event: "charge.success",
            data: {
                metadata: {
                    custom_fields: [
                        { variable_name: "user_id", value: "test_uid" },
                        { variable_name: "identity_type", value: "scholar" }
                    ]
                }
            }
        };

        const hash = crypto.createHmac("sha512", mockSecret)
            .update(JSON.stringify(payload))
            .digest("hex");

        const req = {
            body: payload,
            headers: { "x-paystack-signature": hash },
        } as any;

        const res = {
            status: jest.fn().mockReturnThis(),
            send: jest.fn(),
        } as any;

        // Since it's onRequest, it's a typical Express handler
        await paystackWebhook(req, res);

        expect(res.status).toHaveBeenCalledWith(200);
        expect(res.send).toHaveBeenCalledWith("Webhook received");
        
        // Ensure firestore was updated
        const firestore = admin.firestore();
        expect(firestore.collection).toHaveBeenCalledWith("users");
        expect(firestore.collection("users").doc).toHaveBeenCalledWith("test_uid");
        expect(firestore.collection("users").doc("test_uid").set).toHaveBeenCalledWith(
            expect.objectContaining({
                isPremium: true,
                identity_type: "scholar"
            }),
            { merge: true }
        );
    });

    it("should reject invalid signatures", async () => {
        const payload = { event: "charge.success", data: {} };
        const req = {
            body: payload,
            headers: { "x-paystack-signature": "invalid_signature" },
        } as any;

        const res = {
            status: jest.fn().mockReturnThis(),
            send: jest.fn(),
        } as any;

        await paystackWebhook(req, res);

        expect(res.status).toHaveBeenCalledWith(401);
        expect(res.send).toHaveBeenCalledWith("Invalid signature");
    });
});
