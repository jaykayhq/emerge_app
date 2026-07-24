import 'package:emerge_app/core/deletion/sync_status.dart';
import 'package:emerge_app/core/utils/app_logger.dart';

/// Structured, security-grade audit logging for deletion operations.
class DeletionAudit {
  final SyncMetrics _metrics;
  final void Function(Map<String, dynamic> event)? _onEvent;

  DeletionAudit({
    SyncMetrics? metrics,
    void Function(Map<String, dynamic>)? onEvent,
  })  : _metrics = metrics ?? SyncMetrics(),
        _onEvent = onEvent;

  SyncMetrics get metrics => _metrics;

  void log({
    required String op,
    required String target,
    required String outcome,
    int? durationMs,
    int attempt = 1,
    String? habitId,
    String? uid,
    String? error,
  }) {
    final event = <String, dynamic>{
      'op': op,
      'target': target,
      'outcome': outcome,
      if (durationMs != null) 'durationMs': durationMs,
      'attempt': attempt,
      if (habitId != null) 'habitId': habitId,
      if (uid != null) 'uid': uid,
      if (error != null) 'error': error,
      'timestamp': DateTime.now().toIso8601String(),
    };
    // Account-level deletions are security events → Crashlytics in prod.
    if (op == 'deleteAccount') {
      AppLogger.security(
        '[DELETION] $op $outcome',
        context: {'target': target, 'uid': uid, 'outcome': outcome},
      );
    } else {
      AppLogger.i('[DELETION] $op $outcome (${durationMs ?? 0}ms)');
    }
    _onEvent?.call(event);
  }
}
