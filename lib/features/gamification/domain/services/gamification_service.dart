import 'package:emerge_app/core/constants/gamification_constants.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/gamification/domain/models/world_building.dart';
import 'package:emerge_app/features/gamification/domain/models/world_zone.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';

class GamificationService {
  // Zone growth/decay constants
  static const double healthGainOnComplete = 0.1;
  static const double healthLossOnMiss = 0.05;
  static const double dailyDecayRate = 0.03;
  static const int milestonesPerLevelBase = 10;

  /// Calculates XP gain based on habit difficulty and streak.
  int calculateXpGain(Habit habit) {
    double multiplier = GamificationConstants.difficultyEasyMultiplier;
    switch (habit.difficulty) {
      case HabitDifficulty.easy:
        multiplier = GamificationConstants.difficultyEasyMultiplier;
        break;
      case HabitDifficulty.medium:
        multiplier = GamificationConstants.difficultyMediumMultiplier;
        break;
      case HabitDifficulty.hard:
        multiplier = GamificationConstants.difficultyHardMultiplier;
        break;
    }

    // Streak bonus: +10% per 7 days, capped at 50%
    double streakBonus =
        (habit.currentStreak / GamificationConstants.daysPerStreakBonusStep) *
        GamificationConstants.streakBonusPerStep;
    if (streakBonus > GamificationConstants.maxStreakBonus) {
      streakBonus = GamificationConstants.maxStreakBonus;
    }

    return ((GamificationConstants.baseXpPerHabit * multiplier) *
            (1 + streakBonus))
        .round();
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
    int newSpirit = currentStats.spiritXp;

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
      case HabitAttribute.spirit:
        newSpirit += xp;
        break;
    }

    // Calculate total level based on total XP
    int totalXp =
        newStrength +
        newIntellect +
        newVitality +
        newCreativity +
        newFocus +
        newSpirit;
    int newLevel = calculateLevel(totalXp);

