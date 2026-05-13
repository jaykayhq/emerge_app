import 'package:drift/drift.dart';

class LeaderboardEntriesTable extends Table {
  TextColumn get id => text()();
  TextColumn get tribeId => text()();
  TextColumn get userId => text()();
  TextColumn get userName => text().withDefault(const Constant('Anonymous'))();
  IntColumn get xp => integer().withDefault(const Constant(0))();
  IntColumn get level => integer().withDefault(const Constant(1))();
  IntColumn get rank => integer().withDefault(const Constant(0))();
  TextColumn get archetype => text().nullable()();
  TextColumn get updatedAt => text()();
  TextColumn get syncedAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
