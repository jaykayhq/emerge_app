import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/core/drift/database.dart';
import 'package:emerge_app/core/utils/app_logger.dart';

class EnhancedSyncEngine {
  final MutationQueueDao _mutationQueue;
  final FirebaseFirestore _firestore;
  bool _isProcessing = false;

  EnhancedSyncEngine(this._mutationQueue, this._firestore);

  Future<void> processMutationQueue() async {
    if (_isProcessing) {
      AppLogger.d('SyncEngine: Already processing, skipping');
      return;
    }
    _isProcessing = true;
    try {
      final mutations = await _mutationQueue.getAllPending();
      if (mutations.isEmpty) {
        AppLogger.d('SyncEngine: No pending mutations.');
        return;
      }

      AppLogger.d('SyncEngine: Processing ${mutations.length} mutations...');

      for (final mutation in mutations) {
        final success = await _applyMutation(mutation);
        if (success) {
          await _mutationQueue.deleteProcessed(mutation.id);
          AppLogger.d('SyncEngine: Synced mutation ${mutation.id}');
        } else {
          await _mutationQueue.incrementRetry(mutation.id);
          if (mutation.retryCount >= 3) {
            AppLogger.d(
              'SyncEngine: Dropping mutation ${mutation.id} after 3 retries',
            );
            await _mutationQueue.deleteProcessed(mutation.id);
          }
          AppLogger.d(
            'SyncEngine: Mutation ${mutation.id} failed, continuing to next',
          );
          continue;
        }
      }
    } finally {
      _isProcessing = false;
    }
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
        if (date != null) {
          data[key] = Timestamp.fromDate(date);
        }
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

  Future<void> enqueueMutation({
    required String collectionPath,
    required String documentId,
    required String operation,
    Map<String, dynamic>? data,
  }) async {
    await _mutationQueue.enqueue(
      collectionPath: collectionPath,
      documentId: documentId,
      operation: operation,
      dataJson: data != null ? jsonEncode(data) : null,
    );
  }

  Future<void> enqueueSet({
    required String collectionPath,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    await enqueueMutation(
      collectionPath: collectionPath,
      documentId: documentId,
      operation: 'set',
      data: data,
    );
  }

  Future<void> enqueueUpdate({
    required String collectionPath,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    await enqueueMutation(
      collectionPath: collectionPath,
      documentId: documentId,
      operation: 'update',
      data: data,
    );
  }
}
