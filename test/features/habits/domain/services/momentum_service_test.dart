import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/domain/services/momentum_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MomentumService service;

  setUp(() {
    service = MomentumService();
  });

  group('applyCompletion', () {
    test('boosts momentum by 10 and resets consecutiveMisses', () {
      final habit = Habit(
        id: 'h1', userId: 'u1', title: 'Test',
        createdAt: DateTime.now(),
        momentumScore: 30, consecutiveMisses: 3,
      );
      final result = service.applyCompletion(habit);
      expect(result.momentumScore, 40);
      expect(result.consecutiveMisses, 0);
    });

    test('caps momentum at 100', () {
      final habit = Habit(
        id: 'h1', userId: 'u1', title: 'Test',
        createdAt: DateTime.now(),
        momentumScore: 95, consecutiveMisses: 0,
      );
      final result = service.applyCompletion(habit);
      expect(result.momentumScore, 100);
    });
  });

  group('applyDailyDecay', () {
    test('subtracts idle decay for first miss', () {
      final habit = Habit(
        id: 'h1', userId: 'u1', title: 'Test',
        createdAt: DateTime.now(),
        momentumScore: 50, consecutiveMisses: 0,
      );
      final result = service.applyDailyDecay(habit);
      expect(result.momentumScore, 48);
      expect(result.consecutiveMisses, 1);
    });

    test('subtracts miss decay for subsequent misses', () {
      final habit = Habit(
        id: 'h1', userId: 'u1', title: 'Test',
        createdAt: DateTime.now(),
        momentumScore: 50, consecutiveMisses: 2,
      );
      final result = service.applyDailyDecay(habit);
      expect(result.momentumScore, 45);
      expect(result.consecutiveMisses, 3);
    });

    test('caps momentum at 0', () {
      final habit = Habit(
        id: 'h1', userId: 'u1', title: 'Test',
        createdAt: DateTime.now(),
        momentumScore: 1, consecutiveMisses: 0,
      );
      final result = service.applyDailyDecay(habit);
      expect(result.momentumScore, 0);
    });
  });

  group('applyMultiDayDecay', () {
    test('returns unchanged habit when daysMissed <= 0', () {
      final habit = Habit(
        id: 'h1', userId: 'u1', title: 'Test',
        createdAt: DateTime.now(),
        momentumScore: 50, consecutiveMisses: 0,
      );
      expect(service.applyMultiDayDecay(habit, 0), habit);
      expect(service.applyMultiDayDecay(habit, -1), habit);
    });

    test('applies correct decay for multiple missed days', () {
      final habit = Habit(
        id: 'h1', userId: 'u1', title: 'Test',
        createdAt: DateTime.now(),
        momentumScore: 100, consecutiveMisses: 0,
      );
      // 3 misses: first idle decay (2), then miss decay (5), then miss decay (5)
      final result = service.applyMultiDayDecay(habit, 3);
      expect(result.momentumScore, 88);
      expect(result.consecutiveMisses, 3);
    });

    test('uses miss decay for all days when already missing', () {
      final habit = Habit(
        id: 'h1', userId: 'u1', title: 'Test',
        createdAt: DateTime.now(),
        momentumScore: 100, consecutiveMisses: 5,
      );
      final result = service.applyMultiDayDecay(habit, 2);
      expect(result.momentumScore, 90); // 100 - 5 - 5
      expect(result.consecutiveMisses, 7);
    });
  });

  group('computeWorldHealth', () {
    test('returns average momentum of active habits', () {
      final habits = [
        Habit(id: 'h1', userId: 'u1', title: 'A', createdAt: DateTime.now(), momentumScore: 80, isArchived: false),
        Habit(id: 'h2', userId: 'u1', title: 'B', createdAt: DateTime.now(), momentumScore: 20, isArchived: false),
      ];
      expect(service.computeWorldHealth(habits), 50);
    });

    test('excludes archived habits', () {
      final habits = [
        Habit(id: 'h1', userId: 'u1', title: 'A', createdAt: DateTime.now(), momentumScore: 80, isArchived: false),
        Habit(id: 'h2', userId: 'u1', title: 'B', createdAt: DateTime.now(), momentumScore: 20, isArchived: true),
      ];
      expect(service.computeWorldHealth(habits), 80);
    });

    test('returns 50 for empty list', () {
      expect(service.computeWorldHealth([]), 50);
    });
  });

  group('momentumLabel', () {
    test('returns correct label for each state', () {
      expect(service.momentumLabel(HabitStreakState.onFire), 'On Fire 🔥');
      expect(service.momentumLabel(HabitStreakState.strong), 'Strong');
      expect(service.momentumLabel(HabitStreakState.building), 'Building');
      expect(service.momentumLabel(HabitStreakState.atRisk), 'At Risk');
      expect(service.momentumLabel(HabitStreakState.recovery), 'Recovery');
      expect(service.momentumLabel(HabitStreakState.reset), 'Fresh Start');
    });
  });
}
