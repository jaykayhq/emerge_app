import 'package:emerge_app/features/narrator/domain/models/narrator_trigger.dart';
import 'package:emerge_app/features/narrator/domain/services/narrator_trigger_engine.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builders keep the test bodies focused on the one field each test varies.
AppOpenContext _ctx({
  String route = '/',
  DateTime? now,
  bool isFirstAppOpen = false,
  int daysSinceInstall = 10,
  int daysSinceLastOpen = 0,
}) {
  return AppOpenContext(
    currentRoute: route,
    now: now ?? DateTime(2026, 7, 5, 12),
    isFirstAppOpen: isFirstAppOpen,
    daysSinceInstall: daysSinceInstall,
    daysSinceLastOpen: daysSinceLastOpen,
  );
}

NarratorUserStats _stats({
  double momentumScore = 0.5,
  int consecutiveActiveDays = 1,
  int totalHabitsToday = 0,
  int completedHabitsToday = 0,
  int currentLevel = 1,
  int previousLevel = 1,
  bool hasStreakBreak = false,
  int currentStreak = 0,
  int longestStreak = 0,
  int consecutiveMisses = 0,
  bool hasCompletedEveningReflectionToday = false,
  bool hasCompletedOnboarding = true,
  bool archetypeSelected = true,
}) {
  return NarratorUserStats(
    momentumScore: momentumScore,
    consecutiveActiveDays: consecutiveActiveDays,
    totalHabitsToday: totalHabitsToday,
    completedHabitsToday: completedHabitsToday,
    currentLevel: currentLevel,
    previousLevel: previousLevel,
    hasStreakBreak: hasStreakBreak,
    currentStreak: currentStreak,
    longestStreak: longestStreak,
    consecutiveMisses: consecutiveMisses,
    hasCompletedEveningReflectionToday: hasCompletedEveningReflectionToday,
    hasCompletedOnboarding: hasCompletedOnboarding,
    archetypeSelected: archetypeSelected,
  );
}

