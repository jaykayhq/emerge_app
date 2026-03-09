import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:emerge_app/features/social/domain/models/challenge.dart';
import 'package:emerge_app/features/social/domain/models/challenge_catalog.dart';
import 'package:fpdart/fpdart.dart';

abstract class ChallengeRepository {
  Future<List<Challenge>> getChallenges({bool featuredOnly = false});
  Future<List<Challenge>> getUserChallenges(String userId);
  Future<void> joinChallenge(String userId, String challengeId);
  Future<void> createSoloChallenge(String userId, Challenge challenge);
  Future<Either<Failure, Unit>> updateProgress(
    String userId,
    String challengeId,
    int progress,
  );
  Future<void> completeChallenge(String userId, String challengeId);
  Future<Either<Failure, Unit>> completeChallengeWithReward(
    String userId,
    String challengeId,
  );
  Future<List<Challenge>> getChallengesByArchetype(String archetypeId);
  Future<Challenge?> getWeeklySpotlight({String? archetypeId});
  Future<List<Map<String, dynamic>>> getLeaderboard(
    String challengeId, {
    int limit = 3,
  });
}

class FirestoreChallengeRepository implements ChallengeRepository {
  final FirebaseFirestore _firestore;

  FirestoreChallengeRepository(this._firestore);

  @override
  Future<List<Challenge>> getChallenges({bool featuredOnly = false}) async {
    Query query = _firestore.collection('challenges');
    if (featuredOnly) {
      query = query.where('isFeatured', isEqualTo: true);
    }
    final snapshot = await query.get();
    return snapshot.docs.map((doc) {
      return Challenge.fromMap(doc.data() as Map<String, dynamic>, id: doc.id);
    }).toList();
  }

  @override
  Future<List<Challenge>> getUserChallenges(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('challenges')
        .get();
    return snapshot.docs.map((doc) {
      return Challenge.fromMap(doc.data(), id: doc.id);
    }).toList();
  }

  @override
  Future<void> joinChallenge(String userId, String challengeId) async {
    final challengeDoc = await _firestore
        .collection('challenges')
        .doc(challengeId)
        .get();

    Map<String, dynamic>? challengeData;

    // Fallback to local ChallengeCatalog if the global doc hasn't been created yet
    if (!challengeDoc.exists) {
      final localChallenge = ChallengeCatalog.getChallengeById(challengeId);
      if (localChallenge == null) {
        throw Exception('Challenge not found globally or locally.');
      }
      challengeData = localChallenge.toMap();
      // Write the global doc instantly so other users can see participants
      await _firestore
          .collection('challenges')
          .doc(challengeId)
          .set(challengeData);
    } else {
      challengeData = challengeDoc.data();
    }

    if (challengeData == null) {
      throw Exception('Challenge data is null');
    }

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('challenges')
        .doc(challengeId)
        .set({
          ...challengeData,
          'joinedAt': FieldValue.serverTimestamp(),
          'status': ChallengeStatus.active.name,
          'currentDay': 0,
        });

    await _firestore.collection('challenges').doc(challengeId).update({
      'participants': FieldValue.increment(1),
    });
  }

  @override
  Future<void> createSoloChallenge(String userId, Challenge challenge) async {
    // 1. We create the raw challenge document
    final challengeData = challenge.toMap();

    // 2. We set it directly into the user's active challenges subcollection
    // Because it's a solo challenge, we don't need a global document for others to discover
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('challenges')
        .doc(challenge.id)
        .set({
          ...challengeData,
          'joinedAt': FieldValue.serverTimestamp(),
          'status': ChallengeStatus.active.name,
          'currentDay': 0,
        });
  }

  @override
  Future<Either<Failure, Unit>> updateProgress(
    String userId,
    String challengeId,
    int progress,
  ) async {
    try {
      return await _firestore.runTransaction((transaction) async {
        // Get the user's challenge document
        final userChallengeRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('challenges')
            .doc(challengeId);

        final snapshot = await transaction.get(userChallengeRef);

        if (!snapshot.exists) {
          AppLogger.e(
            'Challenge progress update failed: Challenge not found',
            'Challenge $challengeId not found for user $userId',
            StackTrace.current,
          );
          return Left(
            ServerFailure('Challenge not found. Please join the challenge first.'),
          );
        }

        final data = snapshot.data()!;
        final currentDay = data['currentDay'] as int? ?? 0;
        final totalDays = data['totalDays'] as int? ?? 1;
        final currentStatus = data['status'] as String?;

        // Validation 1: Only allow incrementing by 1 (prevent cheating)
        if (progress != currentDay + 1) {
          AppLogger.w(
            'Invalid progress increment attempted: User $userId, Challenge $challengeId, '
            'Current: $currentDay, Attempted: $progress',
          );
          return Left(
            ServerFailure('Progress can only be incremented by 1 day at a time.'),
          );
        }

        // Validation 2: Progress cannot exceed totalDays (cannot exceed 100%)
        if (progress > totalDays) {
          AppLogger.w(
            'Progress exceeds total days: User $userId, Challenge $challengeId, '
            'Progress: $progress, Total: $totalDays',
          );
          return Left(
            ServerFailure('Challenge progress cannot exceed total days.'),
          );
        }

        // Validation 3: Check if challenge is already completed
        if (currentStatus == ChallengeStatus.completed.name) {
          AppLogger.w(
            'Attempted to update completed challenge: User $userId, Challenge $challengeId',
          );
          return Left(ServerFailure('This challenge is already completed.'));
        }

        // Update progress
        final updateData = <String, dynamic>{'currentDay': progress};

        // Auto-mark as completed when progress >= totalDays
        if (progress >= totalDays) {
          updateData['status'] = ChallengeStatus.completed.name;
          AppLogger.i(
            'Challenge automatically marked as completed: User $userId, Challenge $challengeId',
          );
        }

        transaction.update(userChallengeRef, updateData);

        AppLogger.d(
          'Challenge progress updated: User $userId, Challenge $challengeId, Day $progress/$totalDays',
        );

        return const Right(unit);
      });
    } catch (e, stackTrace) {
      AppLogger.e('Challenge progress update failed', e, stackTrace);
      return Left(ServerFailure('Failed to update challenge progress: ${e.toString()}'));
    }
  }

