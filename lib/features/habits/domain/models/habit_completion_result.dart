import 'package:emerge_app/features/narrator/domain/models/narrator_trigger.dart';

/// The result of a habit completion operation.
///
/// Carries both the mechanical outcome (XP, streak, momentum) and a
/// potential Narrator trigger so the UI layer knows whether to show
/// the Narrator sheet after completion.
class HabitCompletionResult {
  final String habitId;
  final int xpEarned;
  final int newStreak;
  final int newMomentumScore;
  final bool isStreakMilestone;
  final bool isUndo;
  final bool wasRecovery;
  final NarratorTrigger? narratorTrigger;

  const HabitCompletionResult({
    required this.habitId,
    required this.xpEarned,
    required this.newStreak,
    required this.newMomentumScore,
    this.isStreakMilestone = false,
    this.isUndo = false,
    this.wasRecovery = false,
    this.narratorTrigger,
  });

  /// Convenience constructor for error or empty states.
  const HabitCompletionResult.empty()
      : habitId = '',
        xpEarned = 0,
        newStreak = 0,
        newMomentumScore = 0,
        isStreakMilestone = false,
        isUndo = false,
        wasRecovery = false,
        narratorTrigger = null;

  /// Whether this completion was a meaningful new completion (not an undo).
  bool get isMeaningful => !isUndo && xpEarned > 0;
}
