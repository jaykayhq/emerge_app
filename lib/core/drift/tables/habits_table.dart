import 'package:drift/drift.dart';

class HabitsTable extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get title => text()();
  TextColumn get cue => text().nullable()();
  TextColumn get routine => text().nullable()();
  TextColumn get reward => text().nullable()();
  TextColumn get frequency => text().withDefault(const Constant('daily'))();
  TextColumn get difficulty => text().withDefault(const Constant('medium'))();
  TextColumn get attribute => text().nullable()();
  IntColumn get currentStreak => integer().withDefault(const Constant(0))();
  IntColumn get longestStreak => integer().withDefault(const Constant(0))();
  IntColumn get momentumScore => integer().withDefault(const Constant(0))();
  IntColumn get consecutiveMisses => integer().withDefault(const Constant(0))();
  TextColumn get lastCompletedDate => text().nullable()();
  IntColumn get isArchived => integer().withDefault(const Constant(0))();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  TextColumn get syncedAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
