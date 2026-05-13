import 'package:drift/drift.dart';

class TribeStatsTable extends Table {
  TextColumn get tribeId => text()();
  TextColumn get tribeName => text().nullable()();
  TextColumn get archetypeId => text().nullable()();
  IntColumn get memberCount => integer().withDefault(const Constant(0))();
  IntColumn get totalXp => integer().withDefault(const Constant(0))();
  IntColumn get totalHabitsCompleted => integer().withDefault(const Constant(0))();
  IntColumn get totalChallengesCompleted => integer().withDefault(const Constant(0))();
  IntColumn get userContributionXp => integer().withDefault(const Constant(0))();
  IntColumn get userHabitsCompleted => integer().withDefault(const Constant(0))();
  IntColumn get userChallengesCompleted => integer().withDefault(const Constant(0))();
  TextColumn get updatedAt => text()();
  TextColumn get syncedAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {tribeId};
}
