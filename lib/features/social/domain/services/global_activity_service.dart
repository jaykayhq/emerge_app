import 'package:cloud_firestore/cloud_firestore.dart';
import '../entities/activity.dart';

class GlobalActivityService {
  final FirebaseFirestore _firestore;

  GlobalActivityService(this._firestore);

  String _getClubId(String archetypeId) {
    return '${archetypeId}_club';
  }

  Future<void> _logActivity(Activity activity) async {
    await _firestore.runTransaction((transaction) async {
      // Write to global activities collection
      final globalRef = _firestore
          .collection('global_activities')
          .doc(activity.id);

      transaction.set(globalRef, activity.toMap());

      // Write to club-specific activity collection if clubId exists
      if (activity.clubId != null) {
        final clubRef = _firestore
            .collection('clubs')
            .doc(activity.clubId)
            .collection('activities')
            .doc(activity.id);

        transaction.set(clubRef, activity.toMap());
      }
    });
  }

  Future<void> logHabitComplete({
    required String userId,
    required String userName,
    required String archetypeId,
    required String habitId,
    required String habitTitle,
    required int streakDay,
    required String attribute,
  }) async {
    final activity = Activity(
      id: '${userId}_${habitId}_${DateTime.now().millisecondsSinceEpoch}',
      type: ActivityType.habitComplete,
      userId: userId,
      userName: userName,
      archetypeId: archetypeId,
      clubId: _getClubId(archetypeId),
      data: {
        'habitId': habitId,
        'habitTitle': habitTitle,
        'streakDay': streakDay,
        'attribute': attribute,
      },
      timestamp: DateTime.now(),
    );

    await _logActivity(activity);
  }

  Future<void> logLevelUp({
    required String userId,
    required String userName,
    required String archetypeId,
    required int newLevel,
    required int totalXp,
  }) async {
    final activity = Activity(
      id: '${userId}_level_${DateTime.now().millisecondsSinceEpoch}',
      type: ActivityType.levelUp,
      userId: userId,
      userName: userName,
      archetypeId: archetypeId,
      clubId: _getClubId(archetypeId),
      data: {
        'newLevel': newLevel,
        'totalXp': totalXp,
      },
      timestamp: DateTime.now(),
    );

    await _logActivity(activity);
  }

  Future<void> logChallengeComplete({
    required String userId,
    required String userName,
    required String archetypeId,
    required String challengeId,
    required String challengeTitle,
    required int xpReward,
  }) async {
    final activity = Activity(
      id: '${userId}_challenge_complete_${challengeId}_${DateTime.now().millisecondsSinceEpoch}',
      type: ActivityType.challengeComplete,
      userId: userId,
      userName: userName,
      archetypeId: archetypeId,
      clubId: _getClubId(archetypeId),
      data: {
        'challengeId': challengeId,
        'challengeTitle': challengeTitle,
        'xpReward': xpReward,
      },
      timestamp: DateTime.now(),
    );

    await _logActivity(activity);
  }

  Future<void> logChallengeJoin({
    required String userId,
    required String userName,
    required String archetypeId,
    required String challengeId,
    required String challengeTitle,
  }) async {
    final activity = Activity(
      id: '${userId}_challenge_join_${challengeId}_${DateTime.now().millisecondsSinceEpoch}',
      type: ActivityType.challengeJoin,
      userId: userId,
      userName: userName,
      archetypeId: archetypeId,
      clubId: _getClubId(archetypeId),
      data: {
        'challengeId': challengeId,
        'challengeTitle': challengeTitle,
      },
      timestamp: DateTime.now(),
    );

    await _logActivity(activity);
  }

  Future<void> logStreakMilestone({
    required String userId,
    required String userName,
    required String archetypeId,
    required int streakCount,
  }) async {
    final activity = Activity(
      id: '${userId}_streak_${streakCount}_${DateTime.now().millisecondsSinceEpoch}',
      type: ActivityType.streakMilestone,
      userId: userId,
      userName: userName,
      archetypeId: archetypeId,
      clubId: _getClubId(archetypeId),
      data: {
        'streakCount': streakCount,
      },
      timestamp: DateTime.now(),
    );

    await _logActivity(activity);
  }

  Future<void> logNodeClaim({
    required String userId,
    required String userName,
    required String archetypeId,
    required String nodeId,
    required String nodeTitle,
    required String biome,
  }) async {
    final activity = Activity(
      id: '${userId}_node_${nodeId}_${DateTime.now().millisecondsSinceEpoch}',
      type: ActivityType.nodeClaim,
      userId: userId,
      userName: userName,
      archetypeId: archetypeId,
      clubId: _getClubId(archetypeId),
      data: {
        'nodeId': nodeId,
        'nodeTitle': nodeTitle,
        'biome': biome,
      },
      timestamp: DateTime.now(),
    );

    await _logActivity(activity);
  }

  Stream<List<Activity>> getGlobalActivityFeed({
    int limit = 50,
  }) {
    return _firestore
        .collection('global_activities')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Activity.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<Activity>> getClubActivityFeed(
    String clubId, {
    int limit = 50,
  }) {
    return _firestore
        .collection('clubs')
        .doc(clubId)
        .collection('activities')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Activity.fromMap(doc.data(), doc.id))
            .toList());
  }
}
