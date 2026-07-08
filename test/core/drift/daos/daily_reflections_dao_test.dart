import 'package:drift/native.dart';
import 'package:emerge_app/core/drift/app_database.dart';
import 'package:emerge_app/core/drift/daos/daily_reflections_dao.dart';
import 'package:emerge_app/features/reflections/domain/entities/mood.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late DailyReflectionsDao dao;

  setUp(() {
    db = AppDatabase.withExecutor(NativeDatabase.memory());
    dao = db.dailyReflectionsDao;
  });
  tearDown(() => db.close());

  test('upsert inserts a new row when none exists', () async {
    await dao.upsert(
      userId: 'u1',
      localDate: DateTime(2026, 7, 5),
      mood: Mood.good,
      note: 'felt strong',
    );
    final row = await dao.getByDate('u1', DateTime(2026, 7, 5));
    expect(row, isNotNull);
    expect(row!.mood, Mood.good.value);
    expect(row.note, 'felt strong');
  });

  test('upsert overwrites existing row for the same user + date', () async {
    await dao.upsert(userId: 'u1', localDate: DateTime(2026, 7, 5), mood: Mood.ok, note: 'a');
    await dao.upsert(userId: 'u1', localDate: DateTime(2026, 7, 5), mood: Mood.great, note: 'b');
    final row = await dao.getByDate('u1', DateTime(2026, 7, 5));
    expect(row, isNotNull);
    expect(row!.mood, Mood.great.value);
    expect(row.note, 'b');
  });

  test('getByDate normalises to day-only', () async {
    await dao.upsert(
      userId: 'u1',
      localDate: DateTime(2026, 7, 5, 14, 30),
      mood: Mood.meh,
      note: 'meh day',
    );
    final row = await dao.getByDate('u1', DateTime(2026, 7, 5, 9, 0));
    expect(row, isNotNull);
    expect(row!.note, 'meh day');
  });

  test('getByDate returns null when no row exists', () async {
    final row = await dao.getByDate('u-missing', DateTime(2026, 7, 5));
    expect(row, isNull);
  });
}
