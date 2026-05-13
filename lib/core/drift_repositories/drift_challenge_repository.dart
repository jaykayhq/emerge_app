import 'package:emerge_app/core/drift/database.dart';
import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/core/game_loop/game_loop_engine.dart';
import 'package:emerge_app/core/sync/sync_engine.dart';
import 'package:emerge_app/features/social/domain/models/challenge.dart';
import 'package:emerge_app/features/social/domain/models/challenge_catalog.dart';
import 'package:emerge_app/features/social/domain/repositories/challenge_repository.dart';
import 'package:fpdart/fpdart.dart';

class DriftChallengeRepository implements ChallengeRepository {
  final AppDatabase _db;
  final LocalGameLoopEngine _engine;
  final EnhancedSyncEngine _syncEngine;

  DriftChallengeRepository(this._db, this._engine, this._syncEngine);

  @override
  Future<Either<Failure, Unit>> joinChallenge(String userId, String challengeId) async {
    try {
      final challenge = ChallengeCatalog.getChallengeById(challengeId);
      if (challenge == null) return Left(ServerFailure('Challenge not found'));

      await _db.challengeProgressDao.insertFromData(
        challengeId: challengeId,
        userId: userId,
        title: challenge.title,
        attribute: challenge.xpReward > 0 ? 'vitality' : null,
        totalDays: challenge.totalDays,
        xpReward: challenge.xpReward,
        joinedAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      );

      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateProgress(String userId, String challengeId, int progress) async {
    try {
      final challenges = await _db.challengeProgressDao.getActive(userId);
      final challenge = challenges.where((c) => c.challengeId == challengeId).firstOrNull;
      if (challenge == null) return Left(ServerFailure('Challenge not found'));

      final result = _engine.processChallengeProgress(
        currentDay: challenge.currentDay,
        totalDays: challenge.totalDays,
        xpReward: challenge.xpReward,
      );

      await _db.challengeProgressDao.updateDay(
        challengeId, result.newDay,
        result.isCompleted ? 'completed' : 'active',
      );

      if (result.isCompleted && result.xpReward != null) {
        final stats = await _db.userStatsDao.getStats(userId);
        if (stats != null) {
          final newTotal = stats.totalXp + result.xpReward!;
          final newLevel = _engine.computeLevel(newTotal);
          await _db.userStatsDao.updateAttributeXp(
            userId, 'vitality', result.xpReward!, newLevel, newTotal,
          );
        }
      }

      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> completeChallengeWithReward(String userId, String challengeId) async {
    try {
      await _db.challengeProgressDao.updateDay(challengeId, 0, 'completed');
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<List<Challenge>> getChallenges({bool featuredOnly = false}) async {
    return ChallengeCatalog.getFeatured();
  }

  @override
  Future<List<Challenge>> getUserChallenges(String userId) async {
    final all = await _db.challengeProgressDao.getActive(userId);
    return all.map((r) => Challenge(
      id: r.challengeId,
      title: r.title ?? '',
      description: '',
      imageUrl: '',
      reward: '',
      participants: 0,
      daysLeft: r.totalDays - r.currentDay,
      totalDays: r.totalDays,
      currentDay: r.currentDay,
      status: ChallengeStatus.values.firstWhere(
        (e) => e.name == r.status,
        orElse: () => ChallengeStatus.featured,
      ),
      xpReward: r.xpReward,
      steps: [],
    )).toList();
  }

  @override
  Future<List<Challenge>> getChallengesByArchetype(String archetypeId) async {
    return ChallengeCatalog.getAvailableChallenges(archetypeId);
  }

  @override
  Future<Challenge?> getWeeklySpotlight({String? archetypeId}) async {
    if (archetypeId == null) return null;
    return ChallengeCatalog.getWeeklySpotlight(archetypeId);
  }

  @override
  Future<Challenge?> getChallengeById(String id) async {
    return ChallengeCatalog.getChallengeById(id);
  }

  @override
  Future<void> completeChallenge(String userId, String challengeId) async {
    await _db.challengeProgressDao.updateDay(challengeId, 0, 'completed');
  }

  @override
  Future<void> createSoloChallenge(String userId, Challenge challenge) async {
    await _db.challengeProgressDao.insertFromData(
      challengeId: challenge.id,
      userId: userId,
      title: challenge.title,
      totalDays: challenge.totalDays,
      xpReward: challenge.xpReward,
      updatedAt: DateTime.now().toIso8601String(),
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getLeaderboard(String challengeId, {int limit = 3}) async {
    return [];
  }

  @override
  Future<void> seedChallengesIfEmpty() async {}
}
