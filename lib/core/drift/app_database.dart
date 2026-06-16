import 'package:drift/drift.dart';

import 'app_database_connection.dart';

import 'tables/user_stats_table.dart';
import 'tables/habits_table.dart';
import 'tables/habit_completions_table.dart';
import 'tables/challenge_progress_table.dart';
import 'tables/tribe_stats_table.dart';
import 'tables/leaderboard_entries_table.dart';
import 'tables/mutation_queue_table.dart';
import 'tables/tribe_activity_table.dart';

import 'daos/user_stats_dao.dart';
import 'daos/habits_dao.dart';
import 'daos/habit_completions_dao.dart';
import 'daos/challenge_progress_dao.dart';
import 'daos/tribe_stats_dao.dart';
import 'daos/leaderboard_entries_dao.dart';
import 'daos/mutation_queue_dao.dart';
import 'daos/tribe_activity_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    UserStatsTable,
    HabitsTable,
    HabitCompletionsTable,
    ChallengeProgressTable,
    TribeStatsTable,
    LeaderboardEntriesTable,
    MutationQueueTable,
    TribeActivityTable,
  ],
  daos: [
    UserStatsDao,
    HabitsDao,
    HabitCompletionsDao,
    ChallengeProgressDao,
    TribeStatsDao,
    LeaderboardEntriesDao,
    MutationQueueDao,
    TribeActivityDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(createDriftConnection());

  AppDatabase.withExecutor(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.deleteTable(userStatsTable.actualTableName);
        await m.createTable(userStatsTable);
      }
    },
    beforeOpen: (details) async {
      if (details.wasCreated) {
        // Initial data seeding if needed
      }
    },
  );

  static AppDatabase? _instance;
  static AppDatabase get instance {
    _instance ??= AppDatabase();
    return _instance!;
  }

  /// Clears all data from all tables in the database.
  Future<void> clearAll() async {
    await transaction(() async {
      for (final table in allTables) {
        await delete(table).go();
      }
    });
  }
}
