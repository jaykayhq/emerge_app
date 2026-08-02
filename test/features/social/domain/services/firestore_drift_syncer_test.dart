import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:drift/native.dart';
import 'package:emerge_app/core/drift/app_database.dart';
import 'package:emerge_app/features/social/domain/services/firestore_drift_syncer.dart';

void main() {
  late AppDatabase db;
  late FakeFirebaseFirestore firestore;
  late FirestoreDriftSyncer syncer;

  setUp(() async {
    db = AppDatabase.withExecutor(NativeDatabase.memory());
    firestore = FakeFirebaseFirestore();
    syncer = FirestoreDriftSyncer(
      firestore: firestore,
      leaderboardDao: db.leaderboardEntriesDao,
      tribeStatsDao: db.tribeStatsDao,
    );
  });

  tearDown(() async {
    syncer.stop();
    await db.close();
  });

  test('tribe stats upserted from Firestore document', () async {
    await firestore.collection('tribes').doc('t1').set({
      'totalXp': 1000,
      'memberCount': 5,
      'totalHabitsCompleted': 200,
    });

    syncer.start('t1');
    await Future.delayed(const Duration(milliseconds: 100));

    final stats = await db.tribeStatsDao.getStats('t1');
    expect(stats, isNotNull);
    expect(stats!.totalXp, 1000);
    expect(stats.memberCount, 5);
  });

  test('start() pulls leaderboard rows by clubId, not tribeId', () async {
    await firestore.collection('club_leaderboards').add({
      'userId': 'u1',
      'userName': 'User1',
      'clubId': 'tribeA',
      'xp': 500,
      'level': 5,
      'rank': 1,
    });

    syncer.start('tribeA');
    await pumpEventQueue();

    final rows = await db.leaderboardEntriesDao.getForTribe('tribeA');
    expect(rows, isNotEmpty);
    expect(rows.first.tribeId, 'tribeA');
  });

  test('leaderboard entry upserted from Firestore', () async {
    await firestore.collection('club_leaderboards').add({
      'clubId': 't1',
      'userId': 'u1',
      'userName': 'User1',
      'xp': 500,
      'level': 5,
      'rank': 1,
    });

    syncer.start('t1');
    await Future.delayed(const Duration(milliseconds: 100));

    final entries = await db.leaderboardEntriesDao.watchLeaderboard('t1').first;
    expect(entries, isNotEmpty);
  });

  test('multiple tribe docs update independently', () async {
    await firestore.collection('tribes').doc('t1').set({
      'totalXp': 1000,
      'memberCount': 5,
    });
    await firestore.collection('tribes').doc('t2').set({
      'totalXp': 2000,
      'memberCount': 10,
    });

    syncer.start('t1');
    await Future.delayed(const Duration(milliseconds: 100));

    final statsT1 = await db.tribeStatsDao.getStats('t1');
    final statsT2 = await db.tribeStatsDao.getStats('t2');
    expect(statsT1, isNotNull);
    expect(statsT1!.totalXp, 1000);
    // t2 should NOT be synced since we started with tribeId 't1'
    expect(statsT2?.totalXp, isNot(2000));
  });
}
