class GameLoopResult {
  final int newStreak;
  final int longestStreak;
  final int xpGained;
  final String attribute;
  final int newLevel;
  final int newTotalXp;
  final int newMomentumScore;
  final int newConsecutiveMisses;
  final bool isRecovery;
  final double worldHealthDelta;
  final Map<String, ChallengeProgressUpdate> challengeUpdates;

  const GameLoopResult({
    required this.newStreak,
    required this.longestStreak,
    required this.xpGained,
    required this.attribute,
    required this.newLevel,
    required this.newTotalXp,
    required this.newMomentumScore,
    required this.newConsecutiveMisses,
    required this.isRecovery,
    required this.worldHealthDelta,
    required this.challengeUpdates,
  });
}

class ChallengeProgressUpdate {
  final String challengeId;
  final int newDay;
  final bool isCompleted;
  final int? xpReward;

  const ChallengeProgressUpdate({
    required this.challengeId,
    required this.newDay,
    required this.isCompleted,
    this.xpReward,
  });
}
