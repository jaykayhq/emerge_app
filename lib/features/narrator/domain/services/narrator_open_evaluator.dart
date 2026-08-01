import 'package:emerge_app/features/narrator/domain/models/narrator_trigger.dart';
import 'package:emerge_app/features/narrator/domain/services/narrator_trigger_engine.dart';

/// Pure input for a timeline-open narrator evaluation.
class NarratorOpenInput {
  final DateTime now;
  final DateTime? installedAt;
  final DateTime? lastOpenAt;
  final double momentumScore; // 0..1
  final int consecutiveActiveDays;
  final int currentStreak;
  final int longestStreak;
  final int consecutiveMisses;
  final bool hasCompletedOnboarding;
  final bool archetypeSelected;
  final Map<NarratorTrigger, DateTime> recentTriggers;

  const NarratorOpenInput({
    required this.now,
    this.installedAt,
    this.lastOpenAt,
    required this.momentumScore,
    required this.consecutiveActiveDays,
    required this.currentStreak,
    required this.longestStreak,
    required this.consecutiveMisses,
    required this.hasCompletedOnboarding,
    required this.archetypeSelected,
    this.recentTriggers = const {},
  });
}

/// Evaluates which narrator trigger (if any) should fire when the timeline
/// opens. Excludes [NarratorTrigger.weeklyRecap] and
/// [NarratorTrigger.eveningReflection] — those have dedicated surfaces
/// (recap hub / evening check-in). levelUp cannot fire here (no level delta
/// at open) — the engine's check simply won't match since previous == current.
class NarratorOpenEvaluator {
  static NarratorTrigger? evaluate(NarratorOpenInput input) {
    final context = AppOpenContext(
      currentRoute: '/timeline',
      now: input.now,
      isFirstAppOpen: input.installedAt == null,
      daysSinceInstall: input.installedAt == null
          ? 0
          : input.now.difference(input.installedAt!).inDays,
      daysSinceLastOpen: input.lastOpenAt == null
          ? 0
          : input.now.difference(input.lastOpenAt!).inDays,
    );
    final stats = NarratorUserStats(
      momentumScore: input.momentumScore,
      consecutiveActiveDays: input.consecutiveActiveDays,
      totalHabitsToday: 0,
      completedHabitsToday: 0,
      currentLevel: 1,
      previousLevel: 1,
      hasStreakBreak: input.consecutiveMisses > 0,
      currentStreak: input.currentStreak,
      longestStreak: input.longestStreak,
      consecutiveMisses: input.consecutiveMisses,
      hasCompletedEveningReflectionToday: true, // evening has its own surface
      hasCompletedOnboarding: input.hasCompletedOnboarding,
      archetypeSelected: input.archetypeSelected,
    );
    final trigger = NarratorTriggerEngine.shouldTrigger(
      context: context,
      stats: stats,
      recentTriggers: input.recentTriggers,
    );
    if (trigger == NarratorTrigger.weeklyRecap ||
        trigger == NarratorTrigger.eveningReflection) {
      return null;
    }
    return trigger;
  }
}
