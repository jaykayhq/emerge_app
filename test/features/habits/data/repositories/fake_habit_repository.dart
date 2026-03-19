import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/domain/models/habit_activity.dart';
import 'package:emerge_app/features/habits/domain/repositories/habit_repository.dart';
import 'package:fpdart/fpdart.dart';

class FakeHabitRepository implements HabitRepository {
  final Map<String, Habit> _habits = {};

  @override
  Stream<List<Habit>> watchHabits(String userId) async* {
    yield _habits.values.where((h) => h.userId == userId).toList();
  }

  @override
  Future<Either<Failure, Unit>> createHabit(Habit habit) async {
    _habits[habit.id] = habit;
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> updateHabit(Habit habit) async {
    if (!_habits.containsKey(habit.id)) {
      return Left(ServerFailure('Habit not found'));
    }
    _habits[habit.id] = habit;
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> deleteHabit(String habitId) async {
    _habits.remove(habitId);
    return const Right(unit);
  }

  @override
  Future<Either<Failure, bool>> completeHabit(
    String habitId,
    DateTime date,
  ) async {
    final habit = _habits[habitId];
    if (habit == null) return Left(ServerFailure('Habit not found'));

    // Toggle completion
    if (habit.lastCompletedDate?.day == date.day &&
        habit.lastCompletedDate?.month == date.month &&
        habit.lastCompletedDate?.year == date.year) {
      _habits[habitId] = habit.copyWith(
        currentStreak: (habit.currentStreak > 0) ? habit.currentStreak - 1 : 0,
        clearLastCompletedDate: true,
      );
      return const Right(false);
    } else {
      _habits[habitId] = habit.copyWith(
        currentStreak: habit.currentStreak + 1,
        lastCompletedDate: date,
      );
      return const Right(true);
    }
  }

  @override
  Future<Habit?> getHabit(String habitId) async {
    return _habits[habitId];
  }

  @override
  Future<List<Habit>> getHabitsByAnchor(String anchorHabitId) async {
    return _habits.values.where((h) => h.cue == anchorHabitId).toList();
  }

  @override
  Future<List<HabitActivity>> getActivity(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    return [];
  }
}
