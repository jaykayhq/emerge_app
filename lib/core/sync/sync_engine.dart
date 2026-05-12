import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/core/services/local_cache_service.dart';
import 'package:flutter/foundation.dart';

class SyncEngine {
  final FirebaseFirestore _firestore;
  final LocalCacheService _localCache;

  SyncEngine(this._firestore, this._localCache);

  /// Processes all pending mutations in the local cache.
  Future<void> processMutationQueue() async {
    final mutations = _localCache.getMutationQueue();
    if (mutations.isEmpty) {
      debugPrint('SyncEngine: No pending mutations to process.');
      return;
    }

    debugPrint('SyncEngine: Processing ${mutations.length} mutations...');

    // Sort by timestamp to ensure correct order of operations
    final sortedMutations = Map.fromEntries(
      mutations.entries.toList()
        ..sort((a, b) => a.value['timestamp'].compareTo(b.value['timestamp']))
    );

    for (final entry in sortedMutations.entries) {
      final mutationId = entry.key;
      final data = entry.value;

      final bool success = await _applyMutation(data);
      if (success) {
        await _localCache.removeMutation(mutationId);
        debugPrint('SyncEngine: Successfully synced mutation $mutationId');
      } else {
        debugPrint('SyncEngine: Failed to sync mutation $mutationId. Will retry later.');
        // Stop processing on first failure to maintain order if it's a network/auth issue
        break;
      }
    }
  }

  Future<bool> _applyMutation(Map<String, dynamic> mutation) async {
    final String collectionPath = mutation['collectionPath'];
    final String documentId = mutation['documentId'];
    final String operation = mutation['operation'];
    final Map<String, dynamic> data = Map<String, dynamic>.from(mutation['data']);

    try {
      final docRef = _firestore.collection(collectionPath).doc(documentId);

      switch (operation) {
        case 'set':
          _convertDatesToTimestamps(data);
          await docRef.set(data, SetOptions(merge: true));
          break;
        case 'update':
          _convertDatesToTimestamps(data);
          _expandSentinelMarkers(data);
          try {
            await docRef.update(data);
          } on FirebaseException catch (e) {
            if (e.code == 'not-found') {
              // Doc doesn't exist yet (e.g. new user syncing for the first time) — merge instead
              debugPrint('SyncEngine: Doc not found for update, falling back to set+merge.');
              await docRef.set(data, SetOptions(merge: true));
            } else {
              rethrow;
            }
          }
          break;
        case 'delete':
          await docRef.delete();
          break;
        case 'add':
          _convertDatesToTimestamps(data);
          // For 'add', we ignore the documentId and let Firestore generate a new one
          await _firestore.collection(collectionPath).add(data);
          break;
        default:
          debugPrint('SyncEngine: Unknown operation $operation');
          return false;
      }
      return true;
    } catch (e) {
      debugPrint('SyncEngine: Error applying mutation: $e');
      return false;
    }
  }

  /// Converts custom sentinel marker strings back to real Firestore FieldValues.
  ///
  /// This is the companion to [LocalCacheService.enqueueMutation]'s serialization
  /// convention. Keys prefixed with `__arrayUnion_`, `__arrayRemove_`, and
  /// `__increment_` are expanded here before writing to Firestore.
  void _expandSentinelMarkers(Map<String, dynamic> data) {
    final keysToExpand = data.keys
        .where((k) => k.startsWith('__arrayUnion_') || k.startsWith('__arrayRemove_') || k.startsWith('__increment_'))
        .toList();

    for (final key in keysToExpand) {
      final value = data.remove(key);
      if (key.startsWith('__arrayUnion_')) {
        final fieldName = key.replaceFirst('__arrayUnion_', '');
        data[fieldName] = FieldValue.arrayUnion(value as List);
      } else if (key.startsWith('__arrayRemove_')) {
        final fieldName = key.replaceFirst('__arrayRemove_', '');
        data[fieldName] = FieldValue.arrayRemove(value as List);
      } else if (key.startsWith('__increment_')) {
        final fieldName = key.replaceFirst('__increment_', '');
        data[fieldName] = FieldValue.increment(value as num);
      }
    }
  }

  void _convertDatesToTimestamps(Map<String, dynamic> data) {
    data.forEach((key, value) {
      if (value is String) {
        final date = DateTime.tryParse(value);
        if (date != null && value.contains('T') && value.contains('-')) {
          // Heuristic to check if it's an ISO8601 date
          data[key] = Timestamp.fromDate(date);
        }
      } else if (value is Map<String, dynamic>) {
        _convertDatesToTimestamps(value);
      } else if (value is List) {
        for (var i = 0; i < value.length; i++) {
          if (value[i] is Map<String, dynamic>) {
            _convertDatesToTimestamps(value[i]);
          }
        }
      }
    });
  }
}
