import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Service for logging user activities to both their archetype club and a global activity feed.
///
/// This is the foundation for real-time social interaction, using frontend-driven
/// Firestore updates without requiring Cloud Functions.
class SocialActivityService {
  final FirebaseFirestore _firestore;

  // Firestore collection and document path constants
  static const String _kTribesCollection = 'tribes';
  static const String _kActivityCollection = 'activity';
  static const String _kContributorsCollection = 'contributors';
  static const String _kGlobalActivitiesCollection = 'global_activities';

  // Activity type constants
  static const String _kActivityTypeHabitComplete = 'habit_complete';
  static const String _kActivityTypeLevelUp = 'level_up';
  static const String _kActivityTypeChallengeComplete = 'challenge_complete';
  static const String _kActivityTypeStreakMilestone = 'streak_milestone';
  static const String _kActivityTypeNodeClaim = 'node_claim';
  static const String _kActivityTypeBadgeEarned = 'badge_earned';

  SocialActivityService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Gets the official club ID for a given archetype.
  String _getClubIdForArchetype(String archetype) {
    switch (archetype.toLowerCase()) {
      case 'athlete':
        return 'morning_warriors';
      case 'scholar':
        return 'deep_work_society';
      case 'stoic':
        return 'mindful_masters';
      case 'creator':
        return 'creative_collective';
      case 'zealot':
      case 'mystic':
        return 'lunar_seekers';
      default:
        return '${archetype}_club';
    }
  }

