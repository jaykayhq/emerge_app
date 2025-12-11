import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:emerge_app/features/auth/domain/entities/auth_user.dart';
import 'package:emerge_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  FirebaseAuthRepository(this._firebaseAuth, this._firestore);

  @override
  Stream<AuthUser> get user {
    return _firebaseAuth.idTokenChanges().map((firebaseUser) {
      if (firebaseUser == null) {
        return AuthUser.empty;
      }
      return AuthUser(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName: firebaseUser.displayName,
      );
    });
  }

  @override
  Future<Either<Failure, AuthUser>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        return const Left(AuthFailure('User not found'));
      }
      return Right(
        AuthUser(
          id: user.uid,
          email: user.email ?? '',
          displayName: user.displayName,
        ),
      );
    } on FirebaseAuthException catch (e) {
      AppLogger.e('Sign in failed', e);
      return Left(AuthFailure(e.message ?? 'Authentication failed'));
    } catch (e, s) {
      AppLogger.e('Sign in failed', e, s);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthUser>> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        return const Left(AuthFailure('User creation failed'));
      }

      // Update display name (username)
      await user.updateDisplayName(username);
      await user.reload(); // Reload to get updated info
      final updatedUser = _firebaseAuth.currentUser;

      // Create UserProfile in Firestore
      final userProfile = UserProfile(uid: updatedUser?.uid ?? user.uid);
      await _firestore
          .collection('users')
          .doc(userProfile.uid)
          .set(userProfile.toMap());

      // Create UserStats in Firestore (using UserProfile structure as expected by UserStatsRepository)
      await _firestore
          .collection('user_stats')
          .doc(userProfile.uid)
          .set(userProfile.toMap());

      return Right(
        AuthUser(
          id: updatedUser?.uid ?? user.uid,
          email: updatedUser?.email ?? user.email ?? '',
          displayName: updatedUser?.displayName ?? username,
        ),
      );
    } on FirebaseAuthException catch (e) {
      AppLogger.e('Sign up failed', e);
      return Left(AuthFailure(e.message ?? 'Sign up failed'));
    } catch (e, s) {
      AppLogger.e('Sign up failed', e, s);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthUser>> signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn();
      final googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        return const Left(AuthFailure('Google Sign-In cancelled'));
      }

      final googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );
      final user = userCredential.user;

      if (user == null) {
        return const Left(AuthFailure('User not found'));
      }

      return Right(
        AuthUser(
          id: user.uid,
          email: user.email ?? '',
          displayName: user.displayName,
        ),
      );
    } on FirebaseAuthException catch (e) {
      AppLogger.e('Google Sign-In failed', e);
      return Left(AuthFailure(e.message ?? 'Google Sign-In failed'));
    } catch (e, s) {
      AppLogger.e('Google Sign-In failed', e, s);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      return const Right(null);
    } on FirebaseAuthException catch (e) {
      AppLogger.e('Password reset failed', e);
      return Left(AuthFailure(e.message ?? 'Password reset failed'));
    } catch (e, s) {
      AppLogger.e('Password reset failed', e, s);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _firebaseAuth.signOut();
  }
}
