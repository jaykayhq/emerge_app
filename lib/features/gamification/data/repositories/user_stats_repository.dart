import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final userStatsRepositoryProvider = Provider<UserStatsRepository>((ref) {
  return UserStatsRepository(FirebaseFirestore.instance);
});

class UserStatsRepository {
  final FirebaseFirestore _firestore;

  UserStatsRepository(this._firestore);

  Future<void> saveUserStats(UserProfile profile) async {
    await _firestore
        .collection('user_stats')
        .doc(profile.uid)
        .set(profile.toMap());
  }

  Stream<UserProfile> watchUserStats(String uid) {
    if (uid.isEmpty) {
      return Stream.value(const UserProfile(uid: ''));
    }
    return _firestore
        .collection('user_stats')
        .doc(uid)
        .snapshots()
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
}
