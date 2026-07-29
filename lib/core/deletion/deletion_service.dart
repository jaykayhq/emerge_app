import 'dart:async';

import 'package:emerge_app/core/deletion/deletion_audit.dart';
import 'package:emerge_app/core/deletion/delete_account_backend.dart';
import 'package:emerge_app/core/drift/database.dart';
import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/core/sync/sync_engine.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  })  : _db = db,
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
        _audit.log(
          op: 'deleteHabit',
          target: 'habit',
          habitId: habitId,
          outcome: 'noop',
          durationMs: sw.elapsedMilliseconds,
        );
        return const Right(unit); // idempotent
      }
      await _db.transaction(() async {
        await _db.habitsDao.archiveHabit(habitId);
        await _db.habitCompletionsDao.deleteByHabitId(habitId);
      });
      try {
        // Habits live in the TOP-LEVEL `habits` collection (see
        // DriftHabitRepository.createHabit) and firestore.rules allows the
        // owner to delete there. A hard delete is idempotent server-side.
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
    } catch (e, _) {
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
    await _db.clearAll();
    await auth.signOut();
    await idStore.clear('deletionRequestId:$userId');
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
