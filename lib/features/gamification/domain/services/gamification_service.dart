import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';

class GamificationService {
  static const int baseXpPerHabit = 10;
  static const int xpPerLevel = 100;

  /// Calculates XP gain based on habit difficulty and streak.
  int calculateXpGain(Habit habit) {
    int multiplier = 1;
    switch (habit.difficulty) {
      case HabitDifficulty.easy:
        multiplier = 1;
        break;
      case HabitDifficulty.medium:
        multiplier = 2;
        break;
      case HabitDifficulty.hard:
        multiplier = 3;
        break;
    }

    // Streak bonus: +10% per 7 days, capped at 50%
    double streakBonus = (habit.currentStreak / 7) * 0.1;
    if (streakBonus > 0.5) streakBonus = 0.5;

    return ((baseXpPerHabit * multiplier) * (1 + streakBonus)).round();
  }

  /// Returns a new UserAvatarStats with updated XP and potentially a new level.
  UserAvatarStats addXp(
    UserAvatarStats currentStats,
    int xp,
    HabitAttribute attribute,
  ) {
    int newStrength = currentStats.strengthXp;
    int newIntellect = currentStats.intellectXp;
    int newVitality = currentStats.vitalityXp;
    int newCreativity = currentStats.creativityXp;
    int newFocus = currentStats.focusXp;

    switch (attribute) {
      case HabitAttribute.strength:
        newStrength += xp;
        break;
      case HabitAttribute.intellect:
        newIntellect += xp;
        break;
      case HabitAttribute.vitality:
        newVitality += xp;
        break;
      case HabitAttribute.creativity:
        newCreativity += xp;
        break;
      case HabitAttribute.focus:
        newFocus += xp;
        break;
    }

    // Calculate total level based on total XP
    int totalXp =
        newStrength + newIntellect + newVitality + newCreativity + newFocus;
    int newLevel = (totalXp / xpPerLevel).floor() + 1;

    return UserAvatarStats(
      strengthXp: newStrength,
      intellectXp: newIntellect,
      vitalityXp: newVitality,
      creativityXp: newCreativity,
      focusXp: newFocus,
      level: newLevel,
    );
  }

  /// Calculates the new World State based on completed habits vs total habits.
  /// [entropy] increases if habits are missed.
  UserWorldState updateWorldState(
    UserWorldState currentState,
    List<Habit> habits,
  ) {
    // Logic:
    // 1. Calculate completion rate for yesterday/today.
    // 2. If missed, increase entropy.
    // 3. If completed, decrease entropy and potentially level up city/forest.

    // For now, simple logic:
    // - Each active habit that is NOT completed today adds 0.05 entropy (if checked at end of day).
    // - Each completed habit removes 0.1 entropy.
    // - City/Forest level grows with total completions (tracked elsewhere or derived).

    // This method might need to be called by a daily scheduler or when opening the app.
    // For this initial implementation, we'll just provide helper methods to modify state.
    return currentState;
  }

  UserWorldState applyEntropy(UserWorldState currentState, double amount) {
    double newEntropy = currentState.entropy + amount;
    if (newEntropy > 1.0) newEntropy = 1.0;
    return UserWorldState(
      cityLevel: currentState.cityLevel,
      forestLevel: currentState.forestLevel,
      entropy: newEntropy,
    );
  }

  UserWorldState reduceEntropy(UserWorldState currentState, double amount) {
    double newEntropy = currentState.entropy - amount;
    if (newEntropy < 0.0) newEntropy = 0.0;
    return UserWorldState(
      cityLevel: currentState.cityLevel,
      forestLevel: currentState.forestLevel,
      entropy: newEntropy,
    );
  }

  UserWorldState levelUpWorld(UserWorldState currentState, bool isCity) {
    return UserWorldState(
      cityLevel: isCity ? currentState.cityLevel + 1 : currentState.cityLevel,
      forestLevel: !isCity
          ? currentState.forestLevel + 1
          : currentState.forestLevel,
      entropy: currentState.entropy,
    );
  }
}
