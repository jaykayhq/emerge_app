import 'package:drift/drift.dart';

class TribeActivityTable extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get userName => text().withDefault(const Constant('Someone'))();
  TextColumn get tribeId => text().nullable()();
  TextColumn get type => text()(); // habit_complete, level_up, etc.
  TextColumn get description => text()();
  IntColumn get value =>
      integer().withDefault(const Constant(0))(); // e.g., XP earned
  TextColumn get timestamp => text()();
  TextColumn get syncedAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