  @override
  Future<void> completeChallenge(String userId, String challengeId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('challenges')
        .doc(challengeId)
        .update({'status': ChallengeStatus.completed.name});
  }

  @override
  Future<Either<Failure, Unit>> completeChallengeWithReward(
    String userId,
    String challengeId,
  ) async {
    try {
      return await _firestore.runTransaction((transaction) async {
        // Get the user's challenge document
        final userChallengeRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('challenges')
            .doc(challengeId);

        final challengeSnapshot = await transaction.get(userChallengeRef);

        if (!challengeSnapshot.exists) {
          AppLogger.e(
            'Challenge completion failed: Challenge not found',
            'Challenge $challengeId not found for user $userId',
            StackTrace.current,
          );
          return Left(
            ServerFailure('Challenge not found. Please join the challenge first.'),
          );
        }

        final challengeData = challengeSnapshot.data()!;
        final currentStatus = challengeData['status'] as String?;
        final currentDay = challengeData['currentDay'] as int? ?? 0;
        final totalDays = challengeData['totalDays'] as int? ?? 1;
        final xpReward = challengeData['xpReward'] as int? ?? 0;

        // Validation: Check if challenge is already completed
        if (currentStatus == ChallengeStatus.completed.name) {
          AppLogger.w(
            'Attempted to complete already completed challenge: User $userId, Challenge $challengeId',
          );
          return Left(ServerFailure('This challenge is already completed.'));
        }

        // Validation: Ensure challenge is fully completed
        if (currentDay < totalDays) {
          AppLogger.w(
            'Attempted to complete incomplete challenge: User $userId, Challenge $challengeId, '
            'Progress: $currentDay/$totalDays',
          );
          return Left(
            ServerFailure('Complete all days before finishing the challenge.'),
          );
        }

        // Update challenge status to completed
        transaction.update(
          userChallengeRef,
          {'status': ChallengeStatus.completed.name},
        );

        // Award XP to user if reward > 0
        if (xpReward > 0) {
          final userStatsRef = _firestore.collection('user_stats').doc(userId);
          final userStatsSnapshot = await transaction.get(userStatsRef);

          if (userStatsSnapshot.exists) {
            final userData = userStatsSnapshot.data()!;
            final avatarStats = Map<String, dynamic>.from(
              userData['avatarStats'] as Map? ?? {},
            );

            // Add XP to vitalityXp (default attribute for challenges)
            final currentVitalityXp = (avatarStats['vitalityXp'] as int?) ?? 0;
            avatarStats['vitalityXp'] = currentVitalityXp + xpReward;

            // Recalculate total XP
            int totalXp = 0;
            final keys = [
              'strengthXp',
              'intellectXp',
              'vitalityXp',
              'creativityXp',
              'focusXp',
              'spiritXp',
            ];
            for (final key in keys) {
              totalXp += (avatarStats[key] as int?) ?? 0;
            }

            // Update user stats
            transaction.set(
              userStatsRef,
              {
                'avatarStats': avatarStats,
                'currentXp': totalXp,
                'currentLevel': avatarStats['level'] as int? ?? 1,
              },
              SetOptions(merge: true),
            );

            AppLogger.i(
              'XP awarded for challenge completion: User $userId, Challenge $challengeId, XP: $xpReward',
            );
          } else {
            AppLogger.w(
              'User stats document not found for XP award: User $userId',
            );
          }
        }

        // Update global challenge participants count
        final globalChallengeRef = _firestore.collection('challenges').doc(challengeId);
        final globalChallengeSnapshot = await transaction.get(globalChallengeRef);

        if (globalChallengeSnapshot.exists) {
          transaction.update(
            globalChallengeRef,
            {'completedCount': FieldValue.increment(1)},
          );
        }

        AppLogger.i(
          'Challenge completed with reward: User $userId, Challenge $challengeId',
        );

        return const Right(unit);
      });
    } catch (e, stackTrace) {
      AppLogger.e('Challenge completion failed', e, stackTrace);
      return Left(ServerFailure('Failed to complete challenge: ${e.toString()}'));
    }
  }

  @override
  Future<List<Challenge>> getChallengesByArchetype(String archetypeId) async {
    // Rely exclusively on the local ChallengeCatalog for robust frontend logic
    return ChallengeCatalog.getAvailableChallenges(archetypeId);
  }

  @override
  Future<Challenge?> getWeeklySpotlight({String? archetypeId}) async {
    // Generate weekly challenge locally instead of pinging Firestore
    if (archetypeId != null) {
      return ChallengeCatalog.getWeeklySpotlight(archetypeId);
    }
    return null;
  }

  @override
  Future<List<Map<String, dynamic>>> getLeaderboard(
    String challengeId, {
    int limit = 3,
  }) async {
    final snapshot = await _firestore
        .collection('challenges')
        .doc(challengeId)
        .collection('participants')
        .orderBy('xp', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }
}
