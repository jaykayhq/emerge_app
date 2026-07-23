import 'dart:async';

import 'package:emerge_app/core/deletion/deletion_audit.dart';
import 'package:emerge_app/core/drift/database.dart';
import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/core/sync/sync_engine.dart';
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
        await _syncEngine.enqueueUpdate(
          collectionPath: 'users/$userId/habits',
          documentId: habitId,
          data: {
            'isArchived': true,
            'updatedAt': DateTime.now().toIso8601String(),
          },
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
}
