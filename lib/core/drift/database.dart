import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'tables/user_stats_table.dart';
import 'tables/habits_table.dart';
import 'tables/habit_completions_table.dart';
import 'tables/challenge_progress_table.dart';
import 'tables/tribe_stats_table.dart';
import 'tables/leaderboard_entries_table.dart';
import 'tables/blueprints_table.dart';
import 'tables/mutation_queue_table.dart';

import 'daos/user_stats_dao.dart';
import 'daos/habits_dao.dart';
import 'daos/habit_completions_dao.dart';
import 'daos/challenge_progress_dao.dart';
import 'daos/tribe_stats_dao.dart';
import 'daos/leaderboard_entries_dao.dart';
import 'daos/blueprints_dao.dart';
import 'daos/mutation_queue_dao.dart';

part 'database.g.dart';

@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  return AppDatabase.instance;
}

@Riverpod(keepAlive: true)
UserStatsDao userStatsDao(Ref ref) {
  return ref.watch(appDatabaseProvider).userStatsDao;
}

@Riverpod(keepAlive: true)
HabitsDao habitsDao(Ref ref) {
  return ref.watch(appDatabaseProvider).habitsDao;
}

@Riverpod(keepAlive: true)
HabitCompletionsDao habitCompletionsDao(Ref ref) {
  return ref.watch(appDatabaseProvider).habitCompletionsDao;
}

@Riverpod(keepAlive: true)
ChallengeProgressDao challengeProgressDao(Ref ref) {
  return ref.watch(appDatabaseProvider).challengeProgressDao;
}

@Riverpod(keepAlive: true)
TribeStatsDao tribeStatsDao(Ref ref) {
  return ref.watch(appDatabaseProvider).tribeStatsDao;
}

@Riverpod(keepAlive: true)
LeaderboardEntriesDao leaderboardEntriesDao(Ref ref) {
  return ref.watch(appDatabaseProvider).leaderboardEntriesDao;
}

@Riverpod(keepAlive: true)
BlueprintsDao blueprintsDao(Ref ref) {
  return ref.watch(appDatabaseProvider).blueprintsDao;
}

@Riverpod(keepAlive: true)
MutationQueueDao mutationQueueDao(Ref ref) {
  return ref.watch(appDatabaseProvider).mutationQueueDao;
}

@DriftDatabase(
  tables: [
    UserStatsTable,
    HabitsTable,
    HabitCompletionsTable,
    ChallengeProgressTable,
    TribeStatsTable,
    LeaderboardEntriesTable,
    BlueprintsTable,
    MutationQueueTable,
  ],
  daos: [
    UserStatsDao,
    HabitsDao,
    HabitCompletionsDao,
    ChallengeProgressDao,
    TribeStatsDao,
    LeaderboardEntriesDao,
    BlueprintsDao,
    MutationQueueDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase._() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static AppDatabase? _instance;
  static AppDatabase get instance {
    _instance ??= AppDatabase._();
    return _instance!;
  }

  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'emerge_app.sqlite'));
      return NativeDatabase(file);
    });
  }
}
