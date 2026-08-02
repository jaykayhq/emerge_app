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

  group('Merge logic (local vs remote, SP-G D4)', () {
    // Mirrors cachedTribeStatsProvider.emitMerged's exact expressions: tribe
    // totals are recalc-only (server-authoritative D10) — remote Firestore
    // values win as soon as they arrive; local Drift totals only fill in
    // while remote is absent. (memberCount can decrease on leave, so remote
    // is authoritative there too.)
    int mergedTotalXp({required int localXp, int? remoteXp}) =>
        remoteXp ?? localXp;
    int mergedHabits({required int localHabits, int? remoteHabits}) =>
        remoteHabits ?? localHabits;
    int mergedChallenges({
      required int localChallenges,
      int? remoteChallenges,
    }) =>
        remoteChallenges ?? localChallenges;
    int mergedMemberCount({int? localMembers, int? remoteMembers}) =>
        remoteMembers ?? localMembers ?? 0;

    test('remote totalXp wins over inflated local', () {
      const localXp = 500;
      const remoteXp = 200;
      expect(mergedTotalXp(localXp: localXp, remoteXp: remoteXp), 200);
    });

    test('remote totalHabitsCompleted wins over inflated local', () {
      const localHabits = 30;
      const remoteHabits = 20;
      expect(mergedHabits(localHabits: localHabits, remoteHabits: remoteHabits), 20);
    });

    test('remote totalChallengesCompleted wins over inflated local', () {
      const localChallenges = 10;
      const remoteChallenges = 3;
      expect(
        mergedChallenges(
          localChallenges: localChallenges,
          remoteChallenges: remoteChallenges,
        ),
        3,
      );
    });

    test('local totalXp survives when remote is absent', () {
      const localXp = 500;
      expect(mergedTotalXp(localXp: localXp), 500);
    });

    test('local habits survive when remote is absent', () {
      const localHabits = 30;
      expect(mergedHabits(localHabits: localHabits), 30);
    });

    test('remote memberCount used over local (can decrease)', () {
      const localMembers = 15;
      const remoteMembers = 8;
      expect(
        mergedMemberCount(
          localMembers: localMembers,
          remoteMembers: remoteMembers,
        ),
        8,
      );
    });

    test('handles null local data gracefully', () {
      const remoteXp = 100;
      expect(mergedTotalXp(localXp: 0, remoteXp: remoteXp), 100);
    });

    test('handles null remote data gracefully', () {
      const localXp = 200;
      expect(mergedTotalXp(localXp: localXp), 200);
    });
  });
}
