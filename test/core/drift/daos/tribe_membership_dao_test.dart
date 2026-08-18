import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:emerge_app/core/drift/app_database.dart';
import 'package:emerge_app/core/drift/daos/tribe_membership_dao.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late TribeMembershipDao dao;

  setUp(() async {
    db = AppDatabase.withExecutor(NativeDatabase.memory());
    dao = TribeMembershipDao(db);
    await dao.upsertMembership(
      UserTribeTableCompanion(
        userId: const Value('user1'),
        tribeId: const Value('morning_warriors'),
        membershipType: const Value('archetype'),
        joinedAt: Value(DateTime.now().toIso8601String()),
        isActive: const Value(true),
      ),
    );
  });

  tearDown(() => db.close());

  test('watchActiveMembership returns active tribe', () async {
    final membership = await dao.watchActiveMembership('user1').first;
    expect(membership, isNotNull);
    expect(membership!.tribeId, 'morning_warriors');
    expect(membership.isActive, true);
  });

  test('deactivateAll sets all to inactive', () async {
    await dao.deactivateAll('user1');
    final membership = await dao.watchActiveMembership('user1').first;
    expect(membership, isNull);
  });

  test('upsertMembership updates existing row', () async {
    await dao.upsertMembership(
      UserTribeTableCompanion(
        userId: const Value('user1'),
        tribeId: const Value('morning_warriors'),
        membershipType: const Value('creator'),
        joinedAt: Value(DateTime.now().toIso8601String()),
        isActive: const Value(true),
      ),
    );
    final membership = await dao.watchActiveMembership('user1').first;
    expect(membership!.membershipType, 'creator');
  });

  test('removeMembership deletes the row', () async {
    await dao.removeMembership('user1', 'morning_warriors');
    final membership = await dao.watchActiveMembership('user1').first;
    expect(membership, isNull);
  });
}
