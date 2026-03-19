import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:emerge_app/core/utils/validators.dart';
import 'package:emerge_app/features/auth/domain/entities/auth_user.dart';
import 'package:emerge_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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
    // Validate inputs before sending to Firebase
    final emailError = AppValidators.validateEmail(email);
    if (emailError != null) {
      return Left(AuthFailure(emailError));
    }

    final passwordError = AppValidators.validatePassword(password);
    if (passwordError != null) {
      return Left(AuthFailure(passwordError));
    }

    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
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
    // Validate inputs before sending to Firebase
    final emailError = AppValidators.validateEmail(email);
    if (emailError != null) {
      return Left(AuthFailure(emailError));
    }

    final passwordError = AppValidators.validatePassword(password);
    if (passwordError != null) {
      return Left(AuthFailure(passwordError));
    }

    final usernameError = AppValidators.validateUsername(username);
    if (usernameError != null) {
      return Left(AuthFailure(usernameError));
    }

    // Sanitize inputs
    final sanitizedEmail = email.trim();
    final sanitizedUsername = AppValidators.sanitizeInput(username);

    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: sanitizedEmail,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        return const Left(AuthFailure('User creation failed'));
      }

      // Update display name (username) - use sanitized version
      await user.updateDisplayName(sanitizedUsername);
      await user.reload(); // Reload to get updated info
      final updatedUser = _firebaseAuth.currentUser;

      // Create UserProfile in Firestore
      final userProfile = UserProfile(uid: updatedUser?.uid ?? user.uid);
      final profileMap = userProfile.toMap();
      profileMap['email'] = updatedUser?.email ?? user.email ?? '';
      profileMap['displayName'] = updatedUser?.displayName ?? sanitizedUsername;
      profileMap['createdAt'] = FieldValue.serverTimestamp();

      await _firestore.collection('users').doc(userProfile.uid).set(profileMap);

      // Create UserStats in Firestore (using UserProfile structure as expected by UserStatsRepository)
      await _firestore
          .collection('user_stats')
          .doc(userProfile.uid)
          .set(userProfile.toMap());

      return Right(
        AuthUser(
          id: updatedUser?.uid ?? user.uid,
          email: updatedUser?.email ?? user.email ?? '',
          displayName: updatedUser?.displayName ?? sanitizedUsername,
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
      UserCredential userCredential;

      if (kIsWeb) {
        // On web, use Firebase Auth popup directly
        final googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        userCredential = await _firebaseAuth.signInWithPopup(googleProvider);
      } else {
        // On mobile, use the GoogleSignIn package
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

        userCredential = await _firebaseAuth.signInWithCredential(credential);
      }

      final user = userCredential.user;

      if (user == null) {
        return const Left(AuthFailure('User not found'));
      }

      // Create or update user profile in Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        final userProfile = UserProfile(uid: user.uid);
        final profileMap = userProfile.toMap();
        profileMap['email'] = user.email ?? '';
        profileMap['displayName'] = user.displayName ?? '';
        profileMap['createdAt'] = FieldValue.serverTimestamp();
        await _firestore.collection('users').doc(user.uid).set(profileMap);
        await _firestore
            .collection('user_stats')
            .doc(user.uid)
            .set(userProfile.toMap());
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
    // Validate email before sending reset
    final emailError = AppValidators.validateEmail(email);
    if (emailError != null) {
      return Left(AuthFailure(emailError));
    }

    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
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
    if (!kIsWeb) {
      final googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
    }
    await _firebaseAuth.signOut();
  }

  @override
  Future<Either<Failure, void>> updateDisplayName(String displayName) async {
    // Validate display name using username rules
    final usernameError = AppValidators.validateUsername(displayName);
    if (usernameError != null) {
      return Left(AuthFailure(usernameError));
    }

    // Sanitize input
    final sanitizedDisplayName = AppValidators.sanitizeInput(displayName);

    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return const Left(AuthFailure('User not logged in'));
      }
      await user.updateDisplayName(sanitizedDisplayName);
      await user.reload();
      return const Right(null);
    } on FirebaseAuthException catch (e) {
      AppLogger.e('Update display name failed', e);
      return Left(AuthFailure(e.message ?? 'Update failed'));
    } catch (e, s) {
      AppLogger.e('Update display name failed', e, s);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAccount() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return const Left(AuthFailure('User not logged in'));
      }
      final uid = user.uid;

      // Delete user's habits subcollection
      final habitsSnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('habits')
          .get();
      for (final doc in habitsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete user profile from 'users' collection
      await _firestore.collection('users').doc(uid).delete();

      // Delete from 'user_stats' collection (legacy mirror)
      await _firestore.collection('user_stats').doc(uid).delete();

      // Remove from any tribes
      final tribeQuery = await _firestore
          .collection('tribes')
          .where('memberIds', arrayContains: uid)
          .get();
      for (final tribeDoc in tribeQuery.docs) {
        await tribeDoc.reference.update({
          'memberIds': FieldValue.arrayRemove([uid]),
          'memberCount': FieldValue.increment(-1),
        });
      }

      // Finally delete the Firebase Auth account
      await user.delete();

      return const Right(null);
    } on FirebaseAuthException catch (e) {
      AppLogger.e('Delete account failed', e);
      if (e.code == 'requires-recent-login') {
        return const Left(
          AuthFailure(
            'For security, please log out and log back in before deleting your account.',
          ),
        );
      }
      return Left(AuthFailure(e.message ?? 'Delete failed'));
    } catch (e, s) {
      AppLogger.e('Delete account failed', e, s);
      return Left(ServerFailure(e.toString()));
    }
  }
}
