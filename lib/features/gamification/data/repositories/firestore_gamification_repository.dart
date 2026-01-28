import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:emerge_app/features/gamification/domain/entities/user_stats.dart';
import 'package:emerge_app/features/gamification/domain/repositories/gamification_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter/foundation.dart';

// ENHANCED: Top-level function for isolate parsing (must be top-level)
UserStats _parseUserStats(Map<String, dynamic> params) {
  final userId = params['userId'] as String;
  final data = params['data'] as Map<String, dynamic>?;

  if (data == null) {
    return UserStats(userId: userId);
  }

  // All parsing happens in isolate, not blocking main thread
  return UserStats(
    userId: userId,
    currentXp: data['currentXp'] as int? ?? 0,
    currentLevel: data['currentLevel'] as int? ?? 1,
    currentStreak: data['currentStreak'] as int? ?? 0,
    unlockedBadges:
        (data['unlockedBadges'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        [],
    identityVotes:
        (data['identityVotes'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(key, value as int),
        ) ??
        const {},
  );
}

class FirestoreGamificationRepository implements GamificationRepository {
  final FirebaseFirestore _firestore;

  FirestoreGamificationRepository(this._firestore);

  @override
  Stream<UserStats> watchUserStats(String userId) {
    return _firestore.collection('user_stats').doc(userId).snapshots().asyncMap((
      snapshot,
    ) async {
      // ENHANCED: Move heavy parsing to isolate to prevent UI jank
      if (!snapshot.exists || snapshot.data() == null) {
        return UserStats(userId: userId);
      }

      // Parse in isolate using compute()
      return compute(_parseUserStats, {
        'userId': userId,
        'data': snapshot.data(),
      });
    }).distinct();
  }

  @override
  Future<Either<Failure, Unit>> updateUserStats(UserStats stats) async {
    try {
      await _firestore.collection('user_stats').doc(stats.userId).set({
        'currentXp': stats.currentXp,
        'currentLevel': stats.currentLevel,
        'currentStreak': stats.currentStreak,
        'unlockedBadges': stats.unlockedBadges,
        'identityVotes': stats.identityVotes,
      }, SetOptions(merge: true));
      return const Right(unit);
    } catch (e, s) {
      AppLogger.e('Update user stats failed', e, s);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> addXp(String userId, int amount) async {
    try {
      final docRef = _firestore.collection('user_stats').doc(userId);

      return await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);

        int currentXp = 0;
        // int currentLevel = 1; // Unused

        if (snapshot.exists && snapshot.data() != null) {
          currentXp = snapshot.data()!['currentXp'] as int? ?? 0;
          // currentLevel = snapshot.data()!['currentLevel'] as int? ?? 1;
        }

        final newXp = currentXp + amount;
        // Simple level up logic: Level = XP / 100 + 1
        final newLevel = (newXp / 100).floor() + 1;

        transaction.set(docRef, {
          'currentXp': newXp,
          'currentLevel': newLevel,
        }, SetOptions(merge: true));

        return const Right(unit);
      });
    } catch (e, s) {
      AppLogger.e('Add XP failed', e, s);
      return Left(ServerFailure(e.toString()));
    }
  }
}
