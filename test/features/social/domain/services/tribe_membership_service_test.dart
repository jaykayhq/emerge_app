import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:emerge_app/core/drift/app_database.dart';
import 'package:emerge_app/core/sync/sync_engine.dart';
import 'package:emerge_app/features/social/domain/services/tribe_membership_service.dart';
import 'package:emerge_app/features/social/data/repositories/tribe_repository.dart';
import 'package:emerge_app/core/drift_repositories/drift_tribe_repository.dart';

void main() {
  late AppDatabase db;
  late FakeFirebaseFirestore firestore;
  late EnhancedSyncEngine syncEngine;
  late TribeRepository repository;
  late TribeMembershipService service;

  setUp(() async {
    db = AppDatabase.withExecutor(NativeDatabase.memory());
    firestore = FakeFirebaseFirestore();
    syncEngine = EnhancedSyncEngine(db.mutationQueueDao, firestore);
    repository = DriftTribeRepository(db, syncEngine, firestore);
    service = TribeMembershipService(
      repository,
      db.tribeMembershipDao,
      db.tribeStatsDao,
      syncEngine,
      firestore,
    );

    // Seed tribe document so transactions can read it
    await firestore.collection('tribes').doc('morning_warriors').set({
      'memberCount': 0,
      'members': <String>[],
    });
  });

  tearDown(() => db.close());

  test('joinTribe writes Drift membership + enqueues sync', () async {
    await service.joinTribe(
      userId: 'user1',
      tribeId: 'morning_warriors',
      type: 'archetype',
    );
    final membership = await db.tribeMembershipDao
        .watchActiveMembership('user1')
        .first;
    expect(membership, isNotNull);
    expect(membership!.tribeId, 'morning_warriors');
    expect(membership.isActive, true);
  });

  test(
    'joinTribe rejects when a Firestore membership doc already exists',
    () async {
      await firestore
          .collection('users')
          .doc('user1')
          .collection('tribes')
          .doc('morning_warriors')
          .set({'tribeId': 'morning_warriors', 'joinedAt': Timestamp.now()});

      final result = await service.joinTribe(
        userId: 'user1',
        tribeId: 'morning_warriors',
        type: 'archetype',
      );

      expect(result.isLeft(), true);
      final tribe = await firestore
          .collection('tribes')
          .doc('morning_warriors')
          .get();
      expect((tribe.data()?['memberCount'] as int?) ?? 0, 0); // no +1
    },
  );

  test('joinTribe preserves existing contributor totals on rejoin', () async {
    await firestore.collection('tribes').doc('morning_warriors').set({
      'memberCount': 0,
      'members': <String>[],
    });
    await firestore
        .collection('tribes')
        .doc('morning_warriors')
        .collection('contributors')
        .doc('user1')
        .set({
          'userId': 'user1',
          'totalXpContributed': 250,
          'contributionCount': 3,
        });

    await service.joinTribe(
      userId: 'user1',
      tribeId: 'morning_warriors',
      type: 'archetype',
    );

    final contributor = await firestore
        .collection('tribes')
        .doc('morning_warriors')
        .collection('contributors')
        .doc('user1')
        .get();
    expect(
      (contributor.data()?['totalXpContributed'] as int?) ?? 0,
      250,
    ); // NOT reset to 0
  });

  test('joinTribe creates a zeroed contributor doc for a first join', () async {
    await service.joinTribe(
      userId: 'user1',
      tribeId: 'morning_warriors',
      type: 'archetype',
    );
    final contributor = await firestore
        .collection('tribes')
        .doc('morning_warriors')
        .collection('contributors')
        .doc('user1')
        .get();
    expect((contributor.data()?['totalXpContributed'] as int?) ?? 0, 0);
  });

  test(
    'joinTribe writes membership atomically; tribe doc is server-owned',
    () async {
      await db.tribeStatsDao.upsertStats(
        TribeStatsTableCompanion(
          tribeId: const Value('morning_warriors'),
          tribeName: const Value('Morning Warriors'),
          archetypeId: const Value('athlete'),
          memberCount: const Value(0),
          totalXp: const Value(0),
          totalHabitsCompleted: const Value(0),
          totalChallengesCompleted: const Value(0),
          userContributionXp: const Value(0),
          userHabitsCompleted: const Value(0),
          userChallengesCompleted: const Value(0),
          updatedAt: Value(DateTime.now().toIso8601String()),
        ),
      );
      await service.joinTribe(
        userId: 'user1',
        tribeId: 'morning_warriors',
        type: 'archetype',
      );
      // The membership + contributor docs are client-written...
      final membership = await firestore
          .collection('users')
          .doc('user1')
          .collection('tribes')
          .doc('morning_warriors')
          .get();
      expect(membership.exists, true);
      final contributor = await firestore
          .collection('tribes')
          .doc('morning_warriors')
          .collection('contributors')
          .doc('user1')
          .get();
      expect(contributor.exists, true);
      // ...but the tribe doc memberCount/members are owned by the server
      // trigger. The client must NOT write them (rules deny it and dead-letter
      // the mutation).
      final tribe = await firestore
          .collection('tribes')
          .doc('morning_warriors')
          .get();
      expect(tribe.data()?['memberCount'], 0);
      expect(tribe.data()?['members'], <String>[]);
      // Local Drift cache reflects the join immediately.
      final stats = await db.tribeStatsDao.getStats('morning_warriors');
      expect(stats, isNotNull);
      expect(stats!.memberCount, 1);
    },
  );

  test('leaveTribe deactivates membership', () async {
    await service.joinTribe(
      userId: 'user1',
      tribeId: 'morning_warriors',
      type: 'archetype',
    );
    await service.leaveTribe('user1');
    final membership = await db.tribeMembershipDao
        .watchActiveMembership('user1')
        .first;
    expect(membership, isNull);
  });
}
