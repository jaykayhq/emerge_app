// test/features/social/domain/services/tribe_aggregates_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/social/domain/services/tribe_aggregates.dart';

void main() {
  final now = DateTime.utc(2026, 8, 18, 12, 0);

  ContributorRecord record({
    int xp = 0,
    int habits = 0,
    int challenges = 0,
    DateTime? joinedAt,
    DateTime? lastActivity,
  }) {
    return ContributorRecord(
      totalXpContributed: xp,
      totalHabitsCompleted: habits,
      totalChallengesCompleted: challenges,
      joinedAt: joinedAt,
      lastActivity: lastActivity,
    );
  }

  test('sums contributor fields', () {
    final agg = aggregateTribeContributors(contributors: [
      record(xp: 3000, habits: 40, challenges: 2),
      record(xp: 2000, habits: 20, challenges: 1),
      record(),
    ], now: now);

    expect(agg.totalXp, 5000);
    expect(agg.totalHabitsCompleted, 60);
    expect(agg.totalChallengesCompleted, 3);
  });

  test('counts new members from the 7-day window', () {
    final agg = aggregateTribeContributors(contributors: [
      record(joinedAt: now.subtract(const Duration(days: 1))),
      record(joinedAt: now.subtract(const Duration(days: 8))),
      record(joinedAt: null),
    ], now: now);

    expect(agg.newMembers, 1);
  });

  test('counts active members from the 7-day window', () {
    final agg = aggregateTribeContributors(contributors: [
      record(lastActivity: now.subtract(const Duration(hours: 1))),
      record(lastActivity: now.subtract(const Duration(days: 8))),
      record(lastActivity: null),
    ], now: now);

    expect(agg.activeMembers, 1);
  });

  test('boundary: 7 days exactly belongs to the previous window', () {
    final agg = aggregateTribeContributors(contributors: [
      record(
        joinedAt: now.subtract(const Duration(days: 7)),
        lastActivity: now.subtract(const Duration(days: 7)),
      ),
    ], now: now);

    expect(agg.newMembers, 0);
    expect(agg.activeMembers, 0);
  });

  test('empty contributors yield zeros', () {
    final agg = aggregateTribeContributors(contributors: const [], now: now);
    expect(agg.totalXp, 0);
    expect(agg.totalHabitsCompleted, 0);
    expect(agg.totalChallengesCompleted, 0);
    expect(agg.newMembers, 0);
    expect(agg.activeMembers, 0);
  });
}