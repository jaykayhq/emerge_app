import 'package:drift/drift.dart';

class HabitCompletionsTable extends Table {
  TextColumn get id => text()();
  TextColumn get habitId => text()();
  TextColumn get userId => text()();
  TextColumn get completedAt => text()();
  IntColumn get xpGained => integer().withDefault(const Constant(0))();
  TextColumn get attribute => text().nullable()();
  IntColumn get momentumAtCompletion => integer().nullable()();
  IntColumn get streakDay => integer().withDefault(const Constant(0))();
  IntColumn get wasRecovery => integer().withDefault(const Constant(0))();
  TextColumn get syncedAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
