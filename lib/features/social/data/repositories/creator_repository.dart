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
    return CreatorProfile.fromMap(doc.data()!);
  }

  Stream<CreatorProfile?> watchCreatorProfile(String userId) {
    return _firestore
        .collection('creator_profiles')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? CreatorProfile.fromMap(doc.data()!) : null);
  }

  Future<void> updateCreatorProfile(CreatorProfile profile) async {
    await _firestore
        .collection('creator_profiles')
        .doc(profile.userId)
        .set(profile.toMap(), SetOptions(merge: true));
  }
}
