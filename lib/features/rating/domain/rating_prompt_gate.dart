/// Signals a peak-satisfaction moment that qualifies for a rating prompt.
enum RatingPromptSignal { sevenDayStreak, challengeCompleted, emergeReveal }

/// Pure decision logic for the rating prompt gate — no Flutter, no Firebase.
class RatingPromptGate {
  const RatingPromptGate._();

  static const Duration defaultCooldown = Duration(days: 90);

  /// True when the prompt should be shown for [signal].
  ///
  /// Rules:
  /// - never ask if the user opted out ([dontAskAgain])
  /// - never ask twice in the same app version
  /// - never ask more often than [cooldown]
  static bool shouldAsk({
    required RatingPromptSignal signal,
    required DateTime now,
    required DateTime? lastAskedAt,
    required String? versionAskedFor,
    required bool dontAskAgain,
    required String currentVersion,
    required Duration cooldown,
  }) {
    if (dontAskAgain) return false;
    if (lastAskedAt == null) return true;
    if (versionAskedFor == currentVersion) return false;
    if (now.difference(lastAskedAt) < cooldown) return false;
    return true;
  }
}
