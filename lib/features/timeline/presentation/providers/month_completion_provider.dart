import 'dart:async';

import 'package:emerge_app/core/drift/database.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:emerge_app/features/timeline/domain/models/day_completion.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'month_completion_provider.g.dart';

String _dayKey(DateTime day) =>
    '${day.year}-${day.month.toString().padLeft(2, '0')}-'
    '${day.day.toString().padLeft(2, '0')}';

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

bool _isSameOrBeforeDay(DateTime candidate, DateTime day) {
  if (candidate.year != day.year) return candidate.year < day.year;
  if (candidate.month != day.month) return candidate.month < day.month;
  return candidate.day <= day.day;
}

/// Pure per-day completion math for the calendar strip — testable without
/// Drift/Riverpod. Completions use the record type
/// `({String habitId, DateTime completedAt})`.
///
/// For every day of [month]:
/// - active = habits created on/before that day (compared by calendar day)
///   AND active on that day per [Habit.isActiveOnDay] (archived excluded).
/// - completedIds = distinct habitIds from [completions] rows whose
///   completedAt is on that day and whose habitId is active.
/// - status: none (no completions), complete (all active done),
///   partial (some done). Days with zero active habits are `none` (0%).
Map<String, DayCompletion> computeMonthDayCompletion({
  required List<Habit> habits,
  required List<({String habitId, DateTime completedAt})> completions,
  required DateTime month,
}) {
  final lastDay = DateTime(month.year, month.month + 1, 0);
  final result = <String, DayCompletion>{};

  for (var d = 1; d <= lastDay.day; d++) {
    final day = DateTime(month.year, month.month, d);
    final key = _dayKey(day);

    final active = habits
        .where(
          (h) =>
              _isSameOrBeforeDay(h.createdAt, day) && h.isActiveOnDay(day),
        )
        .toList();

    if (active.isEmpty) {
      result[key] = DayCompletion.none;
      continue;
    }

    final activeIds = {for (final h in active) h.id};
    final completedIds = <String>{};
    for (final c in completions) {
      if (_isSameDay(c.completedAt, day) && activeIds.contains(c.habitId)) {
        completedIds.add(c.habitId);
      }
    }

    final status = completedIds.isEmpty
        ? DayCompletionStatus.none
        : completedIds.length >= active.length
            ? DayCompletionStatus.complete
            : DayCompletionStatus.partial;
    final percent =
        (completedIds.length / active.length * 100).round();

    result[key] = DayCompletion(status: status, percent: percent);
  }

  return result;
}

/// Per-day completion for the current month, derived from the habits stream
/// and the per-user Drift completion history. Empty map when signed out.
@riverpod
Stream<Map<String, DayCompletion>> monthCompletion(Ref ref) {
  final userId = ref.watch(authStateChangesProvider).value?.id;
  if (userId == null || userId.isEmpty) {
    return Stream.value(const {});
  }

  final repository = ref.watch(habitRepositoryProvider);
  final habitsStream = repository.watchHabits(userId);
  final completionsStream =
      ref.watch(habitCompletionsDaoProvider).watchCompletions(userId);

  return _combineLatest(
    habitsStream,
    completionsStream,
    (List<Habit> habits, List<HabitCompletionsTableData> rows) =>
        computeMonthDayCompletion(
      habits: habits,
      completions: [
        for (final row in rows)
          (habitId: row.habitId, completedAt: DateTime.parse(row.completedAt)),
      ],
      month: DateTime.now(),
    ),
  );
}

/// Minimal combineLatest: emits the combined value whenever either source
/// emits, buffering the other's latest value. Cancels both subscriptions when
/// the consumer cancels and pauses/resumes them with the consumer.
Stream<R> _combineLatest<A, B, R>(
  Stream<A> first,
  Stream<B> second,
  R Function(A, B) combine,
) {
  late A? lastA;
  late B? lastB;
  var hasA = false;
  var hasB = false;
  late StreamController<R> controller;
  late StreamSubscription<A> subA;
  late StreamSubscription<B> subB;

  void emitIfReady() {
    if (hasA && hasB && !controller.isClosed) {
      controller.add(combine(lastA as A, lastB as B));
    }
  }

  controller = StreamController<R>(
    onListen: () {
      subA = first.listen(
        (a) {
          lastA = a;
          hasA = true;
          emitIfReady();
        },
        onError: controller.addError,
        onDone: () {
          if (!controller.isClosed) controller.close();
        },
      );
      subB = second.listen(
        (b) {
          lastB = b;
          hasB = true;
          emitIfReady();
        },
        onError: controller.addError,
        onDone: () {
          if (!controller.isClosed) controller.close();
        },
      );
    },
    onPause: () {
      subA.pause();
      subB.pause();
    },
    onResume: () {
      subA.resume();
      subB.resume();
    },
    onCancel: () async {
      await subA.cancel();
      await subB.cancel();
    },
  );

  return controller.stream;
}
