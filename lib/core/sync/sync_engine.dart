import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/core/deletion/sync_status.dart';
import 'package:emerge_app/core/drift/database.dart';
import 'package:emerge_app/core/utils/app_logger.dart';

/// Applies a single queued mutation; returns true on success.
typedef MutationApplier = Future<bool> Function(MutationQueueTableData);

class EnhancedSyncEngine {
  final MutationQueueDao _mutationQueue;
  final FirebaseFirestore _firestore;
  final SyncMetrics _metrics;
  final MutationApplier? applier;

  final int maxRetries;
  final int breakerThreshold;
  final Duration baseBackoff;
  final Duration capBackoff;

  final StreamController<SyncStatus> _statusController =
      StreamController<SyncStatus>.broadcast();
  SyncStatus _status = SyncStatus.idle;
  int _consecutiveFailures = 0;
  bool _isProcessing = false;

  EnhancedSyncEngine(
    this._mutationQueue,
    this._firestore, {
    SyncMetrics? metrics,
    this.applier,
    this.maxRetries = 5,
    this.breakerThreshold = 5,
    this.baseBackoff = const Duration(seconds: 1),
    Duration? maxBackoff,
  })  : _metrics = metrics ?? SyncMetrics(),
        capBackoff = maxBackoff ?? const Duration(minutes: 5);

  SyncMetrics get metrics => _metrics;

  Stream<SyncStatus> get status => _statusController.stream;

  SyncStatus get currentStatus => _status;

  void _setStatus(SyncStatus s) {
    if (_status != s) {
      _status = s;
      _statusController.add(s);
    }
  }

  Future<void> enqueueMutation({
    required String collectionPath,
    required String documentId,
    required String operation,
    Map<String, dynamic>? data,
    String? idempotencyKey,
  }) async {
    _metrics.recordEnqueued();
    await _mutationQueue.enqueue(
      collectionPath: collectionPath,
      documentId: documentId,
      operation: operation,
      dataJson: data != null ? jsonEncode(data) : null,
      idempotencyKey: idempotencyKey,
    );
  }

  Future<void> enqueueSet({
    required String collectionPath,
    required String documentId,
    required Map<String, dynamic> data,
  }) =>
      enqueueMutation(
        collectionPath: collectionPath,
        documentId: documentId,
        operation: 'set',
        data: data,
      );

  Future<void> enqueueUpdate({
    required String collectionPath,
    required String documentId,
    required Map<String, dynamic> data,
    String? idempotencyKey,
  }) =>
      enqueueMutation(
        collectionPath: collectionPath,
        documentId: documentId,
        operation: 'update',
        data: data,
        idempotencyKey: idempotencyKey,
      );

  Future<void> processMutationQueue() async {
    if (_isProcessing) {
      AppLogger.d('SyncEngine: Already processing, skipping');
      return;
    }
    _isProcessing = true;
    _setStatus(SyncStatus.processing);
    final sw = Stopwatch()..start();
    try {
      final nowIso = DateTime.now().toIso8601String();
      final mutations = await _mutationQueue.getDue(nowIso);
      _metrics.queueDepth = mutations.length;
      for (final mutation in mutations) {
        final ok = applier != null
            ? await applier!(mutation)
            : await _applyMutation(mutation);
        if (ok) {
          await _mutationQueue.deleteProcessed(mutation.id);
          _metrics.recordSucceeded();
          _consecutiveFailures = 0;
          _metrics.consecutiveFailures = 0;
          AppLogger.d('SyncEngine: Synced mutation ${mutation.id}');
        } else {
          _metrics.recordFailed();
          _consecutiveFailures++;
          _metrics.consecutiveFailures = _consecutiveFailures;
          final nextCount = mutation.retryCount + 1;
          final nextRetry = _backoff(nextCount);
          final status = nextCount >= maxRetries ? 'dead' : 'pending';
          if (status == 'dead') _metrics.recordDeadLettered();
          await _mutationQueue.markFailed(
            id: mutation.id,
            retryCount: nextCount,
            lastError: 'apply failed',
            nextRetryAt: nextRetry.toIso8601String(),
            status: status,
          );
          AppLogger.w('SyncEngine: Mutation ${mutation.id} failed '
              '(attempt $nextCount/$maxRetries) -> $status');
        }
      }
      _setStatus(_consecutiveFailures >= breakerThreshold
          ? SyncStatus.degraded
          : SyncStatus.idle);
    } catch (e) {
      AppLogger.e('SyncEngine: processing error', e);
      _setStatus(SyncStatus.degraded);
    } finally {
      _metrics.lastProcessingMs = sw.elapsedMilliseconds;
      _isProcessing = false;
    }
  }

