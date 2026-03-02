import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

/// Service for managing Firebase App Check initialization and configuration
///
/// App Check helps protect your backend resources from abuse by verifying
/// that requests come from your legitimate app and not from scripts or bots.
class AppCheckService {
  /// Initialize Firebase App Check with appropriate providers for each platform
  ///
  /// In production, uses:
  /// - Android: Play Integrity API
  /// - iOS: App Attest
  ///
  /// In debug mode, uses DebugProvider to allow development and testing
  static Future<FirebaseAppCheck> initialize() async {
    final appCheck = FirebaseAppCheck.instance;

    try {
      // Configure App Check based on platform and build mode
      if (kIsWeb) {
        // Web mode: ReCaptcha V3 is the standard provider
        // site key must be obtained from Firebase Console
        await appCheck.activate(
          webProvider: ReCaptchaV3Provider(
            '6LdW940qAAAAAI33f-i5v5y5v5v5v5v5v5v5v5v',
          ),
        );
      } else if (kDebugMode) {
        // Debug mode: Use DebugProvider for development
        await appCheck.activate(
          androidProvider: AndroidProvider.debug,
          appleProvider: AppleProvider.debug,
        );
      } else {
        // Production mode: Use real attestation providers
        // Mobile: Play Integrity (Android) and App Attest (iOS)
        await appCheck.activate(
          androidProvider: AndroidProvider.playIntegrity,
          appleProvider: AppleProvider.appAttest,
        );
      }

      // Set up token auto-refresh
      // This ensures App Check tokens stay fresh (they expire every hour)
      await appCheck.setTokenAutoRefreshEnabled(true);

      debugPrint('✅ Firebase App Check initialized successfully');
      return appCheck;
    } catch (e) {
      // Check for rate limiting errors (common during development)
      final isRateLimited = e.toString().contains('Too many attempts');

      if (isRateLimited) {
        debugPrint('⚠️ App Check rate limited - continuing without token');
        debugPrint('   Wait a few minutes before hot reloading again');
        return appCheck;
      }

      debugPrint('⚠️ Firebase App Check initialization failed: $e');
      debugPrint('📱 This is usually due to:');
      debugPrint('   1. No internet connection on the device');
      debugPrint('   2. Firebase App Check not enabled in Firebase Console');
      debugPrint('   3. DNS resolution issues');
      debugPrint('');
      debugPrint('🔧 The app will continue without App Check protection.');
      debugPrint(
        '   Please enable App Check in Firebase Console when you have internet.',
      );

      // Return instance anyway - app can continue without token verification
      return appCheck;
    }
  }

  /// Get the current App Check token
  ///
  /// This token should be included in requests to your backend to verify
  /// the request is coming from your legitimate app
  static Future<String?> getToken() async {
    try {
      final token = await FirebaseAppCheck.instance.getToken();
      return token;
    } catch (e) {
      debugPrint('❌ Error getting App Check token: $e');
      return null;
    }
  }

  /// Force refresh the App Check token
  ///
  /// Use this when a token has expired or you need a fresh token
  static Future<String?> refreshTokens() async {
    try {
      // The getToken() method automatically refreshes tokens when needed
      final token = await FirebaseAppCheck.instance.getToken();
      debugPrint('🔄 App Check token refreshed');
      return token;
    } catch (e) {
      debugPrint('❌ Error refreshing App Check token: $e');
      return null;
    }
  }

  /// Listen to token changes
  ///
  /// Returns a Stream that emits new tokens whenever they are refreshed
  static Stream<String?> get onTokenChange {
    return FirebaseAppCheck.instance.onTokenChange;
  }

  /// Check if App Check is properly configured
  static Future<bool> isConfigured() async {
    try {
      final token = await getToken();
      return token != null && token.isNotEmpty;
    } catch (e) {
      debugPrint('❌ App Check not configured: $e');
      return false;
    }
  }
}

/// Extension to easily add App Check tokens to HTTP requests
extension AppCheckRequestExtension on Map<String, String> {
  /// Add App Check token to request headers
  Map<String, String> withAppCheckToken() {
    final withToken = Map<String, String>.from(this);
    AppCheckService.getToken().then((token) {
      if (token != null) {
        withToken['X-Firebase-AppCheck'] = token;
      }
    });
    return withToken;
  }
}
