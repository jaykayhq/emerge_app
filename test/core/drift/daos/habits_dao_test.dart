// HabitsDao round-trip coverage — specifically the imageUrl (emoji) column
// that the habit cards render. Regression: the emoji was saved to the entity
// but never persisted, so cards fell back to the bolt icon after reload.
import 'package:drift/native.dart';
import 'package:emerge_app/core/drift/app_database.dart';
import 'package:emerge_app/core/drift/daos/habits_dao.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late HabitsDao dao;

  setUp(() {
    db = AppDatabase.withExecutor(NativeDatabase.memory());
    dao = HabitsDao(db);
  });

  tearDown(() => db.close());

  test('insertFromData persists the imageUrl emoji and reads it back',
      () async {
    await dao.insertFromData(
      id: 'h1',
      userId: 'user1',
      title: 'Morning run',
      attribute: 'vitality',
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
      imageUrl: '🔥',
    );

    final row = await dao.getHabit('h1');
    expect(row, isNotNull);
    expect(row!.imageUrl, '🔥');
  });

  test('upsert with null imageUrl leaves the emoji intact (partial update)',
      () async {
    await dao.insertFromData(
      id: 'h2',
      userId: 'user1',
      title: 'Read',
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
      imageUrl: '📚',
    );

    // insertOnConflictUpdate with imageUrl omitted would blank the column,
    // so the DAO must keep the value; simulate a streak-only update path.
    await dao.updateStreak('h2', 1, 1, DateTime.now().toIso8601String());

    final row = await dao.getHabit('h2');
    expect(row!.imageUrl, '📚');
  });
}
