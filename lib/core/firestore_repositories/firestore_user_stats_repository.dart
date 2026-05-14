import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/core/drift_repositories/drift_user_stats_repository.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';

/// Firestore-backed implementation of user stats operations.
///
/// Used on web platforms where Drift/SQLite is not available.
/// Reads from and writes directly to Firestore collections
/// (`user_stats` and `users`) with no local database layer.
///
/// Matches the interface of [DriftUserStatsRepository] but
/// operates without the offline-first Drift + SyncEngine pattern.
class FirestoreUserStatsRepository implements DriftUserStatsRepository {
  final FirebaseFirestore _firestore;

  FirestoreUserStatsRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  /// Recursively converts all [Timestamp] values in a map to ISO 8601
  /// strings. This is needed because [UserProfile.fromMap] expects
  /// string-based timestamps, but Firestore stores [Timestamp] objects.
  Map<String, dynamic> _convertTimestamps(Map<String, dynamic> data) {
    final result = <String, dynamic>{};
    for (final entry in data.entries) {
      final value = entry.value;
      if (value is Timestamp) {
        result[entry.key] = value.toDate().toIso8601String();
      } else if (value is Map<String, dynamic>) {
        result[entry.key] = _convertTimestamps(value);
      } else {
        result[entry.key] = value;
      }
    }
    return result;
  }

  /// Writes the full profile to `user_stats/{uid}` and a subset of
  /// identity fields to `users/{uid}`.
  @override
  Future<void> saveUserStats(UserProfile profile) async {
    // Write full profile to user_stats (using toFirestore() for proper
    // Timestamp encoding)
    await _firestore
        .collection('user_stats')
        .doc(profile.uid)
        .set(profile.toFirestore());

    // Write identity subset to users (for social/tribe features)
    await _firestore.collection('users').doc(profile.uid).set(
      {
        'archetype': profile.archetype.name,
        'level': profile.avatarStats.level,
        'streak': profile.avatarStats.streak,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      },
      SetOptions(merge: true),
    );
  }

  /// Delegates to [saveUserStats].
  @override
  Future<void> syncUserIdentity(UserProfile profile) async {
    await saveUserStats(profile);
  }

  /// Streams [UserProfile] from the `user_stats/{uid}` document.
  /// Converts [Timestamp] fields to ISO 8601 strings before
  /// deserializing via [UserProfile.fromMap].
  @override
  Stream<UserProfile> watchUserStats(String uid) {
    return _firestore
        .collection('user_stats')
        .doc(uid)
        .snapshots()
        .map((snapshot) {
      final data = snapshot.data();
      if (data == null) return UserProfile(uid: uid);
      final processed = _convertTimestamps(data);
      return UserProfile.fromMap(processed);
    });
  }

  /// Single-read accessor for `user_stats/{uid}`.
  /// Converts [Timestamp] fields to ISO 8601 strings before
  /// deserializing via [UserProfile.fromMap].
  @override
  Future<UserProfile> getUserStats(String uid) async {
    final doc = await _firestore.collection('user_stats').doc(uid).get();
    final data = doc.data();
    if (data == null) return UserProfile(uid: uid);
    final processed = _convertTimestamps(data);
    return UserProfile.fromMap(processed);
  }

  /// Updates the world entropy on the `users/{uid}` document.
  /// The [score] is a 0-100 value that is converted to an entropy
  /// ratio (1.0 - score/100).
  @override
  Future<void> updateWorldHealth(String uid, int score) async {
    final healthPercent = score / 100.0;
    await _firestore.collection('users').doc(uid).update({
      'worldState.entropy': 1.0 - healthPercent,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Updates the streak value on the `user_stats/{uid}` document.
  Future<void> updateStreak(String uid, int streak) async {
    await _firestore.collection('user_stats').doc(uid).update({
      'avatarStats.streak': streak,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // ---------------------------------------------------------------------------
  // Recap CRUD — all read from / write to `user_stats/{userId}/recaps/`
  // ---------------------------------------------------------------------------

  /// Returns the most recent recap for the given user, or null.
  @override
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

  /// Returns a single recap by its document id, or null.
  @override
  Future<Map<String, dynamic>?> getRecap(String userId, String recapId) async {
    final doc = await _firestore
        .collection('user_stats')
        .doc(userId)
        .collection('recaps')
        .doc(recapId)
        .get();
    return doc.data();
  }

  /// Returns the [limit] most recent recaps for the user.
  @override
  Future<List<Map<String, dynamic>>> getRecaps(
    String userId, {
    int limit = 10,
  }) async {
    final snapshot = await _firestore
        .collection('user_stats')
        .doc(userId)
        .collection('recaps')
        .orderBy('endDate', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  /// Persists a recap document under `user_stats/{userId}/recaps/{id}`.
  @override
  Future<void> saveRecap(
    String userId,
    Map<String, dynamic> recapData,
  ) async {
    await _firestore
        .collection('user_stats')
        .doc(userId)
        .collection('recaps')
        .doc(recapData['id'] as String)
        .set(recapData);
  }

  @override
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

  @override
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
    final nowStr = date.toIso8601String();
    final data = <String, dynamic>{
      'userId': userId,
      'date': nowStr,
      'type': type,
      'createdAt': nowStr,
    };
    if (habitId != null) data['habitId'] = habitId;
    if (sourceId != null) data['sourceId'] = sourceId;
    if (difficulty != null) data['difficulty'] = difficulty;
    if (attribute != null) data['attribute'] = attribute;
    if (streakDay != null) data['streakDay'] = streakDay;

    final docId = '${userId}_${type}_${date.millisecondsSinceEpoch}';
    await _firestore
        .collection('user_activity')
        .doc(docId)
        .set(data);
  }
}
