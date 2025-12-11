import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/gamification/domain/repositories/user_profile_repository.dart';
import 'package:fpdart/fpdart.dart';

class FirestoreUserProfileRepository implements UserProfileRepository {
  final FirebaseFirestore _firestore;

  FirestoreUserProfileRepository(this._firestore);

  @override
  Future<Either<String, Unit>> createProfile(UserProfile profile) async {
    try {
      await _firestore
          .collection('users')
          .doc(profile.uid)
          .set(profile.toMap());
      return const Right(unit);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, UserProfile>> getProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return Right(UserProfile.fromMap(doc.data()!));
      } else {
        return const Left('Profile not found');
      }
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Stream<UserProfile?> watchProfile(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return UserProfile.fromMap(doc.data()!);
      }
      return null;
    });
  }

  @override
  Future<Either<String, Unit>> updateProfile(UserProfile profile) async {
    try {
      await _firestore
          .collection('users')
          .doc(profile.uid)
          .update(profile.toMap());
      return const Right(unit);
    } catch (e) {
      return Left(e.toString());
    }
  }
}
