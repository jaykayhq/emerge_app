# Monetization Setup for Emerge App

This document outlines the steps to fully connect your app to RevenueCat and AdMob for monetization.

## 1. Environment Variables

Set up your environment variables for RevenueCat and AdMob:

### For local development:
Create a `.env` file or pass variables when building:
```bash
flutter run --dart-define=REVENUECAT_GOOGLE_API_KEY=your_revenuecat_key_here
flutter run --dart-define=ADMOB_BANNER_AD_UNIT_ID=your_admob_banner_id_here
```

### For release builds:
```bash
flutter build apk --dart-define=REVENUECAT_GOOGLE_API_KEY=your_revenuecat_key_here --dart-define=ADMOB_BANNER_AD_UNIT_ID=your_admob_banner_id_here
```

## 2. RevenueCat Configuration

1. Sign up for a RevenueCat account at https://www.revenuecat.com/
2. Create a new project in the RevenueCat dashboard
3. Configure your products and entitlements:
   - Create an entitlement named "premium" (as referenced in the code)
   - Set up your in-app purchases in Google Play Console
   - Link your Google Play account to RevenueCat
4. Replace the placeholder API keys in the code with your actual keys

## 3. AdMob Configuration

1. Sign up for AdMob at https://admob.google.com/
2. Create ad units for your app:
   - Create a banner ad unit
3. Replace the placeholder ad unit ID with your actual ad unit ID
4. Add your AdMob App ID to the AndroidManifest.xml file (already done in this project)

## 4. Testing

### RevenueCat Testing:
1. Use RevenueCat's sandbox environment for testing
2. The app should properly detect subscription status
3. Test purchase flow using test products

### AdMob Testing:
1. Banner ads will only show to non-premium users
2. Ads are hidden when the user has premium status
3. Test both ad showing and hiding based on subscription status

## 5. Server-Side Verification

Set up RevenueCat webhooks as documented in `docs/revenuecat_webhooks.md` to verify purchases on your backend and update user subscription status in Firestore.

## 6. Build and Release

Before releasing to production:
1. Replace all test ad unit IDs with production IDs
2. Ensure RevenueCat is configured with your production Google Play account
3. Test the entire purchase flow
4. Verify that ads are properly shown/hidden based on subscription status