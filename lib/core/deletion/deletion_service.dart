import 'dart:async';

import 'package:emerge_app/core/deletion/deletion_audit.dart';
import 'package:emerge_app/core/deletion/delete_account_backend.dart';
import 'package:emerge_app/core/drift/database.dart';
import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/core/sync/sync_engine.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';

/// Single owner of deletion logic for both habit and account deletes.
class DeletionService {
  final AppDatabase _db;
  final EnhancedSyncEngine _syncEngine;
  final DeletionAudit _audit;

  DeletionService({
    required AppDatabase db,
    required EnhancedSyncEngine syncEngine,
    required DeletionAudit audit,
  }) : _db = db,
       _syncEngine = syncEngine,
       _audit = audit;

  Future<Either<Failure, Unit>> deleteHabit({
    required String userId,
    required String habitId,
  }) async {
    final sw = Stopwatch()..start();
    try {
      final existing = await _db.habitsDao.getHabit(habitId);
      if (existing == null) {
        return const Left(ServerFailure('Habit not found'));
      }
      if (existing.isArchived == 1) {
        // A prior attempt may have archived locally but failed at the remote
        // enqueue, leaving the remote habit doc alive. Re-enqueue the delete
        // so the retry self-heals; the idempotency key dedupes against a
        // mutation the first attempt already queued.
        try {
          await _syncEngine.enqueueMutation(
            collectionPath: 'habits',
            documentId: habitId,
            operation: 'delete',
            idempotencyKey: 'del:habit:$habitId',
          );
        } catch (e) {
          // Best-effort: the row is already archived locally, so this is
          // still an idempotent success.
          debugPrint(
            'Failed to re-enqueue delete for archived habit $habitId: $e',
          );
        }
        _audit.log(
          op: 'deleteHabit',
          target: 'habit',
          habitId: habitId,
          outcome: 'noop',
          durationMs: sw.elapsedMilliseconds,
        );
        return const Right(unit); // idempotent
      }
      final completions = await _db.transaction(() async {
        // Capture the ids BEFORE the cascade so they can be mirrored remotely.
        final rows = await _db.habitCompletionsDao.getByHabitId(
          habitId,
          userId,
        );
        await _db.habitsDao.archiveHabit(habitId);
        await _db.habitCompletionsDao.deleteByHabitId(habitId, userId);
        return rows;
      });
      // Mirror the completion cascade remotely FIRST so a failure on the
      // habit-doc enqueue below cannot strand the remote history: the local
      // ids are already gone after the archive, so a later retry would be a
      // no-op. Best-effort: a stale completion doc is a hygiene issue, not a
      // leak.
      for (final c in completions) {
        try {
          await _syncEngine.enqueueMutation(
            collectionPath: 'users/$userId/habit_completions',
            documentId: c.id,
            operation: 'delete',
            idempotencyKey: 'del:completion:${c.id}',
          );
        } catch (e) {
          debugPrint(
            'Failed to enqueue remote deletion of completion ${c.id}: $e',
          );
        }
      }
      try {
        // Habits live in the TOP-LEVEL `habits` collection (see
        // DriftHabitRepository.createHabit) and firestore.rules allows the
        // owner to delete there. A hard delete is idempotent server-side.
        //
        // If this throws, the completion mirrors above are already queued, so
        // a later retry only needs to recover this delete (see the
        // already-archived branch above, which re-enqueues it).
        await _syncEngine.enqueueMutation(
          collectionPath: 'habits',
          documentId: habitId,
          operation: 'delete',
          idempotencyKey: 'del:habit:$habitId',
        );
      } catch (e) {
        // Local archive already committed; surface the remote failure.
        _audit.log(
          op: 'deleteHabit',
          target: 'habit',
          habitId: habitId,
          outcome: 'error',
          durationMs: sw.elapsedMilliseconds,
          error: e.toString(),
        );
        return Left(ServerFailure('remote enqueue failed: $e'));
      }
      _audit.log(
        op: 'deleteHabit',
        target: 'habit',
        habitId: habitId,
        outcome: 'success',
        durationMs: sw.elapsedMilliseconds,
      );
      return const Right(unit);
    } catch (e) {
      _audit.log(
        op: 'deleteHabit',
        target: 'habit',
        habitId: habitId,
        outcome: 'error',
        durationMs: sw.elapsedMilliseconds,
        error: e.toString(),
      );
      return Left(ServerFailure(e.toString()));
    }
  }

  /// Server-first account deletion: local data is only wiped after the
  /// backend confirms success. The deletionRequestId is durable so retries
  /// after app-kill reuse the SAME id (server dedupes).
  Future<Either<Failure, Unit>> deleteAccount({
    required String userId,
    required DeleteAccountBackend backend,
    required SecureIdStore idStore,
    required FirebaseAuth auth,
  }) async {
    final sw = Stopwatch()..start();
    final id = await idStore.loadOrCreateId('deletionRequestId:$userId');
    final result = await backend.delete(deletionRequestId: id);
    if (result.isLeft()) {
      final msg = result.fold((f) => f.message, (_) => 'error');
      _audit.log(
        op: 'deleteAccount',
        target: 'account',
        uid: userId,
        outcome: 'error',
        durationMs: sw.elapsedMilliseconds,
        error: msg,
      );
      return result; // local data intentionally NOT cleared
    }
    // After backend confirms deletion:
    try {
      await _db.clearAll();
    } catch (e, st) {
      debugPrint('Failed to clear local DB during deletion: $e\n$st');
    }
    try {
      await auth.signOut();
    } catch (e, st) {
      debugPrint('Failed to sign out during deletion: $e\n$st');
    }
    try {
      await idStore.clear('deletionRequestId:$userId');
    } catch (e, st) {
      debugPrint('Failed to clear ID store during deletion: $e\n$st');
    }
    _audit.log(
      op: 'deleteAccount',
      target: 'account',
      uid: userId,
      outcome: 'success',
      durationMs: sw.elapsedMilliseconds,
    );
    return const Right(unit);
  }
}
