import 'package:drift/native.dart';
import 'package:emerge_app/core/drift/app_database.dart';
import 'package:emerge_app/features/reflections/domain/entities/mood.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.withExecutor(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('HabitReflectionsDao.getByDate', () {
    test('returns null when no row exists', () async {
      final row = await db.habitReflectionsDao.getByDate(
        'u1',
        'h1',
        DateTime(2026, 7, 10),
      );
      expect(row, isNull);
    });

    test('ignores time component of localDate', () async {
      await db.habitReflectionsDao.upsert(
        userId: 'u1',
        habitId: 'h1',
        localDate: DateTime(2026, 7, 10, 9, 30),
        mood: Mood.good,
        note: 'felt strong',
      );
      final row = await db.habitReflectionsDao.getByDate(
        'u1',
        'h1',
        DateTime(2026, 7, 10, 23, 59),
      );
      expect(row, isNotNull);
      expect(row!.note, 'felt strong');
    });
  });

  group('HabitReflectionsDao.upsert', () {
    test('inserts new row', () async {
      await db.habitReflectionsDao.upsert(
        userId: 'u1',
        habitId: 'h1',
        localDate: DateTime(2026, 7, 10),
        mood: Mood.ok,
        note: 'first',
      );
      final row = await db.habitReflectionsDao.getByDate(
        'u1',
        'h1',
        DateTime(2026, 7, 10),
      );
      expect(row, isNotNull);
      expect(row!.mood, Mood.ok.value);
      expect(row.note, 'first');
    });

    test('updates existing row on same (userId, habitId, day)', () async {
      await db.habitReflectionsDao.upsert(
        userId: 'u1',
        habitId: 'h1',
        localDate: DateTime(2026, 7, 10),
        mood: Mood.ok,
        note: 'first',
      );
      await db.habitReflectionsDao.upsert(
        userId: 'u1',
        habitId: 'h1',
        localDate: DateTime(2026, 7, 10),
        mood: Mood.great,
        note: 'second',
      );
      final rows = await db.select(db.habitReflectionsTable).get();
      expect(rows, hasLength(1));
      expect(rows.first.note, 'second');
      expect(rows.first.mood, Mood.great.value);
    });

    test('keeps separate rows per habitId on same day', () async {
      await db.habitReflectionsDao.upsert(
        userId: 'u1',
        habitId: 'h1',
        localDate: DateTime(2026, 7, 10),
        mood: Mood.ok,
        note: 'h1 note',
      );
      await db.habitReflectionsDao.upsert(
        userId: 'u1',
        habitId: 'h2',
        localDate: DateTime(2026, 7, 10),
        mood: Mood.good,
        note: 'h2 note',
      );
      final rows = await db.select(db.habitReflectionsTable).get();
      expect(rows, hasLength(2));
    });
  });

  group('HabitReflectionsDao.watchForHabit', () {
    test('emits on insert', () async {
      final stream = db.habitReflectionsDao.watchForHabit(
        'u1',
        'h1',
        DateTime(2026, 7, 1),
        DateTime(2026, 7, 31),
      );
      final emitted = <int>[];
      final sub = stream.listen((rows) => emitted.add(rows.length));
      await Future<void>.delayed(Duration.zero);
      await db.habitReflectionsDao.upsert(
        userId: 'u1',
        habitId: 'h1',
        localDate: DateTime(2026, 7, 10),
        mood: Mood.ok,
        note: '',
      );
      await Future<void>.delayed(Duration(milliseconds: 50));
      expect(emitted.last, 1);
      await sub.cancel();
    });
  });
}
