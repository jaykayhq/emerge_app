/// Premium state derived from a `users/{uid}` Firestore record.
///
/// Pure and time-injected so the pause/expiry matrix is unit-testable
/// without Firebase (the `decideRedirect` signature pattern).
class PremiumState {
  final bool isPremium;
  final bool isPaused;
  final DateTime? premiumEndsAt;

  const PremiumState({
    required this.isPremium,
    this.isPaused = false,
    this.premiumEndsAt,
  });
}

PremiumState computePremiumState({
  required Map<String, dynamic>? record,
  required DateTime now,
}) {
  if (record == null || record['isPremium'] != true) {
    return const PremiumState(isPremium: false);
  }

  final status = record['subscriptionStatus'] as String?;
  final endsAt = record['premiumEndsAt'] as DateTime?;

  if (status == 'paused') {
    if (endsAt != null && !endsAt.isAfter(now)) {
      return const PremiumState(isPremium: false);
    }
    return PremiumState(isPremium: true, isPaused: true, premiumEndsAt: endsAt);
  }

  return const PremiumState(isPremium: true);
}
