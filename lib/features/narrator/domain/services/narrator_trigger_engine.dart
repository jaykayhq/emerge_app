import 'package:emerge_app/features/narrator/domain/models/narrator_trigger.dart';

/// Contextual information about the current app open.
class AppOpenContext {
  /// The route the user is currently on.
  final String currentRoute;

  /// The current date/time.
  final DateTime now;

  /// Whether this is the very first app open ever.
  final bool isFirstAppOpen;

  /// Number of days since the app was first installed.
  final int daysSinceInstall;

  /// Number of days since the user last opened the app.
  final int daysSinceLastOpen;

  const AppOpenContext({
    required this.currentRoute,
    required this.now,
    required this.isFirstAppOpen,
    required this.daysSinceInstall,
    required this.daysSinceLastOpen,
  });
}

/// User statistics relevant to the Narrator trigger engine.
class NarratorUserStats {
  /// Momentum score (0.0 to 1.0).
  final double momentumScore;

  /// Number of consecutive active days.
  final int consecutiveActiveDays;

  /// Total habits scheduled for today.
  final int totalHabitsToday;

  /// Number of habits completed today.
  final int completedHabitsToday;

  /// The user's current level.
  final int currentLevel;

  /// The user's previous level (before the most recent change).
  final int previousLevel;

  /// Whether a streak break has been detected.
  final bool hasStreakBreak;

  /// The user's current streak.
  final int currentStreak;

  /// The user's longest streak.
  final int longestStreak;

  /// Number of consecutive misses.
  final int consecutiveMisses;

  /// Whether the user has already completed their evening reflection today.
  final bool hasCompletedEveningReflectionToday;

  /// Whether the user has completed onboarding.
  final bool hasCompletedOnboarding;

  /// Whether the user has selected an archetype.
  final bool archetypeSelected;

  const NarratorUserStats({
    required this.momentumScore,
    required this.consecutiveActiveDays,
    required this.totalHabitsToday,
    required this.completedHabitsToday,
    required this.currentLevel,
    required this.previousLevel,
    required this.hasStreakBreak,
    required this.currentStreak,
    required this.longestStreak,
    required this.consecutiveMisses,
    required this.hasCompletedEveningReflectionToday,
    required this.hasCompletedOnboarding,
    required this.archetypeSelected,
  });

  /// Creates a copy with the given fields replaced.
  NarratorUserStats copyWith({
    double? momentumScore,
    int? consecutiveActiveDays,
    int? totalHabitsToday,
    int? completedHabitsToday,
    int? currentLevel,
    int? previousLevel,
    bool? hasStreakBreak,
    int? currentStreak,
    int? longestStreak,
    int? consecutiveMisses,
    bool? hasCompletedEveningReflectionToday,
    bool? hasCompletedOnboarding,
    bool? archetypeSelected,
  }) {
    return NarratorUserStats(
      momentumScore: momentumScore ?? this.momentumScore,
      consecutiveActiveDays: consecutiveActiveDays ?? this.consecutiveActiveDays,
      totalHabitsToday: totalHabitsToday ?? this.totalHabitsToday,
      completedHabitsToday:
          completedHabitsToday ?? this.completedHabitsToday,
      currentLevel: currentLevel ?? this.currentLevel,
      previousLevel: previousLevel ?? this.previousLevel,
      hasStreakBreak: hasStreakBreak ?? this.hasStreakBreak,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      consecutiveMisses: consecutiveMisses ?? this.consecutiveMisses,
      hasCompletedEveningReflectionToday:
          hasCompletedEveningReflectionToday ??
              this.hasCompletedEveningReflectionToday,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      archetypeSelected: archetypeSelected ?? this.archetypeSelected,
    );
  }
}

/// Pure logic engine that determines whether the Narrator should appear.
///
/// This class has NO framework dependencies and is fully testable.
class NarratorTriggerEngine {
  /// Cooldown duration for most triggers (4 hours).
  static const Duration _cooldown = Duration(hours: 4);

  /// Determines whether the Narrator should trigger and returns the
  /// highest-priority trigger that matches, or `null` if none match.
  ///
  /// Priority ordering (highest first):
  ///   longAbsence > levelUp > streakBreakFirstMiss > onFireState >
  ///   weeklyRecap > morningBriefEarlyDays > eveningReflection
  static NarratorTrigger? shouldTrigger({
    required AppOpenContext context,
    required NarratorUserStats stats,
    required Map<NarratorTrigger, DateTime> recentTriggers,
  }) {
    // Check triggers in priority order.
    final now = context.now;
    final candidates = <NarratorTrigger?>[
      _checkLongAbsence(context, stats, recentTriggers),
      _checkLevelUp(stats, now, recentTriggers),
      _checkStreakBreakFirstMiss(stats, now, recentTriggers),
      _checkOnFireState(stats, now, recentTriggers),
      _checkWeeklyRecap(context, recentTriggers),
      _checkMorningBriefEarlyDays(context, stats, recentTriggers),
      _checkEveningReflection(context, stats, recentTriggers),
    ];

    for (final trigger in candidates) {
      if (trigger != null) return trigger;
    }
    return null;
  }

