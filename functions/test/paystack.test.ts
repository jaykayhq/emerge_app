import * as admin from "firebase-admin";
import axios from "axios";
import {
  initializePaystackTransaction,
  paystackWebhook,
} from "../src/payments/paystack";
import * as crypto from "crypto";

jest.mock("firebase-admin", () => {
  const firestoreMock = {
    collection: jest.fn().mockReturnThis(),
    doc: jest.fn().mockReturnThis(),
    get: jest.fn().mockResolvedValue({ exists: false }),
    set: jest.fn().mockResolvedValue(true),
  };
  // admin.firestore.FieldValue is a static on the function object.
  const firestore = jest.fn(() => firestoreMock);
  (firestore as any).FieldValue = {
    serverTimestamp: jest.fn(() => "mockTimestamp"),
  };
  return {
    apps: [],
    initializeApp: jest.fn(),
    firestore,
  };
});

jest.mock("axios", () => ({
  post: jest.fn(),
}));

const axiosPost = axios.post as jest.Mock;

describe("Paystack Webhook", () => {
  const mockSecret = "sk_test_mockkey";
  process.env.PAYSTACK_SECRET_KEY = mockSecret;

  it("should process charge.success event and update firestore", async () => {
    const payload = {
      event: "charge.success",
      id: "evt_test_1",
      data: {
        reference: "ref_test_1",
        metadata: {
          custom_fields: [
            { variable_name: "user_id", value: "test_uid" },
            { variable_name: "identity_type", value: "scholar" },
          ],
        },
      },
    };

    const hash = crypto
      .createHmac("sha512", mockSecret)
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
        identity_type: "scholar",
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

describe("initializePaystackTransaction callbackUrl", () => {
  const auth = { uid: "u1", token: {} } as any;
  const mockSecret = "sk_test_mockkey";
  process.env.PAYSTACK_SECRET_KEY = mockSecret;

  const runCallable = (data: any) =>
    initializePaystackTransaction.run({
      auth,
      data,
      rawRequest: {} as any,
      acceptsStreaming: false,
    });

  beforeEach(() => {
    axiosPost.mockReset();
    axiosPost.mockResolvedValue({
      data: {
        data: {
          authorization_url: "https://checkout.paystack.com/test",
          access_code: "test_access_code",
          reference: "test_reference",
        },
      },
    });
  });

  it("forwards a valid app-domain callbackUrl to Paystack", async () => {
    const result = await runCallable({
      amount: 1500000,
      email: "a@b.com",
      callbackUrl: "https://emerge.web.app/order-confirmed",
    });
    expect(result).toMatchObject({
      authorization_url: expect.any(String),
    });
    expect(axiosPost).toHaveBeenCalledWith(
      expect.any(String),
      expect.objectContaining({
        callback_url: "https://emerge.web.app/order-confirmed",
      }),
      expect.any(Object)
    );
  });

  it("omits callback_url when not provided (backward compatible)", async () => {
    await runCallable({ amount: 1500000, email: "a@b.com" });
    const [, body] = axiosPost.mock.calls[0];
    expect(body.callback_url).toBeUndefined();
  });

  it("rejects a non-string callbackUrl", async () => {
    await expect(
      runCallable({ amount: 1500000, email: "a@b.com", callbackUrl: 42 })
    ).rejects.toHaveProperty("code", "invalid-argument");
  });

  it("rejects a disallowed callback host", async () => {
    await expect(
      runCallable({
        amount: 1500000,
        email: "a@b.com",
        callbackUrl: "https://evil.example.com/phish",
      })
    ).rejects.toHaveProperty("code", "invalid-argument");
  });
});
