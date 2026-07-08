import 'package:drift/drift.dart';

import 'package:emerge_app/core/drift/app_database.dart';
import 'package:emerge_app/core/drift/tables/daily_reflections_table.dart';
import 'package:emerge_app/features/reflections/domain/entities/mood.dart';

part 'daily_reflections_dao.g.dart';

/// DAO for the daily_reflections table.
///
/// Stores the user's daily mood (1..5) and optional 1-line note.
/// One row per (userId, localDate); upserts by date.
@DriftAccessor(tables: [DailyReflectionsTable])
class DailyReflectionsDao extends DatabaseAccessor<AppDatabase>
    with _$DailyReflectionsDaoMixin {
  DailyReflectionsDao(super.db);

  static int _idCounter = 0;

  String _newId() {
    _idCounter++;
    return 'r_${DateTime.now().millisecondsSinceEpoch}_$_idCounter';
  }

  DateTime _dayOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  /// Returns the row for (userId, localDate), or null if none.
  /// Time component of [localDate] is ignored — only the calendar day matters.
  Future<DailyReflectionsTableData?> getByDate(String userId, DateTime localDate) {
    final day = _dayOnly(localDate);
    return (select(dailyReflectionsTable)
          ..where((t) => t.userId.equals(userId) & t.localDate.equals(day))
          ..limit(1))
        .getSingleOrNull();
  }

  /// Inserts a new row, or overwrites the existing row for (userId, localDate).
  Future<void> upsert({
    required String userId,
    required DateTime localDate,
    required Mood mood,
    required String note,
  }) async {
    final day = _dayOnly(localDate);
    final existing = await getByDate(userId, day);
    final now = DateTime.now();

    if (existing == null) {
      await into(dailyReflectionsTable).insert(
        DailyReflectionsTableCompanion.insert(
          id: _newId(),
          userId: userId,
          localDate: day,
          mood: mood.value,
          note: Value(note),
          createdAt: now,
          updatedAt: now,
        ),
      );
    } else {
      await (update(dailyReflectionsTable)..where((t) => t.id.equals(existing.id)))
          .write(
        DailyReflectionsTableCompanion(
          mood: Value(mood.value),
          note: Value(note),
          updatedAt: Value(now),
        ),
      );
    }
  }
}
