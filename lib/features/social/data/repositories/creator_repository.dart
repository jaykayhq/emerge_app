// lib/features/social/data/repositories/creator_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/features/social/domain/entities/creator_profile.dart';

final creatorRepositoryProvider = Provider<CreatorRepository>((ref) {
  return CreatorRepository();
});

class CreatorRepository {
  final FirebaseFirestore _firestore;

  CreatorRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<CreatorProfile?> getCreatorProfile(String userId) async {
    final doc = await _firestore
        .collection('creator_profiles')
        .doc(userId)
        .get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    return CreatorProfile.fromMap({...data, 'userId': doc.id});
  }

  Stream<CreatorProfile?> watchCreatorProfile(String userId) {
    return _firestore
        .collection('creator_profiles')
        .doc(userId)
        .snapshots()
        .map(
          (doc) => doc.exists
              ? CreatorProfile.fromMap({...doc.data()!, 'userId': doc.id})
              : null,
        );
  }

  /// Streams verified creator profiles, ordered by [blueprintCount] desc,
  /// limited to [limit] entries. Used by the lobby's creator strip and the
  /// browse-all-creators screen.
  Stream<List<CreatorProfile>> watchVerifiedCreators({int limit = 12}) {
    return _firestore
        .collection('creator_profiles')
        .where('isVerifiedCreator', isEqualTo: true)
        .orderBy('blueprintCount', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => CreatorProfile.fromMap({...d.data(), 'userId': d.id}))
              .toList(),
        );
  }

  Future<void> updateCreatorProfile(CreatorProfile profile) async {
    await _firestore
        .collection('creator_profiles')
        .doc(profile.userId)
        .set(profile.toMap(), SetOptions(merge: true));
  }

  /// Writes only the caller-provided, owner-editable profile fields
  /// (displayName, avatarUrl, heroImageUrl, bio, specialityTags). Never
  /// touches privileged fields (ownerId/userId/role/isVerifiedCreator) — the
  /// Firestore rules reject diffs on those, and a targeted merge also can't
  /// regress onboarding fields the way a full toMap() merge could.
  Future<void> updateCreatorProfileFields(
    String userId, {
    String? displayName,
    String? avatarUrl,
    String? heroImageUrl,
    String? bio,
    List<String>? specialityTags,
  }) async {
    final data = <String, dynamic>{'userId': userId};
    if (displayName != null) data['displayName'] = displayName;
    if (avatarUrl != null) data['avatarUrl'] = avatarUrl;
    if (heroImageUrl != null) data['heroImageUrl'] = heroImageUrl;
    if (bio != null) data['bio'] = bio;
    if (specialityTags != null) data['specialityTags'] = specialityTags;

    await _firestore
        .collection('creator_profiles')
        .doc(userId)
        .set(data, SetOptions(merge: true));
  }

  /// Renames the creator across every display surface: the public
  /// `creator_profiles` doc plus the `users` / `user_stats` mirrors. Mirrors
  /// are merged (create-if-missing) because creator signup only writes
  /// creator_profiles — the other docs may not exist yet.
  ///
  /// Note: the Firebase Auth displayName is updated separately via the auth
  /// repository; this method only syncs the Firestore mirrors.
  Future<void> updateCreatorName(String userId, String displayName) async {
    final batch = _firestore.batch();
    batch.set(
      _firestore.collection('creator_profiles').doc(userId),
      {'userId': userId, 'displayName': displayName},
      SetOptions(merge: true),
    );
    batch.set(
      _firestore.collection('users').doc(userId),
      {'displayName': displayName},
      SetOptions(merge: true),
    );
    batch.set(
      _firestore.collection('user_stats').doc(userId),
      {'displayName': displayName},
      SetOptions(merge: true),
    );
    await batch.commit();
  }
}
