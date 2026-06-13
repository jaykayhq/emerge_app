// lib/features/social/data/repositories/creator_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/features/social/domain/entities/creator_profile.dart';

class CreatorRepository {
  final FirebaseFirestore _firestore;

  CreatorRepository({FirebaseFirestore? firestore}) 
      : _firestore = firestore ?? FirebaseFirestore.instance;

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
