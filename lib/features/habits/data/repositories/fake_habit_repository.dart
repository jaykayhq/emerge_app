import 'dart:async';

import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/domain/repositories/habit_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:uuid/uuid.dart';

class FakeHabitRepository implements HabitRepository {
  final _controller = StreamController<List<Habit>>.broadcast();
  final List<Habit> _habits = [];

  FakeHabitRepository() {
    // Add some dummy data
    _habits.addAll([
      Habit(
        id: const Uuid().v4(),
        userId: '123',
        title: 'Read 10 pages',
        cue: 'After I pour my morning coffee',
        routine: 'I will read 10 pages',
        reward: 'Enjoy the coffee',
        createdAt: DateTime.now(),
        difficulty: HabitDifficulty.easy,
      ),
      Habit(
        id: const Uuid().v4(),
        userId: '123',
        title: 'Meditate 5 mins',
        cue: 'Before I go to bed',
        routine: 'I will meditate for 5 minutes',
        reward: 'Better sleep',
        createdAt: DateTime.now(),
        difficulty: HabitDifficulty.medium,
      ),
    ]);
    _controller.add(_habits);
  }

  @override
  Stream<List<Habit>> watchHabits(String userId) {
    return _controller.stream.map((habits) {
      return habits.where((h) => h.userId == userId).toList();
    });
  }

  @override
  Future<Either<Failure, Unit>> createHabit(Habit habit) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _habits.add(habit);
    _controller.add(_habits);
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> updateHabit(Habit habit) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _habits.indexWhere((h) => h.id == habit.id);
    if (index != -1) {
      _habits[index] = habit;
      _controller.add(_habits);
      return const Right(unit);
    }
    return const Left(CacheFailure('Habit not found'));
  }

  @override
  Future<Either<Failure, Unit>> deleteHabit(String habitId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _habits.removeWhere((h) => h.id == habitId);
    _controller.add(_habits);
    return const Right(unit);
  }

  @override
  Future<Either<Failure, bool>> completeHabit(
    String habitId,
    DateTime date,
  ) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _habits.indexWhere((h) => h.id == habitId);
    if (index != -1) {
      final habit = _habits[index];

      // Check if already completed today
      final isCompletedToday =
          habit.lastCompletedDate != null &&
          habit.lastCompletedDate!.year == date.year &&
          habit.lastCompletedDate!.month == date.month &&
          habit.lastCompletedDate!.day == date.day;

      if (isCompletedToday) {
        // Undo completion (toggle off)
        final updatedHabit = habit.copyWith(
          currentStreak: habit.currentStreak > 0 ? habit.currentStreak - 1 : 0,
          lastCompletedDate: null,
        );
        _habits[index] = updatedHabit;
        _controller.add(_habits);
        return const Right(false);
      }

      final updatedHabit = habit.copyWith(
        currentStreak: habit.currentStreak + 1,
        lastCompletedDate: date,
      );

      _habits[index] = updatedHabit;
      _controller.add(_habits);
      return const Right(true);
    }
    return const Left(CacheFailure('Habit not found'));
  }

  @override
  Future<Habit?> getHabit(String habitId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _habits.firstWhere((h) => h.id == habitId);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<Habit>> getHabitsByAnchor(String anchorHabitId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return [];
  }
}