    return UserAvatarStats(
      strengthXp: newStrength,
      intellectXp: newIntellect,
      vitalityXp: newVitality,
      creativityXp: newCreativity,
      focusXp: newFocus,
      spiritXp: newSpirit,
      level: newLevel,
      streak: currentStats.streak,
    );
  }

  /// Centralized level calculation from total XP
  static int calculateLevel(int totalXp) {
    return (totalXp / GamificationConstants.xpPerLevel).floor() + 1;
  }

  /// Updates the world state when a habit is completed or missed
  UserWorldState updateWorldFromHabit({
    required UserWorldState currentState,
    required Habit habit,
    required bool completed,
  }) {
    // Find the zone linked to this habit's attribute
    final zone = WorldZone.getZoneForAttribute(habit.attribute);
    if (zone == null) return currentState;

    // Get current zone state
    final zoneData =
        currentState.zones[zone.id] ??
        {
          'zoneId': zone.id,
          'level': 1,
          'health': 1.0,
          'milestone': 0,
          'activeElements': <String>[],
        };

    double currentHealth = (zoneData['health'] as num?)?.toDouble() ?? 1.0;
    int currentMilestone = zoneData['milestone'] as int? ?? 0;
    int currentLevel = zoneData['level'] as int? ?? 1;

    if (completed) {
      // Increase health and milestone
      currentHealth = (currentHealth + healthGainOnComplete).clamp(0.0, 1.0);
      currentMilestone += 1;

      // Check for level up
      final milestonesNeeded = currentLevel * milestonesPerLevelBase;
      if (currentMilestone >= milestonesNeeded) {
        currentLevel += 1;
        currentMilestone = 0; // Reset milestone for next level
      }
    } else {
      // Decrease health on miss
      currentHealth = (currentHealth - healthLossOnMiss).clamp(0.0, 1.0);
    }

    // Update zone state
    final updatedZones = Map<String, Map<String, dynamic>>.from(
      currentState.zones,
    );
    updatedZones[zone.id] = {
      'zoneId': zone.id,
      'level': currentLevel,
      'health': currentHealth,
      'milestone': currentMilestone,
      'activeElements': zoneData['activeElements'] ?? <String>[],
      'lastUpdated': DateTime.now().toIso8601String(),
    };

    // Recalculate global entropy based on zone health
    double totalHealth = 0;
    int zoneCount = 0;
    for (final z in updatedZones.values) {
      totalHealth += (z['health'] as num?)?.toDouble() ?? 1.0;
      zoneCount++;
    }
    final avgHealth = zoneCount > 0 ? totalHealth / zoneCount : 1.0;
    final newEntropy = 1.0 - avgHealth;

    return currentState.copyWith(
      zones: updatedZones,
      entropy: newEntropy.clamp(0.0, 1.0),
      lastActiveDate: DateTime.now(),
    );
  }

  /// Apply daily decay when user hasn't been active
  UserWorldState applyDailyDecay(UserWorldState currentState, int daysMissed) {
    if (daysMissed <= 0) return currentState;

    // Progressive decay: more days = more decay
    final totalDecay = (daysMissed * dailyDecayRate).clamp(0.0, 0.5);

    // Apply decay to all zones
    final updatedZones = Map<String, Map<String, dynamic>>.from(
      currentState.zones,
    );
    for (final entry in updatedZones.entries) {
      final currentHealth = (entry.value['health'] as num?)?.toDouble() ?? 1.0;
      updatedZones[entry.key] = Map<String, dynamic>.from(entry.value)
        ..['health'] = (currentHealth - totalDecay).clamp(0.0, 1.0);
    }

    return currentState.copyWith(
      zones: updatedZones,
      entropy: (currentState.entropy + totalDecay).clamp(0.0, 1.0),
      lastActiveDate: DateTime.now(),
    );
  }

  /// Get buildings available to unlock for a specific zone
  List<WorldBuilding> getAvailableBuildings(String zoneId, int zoneLevel) {
    return WorldBuildingCatalog.getBuildingsForZone(
      zoneId,
    ).where((b) => b.requiredZoneLevel <= zoneLevel).toList();
  }

  /// Get newly unlockable buildings after a level up
  List<WorldBuilding> getNewlyUnlockedBuildings(
    String zoneId,
    int newLevel,
    List<String> alreadyUnlocked,
  ) {
    return WorldBuildingCatalog.getBuildingsForZone(zoneId)
        .where(
          (b) =>
              b.requiredZoneLevel == newLevel &&
              !alreadyUnlocked.contains(b.id),
        )
        .toList();
  }

  /// Update seasonal state based on streak
  WorldSeason calculateSeason(int streak) {
    if (streak >= 90) return WorldSeason.winter; // Mastery
    if (streak >= 60) return WorldSeason.autumn; // Harvest
    if (streak >= 30) return WorldSeason.summer; // Growth
    return WorldSeason.spring; // Beginning
  }

  /// Calculates the new World State based on completed habits vs total habits.
  /// [entropy] increases if habits are missed.
  UserWorldState updateWorldState(
    UserWorldState currentState,
    List<Habit> habits,
  ) {
    // Filter active habits (not archived)
    final activeHabits = habits.where((h) => !h.isArchived).toList();
    if (activeHabits.isEmpty) return currentState;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Check which habits were completed today
    final completedToday = activeHabits.where((h) {
      if (h.lastCompletedDate == null) return false;
      final completedDate = DateTime(
        h.lastCompletedDate!.year,
        h.lastCompletedDate!.month,
        h.lastCompletedDate!.day,
      );
      return completedDate == today;
    }).length;

    final completionRate = completedToday / activeHabits.length;

    // Adjust entropy based on completion rate
    double newEntropy = currentState.entropy;
    if (completionRate >= 0.8) {
      // Great day - reduce entropy
      newEntropy -= 0.1;
    } else if (completionRate >= 0.5) {
      // Okay day - slight improvement
      newEntropy -= 0.02;
    } else if (completionRate < 0.3) {
      // Poor day - increase entropy
      newEntropy += 0.05;
    }

    return currentState.copyWith(
      entropy: newEntropy.clamp(0.0, 1.0),
      lastActiveDate: DateTime.now(),
      worldAge: currentState.worldAge + 1,
    );
  }

  UserWorldState applyEntropy(UserWorldState currentState, double amount) {
    double newEntropy = currentState.entropy + amount;
    if (newEntropy > 1.0) newEntropy = 1.0;
    return currentState.copyWith(entropy: newEntropy);
  }

  UserWorldState reduceEntropy(UserWorldState currentState, double amount) {
    double newEntropy = currentState.entropy - amount;
    if (newEntropy < 0.0) newEntropy = 0.0;
    return currentState.copyWith(entropy: newEntropy);
  }

  UserWorldState levelUpWorld(UserWorldState currentState, bool isCity) {
    return currentState.copyWith(
      cityLevel: isCity ? currentState.cityLevel + 1 : currentState.cityLevel,
      forestLevel: !isCity
          ? currentState.forestLevel + 1
          : currentState.forestLevel,
    );
  }

  /// Unlock a building in the world
  UserWorldState unlockBuilding(
    UserWorldState currentState,
    String buildingId,
  ) {
    if (currentState.unlockedBuildings.contains(buildingId)) {
      return currentState;
    }

    return currentState.copyWith(
      unlockedBuildings: [...currentState.unlockedBuildings, buildingId],
      totalBuildingsConstructed: currentState.totalBuildingsConstructed + 1,
    );
  }

  /// Place a building in the world
  UserWorldState placeBuilding(
    UserWorldState currentState,
    String buildingId,
    double x,
    double y,
  ) {
    final placement = {
      'buildingId': buildingId,
      'x': x,
      'y': y,
      'placedAt': DateTime.now().toIso8601String(),
    };

    // Remove any existing placement for this building
    final updatedPlacements =
        currentState.buildingPlacements
            .where((p) => p['buildingId'] != buildingId)
            .toList()
          ..add(placement);

    return currentState.copyWith(buildingPlacements: updatedPlacements);
  }
}
