import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:emerge_app/core/config/app_config.dart';

/// Network security configuration for the Emerge app
///
/// NOTE: SSL certificate pinning has been removed in favor of Firebase App Check,
/// which provides better security with zero maintenance overhead.
/// App Check automatically verifies app authenticity using Play Integrity API.
class NetworkSecurityConfig {
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration longTimeout = Duration(minutes: 2);
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 1);

  // Security headers to add to outgoing requests
  static const Map<String, String> securityHeaders = {
    'X-Content-Type-Options': 'nosniff',
    'X-Frame-Options': 'DENY',
    'X-XSS-Protection': '1; mode=block',
    'Strict-Transport-Security': 'max-age=31536000; includeSubDomains',
    'Referrer-Policy': 'strict-origin-when-cross-origin',
    'Content-Security-Policy': "default-src 'self'",
  };

  // User agent string for API requests
  static String get userAgent {
    final packageInfo = kIsWeb
        ? 'Web'
        : Platform.isIOS
        ? 'iOS'
        : 'Android';
    final version = '1.0.0'; // Get from package_info_plus
    return 'EmergeApp/$packageInfo/$version';
  }

  // Validate URL is safe for requests
  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);

      // Only allow HTTPS in production
      if (!AppConfig.isDevelopment && uri.scheme != 'https') {
        return false;
      }

      // Block localhost in production
      if (!AppConfig.isDevelopment &&
          (uri.host == 'localhost' || uri.host == '127.0.0.1')) {
        return false;
      }

      // Allow specific domains
      final allowedDomains = [
        'firebase.googleapis.com',
        'firebasestorage.googleapis.com',
        'www.googleapis.com',
        'accounts.google.com',
        'revenuecat.com',
        'api.revenuecat.com',
        'pollinations.ai',
        'image.pollinations.ai',
      ];

      if (allowedDomains.any((domain) => uri.host.endsWith(domain))) {
        return true;
      }

      // Allow development-specific domains
      if (AppConfig.isDevelopment &&
          (uri.host.contains('ngrok') || uri.host.contains('expo'))) {
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  // Sanitize request headers to remove sensitive information
  static Map<String, String> sanitizeHeaders(Map<String, String> headers) {
    final sanitized = Map<String, String>.from(headers);

    // Remove sensitive headers that shouldn't be logged
    sanitized.remove('authorization');
    sanitized.remove('cookie');
    sanitized.remove('x-api-key');
    sanitized.remove('x-auth-token');

    return sanitized;
  }

  // Add security headers to requests
  static Map<String, String> addSecurityHeaders(Map<String, String> headers) {
    final withSecurity = Map<String, String>.from(headers);
    withSecurity.addAll(securityHeaders);
    return withSecurity;
  }
}
