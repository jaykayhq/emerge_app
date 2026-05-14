/// Database providers — conditionally imports drift types.
///
/// On native platforms (`dart.library.io`) the real `drift_native.dart` barrel
/// is used, which brings in the actual `AppDatabase`, DAO types and drift
/// packages.  On the web the `drift_stubs.dart` placeholder is imported
/// instead — every provider already returns `null` when `kIsWeb` is true, so
/// the stubs are never instantiated at runtime.

export 'drift_stubs.dart' if (dart.library.io) 'drift_native.dart';
import 'drift_stubs.dart' if (dart.library.io) 'drift_native.dart';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

part 'database.g.dart';

// ---------------------------------------------------------------------------
// AppDatabase provider
// ---------------------------------------------------------------------------

@Riverpod(keepAlive: true)
AppDatabase? appDatabase(Ref ref) {
  if (kIsWeb) return null;
  return AppDatabase.instance;
}

// ---------------------------------------------------------------------------
// DAO providers
// ---------------------------------------------------------------------------

@Riverpod(keepAlive: true)
UserStatsDao? userStatsDao(Ref ref) {
  if (kIsWeb) return null;
  return ref.watch(appDatabaseProvider)!.userStatsDao;
}

@Riverpod(keepAlive: true)
HabitsDao? habitsDao(Ref ref) {
  if (kIsWeb) return null;
  return ref.watch(appDatabaseProvider)!.habitsDao;
}

@Riverpod(keepAlive: true)
HabitCompletionsDao? habitCompletionsDao(Ref ref) {
  if (kIsWeb) return null;
  return ref.watch(appDatabaseProvider)!.habitCompletionsDao;
}

@Riverpod(keepAlive: true)
ChallengeProgressDao? challengeProgressDao(Ref ref) {
  if (kIsWeb) return null;
  return ref.watch(appDatabaseProvider)!.challengeProgressDao;
}

@Riverpod(keepAlive: true)
TribeStatsDao? tribeStatsDao(Ref ref) {
  if (kIsWeb) return null;
  return ref.watch(appDatabaseProvider)!.tribeStatsDao;
}

@Riverpod(keepAlive: true)
LeaderboardEntriesDao? leaderboardEntriesDao(Ref ref) {
  if (kIsWeb) return null;
  return ref.watch(appDatabaseProvider)!.leaderboardEntriesDao;
}

@Riverpod(keepAlive: true)
BlueprintsDao? blueprintsDao(Ref ref) {
  if (kIsWeb) return null;
  return ref.watch(appDatabaseProvider)!.blueprintsDao;
}

@Riverpod(keepAlive: true)
MutationQueueDao? mutationQueueDao(Ref ref) {
  if (kIsWeb) return null;
  return ref.watch(appDatabaseProvider)!.mutationQueueDao;
}

@Riverpod(keepAlive: true)
TribeActivityDao? tribeActivityDao(Ref ref) {
  if (kIsWeb) return null;
  return ref.watch(appDatabaseProvider)!.tribeActivityDao;
}
