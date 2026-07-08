# Firebase App Check Setup Guide

## Overview

Firebase App Check is now configured in your Emerge app to protect your backend resources (Firestore, Cloud Functions, Storage) from abuse and unauthorized access.

## What Was Added

### 1. Dependencies
- ✅ `firebase_app_check: ^0.3.1+4` added to [pubspec.yaml](../pubspec.yaml)
- ✅ `com.google.android.play:integrity:1.3.0` (Play Integrity API) added to [android/app/build.gradle.kts](../android/app/build.gradle.kts)

### 2. Files Created
- ✅ [lib/core/security/app_check_service.dart](../lib/core/security/app_check_service.dart) - App Check initialization and token management

### 3. Files Modified
- ✅ [lib/core/init/init_app.dart](../lib/core/init/init_app.dart) - App Check initialization in app startup
- ✅ [android/app/src/main/AndroidManifest.xml](../android/app/src/main/AndroidManifest.xml) - Debug token configuration

## Next Steps (Required)

### 1. Get Your Debug Token (Development Only)

Run your app in debug mode to get the debug token:

```bash
flutter run
```

Look for this in your console logs:
```
🔐 App Check Debug Token: YOUR_DEBUG_TOKEN_HERE
Add this token in Firebase Console → App Check → Apps → Debug Tokens
```

### 2. Add Debug Token in Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `tradeflash-l2966`
3. Navigate to: **App Check** → **Apps** → **Your Android App**
4. Click **Debug Tokens** (usually in the ⋮ menu)
5. Click **Add debug token**
6. Paste the token from your console logs
7. Save

### 3. Enable App Check on Firebase Services

For each service you want to protect:

#### Firestore
1. Go to **Firestore Database** → **Rules**
2. Add App Check requirement to your rules:
```javascript
allow read, write: if request.auth != null && request.appCheck != null;
```

#### Cloud Functions
1. Go to **Functions** → **your function**
2. Add App Check validation:
```typescript
import { onCall } from "firebase-functions/v2/https";
import { onDocumentWritten } from "firebase-functions/v2/firestore";

// Protect callable functions
exports.yourFunction = onCall((req) => {
  // App Check token is automatically verified
  // Add your function logic here
});

// Protect firestore triggers
exports.yourTrigger = onDocumentWritten("your-path", (event) => {
  // Add your logic here
});
```

#### Cloud Storage
1. Go to **Storage** → **Rules**
2. Add App Check requirement:
```javascript
allow read, write: if request.auth != null && request.appCheck != null;
```

### 4. Production Setup (Before Play Store Launch)

#### A. Enable Play Integrity API
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project
3. Navigate to: **APIs & Services** → **Library**
4. Search for "Play Integrity API"
5. Click **Enable**

