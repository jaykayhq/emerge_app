import 'package:emerge_app/core/services/local_cache_service.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/domain/models/habit_activity.dart';
import 'package:emerge_app/features/habits/domain/repositories/habit_repository.dart';
import 'package:emerge_app/features/blueprints/domain/models/blueprint.dart';
import 'package:fpdart/fpdart.dart';
import 'package:emerge_app/core/error/failure.dart';

class CacheAwareHabitRepository implements HabitRepository {
  final HabitRepository _remoteRepository;
  final LocalCacheService _localCache;

  CacheAwareHabitRepository(this._remoteRepository, this._localCache);

  @override
  Stream<List<Habit>> watchHabits(String userId) {
    // Firestore's persistence handles the local caching for the stream automatically.
    // We could also merge with Hive data if we had a separate local-only collection.
    return _remoteRepository.watchHabits(userId);
  }

  @override
  Future<Either<Failure, Unit>> createHabit(Habit habit) async {
    // Optimistic write to Hive
    await _localCache.enqueueMutation(
      collectionPath: 'habits',
      documentId: habit.id,
      data: habit.toMap(),
      operation: 'set',
    );

    // Attempt remote write
    final result = await _remoteRepository.createHabit(habit);
    
    return result.fold(
      (failure) => Left(failure),
      (unit) async {
        // Success - we don't strictly need to remove it here if 
        // the background sync handles cleanup, but let's be clean.
        // Actually, we should only remove it if we are SURE it's synced.
        return Right(unit);
      },
    );
  }

  @override
  Future<Either<Failure, Unit>> updateHabit(Habit habit) async {
    await _localCache.enqueueMutation(
      collectionPath: 'habits',
      documentId: habit.id,
      data: habit.toMap(),
      operation: 'update',
    );

    return _remoteRepository.updateHabit(habit);
  }

  @override
  Future<Either<Failure, Unit>> deleteHabit(String habitId) async {
    await _localCache.enqueueMutation(
      collectionPath: 'habits',
      documentId: habitId,
      data: {},
      operation: 'delete',
    );

    return _remoteRepository.deleteHabit(habitId);
  }

  @override
  Future<Either<Failure, bool>> completeHabit(String habitId, DateTime date) async {
    // Completion involves a transaction and multiple writes (activity logs, world health).
    // This is hard to do optimistically with Hive without a full sync engine.
    // For now, we rely on Firestore's built-in transaction persistence if available,
    // or just let it fail/retry.
    return _remoteRepository.completeHabit(habitId, date);
  }

  @override
  Future<Habit?> getHabit(String habitId) async {
    return _remoteRepository.getHabit(habitId);
  }

  @override
  Future<List<Habit>> getHabitsByAnchor(String anchorHabitId) async {
    return _remoteRepository.getHabitsByAnchor(anchorHabitId);
  }

  @override
  Future<List<HabitActivity>> getActivity(String userId, DateTime start, DateTime end) async {
    return _remoteRepository.getActivity(userId, start, end);
  }

  @override
  Future<Either<Failure, Unit>> createHabitsFromBlueprint({
    required String userId,
    required Blueprint blueprint,
    String? reminderTime,
  }) async {
    return _remoteRepository.createHabitsFromBlueprint(
      userId: userId,
      blueprint: blueprint,
      reminderTime: reminderTime,
    );
  }
}