  /// Returns the askNarrator trigger for explicit user-initiated opens.
  /// No cooldown applies (user-driven).
  static NarratorTrigger resolveAskNarratorTrigger() => NarratorTrigger.askNarrator;

  /// Helper to detect if a streak break should trigger.
  static bool shouldTriggerOnStreakBreak({required int consecutiveMisses}) {
    return consecutiveMisses > 0;
  }

  // ---------------------------------------------------------------------------
  // Individual trigger checks
  // ---------------------------------------------------------------------------

  static NarratorTrigger? _checkLongAbsence(
    AppOpenContext context,
    NarratorUserStats stats,
    Map<NarratorTrigger, DateTime> recentTriggers,
  ) {
    if (context.daysSinceLastOpen >= 3 &&
        !_isOnCooldown(NarratorTrigger.longAbsence, context.now, recentTriggers)) {
      return NarratorTrigger.longAbsence;
    }
    return null;
  }

  static NarratorTrigger? _checkLevelUp(
    NarratorUserStats stats,
    DateTime now,
    Map<NarratorTrigger, DateTime> recentTriggers,
  ) {
    if (stats.currentLevel > stats.previousLevel &&
        !_isOnCooldown(NarratorTrigger.levelUp, now, recentTriggers)) {
      return NarratorTrigger.levelUp;
    }
    return null;
  }

  static NarratorTrigger? _checkStreakBreakFirstMiss(
    NarratorUserStats stats,
    DateTime now,
    Map<NarratorTrigger, DateTime> recentTriggers,
  ) {
    if (shouldTriggerOnStreakBreak(consecutiveMisses: stats.consecutiveMisses) &&
        !_isOnCooldown(NarratorTrigger.streakBreakFirstMiss, now, recentTriggers)) {
      return NarratorTrigger.streakBreakFirstMiss;
    }
    return null;
  }

  static NarratorTrigger? _checkOnFireState(
    NarratorUserStats stats,
    DateTime now,
    Map<NarratorTrigger, DateTime> recentTriggers,
  ) {
    if (stats.momentumScore >= 0.8 &&
        stats.consecutiveActiveDays >= 7 &&
        !_isOnCooldown(NarratorTrigger.onFireState, now, recentTriggers)) {
      return NarratorTrigger.onFireState;
    }
    return null;
  }

  static NarratorTrigger? _checkWeeklyRecap(
    AppOpenContext context,
    Map<NarratorTrigger, DateTime> recentTriggers,
  ) {
    // Trigger on day 7, 14, 21, etc.
    if (context.daysSinceInstall > 0 &&
        context.daysSinceInstall % 7 == 0 &&
        !_isOnCooldown(NarratorTrigger.weeklyRecap, context.now, recentTriggers)) {
      return NarratorTrigger.weeklyRecap;
    }
    return null;
  }

  static NarratorTrigger? _checkMorningBriefEarlyDays(
    AppOpenContext context,
    NarratorUserStats stats,
    Map<NarratorTrigger, DateTime> recentTriggers,
  ) {
    if (context.daysSinceInstall <= 5 &&
        stats.hasCompletedOnboarding &&
        stats.archetypeSelected &&
        !_isOnCooldown(NarratorTrigger.morningBriefEarlyDays, context.now, recentTriggers)) {
      return NarratorTrigger.morningBriefEarlyDays;
    }
    return null;
  }

  static NarratorTrigger? _checkEveningReflection(
    AppOpenContext context,
    NarratorUserStats stats,
    Map<NarratorTrigger, DateTime> recentTriggers,
  ) {
    if (!stats.hasCompletedEveningReflectionToday &&
        context.now.hour >= 18 && // 6 PM or later
        !_isOnCooldown(NarratorTrigger.eveningReflection, context.now, recentTriggers)) {
      return NarratorTrigger.eveningReflection;
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Cooldown helpers
  // ---------------------------------------------------------------------------

  /// Checks whether the given trigger is on cooldown.
  static bool _isOnCooldown(
    NarratorTrigger trigger,
    DateTime now,
    Map<NarratorTrigger, DateTime> recentTriggers,
  ) {
    final lastTriggered = recentTriggers[trigger];
    if (lastTriggered == null) return false;

    return now.difference(lastTriggered) < _cooldown;
  }
}
