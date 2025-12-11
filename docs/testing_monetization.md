# Testing Monetization Functionality

This document provides instructions for testing the RevenueCat and AdMob integration in your app.

## 1. Pre-Setup Requirements

Before testing, ensure you have:
- RevenueCat account and project set up
- AdMob account and ad units created
- Environment variables set for your test keys

## 2. Testing RevenueCat Integration

### 2.1 Setup Test Environment
```bash
# Run with test environment variables
flutter run --dart-define=REVENUECAT_GOOGLE_API_KEY=your_test_revenuecat_key
```

### 2.2 Test Subscription Status
1. Launch the app
2. Verify that `isPremium` provider correctly initializes to `false`
3. Check that paywall screen displays properly
4. Verify that the subscription status is fetched from RevenueCat

### 2.3 Test Purchase Flow
1. Navigate to the paywall screen
2. Initiate a purchase using RevenueCat's test products
3. Verify that purchase completes successfully
4. Confirm that `isPremium` state updates to `true`
5. Verify that UI elements update accordingly (e.g., ads are hidden)

### 2.4 Test Restore Purchases
1. Simulate a new app installation
2. Use the "Restore Purchases" functionality
3. Confirm that previous purchases are recognized
4. Verify that premium status is restored

## 3. Testing AdMob Integration

### 3.1 Ad Display Test
1. Ensure you're using test ad unit IDs during development
2. Verify that ads are displayed when user is not premium
3. Confirm that ads are hidden when user has premium status
4. Test ad loading and display on different screen sizes

### 3.2 Ad Behavior Test
1. Purchase premium subscription
2. Verify ads disappear immediately or after UI refresh
3. Cancel subscription (in sandbox) and verify ads reappear
4. Test ad loading behavior when network is slow

## 4. End-to-End Testing

### 4.1 Free User Experience
- App launches normally
- Ads are displayed in appropriate locations
- Premium features are locked
- Paywall is accessible

### 4.2 Premium User Experience
- App launches normally
- No ads are displayed
- Premium features are accessible
- Subscription status is maintained

## 5. Debugging Tips

### RevenueCat Debugging
- Check logs for RevenueCat SDK messages
- Use RevenueCat dashboard to monitor events
- Enable debug logging in the repository

### AdMob Debugging
- Look for ad loading errors in logs
- Verify ad unit IDs are correct
- Ensure AdMob App ID is properly configured

## 6. Production Checklist

Before releasing:
- Replace test ad unit IDs with production IDs
- Ensure RevenueCat is configured for production
- Test with real payment methods in sandbox
- Verify all monetization features work as expected
- Confirm analytics and tracking are working

## 7. Common Issues

- Ads not loading: Check ad unit IDs and internet connection
- Purchase failures: Verify RevenueCat configuration and billing setup
- Subscription status not updating: Check webhook configuration
- Ads still showing for premium users: Verify subscription status check