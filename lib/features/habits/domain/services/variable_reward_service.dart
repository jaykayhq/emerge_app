import 'dart:math';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';

class VariableRewardService {
  static const double streakBonusMax = 0.5;
  static const double randomBonusChance = 0.15;
  static const double randomBonusMax = 0.3;

  static const List<int> streakMilestones = [
    7, 14, 30, 60, 90, 180, 365
  ];

  static int calculateFinalXp({
    required Habit habit,
    required int baseXp,
    required int currentStreak,
  }) {
    double xp = baseXp.toDouble();

    xp = _applyStreakBonus(xp, currentStreak);
    xp = _applyRandomBonus(xp);
    xp = _applyMilestoneBonus(xp, currentStreak);

    return xp.toInt();
  }

  static double _applyStreakBonus(double xp, int currentStreak) {
    if (currentStreak <= 0) return xp;

    final streakBonus = (currentStreak * 0.1).clamp(0.0, streakBonusMax);
    return xp * (1 + streakBonus);
  }

  static double _applyRandomBonus(double xp) {
    final random = Random();
    if (random.nextDouble() < randomBonusChance) {
      final bonusMultiplier = 1 + (random.nextDouble() * randomBonusMax);
      return xp * bonusMultiplier;
    }
    return xp;
  }

  static double _applyMilestoneBonus(double xp, int currentStreak) {
    if (streakMilestones.contains(currentStreak)) {
      return xp * 2;
    }
    return xp;
  }

  static bool isStreakMilestone(int streak) {
    return streakMilestones.contains(streak);
  }

  static int? getNextMilestone(int currentStreak) {
    for (final milestone in streakMilestones) {
      if (milestone > currentStreak) {
        return milestone;
      }
    }
    return null;
  }

  static int daysToNextMilestone(int currentStreak) {
    final nextMilestone = getNextMilestone(currentStreak);
    if (nextMilestone == null) return 0;
    return nextMilestone - currentStreak;
  }

  static String getMilestoneMessage(int streak) {
    switch (streak) {
      case 7:
        return "One week streak! You're building momentum!";
      case 14:
        return "Two weeks! Your discipline is showing.";
      case 30:
        return "One month! You're becoming consistent.";
      case 60:
        return "Two months! This is a real habit now.";
      case 90:
        return "90 days! You're proving yourself.";
      case 180:
        return "Half a year! Incredible dedication.";
      case 365:
        return "One full year! You're legendary!";
      default:
        return "Great job! Keep it going!";
    }
  }
}

class XpRewardBreakdown {
  final int baseXp;
  final double streakBonus;
  final double randomBonus;
  final double milestoneBonus;
  final int totalXp;

  const XpRewardBreakdown({
    required this.baseXp,
    required this.streakBonus,
    required this.randomBonus,
    required this.milestoneBonus,
    required this.totalXp,
  });

  String get summary {
    final parts = <String>[];
    parts.add('Base: +$baseXp');
    if (streakBonus > 0) parts.add('Streak: +${streakBonus.toInt()}');
    if (randomBonus > 0) parts.add('Lucky: +${randomBonus.toInt()}');
    if (milestoneBonus > 0) parts.add('Milestone: +${milestoneBonus.toInt()}');
    return parts.join(', ');
  }
}

XpRewardBreakdown calculateXpBreakdown({
  required Habit habit,
  required int baseXp,
  required int currentStreak,
}) {
  double xp = baseXp.toDouble();
  double streakBonus = 0;
  double randomBonus = 0;
  double milestoneBonus = 0;

  if (currentStreak > 0) {
    streakBonus = (currentStreak * 0.1).clamp(0.0, VariableRewardService.streakBonusMax);
    xp *= (1 + streakBonus);
  }

  final random = Random();
  if (random.nextDouble() < VariableRewardService.randomBonusChance) {
    randomBonus = xp * (random.nextDouble() * VariableRewardService.randomBonusMax);
    xp += randomBonus;
  }

  if (VariableRewardService.isStreakMilestone(currentStreak)) {
    milestoneBonus = baseXp.toDouble();
    xp *= 2;
  }

  return XpRewardBreakdown(
    baseXp: baseXp,
    streakBonus: streakBonus * baseXp,
    randomBonus: randomBonus,
    milestoneBonus: milestoneBonus,
    totalXp: xp.toInt(),
  );
}