// Unit tests for the pure per-day completion math that powers the calendar
// strip's dot + percentage (Task A). Uses the record type
// `({String habitId, DateTime completedAt})` so no Drift import is needed.
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/timeline/domain/models/day_completion.dart';
import 'package:emerge_app/features/timeline/presentation/providers/month_completion_provider.dart';
import 'package:flutter_test/flutter_test.dart';

Habit _habit(
  String id, {
  DateTime? createdAt,
  HabitFrequency frequency = HabitFrequency.daily,
  bool isArchived = false,
}) {
  return Habit(
    id: id,
    userId: 'u1',
    title: id,
    createdAt: createdAt ?? DateTime(2026, 3, 1),
    frequency: frequency,
    isArchived: isArchived,
  );
}

void main() {
  group('computeMonthDayCompletion', () {
    final month = DateTime(2026, 3);
    const day10Key = '2026-03-10';

    test('no completions: every day of the month is none with 0%', () {
      final result = computeMonthDayCompletion(
        habits: [_habit('a'), _habit('b')],
        completions: const [],
        month: month,
      );

      expect(result.length, 31);
      for (final day in result.values) {
        expect(day.status, DayCompletionStatus.none);
        expect(day.percent, 0);
      }
    });

    test('one of two active habits completed: partial with 50%', () {
      final result = computeMonthDayCompletion(
        habits: [_habit('a'), _habit('b')],
        completions: [
          (habitId: 'a', completedAt: DateTime(2026, 3, 10, 9, 30)),
        ],
        month: month,
      );

      final day = result[day10Key]!;
      expect(day.status, DayCompletionStatus.partial);
      expect(day.percent, 50);

      // A day with no completions stays none.
      expect(result['2026-03-11']!.status, DayCompletionStatus.none);
      expect(result['2026-03-11']!.percent, 0);
    });

    test('all active habits completed: complete with 100%', () {
      final result = computeMonthDayCompletion(
        habits: [_habit('a'), _habit('b')],
        completions: [
          (habitId: 'a', completedAt: DateTime(2026, 3, 10, 8, 0)),
          (habitId: 'b', completedAt: DateTime(2026, 3, 10, 20, 0)),
        ],
        month: month,
      );

      final day = result[day10Key]!;
      expect(day.status, DayCompletionStatus.complete);
      expect(day.percent, 100);
    });

    test('weekly habit excluded on days that are not its creation weekday', () {
      // Created 2026-03-02; the 3rd is always a different weekday, the 9th
      // is exactly one week later (same weekday → active).
      final weekly = _habit(
        'weekly',
        createdAt: DateTime(2026, 3, 2),
        frequency: HabitFrequency.weekly,
      );

      // Completion on a day the habit is NOT scheduled → excluded → none.
      final offDay = computeMonthDayCompletion(
        habits: [weekly],
        completions: [
          (habitId: 'weekly', completedAt: DateTime(2026, 3, 3, 12, 0)),
        ],
        month: month,
      );
      expect(offDay['2026-03-03']!.status, DayCompletionStatus.none);
      expect(offDay['2026-03-03']!.percent, 0);

      // Completion on the habit's weekday → active and complete.
      final onDay = computeMonthDayCompletion(
        habits: [weekly],
        completions: [
          (habitId: 'weekly', completedAt: DateTime(2026, 3, 9, 12, 0)),
        ],
        month: month,
      );
      expect(onDay['2026-03-09']!.status, DayCompletionStatus.complete);
      expect(onDay['2026-03-09']!.percent, 100);
    });

    test('habit created mid-month is not counted before its creation day', () {
      final lateHabit = _habit('late', createdAt: DateTime(2026, 3, 15));

      final result = computeMonthDayCompletion(
        habits: [lateHabit],
        completions: [
          (habitId: 'late', completedAt: DateTime(2026, 3, 10, 9, 0)),
          (habitId: 'late', completedAt: DateTime(2026, 3, 15, 9, 0)),
        ],
        month: month,
      );

      // Before creation: not active, completion ignored.
      expect(result['2026-03-10']!.status, DayCompletionStatus.none);
      expect(result['2026-03-10']!.percent, 0);
      // On creation day: active (created on/before the day) → complete.
      expect(result['2026-03-15']!.status, DayCompletionStatus.complete);
      expect(result['2026-03-15']!.percent, 100);
    });

    test('multiple rows for the same habit on the same day count once', () {
      final result = computeMonthDayCompletion(
        habits: [_habit('a')],
        completions: [
          (habitId: 'a', completedAt: DateTime(2026, 3, 10, 8, 0)),
          (habitId: 'a', completedAt: DateTime(2026, 3, 10, 12, 0)),
          (habitId: 'a', completedAt: DateTime(2026, 3, 10, 21, 0)),
        ],
        month: month,
      );

      expect(result[day10Key]!.status, DayCompletionStatus.complete);
      expect(result[day10Key]!.percent, 100);
    });

    test('archived habit is excluded even with completions', () {
      final result = computeMonthDayCompletion(
        habits: [_habit('gone', isArchived: true)],
        completions: [
          (habitId: 'gone', completedAt: DateTime(2026, 3, 10, 9, 0)),
        ],
        month: month,
      );

      expect(result[day10Key]!.status, DayCompletionStatus.none);
      expect(result[day10Key]!.percent, 0);
    });

    test('days with zero active habits are none with 0%', () {
      final result = computeMonthDayCompletion(
        habits: [_habit('a')],
        completions: const [],
        month: month,
      );

      for (final day in result.values) {
        expect(day.status, DayCompletionStatus.none);
        expect(day.percent, 0);
      }
    });
  });
}
