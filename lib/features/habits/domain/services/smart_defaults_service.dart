import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:flutter/material.dart';

/// Smart defaults for habit creation, derived from existing habits and archetype.
///
/// Principles: Anchoring (pre-fill from existing patterns), Default Effect
/// (sensible defaults reduce friction), Law of Least Effort (fewer taps).
class SmartDefaults {
  /// Most common time slot among user's habits, or archetype default.
  final TimeOfDay time;

  /// Archetype's primary attribute.
  final HabitAttribute attribute;

  /// Easy if <3 active habits, Medium otherwise.
  final HabitDifficulty difficulty;

  /// 5 min default, median of existing if available.
  final int timerMinutes;

  const SmartDefaults({
    required this.time,
    required this.attribute,
    required this.difficulty,
    required this.timerMinutes,
  });
}

/// Archetype-based default times.
const _archetypeDefaultTimes = {
  UserArchetype.athlete: TimeOfDay(hour: 7, minute: 0),
  UserArchetype.creator: TimeOfDay(hour: 10, minute: 0),
  UserArchetype.scholar: TimeOfDay(hour: 8, minute: 0),
  UserArchetype.stoic: TimeOfDay(hour: 6, minute: 0),
  UserArchetype.zealot: TimeOfDay(hour: 5, minute: 0),
  UserArchetype.none: TimeOfDay(hour: 7, minute: 0),
};

/// Archetype-to-primary-attribute mapping.
const _archetypeDefaultAttributes = {
  UserArchetype.athlete: HabitAttribute.vitality,
  UserArchetype.creator: HabitAttribute.creativity,
  UserArchetype.scholar: HabitAttribute.intellect,
  UserArchetype.stoic: HabitAttribute.focus,
  UserArchetype.zealot: HabitAttribute.spirit,
  UserArchetype.none: HabitAttribute.vitality,
};

int _timeOfDayToMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

/// Pure function that computes smart defaults for habit creation.
///
/// - [existingHabits]: user's current habits (used for time + timer anchoring).
/// - [archetype]: the user's archetype (attribute + time defaults).
/// - [activeHabitCount]: number of non-archived habits (difficulty gate).
SmartDefaults computeSmartDefaults({
  required List<Habit> existingHabits,
  required UserArchetype archetype,
  int activeHabitCount = 0,
}) {
  // ── Time: most common among existing, or archetype default ──
  final TimeOfDay time;
  if (existingHabits.isEmpty) {
    time = _archetypeDefaultTimes[archetype] ??
        const TimeOfDay(hour: 7, minute: 0);
  } else {
    final timeCounts = <int, int>{};
    for (final h in existingHabits) {
      if (h.reminderTime != null) {
        final minutes = _timeOfDayToMinutes(h.reminderTime!);
        timeCounts[minutes] = (timeCounts[minutes] ?? 0) + 1;
      }
    }
    if (timeCounts.isEmpty) {
      time = _archetypeDefaultTimes[archetype] ??
          const TimeOfDay(hour: 7, minute: 0);
    } else {
      final mostCommonMinutes = timeCounts.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
      time = TimeOfDay(
        hour: mostCommonMinutes ~/ 60,
        minute: mostCommonMinutes % 60,
      );
    }
  }

  // ── Attribute: archetype primary ──
  final attribute =
      _archetypeDefaultAttributes[archetype] ?? HabitAttribute.vitality;

  // ── Difficulty: Easy if <3 active habits, Medium otherwise ──
  final difficulty =
      activeHabitCount < 3 ? HabitDifficulty.easy : HabitDifficulty.medium;

  // ── Timer: 5 min default, median of existing if available ──
  final int timerMinutes;
  if (existingHabits.isEmpty) {
    timerMinutes = 5;
  } else {
    final timerValues =
        existingHabits.map((h) => h.timerDurationMinutes).toList()..sort();
    timerMinutes = timerValues[timerValues.length ~/ 2];
  }

  return SmartDefaults(
    time: time,
    attribute: attribute,
    difficulty: difficulty,
    timerMinutes: timerMinutes,
  );
}
