import 'package:emerge_app/core/drift/database.dart';
import 'package:emerge_app/core/drift_repositories/drift_leaderboard_repository.dart';
import 'package:emerge_app/core/sync/sync_providers.dart';
import 'package:emerge_app/features/social/domain/entities/leaderboard_entry.dart';
import 'package:emerge_app/features/social/domain/repositories/leaderboard_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'leaderboard_provider.g.dart';

@riverpod
LeaderboardRepository leaderboardRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  final syncEngine = ref.watch(enhancedSyncEngineProvider);
  return DriftLeaderboardRepository(db, syncEngine);
}

@riverpod
Stream<List<LeaderboardEntry>> clubLeaderboard(Ref ref, String clubId) {
  if (clubId.isEmpty) {
    return const Stream.empty();
  }
  final repository = ref.watch(leaderboardRepositoryProvider);
  return repository.watchClubLeaderboard(clubId);
}

@riverpod
Stream<List<LeaderboardEntry>> challengeLeaderboard(
  Ref ref,
  String challengeId,
) {
  if (challengeId.isEmpty) {
    return const Stream.empty();
  }
  final repository = ref.watch(leaderboardRepositoryProvider);
  return repository.watchChallengeLeaderboard(challengeId);
}
