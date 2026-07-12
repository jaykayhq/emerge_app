import 'package:drift/native.dart';
import 'package:emerge_app/core/drift/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('habit_reflections table exists after schemaVersion=8 migration', () async {
    final db = AppDatabase.withExecutor(NativeDatabase.memory());
    final row = await db.customSelect(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='habit_reflections'",
    ).getSingleOrNull();
    expect(row, isNotNull,
        reason: 'habit_reflections table should exist after migration to v8');
    await db.close();
  });
}
