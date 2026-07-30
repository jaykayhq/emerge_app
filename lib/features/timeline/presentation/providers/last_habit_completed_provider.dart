import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'last_habit_completed_provider.g.dart';

/// Pure predicate: did the user *just* complete the final outstanding habit?
///
/// True only on the exact transition into an all-done state:
/// previously fewer than [totalHabits] were complete, and now every habit is.
/// Guards against the no-habits case and against undo (count going down).
bool isLastHabitJustCompleted({
  required int previousCompleted,
  required int currentCompleted,
  required int totalHabits,
}) {
  if (totalHabits <= 0) return false;
  return previousCompleted < totalHabits &&
      currentCompleted == totalHabits &&
      currentCompleted > previousCompleted;
}

/// Emits `true` on the frame where today's last habit is completed, then
/// resets to `false`. Timeline watches this to fire the all-done celebration.
///
/// Keeps its own memory of the previous completed count so the pure
/// [isLastHabitJustCompleted] can detect the (total-1 -> total) edge.
@riverpod
class LastHabitCompleted extends _$LastHabitCompleted {
  /// Previous completed count. `null` until the first build establishes a
  /// baseline — this prevents a false-positive celebration when the Timeline
  /// opens (or the autoDispose provider re-initializes) while every habit is
  /// already complete.
  int? _previousCompleted;

  @override
  bool build() {
    final habitsAsync = ref.watch(habitsProvider);

    // Only evaluate on real data. While loading/errored, hold the baseline
    // and emit false so a transient empty list can't trigger the celebration.
    if (!habitsAsync.hasValue) {
      return false;
    }
    final habits = habitsAsync.value ?? const <Habit>[];
    final now = DateTime.now();

    // Only count habits that are active today so the "all done" celebration
    // fires at the right moment (ignoring weekly habits not scheduled today).
    final todaysHabits =
        habits.where((h) => h.isActiveOnDay(now)).toList();
    final total = todaysHabits.length;
    final currentCompleted =
        todaysHabits.where((h) => h.isCompletedOn(now)).length;

    // First real build: record baseline only, never celebrate.
    if (_previousCompleted == null) {
      _previousCompleted = currentCompleted;
      return false;
    }

    final justCompleted = isLastHabitJustCompleted(
      previousCompleted: _previousCompleted!,
      currentCompleted: currentCompleted,
      totalHabits: total,
    );

    _previousCompleted = currentCompleted;

    // One-shot event: if we're emitting true, schedule an immediate reset to
    // false so late-added listeners / re-reads don't observe a stale true.
    if (justCompleted) {
      Future.microtask(() {
        if (ref.mounted) state = false;
      });
    }

    return justCompleted;
  }
}
