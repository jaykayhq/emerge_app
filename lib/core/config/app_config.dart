import 'package:emerge_app/features/onboarding/data/services/remote_config_service.dart';
import 'package:flutter/foundation.dart';
import '../../core/utils/app_logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
  static const String revenuecatGoogleApiKey = String.fromEnvironment('REVENUECAT_GOOGLE_API_KEY');
  @Deprecated('Use Firebase Remote Config instead')
  static const String revenuecatAppleApiKey = String.fromEnvironment('REVENUECAT_APPLE_API_KEY');

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

  // Get API key from multiple sources with fallback logic
  static String getRevenueCatApiKey(String platform) {
    String? key;

    // Layer 1: Check Firebase Remote Config (Production Standard)
    if (_remoteConfigService != null) {
      final remoteKey = _remoteConfigService!.getRevenueCatApiKey(platform);
      if (remoteKey.isNotEmpty && 
          remoteKey != 'YOUR_REVENUECAT_API_KEY' &&
          !remoteKey.contains('your_production')) {
        key = remoteKey;
        if (kDebugMode) {
          debugPrint('🔑 Using RevenueCat key from Firebase Remote Config for $platform');
        }
      }
    }

    // Layer 2: Fallback to .env file (Development Support)
    if (key == null || key.isEmpty) {
      String envVarName = 'REVENUECAT_GOOGLE_API_KEY';
      if (platform == 'ios') {
        envVarName = 'REVENUECAT_APPLE_API_KEY';
      } else if (platform == 'web') {
        envVarName = 'REVENUECAT_WEB_API_KEY';
      }

      final envKey = dotenv.isInitialized ? dotenv.maybeGet(envVarName) : null;
      if (envKey != null && 
          envKey.isNotEmpty && 
          envKey != 'YOUR_REVENUECAT_API_KEY' &&
          !envKey.contains('your_production')) {
        key = envKey;
        if (kDebugMode) {
          debugPrint('🔑 Using RevenueCat key from .env file for $platform');
        }
      }
    }

    // Layer 3: Fallback to compile-time variables (--dart-define)
    if (key == null || key.isEmpty) {
      String? defineKey;
      if (platform == 'android') {
        defineKey = revenuecatGoogleApiKey;
      } else if (platform == 'ios') {
        defineKey = revenuecatAppleApiKey;
      } else if (platform == 'web') {
        defineKey = const String.fromEnvironment('REVENUECAT_WEB_API_KEY');
      }
      
      if (defineKey != null && defineKey.isNotEmpty) {
        key = defineKey;
        if (kDebugMode) {
          debugPrint('🔑 Using RevenueCat key from --dart-define for $platform');
        }
      }
    }

    if (key != null && key.isNotEmpty) {
      // SECURITY: Prevent test keys in production
      if (isProduction && key.startsWith('test_')) {
        throw Exception(
          'SECURITY VIOLATION: Test RevenueCat API key detected in production build.',
        );
      }
      return key;
    }

    // SECURITY: Fail fast if key is missing (production only)
    if (isProduction) {
      throw Exception(
        'RevenueCat API key not configured for $platform.',
      );
    }

    // In development, allow app to continue without RevenueCat
    debugPrint('⚠️ RevenueCat API key not configured for $platform - monetization disabled');
    return '';
  }

  static String getAdUnitId(String type, String platform) {
    if (isDevelopment) {
      return _getTestAdUnitId(type, platform);
    }

    if (_remoteConfigService != null) {
      final key = _remoteConfigService!.getString('ad_unit_${type}_$platform');
      if (key.isNotEmpty) return key;
    }
    
    // Fallback production IDs if Remote Config fails
    if (platform == 'android') {
      return {
        'banner': 'ca-app-pub-5049162599848475/3295552257',
        'interstitial': 'ca-app-pub-5049162599848475/7186785099',
        'rewarded': 'ca-app-pub-5049162599848475/1076583020',
      }[type] ?? '';
    }
    return ''; // Add iOS production IDs here when available
  }

  static String _getTestAdUnitId(String type, String platform) {
    if (platform == 'android') {
      return {
        'banner': 'ca-app-pub-3940256099942544/6300978111',
        'interstitial': 'ca-app-pub-3940256099942544/1033173712',
        'rewarded': 'ca-app-pub-3940256099942544/5224354917',
      }[type] ?? '';
    } else if (platform == 'ios') {
      return {
        'banner': 'ca-app-pub-3940256099942544/2934735716',
        'interstitial': 'ca-app-pub-3940256099942544/4411468910',
        'rewarded': 'ca-app-pub-3940256099942544/1712485313',
      }[type] ?? '';
    }
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
      // RevenueCat keys resolved via multi-layer fallback
      final googleKey = getRevenueCatApiKey('android');
      final appleKey = getRevenueCatApiKey('ios');
      final webKey = getRevenueCatApiKey('web');
      AppLogger.i(
        '  RevenueCat Google Key resolved: ${googleKey.isNotEmpty}',
      );
      AppLogger.i(
        '  RevenueCat Apple Key resolved: ${appleKey.isNotEmpty}',
      );
      AppLogger.i(
        '  RevenueCat Web Key resolved: ${webKey.isNotEmpty}',
      );
      AppLogger.i('  Firebase App Check enabled: $enableFirebaseAppCheck');
      AppLogger.i('  SSL Pinning enabled: $enableSslPinning');
      AppLogger.i('  Rate Limiting enabled: $enableRateLimiting');
    }
  }
}
