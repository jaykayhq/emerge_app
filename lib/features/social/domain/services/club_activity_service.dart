import 'package:emerge_app/core/drift/database.dart';
import 'package:emerge_app/core/drift/daos/tribe_activity_dao.dart';
import 'package:emerge_app/core/sync/sync_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';

import 'package:emerge_app/features/social/domain/repositories/leaderboard_repository.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';

/// Service for logging user activities to both their archetype club and a global activity feed.
///
/// This has been refactored for the Offline-First Architecture. All writes are now queued
/// through the [EnhancedSyncEngine], avoiding direct `FirebaseFirestore` transactions.
class SocialActivityService {
  final EnhancedSyncEngine _syncEngine;
  final TribeActivityDao _activityDao;
  final LeaderboardRepository _leaderboardRepo;

  // Firestore collection and document path constants
  static const String _kTribesCollection = 'tribes';
  static const String _kActivityCollection = 'activity';
  static const String _kGlobalActivitiesCollection = 'global_activities';

  // Activity type constants
  static const String _kActivityTypeHabitComplete = 'habit_complete';
  static const String _kActivityTypeLevelUp = 'level_up';
  static const String _kActivityTypeChallengeComplete = 'challenge_complete';
  static const String _kActivityTypeStreakMilestone = 'streak_milestone';
  static const String _kActivityTypeNodeClaim = 'node_claim';
  static const String _kActivityTypeBadgeEarned = 'badge_earned';
  static const String _kActivityTypePartnerJoined = 'partner_joined';
  static const String _kActivityTypeContractCommitted = 'contract_committed';

  SocialActivityService({
    required EnhancedSyncEngine syncEngine,
    required TribeActivityDao activityDao,
    required LeaderboardRepository leaderboardRepo,
  }) : _syncEngine = syncEngine,
       _activityDao = activityDao,
       _leaderboardRepo = leaderboardRepo;

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
      final nowStr = DateTime.now().toUtc().toIso8601String();

      // 1. Write to local Drift database (TribeActivityTable)
      await _activityDao.insertActivity(
        TribeActivityTableCompanion(
          id: Value(id),
          userId: Value(userId),
          userName: Value(userName),
          tribeId: Value(clubId),
          type: Value(_kActivityTypeHabitComplete),
          description: Value('Completed habit: $habitTitle'),
          value: Value(xpGained ?? 0),
          timestamp: Value(nowStr),
        ),
      );

      // 2. Write to Global Activity Firestore
      await _syncEngine.enqueueSet(
        collectionPath: _kGlobalActivitiesCollection,
        documentId: id,
        data: {
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
          'timestamp': nowStr,
        },
      );

      // 3. Write to Club Activity Firestore
      await _syncEngine.enqueueSet(
        collectionPath: '$_kTribesCollection/$clubId/$_kActivityCollection',
        documentId: id,
        data: {
          'type': _kActivityTypeHabitComplete,
          'userId': userId,
          'userName': userName,
          'data': {
            'habitId': habitId,
            'habitTitle': habitTitle,
            'streakDay': streakDay,
            'attribute': attribute,
          },
          'timestamp': nowStr,
        },
      );

      // 4. Update Leaderboard via Repository
      if (xpGained != null || currentLevel != null) {
        final clubId = _getClubIdForArchetype(archetype);
        await _leaderboardRepo.updateUserScore(
          userId,
          xp: xpGained ?? 0,
          level: currentLevel ?? 1,
          archetype: UserArchetype.values.firstWhere(
            (e) => e.name.toLowerCase() == archetype.toLowerCase(),
            orElse: () => UserArchetype.none,
          ),
          userName: userName,
          clubId: clubId,
          isIncrement: true,
        );
      }

      // Note: Tribe Aggregate Counters, Contributor Stats, Leaderboard, and User Stats
      // are handled by DriftHabitRepository.completeHabit in the offline-first flow.
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
      final nowStr = DateTime.now().toUtc().toIso8601String();

