import 'package:drift/native.dart';
import 'package:emerge_app/core/drift/database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  setUp(() async {
    db = AppDatabase.withExecutor(NativeDatabase.memory());
    await db.habitsDao.insertFromData(
      id: 'h1',
      userId: 'u1',
      title: 'Read',
      cue: 'after coffee',
      frequency: 'daily',
      difficulty: 'hard',
      currentStreak: 7,
      longestStreak: 12,
      createdAt: DateTime(2026, 1, 1).toIso8601String(),
      updatedAt: DateTime(2026, 1, 1).toIso8601String(),
    );
    await db.habitCompletionsDao.insertFromData(
      id: 'c1',
      habitId: 'h1',
      userId: 'u1',
      completedAt: DateTime(2026, 2, 1).toIso8601String(),
    );
  });
  tearDown(() => db.close());

  test('archiveHabit only flips isArchived, preserves other fields', () async {
    await db.habitsDao.archiveHabit('h1');
    final row = await db.habitsDao.getHabit('h1');
    expect(row!.isArchived, 1);
    expect(row.cue, 'after coffee'); // NOT overwritten to ''
    expect(row.currentStreak, 7); // NOT reset to 0
    expect(row.frequency, 'daily');
  });

  test('deleteByHabitId cascades local completions', () async {
    final deleted = await db.habitCompletionsDao.deleteByHabitId('h1');
    expect(deleted, 1);
    final remaining = await db.habitCompletionsDao.getBetweenDates(
      'u1',
      DateTime(2020).toIso8601String(),
      DateTime(2030).toIso8601String(),
    );
    expect(remaining.length, 0);
  });
}
