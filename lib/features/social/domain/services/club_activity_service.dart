import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Service for logging user activities to their archetype club's activity feed.
///
/// This is the foundation for real-time club activity, using frontend-driven
/// Firestore updates without requiring Cloud Functions.
class ClubActivityService {
  final FirebaseFirestore _firestore;

  ClubActivityService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Gets the club ID for a given archetype.
  ///
  /// Club IDs follow the pattern `{archetypeId}_club`.
  String getClubIdForArchetype(String archetype) {
    return '${archetype}_club';
  }

  /// Logs a habit completion to the user's archetype club's activity feed
  /// and updates the contributor stats.
  ///
  /// This method handles errors gracefully - if logging fails, it won't
  /// break the main habit completion operation.
  Future<void> logHabitCompletion({
    required String userId,
    required String userName,
    required String archetype,
    required String habitId,
    required String habitTitle,
    required int xpGained,
  }) async {
    try {
      final clubId = getClubIdForArchetype(archetype);

      await _firestore.runTransaction((transaction) async {
        final clubRef = _firestore.collection('tribes').doc(clubId);

        // Create activity document
        final activityRef = clubRef.collection('activity').doc();
        transaction.set(activityRef, {
          'type': 'habit_complete',
          'userId': userId,
          'userName': userName,
          'timestamp': FieldValue.serverTimestamp(),
          'habitId': habitId,
          'habitTitle': habitTitle,
          'xpGained': xpGained,
        });

        // Update contributor stats with merge
        final contributorRef = clubRef.collection('contributors').doc(userId);
        transaction.set(
          contributorRef,
          {
            'userId': userId,
            'userName': userName,
            'lastActivity': FieldValue.serverTimestamp(),
            'contributionCount': FieldValue.increment(1),
            'archetype': archetype,
          },
          SetOptions(merge: true),
        );
      });
    } catch (e) {
      // Handle errors gracefully - don't let activity logging fail break the main operation
      debugPrint('Error logging habit completion to club activity: $e');
    }
  }

  /// Logs a level up to the user's archetype club's activity feed.
  ///
  /// This method handles errors gracefully - if logging fails, it won't
  /// break the main level up operation.
  Future<void> logLevelUp({
    required String userId,
    required String userName,
    required String archetype,
    required int newLevel,
  }) async {
    try {
      final clubId = getClubIdForArchetype(archetype);

      await _firestore.runTransaction((transaction) async {
        final clubRef = _firestore.collection('tribes').doc(clubId);
        final activityRef = clubRef.collection('activity').doc();

        transaction.set(activityRef, {
          'type': 'level_up',
          'userId': userId,
          'userName': userName,
          'timestamp': FieldValue.serverTimestamp(),
          'newLevel': newLevel,
        });
      });
    } catch (e) {
      // Handle errors gracefully - don't let activity logging fail break the main operation
      debugPrint('Error logging level up to club activity: $e');
    }
  }

  /// Logs a challenge completion to the user's archetype club's activity feed.
  ///
  /// This method handles errors gracefully - if logging fails, it won't
  /// break the main challenge completion operation.
  Future<void> logChallengeComplete({
    required String userId,
    required String userName,
    required String archetype,
    required String challengeId,
    required String challengeTitle,
  }) async {
    try {
      final clubId = getClubIdForArchetype(archetype);

      await _firestore.runTransaction((transaction) async {
        final clubRef = _firestore.collection('tribes').doc(clubId);
        final activityRef = clubRef.collection('activity').doc();

        transaction.set(activityRef, {
          'type': 'challenge_complete',
          'userId': userId,
          'userName': userName,
          'timestamp': FieldValue.serverTimestamp(),
          'challengeId': challengeId,
          'challengeTitle': challengeTitle,
        });
      });
    } catch (e) {
      // Handle errors gracefully - don't let activity logging fail break the main operation
      debugPrint('Error logging challenge completion to club activity: $e');
    }
  }
}
