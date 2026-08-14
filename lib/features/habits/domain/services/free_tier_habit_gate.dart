/// Pure free-tier habit-cap decision for the onboarding/anchor bypass.
///
/// Extracted so the free-tier math is unit-testable without Riverpod,
/// Firebase, or Remote Config (mirrors `decideRedirect` / `CoachAskQuota`).
/// Semantics mirror `createHabit`'s gate: a free user may hold up to
/// [freeLimit] active (non-archived) habits; premium bypasses the cap.
class FreeTierHabitGate {
  const FreeTierHabitGate._();

  /// Whether [habitsToAdd] new habits fit within the free tier given
  /// [activeHabitCount] currently active habits.
  static bool canAddHabits({
    required int activeHabitCount,
    required int habitsToAdd,
    required int freeLimit,
    required bool isPremium,
  }) {
    if (isPremium) return true;
    return activeHabitCount + habitsToAdd <= freeLimit;
  }
}
