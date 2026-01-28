import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

enum SecurityEventType {
  authentication,
  authorization,
  dataAccess,
  networkActivity,
  systemEvent,
  securityViolation,
  suspiciousActivity,
  configuration,
}

enum SecurityEventLevel { info, warning, error, critical }

class SecurityEvent {
  final SecurityEventType type;
  final SecurityEventLevel level;
  final String message;
  final Map<String, dynamic>? details;
  final String? userId;
  final String? sessionId;
  final DateTime timestamp;
  final String? ipAddress;
  final String? userAgent;

  SecurityEvent({
    required this.type,
    required this.level,
    required this.message,
    this.details,
    this.userId,
    this.sessionId,
    DateTime? timestamp,
    this.ipAddress,
    this.userAgent,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString(),
      'level': level.toString(),
      'message': message,
      'details': details,
      'userId': userId,
      'sessionId': sessionId,
      'timestamp': timestamp.toIso8601String(),
      'ipAddress': ipAddress,
      'userAgent': userAgent,
    };
  }

  String toFormattedString() {
    final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    final levelStr = level.toString().split('.').last.toUpperCase();
    final typeStr = type.toString().split('.').last;

    return '[${formatter.format(timestamp)}] $levelStr [$typeStr] $message';
  }
}

class SecurityLogger {
  static final SecurityLogger _instance = SecurityLogger._internal();
  factory SecurityLogger() => _instance;
  SecurityLogger._internal() {
    _initialize();
  }

  final List<SecurityEvent> _events = [];
  final int _maxEventsInMemory = 1000;
  Timer? _flushTimer;
  static const Duration _flushInterval = Duration(minutes: 5);

  void _initialize() {
    // Start periodic flush timer
    _flushTimer?.cancel();
    _flushTimer = Timer.periodic(_flushInterval, (_) => _flushEvents());
  }

  void dispose() {
    _flushTimer?.cancel();
    _flushEvents(); // Final flush
  }

  // Log security events
  void logEvent({
    required SecurityEventType type,
    required SecurityEventLevel level,
    required String message,
    Map<String, dynamic>? details,
    String? userId,
    String? sessionId,
    String? ipAddress,
    String? userAgent,
  }) {
    final event = SecurityEvent(
      type: type,
      level: level,
      message: message,
      details: details,
      userId: userId,
      sessionId: sessionId,
      ipAddress: ipAddress,
      userAgent: userAgent,
    );

    _events.add(event);

    // Keep only recent events in memory
    if (_events.length > _maxEventsInMemory) {
      _events.removeRange(0, _events.length - _maxEventsInMemory);
    }

    // Immediate action for critical events
    if (level == SecurityEventLevel.critical) {
      _handleCriticalEvent(event);
    }

    // Print to console in debug mode
    if (kDebugMode) {
      print(event.toFormattedString());
      if (details != null) {
        print('Details: $details');
      }
    }
  }

  // Convenience methods for common events
  void logAuthenticationSuccess(String userId, {String? sessionId}) {
    logEvent(
      type: SecurityEventType.authentication,
      level: SecurityEventLevel.info,
      message: 'User authentication successful',
      userId: userId,
      sessionId: sessionId,
      details: {'action': 'login_success'},
    );
  }

  void logAuthenticationFailure(
    String email, {
    String? reason,
    String? ipAddress,
  }) {
    logEvent(
      type: SecurityEventType.authentication,
      level: SecurityEventLevel.warning,
      message: 'User authentication failed',
      details: {'email': _sanitizeEmail(email), 'reason': reason ?? 'unknown'},
      ipAddress: ipAddress,
    );
  }

  void logSuspiciousActivity({
    required String activity,
    String? userId,
    Map<String, dynamic>? details,
  }) {
    logEvent(
      type: SecurityEventType.suspiciousActivity,
      level: SecurityEventLevel.warning,
      message: 'Suspicious activity detected: $activity',
      userId: userId,
      details: details,
    );
  }

  void logDataAccess({
    required String resource,
    required String action,
    String? userId,
    bool success = true,
  }) {
    logEvent(
      type: SecurityEventType.dataAccess,
      level: success ? SecurityEventLevel.info : SecurityEventLevel.warning,
      message: 'Data access: $action on $resource',
      userId: userId,
      details: {'resource': resource, 'action': action, 'success': success},
    );
  }

  void logNetworkRequest({
    required String url,
    required String method,
    int? statusCode,
    String? userId,
  }) {
    final level = _getNetworkLogLevel(statusCode);
    logEvent(
      type: SecurityEventType.networkActivity,
      level: level,
      message: 'Network request: $method $url',
      userId: userId,
      details: {
        'url': _sanitizeUrl(url),
        'method': method,
        'statusCode': statusCode,
      },
    );
  }

  void logSecurityViolation({
    required String violation,
    String? userId,
    Map<String, dynamic>? details,
  }) {
    logEvent(
      type: SecurityEventType.securityViolation,
      level: SecurityEventLevel.critical,
      message: 'Security violation: $violation',
      userId: userId,
      details: details,
    );
  }

