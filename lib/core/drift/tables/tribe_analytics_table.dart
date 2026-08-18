// lib/core/drift/tables/tribe_analytics_table.dart
import 'package:drift/drift.dart';

/// Per-tribe-per-day analytics snapshot cache (offline-first render).
class TribeAnalyticsTable extends Table {
  TextColumn get tribeId => text()();
  TextColumn get date => text()(); // yyyy-MM-dd
  IntColumn get memberCount => integer().withDefault(const Constant(0))();
  IntColumn get totalXp => integer().withDefault(const Constant(0))();
  IntColumn get totalHabitsCompleted =>
      integer().withDefault(const Constant(0))();
  IntColumn get totalChallengesCompleted =>
      integer().withDefault(const Constant(0))();
  IntColumn get activeMembers => integer().withDefault(const Constant(0))();
  IntColumn get newMembersThisWeek =>
      integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {tribeId, date};
}