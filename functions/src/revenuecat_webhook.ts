import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import * as crypto from "crypto";

const getDb = () => admin.firestore();

/**
 * Validates webhook signature from RevenueCat
 * Prevents fraudulent webhooks
 */
function verifyWebhookSignature(
  payload: string,
  signature: string,
  secret: string
): boolean {
  try {
    const hmac = crypto.createHmac("sha256", secret);
    const expectedSignature = hmac.update(payload).digest("hex");
    return expectedSignature.toLowerCase() === signature.toLowerCase();
  } catch (error) {
    console.error("Error verifying webhook signature:", error);
    return false;
  }
}

/**
 * Handles RevenueCat webhooks for subscription events
 * Events: INITIAL_PURCHASE, RENEWAL, CANCELLATION, EXPIRATION, PRODUCT_CHANGE
 */
export const revenueCatWebhook = functions.https.onRequest(
  async (req, res) => {
    // Verify RevenueCat secret from environment
    const webhookSecret = process.env.REVENUECAT_WEBHOOK_SECRET;

    if (!webhookSecret) {
      console.error("REVENUECAT_WEBHOOK_SECRET not configured");
      res.status(500).send("Webhook secret not configured");
      return;
    }

    // Get required headers
    const signature = req.get("X-RevenueCat-Webhook-Signature");
    const body = req.body;

    if (!signature || !body) {
      console.error("Missing signature or body");
      res.status(400).send("Bad request");
      return;
    }

    // Verify webhook signature
    const payload = JSON.stringify(body);
    if (!verifyWebhookSignature(payload, signature, webhookSecret)) {
      console.error("Invalid webhook signature");
      res.status(401).send("Unauthorized");
      return;
    }

    const eventId = body.event_id;
    const eventType = body.event_type;
    const appId = body.app_id;

    console.log(`RevenueCat webhook received: ${eventType}`);

    const firestore = getDb();

    try {
      switch (eventType) {
      case "INITIAL_PURCHASE":
      case "RENEWAL":
        await handleSubscriptionActive(eventId, body, firestore);
        break;
      case "CANCELLATION":
      case "EXPIRATION":
      case "UNCANCELLATION":
        await handleSubscriptionCancelled(eventId, body, firestore);
        break;
      case "PRODUCT_CHANGE":
        await handleProductChange(eventId, body, firestore);
        break;
      case "TRANSFER":
        await handleSubscriptionTransfer(eventId, body, firestore);
        break;
      case "TEST":
        console.log("Test webhook received, ignoring");
        break;
      default:
        console.warn(`Unknown event type: ${eventType}`);
      }

      // Acknowledge webhook receipt
      await firestore.collection("webhook_receipts").doc(eventId).set({
        eventId,
        eventType,
        appId,
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      res.status(200).send("Webhook processed successfully");
    } catch (error) {
      console.error("Error processing webhook:", error);

      // Log failed webhook
      await firestore.collection("webhook_receipts").doc(eventId).set({
        eventId,
        eventType,
        error: error instanceof Error ? error.message : String(error),
        failedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });

      res.status(500).send("Error processing webhook");
    }
  }
);

/**
 * Handles active subscription events
 */
async function handleSubscriptionActive(
  eventId: string,
  body: any,
  firestore: admin.firestore.Firestore,
) {
  const apiKey = body.api_key;

  // Extract customer info from body
  const customerInfo = body.customer_info || {};
  const entitlements = customerInfo.entitlements || {};

  // Find user by RevenueCat customer ID
  const usersSnapshot = await firestore
    .collection("users")
    .where("revenueCatCustomerId", "==", apiKey)
    .limit(1)
    .get();

  if (usersSnapshot.empty) {
    console.warn(`No user found for RevenueCat customer ID: ${apiKey}`);
    return;
  }

  const userId = usersSnapshot.docs[0].id;

  // Update user subscription status
  await firestore.collection("users").doc(userId).update({
    isPremium: true,
    subscriptionExpiry: calculateExpiryDate(entitlements),
    subscriptionType: "premium",
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  console.log(`Updated user ${userId} subscription to premium`);
}

/**
 * Handles cancelled/expired subscription events
 */
async function handleSubscriptionCancelled(
  eventId: string,
  body: any,
  firestore: admin.firestore.Firestore,
) {
  const customerInfo = body.customer_info || {};
  const entitlements = customerInfo.entitlements || {};
  const apiKey = body.api_key;

  const usersSnapshot = await firestore
    .collection("users")
    .where("revenueCatCustomerId", "==", apiKey)
    .limit(1)
    .get();

  if (usersSnapshot.empty) {
    console.warn(`No user found for RevenueCat customer ID: ${apiKey}`);
    return;
  }

  const userId = usersSnapshot.docs[0].id;

  // Check if any entitlement is still active
  const hasActiveEntitlement = Object.values(entitlements).some(
    (ent: any) => ent && ent.expires_date_ms && new Date(ent.expires_date_ms) > new Date()
  );

  const isPremium = hasActiveEntitlement;

  await firestore.collection("users").doc(userId).update({
    isPremium,
    subscriptionExpiry: hasActiveEntitlement ? calculateExpiryDate(entitlements) : null,
    subscriptionType: hasActiveEntitlement ? "premium" : "free",
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  console.log(`Updated user ${userId} subscription status to ${isPremium ? "premium" : "free"}`);
}

/**
 * Handles product change events (e.g., plan upgrade/downgrade)
 */
async function handleProductChange(
  eventId: string,
  body: any,
  firestore: admin.firestore.Firestore,
) {
  const customerInfo = body.customer_info || {};
  const entitlements = customerInfo.entitlements || {};
  const apiKey = body.api_key;

  const usersSnapshot = await firestore
    .collection("users")
    .where("revenueCatCustomerId", "==", apiKey)
    .limit(1)
    .get();

  if (usersSnapshot.empty) {
    return;
  }

  const userId = usersSnapshot.docs[0].id;

  await firestore.collection("users").doc(userId).update({
    entitlements,
    subscriptionExpiry: calculateExpiryDate(entitlements),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  console.log(`Updated user ${userId} product subscription`);
}

/**
 * Handles subscription transfer events
 */
async function handleSubscriptionTransfer(
  eventId: string,
  body: any,
  firestore: admin.firestore.Firestore,
) {
  const apiKey = body.api_key;

  console.log(`Subscription transfer for ${apiKey}`);

  // Find old user and remove premium status
  const oldUsersSnapshot = await firestore
    .collection("users")
    .where("revenueCatCustomerId", "==", apiKey)
    .get();

  for (const doc of oldUsersSnapshot.docs) {
    await firestore.collection("users").doc(doc.id).update({
      isPremium: false,
      subscriptionType: "free",
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }

  console.log(`Removed premium status from ${oldUsersSnapshot.size} user(s)`);
}

/**
 * Calculates expiry date from entitlements
 * Returns the earliest future expiry date
 */
function calculateExpiryDate(entitlements: Record<string, any>): admin.firestore.Timestamp | null {
  const now = Date.now();
  let earliestExpiry: Date | null = null;

  for (const entitlement of Object.values(entitlements || {})) {
    if (entitlement && entitlement.expires_date_ms) {
      const expiryDate = new Date(entitlement.expires_date_ms);
      if (expiryDate.getTime() > now && (!earliestExpiry || expiryDate < earliestExpiry)) {
        earliestExpiry = expiryDate;
      }
    }
  }

  return earliestExpiry
    ? admin.firestore.Timestamp.fromDate(earliestExpiry)
    : null;
}