  void logConfigurationChange({
    required String setting,
    required String oldValue,
    required String newValue,
    String? userId,
  }) {
    logEvent(
      type: SecurityEventType.configuration,
      level: SecurityEventLevel.info,
      message: 'Configuration changed: $setting',
      userId: userId,
      details: {'setting': setting, 'oldValue': oldValue, 'newValue': newValue},
    );
  }

  // Get security statistics
  Map<String, dynamic> getSecurityStats() {
    final now = DateTime.now();
    final last24h = now.subtract(const Duration(hours: 24));
    final last1h = now.subtract(const Duration(hours: 1));

    final recentEvents = _events.where((e) => e.timestamp.isAfter(last24h));
    final criticalEvents = recentEvents.where(
      (e) => e.level == SecurityEventLevel.critical,
    );
    final authFailures = recentEvents.where(
      (e) =>
          e.type == SecurityEventType.authentication &&
          e.level == SecurityEventLevel.warning,
    );
    final suspiciousEvents = recentEvents.where(
      (e) => e.type == SecurityEventType.suspiciousActivity,
    );

    return {
      'totalEvents24h': recentEvents.length,
      'criticalEvents24h': criticalEvents.length,
      'authFailures24h': authFailures.length,
      'suspiciousActivities24h': suspiciousEvents.length,
      'eventsLastHour': _events
          .where((e) => e.timestamp.isAfter(last1h))
          .length,
      'uniqueUsers24h': recentEvents
          .map((e) => e.userId)
          .where((id) => id != null)
          .toSet()
          .length,
    };
  }

  // Get recent events for monitoring dashboard
  List<SecurityEvent> getRecentEvents({int limit = 100}) {
    final sortedEvents = List<SecurityEvent>.from(_events)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sortedEvents.take(limit).toList();
  }

  // Export events for analysis
  String exportEvents({DateTime? startDate, DateTime? endDate}) {
    final filteredEvents = _events.where((event) {
      if (startDate != null && event.timestamp.isBefore(startDate)) {
        return false;
      }
      if (endDate != null && event.timestamp.isAfter(endDate)) {
        return false;
      }
      return true;
    });

    final exportData = {
      'exportedAt': DateTime.now().toIso8601String(),
      'totalEvents': filteredEvents.length,
      'events': filteredEvents.map((e) => e.toJson()).toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(exportData);
  }

  // Private helper methods
  SecurityEventLevel _getNetworkLogLevel(int? statusCode) {
    if (statusCode == null) {
      return SecurityEventLevel.error;
    }

    if (statusCode >= 200 && statusCode < 300) {
      return SecurityEventLevel.info;
    } else if (statusCode >= 400 && statusCode < 500) {
      return SecurityEventLevel.warning;
    } else if (statusCode >= 500) {
      return SecurityEventLevel.error;
    }

    return SecurityEventLevel.warning;
  }

  String _sanitizeEmail(String email) {
    final atIndex = email.indexOf('@');
    if (atIndex <= 2) return '***@***';

    final domain = email.substring(atIndex);
    final prefix = email.substring(0, 2);
    return '$prefix***$domain';
  }

  String _sanitizeUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return '${uri.scheme}://${uri.host}${uri.path}';
    } catch (e) {
      return 'invalid_url';
    }
  }

  void _handleCriticalEvent(SecurityEvent event) {
    // In a production app, this would:
    // 1. Send immediate alerts to security team
    // 2. Trigger automated security responses
    // 3. Create high-priority tickets

    if (kDebugMode) {
      print('🚨 CRITICAL SECURITY EVENT: ${event.message}');
      print('Details: ${event.details}');
    }

    // Implement alert sending logic here
    _sendSecurityAlert(event);
  }

  void _sendSecurityAlert(SecurityEvent event) {
    // Placeholder for sending alerts
    // This could integrate with:
    // - Email services
    // - Slack/Discord webhooks
    // - SMS services
    // - PagerDuty
    // - Custom alerting systems

    if (kDebugMode) {
      print('Security alert sent for: ${event.message}');
    }
  }

  Future<void> _flushEvents() async {
    if (_events.isEmpty) return;

    try {
      // In production, this would send events to:
      // - Security information and event management (SIEM) system
      // - Log aggregation service (ELK, Splunk, etc.)
      // - Security analytics platform
      // - External monitoring service

      final eventsToFlush = List<SecurityEvent>.from(_events);
      _events.clear();

      if (kDebugMode) {
        print('Flushed ${eventsToFlush.length} security events');
      }

      // Implement actual flushing logic here
      await _sendToLogAggregator(eventsToFlush);
    } catch (e) {
      if (kDebugMode) {
        print('Error flushing security events: $e');
      }
    }
  }

  Future<void> _sendToLogAggregator(List<SecurityEvent> events) async {
    // Placeholder for sending to log aggregator
    // This would typically be an HTTP request to your logging service
    if (kDebugMode) {
      print('Would send ${events.length} events to log aggregator');
    }
  }
}
