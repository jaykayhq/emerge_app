import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/core/utils/app_logger.dart';
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
      final result = await _firestore.runTransaction<Either<Failure, Unit>>((
        transaction,
      ) async {
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
            ServerFailure(
              'Challenge not found. Please join the challenge first.',
            ),
          );
        }

        final data = snapshot.data();
        if (data == null) {
          AppLogger.e(
            'Challenge data became null during transaction',
            'Challenge $challengeId not found for user $userId',
            StackTrace.current,
          );
          return Left(
            ServerFailure('Challenge data became null during transaction'),
          );
        }

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
            ServerFailure(
              'Progress can only be incremented by 1 day at a time.',
            ),
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

        // Award XP ONLY on the final day (when challenge is completed)
        final totalXpReward = data['xpReward'] as int? ?? 50;

        if (progress >= totalDays) {
          // Award full XP on completion
          if (totalXpReward > 0) {
            final userStatsRef = _firestore
                .collection('users')
                .doc(userId)
                .collection('stats')
                .doc('main');
            final userStatsSnapshot = await transaction.get(userStatsRef);

            if (userStatsSnapshot.exists) {
              final userStatsData = userStatsSnapshot.data();
              if (userStatsData != null) {
                final avatarStats = Map<String, dynamic>.from(
                  userStatsData['avatarStats'] as Map? ?? {},
                );

                final primaryAttribute =
                    data['attribute'] as String? ?? 'vitality';
                final attributeKey = '${primaryAttribute}Xp';

                final currentAttributeXp =
                    (avatarStats[attributeKey] as int?) ?? 0;
                avatarStats[attributeKey] = currentAttributeXp + totalXpReward;

                // Track challenge XP separately
                final currentChallengeXp =
                    (avatarStats['challengeXp'] as int?) ?? 0;
                avatarStats['challengeXp'] = currentChallengeXp + totalXpReward;

                int totalXp = 0;
                final xpKeys = [
                  'strengthXp',
                  'intellectXp',
                  'vitalityXp',
                  'creativityXp',
                  'focusXp',
                  'spiritXp',
                ];
                for (final key in xpKeys) {
                  totalXp += (avatarStats[key] as int?) ?? 0;
                }

                transaction.set(userStatsRef, {
                  'avatarStats': avatarStats,
                  'currentXp': totalXp,
                }, SetOptions(merge: true));

                AppLogger.i(
                  'Challenge completed! Full XP awarded: User $userId, Challenge $challengeId, XP: $totalXpReward',
                );
              }
            }
          }
        }

        AppLogger.d(
          'Challenge progress updated: User $userId, Challenge $challengeId, Day $progress/$totalDays',
        );

        return Right(unit);
      });

      // After successful transaction, log social activity + XP for completion
      if (result.isRight() && _socialActivityService != null) {
        final checkDoc = await _firestore
            .collection('users')
            .doc(userId)
            .collection('challenges')
            .doc(challengeId)
            .get();
        final checkData = checkDoc.data();
        if (checkData != null &&
            checkData['status'] == ChallengeStatus.completed.name) {
          try {
            final userDoc = await _firestore
                .collection('users')
                .doc(userId)
                .get();
            if (userDoc.exists) {
              final userData = userDoc.data() as Map<String, dynamic>;
              final userName =
                  userData['displayName'] as String? ?? 'Anonymous';
              final archetype = userData['archetype'] as String? ?? 'none';
              final xpReward = checkData['xpReward'] as int? ?? 50;
              final title = checkData['title'] as String? ?? 'a challenge';

              await _socialActivityService.logChallengeComplete(
                userId: userId,
                userName: userName,
                archetype: archetype,
                challengeId: challengeId,
                challengeTitle: title,
                xpReward: xpReward,
              );
              AppLogger.i(
                'Logged challenge completion to social activity + XP: $challengeId',
              );
            }
          } catch (socialError, socialStack) {
            AppLogger.e(
              'Failed to log challenge completion to social activity',
              socialError,
              socialStack,
            );
          }
        }
      }
      return result;
    } catch (e, stackTrace) {
      AppLogger.e('Challenge progress update failed', e, stackTrace);
      return Left(
        ServerFailure('Failed to update challenge progress: ${e.toString()}'),
      );
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
            ServerFailure(
              'Challenge not found. Please join the challenge first.',
            ),
          );
        }

        final challengeData = challengeSnapshot.data();
        if (challengeData == null) {
          AppLogger.e(
            'Challenge data became null during transaction',
            'Challenge $challengeId not found for user $userId',
            StackTrace.current,
          );
          return Left(
            ServerFailure('Challenge data became null during transaction'),
          );
        }

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
        transaction.update(userChallengeRef, {
          'status': ChallengeStatus.completed.name,
        });

        // Award XP to user if reward > 0
        if (xpReward > 0) {
          final userStatsRef = _firestore.collection('user_stats').doc(userId);
          final userStatsSnapshot = await transaction.get(userStatsRef);

          if (userStatsSnapshot.exists) {
            final userData = userStatsSnapshot.data();
            if (userData == null) {
              AppLogger.e(
                'User stats data became null during transaction',
                'User stats not found for user $userId',
                StackTrace.current,
              );
            } else {
              final avatarStats = Map<String, dynamic>.from(
                userData['avatarStats'] as Map? ?? {},
              );

              // Determine the primary attribute for this challenge
              // Default to 'vitality' if not specified
              final primaryAttribute =
                  challengeData['attribute'] as String? ?? 'vitality';
              final attributeKey = '${primaryAttribute}Xp';

              // Add XP to the challenge's primary attribute
              final currentAttributeXp =
                  (avatarStats[attributeKey] as int?) ?? 0;
              avatarStats[attributeKey] = currentAttributeXp + xpReward;

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
              transaction.set(userStatsRef, {
                'avatarStats': avatarStats,
                'currentXp': totalXp,
                'currentLevel': avatarStats['level'] as int? ?? 1,
              }, SetOptions(merge: true));

              AppLogger.i(
                'XP awarded for challenge completion: User $userId, Challenge $challengeId, '
                'Attribute: $attributeKey, XP: $xpReward',
              );
            }
          } else {
            AppLogger.w(
              'User stats document not found for XP award: User $userId',
            );
          }
        }

        AppLogger.i(
          'Challenge completed with reward: User $userId, Challenge $challengeId',
        );

        return const Right(unit);
      });
    } catch (e, stackTrace) {
      AppLogger.e('Challenge completion failed', e, stackTrace);
      return Left(
        ServerFailure('Failed to complete challenge: ${e.toString()}'),
      );
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
