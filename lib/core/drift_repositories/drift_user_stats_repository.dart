import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/core/drift/database.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';

class DriftUserStatsRepository {
  final AppDatabase _db;
  final FirebaseFirestore _firestore;

  DriftUserStatsRepository(this._db) : _firestore = FirebaseFirestore.instance;

  Future<void> saveUserStats(UserProfile profile) async {
    await _db.userStatsDao.upsertFromFirebase(profile.uid, {
      'totalXp': profile.avatarStats.totalXp,
      'level': profile.avatarStats.level,
      'streak': profile.avatarStats.streak,
      'strengthXp': profile.avatarStats.strengthXp,
      'intellectXp': profile.avatarStats.intellectXp,
      'vitalityXp': profile.avatarStats.vitalityXp,
      'creativityXp': profile.avatarStats.creativityXp,
      'focusXp': profile.avatarStats.focusXp,
      'spiritXp': profile.avatarStats.spiritXp,
      'challengeXp': profile.avatarStats.challengeXp,
      'worldHealthScore': profile.worldState.worldHealth,
      'archetype': profile.archetype.name,
      'updatedAt': DateTime.now().toIso8601String(),
      'avatarJson': profile.avatarStats.toMap().toString(),
      'worldStateJson': profile.worldState.toMap().toString(),
      'onboardingProgress': profile.onboardingProgress,
      'onboardingCompletedAt': profile.onboardingCompletedAt?.toIso8601String(),
    });
  }

  Future<void> updateWorldHealth(String uid, int score) async {
    await _db.userStatsDao.updateWorldHealth(uid, score / 100.0);
  }

  Future<void> syncUserIdentity(UserProfile profile) async {
    await saveUserStats(profile);
  }

  Stream<UserProfile> watchUserStats(String uid) {
    return _db.userStatsDao.watchStats(uid).map((row) {
      if (row == null) return UserProfile(uid: uid);
      return _rowToProfile(row);
    });
  }

  Future<UserProfile> getUserStats(String uid) async {
    final row = await _db.userStatsDao.getStats(uid);
    if (row == null) return UserProfile(uid: uid);
    return _rowToProfile(row);
  }

  Future<Map<String, dynamic>?> getLatestRecap(String userId) async {
    final snapshot = await _firestore
        .collection('user_stats')
        .doc(userId)
        .collection('recaps')
        .orderBy('endDate', descending: true)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return snapshot.docs.first.data();
  }

  Future<Map<String, dynamic>?> getRecap(String userId, String recapId) async {
    final doc = await _firestore
        .collection('user_stats')
        .doc(userId)
        .collection('recaps')
        .doc(recapId)
        .get();
    return doc.data();
  }

  Future<List<Map<String, dynamic>>> getRecaps(String userId, {int limit = 10}) async {
    final snapshot = await _firestore
        .collection('user_stats')
        .doc(userId)
        .collection('recaps')
        .orderBy('endDate', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<void> saveRecap(String userId, Map<String, dynamic> recapData) async {
    await _firestore
        .collection('user_stats')
        .doc(userId)
        .collection('recaps')
        .doc(recapData['id'] as String)
        .set(recapData);
  }

  Future<List<Map<String, dynamic>>> getWeeklyActivity(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    final snapshot = await _firestore
        .collection('user_activity')
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<void> logActivity({
    required String userId,
    required String type,
    String? habitId,
    String? sourceId,
    required DateTime date,
    String? difficulty,
    String? attribute,
    int? streakDay,
  }) async {
    final data = <String, dynamic>{
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'type': type,
      'createdAt': FieldValue.serverTimestamp(),
    };
    if (habitId != null) data['habitId'] = habitId;
    if (sourceId != null) data['sourceId'] = sourceId;
    if (difficulty != null) data['difficulty'] = difficulty;
    if (attribute != null) data['attribute'] = attribute;
    if (streakDay != null) data['streakDay'] = streakDay;
    await _firestore.collection('user_activity').add(data);
  }

  UserProfile _rowToProfile(UserStatsTableData row) {
    return UserProfile(
      uid: row.userId,
      archetype: UserArchetype.values.firstWhere(
        (e) => e.name == (row.archetype ?? 'none'),
        orElse: () => UserArchetype.none,
      ),
      avatarStats: UserAvatarStats(
        strengthXp: row.strengthXp,
        intellectXp: row.intellectXp,
        vitalityXp: row.vitalityXp,
        creativityXp: row.creativityXp,
        focusXp: row.focusXp,
        spiritXp: row.spiritXp,
        challengeXp: row.challengeXp,
        level: row.level,
        streak: row.streak,
      ),
      worldState: UserWorldState(
        entropy: 1.0 - row.worldHealthScore,
      ),
      onboardingProgress: row.onboardingProgress,
      onboardingCompletedAt: row.onboardingCompletedAt != null
          ? DateTime.tryParse(row.onboardingCompletedAt!)
          : null,
    );
  }
}
