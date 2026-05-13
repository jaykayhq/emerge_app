import 'package:drift/drift.dart';

class UserStatsTable extends Table {
  TextColumn get userId => text()();
  IntColumn get totalXp => integer().withDefault(const Constant(0))();
  IntColumn get level => integer().withDefault(const Constant(1))();
  IntColumn get streak => integer().withDefault(const Constant(0))();
  IntColumn get strengthXp => integer().withDefault(const Constant(0))();
  IntColumn get intellectXp => integer().withDefault(const Constant(0))();
  IntColumn get vitalityXp => integer().withDefault(const Constant(0))();
  IntColumn get creativityXp => integer().withDefault(const Constant(0))();
  IntColumn get focusXp => integer().withDefault(const Constant(0))();
  IntColumn get spiritXp => integer().withDefault(const Constant(0))();
  IntColumn get challengeXp => integer().withDefault(const Constant(0))();
  RealColumn get worldHealthScore => real().withDefault(const Constant(1.0))();
  TextColumn get archetype => text().nullable()();
  TextColumn get avatarJson => text().nullable()();
  TextColumn get worldStateJson => text().nullable()();
  TextColumn get updatedAt => text().withDefault(Constant(''))();
  TextColumn get syncedAt => text().nullable()();
  IntColumn get onboardingProgress => integer().withDefault(const Constant(0))();
  TextColumn get onboardingCompletedAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {userId};
}
