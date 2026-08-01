/// Pure daily quota for free-tier narrator-coach asks.
///
/// Free users get [freeDailyLimit] asks per local calendar day; premium
/// users bypass the quota entirely. Deliberately free of storage/UI so it
/// can be unit-tested without Firebase (mirrors `decideRedirect`).
class CoachAskQuota {
  static const int freeDailyLimit = 3;

  /// Local calendar day key, e.g. '2026-08-01'.
  final String dateKey;

  /// Number of asks consumed today (free users only).
  final int usedToday;

  /// Whether the user is premium (bypasses the quota).
  final bool isPremium;

  const CoachAskQuota({
    required this.dateKey,
    required this.usedToday,
    required this.isPremium,
  });

  /// -1 for premium (unlimited); otherwise asks left today (0..limit).
  int get remaining =>
      isPremium ? -1 : (freeDailyLimit - usedToday).clamp(0, freeDailyLimit);

  bool get canAsk => isPremium || usedToday < freeDailyLimit;

  /// Returns a copy with the counter incremented. Premium users are
  /// unaffected so their stored counter can never grow unbounded.
  CoachAskQuota consume() => isPremium
      ? this
      : CoachAskQuota(
          dateKey: dateKey,
          usedToday: usedToday + 1,
          isPremium: isPremium,
        );

  static String dateKeyFor(DateTime now) {
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Rebuilds the quota from storage. If [storedKey] is not today's key,
  /// the counter resets to 0 (rollover).
  static CoachAskQuota fromStorage({
    required String storedKey,
    required int used,
    required bool isPremium,
    required DateTime now,
  }) {
    final today = dateKeyFor(now);
    return CoachAskQuota(
      dateKey: today,
      usedToday: storedKey == today ? used : 0,
      isPremium: isPremium,
    );
  }
}
