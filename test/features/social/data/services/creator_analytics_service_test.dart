// test/features/social/data/services/creator_analytics_service_test.dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/social/data/services/creator_analytics_service.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late CreatorAnalyticsService service;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    service = CreatorAnalyticsService(firestore: firestore);
  });

  Future<void> seedTribe() async {
    await firestore.collection('tribes').doc('t1').set({
      'name': 'The Forge',
      'memberCount': 3,
      'createdBy': 'creator1',
      'type': 'creator',
    });
    final contributors = firestore
        .collection('tribes')
        .doc('t1')
        .collection('contributors');
    await contributors.doc('u1').set({
      'userName': 'Ada',
      'totalXpContributed': 3000,
      'totalHabitsCompleted': 40,
      'totalChallengesCompleted': 2,
      'joinedAt': DateTime.now()
          .subtract(const Duration(days: 30))
          .toIso8601String(),
      'lastActivity': DateTime.now().toIso8601String(),
    });
    await contributors.doc('u2').set({
      'userName': 'Bob',
      'totalXpContributed': 2000,
      'totalHabitsCompleted': 20,
      'totalChallengesCompleted': 1,
      'joinedAt': DateTime.now()
          .subtract(const Duration(days: 2))
          .toIso8601String(),
      'lastActivity': DateTime.now().toIso8601String(),
    });
    await contributors.doc('u3').set({
      'userName': 'Cara',
      'totalXpContributed': 0,
      'totalHabitsCompleted': 0,
      'totalChallengesCompleted': 0,
      'joinedAt': DateTime.now()
          .subtract(const Duration(days: 60))
          .toIso8601String(),
      'lastActivity': DateTime.now()
          .subtract(const Duration(days: 30))
          .toIso8601String(),
    });
  }

  test('aggregates KPIs, member growth, active members, top members', () async {
    await seedTribe();
    await firestore.collection('blueprints').doc('b1').set({
      'creatorUserId': 'creator1',
      'title': 'Morning Stack',
      'adoptionCount': 7,
      'habits': [
        {'title': 'Read'},
        {'title': 'Run'},
      ],
    });
    await firestore.collection('challenges').doc('c1').set({
      'createdBy': 'creator1',
      'title': '30 Days of Reading',
      'participants': 5,
      'status': 'active',
      'xpReward': 100,
    });

    final result = await service.getCreatorAnalytics(
      uid: 'creator1',
      tribeId: 't1',
    );

    expect(result.isRight(), isTrue);
    final analytics = result.getRight().toNullable()!;
    expect(analytics.tribeName, 'The Forge');
    expect(analytics.memberCount, 3);
    expect(analytics.totalXp, 5000);
    expect(analytics.totalHabitsCompleted, 60);
    expect(analytics.totalChallengesCompleted, 3);
    expect(analytics.newMembersThisWeek, 1); // u2 joined 2 days ago
    expect(analytics.activeMembers, 2); // u1, u2 active in last 7d
    expect(analytics.activeRate, closeTo(0.67, 0.01));
    expect(analytics.topMembers.length, 2); // u3 has 0 xp, excluded
    expect(analytics.topMembers.first.name, 'Ada');
    expect(analytics.blueprintStats.single.adoptionCount, 7);
    expect(analytics.challengeStats.single.participants, 5);
  });

  test('returns zeros for an empty tribe', () async {
    await firestore.collection('tribes').doc('t1').set({
      'name': 'Empty',
      'memberCount': 0,
      'createdBy': 'creator1',
      'type': 'creator',
    });
    final result = await service.getCreatorAnalytics(
      uid: 'creator1',
      tribeId: 't1',
    );
    expect(result.isRight(), isTrue);
    final analytics = result.getRight().toNullable()!;
    expect(analytics.memberCount, 0);
    expect(analytics.topMembers, isEmpty);
    expect(analytics.blueprintStats, isEmpty);
  });

  test('returns Left on invalid input', () async {
    final result = await service.getCreatorAnalytics(
      uid: 'creator1',
      tribeId: '',
    );
    expect(result.isLeft(), isTrue);
  });
}
