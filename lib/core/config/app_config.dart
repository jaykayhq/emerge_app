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

  // RevenueCat Configuration
  static const String revenuecatGoogleApiKey = String.fromEnvironment(
    'REVENUECAT_GOOGLE_API_KEY',
  );
  static const String revenuecatAppleApiKey = String.fromEnvironment(
    'REVENUECAT_APPLE_API_KEY',
  );

  // Security Configuration
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
      return firebaseApiKey.isNotEmpty &&
          revenuecatGoogleApiKey.isNotEmpty &&
          revenuecatAppleApiKey != 'YOUR_REVENUECAT_APPLE_API_KEY';
    }
    return true; // Allow defaults in development
  }

  // Get API key with validation (SECURITY: No hardcoded fallbacks)
  // Priority: Remote Config > Compile-time env var
  static String getRevenueCatApiKey(String platform) {
    String? key;

    // Try Remote Config first (Google Cloud Secret Manager integration)
    if (_remoteConfigService != null) {
      final remoteKey = _remoteConfigService!.getRevenueCatApiKey(platform);
      if (remoteKey.isNotEmpty && remoteKey != 'YOUR_REVENUECAT_API_KEY') {
        key = remoteKey;
        if (kDebugMode) {
          debugPrint(
            '🔑 Using RevenueCat key from Remote Config for $platform',
          );
        }
      }
    }

    // Fallback to compile-time environment variable
    if (key == null || key.isEmpty) {
      if (platform == 'android') {
        key = revenuecatGoogleApiKey;
      } else if (platform == 'ios') {
        key = revenuecatAppleApiKey;
      } else {
        throw ArgumentError('Unsupported platform: $platform');
      }
      if (kDebugMode && key.isNotEmpty) {
        debugPrint(
          '🔑 Using RevenueCat key from compile-time env var for $platform',
        );
      }
    }

    // SECURITY: Fail fast if key is missing (production only)
    if (key.isEmpty) {
      if (isProduction) {
        throw Exception(
          'RevenueCat API key not configured for $platform. '
          'Set REVENUECAT_${platform.toUpperCase()}_API_KEY environment variable '
          'or configure in Firebase Remote Config.',
        );
      } else {
        // In development, allow app to continue without RevenueCat
        debugPrint(
          '⚠️ RevenueCat API key not configured for $platform - monetization disabled',
        );
        return '';
      }
    }

    // SECURITY: Prevent test keys in production
    if (isProduction && key.startsWith('test_')) {
      throw Exception(
        'SECURITY VIOLATION: Test RevenueCat API key detected in production build. '
        'This configuration is not allowed.',
      );
    }

    // Warn if test key in development
    if (isDevelopment && key.startsWith('test_')) {
      // Only in debug mode, allow test keys but warn
      debugPrint('WARNING: Using test RevenueCat API key in development');
    }

    return key;
  }

  // ENHANCED: Log configuration status using AppLogger (with PII redaction)
  static void logConfigurationStatus() {
    if (kDebugMode) {
      AppLogger.i('App Configuration');
      AppLogger.i('  Environment: $_environment');
      AppLogger.i(
        '  Firebase API Key configured: ${firebaseApiKey.isNotEmpty}',
      );
      AppLogger.i(
        '  RevenueCat Google Key configured: ${revenuecatGoogleApiKey.isNotEmpty}',
      );
      AppLogger.i(
        '  RevenueCat Apple Key configured: ${revenuecatAppleApiKey.isNotEmpty && revenuecatAppleApiKey != 'YOUR_REVENUECAT_APPLE_API_KEY'}',
      );
      AppLogger.i('  Firebase App Check enabled: $enableFirebaseAppCheck');
      AppLogger.i('  SSL Pinning enabled: $enableSslPinning');
      AppLogger.i('  Rate Limiting enabled: $enableRateLimiting');
    }
  }
}
