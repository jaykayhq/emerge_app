import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/social/domain/entities/leaderboard_entry.dart';
import 'package:fpdart/fpdart.dart';

/// Repository interface for leaderboard operations
/// Provides real-time streaming of leaderboard data and score updates
abstract class LeaderboardRepository {
  /// Watch leaderboard for a specific club
  /// Returns empty stream if clubId is null or empty
  Stream<List<LeaderboardEntry>> watchClubLeaderboard([String? clubId]);

  /// Watch leaderboard for a specific challenge
  /// Returns empty stream if challengeId is null or empty
  Stream<List<LeaderboardEntry>> watchChallengeLeaderboard([
    String? challengeId,
  ]);

  /// Update user's score on a leaderboard
  /// Either clubId or challengeId must be provided
  /// Returns Left(ServerFailure) if:
  /// - userId is empty
  /// - Neither clubId nor challengeId is provided
  Future<Either<Failure, Unit>> updateUserScore(
    String userId, {
    required int xp,
    required int level,
    required UserArchetype archetype,
    String? userName,
    String? clubId,
    String? challengeId,
  });
}
