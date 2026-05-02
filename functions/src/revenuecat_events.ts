import { onCustomEventPublished } from "firebase-functions/v2/eventarc";
import * as admin from "firebase-admin";

const db = admin.firestore();

/**
 * Handles billing issue events from RevenueCat extension
 * Sends push notifications to users with billing problems
 */
export const onBillingIssue = onCustomEventPublished(
  "com.revenuecat.v1.billing_issue",
  async (event) => {
    const data = event.data.message.json;
    const appUserId = data.app_user_id;
    const productId = data.product_id;
    const expirationDate = data.expires_date;

    console.log(`Billing issue detected for user ${appUserId}, product ${productId}`);

    try {
      // Get user's push notification token
      const userDoc = await db.collection("users").doc(appUserId).get();
      if (!userDoc.exists) {
        console.log(`User ${appUserId} not found`);
        return;
      }

      const userData = userDoc.data();
      const pushToken = userData?.pushNotificationToken;

      if (!pushToken) {
        console.log(`No push token found for user ${appUserId}`);
        return;
      }

      // Send push notification
      const message = {
        token: pushToken,
        notification: {
          title: "Payment Issue Detected",
          body: "Your subscription payment failed. Please update your payment method to continue enjoying premium features.",
        },
        data: {
          type: "billing_issue",
          productId: productId,
          expirationDate: expirationDate,
        },
      };

      await admin.messaging().send(message);
      console.log(`Push notification sent to user ${appUserId}`);
    } catch (error) {
      console.error(`Error handling billing issue for user ${appUserId}:`, error);
    }
  }
);

/**
 * Handles subscription renewal events from RevenueCat extension
 * Updates user stats and sends confirmation notifications
 */
export const onSubscriptionRenewed = onCustomEventPublished(
  "com.revenuecat.v1.renewal",
  async (event) => {
    const data = event.data.message.json;
    const appUserId = data.app_user_id;
    const productId = data.product_id;
    const entitlementId = data.entitlement_id;

    console.log(`Subscription renewed for user ${appUserId}, product ${productId}`);

    try {
      // Update user document with renewal info
      await db.collection("users").doc(appUserId).update({
        lastRenewalAt: admin.firestore.FieldValue.serverTimestamp(),
        subscriptionStatus: "active",
      });

      // Get user's push notification token
      const userDoc = await db.collection("users").doc(appUserId).get();
      if (!userDoc.exists) return;

      const userData = userDoc.data();
      const pushToken = userData?.pushNotificationToken;

      if (pushToken) {
        // Send renewal confirmation notification
        const message = {
          token: pushToken,
          notification: {
            title: "Subscription Renewed",
            body: "Your premium subscription has been successfully renewed. Thank you for your continued support!",
          },
          data: {
            type: "subscription_renewed",
            productId: productId,
            entitlementId: entitlementId,
          },
        };

        await admin.messaging().send(message);
        console.log(`Renewal notification sent to user ${appUserId}`);
      }
    } catch (error) {
      console.error(`Error handling renewal for user ${appUserId}:`, error);
    }
  }
);

/**
 * Handles subscription cancellation events from RevenueCat extension
 * Updates user stats and sends notifications
 */
export const onSubscriptionCancelled = onCustomEventPublished(
  "com.revenuecat.v1.cancellation",
  async (event) => {
    const data = event.data.message.json;
    const appUserId = data.app_user_id;
    const productId = data.product_id;
    const expirationDate = data.expires_date;

    console.log(`Subscription cancelled for user ${appUserId}, product ${productId}`);

    try {
      // Update user document with cancellation info
      await db.collection("users").doc(appUserId).update({
        subscriptionStatus: "cancelled",
        cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
        expiresAt: new Date(expirationDate),
      });

      // Get user's push notification token
      const userDoc = await db.collection("users").doc(appUserId).get();
      if (!userDoc.exists) return;

      const userData = userDoc.data();
      const pushToken = userData?.pushNotificationToken;

      if (pushToken) {
        // Send cancellation notification
        const message = {
          token: pushToken,
          notification: {
            title: "Subscription Cancelled",
            body: "Your subscription has been cancelled. You'll continue to have access until your current billing period ends.",
          },
          data: {
            type: "subscription_cancelled",
            productId: productId,
            expirationDate: expirationDate,
          },
        };

        await admin.messaging().send(message);
        console.log(`Cancellation notification sent to user ${appUserId}`);
      }
    } catch (error) {
      console.error(`Error handling cancellation for user ${appUserId}:`, error);
    }
  }
);

