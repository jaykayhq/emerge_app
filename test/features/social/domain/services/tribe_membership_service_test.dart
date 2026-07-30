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

  test('joinTribe enqueues Firestore sync operations', () async {
    await service.joinTribe(
      userId: 'user1',
      tribeId: 'morning_warriors',
      type: 'archetype',
    );
    final queue = await db.mutationQueueDao.getAllPending();
    // 2 sync ops (user membership + contributor); tribe doc uses direct transaction
    expect(queue.length, greaterThanOrEqualTo(2));
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
