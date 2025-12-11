import 'package:flutter/foundation.dart';

class AppConfig {
  // Environment Configuration
  static const String _environment = String.fromEnvironment('FLUTTER_ENV', defaultValue: 'development');
  static bool get isDevelopment => _environment == 'development';
  static bool get isProduction => _environment == 'production';

  // Firebase Configuration
  static const String firebaseApiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const String firebaseProjectId = String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: 'tradeflash-l2966');
  static const String firebaseStorageBucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET', defaultValue: 'tradeflash-l2966.firebasestorage.app');

  // RevenueCat Configuration
  static const String revenuecatGoogleApiKey = String.fromEnvironment('REVENUECAT_GOOGLE_API_KEY');
  static const String revenuecatAppleApiKey = String.fromEnvironment('REVENUECAT_APPLE_API_KEY');

  // Security Configuration
  static const bool enableFirebaseAppCheck = bool.fromEnvironment('ENABLE_FIREBASE_APP_CHECK', defaultValue: false);
  static const bool enableSslPinning = bool.fromEnvironment('ENABLE_SSL_PINNING', defaultValue: false);
  static const bool enableRateLimiting = bool.fromEnvironment('ENABLE_RATE_LIMITING', defaultValue: true);

  // Validate required configuration
  static bool get isValidConfig {
    if (isProduction) {
      return firebaseApiKey.isNotEmpty &&
             revenuecatGoogleApiKey.isNotEmpty &&
             revenuecatAppleApiKey != 'YOUR_REVENUECAT_APPLE_API_KEY';
    }
    return true; // Allow defaults in development
  }

  // Get API key with fallback for development
  static String getRevenueCatApiKey(String platform) {
    if (platform == 'android') {
      return isDevelopment && revenuecatGoogleApiKey.isEmpty
          ? 'test_sauiTQOmjONwFQcHUOvQVVwNavV' // Test key for development only
          : revenuecatGoogleApiKey;
    } else if (platform == 'ios') {
      return revenuecatAppleApiKey;
    }
    throw ArgumentError('Unsupported platform: $platform');
  }

  // Log configuration status (without exposing keys)
  static void logConfigurationStatus() {
    if (kDebugMode) {
      print('App Configuration:');
      print('  Environment: $_environment');
      print('  Firebase API Key configured: ${firebaseApiKey.isNotEmpty}');
      print('  RevenueCat Google Key configured: ${revenuecatGoogleApiKey.isNotEmpty}');
      print('  RevenueCat Apple Key configured: ${revenuecatAppleApiKey.isNotEmpty && revenuecatAppleApiKey != 'YOUR_REVENUECAT_APPLE_API_KEY'}');
      print('  Firebase App Check enabled: $enableFirebaseAppCheck');
      print('  SSL Pinning enabled: $enableSslPinning');
      print('  Rate Limiting enabled: $enableRateLimiting');
    }
  }
}