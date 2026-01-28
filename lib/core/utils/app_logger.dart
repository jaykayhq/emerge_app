import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// ENHANCED: Structured logging utility with PII redaction for production safety.
///
/// Security Features:
/// - PII (Personally Identifiable Information) redaction
/// - Debug-only console output
/// - Production logging to Firebase Crashlytics
/// - Structured log levels (DEBUG, INFO, WARNING, ERROR)
class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 50,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.none,
    ),
  );

  /// ENHANCED: Redact sensitive information from log messages
  ///
  /// Removes:
  /// - Email addresses
  /// - API tokens and keys (32+ character alphanumeric strings)
  /// - Credit card numbers (16 digits)
  /// - Phone numbers
  /// - Firebase project IDs
  static String _redactPii(String message) {
    // Redact email addresses
    message = message.replaceAll(
      RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'),
      '***@***.***',
    );

    // Redact API tokens/keys (32+ character alphanumeric strings)
    message = message.replaceAll(
      RegExp(r'\b[A-Za-z0-9]{32,}\b'),
      '***REDACTED_TOKEN***',
    );

    // Redact potential credit card numbers (16 digits, optionally with spaces/dashes)
    message = message.replaceAll(
      RegExp(r'\b\d{4}[-\s]?\d{4}[-\s]?\d{4}[-\s]?\d{4}\b'),
      '****-****-****-****',
    );

    // Redact phone numbers (various formats)
    message = message.replaceAll(
      RegExp(r'\b\+?(\d{1,3}[-\s]?)?\(?\d{3}\)?[-\s]?\d{3}[-\s]?\d{4}\b'),
      '***-***-****',
    );

    // Redact Firebase project IDs
    message = message.replaceAll(
      RegExp(r'\b[A-Za-z0-9-]{20,}\.firebaseapp\.com\b'),
      '***.firebaseapp.com',
    );

    // Redact query parameters with sensitive data
    message = message.replaceAll(
      RegExp(r'[?&](token|key|password|api_key|access_token|secret)=[^&\s]*', caseSensitive: false),
      '',
    );

    return message;
  }

  /// Debug level log - only shown in debug mode (with PII redaction)
  static void d(String message, {Object? error, StackTrace? stackTrace}) {
    final redacted = _redactPii(message);

    if (kDebugMode) {
      _logger.d(redacted, error: error, stackTrace: stackTrace);
    }
  }

  /// Info level log - shown in debug mode, sent to Crashlytics in production (with PII redaction)
  static void i(String message, {Object? error, StackTrace? stackTrace}) {
    final redacted = _redactPii(message);

    if (kDebugMode) {
      _logger.i(redacted, error: error, stackTrace: stackTrace);
    } else if (!kIsWeb) {
      // In production, send to Crashlytics
      FirebaseCrashlytics.instance.log(redacted);
    }
  }

  /// Warning level log - shown in debug mode, sent to Crashlytics in production (with PII redaction)
  static void w(String message, {Object? error, StackTrace? stackTrace}) {
    final redacted = _redactPii(message);

    if (kDebugMode) {
      _logger.w(redacted, error: error, stackTrace: stackTrace);
    } else if (!kIsWeb) {
      // In production, send to Crashlytics as non-fatal
      FirebaseCrashlytics.instance.log('[WARNING] $redacted');
      if (error != null) {
        FirebaseCrashlytics.instance.recordError(
          error,
          stackTrace,
          fatal: false,
        );
      }
    }
  }

  /// Error level log - always shown, sent to Crashlytics in production (with PII redaction)
  static void e(String message, [dynamic error, StackTrace? stackTrace]) {
    final redacted = _redactPii(message);

    if (kDebugMode) {
      _logger.e(redacted, error: error, stackTrace: stackTrace);
    }

    if (!kIsWeb) {
      // In production, send to Crashlytics as non-fatal error
      FirebaseCrashlytics.instance.log('[ERROR] $redacted');
      if (error != null || stackTrace != null) {
        FirebaseCrashlytics.instance.recordError(
          error ?? Exception(message),
          stackTrace,
          fatal: false,
          information: ['Message: $redacted'],
        );
      }
    }
  }

  /// ENHANCED: Log security event (always sent to Crashlytics with PII redaction)
  ///
  /// Usage: `AppLogger.security('Failed login attempt', {'email': email})`
  static void security(String event, {Map<String, dynamic>? context}) {
    final redactedEvent = _redactPii(event);
    final redactedContext = context?.map((key, value) =>
        MapEntry(key, _redactPii(value.toString())));

    if (kDebugMode) {
      _logger.w('🔒 $redactedEvent ${redactedContext != null ? "- $redactedContext" : ""}');
    } else if (!kIsWeb) {
      // Always log security events to Crashlytics
      FirebaseCrashlytics.instance.log(
        '[SECURITY] $redactedEvent ${redactedContext != null ? "- $redactedContext" : ""}',
      );
    }
  }

  /// ENHANCED: Log network request (with URL redaction)
  ///
  /// Usage: `AppLogger.networkRequest('GET', 'https://api.example.com/users', statusCode: 200)`
  static void networkRequest(String method, String url, {int? statusCode}) {
    // Redact query parameters that might contain sensitive data
    final redactedUrl = url.replaceAll(
      RegExp(r'[?&](token|key|password|api_key|access_token)=[^&]*', caseSensitive: false),
      '',
    );

    final status = statusCode != null ? ' - Status: $statusCode' : '';
    i('🌐 $method $redactedUrl$status');
  }

  /// ENHANCED: Log performance metric
  ///
  /// Usage: `AppLogger.performance('Database query', Duration(milliseconds: 150))`
  static void performance(String operation, Duration duration) {
    final millis = duration.inMilliseconds;
    final redactedOp = _redactPii(operation);

    if (millis > 1000) {
      w('⏱️  SLOW: $redactedOp took ${duration.inSeconds}s');
    } else {
      d('⏱️  $redactedOp took ${millis}ms');
    }
  }
}