      // 1. Write to local Drift
      await _activityDao.insertActivity(
        TribeActivityTableCompanion(
          id: Value(id),
          userId: Value(userId),
          userName: Value(userName),
          tribeId: Value(clubId),
          type: Value(_kActivityTypeLevelUp),
          description: Value('Leveled up to Level $newLevel!'),
          value: Value(totalXp),
          timestamp: Value(nowStr),
        ),
      );

      // 2. Global Firestore
      await _syncEngine.enqueueSet(
        collectionPath: _kGlobalActivitiesCollection,
        documentId: id,
        data: {
          'type': _kActivityTypeLevelUp,
          'userId': userId,
          'userName': userName,
          'archetypeId': archetype,
          'clubId': clubId,
          'data': {'newLevel': newLevel, 'totalXp': totalXp},
          'timestamp': nowStr,
        },
      );

      // 3. Club Firestore
      await _syncEngine.enqueueSet(
        collectionPath: '$_kTribesCollection/$clubId/$_kActivityCollection',
        documentId: id,
        data: {
          'type': _kActivityTypeLevelUp,
          'userId': userId,
          'userName': userName,
          'data': {'newLevel': newLevel},
          'timestamp': nowStr,
        },
      );

      // 4. Update Leaderboard
      await _leaderboardRepo.updateUserScore(
        userId,
        xp: totalXp,
        level: newLevel,
        archetype: UserArchetype.values.firstWhere(
          (e) => e.name.toLowerCase() == archetype.toLowerCase(),
          orElse: () => UserArchetype.none,
        ),
        userName: userName,
        clubId: clubId,
        isIncrement: false, // Level up sets absolute values
      );
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
      final nowStr = DateTime.now().toUtc().toIso8601String();

      // 1. Write to local Drift
      await _activityDao.insertActivity(
        TribeActivityTableCompanion(
          id: Value(id),
          userId: Value(userId),
          userName: Value(userName),
          tribeId: Value(clubId),
          type: Value(_kActivityTypeChallengeComplete),
          description: Value('Completed challenge: $challengeTitle'),
          value: Value(xpReward),
          timestamp: Value(nowStr),
        ),
      );

      // 2. Global Firestore
      await _syncEngine.enqueueSet(
        collectionPath: _kGlobalActivitiesCollection,
        documentId: id,
        data: {
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
          'timestamp': nowStr,
        },
      );

      // 3. Club Firestore
      await _syncEngine.enqueueSet(
        collectionPath: '$_kTribesCollection/$clubId/$_kActivityCollection',
        documentId: id,
        data: {
          'type': _kActivityTypeChallengeComplete,
          'userId': userId,
          'userName': userName,
          'data': {
            'challengeId': challengeId,
            'challengeTitle': challengeTitle,
          },
          'timestamp': nowStr,
        },
      );

      // 4. Update Leaderboard via Repository
      await _leaderboardRepo.updateUserScore(
        userId,
        xp: xpReward,
        level: 1, // XP only update, level handled by user stats
        archetype: UserArchetype.values.firstWhere(
          (e) => e.name.toLowerCase() == archetype.toLowerCase(),
          orElse: () => UserArchetype.none,
        ),
        userName: userName,
        clubId: clubId,
        isIncrement: true,
      );
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
      final nowStr = DateTime.now().toUtc().toIso8601String();

      // Global
      await _syncEngine.enqueueSet(
        collectionPath: _kGlobalActivitiesCollection,
        documentId: id,
        data: {
          'type': _kActivityTypeStreakMilestone,
          'userId': userId,
          'userName': userName,
          'archetypeId': archetype,
          'clubId': clubId,
          'data': {'streakDays': streakDays},
          'timestamp': nowStr,
        },
      );

      // Club
      await _syncEngine.enqueueSet(
        collectionPath: '$_kTribesCollection/$clubId/$_kActivityCollection',
        documentId: id,
        data: {
          'type': _kActivityTypeStreakMilestone,
          'userId': userId,
          'userName': userName,
          'data': {'streakDays': streakDays},
          'timestamp': nowStr,
        },
      );
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
      final nowStr = DateTime.now().toUtc().toIso8601String();

