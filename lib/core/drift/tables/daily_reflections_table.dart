import 'package:drift/drift.dart';

/// Drift table for daily user reflections.
///
/// Stores the user's mood (1-5) and optional 1-line note for a given local date.
/// One row per (userId, localDate) — upserted via the DAO.
class DailyReflectionsTable extends Table {
  /// Unique row id.
  TextColumn get id => text()();

  /// Owner user id.
  TextColumn get userId => text()();

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
  String? get tableName => 'daily_reflections';
}