  DateTime _backoff(int retryCount) {
    final exp = baseBackoff * (1 << (retryCount - 1));
    final clamped = exp > capBackoff ? capBackoff : exp;
    return DateTime.now().add(clamped);
  }

  /// Re-enqueue dead-letter rows for another attempt.
  Future<void> resetDeadLetters() async {
    await _mutationQueue.resetDeadToPending();
    _consecutiveFailures = 0;
    _metrics.consecutiveFailures = 0;
    _setStatus(SyncStatus.idle);
  }

  /// Legacy alias: revive dead letters and immediately reprocess.
  Future<void> retryDeadLetter() async {
    await resetDeadLetters();
    await processMutationQueue();
  }

  Future<bool> _applyMutation(MutationQueueTableData mutation) async {
    try {
      final ref = _firestore
          .collection(mutation.collectionPath)
          .doc(mutation.documentId);
      final data = mutation.dataJson != null
          ? Map<String, dynamic>.from(jsonDecode(mutation.dataJson!) as Map)
          : <String, dynamic>{};
      switch (mutation.operation) {
        case 'set':
          _convertTimestamps(data);
          _processMarkers(data);
          await ref.set(data, SetOptions(merge: true));
          break;
        case 'update':
          _convertTimestamps(data);
          _processMarkers(data);
          await ref.update(data);
          break;
        case 'delete':
          await ref.delete();
          break;
        default:
          return false;
      }
      return true;
    } catch (e) {
      AppLogger.d('SyncEngine: Error applying mutation: $e');
      return false;
    }
  }

  void _convertTimestamps(Map<String, dynamic> data) {
    data.forEach((key, value) {
      if (value is String && value.contains('T') && value.contains('-')) {
        final date = DateTime.tryParse(value);
        if (date != null) data[key] = Timestamp.fromDate(date);
      } else if (value is Map<String, dynamic>) {
        _convertTimestamps(value);
      } else if (value is List) {
        for (var i = 0; i < value.length; i++) {
          if (value[i] is Map<String, dynamic>) {
            _convertTimestamps(value[i] as Map<String, dynamic>);
          }
        }
      }
    });
  }

  void _processMarkers(Map<String, dynamic> data) {
    final keysToUpdate = <String, dynamic>{};
    data.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        if (value.containsKey('__type__')) {
          final type = value['__type__'];
          if (type == 'increment') {
            keysToUpdate[key] = FieldValue.increment(value['value'] as num);
          } else if (type == 'serverTimestamp') {
            keysToUpdate[key] = FieldValue.serverTimestamp();
          } else if (type == 'arrayUnion') {
            keysToUpdate[key] = FieldValue.arrayUnion(value['values'] as List);
          } else if (type == 'arrayRemove') {
            keysToUpdate[key] = FieldValue.arrayRemove(value['values'] as List);
          }
        } else {
          _processMarkers(value);
        }
      } else if (value is List) {
        for (var i = 0; i < value.length; i++) {
          if (value[i] is Map<String, dynamic>) {
            _processMarkers(value[i] as Map<String, dynamic>);
          }
        }
      }
    });
    data.addAll(keysToUpdate);
  }
}
