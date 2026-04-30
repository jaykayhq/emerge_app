import 'package:emerge_app/features/habits/domain/entities/habit.dart';

class MomentumService {
  static const int _completionBoost = 10;
  static const int _missDecay = 5;
  static const int _idleDecay = 2;

  /// Called when a habit is completed today.
  Habit applyCompletion(Habit habit) {
    final newScore = (habit.momentumScore + _completionBoost).clamp(0, 100);
    return habit.copyWith(
      momentumScore: newScore,
      consecutiveMisses: 0,
    );
  }

  /// Called once per day for each habit NOT completed that day.
  Habit applyDailyDecay(Habit habit) {
    return applyMultiDayDecay(habit, 1);
  }

  /// Called when multiple days are missed.
  Habit applyMultiDayDecay(Habit habit, int daysMissed) {
    if (daysMissed <= 0) return habit;
    
    int newScore = habit.momentumScore;
    int consecutiveMisses = habit.consecutiveMisses;
    
    for (int i = 0; i < daysMissed; i++) {
      final decayAmount = consecutiveMisses > 0 ? _missDecay : _idleDecay;
      newScore = (newScore - decayAmount).clamp(0, 100);
      consecutiveMisses++;
    }
    
    return habit.copyWith(
      momentumScore: newScore,
      consecutiveMisses: consecutiveMisses,
    );
  }

  /// Compute world health score as the average momentum across all habits.
  int computeWorldHealth(List<Habit> habits) {
    final active = habits.where((h) => !h.isArchived).toList();
    if (active.isEmpty) return 50; // neutral default
    final total = active.fold<int>(0, (sum, h) => sum + h.momentumScore);
    return (total / active.length).round();
  }

  /// Human-readable momentum label for UI.
  String momentumLabel(HabitStreakState state) {
    switch (state) {
      case HabitStreakState.onFire:   return "On Fire 🔥";
      case HabitStreakState.strong:   return "Strong";
      case HabitStreakState.building: return "Building";
      case HabitStreakState.atRisk:   return "At Risk";
      case HabitStreakState.recovery: return "Recovery";
      case HabitStreakState.reset:    return "Fresh Start";
    }
  }
}
