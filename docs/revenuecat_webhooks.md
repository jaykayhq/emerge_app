# RevenueCat Webhooks Setup

To properly connect your app to RevenueCat and handle subscription events server-side, you need to set up webhooks in your RevenueCat dashboard.

## 1. Configure Webhooks in RevenueCat Dashboard

1. Go to your RevenueCat dashboard
2. Navigate to Project Settings → Webhooks
3. Add your webhook endpoint URL (typically your Firebase Functions URL)

## 2. Webhook Endpoint Implementation

Create a Firebase Function to handle RevenueCat webhooks:

```javascript
// In functions/src/index.ts
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

// Verify RevenueCat webhook signature
const verifyRevenueCatWebhook = (req: any) => {
  // RevenueCat signs webhooks with a secret key
  // Implementation depends on your security requirements
  // Check RevenueCat documentation for signature verification
  return true; // Simplified - implement proper verification
};

export const revenueCatWebhook = functions.https.onRequest(async (req, res) => {
  if (req.method !== 'POST') {
    return res.status(405).send('Method not allowed');
  }

  // Verify webhook signature
  if (!verifyRevenueCatWebhook(req)) {
    return res.status(401).send('Unauthorized');
  }

  const event = req.body;

  switch (event.event_type) {
    case 'NON_RENEWING_PURCHASE':
    case 'RENEWAL':
    case 'PRODUCT_CHANGE':
      // Update user subscription status in Firestore
      await admin
        .firestore()
        .collection('users')
        .doc(event.app_user_id)
        .update({
          isPremium: true,
          subscriptionStatus: 'active',
          entitlements: event.entitlements,
          updated_at: admin.firestore.FieldValue.serverTimestamp(),
        });
      break;
      
    case 'CANCELLATION':
    case 'BILLING_ISSUE':
      // Handle subscription cancellation
      await admin
        .firestore()
        .collection('users')
        .doc(event.app_user_id)
        .update({
          isPremium: false,
          subscriptionStatus: 'cancelled',
          updated_at: admin.firestore.FieldValue.serverTimestamp(),
        });
      break;
  }

  res.status(200).send('OK');
});
```

## 3. Environment Variables

Add your RevenueCat shared secret to Firebase environment variables:

```bash
firebase functions:config:set revenuecat.applesharesecret="your_secret_here"
firebase functions:config:set revenuecat.googleapisecret="your_secret_here"
```

## 4. RevenueCat Configuration

In your RevenueCat dashboard:
1. Set up entitlements (e.g., "premium")
2. Configure products and offerings
3. Map your in-app purchases to products in Google Play Console and Apple App Store Connect

## 5. Testing Webhooks

Use RevenueCat's webhook testing tools to verify your endpoint is working correctly before going live.