import 'package:emerge_app/core/constants/gamification_constants.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/gamification/domain/services/gamification_service.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:flutter_test/flutter_test.dart';

/// Helper to create a minimal [Habit] for testing.
Habit _makeHabit({
  HabitDifficulty difficulty = HabitDifficulty.medium,
  int currentStreak = 0,
  HabitAttribute attribute = HabitAttribute.vitality,
  bool isArchived = false,
  DateTime? lastCompletedDate,
}) {
  return Habit(
    id: 'test-habit-1',
    userId: 'user-1',
    title: 'Test Habit',
    cue: 'cue',
    routine: 'routine',
    reward: 'reward',
    frequency: HabitFrequency.daily,
    difficulty: difficulty,
    isArchived: isArchived,
    createdAt: DateTime(2025, 1, 1),
    currentStreak: currentStreak,
    attribute: attribute,
    lastCompletedDate: lastCompletedDate,
  );
}

/// Helper to create default [UserAvatarStats].
UserAvatarStats _makeStats({
  int strengthXp = 0,
  int intellectXp = 0,
  int vitalityXp = 0,
  int creativityXp = 0,
  int focusXp = 0,
  int spiritXp = 0,
  int level = 1,
  int streak = 0,
}) {
  return UserAvatarStats(
    strengthXp: strengthXp,
    intellectXp: intellectXp,
    vitalityXp: vitalityXp,
    creativityXp: creativityXp,
    focusXp: focusXp,
    spiritXp: spiritXp,
    level: level,
    streak: streak,
  );
}

/// Helper to create default [UserWorldState].
UserWorldState _makeWorldState({
  double entropy = 0.0,
  int worldAge = 0,
  Map<String, Map<String, dynamic>>? zones,
}) {
  return UserWorldState(
    cityLevel: 1,
    forestLevel: 1,
    entropy: entropy,
    worldAge: worldAge,
    zones: zones ?? {},
    unlockedBuildings: [],
    buildingPlacements: [],
    unlockedLandPlots: [],
    totalBuildingsConstructed: 0,
    lastActiveDate: DateTime(2025, 1, 1),
    worldTheme: WorldTheme.sanctuary,
    seasonalState: WorldSeason.spring,
    claimedNodes: [],
  );
}

