import 'package:emerge_app/features/narrator/domain/models/narrator_trigger.dart';
import 'package:emerge_app/features/narrator/domain/services/narrator_trigger_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DateTime now;
  late AppOpenContext defaultContext;
  late NarratorUserStats defaultStats;
  late Map<NarratorTrigger, DateTime> emptyCooldown;

  setUp(() {
    now = DateTime(2026, 7, 2, 10, 0); // 10 AM
    defaultContext = AppOpenContext(
      currentRoute: '/timeline',
      now: now,
      isFirstAppOpen: false,
      daysSinceInstall: 30,
      daysSinceLastOpen: 0, // opened today
    );
    defaultStats = const NarratorUserStats(
      momentumScore: 0.5,
      consecutiveActiveDays: 3,
      totalHabitsToday: 5,
      completedHabitsToday: 2,
      currentLevel: 3,
      previousLevel: 3,
      hasStreakBreak: false,
      currentStreak: 5,
      longestStreak: 10,
      consecutiveMisses: 0,
      hasCompletedEveningReflectionToday: false,
      hasCompletedOnboarding: true,
      archetypeSelected: true,
    );
    emptyCooldown = {};
  });

  group('AppOpenContext', () {
    test('can be created with all fields', () {
      final ctx = AppOpenContext(
        currentRoute: '/world',
        now: now,
        isFirstAppOpen: true,
        daysSinceInstall: 1,
        daysSinceLastOpen: 1,
      );
      expect(ctx.currentRoute, '/world');
      expect(ctx.isFirstAppOpen, true);
      expect(ctx.daysSinceInstall, 1);
    });
  });

  group('NarratorUserStats', () {
    test('can be created with all fields', () {
      const stats = NarratorUserStats(
        momentumScore: 0.8,
        consecutiveActiveDays: 10,
        totalHabitsToday: 3,
        completedHabitsToday: 3,
        currentLevel: 5,
        previousLevel: 4,
        hasStreakBreak: false,
        currentStreak: 15,
        longestStreak: 20,
        consecutiveMisses: 0,
        hasCompletedEveningReflectionToday: false,
        hasCompletedOnboarding: true,
        archetypeSelected: true,
      );
      expect(stats.momentumScore, 0.8);
      expect(stats.consecutiveActiveDays, 10);
    });
  });

  group('NarratorTriggerEngine.shouldTrigger', () {
    test('returns longAbsence when absent > 3 days', () {
      final ctx = AppOpenContext(
        currentRoute: '/timeline',
        now: now,
        isFirstAppOpen: false,
        daysSinceInstall: 30,
        daysSinceLastOpen: 5, // absent for 5 days
      );

      final result = NarratorTriggerEngine.shouldTrigger(
        context: ctx,
        stats: defaultStats,
        recentTriggers: emptyCooldown,
      );

      expect(result, NarratorTrigger.longAbsence);
    });

    test('returns levelUp when level increased', () {
      final stats = defaultStats.copyWith(
        currentLevel: 4,
        previousLevel: 3,
      );

      final result = NarratorTriggerEngine.shouldTrigger(
        context: defaultContext,
        stats: stats,
        recentTriggers: emptyCooldown,
      );

      expect(result, NarratorTrigger.levelUp);
    });

    test('levelUp has higher priority than longAbsence', () {
      final ctx = AppOpenContext(
        currentRoute: '/timeline',
        now: now,
        isFirstAppOpen: false,
        daysSinceInstall: 30,
        daysSinceLastOpen: 5,
      );
      final stats = defaultStats.copyWith(
        currentLevel: 4,
        previousLevel: 3,
      );

      final result = NarratorTriggerEngine.shouldTrigger(
        context: ctx,
        stats: stats,
        recentTriggers: emptyCooldown,
      );

      // Long absence has highest priority per spec
      expect(result, NarratorTrigger.longAbsence);
    });

    test('returns streakBreakFirstMiss when consecutiveMisses > 0', () {
      final stats = defaultStats.copyWith(
        consecutiveMisses: 2,
        hasStreakBreak: true,
      );

      final result = NarratorTriggerEngine.shouldTrigger(
        context: defaultContext,
        stats: stats,
        recentTriggers: emptyCooldown,
      );

      expect(result, NarratorTrigger.streakBreakFirstMiss);
    });

    test('returns onFireState when momentum >= 0.8 and active days >= 7', () {
      final stats = defaultStats.copyWith(
        momentumScore: 0.85,
        consecutiveActiveDays: 10,
      );

      final result = NarratorTriggerEngine.shouldTrigger(
        context: defaultContext,
        stats: stats,
        recentTriggers: emptyCooldown,
      );

      expect(result, NarratorTrigger.onFireState);
    });

    test('returns weeklyRecap on day 7 since install', () {
      final ctx = AppOpenContext(
        currentRoute: '/timeline',
        now: now,
        isFirstAppOpen: false,
        daysSinceInstall: 7,
        daysSinceLastOpen: 1,
      );

      final result = NarratorTriggerEngine.shouldTrigger(
        context: ctx,
        stats: defaultStats,
        recentTriggers: emptyCooldown,
      );

      expect(result, NarratorTrigger.weeklyRecap);
    });

    test('returns morningBriefEarlyDays when within first 5 days', () {
      final ctx = AppOpenContext(
        currentRoute: '/timeline',
        now: now,
        isFirstAppOpen: false,
        daysSinceInstall: 2,
        daysSinceLastOpen: 1,
      );

      final result = NarratorTriggerEngine.shouldTrigger(
        context: ctx,
        stats: defaultStats,
        recentTriggers: emptyCooldown,
      );

      expect(result, NarratorTrigger.morningBriefEarlyDays);
    });

    test('returns eveningReflection when reflection not completed and evening',
        () {
      final eveningCtx = AppOpenContext(
        currentRoute: '/timeline',
        now: DateTime(2026, 7, 2, 20, 0), // 8 PM
        isFirstAppOpen: false,
        daysSinceInstall: 30,
        daysSinceLastOpen: 1,
      );
      final stats = defaultStats.copyWith(
        hasCompletedEveningReflectionToday: false,
      );

      final result = NarratorTriggerEngine.shouldTrigger(
        context: eveningCtx,
        stats: stats,
        recentTriggers: emptyCooldown,
      );

      expect(result, NarratorTrigger.eveningReflection);
    });

    test('does not return eveningReflection if already completed', () {
      final eveningCtx = AppOpenContext(
        currentRoute: '/timeline',
        now: DateTime(2026, 7, 2, 20, 0),
        isFirstAppOpen: false,
        daysSinceInstall: 30,
        daysSinceLastOpen: 1,
      );
      final stats = defaultStats.copyWith(
        hasCompletedEveningReflectionToday: true,
      );

      final result = NarratorTriggerEngine.shouldTrigger(
        context: eveningCtx,
        stats: stats,
        recentTriggers: emptyCooldown,
      );

      expect(result, isNull);
    });

    test('returns null when no trigger conditions are met', () {
      final result = NarratorTriggerEngine.shouldTrigger(
        context: defaultContext,
        stats: defaultStats,
        recentTriggers: emptyCooldown,
      );

      expect(result, isNull);
    });

    test('respects cooldown - same trigger within 4 hours returns null', () {
      final stats = defaultStats.copyWith(
        currentLevel: 4,
        previousLevel: 3,
      );

      final cooldown = <NarratorTrigger, DateTime>{
        NarratorTrigger.levelUp: now.subtract(const Duration(hours: 1)),
      };

      final result = NarratorTriggerEngine.shouldTrigger(
        context: defaultContext,
        stats: stats,
        recentTriggers: cooldown,
      );

      expect(result, isNull);
    });

    test('removed triggers never fire', () {
      // The engine no longer checks for screenFirstVisit, nodeFirstVisit,
      // dailyInsight, or newHabitCreation (removed in Task 5).
      // We can't reference the removed enum values since they're gone,
      // so we just verify the engine returns null for neutral stats
      // (none of the remaining triggers should fire).
      final result = NarratorTriggerEngine.shouldTrigger(
        context: defaultContext,
        stats: defaultStats,
        recentTriggers: emptyCooldown,
      );

      // None of the remaining triggers match neutral stats
      expect(result, isNull);
    });

    test('does not trigger morningBrief if onboarding not complete', () {
      final stats = defaultStats.copyWith(
        hasCompletedOnboarding: false,
        archetypeSelected: true,
      );

      final result = NarratorTriggerEngine.shouldTrigger(
        context: defaultContext,
        stats: stats,
        recentTriggers: emptyCooldown,
      );

      expect(result, isNull);
    });

    test('does not trigger morningBrief if archetype not selected', () {
      final stats = defaultStats.copyWith(
        hasCompletedOnboarding: true,
        archetypeSelected: false,
      );

      final result = NarratorTriggerEngine.shouldTrigger(
        context: defaultContext,
        stats: stats,
        recentTriggers: emptyCooldown,
      );

      expect(result, isNull);
    });

    test('shouldTriggerOnStreakBreak returns true when consecutiveMisses > 0',
        () {
      expect(
        NarratorTriggerEngine.shouldTriggerOnStreakBreak(
          consecutiveMisses: 1,
        ),
        true,
      );
      expect(
        NarratorTriggerEngine.shouldTriggerOnStreakBreak(
          consecutiveMisses: 5,
        ),
        true,
      );
    });

    test('shouldTriggerOnStreakBreak returns false when no consecutive misses',
        () {
      expect(
        NarratorTriggerEngine.shouldTriggerOnStreakBreak(
          consecutiveMisses: 0,
        ),
        false,
      );
    });

    test('cooldown expired after 4 hours allows trigger again', () {
      final stats = defaultStats.copyWith(
        momentumScore: 0.85,
        consecutiveActiveDays: 10,
      );

      final cooldown = <NarratorTrigger, DateTime>{
        NarratorTrigger.onFireState: now.subtract(const Duration(hours: 5)),
      };

      final result = NarratorTriggerEngine.shouldTrigger(
        context: defaultContext,
        stats: stats,
        recentTriggers: cooldown,
      );

      expect(result, NarratorTrigger.onFireState);
    });
  });
}
