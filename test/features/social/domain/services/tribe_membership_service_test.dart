import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
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
    syncEngine = EnhancedSyncEngine(
      db.mutationQueueDao,
      firestore,
    );
    repository = DriftTribeRepository(db, syncEngine, firestore);
    service = TribeMembershipService(repository, db.tribeMembershipDao, syncEngine, firestore);

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
    final membership = await db.tribeMembershipDao.watchActiveMembership('user1').first;
    expect(membership, isNotNull);
    expect(membership!.tribeId, 'morning_warriors');
    expect(membership.isActive, true);
  });

  test('joinTribe rejects when a Firestore membership doc already exists', () async {
    await firestore
        .collection('users').doc('user1').collection('tribes').doc('morning_warriors')
        .set({'tribeId': 'morning_warriors', 'joinedAt': Timestamp.now()});

    final result = await service.joinTribe(
        userId: 'user1', tribeId: 'morning_warriors', type: 'archetype');

    expect(result.isLeft(), true);
    final tribe = await firestore.collection('tribes').doc('morning_warriors').get();
    expect((tribe.data()?['memberCount'] as int?) ?? 0, 0); // no +1
  });

  test('joinTribe preserves existing contributor totals on rejoin', () async {
    await firestore.collection('tribes').doc('morning_warriors').set({
      'memberCount': 0,
      'members': <String>[],
    });
    await firestore
        .collection('tribes').doc('morning_warriors').collection('contributors')
        .doc('user1')
        .set({'userId': 'user1', 'totalXpContributed': 250, 'contributionCount': 3});

    await service.joinTribe(userId: 'user1', tribeId: 'morning_warriors', type: 'archetype');

    final contributor = await firestore
        .collection('tribes').doc('morning_warriors').collection('contributors')
        .doc('user1').get();
    expect((contributor.data()?['totalXpContributed'] as int?) ?? 0, 250); // NOT reset to 0
  });

  test('joinTribe creates a zeroed contributor doc for a first join', () async {
    await service.joinTribe(userId: 'user1', tribeId: 'morning_warriors', type: 'archetype');
    final contributor = await firestore
        .collection('tribes').doc('morning_warriors').collection('contributors')
        .doc('user1').get();
    expect((contributor.data()?['totalXpContributed'] as int?) ?? 0, 0);
  });

  test('joinTribe writes membership atomically via transaction', () async {
    await service.joinTribe(userId: 'user1', tribeId: 'morning_warriors', type: 'archetype');
    final tribe = await firestore.collection('tribes').doc('morning_warriors').get();
    expect(tribe.data()?['memberCount'], 1);
    expect(tribe.data()?['members'], <String>['user1']);
    final membership = await firestore
        .collection('users').doc('user1').collection('tribes').doc('morning_warriors').get();
    expect(membership.exists, true);
  });

  test('leaveTribe deactivates membership', () async {
    await service.joinTribe(
      userId: 'user1',
      tribeId: 'morning_warriors',
      type: 'archetype',
    );
    await service.leaveTribe('user1');
    final membership = await db.tribeMembershipDao.watchActiveMembership('user1').first;
    expect(membership, isNull);
  });
}