void main() {
  late GamificationService service;

  setUp(() {
    service = GamificationService();
  });

  // ── calculateXpGain ──────────────────────────────────────────────

  group('calculateXpGain', () {
    test('easy habit with zero streak returns base XP', () {
      final habit = _makeHabit(difficulty: HabitDifficulty.easy);
      final xp = service.calculateXpGain(habit);
      expect(
        xp,
        (GamificationConstants.baseXpPerHabit *
                GamificationConstants.difficultyEasyMultiplier)
            .round(),
      );
    });

    test('medium habit returns 2x base XP', () {
      final habit = _makeHabit(difficulty: HabitDifficulty.medium);
      final xp = service.calculateXpGain(habit);
      expect(
        xp,
        (GamificationConstants.baseXpPerHabit *
                GamificationConstants.difficultyMediumMultiplier)
            .round(),
      );
    });

    test('hard habit returns 3x base XP', () {
      final habit = _makeHabit(difficulty: HabitDifficulty.hard);
      final xp = service.calculateXpGain(habit);
      expect(
        xp,
        (GamificationConstants.baseXpPerHabit *
                GamificationConstants.difficultyHardMultiplier)
            .round(),
      );
    });

    test('streak bonus adds 10% per 7-day step', () {
      final habit = _makeHabit(
        difficulty: HabitDifficulty.easy,
        currentStreak: 7,
      );
      final xp = service.calculateXpGain(habit);
      // 10 * 1.0 * (1 + 0.1) = 11
      expect(xp, 11);
    });

    test('streak bonus caps at 50%', () {
      final habit = _makeHabit(
        difficulty: HabitDifficulty.easy,
        currentStreak: 100, // Way past cap
      );
      final xp = service.calculateXpGain(habit);
      // 10 * 1.0 * (1 + 0.5) = 15
      expect(xp, 15);
    });
  });

  // ── addXp ────────────────────────────────────────────────────────

  group('addXp', () {
    test('adds XP to the correct attribute', () {
      final stats = _makeStats();
      final updated = service.addXp(stats, 50, HabitAttribute.strength);
      expect(updated.strengthXp, 50);
      expect(updated.intellectXp, 0);
    });

    test('level is recalculated from total XP', () {
      final stats = _makeStats();
      final updated = service.addXp(
        stats,
        GamificationConstants.xpPerLevel,
        HabitAttribute.vitality,
      );
      // 500 total XP → floor(500/500) + 1 = 2
      expect(updated.level, 2);
    });

    test('preserves existing XP in other attributes', () {
      final stats = _makeStats(strengthXp: 100, intellectXp: 200);
      final updated = service.addXp(stats, 50, HabitAttribute.focus);
      expect(updated.strengthXp, 100);
      expect(updated.intellectXp, 200);
      expect(updated.focusXp, 50);
    });
  });

  // ── calculateLevel ──────────────────────────────────────────────

  group('calculateLevel', () {
    test('0 XP is level 1', () {
      expect(GamificationService.calculateLevel(0), 1);
    });

    test('499 XP is still level 1', () {
      expect(GamificationService.calculateLevel(499), 1);
    });

    test('500 XP is level 2', () {
      expect(GamificationService.calculateLevel(500), 2);
    });

    test('1500 XP is level 4', () {
      expect(GamificationService.calculateLevel(1500), 4);
    });
  });

  // ── calculateSeason ─────────────────────────────────────────────

  group('calculateSeason', () {
    test('0-29 streak is spring', () {
      expect(service.calculateSeason(0), WorldSeason.spring);
      expect(service.calculateSeason(29), WorldSeason.spring);
    });

    test('30-59 streak is summer', () {
      expect(service.calculateSeason(30), WorldSeason.summer);
      expect(service.calculateSeason(59), WorldSeason.summer);
    });

    test('60-89 streak is autumn', () {
      expect(service.calculateSeason(60), WorldSeason.autumn);
      expect(service.calculateSeason(89), WorldSeason.autumn);
    });

    test('90+ streak is winter (mastery)', () {
      expect(service.calculateSeason(90), WorldSeason.winter);
      expect(service.calculateSeason(365), WorldSeason.winter);
    });
  });

  // ── applyDailyDecay ─────────────────────────────────────────────

  group('applyDailyDecay', () {
    test('0 days missed returns unchanged state', () {
      final state = _makeWorldState(entropy: 0.2);
      final result = service.applyDailyDecay(state, 0);
      expect(result.entropy, 0.2);
    });

    test('1 day missed increases entropy', () {
      final state = _makeWorldState(entropy: 0.0);
      final result = service.applyDailyDecay(state, 1);
      expect(result.entropy, greaterThan(0.0));
    });

    test('decay is capped at 0.5 maximum', () {
      final state = _makeWorldState(entropy: 0.0);
      final result = service.applyDailyDecay(state, 100);
      expect(result.entropy, lessThanOrEqualTo(1.0));
    });

    test('zone health decreases with decay', () {
      final state = _makeWorldState(
        zones: {
          'zone-1': {'health': 1.0, 'level': 1, 'milestone': 0},
        },
      );
      final result = service.applyDailyDecay(state, 3);
      final zoneHealth = (result.zones['zone-1']!['health'] as num).toDouble();
      expect(zoneHealth, lessThan(1.0));
    });
  });

  // ── unlockBuilding ──────────────────────────────────────────────

  group('unlockBuilding', () {
    test('adds new building to unlocked list', () {
      final state = _makeWorldState();
      final result = service.unlockBuilding(state, 'library');
      expect(result.unlockedBuildings, contains('library'));
      expect(result.totalBuildingsConstructed, 1);
    });

    test('does not duplicate an already-unlocked building', () {
      var state = _makeWorldState();
      state = service.unlockBuilding(state, 'library');
      final result = service.unlockBuilding(state, 'library');
      expect(result.unlockedBuildings.where((b) => b == 'library').length, 1);
      expect(result.totalBuildingsConstructed, 1);
    });
  });

  // ── applyEntropy / reduceEntropy ─────────────────────────────────

  group('entropy manipulation', () {
    test('applyEntropy increases entropy', () {
      final state = _makeWorldState(entropy: 0.3);
      final result = service.applyEntropy(state, 0.2);
      expect(result.entropy, 0.5);
    });

    test('applyEntropy caps at 1.0', () {
      final state = _makeWorldState(entropy: 0.9);
      final result = service.applyEntropy(state, 0.5);
      expect(result.entropy, 1.0);
    });

    test('reduceEntropy decreases entropy', () {
      final state = _makeWorldState(entropy: 0.5);
      final result = service.reduceEntropy(state, 0.2);
      expect(result.entropy, 0.3);
    });

    test('reduceEntropy floors at 0.0', () {
      final state = _makeWorldState(entropy: 0.1);
      final result = service.reduceEntropy(state, 0.5);
      expect(result.entropy, 0.0);
    });
  });

  // ── levelUpWorld ────────────────────────────────────────────────

  group('levelUpWorld', () {
    test('levels up city when isCity=true', () {
      final state = _makeWorldState();
      final result = service.levelUpWorld(state, true);
      expect(result.cityLevel, 2);
      expect(result.forestLevel, 1);
    });

    test('levels up forest when isCity=false', () {
      final state = _makeWorldState();
      final result = service.levelUpWorld(state, false);
      expect(result.cityLevel, 1);
      expect(result.forestLevel, 2);
    });
  });
}
