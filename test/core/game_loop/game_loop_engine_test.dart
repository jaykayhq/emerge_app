import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/core/game_loop/game_loop_engine.dart';

void main() {
  late LocalGameLoopEngine engine;

  setUp(() {
    engine = LocalGameLoopEngine();
  });

  group('computeXpGain', () {
    test('easy habit with 0 streak returns base XP', () {
      final xp = engine.computeXpGain(difficultyMultiplier: 1.0, streak: 0);
      expect(xp, 10);
    });

    test('hard habit with 0 streak returns 30 XP', () {
      final xp = engine.computeXpGain(difficultyMultiplier: 3.0, streak: 0);
      expect(xp, 30);
    });

    test('medium habit with 30-day streak gets ~42% bonus', () {
      final xp = engine.computeXpGain(difficultyMultiplier: 2.0, streak: 30);
      // 30/7 = 4.28 steps → 42.8% bonus → 20 * 1.428 = 28.57 → round = 29
      expect(xp, 29);
    });

    test('streak bonus capped at 50% even for 100-day streak', () {
      final xp = engine.computeXpGain(difficultyMultiplier: 1.0, streak: 100);
      expect(xp, 15);
    });

    test('negative streak is treated as 0', () {
      final xp = engine.computeXpGain(difficultyMultiplier: 1.0, streak: -5);
      expect(xp, 10);
    });

    test('zero difficulty multiplier returns 0 XP', () {
      final xp = engine.computeXpGain(difficultyMultiplier: 0.0, streak: 0);
      expect(xp, 0);
    });
  });

  group('computeLevel', () {
    test('0 XP returns level 1', () {
      expect(engine.computeLevel(0), 1);
    });

    test('499 XP returns level 1', () {
      expect(engine.computeLevel(499), 1);
    });

    test('500 XP returns level 2', () {
      expect(engine.computeLevel(500), 2);
    });

    test('1500 XP returns level 4', () {
      expect(engine.computeLevel(1500), 4);
    });

    test('negative XP returns level 1', () {
      expect(engine.computeLevel(-100), 1);
    });

    test('high XP at level boundary', () {
      expect(engine.computeLevel(5000), 11);
    });
  });

  group('processHabitCompletion', () {
    test('first completion sets streak to 1', () {
      final result = engine.processHabitCompletion(
        currentStreak: 0,
        longestStreak: 0,
        momentumScore: 0,
        consecutiveMisses: 0,
        difficultyMultiplier: 1.0,
        attribute: 'vitality',
        lastCompletedDate: null,
      );

      expect(result.newStreak, 1);
      expect(result.longestStreak, 1);
      expect(result.isRecovery, false);
    });

    test('consecutive completion increments streak', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final result = engine.processHabitCompletion(
        currentStreak: 5,
        longestStreak: 10,
        momentumScore: 50,
        consecutiveMisses: 0,
        difficultyMultiplier: 2.0,
        attribute: 'strength',
        lastCompletedDate: yesterday,
      );

      expect(result.newStreak, 6);
      expect(result.longestStreak, 10);
      // streak 6 gives ~8% bonus: 20 * 1.0857 = 21.71 -> 22
      expect(result.xpGained, 22);
    });

    test('completion after miss is recovery', () {
      final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
      final result = engine.processHabitCompletion(
        currentStreak: 0,
        longestStreak: 5,
        momentumScore: 10,
        consecutiveMisses: 3,
        difficultyMultiplier: 2.0,
        attribute: 'vitality',
        lastCompletedDate: twoDaysAgo,
      );

      expect(result.isRecovery, true);
      expect(result.newStreak, 1);
      expect(result.longestStreak, 5);
      expect(result.newMomentumScore, 20);
      expect(result.newConsecutiveMisses, 0);
    });

    test('same-day completion is idempotent', () {
      final today = DateTime.now();
      final result = engine.processHabitCompletion(
        currentStreak: 5,
        longestStreak: 5,
        momentumScore: 80,
        consecutiveMisses: 0,
        difficultyMultiplier: 1.0,
        attribute: 'focus',
        lastCompletedDate: today,
      );

      expect(result.newStreak, 5);
      expect(result.xpGained, 0);
      expect(result.newMomentumScore, 80);
    });

    test('challenge progress is computed when attribute matches', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final result = engine.processHabitCompletion(
        currentStreak: 0,
        longestStreak: 0,
        momentumScore: 0,
        consecutiveMisses: 0,
        difficultyMultiplier: 1.0,
        attribute: 'vitality',
        lastCompletedDate: yesterday,
        activeChallenges: [
          ChallengeProgressInput(
            challengeId: 'challenge_1',
            currentDay: 0,
            totalDays: 7,
            xpReward: 100,
            attribute: 'vitality',
          ),
        ],
      );

      expect(result.challengeUpdates.length, 1);
      expect(result.challengeUpdates['challenge_1']!.newDay, 1);
      expect(result.challengeUpdates['challenge_1']!.isCompleted, false);
    });

    test('challenge is marked complete on final day', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final result = engine.processHabitCompletion(
        currentStreak: 0,
        longestStreak: 0,
        momentumScore: 0,
        consecutiveMisses: 0,
        difficultyMultiplier: 1.0,
        attribute: 'vitality',
        lastCompletedDate: yesterday,
        activeChallenges: [
          ChallengeProgressInput(
            challengeId: 'challenge_2',
            currentDay: 6,
            totalDays: 7,
            xpReward: 100,
            attribute: 'vitality',
          ),
        ],
      );

      expect(result.challengeUpdates['challenge_2']!.newDay, 7);
      expect(result.challengeUpdates['challenge_2']!.isCompleted, true);
      expect(result.challengeUpdates['challenge_2']!.xpReward, 100);
    });
  });

  group('processChallengeProgress', () {
    test('day 1 of 7-day challenge', () {
      final result = engine.processChallengeProgress(
        currentDay: 0,
        totalDays: 7,
        xpReward: 100,
      );

      expect(result.newDay, 1);
      expect(result.isCompleted, false);
      expect(result.xpReward, null);
    });

    test('final day marks completed and awards XP', () {
      final result = engine.processChallengeProgress(
        currentDay: 6,
        totalDays: 7,
        xpReward: 100,
      );

      expect(result.newDay, 7);
      expect(result.isCompleted, true);
      expect(result.xpReward, 100);
    });

    test('day equals totalDays is completed', () {
      final result = engine.processChallengeProgress(
        currentDay: 7,
        totalDays: 7,
        xpReward: 100,
      );

      expect(result.newDay, 8);
      expect(result.isCompleted, true);
      expect(result.xpReward, 100);
    });
  });
}
