import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/social/domain/models/challenge.dart';
import 'package:emerge_app/features/social/domain/models/challenge_catalog.dart';
import 'package:emerge_app/features/social/domain/repositories/challenge_repository.dart';
import 'package:emerge_app/features/social/domain/services/club_activity_service.dart';
import 'package:fpdart/fpdart.dart';

class FirestoreChallengeRepository implements ChallengeRepository {
  final FirebaseFirestore _firestore;
  final SocialActivityService? _socialActivityService;

  FirestoreChallengeRepository(this._firestore, [this._socialActivityService]);

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
  Future<Either<Failure, Unit>> joinChallenge(
    String userId,
    String challengeId,
  ) async {
    try {
      final challengeDoc = await _firestore
          .collection('challenges')
          .doc(challengeId)
          .get();

      Map<String, dynamic>? challengeData;

      // Fallback to local ChallengeCatalog if the global doc hasn't been created yet
      if (!challengeDoc.exists) {
        final localChallenge = ChallengeCatalog.getChallengeById(challengeId);
        if (localChallenge == null) {
          return Left(
            ServerFailure('Challenge not found globally or locally.'),
          );
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
        return Left(ServerFailure('Challenge data is null'));
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

      return const Right(unit);
    } catch (e) {
      AppLogger.e('Error joining challenge', e.toString(), StackTrace.current);
      return Left(ServerFailure(e.toString()));
    }
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
      final userChallengeRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('challenges')
          .doc(challengeId);
      final userStatsRef = _firestore.collection('user_stats').doc(userId);

      // Success payload if we complete the challenge
      Map<String, dynamic>? completionLog;

      final result = await _firestore.runTransaction<Either<Failure, Unit>>((
        transaction,
      ) async {
        // 1. ALL GETS FIRST
        final challengeSnapshot = await transaction.get(userChallengeRef);
        final userStatsSnapshot = await transaction.get(userStatsRef);

        if (!challengeSnapshot.exists) {
          return Left(
            ServerFailure(
              'Challenge not found. Please join the challenge first.',
            ),
          );
        }

        final challengeData = challengeSnapshot.data()!;
        final currentDay = (challengeData['currentDay'] as num?)?.toInt() ?? 0;
        final totalDays = (challengeData['totalDays'] as num?)?.toInt() ?? 1;
        final currentStatus = challengeData['status'] as String?;

        if (progress != currentDay + 1) {
          return Left(
            ServerFailure(
              'Progress can only be incremented by 1 day at a time.',
            ),
          );
        }

        if (progress > totalDays) {
          return Left(
            ServerFailure('Challenge progress cannot exceed total days.'),
          );
        }

        if (currentStatus == ChallengeStatus.completed.name) {
          return Left(ServerFailure('This challenge is already completed.'));
        }

        // 2. PREPARE UPDATES
        final updateData = <String, dynamic>{'currentDay': progress};
        final isCompleted = progress >= totalDays;

        if (isCompleted) {
          updateData['status'] = ChallengeStatus.completed.name;
          final xpReward = (challengeData['xpReward'] as num?)?.toInt() ?? 50;

          if (userStatsSnapshot.exists) {
            final userStatsData = userStatsSnapshot.data()!;
            var avatarStats = UserAvatarStats.fromMap(
              userStatsData['avatarStats'] as Map<String, dynamic>? ?? {},
            );

            final primaryAttribute =
                challengeData['attribute'] as String? ?? 'vitality';

            avatarStats = avatarStats.addAttributeXp(primaryAttribute, xpReward);
            avatarStats = avatarStats.copyWith(
              challengeXp: avatarStats.challengeXp + xpReward,
            );

            transaction.set(
              userStatsRef,
              {
                'avatarStats': avatarStats.toMap(),
                'totalXp': avatarStats.totalXp,
                'level': avatarStats.level,
              },
              SetOptions(merge: true),
            );

            // Capture completion data for social logging outside
            completionLog = {
              'userId': userId,
              'userName': userStatsData['displayName'] ?? 'Warrior',
              'archetype': userStatsData['archetype'] ?? 'none',
              'challengeId': challengeId,
              'title': challengeData['title'] ?? 'Challenge',
              'xpReward': xpReward,
            };
          }
        }

        transaction.update(userChallengeRef, updateData);
        return const Right(unit);
      });

      // 3. SOCIAL LOGGING OUTSIDE TRANSACTION
      if (result.isRight() && completionLog != null && _socialActivityService != null) {
        // Note: logChallengeComplete has its own internal transaction for tribes/leaderboards
        // which would have conflicted if run inside this one.
        unawaited(_socialActivityService.logChallengeComplete(
          userId: completionLog!['userId'],
          userName: completionLog!['userName'],
          archetype: completionLog!['archetype'],
          challengeId: completionLog!['challengeId'],
          challengeTitle: completionLog!['title'],
          xpReward: completionLog!['xpReward'],
        ));
      }

      return result;
    } catch (e, stackTrace) {
      AppLogger.e('Challenge progress update failed', e, stackTrace);
      return Left(ServerFailure('Failed to update: ${e.toString()}'));
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
      final userChallengeRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('challenges')
          .doc(challengeId);
      final userStatsRef = _firestore.collection('user_stats').doc(userId);

      Map<String, dynamic>? completionLog;

      final result = await _firestore.runTransaction<Either<Failure, Unit>>((
        transaction,
      ) async {
        // 1. ALL GETS FIRST
        final challengeSnapshot = await transaction.get(userChallengeRef);
        final userStatsSnapshot = await transaction.get(userStatsRef);

        if (!challengeSnapshot.exists) {
          return Left(ServerFailure('Challenge not found.'));
        }

        final challengeData = challengeSnapshot.data()!;
        final currentStatus = challengeData['status'] as String?;
        final xpReward = (challengeData['xpReward'] as num?)?.toInt() ?? 0;

        if (currentStatus == ChallengeStatus.completed.name) {
          return Left(ServerFailure('Challenge already completed.'));
        }

        // 2. Perform UPDATES
        transaction.update(userChallengeRef, {
          'status': ChallengeStatus.completed.name,
          'completedAt': FieldValue.serverTimestamp(),
          'lastUpdated': FieldValue.serverTimestamp(),
        });

        if (xpReward > 0 && userStatsSnapshot.exists) {
          final userStatsData = userStatsSnapshot.data()!;
          var avatarStats = UserAvatarStats.fromMap(
            userStatsData['avatarStats'] as Map<String, dynamic>? ?? {},
          );

          final primaryAttribute =
              challengeData['attribute'] as String? ?? 'vitality';
          
          avatarStats = avatarStats.addAttributeXp(primaryAttribute, xpReward);
          avatarStats = avatarStats.copyWith(
            challengeXp: avatarStats.challengeXp + xpReward,
          );

          transaction.set(
            userStatsRef,
            {
              'avatarStats': avatarStats.toMap(),
              'totalXp': avatarStats.totalXp,
              'level': avatarStats.level,
            },
            SetOptions(merge: true),
          );

          // Capture completion data for social logging outside
          completionLog = {
            'userId': userId,
            'userName': userStatsData['displayName'] ?? 'Warrior',
            'archetype': userStatsData['archetype'] ?? 'none',
            'challengeId': challengeId,
            'title': challengeData['title'] ?? 'Challenge',
            'xpReward': xpReward,
          };
        }

        return const Right(unit);
      });

      // 3. SOCIAL LOGGING OUTSIDE TRANSACTION
      if (result.isRight() && completionLog != null && _socialActivityService != null) {
        unawaited(_socialActivityService.logChallengeComplete(
          userId: completionLog!['userId'],
          userName: completionLog!['userName'],
          archetype: completionLog!['archetype'],
          challengeId: completionLog!['challengeId'],
          challengeTitle: completionLog!['title'],
          xpReward: completionLog!['xpReward'],
        ));
      }

      return result;
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
