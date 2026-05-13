import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/core/drift/database.dart';
import 'package:emerge_app/core/drift/daos/mutation_queue_dao.dart';
import 'package:flutter/foundation.dart';

class EnhancedSyncEngine {
  final MutationQueueDao _mutationQueue;
  final FirebaseFirestore _firestore;

  EnhancedSyncEngine(this._mutationQueue, this._firestore);

  Future<void> processMutationQueue() async {
    final mutations = await _mutationQueue.getAllPending();
    if (mutations.isEmpty) {
      debugPrint('SyncEngine: No pending mutations.');
      return;
    }

    debugPrint('SyncEngine: Processing ${mutations.length} mutations...');

    for (final mutation in mutations) {
      final success = await _applyMutation(mutation);
      if (success) {
        await _mutationQueue.deleteProcessed(mutation.id);
        debugPrint('SyncEngine: Synced mutation ${mutation.id}');
      } else {
        await _mutationQueue.incrementRetry(mutation.id);
        if (mutation.retryCount >= 3) {
          debugPrint('SyncEngine: Dropping mutation ${mutation.id} after 3 retries');
          await _mutationQueue.deleteProcessed(mutation.id);
        }
        break;
      }
    }
  }

  Future<bool> _applyMutation(MutationQueueTableData mutation) async {
    try {
      final ref = _firestore.collection(mutation.collectionPath).doc(mutation.documentId);
      final data = mutation.dataJson != null
          ? Map<String, dynamic>.from(jsonDecode(mutation.dataJson!) as Map)
          : <String, dynamic>{};

      switch (mutation.operation) {
        case 'set':
          _convertTimestamps(data);
          await ref.set(data, SetOptions(merge: true));
          break;
        case 'update':
          _convertTimestamps(data);
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
      debugPrint('SyncEngine: Error applying mutation: $e');
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
