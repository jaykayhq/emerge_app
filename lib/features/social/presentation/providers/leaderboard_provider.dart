import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/features/social/data/repositories/firestore_leaderboard_repository.dart';
import 'package:emerge_app/features/social/domain/entities/leaderboard_entry.dart';
import 'package:emerge_app/features/social/domain/repositories/leaderboard_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'leaderboard_provider.g.dart';

/// Provides the LeaderboardRepository instance
@riverpod
LeaderboardRepository leaderboardRepository(Ref ref) {
  final firestore = FirebaseFirestore.instance;
  return FirestoreLeaderboardRepository(firestore);
}

/// Stream provider for club leaderboard
/// Returns empty stream if user is not authenticated
@riverpod
Stream<List<LeaderboardEntry>> clubLeaderboard(Ref ref, String clubId) {
  if (clubId.isEmpty) {
    return const Stream.empty();
  }

  final repository = ref.watch(leaderboardRepositoryProvider);
  return repository.watchClubLeaderboard(clubId);
}

/// Stream provider for challenge leaderboard
/// Returns empty stream if user is not authenticated
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