      // Global
      await _syncEngine.enqueueSet(
        collectionPath: _kGlobalActivitiesCollection,
        documentId: id,
        data: {
          'type': _kActivityTypeNodeClaim,
          'userId': userId,
          'userName': userName,
          'archetypeId': archetype,
          'clubId': clubId,
          'data': {'nodeId': nodeId, 'nodeName': nodeName},
          'timestamp': nowStr,
        },
      );

      // Club
      await _syncEngine.enqueueSet(
        collectionPath: '$_kTribesCollection/$clubId/$_kActivityCollection',
        documentId: id,
        data: {
          'type': _kActivityTypeNodeClaim,
          'userId': userId,
          'userName': userName,
          'data': {'nodeId': nodeId, 'nodeName': nodeName},
          'timestamp': nowStr,
        },
      );
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
      final nowStr = DateTime.now().toUtc().toIso8601String();

      // Global
      await _syncEngine.enqueueSet(
        collectionPath: _kGlobalActivitiesCollection,
        documentId: id,
        data: {
          'type': _kActivityTypeBadgeEarned,
          'userId': userId,
          'userName': userName,
          'archetypeId': archetype,
          'clubId': clubId,
          'data': {'badgeId': badgeId, 'badgeName': badgeName},
          'timestamp': nowStr,
        },
      );

      // Club
      await _syncEngine.enqueueSet(
        collectionPath: '$_kTribesCollection/$clubId/$_kActivityCollection',
        documentId: id,
        data: {
          'type': _kActivityTypeBadgeEarned,
          'userId': userId,
          'userName': userName,
          'data': {'badgeId': badgeId, 'badgeName': badgeName},
          'timestamp': nowStr,
        },
      );
    } catch (e) {
      debugPrint('Error logging badge earned to social activity: $e');
    }
  }

  /// Logs when a new accountability partner relationship is formed.
  Future<void> logPartnerJoined({
    required String userId,
    required String userName,
    required String archetype,
    required String partnerName,
  }) async {
    try {
      final clubId = _getClubIdForArchetype(archetype);
      final id = '${userId}_partner_${DateTime.now().millisecondsSinceEpoch}';
      final nowStr = DateTime.now().toUtc().toIso8601String();

      await _syncEngine.enqueueSet(
        collectionPath: _kGlobalActivitiesCollection,
        documentId: id,
        data: {
          'type': _kActivityTypePartnerJoined,
          'userId': userId,
          'userName': userName,
          'archetypeId': archetype,
          'clubId': clubId,
          'data': {'partnerName': partnerName},
          'timestamp': nowStr,
        },
      );

      await _syncEngine.enqueueSet(
        collectionPath: '$_kTribesCollection/$clubId/$_kActivityCollection',
        documentId: id,
        data: {
          'type': _kActivityTypePartnerJoined,
          'userId': userId,
          'userName': userName,
          'data': {'partnerName': partnerName},
          'timestamp': nowStr,
        },
      );
    } catch (e) {
      debugPrint('Error logging partner joined: $e');
    }
  }

  /// Logs when a user commits to a high-stakes habit contract.
  Future<void> logContractCommitted({
    required String userId,
    required String userName,
    required String archetype,
    required String habitTitle,
    required String penalty,
  }) async {
    try {
      final clubId = _getClubIdForArchetype(archetype);
      final id = '${userId}_contract_${DateTime.now().millisecondsSinceEpoch}';
      final nowStr = DateTime.now().toUtc().toIso8601String();

      await _syncEngine.enqueueSet(
        collectionPath: _kGlobalActivitiesCollection,
        documentId: id,
        data: {
          'type': _kActivityTypeContractCommitted,
          'userId': userId,
          'userName': userName,
          'archetypeId': archetype,
          'clubId': clubId,
          'data': {'habitTitle': habitTitle, 'penalty': penalty},
          'timestamp': nowStr,
        },
      );

      await _syncEngine.enqueueSet(
        collectionPath: '$_kTribesCollection/$clubId/$_kActivityCollection',
        documentId: id,
        data: {
          'type': _kActivityTypeContractCommitted,
          'userId': userId,
          'userName': userName,
          'data': {'habitTitle': habitTitle, 'penalty': penalty},
          'timestamp': nowStr,
        },
      );
    } catch (e) {
      debugPrint('Error logging contract committed: $e');
    }
  }
}
