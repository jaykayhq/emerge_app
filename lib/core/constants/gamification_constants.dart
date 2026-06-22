class GamificationConstants {
  /// Base XP earned for completing a habit
  static const int baseXpPerHabit = 10;

  /// XP required for each level (for a flat progression)
  static const int xpPerLevel = 500;

  /// XP earned from claimable world nodes (base)
  static const int baseNodeXpReward = 50;

  /// Multiplier for 'Easy' difficulty
  static const double difficultyEasyMultiplier = 1.0;

  /// Multiplier for 'Medium' difficulty
  static const double difficultyMediumMultiplier = 2.0;

  /// Multiplier for 'Hard' difficulty
  static const double difficultyHardMultiplier = 3.0;

  /// Maximum streak bonus percentage (0.5 = 50%)
  static const double maxStreakBonus = 0.5;

  /// Days of streak required for each 10% bonus
  static const int daysPerStreakBonusStep = 7;

  /// Bonus percentage per step
  static const double streakBonusPerStep = 0.1;

  /// XP required for each identity 'vote' (evolution of silhouette)
  static const int xpPerIdentityVote = 50;

  /// Total levels to reach maximum evolution stage
  static const int maxEvolutionLevel = 50;

  /// Phase thresholds (levels)
  /// Matches SilhouetteEvolutionState.phaseFromLevel() logic:
  ///   Phantom  1-5   (levels 1-5)
  ///   Construct  6-15
  ///   Incarnate 16-30
  ///   Radiant   31-50
  ///   Ascended  51+
  static const int phasePhantomMaxLevel = 5;
  static const int phaseConstructMaxLevel = 15;
  static const int phaseIncarnateMaxLevel = 30;
  /// Radiant spans 31-50. At level 50, progressInPhase returns 1.0
  /// and phaseFromLevel transitions to Ascended at level 50.
  static const int phaseRadiantMaxLevel = 50;
  // level 50+ is Ascended
}