/**
 * Handles subscription expiration events from RevenueCat extension
 * Updates user stats and sends notifications
 */
export const onSubscriptionExpired = onCustomEventPublished(
  "com.revenuecat.v1.expiration",
  async (event) => {
    const data = event.data.message.json;
    const appUserId = data.app_user_id;
    const productId = data.product_id;

    console.log(`Subscription expired for user ${appUserId}, product ${productId}`);

    try {
      // Update user document with expiration info
      await db.collection("users").doc(appUserId).update({
        subscriptionStatus: "expired",
        expiredAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Get user's push notification token
      const userDoc = await db.collection("users").doc(appUserId).get();
      if (!userDoc.exists) return;

      const userData = userDoc.data();
      const pushToken = userData?.pushNotificationToken;

      if (pushToken) {
        // Send expiration notification
        const message = {
          token: pushToken,
          notification: {
            title: "Subscription Expired",
            body: "Your premium subscription has expired. Subscribe again to continue enjoying premium features!",
          },
          data: {
            type: "subscription_expired",
            productId: productId,
          },
        };

        await admin.messaging().send(message);
        console.log(`Expiration notification sent to user ${appUserId}`);
      }
    } catch (error) {
      console.error(`Error handling expiration for user ${appUserId}:`, error);
    }
  }
);

/**
 * Handles initial purchase events from RevenueCat extension
 * Updates user stats and sends welcome notifications
 */
export const onInitialPurchase = onCustomEventPublished(
  "com.revenuecat.v1.initial_purchase",
  async (event) => {
    const data = event.data.message.json;
    const appUserId = data.app_user_id;
    const productId = data.product_id;
    const entitlementId = data.entitlement_id;

    console.log(`Initial purchase for user ${appUserId}, product ${productId}`);

    try {
      // Update user document with purchase info
      await db.collection("users").doc(appUserId).update({
        subscriptionStatus: "active",
        subscribedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Get user's push notification token
      const userDoc = await db.collection("users").doc(appUserId).get();
      if (!userDoc.exists) return;

      const userData = userDoc.data();
      const pushToken = userData?.pushNotificationToken;

      if (pushToken) {
        // Send welcome notification
        const message = {
          token: pushToken,
          notification: {
            title: "Welcome to Premium!",
            body: "Thank you for subscribing! You now have access to all premium features.",
          },
          data: {
            type: "initial_purchase",
            productId: productId,
            entitlementId: entitlementId,
          },
        };

        await admin.messaging().send(message);
        console.log(`Welcome notification sent to user ${appUserId}`);
      }
    } catch (error) {
      console.error(`Error handling initial purchase for user ${appUserId}:`, error);
    }
  }
);

/**
 * Handles product change events from RevenueCat extension
 * Updates user stats when users upgrade/downgrade plans
 */
export const onProductChange = onCustomEventPublished(
  "com.revenuecat.v1.product_change",
  async (event) => {
    const data = event.data.message.json;
    const appUserId = data.app_user_id;
    const productId = data.product_id;
    const previousProductId = data.previous_product_id;

    console.log(`Product changed for user ${appUserId}: ${previousProductId} -> ${productId}`);

    try {
      // Update user document with product change info
      await db.collection("users").doc(appUserId).update({
        currentProductId: productId,
        previousProductId: previousProductId,
        productChangedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Get user's push notification token
      const userDoc = await db.collection("users").doc(appUserId).get();
      if (!userDoc.exists) return;

      const userData = userDoc.data();
      const pushToken = userData?.pushNotificationToken;

      if (pushToken) {
        // Send product change notification
        const message = {
          token: pushToken,
          notification: {
            title: "Plan Updated",
            body: "Your subscription plan has been successfully updated.",
          },
          data: {
            type: "product_change",
            productId: productId,
            previousProductId: previousProductId,
          },
        };

        await admin.messaging().send(message);
        console.log(`Product change notification sent to user ${appUserId}`);
      }
    } catch (error) {
      console.error(`Error handling product change for user ${appUserId}:`, error);
    }
  }
);
