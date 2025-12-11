import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:emerge_app/core/config/app_config.dart';

class SecureHttpClient extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    if (!AppConfig.enableSslPinning) {
      return super.createHttpClient(context);
    }

    final client = super.createHttpClient(context);

    // Set timeouts
    client.connectionTimeout = const Duration(seconds: 30);
    client.idleTimeout = const Duration(minutes: 1);

    // Configure security settings
    client.badCertificateCallback = (cert, host, port) {
      if (kDebugMode) {
        print('Bad certificate callback for $host:$port');
        print('Certificate: ${cert.subject}');
      }

      // In development, you might want to be more lenient
      if (kDebugMode) {
        return _isLocalhostOrDevelopment(host);
      }

      // In production, implement proper certificate pinning
      return _validateCertificatePin(cert, host);
    };

    // Enable certificate revocation checking
    if (!kDebugMode) {
      // In production, you might want to enable this
      // client.badCertificateCallback = null;
    }

    return client;
  }

  bool _isLocalhostOrDevelopment(String host) {
    // Allow localhost and development certificates in debug mode
    return host == 'localhost' ||
           host == '127.0.0.1' ||
           host.endsWith('.local') ||
           host.contains('ngrok') ||
           host.contains('expo');
  }

  bool _validateCertificatePin(X509Certificate? cert, String host) {
    if (cert == null) return false;

    // List of expected certificate hashes for your Firebase services
    final Map<String, List<String>> certificatePins = {
      'firebase.googleapis.com': [
        'YOUR_FIREBASE_CERTIFICATE_HASH_1',
        'YOUR_FIREBASE_CERTIFICATE_HASH_2',
      ],
      'firebasestorage.googleapis.com': [
        'YOUR_STORAGE_CERTIFICATE_HASH_1',
        'YOUR_STORAGE_CERTIFICATE_HASH_2',
      ],
      'www.googleapis.com': [
        'YOUR_GOOGLE_APIS_CERTIFICATE_HASH_1',
        'YOUR_GOOGLE_APIS_CERTIFICATE_HASH_2',
      ],
    };

    // Get the expected pins for this host
    final expectedPins = certificatePins[host];
    if (expectedPins == null || expectedPins.isEmpty) {
      if (kDebugMode) {
        print('No certificate pins configured for $host');
      }
      return false;
    }

    // Calculate the certificate's SHA-256 hash
    final certHash = _calculateCertificateHash(cert);

    // Check if the certificate hash matches any of the expected pins
    final isValidPin = expectedPins.any((pin) => pin == certHash);

    if (kDebugMode) {
      print('Certificate pin validation for $host: $isValidPin');
      if (!isValidPin) {
        print('Expected pins: ${expectedPins.join(', ')}');
        print('Actual pin: $certHash');
      }
    }

    return isValidPin;
  }

  String _calculateCertificateHash(X509Certificate cert) {
    // This is a simplified implementation
    // In production, you should use proper cryptographic libraries
    final bytes = cert.der;
    final hash = _sha256(bytes);
    return hash.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  }

  List<int> _sha256(List<int> input) {
    // This is a placeholder - use a proper crypto library in production
    // like 'crypto' package or platform-specific implementations
    return input; // Replace with actual SHA-256 implementation
  }
}

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
    final packageInfo = Platform.isIOS ? 'iOS' : 'Android';
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

    // Remove sensitive headers that shouldn't be sent
    sanitized.remove('authorization');
    sanitized.remove('cookie');
    sanitized.remove('x-api-key');
    sanitized.remove('x-auth-token');

    // Add security headers
    sanitized.addAll(securityHeaders);

    return sanitized;
  }
}