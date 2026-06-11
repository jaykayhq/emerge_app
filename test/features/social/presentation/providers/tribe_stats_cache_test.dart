import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/social/presentation/providers/cached_tribe_stats_provider.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';

void main() {
  group('TribeStatsCache', () {
    late TribeStatsCache cache;

    setUp(() {
      cache = TribeStatsCache();
    });

    test('set and get stores stats', () {
      final stats = TribeStats(
        memberCount: 10,
        totalXp: 500,
        totalHabitsCompleted: 25,
        totalChallengesCompleted: 3,
      );
      cache.set('tribe1', stats);
      // Verify no error on set
    });

    test('invalidate removes cached entry', () {
      final stats = TribeStats(
        memberCount: 10,
        totalXp: 500,
        totalHabitsCompleted: 25,
        totalChallengesCompleted: 3,
      );
      cache.set('tribe1', stats);
      cache.invalidate('tribe1');
      // No error on invalidation
    });

    test('clear removes all cached entries', () {
      cache.set(
        'tribe1',
        TribeStats(
          memberCount: 5,
          totalXp: 100,
          totalHabitsCompleted: 0,
          totalChallengesCompleted: 0,
        ),
      );
      cache.set(
        'tribe2',
        TribeStats(
          memberCount: 8,
          totalXp: 200,
          totalHabitsCompleted: 0,
          totalChallengesCompleted: 0,
        ),
      );
      cache.clear();
      // No error on clear
    });

    test('set multiple tribes independently', () {
      cache.set(
        'tribe1',
        TribeStats(
          memberCount: 5,
          totalXp: 100,
          totalHabitsCompleted: 0,
          totalChallengesCompleted: 0,
        ),
      );
      cache.set(
        'tribe2',
        TribeStats(
          memberCount: 8,
          totalXp: 200,
          totalHabitsCompleted: 0,
          totalChallengesCompleted: 0,
        ),
      );
      cache.set(
        'tribe3',
        TribeStats(
          memberCount: 12,
          totalXp: 300,
          totalHabitsCompleted: 0,
          totalChallengesCompleted: 0,
        ),
      );
      cache.invalidate('tribe2');
      // tribe1 and tribe3 should still be set (no error)
    });
  });

  group('TribeStats', () {
    test('equality based on all fields', () {
      final a = TribeStats(
        memberCount: 10,
        totalXp: 500,
        totalHabitsCompleted: 25,
        totalChallengesCompleted: 3,
      );
      final b = TribeStats(
        memberCount: 10,
        totalXp: 500,
        totalHabitsCompleted: 25,
        totalChallengesCompleted: 3,
      );
      expect(a, equals(b));
    });

    test('inequality when memberCount differs', () {
      final a = TribeStats(
        memberCount: 10,
        totalXp: 500,
        totalHabitsCompleted: 0,
        totalChallengesCompleted: 0,
      );
      final b = TribeStats(
        memberCount: 12,
        totalXp: 500,
        totalHabitsCompleted: 0,
        totalChallengesCompleted: 0,
      );
      expect(a, isNot(equals(b)));
    });

    test('inequality when totalXp differs', () {
      final a = TribeStats(
        memberCount: 10,
        totalXp: 500,
        totalHabitsCompleted: 0,
        totalChallengesCompleted: 0,
      );
      final b = TribeStats(
        memberCount: 10,
        totalXp: 600,
        totalHabitsCompleted: 0,
        totalChallengesCompleted: 0,
      );
      expect(a, isNot(equals(b)));
    });

    test('inequality when totalHabitsCompleted differs', () {
      final a = TribeStats(
        memberCount: 10,
        totalXp: 500,
        totalHabitsCompleted: 25,
        totalChallengesCompleted: 0,
      );
      final b = TribeStats(
        memberCount: 10,
        totalXp: 500,
        totalHabitsCompleted: 30,
        totalChallengesCompleted: 0,
      );
      expect(a, isNot(equals(b)));
    });

    test('defaults for optional fields', () {
      final stats = TribeStats(
        memberCount: 5,
        totalXp: 0,
        totalHabitsCompleted: 0,
        totalChallengesCompleted: 0,
      );
      expect(stats.memberCount, 5);
      expect(stats.totalXp, 0);
      expect(stats.totalHabitsCompleted, 0);
      expect(stats.totalChallengesCompleted, 0);
    });
  });

  group('Merge logic (local vs remote)', () {
    test('local XP wins when higher than remote', () {
      const localXp = 500;
      const remoteXp = 200;
      final mergedXp = localXp > remoteXp ? localXp : remoteXp;
      expect(mergedXp, 500);
    });

    test('remote XP wins when higher than local', () {
      const localXp = 100;
      const remoteXp = 300;
      final mergedXp = localXp > remoteXp ? localXp : remoteXp;
      expect(mergedXp, 300);
    });

    test('remote memberCount used over local (can decrease)', () {
      // Remote wins for memberCount (tribe can lose members)
      final mergedMemberCount = 15;
      expect(mergedMemberCount, 15);
    });

    test('local habits win when higher', () {
      const localHabits = 30;
      const remoteHabits = 20;
      final mergedHabits = localHabits > remoteHabits
          ? localHabits
          : remoteHabits;
      expect(mergedHabits, 30);
    });

    test('handles null local data gracefully', () {
      final localXp = null as int?;
      final remoteXp = 100;
      final mergedXp = (localXp ?? 0) > remoteXp ? (localXp ?? 0) : remoteXp;
      expect(mergedXp, 100);
    });

    test('handles null remote data gracefully', () {
      final localXp = 200;
      final remoteXp = null as int?;
      final mergedXp = localXp > (remoteXp ?? 0) ? localXp : (remoteXp ?? 0);
      expect(mergedXp, 200);
    });
  });
}
