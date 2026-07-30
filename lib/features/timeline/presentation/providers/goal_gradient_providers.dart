import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:emerge_app/features/timeline/presentation/providers/goal_gradient_helpers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'goal_gradient_providers.g.dart';

/// Shared mapper: today's completion flags for the currently-loaded habits,
/// evaluated once per habit. Only includes habits active today (via
/// [Habit.isActiveOnDay]) so the fraction matches what the user sees.
/// Empty list when the habits stream is loading/error (`.value` is null)
/// — the pure helpers treat that as 0.
List<_CompFlag> _todayFlags(Ref ref) {
  final habitsAsync = ref.watch(habitsProvider);
  final habits = habitsAsync.value ?? const <Habit>[];
  final now = DateTime.now();
  return [
    for (final h in habits)
      if (h.isActiveOnDay(now)) _CompFlag(h.isCompletedOn(now)),
  ];
}

/// 0.0–1.0 fraction of today's habits already completed.
/// Drives the FAB completion ring and the recap arc.
@riverpod
double completionFraction(Ref ref) {
  return computeCompletionFraction(_todayFlags(ref));
}

/// Count of today's habits not yet completed.
/// Drives the Timeline-tab badge.
@riverpod
int incompleteCount(Ref ref) {
  return computeIncompleteCount(_todayFlags(ref));
}

/// Tiny adapter exposing only the completion flag so the pure helpers
/// (which operate on [HasCompletion]) can be reused for the Riverpod
/// providers without leaking the full [Habit] API.
class _CompFlag implements HasCompletion {
  const _CompFlag(this.isCompleted);
  @override
  final bool isCompleted;
}
