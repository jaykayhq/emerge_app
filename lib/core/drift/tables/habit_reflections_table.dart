import 'package:drift/drift.dart';

/// Drift table for per-habit reflections.
///
/// Stores the user's mood (1-5) and optional 1-line note for a specific
/// habit on a given local date. One row per (userId, habitId, localDate) —
/// upserted via the DAO.
class HabitReflectionsTable extends Table {
  /// Unique row id.
  TextColumn get id => text()();

  /// Owner user id.
  TextColumn get userId => text()();

  /// Owning habit id.
  TextColumn get habitId => text()();

  /// Local date (year/month/day only, time stripped at write time).
  DateTimeColumn get localDate => dateTime()();

  /// Mood as integer 1..5. See [Mood.fromInt] for mapping.
  IntColumn get mood => integer()();

  /// Optional 1-line note (max 140 chars at the call site, not enforced here).
  TextColumn get note => text().withDefault(const Constant(''))();

  /// Row creation timestamp.
  DateTimeColumn get createdAt => dateTime()();

  /// Last update timestamp.
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String? get tableName => 'habit_reflections';
}
