import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/social/domain/entities/leaderboard_entry.dart';
import 'package:emerge_app/features/social/domain/repositories/leaderboard_repository.dart';
import 'package:fpdart/fpdart.dart';

/// Firestore implementation of LeaderboardRepository
/// Manages club and challenge leaderboards with real-time updates
class FirestoreLeaderboardRepository implements LeaderboardRepository {
  final FirebaseFirestore _firestore;

  FirestoreLeaderboardRepository(this._firestore);

  @override
  Stream<List<LeaderboardEntry>> watchClubLeaderboard([String? clubId]) {
    // Return empty stream if clubId is not provided
    if (clubId == null || clubId.isEmpty) {
      AppLogger.w('watchClubLeaderboard called with empty clubId');
      return const Stream.empty();
    }

    return _firestore
        .collection('club_leaderboards')
        .where('clubId', isEqualTo: clubId)
        .orderBy('xp', descending: true)
        .orderBy('lastUpdated', descending: true)
        .limit(100)
        .snapshots()
        .handleError((error, stack) {
          AppLogger.e('Error watching club leaderboard', error, stack);
        })
        .map((snapshot) {
          // Calculate rank based on position in sorted list
          return snapshot.docs.map((doc) {
            final data = doc.data();
            final index = snapshot.docs.indexOf(doc);
            return LeaderboardEntry(
              userId: data['userId'] as String? ?? '',
              userName: data['userName'] as String? ?? 'Anonymous',
              xp: data['xp'] as int? ?? 0,
              level: data['level'] as int? ?? 1,
              archetype: UserArchetype.values.firstWhere(
                (e) => e.name == data['archetype'],
                orElse: () => UserArchetype.none,
              ),
              rank: index + 1, // 1-based rank
              lastUpdated: data['lastUpdated'] != null
                  ? DateTime.tryParse(data['lastUpdated'] as String)
                  : null,
            );
          }).toList();
        });
  }

  @override
  Stream<List<LeaderboardEntry>> watchChallengeLeaderboard([
    String? challengeId,
  ]) {
    // Return empty stream if challengeId is not provided
    if (challengeId == null || challengeId.isEmpty) {
      AppLogger.w('watchChallengeLeaderboard called with empty challengeId');
      return const Stream.empty();
    }

    return _firestore
        .collection('challenge_leaderboards')
        .where('challengeId', isEqualTo: challengeId)
        .orderBy('xp', descending: true)
        .orderBy('lastUpdated', descending: true)
        .limit(100)
        .snapshots()
        .handleError((error, stack) {
          AppLogger.e('Error watching challenge leaderboard', error, stack);
        })
        .map((snapshot) {
          // Calculate rank based on position in sorted list
          return snapshot.docs.map((doc) {
            final data = doc.data();
            final index = snapshot.docs.indexOf(doc);
            return LeaderboardEntry(
              userId: data['userId'] as String? ?? '',
              userName: data['userName'] as String? ?? 'Anonymous',
              xp: data['xp'] as int? ?? 0,
              level: data['level'] as int? ?? 1,
              archetype: UserArchetype.values.firstWhere(
                (e) => e.name == data['archetype'],
                orElse: () => UserArchetype.none,
              ),
              rank: index + 1, // 1-based rank
              lastUpdated: data['lastUpdated'] != null
                  ? DateTime.tryParse(data['lastUpdated'] as String)
                  : null,
            );
          }).toList();
        });
  }

  @override
  Future<Either<Failure, Unit>> updateUserScore(
    String userId, {
    required int xp,
    required int level,
    required UserArchetype archetype,
    String? userName,
    String? clubId,
    String? challengeId,
  }) async {
    // Validate userId
    if (userId.isEmpty) {
      AppLogger.w('updateUserScore called with empty userId');
      return Left(ServerFailure('User ID cannot be empty'));
    }

    // Validate that at least one leaderboard type is specified
    if (clubId == null && challengeId == null) {
      AppLogger.w('updateUserScore called without clubId or challengeId');
      return Left(
        ServerFailure('Either clubId or challengeId must be provided'),
      );
    }

    try {
      final now = DateTime.now();

      // Update club leaderboard if clubId provided
      if (clubId != null && clubId.isNotEmpty) {
        final docRef = _firestore
            .collection('club_leaderboards')
            .doc('${userId}_$clubId');

        await docRef.set({
          'userId': userId,
          'userName': userName ?? 'Anonymous',
          'clubId': clubId,
          'xp': xp,
          'level': level,
          'archetype': archetype.name,
          'lastUpdated': now.toIso8601String(),
        }, SetOptions(merge: true));

        AppLogger.i(
          'Updated club leaderboard for user $userId in club $clubId',
        );
      }

      // Update challenge leaderboard if challengeId provided
      if (challengeId != null && challengeId.isNotEmpty) {
        final docRef = _firestore
            .collection('challenge_leaderboards')
            .doc('${userId}_$challengeId');

        await docRef.set({
          'userId': userId,
          'userName': userName ?? 'Anonymous',
          'challengeId': challengeId,
          'xp': xp,
          'level': level,
          'archetype': archetype.name,
          'lastUpdated': now.toIso8601String(),
        }, SetOptions(merge: true));

        AppLogger.i(
          'Updated challenge leaderboard for user $userId in challenge $challengeId',
        );
      }

      return const Right(unit);
    } catch (e, s) {
      AppLogger.e('Failed to update user score', e, s);
      return Left(ServerFailure(e.toString()));
    }
  }
}
