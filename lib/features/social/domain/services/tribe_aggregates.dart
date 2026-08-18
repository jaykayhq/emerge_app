// lib/features/social/domain/services/tribe_aggregates.dart

/// One contributor row, pre-parsed from a Firestore doc so the aggregation
/// stays pure (no Firebase types in the domain layer).
class ContributorRecord {
  final int totalXpContributed;
  final int totalHabitsCompleted;
  final int totalChallengesCompleted;
  final DateTime? joinedAt;
  final DateTime? lastActivity;

  const ContributorRecord({
    this.totalXpContributed = 0,
    this.totalHabitsCompleted = 0,
    this.totalChallengesCompleted = 0,
    this.joinedAt,
    this.lastActivity,
  });
}

/// Aggregated tribe counters, matching the Node snapshot job exactly
/// (same sums, same 7-day windows) so client and server numbers agree.
class TribeContributorAggregate {
  final int totalXp;
  final int totalHabitsCompleted;
  final int totalChallengesCompleted;
  final int newMembers;
  final int activeMembers;

  const TribeContributorAggregate({
    required this.totalXp,
    required this.totalHabitsCompleted,
    required this.totalChallengesCompleted,
    required this.newMembers,
    required this.activeMembers,
  });
}

/// Sums contributor fields and counts new/active members within the 7-day
/// window ending at [now]. Mirrors `aggregateContributors` in
/// scripts/tribe-analytics-snapshot/snapshot.js.
TribeContributorAggregate aggregateTribeContributors({
  required Iterable<ContributorRecord> contributors,
  required DateTime now,
}) {
  var totalXp = 0;
  var totalHabits = 0;
  var totalChallenges = 0;
  var newMembers = 0;
  var activeMembers = 0;
  final weekAgo = now.subtract(const Duration(days: 7));

  for (final c in contributors) {
    totalXp += c.totalXpContributed;
    totalHabits += c.totalHabitsCompleted;
    totalChallenges += c.totalChallengesCompleted;

    final joinedAt = c.joinedAt;
    if (joinedAt != null && joinedAt.isAfter(weekAgo)) newMembers++;

    final lastActivity = c.lastActivity;
    if (lastActivity != null && lastActivity.isAfter(weekAgo)) {
      activeMembers++;
    }
  }

  return TribeContributorAggregate(
    totalXp: totalXp,
    totalHabitsCompleted: totalHabits,
    totalChallengesCompleted: totalChallenges,
    newMembers: newMembers,
    activeMembers: activeMembers,
  );
}
