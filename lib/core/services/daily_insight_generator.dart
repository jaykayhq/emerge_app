/// Pure daily-insight message generator.
///
/// Client-side replacement for the Cloud Scheduler's `sendDailyInsights`
/// function (formerly `generateAIInsight` in functions/src/habit_notifications.ts).
/// The ladder is replicated exactly so messages stay identical to what users
/// received before: streak tiers first, then level, then XP, then a fallback.
library;

/// Generates the daily growth insight message from user stats.
String generateDailyInsight({
  required int level,
  required int streak,
  required int totalXp,
}) {
  if (streak >= 30) {
    return 'Extraordinary! Your $streak-day streak demonstrates '
        'exceptional consistency. You\'re building lasting change.';
  }
  if (streak >= 14) {
    return 'Impressive dedication! $streak days of progress. '
        'You\'ve established a strong foundation.';
  }
  if (streak >= 7) {
    return '$streak days strong! Research shows this is when habits '
        'start to feel automatic. Keep going!';
  }
  if (streak >= 3) {
    return '$streak days of momentum! You\'re building the neural '
        'pathways for lasting change.';
  }
  if (level > 5) {
    return 'Level $level achieved! Your consistency is paying off. '
        'Focus on maintaining quality over quantity.';
  }
  if (totalXp > 500) {
    return 'You\'ve accumulated $totalXp XP! Every action is a vote '
        'for the identity you\'re becoming.';
  }
  return 'Progress over perfection. Even small steps compound into '
      'remarkable transformations.';
}
