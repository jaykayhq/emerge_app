// Database providers — conditionally imports drift types.
//
// On native platforms (`dart.library.io`) the real `drift_native.dart` barrel
// is used, which brings in the actual `AppDatabase`, DAO types and drift
// packages (including `drift/native.dart`).
// On the web `drift_web.dart` is used instead, which provides the same types
// but backed by `drift/wasm.dart` (WASM SQLite via IndexedDB).

export 'drift_web.dart' if (dart.library.io) 'drift_native.dart';
import 'drift_web.dart' if (dart.library.io) 'drift_native.dart';

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'database.g.dart';

// ---------------------------------------------------------------------------
// AppDatabase provider
// ---------------------------------------------------------------------------

@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  return AppDatabase.instance;
}

// ---------------------------------------------------------------------------
// DAO providers
// ---------------------------------------------------------------------------

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
MutationQueueDao mutationQueueDao(Ref ref) {
  return ref.watch(appDatabaseProvider).mutationQueueDao;
}

@Riverpod(keepAlive: true)
TribeActivityDao tribeActivityDao(Ref ref) {
  return ref.watch(appDatabaseProvider).tribeActivityDao;
}

@Riverpod(keepAlive: true)
NarratorNotesDao narratorNotesDao(Ref ref) {
  return ref.watch(appDatabaseProvider).narratorNotesDao;
}

@Riverpod(keepAlive: true)
PulseFeedDao pulseFeedDao(Ref ref) {
  return ref.watch(appDatabaseProvider).pulseFeedDao;
}
