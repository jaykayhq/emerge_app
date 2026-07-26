import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:emerge_app/features/habits/presentation/providers/smart_defaults_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('smartDefaultsProvider', () {
    ProviderContainer makeContainer({
      required List<Habit> habits,
      required UserArchetype archetype,
    }) {
      return ProviderContainer(
        overrides: [
          // Override with a completed AsyncValue to avoid stream timing issues.
          habitsProvider.overrideWithValue(AsyncValue.data(habits)),
          currentArchetypeProvider.overrideWithValue(archetype),
        ],
      );
    }

    test('returns archetype defaults when no habits exist', () {
      final container = makeContainer(
        habits: [],
        archetype: UserArchetype.athlete,
      );
      final defaults = container.read(smartDefaultsProvider);
      expect(defaults.time, equals(const TimeOfDay(hour: 7, minute: 0)));
      expect(defaults.attribute, equals(HabitAttribute.vitality));
      expect(defaults.difficulty, equals(HabitDifficulty.easy));
      expect(defaults.timerMinutes, equals(5));
      container.dispose();
    });

    test('returns easy difficulty when fewer than 3 active habits', () {
      final container = makeContainer(
        habits: [
          Habit(id: '1', userId: 'u', title: 'A', createdAt: DateTime.now()),
          Habit(id: '2', userId: 'u', title: 'B', createdAt: DateTime.now()),
        ],
        archetype: UserArchetype.scholar,
      );
      final defaults = container.read(smartDefaultsProvider);
      expect(defaults.difficulty, equals(HabitDifficulty.easy));
      container.dispose();
    });

    test('returns medium difficulty when 3+ active habits', () {
      final container = makeContainer(
        habits: [
          Habit(id: '1', userId: 'u', title: 'A', createdAt: DateTime.now()),
          Habit(id: '2', userId: 'u', title: 'B', createdAt: DateTime.now()),
          Habit(id: '3', userId: 'u', title: 'C', createdAt: DateTime.now()),
          Habit(id: '4', userId: 'u', title: 'D', createdAt: DateTime.now()),
        ],
        archetype: UserArchetype.creator,
      );
      final defaults = container.read(smartDefaultsProvider);
      expect(defaults.difficulty, equals(HabitDifficulty.medium));
      container.dispose();
    });

    test('filters out archived habits from active count', () {
      final container = makeContainer(
        habits: [
          Habit(
            id: '1',
            userId: 'u',
            title: 'Active',
            createdAt: DateTime.now(),
          ),
          Habit(
            id: '2',
            userId: 'u',
            title: 'Archived',
            createdAt: DateTime.now(),
            isArchived: true,
          ),
          Habit(
            id: '3',
            userId: 'u',
            title: 'Active 2',
            createdAt: DateTime.now(),
          ),
        ],
        archetype: UserArchetype.stoic,
      );
      final defaults = container.read(smartDefaultsProvider);
      // Archived habit excluded, so activeHabitCount = 2 -> Easy
      expect(defaults.difficulty, equals(HabitDifficulty.easy));
      expect(defaults.attribute, equals(HabitAttribute.focus));
      container.dispose();
    });

    test('uses most common reminderTime from habits', () {
      final container = makeContainer(
        habits: [
          Habit(
            id: '1',
            userId: 'u',
            title: 'Morning',
            createdAt: DateTime.now(),
            reminderTime: const TimeOfDay(hour: 7, minute: 0),
          ),
          Habit(
            id: '2',
            userId: 'u',
            title: 'Morning 2',
            createdAt: DateTime.now(),
            reminderTime: const TimeOfDay(hour: 7, minute: 0),
          ),
          Habit(
            id: '3',
            userId: 'u',
            title: 'Evening',
            createdAt: DateTime.now(),
            reminderTime: const TimeOfDay(hour: 20, minute: 0),
          ),
        ],
        archetype: UserArchetype.zealot,
      );
      final defaults = container.read(smartDefaultsProvider);
      expect(defaults.time, equals(const TimeOfDay(hour: 7, minute: 0)));
      container.dispose();
    });
  });
}
