import 'package:emerge_app/features/onboarding/data/services/remote_config_service.dart';
import 'package:flutter/foundation.dart';
import '../../core/utils/app_logger.dart';

class AppConfig {
  static RemoteConfigService? _remoteConfigService;

  /// Initialize Remote Config (must be called before getRevenueCatApiKey)
  static Future<void> initializeRemoteConfig() async {
    _remoteConfigService = RemoteConfigService();
    await _remoteConfigService!.initialize();
  }

  // Environment Configuration
  static const String _environment = String.fromEnvironment(
    'FLUTTER_ENV',
    defaultValue: 'development',
  );
  static bool get isDevelopment => _environment == 'development';
  static bool get isProduction => _environment == 'production';

  // Firebase Configuration
  static const String firebaseApiKey = String.fromEnvironment(
    'FIREBASE_API_KEY',
  );
  static const String firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'tradeflash-l2966',
  );
  static const String firebaseStorageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
    defaultValue: 'tradeflash-l2966.firebasestorage.app',
  );

  // RevenueCat Configuration - Now linked directly to Firebase Remote Config
  // Old compile-time env vars are deprecated - all keys come from Firebase
  @Deprecated('Use Firebase Remote Config instead')
  static const String revenuecatGoogleApiKey = '';
  @Deprecated('Use Firebase Remote Config instead')
  static const String revenuecatAppleApiKey = '';

  // Security Configuration
  static const String recaptchaSiteKey = String.fromEnvironment(
    'RECAPTCHA_SITE_KEY',
    defaultValue: '', // Empty in production - must be set via env var
  );
  static const bool enableFirebaseAppCheck = bool.fromEnvironment(
    'ENABLE_FIREBASE_APP_CHECK',
    defaultValue: true, // ENHANCED: Enabled by default for security
  );
  static const bool enableSslPinning = bool.fromEnvironment(
    'ENABLE_SSL_PINNING',
    defaultValue: true, // ENHANCED: Enabled by default for security
  );
  static const bool enableRateLimiting = bool.fromEnvironment(
    'ENABLE_RATE_LIMITING',
    defaultValue: true,
  );

  // Validate required configuration
  static bool get isValidConfig {
    if (isProduction) {
      return firebaseApiKey.isNotEmpty;
    }
    return true; // Allow defaults in development
  }

  // Get API key from Firebase Remote Config (RevenueCat linked directly to Firebase)
  static String getRevenueCatApiKey(String platform) {
    if (_remoteConfigService == null) {
      debugPrint('⚠️ Remote Config not initialized - call AppConfig.initializeRemoteConfig() first');
      return '';
    }

    final key = _remoteConfigService!.getRevenueCatApiKey(platform);

    if (key.isNotEmpty && key != 'YOUR_REVENUECAT_API_KEY') {
      if (kDebugMode) {
        debugPrint('🔑 Using RevenueCat key from Firebase Remote Config for $platform');
      }
      return key;
    }

    // SECURITY: Fail fast if key is missing (production only)
    if (isProduction) {
      throw Exception(
        'RevenueCat API key not configured for $platform. '
        'Configure in Firebase Remote Config with key: revenuecat_${platform}_api_key',
      );
    }

    // In development, allow app to continue without RevenueCat
    debugPrint('⚠️ RevenueCat API key not configured for $platform - monetization disabled');
    return '';
  }

  // ENHANCED: Log configuration status using AppLogger (with PII redaction)
  static void logConfigurationStatus() {
    if (kDebugMode) {
      AppLogger.i('App Configuration');
      AppLogger.i('  Environment: $_environment');
      AppLogger.i(
        '  Firebase API Key configured: ${firebaseApiKey.isNotEmpty}',
      );
      // RevenueCat keys now come from Firebase Remote Config
      final googleKey = _remoteConfigService?.getRevenueCatApiKey('android') ?? '';
      final appleKey = _remoteConfigService?.getRevenueCatApiKey('ios') ?? '';
      AppLogger.i(
        '  RevenueCat Google Key configured in Firebase: ${googleKey.isNotEmpty && googleKey != 'YOUR_REVENUECAT_API_KEY'}',
      );
      AppLogger.i(
        '  RevenueCat Apple Key configured in Firebase: ${appleKey.isNotEmpty && appleKey != 'YOUR_REVENUECAT_API_KEY'}',
      );
      AppLogger.i('  Firebase App Check enabled: $enableFirebaseAppCheck');
      AppLogger.i('  SSL Pinning enabled: $enableSslPinning');
      AppLogger.i('  Rate Limiting enabled: $enableRateLimiting');
    }
  }
}
