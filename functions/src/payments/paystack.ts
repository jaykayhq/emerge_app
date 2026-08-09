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

const CALLBACK_ALLOWED_HOSTS = (
  process.env.CALLBACK_ALLOWED_HOSTS ??
  "emerge.web.app,emerge.firebaseapp.com"
)
  .split(",")
  .map((host) => host.trim())
  .filter(Boolean);

/**
 * Cloud Function to securely initialize a Paystack transaction.
 * Only authenticated users can call this function.
 */
export const initializePaystackTransaction = onCall(
  {
    secrets: ["PAYSTACK_SECRET_KEY"], // Requires Secret Manager configuration
  },
  async (request) => {
    // 1. Authenticate Request
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "User must be authenticated.");
    }

    const { amount, email, metadata, callbackUrl } = request.data;
    if (
      !amount ||
      typeof amount !== "number" ||
      amount <= 0 ||
      !Number.isInteger(amount)
    ) {
      throw new HttpsError(
        "invalid-argument",
        "amount must be a positive integer (in kobo)"
      );
    }
    if (
      !email ||
      typeof email !== "string" ||
      !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)
    ) {
      throw new HttpsError(
        "invalid-argument",
        "A valid email address is required"
      );
    }

    // callbackUrl is optional (backward compatible) but must be https and its
    // host must be allow-listed — prevents the callback being pointed at a
    // phishing origin.
    let validatedCallbackUrl: string | undefined;
    if (callbackUrl !== undefined) {
      if (typeof callbackUrl !== "string") {
        throw new HttpsError(
          "invalid-argument",
          "callbackUrl must be a string"
        );
      }
      let parsed: URL;
      try {
        parsed = new URL(callbackUrl);
      } catch {
        throw new HttpsError(
          "invalid-argument",
          "callbackUrl must be a valid URL"
        );
      }
      if (
        parsed.protocol !== "https:" ||
        !CALLBACK_ALLOWED_HOSTS.includes(parsed.host)
      ) {
        throw new HttpsError(
          "invalid-argument",
          "callbackUrl host is not allowed"
        );
      }
      validatedCallbackUrl = callbackUrl;
    }

    // 2. Call Paystack API
    const secretKey = process.env.PAYSTACK_SECRET_KEY;
    if (!secretKey) {
      throw new HttpsError(
        "failed-precondition",
        "PAYSTACK_SECRET_KEY is not configured."
      );
    }
    try {
      const body: Record<string, unknown> = {
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
            },
          ],
        },
      };
      if (validatedCallbackUrl) {
        body.callback_url = validatedCallbackUrl;
      }

      const response = await axios.post(
        "https://api.paystack.co/transaction/initialize",
        body,
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
      logger.error(
        "Paystack Init Error",
        error.response?.data || error.message
      );
      throw new HttpsError("internal", "Unable to initialize transaction.");
    }
  }
);

/**
 * Webhook endpoint for Paystack to send charge.success events.
 */
export const paystackWebhook = onRequest(
  {
    secrets: ["PAYSTACK_SECRET_KEY"],
  },
  async (req, res) => {
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
    const processedRef = db
      .collection("processed_webhooks")
      .doc(eventReference);
    const existing = await processedRef.get();
    if (existing.exists) {
      console.log(`Duplicate webhook ${eventReference}, skipping`);
      res.status(200).send("duplicate");
      return;
    }

    if (event.event === "charge.success") {
      const data = event.data;
      const uid = data.metadata?.custom_fields?.find(
        (f: any) => f.variable_name === "user_id"
      )?.value;
      const identityType = data.metadata?.custom_fields?.find(
        (f: any) => f.variable_name === "identity_type"
      )?.value;

      if (uid) {
        try {
          // Identity-First UX: Evolve the user's avatar / unlock premium
          await db.collection("users").doc(uid).set(
            {
              isPremium: true,
              identity_type: identityType,
              premium_since:
                admin.firestore.FieldValue.serverTimestamp(),
            },
            { merge: true }
          );

          // SP-H: mirror the entitlement into custom claims so the
          // client's claims fallback (subscription_provider.dart:66-80)
          // works on web too (SP-B D2 deferred this here). Merge-safe —
          // preserve existing entitlements and add 'premium' if absent
          // (the filter-then-set pattern from managePremium.ts) so a
          // user with other entitlements is never clobbered.
          try {
            const auth = admin.auth();
            const userRecord = await auth.getUser(uid);
            const existingClaims = userRecord.customClaims ?? {};
            const entitlements = Array.isArray(
              existingClaims.activeEntitlements
            )
              ? (existingClaims.activeEntitlements as string[])
              : [];
            await auth.setCustomUserClaims(uid, {
              ...existingClaims,
              activeEntitlements: entitlements.includes("premium")
                ? entitlements
                : [...entitlements, "premium"],
            });
          } catch (claimErr) {
            logger.error("Paystack claim sync failed:", claimErr);
          }

          logger.info(
            `Successfully upgraded user ${uid} to premium via Paystack.`
          );
        } catch (err) {
          logger.error("Firestore Update Error:", err);
        }
      }
    }

    await processedRef.set({
      processedAt: admin.firestore.FieldValue.serverTimestamp(),
      type: event.event,
    });

    res.status(200).send("Webhook received");
  }
);
