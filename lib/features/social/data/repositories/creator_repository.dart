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
}
