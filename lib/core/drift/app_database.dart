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
import 'tables/narrator_notes_table.dart';
import 'tables/pulse_feed_cards_table.dart';
import 'tables/daily_reflections_table.dart';
import 'tables/habit_reflections_table.dart';

import 'daos/user_stats_dao.dart';
import 'daos/habits_dao.dart';
import 'daos/habit_completions_dao.dart';
import 'daos/challenge_progress_dao.dart';
import 'daos/tribe_stats_dao.dart';
import 'daos/leaderboard_entries_dao.dart';
import 'daos/mutation_queue_dao.dart';
import 'daos/tribe_activity_dao.dart';
import 'daos/narrator_notes_dao.dart';
import 'daos/pulse_feed_dao.dart';
import 'daos/daily_reflections_dao.dart';
import 'daos/habit_reflections_dao.dart';

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
    NarratorNotesTable,
    PulseFeedCardsTable,
    DailyReflectionsTable,
    HabitReflectionsTable,
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
    NarratorNotesDao,
    PulseFeedDao,
    DailyReflectionsDao,
    HabitReflectionsDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(createDriftConnection());

  AppDatabase.withExecutor(super.executor);

  @override
  int get schemaVersion => 9;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.deleteTable(userStatsTable.actualTableName);
        await m.createTable(userStatsTable);
      }
      if (from < 3) {
        await m.addColumn(
          userStatsTable,
          userStatsTable.lastCelebratedLevel,
        );
      }
      if (from < 4) {
        await m.addColumn(
          habitsTable,
          habitsTable.timerDurationMinutes,
        );
        await m.addColumn(
          habitsTable,
          habitsTable.integrationType,
        );
        await m.addColumn(
          habitsTable,
          habitsTable.integrationTarget,
        );
      }
      if (from < 5) {
        await m.createTable(narratorNotesTable);
      }
      if (from < 6) {
        await m.createTable(pulseFeedCardsTable);
      }
      if (from < 7) {
        await m.createTable(dailyReflectionsTable);
      }
      if (from < 8) {
        await m.createTable(habitReflectionsTable);
      }
      if (from < 9) {
        await m.addColumn(
          userStatsTable,
          userStatsTable.interestsCsv as GeneratedColumn<Object>,
        );
        await m.addColumn(
          userStatsTable,
          userStatsTable.joinedClubId as GeneratedColumn<Object>,
        );
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
