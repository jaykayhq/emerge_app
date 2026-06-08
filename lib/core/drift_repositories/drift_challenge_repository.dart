import 'package:emerge_app/core/drift/database.dart';
import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/core/game_loop/game_loop_engine.dart';
import 'package:emerge_app/features/social/domain/models/challenge.dart';
import 'package:emerge_app/features/social/domain/models/challenge_catalog.dart';
import 'package:emerge_app/features/social/domain/repositories/challenge_repository.dart';
import 'package:emerge_app/core/sync/sync_engine.dart';
import 'package:fpdart/fpdart.dart';

class DriftChallengeRepository implements ChallengeRepository {
  final AppDatabase _db;
  final LocalGameLoopEngine _engine;
  final EnhancedSyncEngine _syncEngine;

  DriftChallengeRepository(this._db, this._engine, this._syncEngine);

  @override
  Future<Either<Failure, Unit>> joinChallenge(
    String userId,
    String challengeId,
  ) async {
    try {
      final template = ChallengeCatalog.getChallengeById(challengeId);
      if (template == null) return Left(ServerFailure('Challenge not found'));

      await _db.challengeProgressDao.insertFromData(
        challengeId: challengeId,
        userId: userId,
        title: template.title,
        attribute: template.xpReward > 0 ? 'vitality' : null,
        totalDays: template.totalDays,
        xpReward: template.xpReward,
        joinedAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      );

      // Read back to ensure sync payload matches local state
      final progress = (await _db.challengeProgressDao.getActive(userId))
          .firstWhere(
            (p) => p.challengeId == challengeId,
            orElse: () => throw StateError('Challenge progress not found'),
          );

      // Sync to Firestore with values from local DB
      await _syncEngine.enqueueSet(
        collectionPath: 'users/$userId/challenges',
        documentId: challengeId,
        data: {
          'challengeId': progress.challengeId,
          'userId': progress.userId,
          'title': progress.title,
          'totalDays': progress.totalDays,
          'xpReward': progress.xpReward,
          'joinedAt': progress.joinedAt,
          'updatedAt': DateTime.now().toIso8601String(),
          'status': progress.status,
          'currentDay': progress.currentDay,
        },
      );

      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateProgress(
    String userId,
    String challengeId,
    int progress,
  ) async {
    try {
      final challenges = await _db.challengeProgressDao.getActive(userId);
      final challenge = challenges
          .where((c) => c.challengeId == challengeId)
          .firstOrNull;
      if (challenge == null) return Left(ServerFailure('Challenge not found'));

      final result = _engine.processChallengeProgress(
        currentDay: challenge.currentDay,
        totalDays: challenge.totalDays,
        xpReward: challenge.xpReward,
      );

      await _db.challengeProgressDao.updateDay(
        challengeId,
        result.newDay,
        result.isCompleted ? 'completed' : 'active',
      );

      if (result.isCompleted && result.xpReward != null) {
        final stats = await _db.userStatsDao.getStats(userId);
        if (stats != null) {
          final newTotal = stats.totalXp + result.xpReward!;
          final newLevel = _engine.computeLevel(newTotal);
          await _db.userStatsDao.updateAttributeXp(
            userId,
            'vitality',
            result.xpReward!,
            newLevel,
            newTotal,
          );
        }
      }

      // Sync to Firestore
      await _syncEngine.enqueueSet(
        collectionPath: 'users/$userId/challenges',
        documentId: challengeId,
        data: {
          'currentDay': result.newDay,
          'status': result.isCompleted ? 'completed' : 'active',
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );

      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> completeChallengeWithReward(
    String userId,
    String challengeId,
  ) async {
    try {
      await _db.challengeProgressDao.updateDay(challengeId, 0, 'completed');

      // Sync to Firestore
      await _syncEngine.enqueueSet(
        collectionPath: 'users/$userId/challenges',
        documentId: challengeId,
        data: {
          'status': 'completed',
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );

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
    final all = await _db.challengeProgressDao.getAll(userId);
    return all.map((r) {
      // Look up the original template from catalog to get metadata
      // (imageUrl, description, reward, steps) not stored in the DB
      final template = ChallengeCatalog.getChallengeById(r.challengeId);
      return Challenge(
        id: r.challengeId,
        title: r.title ?? template?.title ?? '',
        description: template?.description ?? '',
        imageUrl: template?.imageUrl ?? '',
        reward: template?.reward ?? '',
        participants: template?.participants ?? 0,
        daysLeft: r.totalDays - r.currentDay,
        totalDays: r.totalDays,
        currentDay: r.currentDay,
        joinedAt: r.joinedAt != null ? DateTime.tryParse(r.joinedAt!) : null,
        status: ChallengeStatus.values.firstWhere(
          (e) => e.name == r.status,
          orElse: () => ChallengeStatus.featured,
        ),
        xpReward: r.xpReward,
        steps: template?.steps ?? [],
        archetypeId: template?.archetypeId,
        category: template?.category ?? ChallengeCategory.all,
      );
    }).toList();
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

    // Sync to Firestore
    await _syncEngine.enqueueSet(
      collectionPath: 'users/$userId/challenges',
      documentId: challengeId,
      data: {
        'status': 'completed',
        'updatedAt': DateTime.now().toIso8601String(),
      },
    );
  }

  @override
  Future<void> createSoloChallenge(String userId, Challenge challenge) async {
    final nowStr = DateTime.now().toIso8601String();
    await _db.challengeProgressDao.insertFromData(
      challengeId: challenge.id,
      userId: userId,
      title: challenge.title,
      totalDays: challenge.totalDays,
      xpReward: challenge.xpReward,
      joinedAt: nowStr,
      updatedAt: nowStr,
    );

    // Sync to Firestore
    await _syncEngine.enqueueSet(
      collectionPath: 'users/$userId/challenges',
      documentId: challenge.id,
      data: {
        'challengeId': challenge.id,
        'userId': userId,
        'title': challenge.title,
        'totalDays': challenge.totalDays,
        'xpReward': challenge.xpReward,
        'joinedAt': nowStr,
        'updatedAt': nowStr,
        'status': 'active',
        'currentDay': 0,
        'isSolo': true,
      },
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getLeaderboard(
    String challengeId, {
    int limit = 3,
  }) async {
    return [];
  }

  @override
  Future<void> seedChallengesIfEmpty() async {}
}
