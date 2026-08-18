import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:emerge_app/core/drift/app_database.dart';
import 'package:emerge_app/core/drift/daos/tribe_activity_dao.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late TribeActivityDao dao;

  setUp(() async {
    db = AppDatabase.withExecutor(NativeDatabase.memory());
    dao = TribeActivityDao(db);
  });

  tearDown(() => db.close());

  Future<void> insertRow({
    required String id,
    required String userId,
    required String type,
    required String timestamp,
  }) {
    return dao.insertActivity(
      TribeActivityTableCompanion(
        id: Value(id),
        userId: Value(userId),
        userName: const Value('Someone'),
        tribeId: Value(null),
        type: Value(type),
        description: const Value(''),
        value: const Value(0),
        timestamp: Value(timestamp),
      ),
    );
  }

  Future<List<TribeActivityTableData>> allRows() =>
      db.select(db.tribeActivityTable).get();

  group('deleteActivity', () {
    test('scopes the delete to the owning userId (shared-device isolation)',
        () async {
      await insertRow(
        id: 'u1_h1_100',
        userId: 'u1',
        type: 'habit_complete',
        timestamp: '2024-03-09T12:00:01.000Z',
      );

      // A caller scoping to a different user must NOT delete the row.
      await dao.deleteActivity('u1_h1_100', 'u2');
      expect((await allRows()).single.id, 'u1_h1_100');

      // The owning user's scope still deletes it.
      await dao.deleteActivity('u1_h1_100', 'u1');
      expect(await allRows(), isEmpty);
    });
  });

  group('getLatestHabitCompletion', () {
    test('matches the exact userId_habitId prefix (LIKE wildcards escaped)',
        () async {
      // A differently-shaped habit id ('h1x') shares the same prefix
      // separators as 'h1' — without escaping, the `_` wildcards in the old
      // pattern let the lookup for 'h1' resolve to the 'h1x' row.
      await insertRow(
        id: 'u1_h1x_300',
        userId: 'u1',
        type: 'habit_complete',
        timestamp: '2024-03-09T12:00:03.000Z',
      );
      await insertRow(
        id: 'u1_h1_200',
        userId: 'u1',
        type: 'habit_complete',
        timestamp: '2024-03-09T12:00:02.000Z',
      );

      final forH1 = await dao.getLatestHabitCompletion('u1', 'h1');
      expect(forH1?.id, 'u1_h1_200');

      final forH1x = await dao.getLatestHabitCompletion('u1', 'h1x');
      expect(forH1x?.id, 'u1_h1x_300');
    });

    test('is scoped to the given userId', () async {
      await insertRow(
        id: 'u2_h1_400',
        userId: 'u2',
        type: 'habit_complete',
        timestamp: '2024-03-09T12:00:04.000Z',
      );
      await insertRow(
        id: 'u1_h1_100',
        userId: 'u1',
        type: 'habit_complete',
        timestamp: '2024-03-09T12:00:01.000Z',
      );

      final row = await dao.getLatestHabitCompletion('u1', 'h1');
      expect(row?.id, 'u1_h1_100');
    });

    test('returns null when the user has no matching habit_complete row',
        () async {
      await insertRow(
        id: 'u1_other_100',
        userId: 'u1',
        type: 'level_up',
        timestamp: '2024-03-09T12:00:01.000Z',
      );

      expect(await dao.getLatestHabitCompletion('u1', 'h1'), isNull);
    });
  });
}