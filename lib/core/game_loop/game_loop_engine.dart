import 'game_loop_result.dart';

class LocalGameLoopEngine {
  static const int _baseXpPerHabit = 10;
  static const int _xpPerLevel = 500;
  static const int _streakBonusStepDays = 7;
  static const double _streakBonusPerStep = 0.10;
  static const double _maxStreakBonus = 0.50;
  static const int _completionBoost = 10;

  int computeXpGain({
    required double difficultyMultiplier,
    required int streak,
  }) {
    double streakBonus = (streak / _streakBonusStepDays) * _streakBonusPerStep;
    if (streakBonus > _maxStreakBonus) streakBonus = _maxStreakBonus;
    return ((_baseXpPerHabit * difficultyMultiplier) * (1 + streakBonus))
        .round();
  }

  int computeLevel(int totalXp) {
    return (totalXp / _xpPerLevel).floor() + 1;
  }

  GameLoopResult processHabitCompletion({
    required int currentStreak,
    required int longestStreak,
    required int momentumScore,
    required int consecutiveMisses,
    required double difficultyMultiplier,
    required String attribute,
    required DateTime? lastCompletedDate,
    List<ChallengeProgressInput> activeChallenges = const [],
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (lastCompletedDate != null) {
      final lastDay = DateTime(
        lastCompletedDate.year,
        lastCompletedDate.month,
        lastCompletedDate.day,
      );
      if (lastDay == today) {
        return GameLoopResult(
          newStreak: currentStreak,
          longestStreak: longestStreak,
          xpGained: 0,
          attribute: attribute,
          newLevel: 0,
          newTotalXp: 0,
          newMomentumScore: momentumScore,
          newConsecutiveMisses: consecutiveMisses,
          isRecovery: false,
          worldHealthDelta: 0,
          challengeUpdates: {},
        );
      }
    }

    final isRecovery = consecutiveMisses > 0;
    final newStreak = currentStreak + 1;
    final newLongestStreak = newStreak > longestStreak
        ? newStreak
        : longestStreak;
    final xpGained = computeXpGain(
      difficultyMultiplier: difficultyMultiplier,
      streak: newStreak,
    );

    final newMomentumScore = (momentumScore + _completionBoost).clamp(0, 100);
    final newConsecutiveMisses = 0;

    final challengeUpdates = <String, ChallengeProgressUpdate>{};
    for (final challenge in activeChallenges) {
      if (challenge.attribute == null || challenge.attribute == attribute) {
        final challengeResult = processChallengeProgress(
          currentDay: challenge.currentDay,
          totalDays: challenge.totalDays,
          xpReward: challenge.xpReward,
        );
        challengeUpdates[challenge.challengeId] = ChallengeProgressUpdate(
          challengeId: challenge.challengeId,
          newDay: challengeResult.newDay,
          isCompleted: challengeResult.isCompleted,
          xpReward: challengeResult.xpReward,
        );
      }
    }

    return GameLoopResult(
      newStreak: newStreak,
      longestStreak: newLongestStreak,
      xpGained: xpGained,
      attribute: attribute,
      newLevel: 0,
      newTotalXp: xpGained,
      newMomentumScore: newMomentumScore,
      newConsecutiveMisses: newConsecutiveMisses,
      isRecovery: isRecovery,
      worldHealthDelta: _completionBoost / 100.0,
      challengeUpdates: challengeUpdates,
    );
  }

  ChallengeProgressUpdate processChallengeProgress({
    required int currentDay,
    required int totalDays,
    required int xpReward,
  }) {
    final newDay = currentDay + 1;
    final isCompleted = newDay >= totalDays;
    return ChallengeProgressUpdate(
      challengeId: '',
      newDay: newDay,
      isCompleted: isCompleted,
      xpReward: isCompleted ? xpReward : null,
    );
  }
}

class ChallengeProgressInput {
  final String challengeId;
  final int currentDay;
  final int totalDays;
  final int xpReward;
  final String? attribute;

  const ChallengeProgressInput({
    required this.challengeId,
    required this.currentDay,
    required this.totalDays,
    required this.xpReward,
    this.attribute,
  });
}
