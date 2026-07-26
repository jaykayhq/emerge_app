/// Pure, unit-testable helpers for the Goal Gradient + Zeigarnik features
/// (Plan 2). No Flutter/Riverpod imports so they can be tested in isolation.
library;

/// Interface so the pure functions work with any object that exposes
/// completion state — not just [Habit]. This keeps the math testable
/// without constructing full domain entities.
abstract class HasCompletion {
  bool get isCompleted;
}

/// Fraction of today's habits completed: 0.0–1.0.
/// Returns 0.0 for an empty list (avoid divide-by-zero / false "complete").
double computeCompletionFraction<T extends HasCompletion>(List<T> habits) {
  if (habits.isEmpty) return 0.0;
  final completed = habits.where((h) => h.isCompleted).length;
  return completed / habits.length;
}

/// Count of incomplete habits for today.
int computeIncompleteCount<T extends HasCompletion>(List<T> habits) {
  return habits.where((h) => !h.isCompleted).length;
}

/// Completion-ring color per the Goal Gradient Effect:
/// green ≥80%, amber 50–79%, coral below 50%.
int ringColorValue(double fraction) {
  if (fraction >= 0.8) return 0xFF2BEE79; // green
  if (fraction >= 0.5) return 0xFFFFC107; // amber
  return 0xFFFF6B6B; // coral
}

/// Momentum dot color per streak:
/// green ≥7, amber ≥3, coral below 3.
int momentumColorValue(int streak) {
  if (streak >= 7) return 0xFF2BEE79;
  if (streak >= 3) return 0xFFFFC107;
  return 0xFFFF6B6B;
}

/// Whether the incomplete-habit badge on the Timeline tab should pulse —
/// i.e. only a couple hours of daylight remain and there is still
/// unfinished business today.
bool shouldPulseIncompleteBadge(int incompleteCount, DateTime now) {
  if (incompleteCount <= 0) return false;
  // Pulse only in the final 2 hours of daylight (17:00–19:00 local).
  final hour = now.hour;
  return hour >= 17 && hour < 19;
}