  /// Logs a habit completion to both the club activity feed and the global activity feed.
  Future<void> logHabitCompletion({
    required String userId,
    required String userName,
    required String archetype,
    required String habitId,
    required String habitTitle,
    required int streakDay,
    required String attribute,
    int? xpGained,
    int? currentLevel,
  }) async {
    try {
      final clubId = _getClubIdForArchetype(archetype);
      final id =
          '${userId}_${habitId}_${DateTime.now().millisecondsSinceEpoch}';

      await _firestore.runTransaction((transaction) async {
        // 1. Write to Global Activity
        final globalRef = _firestore
            .collection(_kGlobalActivitiesCollection)
            .doc(id);
        transaction.set(globalRef, {
          'type': _kActivityTypeHabitComplete,
          'userId': userId,
          'userName': userName,
          'archetypeId': archetype,
          'clubId': clubId,
          'data': {
            'habitId': habitId,
            'habitTitle': habitTitle,
            'streakDay': streakDay,
            'attribute': attribute,
          },
          'timestamp': FieldValue.serverTimestamp(),
        });

        // 2. Write to Club Activity
        final clubActivityRef = _firestore
            .collection(_kTribesCollection)
            .doc(clubId)
            .collection(_kActivityCollection)
            .doc(id);
        transaction.set(clubActivityRef, {
          'type': _kActivityTypeHabitComplete,
          'userId': userId,
          'userName': userName,
          'data': {
            'habitId': habitId,
            'habitTitle': habitTitle,
            'streakDay': streakDay,
            'attribute': attribute,
          },
          'timestamp': FieldValue.serverTimestamp(),
        });

        // 3. Update Club Contributor Stats
        final contributorRef = _firestore
            .collection(_kTribesCollection)
            .doc(clubId)
            .collection(_kContributorsCollection)
            .doc(userId);
        transaction.set(contributorRef, {
          'userId': userId,
          'userName': userName,
          'lastActivity': FieldValue.serverTimestamp(),
          'contributionCount': FieldValue.increment(1),
          'archetype': archetype,
        }, SetOptions(merge: true));

        // 3b. Update Tribe Aggregate Counters
        final tribeRef = _firestore.collection(_kTribesCollection).doc(clubId);
        transaction.set(tribeRef, {
          'totalHabitsCompleted': FieldValue.increment(1),
        }, SetOptions(merge: true));

        // 4. Update Club Leaderboard Entry
        if (xpGained != null) {
          final leaderboardRef = _firestore
              .collection('club_leaderboards')
              .doc('${userId}_$clubId');
          transaction.set(leaderboardRef, {
            'userId': userId,
            'userName': userName,
            'clubId': clubId,
            'xp': FieldValue.increment(xpGained),
            'level': currentLevel,
            'archetype': archetype,
            'lastUpdated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          // 5. Update Core User Stats XP (if available)
          final userStatsRef = _firestore.collection('user_stats').doc(userId);
          transaction.set(userStatsRef, {
            'totalXp': FieldValue.increment(xpGained),
            // We increment specific attribute XP just as a fallback
            '${attribute}Xp': FieldValue.increment(xpGained),
          }, SetOptions(merge: true));
        }
      });
    } catch (e) {
      debugPrint('Error logging habit completion to social activity: $e');
    }
  }

  /// Logs a level up to social activity feeds.
  Future<void> logLevelUp({
    required String userId,
    required String userName,
    required String archetype,
    required int newLevel,
    required int totalXp,
  }) async {
    try {
      final clubId = _getClubIdForArchetype(archetype);
      final id = '${userId}_level_${DateTime.now().millisecondsSinceEpoch}';

      await _firestore.runTransaction((transaction) async {
        // Global
        final globalRef = _firestore
            .collection(_kGlobalActivitiesCollection)
            .doc(id);
        transaction.set(globalRef, {
          'type': _kActivityTypeLevelUp,
          'userId': userId,
          'userName': userName,
          'archetypeId': archetype,
          'clubId': clubId,
          'data': {'newLevel': newLevel, 'totalXp': totalXp},
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Club
        final clubActivityRef = _firestore
            .collection(_kTribesCollection)
            .doc(clubId)
            .collection(_kActivityCollection)
            .doc(id);
        transaction.set(clubActivityRef, {
          'type': _kActivityTypeLevelUp,
          'userId': userId,
          'userName': userName,
          'data': {'newLevel': newLevel},
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Update Leaderboard Level
        final leaderboardRef = _firestore
            .collection('club_leaderboards')
            .doc('${userId}_$clubId');
        transaction.set(leaderboardRef, {
          'userId': userId,
          'userName': userName,
          'clubId': clubId,
          'level': newLevel,
          'xp': totalXp,
          'archetype': archetype,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });
    } catch (e) {
      debugPrint('Error logging level up to social activity: $e');
    }
  }

  /// Logs a challenge completion to social activity feeds.
  Future<void> logChallengeComplete({
    required String userId,
    required String userName,
    required String archetype,
    required String challengeId,
    required String challengeTitle,
    required int xpReward,
  }) async {
    try {
      final clubId = _getClubIdForArchetype(archetype);
      final id =
          '${userId}_challenge_${challengeId}_${DateTime.now().millisecondsSinceEpoch}';

      await _firestore.runTransaction((transaction) async {
        // Global
        final globalRef = _firestore
            .collection(_kGlobalActivitiesCollection)
            .doc(id);
        transaction.set(globalRef, {
          'type': _kActivityTypeChallengeComplete,
          'userId': userId,
          'userName': userName,
          'archetypeId': archetype,
          'clubId': clubId,
          'data': {
            'challengeId': challengeId,
            'challengeTitle': challengeTitle,
            'xpReward': xpReward,
          },
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Club
        final clubActivityRef = _firestore
            .collection(_kTribesCollection)
            .doc(clubId)
            .collection(_kActivityCollection)
            .doc(id);
        transaction.set(clubActivityRef, {
          'type': _kActivityTypeChallengeComplete,
          'userId': userId,
          'userName': userName,
          'data': {
            'challengeId': challengeId,
            'challengeTitle': challengeTitle,
          },
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Update Leaderboard XP
        final leaderboardRef = _firestore
            .collection('club_leaderboards')
            .doc('${userId}_$clubId');
        transaction.set(leaderboardRef, {
          'userId': userId,
          'userName': userName,
          'clubId': clubId,
          'xp': FieldValue.increment(xpReward),
          'archetype': archetype,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Update Core User Stats XP
        final userStatsRef = _firestore.collection('user_stats').doc(userId);
        transaction.set(userStatsRef, {
          'totalXp': FieldValue.increment(xpReward),
        }, SetOptions(merge: true));

        // Update Tribe Aggregate Counters
        final tribeRef = _firestore.collection(_kTribesCollection).doc(clubId);
        transaction.set(tribeRef, {
          'totalChallengesCompleted': FieldValue.increment(1),
        }, SetOptions(merge: true));
      });
    } catch (e) {
      debugPrint('Error logging challenge completion to social activity: $e');
    }
  }

  /// Logs a streak milestone to social activity feeds.
  Future<void> logStreakMilestone({
    required String userId,
    required String userName,
    required String archetype,
    required int streakDays,
  }) async {
    try {
      final clubId = _getClubIdForArchetype(archetype);
      final id =
          '${userId}_streak_${streakDays}_${DateTime.now().millisecondsSinceEpoch}';

      await _firestore.runTransaction((transaction) async {
        // Global
        final globalRef = _firestore
            .collection(_kGlobalActivitiesCollection)
            .doc(id);
        transaction.set(globalRef, {
          'type': _kActivityTypeStreakMilestone,
          'userId': userId,
          'userName': userName,
          'archetypeId': archetype,
          'clubId': clubId,
          'data': {'streakDays': streakDays},
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Club
        final clubActivityRef = _firestore
            .collection(_kTribesCollection)
            .doc(clubId)
            .collection(_kActivityCollection)
            .doc(id);
        transaction.set(clubActivityRef, {
          'type': _kActivityTypeStreakMilestone,
          'userId': userId,
          'userName': userName,
          'data': {'streakDays': streakDays},
          'timestamp': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      debugPrint('Error logging streak milestone to social activity: $e');
    }
  }

  /// Logs a node claim to social activity feeds.
  Future<void> logNodeClaim({
    required String userId,
    required String userName,
    required String archetype,
    required String nodeId,
    required String nodeName,
  }) async {
    try {
      final clubId = _getClubIdForArchetype(archetype);
      final id =
          '${userId}_node_${nodeId}_${DateTime.now().millisecondsSinceEpoch}';

      await _firestore.runTransaction((transaction) async {
        // Global
        final globalRef = _firestore
            .collection(_kGlobalActivitiesCollection)
            .doc(id);
        transaction.set(globalRef, {
          'type': _kActivityTypeNodeClaim,
          'userId': userId,
          'userName': userName,
          'archetypeId': archetype,
          'clubId': clubId,
          'data': {'nodeId': nodeId, 'nodeName': nodeName},
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Club
        final clubActivityRef = _firestore
            .collection(_kTribesCollection)
            .doc(clubId)
            .collection(_kActivityCollection)
            .doc(id);
        transaction.set(clubActivityRef, {
          'type': _kActivityTypeNodeClaim,
          'userId': userId,
          'userName': userName,
          'data': {'nodeId': nodeId, 'nodeName': nodeName},
          'timestamp': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      debugPrint('Error logging node claim: $e');
    }
  }

  /// Logs a badge/reward earning to social activity feeds.
  Future<void> logBadgeEarned({
    required String userId,
    required String userName,
    required String archetype,
    required String badgeId,
    required String badgeName,
  }) async {
    try {
      final clubId = _getClubIdForArchetype(archetype);
      final id =
          '${userId}_badge_${badgeId}_${DateTime.now().millisecondsSinceEpoch}';

      await _firestore.runTransaction((transaction) async {
        // Global
        final globalRef = _firestore
            .collection(_kGlobalActivitiesCollection)
            .doc(id);
        transaction.set(globalRef, {
          'type': _kActivityTypeBadgeEarned,
          'userId': userId,
          'userName': userName,
          'archetypeId': archetype,
          'clubId': clubId,
          'data': {'badgeId': badgeId, 'badgeName': badgeName},
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Club
        final clubActivityRef = _firestore
            .collection(_kTribesCollection)
            .doc(clubId)
            .collection(_kActivityCollection)
            .doc(id);
        transaction.set(clubActivityRef, {
          'type': _kActivityTypeBadgeEarned,
          'userId': userId,
          'userName': userName,
          'data': {'badgeId': badgeId, 'badgeName': badgeName},
          'timestamp': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      debugPrint('Error logging badge earned to social activity: $e');
    }
  }
}
