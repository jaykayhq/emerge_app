import 'package:drift/drift.dart';

class UserStatsTable extends Table {
  TextColumn get userId => text()();
  TextColumn get displayName => text().nullable()();
  TextColumn get photoUrl => text().nullable()();
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
  TextColumn get characterClass => text().nullable()();
  TextColumn get motive => text().nullable()();
  TextColumn get why => text().nullable()();
  TextColumn get anchorsJson => text().nullable()();
  TextColumn get habitStacksJson => text().nullable()();
  TextColumn get skippedOnboardingStepsJson => text().nullable()();
  TextColumn get settingsJson => text().nullable()();
  TextColumn get avatarJson => text().nullable()();
  TextColumn get worldStateJson => text().nullable()();
  TextColumn get updatedAt => text().withDefault(Constant(''))();
  TextColumn get syncedAt => text().nullable()();
  IntColumn get onboardingProgress =>
      integer().withDefault(const Constant(0))();
  TextColumn get onboardingCompletedAt => text().nullable()();
  TextColumn get onboardingStartedAt => text().nullable()();
  BoolColumn get hasEmerged => boolean().withDefault(const Constant(false))();
  RealColumn get momentumScore => real().withDefault(const Constant(0.5))();
  IntColumn get lastCelebratedLevel =>
      integer().withDefault(const Constant(0))();
  TextColumn get interestsCsv => text().nullable()();
  TextColumn get joinedClubId => text().nullable()();

  @override
  Set<Column> get primaryKey => {userId};
}
