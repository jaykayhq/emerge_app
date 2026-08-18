import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/world_map/domain/models/next_identity_vote.dart';

/// Pure domain service that calculates the Next Best Action (NBA) / Identity Vote
/// to display on the World Map Stoking Dock.
class NextIdentityVoteService {
  /// Evaluates the list of [habits] against the current realm [entropy]
  /// and returns the prioritized [NextIdentityVote].
  ///
  /// - Returns [NextIdentityVote.empty] if [habits] is empty.
  /// - Returns [NextIdentityVote.harmonized] if all habits are completed for today.
  /// - Prioritizes lowest-streak habit with `isRecovery: true` when [entropy] > 0.05.
  /// - Otherwise prioritizes highest-streak uncompleted habit.
  /// - Calculates [vitalityImpactPercent] clamped between 10% and 35%.
  NextIdentityVote calculateNextVote({
    required List<Habit> habits,
    required double entropy,
    DateTime? now,
  }) {
    if (habits.isEmpty) {
      return NextIdentityVote.empty();
    }

    final today = now ?? DateTime.now();
    final uncompleted = habits.where((h) => !h.isCompletedOn(today)).toList();
    if (uncompleted.isEmpty) {
      return NextIdentityVote.harmonized();
    }

    // If entropy > 0.05, prioritize recovery habit
    final isRecovery = entropy > 0.05;

    // Prioritize habits: lowest streak for recovery, highest streak otherwise
    uncompleted.sort((a, b) {
      if (isRecovery) {
        return a.currentStreak.compareTo(b.currentStreak);
      }
      return b.currentStreak.compareTo(a.currentStreak);
    });

    final selectedHabit = uncompleted.first;
    final totalHabits = habits.length;
    final impact = ((1.0 / totalHabits) * 100).round().clamp(10, 35);

    return NextIdentityVote.actionable(
      habit: selectedHabit,
      attribute: selectedHabit.attribute,
      vitalityImpactPercent: impact,
      isRecovery: isRecovery,
    );
  }
}
