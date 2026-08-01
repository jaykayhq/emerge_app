import 'package:emerge_app/features/narrator/domain/models/narrator_trigger.dart';
import 'package:emerge_app/features/narrator/domain/services/narrator_open_evaluator.dart';
import 'package:emerge_app/features/narrator/domain/services/narrator_trigger_engine.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds an [NarratorOpenInput] with sane defaults for a settled, engaged
/// user, so individual tests only override what they exercise.
NarratorOpenInput _input({
  required DateTime now,
  DateTime? installedAt,
  DateTime? lastOpenAt,
  double momentumScore = 0.5,
  int consecutiveActiveDays = 0,
  int currentStreak = 0,
  int longestStreak = 0,
  int consecutiveMisses = 0,
  bool hasCompletedOnboarding = true,
  bool archetypeSelected = true,
  Map<NarratorTrigger, DateTime> recentTriggers = const {},
}) {
  return NarratorOpenInput(
    now: now,
    installedAt: installedAt,
    lastOpenAt: lastOpenAt,
    momentumScore: momentumScore,
    consecutiveActiveDays: consecutiveActiveDays,
    currentStreak: currentStreak,
    longestStreak: longestStreak,
    consecutiveMisses: consecutiveMisses,
    hasCompletedOnboarding: hasCompletedOnboarding,
    archetypeSelected: archetypeSelected,
    recentTriggers: recentTriggers,
  );
}

void main() {
  group('NarratorOpenEvaluator', () {
    test('returns longAbsence when daysSinceLastOpen >= 3 and not on cooldown',
        () {
      final now = DateTime(2026, 8, 1, 9, 0);
      final result = NarratorOpenEvaluator.evaluate(
        _input(
          now: now,
          installedAt: now.subtract(const Duration(days: 10)),
          lastOpenAt: now.subtract(const Duration(days: 3)),
        ),
      );
      expect(result, NarratorTrigger.longAbsence);
    });

    test('nulls weeklyRecap even though the engine would fire it (day 7)',
        () {
      final now = DateTime(2026, 8, 1, 9, 0);
      final installedAt = now.subtract(const Duration(days: 7));
      final input = _input(
        now: now,
        installedAt: installedAt,
        lastOpenAt: now.subtract(const Duration(days: 1)),
      );

      // Premise: the raw engine fires weeklyRecap on day 7.
      final engineResult = NarratorTriggerEngine.shouldTrigger(
        context: AppOpenContext(
          currentRoute: '/timeline',
          now: now,
          isFirstAppOpen: false,
          daysSinceInstall: 7,
          daysSinceLastOpen: 1,
        ),
        stats: const NarratorUserStats(
          momentumScore: 0.5,
          consecutiveActiveDays: 0,
          totalHabitsToday: 0,
          completedHabitsToday: 0,
          currentLevel: 1,
          previousLevel: 1,
          hasStreakBreak: false,
          currentStreak: 0,
          longestStreak: 0,
          consecutiveMisses: 0,
          hasCompletedEveningReflectionToday: true,
          hasCompletedOnboarding: true,
          archetypeSelected: true,
        ),
        recentTriggers: const {},
      );
      expect(engineResult, NarratorTrigger.weeklyRecap);

      // The open evaluator must never surface weeklyRecap (recap hub owns it).
      expect(NarratorOpenEvaluator.evaluate(input), isNull);
    });

    test('never returns eveningReflection at open (evening has its own surface)',
        () {
      final now = DateTime(2026, 8, 1, 20, 0); // 8 PM
      final input = _input(
        now: now,
        installedAt: now.subtract(const Duration(days: 30)),
        lastOpenAt: now.subtract(const Duration(days: 1)),
      );

      // Premise: the raw engine would fire eveningReflection here when the
      // evening reflection is not yet completed.
      final engineResult = NarratorTriggerEngine.shouldTrigger(
        context: AppOpenContext(
          currentRoute: '/timeline',
          now: now,
          isFirstAppOpen: false,
          daysSinceInstall: 30,
          daysSinceLastOpen: 1,
        ),
        stats: const NarratorUserStats(
          momentumScore: 0.5,
          consecutiveActiveDays: 0,
          totalHabitsToday: 0,
          completedHabitsToday: 0,
          currentLevel: 1,
          previousLevel: 1,
          hasStreakBreak: false,
          currentStreak: 0,
          longestStreak: 0,
          consecutiveMisses: 0,
          hasCompletedEveningReflectionToday: false,
          hasCompletedOnboarding: true,
          archetypeSelected: true,
        ),
        recentTriggers: const {},
      );
      expect(engineResult, NarratorTrigger.eveningReflection);

      // The open evaluator pins hasCompletedEveningReflectionToday: true
      // (the evening check-in has its own surface) and filters the trigger.
      expect(NarratorOpenEvaluator.evaluate(input), isNull);
    });

    test('returns morningBriefEarlyDays within the first 5 days when '
        'onboarding is complete and an archetype is selected', () {
      final now = DateTime(2026, 8, 1, 9, 0);
      final result = NarratorOpenEvaluator.evaluate(
        _input(
          now: now,
          installedAt: now.subtract(const Duration(days: 3)),
          lastOpenAt: now.subtract(const Duration(days: 1)),
        ),
      );
      expect(result, NarratorTrigger.morningBriefEarlyDays);
    });

    test('does not return morningBriefEarlyDays when onboarding is incomplete',
        () {
      final now = DateTime(2026, 8, 1, 9, 0);
      final result = NarratorOpenEvaluator.evaluate(
        _input(
          now: now,
          installedAt: now.subtract(const Duration(days: 3)),
          lastOpenAt: now.subtract(const Duration(days: 1)),
          hasCompletedOnboarding: false,
          archetypeSelected: false,
        ),
      );
      expect(result, isNull);
    });

    test('respects cooldown — longAbsence fired 1 hour ago suppresses it', () {
      final now = DateTime(2026, 8, 1, 9, 0);
      final result = NarratorOpenEvaluator.evaluate(
        _input(
          now: now,
          installedAt: now.subtract(const Duration(days: 10)),
          lastOpenAt: now.subtract(const Duration(days: 3)),
          recentTriggers: {
            NarratorTrigger.longAbsence: now.subtract(const Duration(hours: 1)),
          },
        ),
      );
      expect(result, isNull);
    });

    test('returns streakBreakFirstMiss when there are consecutive misses', () {
      final now = DateTime(2026, 8, 1, 9, 0);
      final result = NarratorOpenEvaluator.evaluate(
        _input(
          now: now,
          installedAt: now.subtract(const Duration(days: 3)),
          lastOpenAt: now.subtract(const Duration(days: 1)),
          consecutiveMisses: 2,
        ),
      );
      expect(result, NarratorTrigger.streakBreakFirstMiss);
    });

    test('first app open (no install date) is treated as day 0', () {
      final now = DateTime(2026, 8, 1, 9, 0);
      // No installedAt/lastOpenAt: isFirstAppOpen => daysSinceInstall 0.
      // Day 0 is within the morning-brief window and cannot be weeklyRecap
      // (which requires daysSinceInstall > 0) or longAbsence.
      final result = NarratorOpenEvaluator.evaluate(
        _input(now: now),
      );
      expect(result, NarratorTrigger.morningBriefEarlyDays);
    });
  });
}
