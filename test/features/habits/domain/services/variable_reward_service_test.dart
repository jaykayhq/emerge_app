import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/domain/services/variable_reward_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('calculateFinalXp', () {
    test('returns baseXp when streak is 0', () {
      final habit = Habit(
        id: 'h1', userId: 'u1', title: 'Test',
        createdAt: DateTime.now(),
      );
      expect(VariableRewardService.calculateFinalXp(habit: habit, baseXp: 100, currentStreak: 0), 100);
    });

    test('applies streak bonus correctly', () {
      final habit = Habit(
        id: 'h1', userId: 'u1', title: 'Test',
        createdAt: DateTime.now(),
      );
      // streak=7 -> (7/7)*0.1 = 0.1 -> 100 * 1.1 = 110
      expect(VariableRewardService.calculateFinalXp(habit: habit, baseXp: 100, currentStreak: 7), 110);
    });

    test('caps streak bonus at 50%', () {
      final habit = Habit(
        id: 'h1', userId: 'u1', title: 'Test',
        createdAt: DateTime.now(),
      );
      // streak=35 -> (35/7)*0.1 = 0.5 -> 100 * 1.5 = 150 (exactly at cap)
      expect(VariableRewardService.calculateFinalXp(habit: habit, baseXp: 100, currentStreak: 35), 150);
      // streak=70 -> (70/7)*0.1 = 1.0 clamped to 0.5 -> 100 * 1.5 = 150
      expect(VariableRewardService.calculateFinalXp(habit: habit, baseXp: 100, currentStreak: 70), 150);
    });
  });

  group('isStreakMilestone', () {
    test('returns true for known milestones', () {
      for (final milestone in VariableRewardService.streakMilestones) {
        expect(VariableRewardService.isStreakMilestone(milestone), isTrue);
      }
    });

    test('returns false for non-milestone streaks', () {
      expect(VariableRewardService.isStreakMilestone(0), isFalse);
      expect(VariableRewardService.isStreakMilestone(1), isFalse);
      expect(VariableRewardService.isStreakMilestone(5), isFalse);
      expect(VariableRewardService.isStreakMilestone(100), isFalse);
      expect(VariableRewardService.isStreakMilestone(500), isFalse);
    });
  });

  group('getNextMilestone', () {
    test('returns 7 when streak is 0', () {
      expect(VariableRewardService.getNextMilestone(0), 7);
    });

    test('returns next milestone above current streak', () {
      expect(VariableRewardService.getNextMilestone(7), 14);
      expect(VariableRewardService.getNextMilestone(90), 180);
    });

    test('returns null when no milestone above current streak', () {
      expect(VariableRewardService.getNextMilestone(365), isNull);
      expect(VariableRewardService.getNextMilestone(500), isNull);
    });
  });

  group('daysToNextMilestone', () {
    test('returns correct days remaining', () {
      expect(VariableRewardService.daysToNextMilestone(0), 7);
      expect(VariableRewardService.daysToNextMilestone(5), 2);
      expect(VariableRewardService.daysToNextMilestone(60), 30);
    });

    test('returns 0 when past all milestones', () {
      expect(VariableRewardService.daysToNextMilestone(365), 0);
      expect(VariableRewardService.daysToNextMilestone(500), 0);
    });
  });

  group('getMilestoneMessage', () {
    test('returns correct message for day 7', () {
      expect(VariableRewardService.getMilestoneMessage(7),
          "One week streak! You're building momentum!");
    });

    test('returns correct message for day 14', () {
      expect(VariableRewardService.getMilestoneMessage(14),
          "Two weeks! Your discipline is showing.");
    });

    test('returns correct message for day 30', () {
      expect(VariableRewardService.getMilestoneMessage(30),
          "One month! You're becoming consistent.");
    });

    test('returns correct message for day 60', () {
      expect(VariableRewardService.getMilestoneMessage(60),
          "Two months! This is a real habit now.");
    });

    test('returns correct message for day 90', () {
      expect(VariableRewardService.getMilestoneMessage(90),
          "90 days! You're proving yourself.");
    });

    test('returns correct message for day 180', () {
      expect(VariableRewardService.getMilestoneMessage(180),
          "Half a year! Incredible dedication.");
    });

    test('returns correct message for day 365', () {
      expect(VariableRewardService.getMilestoneMessage(365),
          "One full year! You're legendary!");
    });

    test('returns default message for unknown streak', () {
      expect(VariableRewardService.getMilestoneMessage(0),
          "Great job! Keep it going!");
      expect(VariableRewardService.getMilestoneMessage(100),
          "Great job! Keep it going!");
    });
  });

  group('XpRewardBreakdown', () {
    test('constructor sets all fields', () {
      final breakdown = const XpRewardBreakdown(
        baseXp: 100,
        streakBonus: 10,
        randomBonus: 5,
        milestoneBonus: 20,
        totalXp: 135,
      );
      expect(breakdown.baseXp, 100);
      expect(breakdown.streakBonus, 10);
      expect(breakdown.randomBonus, 5);
      expect(breakdown.milestoneBonus, 20);
      expect(breakdown.totalXp, 135);
    });

    test('summary includes all bonuses when present', () {
      final breakdown = const XpRewardBreakdown(
        baseXp: 100,
        streakBonus: 10,
        randomBonus: 5,
        milestoneBonus: 20,
        totalXp: 135,
      );
      expect(breakdown.summary, 'Base: +100, Streak: +10, Lucky: +5, Milestone: +20');
    });

    test('summary excludes zero bonuses', () {
      final breakdown = const XpRewardBreakdown(
        baseXp: 100,
        streakBonus: 0,
        randomBonus: 0,
        milestoneBonus: 0,
        totalXp: 100,
      );
      expect(breakdown.summary, 'Base: +100');
    });
  });

  group('calculateXpBreakdown', () {
    test('returns no bonuses when streak is 0', () {
      final habit = Habit(
        id: 'h1', userId: 'u1', title: 'Test',
        createdAt: DateTime.now(),
      );
      final breakdown = calculateXpBreakdown(habit: habit, baseXp: 100, currentStreak: 0);
      expect(breakdown.baseXp, 100);
      expect(breakdown.streakBonus, 0);
      expect(breakdown.randomBonus, 0);
      expect(breakdown.milestoneBonus, 0);
      expect(breakdown.totalXp, 100);
    });

    test('applies streak bonus correctly', () {
      final habit = Habit(
        id: 'h1', userId: 'u1', title: 'Test',
        createdAt: DateTime.now(),
      );
      // streak=7 -> factor=(7/7)*0.1=0.1 -> streakBonus=0.1*100=10, total=110
      final breakdown = calculateXpBreakdown(habit: habit, baseXp: 100, currentStreak: 7);
      expect(breakdown.streakBonus, 10);
      expect(breakdown.totalXp, 110);
    });

    test('caps streak bonus at 50%', () {
      final habit = Habit(
        id: 'h1', userId: 'u1', title: 'Test',
        createdAt: DateTime.now(),
      );
      // streak=35 -> factor=0.5 (exact cap) -> streakBonus=0.5*50=25, total=75
      final breakdown = calculateXpBreakdown(habit: habit, baseXp: 50, currentStreak: 35);
      expect(breakdown.streakBonus, 25);
      expect(breakdown.totalXp, 75);
    });
  });
}
