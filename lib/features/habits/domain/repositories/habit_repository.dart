import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/domain/models/habit_activity.dart';
import 'package:fpdart/fpdart.dart';

abstract class HabitRepository {
  Stream<List<Habit>> watchHabits(String userId);

  Future<Either<Failure, Unit>> createHabit(Habit habit);

  Future<Either<Failure, Unit>> updateHabit(Habit habit);

  Future<Either<Failure, Unit>> deleteHabit(String habitId);

  Future<Either<Failure, bool>> completeHabit(String habitId, DateTime date);

  Future<Habit?> getHabit(String habitId);

  // Verifies that habit stacking logic is supported by the repository
  // Verifies that habit stacking logic is supported by the repository
  Future<List<Habit>> getHabitsByAnchor(String anchorHabitId);

  Future<List<HabitActivity>> getActivity(
    String userId,
    DateTime start,
    DateTime end,
  );
}
