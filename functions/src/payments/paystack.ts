import { onCall, onRequest, HttpsError } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";
import axios from "axios";
import * as crypto from "crypto";

// Ensure Firebase is initialized
if (admin.apps.length === 0) {
    admin.initializeApp();
}

const db = admin.firestore();

/**
 * Cloud Function to securely initialize a Paystack transaction.
 * Only authenticated users can call this function.
 */
export const initializePaystackTransaction = onCall({
    secrets: ["PAYSTACK_SECRET_KEY"], // Requires Secret Manager configuration
}, async (request) => {
    // 1. Authenticate Request
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "User must be authenticated.");
    }

    const { amount, email, metadata } = request.data;
    if (!amount || typeof amount !== "number" || amount <= 0 || !Number.isInteger(amount)) {
        throw new HttpsError("invalid-argument", "amount must be a positive integer (in kobo)");
    }
    if (!email || typeof email !== "string" || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
        throw new HttpsError("invalid-argument", "A valid email address is required");
    }

    // 2. Call Paystack API
    const secretKey = process.env.PAYSTACK_SECRET_KEY;
    if (!secretKey) {
        throw new HttpsError("failed-precondition", "PAYSTACK_SECRET_KEY is not configured.");
    }
    try {
        const response = await axios.post(
            "https://api.paystack.co/transaction/initialize",
            {
                amount: amount, // in kobo
                email: email,
                channels: ["card", "apple_pay", "google_pay"],
                metadata: {
                    custom_fields: [
                        {
                            display_name: "User ID",
                            variable_name: "user_id",
                            value: request.auth.uid,
                        },
                        {
                            display_name: "Identity Type",
                            variable_name: "identity_type",
                            value: metadata?.identity_type || "default",
                        }
                    ]
                }
            },
            {
                headers: {
                    Authorization: `Bearer ${secretKey}`,
                    "Content-Type": "application/json",
                },
            }
        );

        // 3. Return Authorization URL to Client
        const data = response.data.data;
        return {
            authorization_url: data.authorization_url,
            access_code: data.access_code,
            reference: data.reference,
        };

    } catch (error: any) {
        logger.error("Paystack Init Error", error.response?.data || error.message);
        throw new HttpsError("internal", "Unable to initialize transaction.");
    }
});

/**
 * Webhook endpoint for Paystack to send charge.success events.
 */
export const paystackWebhook = onRequest({
    secrets: ["PAYSTACK_SECRET_KEY"],
}, async (req, res) => {
    const secretKey = process.env.PAYSTACK_SECRET_KEY;
    if (!secretKey) {
        res.status(500).send("PAYSTACK_SECRET_KEY not configured");
        return;
    }
    const hash = crypto
        .createHmac("sha512", secretKey)
        .update(JSON.stringify(req.body))
        .digest("hex");

    // Verify signature
    if (hash !== req.headers["x-paystack-signature"]) {
        res.status(401).send("Invalid signature");
        return;
    }

    const event = req.body;

    const eventReference = event.data?.reference || event.id;
    if (!eventReference) {
        console.warn("Webhook missing reference, skipping");
        res.status(200).send("ignored");
        return;
    }
    // Idempotency check
    const processedRef = db.collection("processed_webhooks").doc(eventReference);
    const existing = await processedRef.get();
    if (existing.exists) {
        console.log(`Duplicate webhook ${eventReference}, skipping`);
        res.status(200).send("duplicate");
        return;
    }

    if (event.event === "charge.success") {
        const data = event.data;
        const uid = data.metadata?.custom_fields?.find((f: any) => f.variable_name === "user_id")?.value;
        const identityType = data.metadata?.custom_fields?.find((f: any) => f.variable_name === "identity_type")?.value;

        if (uid) {
            try {
                // Identity-First UX: Evolve the user's avatar / unlock premium
                await db.collection("users").doc(uid).set({
                    isPremium: true,
                    identity_type: identityType,
                    premium_since: admin.firestore.FieldValue.serverTimestamp(),
                }, { merge: true });

                // SP-H: mirror the entitlement into custom claims so the
                // client's claims fallback (subscription_provider.dart:66-80)
                // works on web too (SP-B D2 deferred this here). Merges —
                // never clobbers existing claims. Refund/expiry clearing is
                // future work (the webhook only receives charge.success).
                try {
                    const auth = admin.auth();
                    const userRecord = await auth.getUser(uid);
                    await auth.setCustomUserClaims(uid, {
                        ...(userRecord.customClaims ?? {}),
                        activeEntitlements: ["premium"],
                    });
                } catch (claimErr) {
                    logger.error("Paystack claim sync failed:", claimErr);
                }

                logger.info(`Successfully upgraded user ${uid} to premium via Paystack.`);
            } catch (err) {
                logger.error("Firestore Update Error:", err);
            }
        }
    }

    await processedRef.set({ processedAt: admin.firestore.FieldValue.serverTimestamp(), type: event.event });

    res.status(200).send("Webhook received");
});
