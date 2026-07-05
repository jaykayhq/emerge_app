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
const PAYSTACK_SECRET_KEY = process.env.PAYSTACK_SECRET_KEY || "sk_test_mockkey"; // Replace with Secret Manager

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
    if (!amount || !email) {
        throw new HttpsError("invalid-argument", "Missing required fields (amount, email).");
    }

    // 2. Call Paystack API
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
                    Authorization: `Bearer ${PAYSTACK_SECRET_KEY}`,
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
    const hash = crypto
        .createHmac("sha512", PAYSTACK_SECRET_KEY)
        .update(JSON.stringify(req.body))
        .digest("hex");

    // Verify signature
    if (hash !== req.headers["x-paystack-signature"]) {
        res.status(401).send("Invalid signature");
        return;
    }

    const event = req.body;

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

                logger.info(`Successfully upgraded user ${uid} to premium via Paystack.`);
            } catch (err) {
                logger.error("Firestore Update Error:", err);
            }
        }
    }

    res.status(200).send("Webhook received");
});