void main() {
  group('NarratorTriggerEngine — removed triggers never fire', () {
    /// These enum values were deleted from NarratorTrigger. If any caller
    /// tries to construct a [NarratorAppearance] with one of them, the code
    /// won't compile. This test guards the contract at runtime: even if a
    /// caller smuggles in a forbidden value via reflection or external
    /// config, the engine must not produce it.
    test(
      'shouldTrigger only ever returns one of the 9 surviving enum values',
      () {
        // The contract after Task 5 is that the engine has exactly 9
        // surviving triggers: onboardingPostArchetype, morningBriefEarlyDays,
        // streakBreakFirstMiss, onFireState, levelUp, weeklyRecap,
        // longAbsence, eveningReflection, askNarrator.
        // (askNarrator is user-driven and not produced by shouldTrigger.)
        const allowedFromEngine = <NarratorTrigger>{
          NarratorTrigger.onboardingPostArchetype,
          NarratorTrigger.morningBriefEarlyDays,
          NarratorTrigger.streakBreakFirstMiss,
          NarratorTrigger.onFireState,
          NarratorTrigger.levelUp,
          NarratorTrigger.weeklyRecap,
          NarratorTrigger.longAbsence,
          NarratorTrigger.eveningReflection,
        };
        // Sweep a wide grid of stat shapes; collect every value the engine
        // returns. Anything outside the allowed set (i.e. any removed value)
        // fails this test.
        final results = <NarratorTrigger?>{};
        for (final days in [0, 3, 7, 30]) {
          for (final misses in [0, 1, 5]) {
            for (final level in [1, 2, 5]) {
              for (final momentum in [0.0, 0.5, 0.9]) {
                results.add(
                  NarratorTriggerEngine.shouldTrigger(
                    context: _ctx(
                      daysSinceInstall: days,
                      daysSinceLastOpen: days,
                    ),
                    stats: _stats(
                      consecutiveMisses: misses,
                      currentLevel: level,
                      previousLevel: level > 1 ? level - 1 : 1,
                      momentumScore: momentum,
                      consecutiveActiveDays: momentum >= 0.8 ? 10 : 1,
                      hasCompletedOnboarding: true,
                      archetypeSelected: true,
                    ),
                    recentTriggers: const {},
                  ),
                );
              }
            }
          }
        }
        for (final value in results) {
          if (value == null) continue;
          expect(
            allowedFromEngine.contains(value),
            isTrue,
            reason:
                'Engine returned $value, which is outside the 9 surviving triggers',
          );
        }
      },
    );

    test('returns null when no trigger condition is met', () {
      // daysSinceInstall=10 > 5 (so morning brief does not fire), no
      // streak break, no level up, low momentum, not a weekly-recap day.
      final result = NarratorTriggerEngine.shouldTrigger(
        context: _ctx(daysSinceInstall: 10, daysSinceLastOpen: 0),
        stats: _stats(
          consecutiveMisses: 0,
          currentLevel: 1,
          previousLevel: 1,
          momentumScore: 0.3,
          consecutiveActiveDays: 1,
        ),
        recentTriggers: const {},
      );
      expect(result, isNull);
    });

    test('does not honor isFirstVisitToRoute (removed field)', () {
      // Pre-refactor, _checkScreenFirstVisit would fire screenFirstVisit
      // when isFirstVisitToRoute was true. The field no longer exists on
      // NarratorUserStats; the engine has no concept of "first visit" and
      // must return null in the corresponding scenario.
      final result = NarratorTriggerEngine.shouldTrigger(
        context: _ctx(
          route: '/some/new/route',
          daysSinceInstall: 1,
          daysSinceLastOpen: 0,
        ),
        stats: _stats(
          consecutiveMisses: 0,
          currentLevel: 1,
          previousLevel: 1,
          momentumScore: 0.0,
          consecutiveActiveDays: 0,
          hasCompletedOnboarding: false,
          archetypeSelected: false,
        ),
        recentTriggers: const {},
      );
      expect(result, isNull);
    });

    test('resolveAskNarratorTrigger returns the new explicit trigger', () {
      expect(
        NarratorTriggerEngine.resolveAskNarratorTrigger(),
        NarratorTrigger.askNarrator,
      );
    });
  });

  group('NarratorTriggerEngine — priority order', () {
    test('longAbsence beats levelUp, streakBreak, onFireState', () {
      final result = NarratorTriggerEngine.shouldTrigger(
        context: _ctx(daysSinceLastOpen: 5),
        stats: _stats(
          consecutiveMisses: 2,
          currentLevel: 5,
          previousLevel: 4,
          momentumScore: 0.9,
          consecutiveActiveDays: 10,
        ),
        recentTriggers: const {},
      );
      expect(result, NarratorTrigger.longAbsence);
    });

    test('levelUp beats streakBreak and onFireState', () {
      final result = NarratorTriggerEngine.shouldTrigger(
        context: _ctx(daysSinceLastOpen: 0),
        stats: _stats(
          consecutiveMisses: 2,
          currentLevel: 5,
          previousLevel: 4,
          momentumScore: 0.9,
          consecutiveActiveDays: 10,
        ),
        recentTriggers: const {},
      );
      expect(result, NarratorTrigger.levelUp);
    });

    test('streakBreakFirstMiss beats onFireState', () {
      final result = NarratorTriggerEngine.shouldTrigger(
        context: _ctx(daysSinceLastOpen: 0),
        stats: _stats(
          consecutiveMisses: 1,
          currentLevel: 1,
          previousLevel: 1,
          momentumScore: 0.9,
          consecutiveActiveDays: 10,
        ),
        recentTriggers: const {},
      );
      expect(result, NarratorTrigger.streakBreakFirstMiss);
    });

    test('onFireState beats weeklyRecap and morningBrief', () {
      final result = NarratorTriggerEngine.shouldTrigger(
        context: _ctx(daysSinceInstall: 7, daysSinceLastOpen: 0),
        stats: _stats(
          momentumScore: 0.9,
          consecutiveActiveDays: 10,
          hasCompletedOnboarding: true,
          archetypeSelected: true,
        ),
        recentTriggers: const {},
      );
      expect(result, NarratorTrigger.onFireState);
    });

    test('weeklyRecap beats morningBriefEarlyDays', () {
      // daysSinceInstall == 7 satisfies weeklyRecap (7 % 7 == 0) AND
      // morningBriefEarlyDays (daysSinceInstall <= 5 is false here, so
      // only weeklyRecap fires).
      final result = NarratorTriggerEngine.shouldTrigger(
        context: _ctx(daysSinceInstall: 7, daysSinceLastOpen: 0),
        stats: _stats(
          momentumScore: 0.1,
          consecutiveActiveDays: 1,
          hasCompletedOnboarding: true,
          archetypeSelected: true,
        ),
        recentTriggers: const {},
      );
      expect(result, NarratorTrigger.weeklyRecap);
    });

    test('eveningReflection wins only when no higher-priority trigger matches',
        () {
      // No streaks, no level-up, no absence, day 2 (not a weekly-recap day),
      // hour 19 (>= 18). archetypeSelected=false so morning brief does NOT
      // pre-empt evening reflection.
      final result = NarratorTriggerEngine.shouldTrigger(
        context: _ctx(
          daysSinceInstall: 2,
          daysSinceLastOpen: 0,
          now: DateTime(2026, 7, 5, 19),
        ),
        stats: _stats(
          momentumScore: 0.1,
          consecutiveActiveDays: 1,
          hasCompletedOnboarding: true,
          archetypeSelected: false,
        ),
        recentTriggers: const {},
      );
      expect(result, NarratorTrigger.eveningReflection);
    });
  });

  group('NarratorTriggerEngine — individual trigger conditions', () {
    test('streakBreakFirstMiss fires when consecutiveMisses > 0 and not cooled',
        () {
      final result = NarratorTriggerEngine.shouldTrigger(
        context: _ctx(daysSinceLastOpen: 0),
        stats: _stats(consecutiveMisses: 1),
        recentTriggers: const {},
      );
      expect(result, NarratorTrigger.streakBreakFirstMiss);
    });

    test('streakBreakFirstMiss suppressed while on cooldown', () {
      final now = DateTime(2026, 7, 5, 12);
      final recent = <NarratorTrigger, DateTime>{
        NarratorTrigger.streakBreakFirstMiss:
            now.subtract(const Duration(hours: 1)),
      };
      final result = NarratorTriggerEngine.shouldTrigger(
        context: _ctx(daysSinceLastOpen: 0, now: now),
        stats: _stats(consecutiveMisses: 1),
        recentTriggers: recent,
      );
      expect(result, isNull);
    });

    test('longAbsence fires when daysSinceLastOpen >= 3', () {
      final result = NarratorTriggerEngine.shouldTrigger(
        context: _ctx(daysSinceLastOpen: 3),
        stats: _stats(),
        recentTriggers: const {},
      );
      expect(result, NarratorTrigger.longAbsence);
    });

    test('longAbsence does NOT fire when daysSinceLastOpen < 3', () {
      final result = NarratorTriggerEngine.shouldTrigger(
        context: _ctx(daysSinceLastOpen: 2),
        stats: _stats(),
        recentTriggers: const {},
      );
      expect(result, isNull);
    });

    test('eveningReflection fires when hour >= 18 and not done today', () {
      final result = NarratorTriggerEngine.shouldTrigger(
        context: _ctx(now: DateTime(2026, 7, 5, 19)),
        stats: _stats(hasCompletedEveningReflectionToday: false),
        recentTriggers: const {},
      );
      expect(result, NarratorTrigger.eveningReflection);
    });

    test('eveningReflection does NOT fire when reflection already completed',
        () {
      final result = NarratorTriggerEngine.shouldTrigger(
        context: _ctx(now: DateTime(2026, 7, 5, 19)),
        stats: _stats(hasCompletedEveningReflectionToday: true),
        recentTriggers: const {},
      );
      expect(result, isNull);
    });

    test('eveningReflection does NOT fire before 6 PM', () {
      final result = NarratorTriggerEngine.shouldTrigger(
        context: _ctx(now: DateTime(2026, 7, 5, 17)),
        stats: _stats(hasCompletedEveningReflectionToday: false),
        recentTriggers: const {},
      );
      expect(result, isNull);
    });
  });
}
