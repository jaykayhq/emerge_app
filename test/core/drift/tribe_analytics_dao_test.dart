// test/core/drift/tribe_analytics_dao_test.dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/core/drift/app_database.dart';
import 'package:emerge_app/core/drift/daos/tribe_analytics_dao.dart';

void main() {
  late AppDatabase db;
  late TribeAnalyticsDao dao;

  setUp(() {
    db = AppDatabase.withExecutor(NativeDatabase.memory());
    dao = db.tribeAnalyticsDao;
  });

  tearDown(() => db.close());

  test('upsert + get latest snapshot', () async {
    await dao.upsertSnapshot(
      userId: 'u1',
      tribeId: 't1',
      date: '2026-08-18',
      memberCount: 10,
      totalXp: 5000,
      totalHabitsCompleted: 120,
      totalChallengesCompleted: 4,
      activeMembers: 6,
      newMembersThisWeek: 2,
    );
    final latest = await dao.getLatest(userId: 'u1', tribeId: 't1');
    expect(latest, isNotNull);
    expect(latest!.memberCount, 10);
    expect(latest.totalXp, 5000);
  });

  test('getLatest returns null when no rows', () async {
    expect(await dao.getLatest(userId: 'u1', tribeId: 'missing'), isNull);
  });

  test('isolates data between users on a shared device', () async {
    await dao.upsertSnapshot(
      userId: 'u1',
      tribeId: 't1',
      date: '2026-08-18',
      memberCount: 10,
      totalXp: 5000,
      totalHabitsCompleted: 120,
      totalChallengesCompleted: 4,
      activeMembers: 6,
      newMembersThisWeek: 2,
    );
    await dao.upsertSnapshot(
      userId: 'u2',
      tribeId: 't1',
      date: '2026-08-18',
      memberCount: 99,
      totalXp: 999,
      totalHabitsCompleted: 999,
      totalChallengesCompleted: 9,
      activeMembers: 1,
      newMembersThisWeek: 0,
    );

    final u1 = await dao.getLatest(userId: 'u1', tribeId: 't1');
    final u2 = await dao.getLatest(userId: 'u2', tribeId: 't1');
    expect(u1!.memberCount, 10);
    expect(u2!.memberCount, 99);
  });
}