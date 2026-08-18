// test/features/social/domain/models/creator_analytics_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/social/domain/models/creator_analytics.dart';

void main() {
  group('TribeAnalyticsSnapshot', () {
    test('toMap/fromMap round-trips', () {
      final snap = TribeAnalyticsSnapshot(
        tribeId: 't1',
        date: '2026-08-18',
        memberCount: 10,
        totalXp: 5000,
        totalHabitsCompleted: 120,
        totalChallengesCompleted: 4,
        activeMembers: 6,
        newMembersThisWeek: 2,
      );
      final restored = TribeAnalyticsSnapshot.fromMap(snap.toMap());
      expect(restored, snap);
    });
  });

  group('CreatorAnalytics', () {
    test('defaults to zeros when constructed empty', () {
      const analytics = CreatorAnalytics(tribeId: 't1', tribeName: 'Tribe');
      expect(analytics.memberCount, 0);
      expect(analytics.blueprintStats, isEmpty);
      expect(analytics.topMembers, isEmpty);
      expect(analytics.challengeStats, isEmpty);
      expect(analytics.trends, isEmpty);
    });
  });
}
