import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/domain/services/smart_defaults_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('computeSmartDefaults', () {
    test('returns archetype default time when no existing habits', () {
      final defaults = computeSmartDefaults(
        existingHabits: [],
        archetype: UserArchetype.athlete,
      );
      expect(defaults.time, equals(const TimeOfDay(hour: 7, minute: 0)));
    });

    test('returns most common time from existing habits', () {
      final defaults = computeSmartDefaults(
        existingHabits: [
          Habit(
            id: '1',
            userId: 'u',
            title: 'Habit 1',
            createdAt: DateTime.now(),
            reminderTime: const TimeOfDay(hour: 7, minute: 0),
          ),
          Habit(
            id: '2',
            userId: 'u',
            title: 'Habit 2',
            createdAt: DateTime.now(),
            reminderTime: const TimeOfDay(hour: 7, minute: 0),
          ),
          Habit(
            id: '3',
            userId: 'u',
            title: 'Habit 3',
            createdAt: DateTime.now(),
            reminderTime: const TimeOfDay(hour: 20, minute: 0),
          ),
        ],
        archetype: UserArchetype.athlete,
      );
      expect(defaults.time, equals(const TimeOfDay(hour: 7, minute: 0)));
    });

    test('returns archetype default time when existing habits have no reminderTime', () {
      final defaults = computeSmartDefaults(
        existingHabits: [
          Habit(id: '1', userId: 'u', title: 'No time', createdAt: DateTime.now()),
          Habit(id: '2', userId: 'u', title: 'No time 2', createdAt: DateTime.now()),
        ],
        archetype: UserArchetype.creator,
      );
      expect(defaults.time, equals(const TimeOfDay(hour: 10, minute: 0)));
    });

    test('returns Easy difficulty when fewer than 3 active habits', () {
      final defaults = computeSmartDefaults(
        existingHabits: [
          Habit(id: '1', userId: 'u', title: 'Test', createdAt: DateTime.now()),
        ],
        archetype: UserArchetype.athlete,
        activeHabitCount: 2,
      );
      expect(defaults.difficulty, equals(HabitDifficulty.easy));
    });

    test('returns Medium difficulty when 3 or more active habits', () {
      final defaults = computeSmartDefaults(
        existingHabits: [],
        archetype: UserArchetype.athlete,
        activeHabitCount: 5,
      );
      expect(defaults.difficulty, equals(HabitDifficulty.medium));
    });

    test('returns 5 min timer default when no existing timer data', () {
      final defaults = computeSmartDefaults(
        existingHabits: [],
        archetype: UserArchetype.athlete,
      );
      expect(defaults.timerMinutes, equals(5));
    });

    test('returns median timer from existing habits', () {
      final defaults = computeSmartDefaults(
        existingHabits: [
          Habit(id: '1', userId: 'u', title: 'A', createdAt: DateTime.now(), timerDurationMinutes: 10),
          Habit(id: '2', userId: 'u', title: 'B', createdAt: DateTime.now(), timerDurationMinutes: 20),
          Habit(id: '3', userId: 'u', title: 'C', createdAt: DateTime.now(), timerDurationMinutes: 30),
        ],
        archetype: UserArchetype.athlete,
      );
      // median of [10, 20, 30] = 20
      expect(defaults.timerMinutes, equals(20));
    });

    test('returns archetype default attribute', () {
      final athleteDefaults = computeSmartDefaults(
        existingHabits: [],
        archetype: UserArchetype.athlete,
      );
      expect(athleteDefaults.attribute, equals(HabitAttribute.vitality));
    });

    test('different archetypes have different attribute defaults', () {
      final athleteDefaults = computeSmartDefaults(
        existingHabits: [],
        archetype: UserArchetype.athlete,
      );
      final creatorDefaults = computeSmartDefaults(
        existingHabits: [],
        archetype: UserArchetype.creator,
      );
      expect(athleteDefaults.attribute, isNot(equals(creatorDefaults.attribute)));
    });

    test('scholar archetype defaults to intellect attribute', () {
      final defaults = computeSmartDefaults(
        existingHabits: [],
        archetype: UserArchetype.scholar,
      );
      expect(defaults.attribute, equals(HabitAttribute.intellect));
    });
  });
}
