import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/features/social/domain/models/challenge.dart';
import 'package:fpdart/fpdart.dart';

/// Abstract repository interface for challenge operations
/// Defined in domain layer following Clean Architecture principles
abstract class ChallengeRepository {
  /// Retrieve all challenges, optionally filtering by featured status
  Future<List<Challenge>> getChallenges({bool featuredOnly = false});

  /// Retrieve all challenges for a specific user
  Future<List<Challenge>> getUserChallenges(String userId);

  /// Join a challenge - adds it to user's active challenges
  Future<void> joinChallenge(String userId, String challengeId);

  /// Create a solo challenge specific to a user
  Future<void> createSoloChallenge(String userId, Challenge challenge);

  /// Update challenge progress with validation
  /// Returns `Left<Failure>` if validation fails (cheating, already complete, etc.)
  /// Returns `Right<Unit>` on success
  Future<Either<Failure, Unit>> updateProgress(
    String userId,
    String challengeId,
    int progress,
  );

  /// Mark a challenge as completed (without awarding rewards)
  Future<void> completeChallenge(String userId, String challengeId);

  /// Complete a challenge and award XP rewards
  /// Returns `Left<Failure>` if validation fails
  /// Returns `Right<Unit>` on success with XP awarded
  Future<Either<Failure, Unit>> completeChallengeWithReward(
    String userId,
    String challengeId,
  );

  /// Get challenges filtered by archetype
  Future<List<Challenge>> getChallengesByArchetype(String archetypeId);

  /// Get the weekly spotlight challenge for an archetype
  Future<Challenge?> getWeeklySpotlight({String? archetypeId});

  /// Get leaderboard entries for a challenge
  Future<List<Map<String, dynamic>>> getLeaderboard(
    String challengeId, {
    int limit = 3,
  });
}