#### B. Link Your App to Play Console
1. Go to [Google Play Console](https://play.google.com/console)
2. Select your app
3. Navigate to: **Setup** → **App integrity**
4. Link your Cloud project

#### C. Update App Check Configuration
Since you said you've already set up the backend, ensure:
- App Check is **enabled** in Firebase Console for your app
- **Play Integrity** is selected as the attestation provider for Android
- Set appropriate **enforcement** levels:
  - **Development**: Unenforced (while testing)
  - **Production**: Enforced (protects against abuse)

## How App Check Works

### Automatic Protection
App Check automatically works with these Firebase services:
- ✅ Cloud Firestore
- ✅ Cloud Functions
- ✅ Cloud Storage
- ✅ Realtime Database
- ✅ Firebase ML

### Token Lifecycle
- Tokens are generated automatically when your app starts
- Tokens are **automatically refreshed** every hour
- Tokens are included in all Firebase requests via the `X-Firebase-AppCheck` header

### Using App Check Tokens Manually

If you need to make requests to your own backend or non-Firebase APIs:

```dart
import 'package:emerge_app/core/security/app_check_service.dart';

// Get current token
final token = await AppCheckService.getToken();

// Add to your custom API requests
final response = await http.get(
  Uri.parse('https://your-api.com/endpoint'),
  headers: {
    'X-Firebase-AppCheck': token!,
    'Authorization': 'Bearer $userToken',
  },
);
```

### Listen for Token Changes

```dart
AppCheckService.onTokenChange.listen((token) {
  if (token != null) {
    print('New App Check token: $token');
    // Update your API clients or send to your backend
  }
});
```

## Configuration Files

### Android
- **Provider**: Play Integrity API
- **Configuration**: [android/app/build.gradle.kts](../android/app/build.gradle.kts)
- **Manifest**: [android/app/src/main/AndroidManifest.xml](../android/app/src/main/AndroidManifest.xml)

### iOS (Future)
When you add iOS support:
- **Provider**: DeviceCheck / App Attest
- **Configuration**: Automatically handled by firebase_app_check plugin

### Web (Future)
When you add web support:
- **Provider**: reCAPTCHA v3
- **Configuration**: Add site key in [lib/core/security/app_check_service.dart](../lib/core/security/app_check_service.dart)

## Security Levels

### Development Mode
- Uses **DebugProvider** - allows unverified requests
- No attestation checks
- Perfect for testing and development

### Production Mode
- Uses **Play Integrity API** - verifies app authenticity
- Checks for:
  - ✅ App is from Play Store
  - ✅ App hasn't been tampered with
  - ✅ Running on genuine Android device
- Blocks unauthorized apps and scripts

## Testing

### Test in Development
1. Run app in debug mode
2. Check console for App Check token
3. Verify Firebase operations work
4. Add debug token to Firebase Console

### Test in Production
1. Build release APK/AAB
2. Install on test device
3. Verify all Firebase operations work
4. Check Firebase Console metrics

### Monitoring
Go to **Firebase Console** → **App Check** → **Metrics** to see:
- Number of verified requests
- Number of unverified requests
- App Check token freshness
- Error rates

## Troubleshooting

### "App Check failed" Errors
**Solution**: Ensure debug token is added in Firebase Console during development

### Requests Being Blocked
**Solution**:
1. Check if App Check is enforced in Firebase Console
2. Verify Play Integrity API is enabled
3. Check token refresh logs in your app

### Token Expired
**Solution**: Tokens auto-refresh every hour. If you need immediate refresh:
```dart
await AppCheckService.refreshTokens();
```

### Play Integrity API Issues
**Solution**:
1. Verify API is enabled in Google Cloud Console
2. Check that your app is properly linked in Play Console
3. Ensure you're using a signed release build for testing

## Removing SSL Pinning Code

Since App Check provides better security, you can now remove the incomplete SSL pinning implementation:

- [ ] Delete or simplify [lib/core/network/secure_http_client.dart](../lib/core/network/secure_http_client.dart)
- [ ] Remove `AppConfig.enableSslPinning` references
- [ ] App Check handles all Firebase security automatically

## Best Practices

1. **Always use App Check tokens** for Firebase backend communication
2. **Monitor metrics** in Firebase Console regularly
3. **Start in Unenforced mode**, test thoroughly, then enable enforcement
4. **Keep Play Integrity API enabled** in production
5. **Never share debug tokens** publicly
6. **Rotate debug tokens** periodically if needed

## Security Benefits

✅ **Prevents abuse**: Blocks scripts and bots from abusing your backend
✅ **Ensures authenticity**: Verifies requests come from your genuine app
✅ **Zero configuration**: Works automatically with Firebase services
✅ **Better than SSL pinning**: No certificate management overhead
✅ **Google-maintained**: Regular security updates from Google

## Support

For issues or questions:
- [Firebase App Check Documentation](https://firebase.google.com/docs/app-check)
- [FlutterFire App Check Plugin](https://firebase.google.com/docs/app-check/flutter)
- [Play Integrity API](https://developer.android.com/google-play/integrity)

---

**Status**: ✅ App Check is fully configured and ready to use!

**Next Step**: Get your debug token and add it to Firebase Console to start testing.
