import 'package:drift/drift.dart';

class ChallengeProgressTable extends Table {
  TextColumn get challengeId => text()();
  TextColumn get userId => text()();
  TextColumn get title => text().nullable()();
  TextColumn get attribute => text().nullable()();
  IntColumn get currentDay => integer().withDefault(const Constant(0))();
  IntColumn get totalDays => integer().withDefault(const Constant(1))();
  TextColumn get status => text().withDefault(const Constant('active'))();
  IntColumn get xpReward => integer().withDefault(const Constant(0))();
  TextColumn get joinedAt => text().nullable()();
  TextColumn get updatedAt => text()();
  TextColumn get syncedAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {challengeId};
}
