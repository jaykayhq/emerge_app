import 'package:drift/drift.dart';

import 'package:emerge_app/core/drift/app_database.dart';
import 'package:emerge_app/core/drift/tables/habit_reflections_table.dart';
import 'package:emerge_app/features/reflections/domain/entities/mood.dart';

part 'habit_reflections_dao.g.dart';

/// DAO for the habit_reflections table.
///
/// Stores per-habit mood (1..5) and optional 1-line note.
/// One row per (userId, habitId, localDate); upserts by key.
@DriftAccessor(tables: [HabitReflectionsTable])
class HabitReflectionsDao extends DatabaseAccessor<AppDatabase>
    with _$HabitReflectionsDaoMixin {
  HabitReflectionsDao(super.db);

  static int _idCounter = 0;

  String _newId() {
    _idCounter++;
    return 'hr_${DateTime.now().millisecondsSinceEpoch}_$_idCounter';
  }

  DateTime _dayOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  /// Returns the row for (userId, habitId, localDate), or null if none.
  /// Time component of [localDate] is ignored.
  Future<HabitReflectionsTableData?> getByDate(
    String userId,
    String habitId,
    DateTime localDate,
  ) {
    final day = _dayOnly(localDate);
    return (select(habitReflectionsTable)
          ..where(
            (t) =>
                t.userId.equals(userId) &
                t.habitId.equals(habitId) &
                t.localDate.equals(day),
          )
          ..limit(1))
        .getSingleOrNull();
  }

  /// Inserts a new row, or overwrites the existing row for
  /// (userId, habitId, localDate).
  Future<void> upsert({
    required String userId,
    required String habitId,
    required DateTime localDate,
    required Mood mood,
    required String note,
  }) async {
    final day = _dayOnly(localDate);
    final existing = await getByDate(userId, habitId, day);
    final now = DateTime.now();

    if (existing == null) {
      await into(habitReflectionsTable).insert(
        HabitReflectionsTableCompanion.insert(
          id: _newId(),
          userId: userId,
          habitId: habitId,
          localDate: day,
          mood: mood.value,
          note: Value(note),
          createdAt: now,
          updatedAt: now,
        ),
      );
    } else {
      await (update(habitReflectionsTable)
            ..where((t) => t.id.equals(existing.id)))
          .write(
        HabitReflectionsTableCompanion(
          mood: Value(mood.value),
          note: Value(note),
          updatedAt: Value(now),
        ),
      );
    }
  }

  /// Streams rows for [habitId] owned by [userId] between [fromDate] and
  /// [toDate] (inclusive, day-only).
  Stream<List<HabitReflectionsTableData>> watchForHabit(
    String userId,
    String habitId,
    DateTime fromDate,
    DateTime toDate,
  ) {
    final from = _dayOnly(fromDate);
    final to = _dayOnly(toDate);
    return (select(habitReflectionsTable)
          ..where(
            (t) =>
                t.userId.equals(userId) &
                t.habitId.equals(habitId) &
                t.localDate.isBetweenValues(from, to),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.localDate)]))
        .watch();
  }
}
