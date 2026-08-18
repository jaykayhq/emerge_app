import 'dart:io';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:emerge_app/core/drift/app_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

void main() {
  test(
    'habit_reflections table exists after schemaVersion=8 migration',
    () async {
      final db = AppDatabase.withExecutor(NativeDatabase.memory());
      final row = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type='table' AND name='habit_reflections'",
          )
          .getSingleOrNull();
      expect(
        row,
        isNotNull,
        reason: 'habit_reflections table should exist after migration to v8',
      );
      await db.close();
    },
  );

  test(
    'v15 -> v16 rebuilds tribe_analytics with the user-scoped primary key',
    () async {
      // Week boundaries decrement at the 7-day edge; drift names the table
      // `tribe_analytics_table` (class name TribeAnalyticsTable).
      const table = 'tribe_analytics_table';
      final dir = Directory.systemTemp.createTempSync('drift_v15_migration');
      addTearDown(() => dir.deleteSync(recursive: true));
      final path = '${dir.path}/app.db';

      // Build a schema-15 database by hand: the analytics table WITHOUT the
      // userId column, keyed on (tribe_id, date), plus one legacy row.
      final v15 = sqlite.sqlite3.open(path);
      v15.execute('PRAGMA user_version = 15');
      v15.execute(
        'CREATE TABLE "$table" ('
        '"tribe_id" TEXT NOT NULL, '
        '"date" TEXT NOT NULL, '
        '"member_count" INTEGER NOT NULL DEFAULT 0, '
        '"total_xp" INTEGER NOT NULL DEFAULT 0, '
        '"total_habits_completed" INTEGER NOT NULL DEFAULT 0, '
        '"total_challenges_completed" INTEGER NOT NULL DEFAULT 0, '
        '"active_members" INTEGER NOT NULL DEFAULT 0, '
        '"new_members_this_week" INTEGER NOT NULL DEFAULT 0, '
        'PRIMARY KEY ("tribe_id", "date"))',
      );
      v15.execute(
        "INSERT INTO $table (tribe_id, date) VALUES ('t1', '2026-08-18')",
      );
      v15.close();

      // Open at schemaVersion 16 and run the repository's own 15 -> 16
      // migration (production's LazyDatabase opener executes the same
      // strategy during beforeOpen; withExecutor defers it).
      final db = AppDatabase.withExecutor(NativeDatabase(File(path)));
      addTearDown(db.close);
      await db.transaction(() async {
        await db.migration.onUpgrade(Migrator(db), 15, 16);
      });

      final tableInfo = await db
          .customSelect('PRAGMA table_info($table)')
          .get();
      final columns = tableInfo.map((r) => r.data['name'] as String).toSet();
      final primaryKey = tableInfo
          .where((r) => (r.data['pk'] as int) > 0)
          .map((r) => r.data['name'] as String)
          .toList();

      expect(columns, contains('user_id'));
      expect(
        primaryKey.toSet(),
        containsAll({'user_id', 'tribe_id', 'date'}),
        reason: 'userId must join the primary key for shared-device isolation',
      );
      // The old un-owned row is dropped by the rebuild.
      final count = await db
          .customSelect('SELECT COUNT(*) AS c FROM $table')
          .getSingle()
          .then((r) => r.data['c']);
      expect(count, 0);
    },
  );
}
