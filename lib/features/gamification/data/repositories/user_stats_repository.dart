import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';

import 'package:emerge_app/core/services/local_cache_service.dart';
import 'package:emerge_app/features/gamification/data/repositories/cache_aware_user_stats_repository.dart';

final userStatsRepositoryProvider = Provider<UserStatsRepository>((ref) {
  final remoteRepository = UserStatsRepository(FirebaseFirestore.instance);
  try {
    // localCacheServiceProvider throws AssertionError if Hive hasn't
    // initialized yet. Fall back gracefully to the remote-only repository
    // so the rest of the provider graph never sees an exception here.
    final cacheService = ref.watch(localCacheServiceProvider);
    return CacheAwareUserStatsRepository(remoteRepository, cacheService);
  } catch (_) {
    // Cache not ready — return remote-only repository without crashing.
    return remoteRepository;
  }
});


class UserStatsRepository {
  final FirebaseFirestore _firestore;

  UserStatsRepository(this._firestore);

  Future<void> saveUserStats(UserProfile profile) async {
    if (profile.uid.isEmpty) {
      AppLogger.w('Cannot save user stats: profile.uid is empty');
      return;
    }
    await _firestore
        .collection('user_stats')
        .doc(profile.uid)
        .set(profile.toMap(), SetOptions(merge: true));
  }

  Future<void> updateWorldHealth(String uid, int score) async {
    final entropy = (1.0 - (score / 100.0)).clamp(0.0, 1.0);
    await _firestore.collection('user_stats').doc(uid).set({
      'worldHealthScore': score,
      'worldState': {
        'entropy': entropy,
      },
      'avatarStats': {
        'momentumScore': score,
      }
    }, SetOptions(merge: true));
  }

  /// Atomically syncs the profile to BOTH `users` and `user_stats` collections
  Future<void> syncUserIdentity(UserProfile profile) async {
    if (profile.uid.isEmpty) {
      AppLogger.w('Cannot sync identity: profile.uid is empty');
      return;
    }

    final data = profile.toMap();
    final batch = _firestore.batch();

    batch.set(
      _firestore.collection('users').doc(profile.uid),
      data,
      SetOptions(merge: true),
    );
    batch.set(
      _firestore.collection('user_stats').doc(profile.uid),
      data,
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  Stream<UserProfile> watchUserStats(String uid) {
    if (uid.isEmpty) {
      return Stream.value(const UserProfile(uid: ''));
    }
    // Debounce rapid updates to prevent rebuild storms
    // 300ms delay balances responsiveness with performance
    return _firestore
        .collection('user_stats')
        .doc(uid)
        .snapshots()
        .debounceTime(const Duration(milliseconds: 300))
        .map((snapshot) {
          try {
            if (snapshot.exists && snapshot.data() != null) {
              return UserProfile.fromMap(snapshot.data()!);
            } else {
              return UserProfile(uid: uid);
            }
          } catch (e) {
            AppLogger.e('Error parsing user stats', e);
            return UserProfile(uid: uid);
          }
        })
        .handleError((error) {
          AppLogger.e('Error watching user stats', error);
          // Return a default profile or rethrow depending on needs.
          // For UI stability, emitting a default profile is safer.
          return UserProfile(uid: uid);
        });
  }

  Future<UserProfile> getUserStats(String uid) async {
    if (uid.isEmpty) {
      return const UserProfile(uid: '');
    }
    try {
      final snapshot = await _firestore.collection('user_stats').doc(uid).get();
      if (snapshot.exists && snapshot.data() != null) {
        return UserProfile.fromMap(snapshot.data()!);
      } else {
        return UserProfile(uid: uid);
      }
    } catch (e) {
      AppLogger.e('Error getting user stats', e);
      return UserProfile(uid: uid);
    }
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
    final data = {
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
    final snapshot = await _firestore
        .collection('user_stats')
        .doc(userId)
        .collection('recaps')
        .doc(recapId)
        .get();

    return snapshot.data();
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
}
