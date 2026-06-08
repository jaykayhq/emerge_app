import 'package:emerge_app/core/drift/app_database.dart';

/// The Pattern Recognition Service (part of the Goldilocks Engine)
/// processes raw HabitCompletions history into aggregated velocity
/// and drop-off patterns for the AI Coach to interpret.
class PatternRecognitionService {
  /// Analyzes a list of habit completions to extract completion velocities
  /// and drop-off patterns.
  static Map<String, dynamic> analyzePatterns(
    List<HabitCompletionsTableData> completions, {
    DateTime? referenceDate,
  }) {
    if (completions.isEmpty) {
      return {'status': 'No recent history'};
    }

    final now = referenceDate ?? DateTime.now();

    // Group completions by habitId
    final Map<String, List<DateTime>> completionsByHabit = {};
    for (final c in completions) {
      final date = DateTime.tryParse(c.completedAt);
      if (date != null) {
        completionsByHabit.putIfAbsent(c.habitId, () => []).add(date);
      }
    }

    final Map<String, dynamic> habitSummaries = {};

    completionsByHabit.forEach((habitId, dates) {
      dates.sort(); // Oldest to newest
      
      int last7DaysCount = 0;
      int previous7DaysCount = 0;
      
      for (final date in dates) {
        final diff = now.difference(date).inDays;
        // Looking at past 14 days
        if (diff >= 0 && diff < 7) {
          last7DaysCount++;
        } else if (diff >= 7 && diff < 14) {
          previous7DaysCount++;
        }
      }
      
      String velocity = 'steady';
      if (last7DaysCount > previous7DaysCount) {
        velocity = 'accelerating';
      } else if (last7DaysCount < previous7DaysCount && previous7DaysCount > 0) {
        velocity = 'dropping off';
      }

      habitSummaries[habitId] = {
        'totalCompletions': dates.length,
        'recentVelocity': velocity,
        'last7Days': last7DaysCount,
        'previous7Days': previous7DaysCount,
      };
    });

    return {
      'analyzedHabitsCount': completionsByHabit.length,
      'details': habitSummaries,
    };
  }
}
