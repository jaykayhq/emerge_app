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
import 'package:cloud_functions/cloud_functions.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';

/// Canonical role strings. Must stay in sync with
/// `functions/src/setUserRole.ts` (VALID_ROLES). The 'creator' value
/// is only written from `lib/features/auth/presentation/providers/
/// auth_providers.dart` (signUpCreator*), which passes the literal
/// directly; this file only writes the 'user' value.
const String _kRoleUser = 'user';

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  FirebaseAuthRepository(this._firebaseAuth, this._firestore) {
    if (!kIsWeb) {
      GoogleSignIn.instance.initialize();
    }
  }

  /// Best-effort: invoke the `setUserRole` Cloud Function and refresh the
  /// user's ID token so the new custom claim is picked up by the router
  /// immediately. Never throws — failures are logged and swallowed so
  /// a role-assignment hiccup can never break the auth flow itself.
  ///
  /// The router has a Firestore fallback (reads `users/{uid}.role`) for
  /// the brief window where the claim hasn't propagated yet, so this is
  /// a perf/UX improvement, not a correctness requirement.
  Future<void> _assignRoleAndRefresh(User user, String role) async {
    try {
      final functions = FirebaseFunctions.instance;
      await functions.httpsCallable('setUserRole').call(<String, dynamic>{
        'role': role,
      });
      await user.getIdToken(true);
      AppLogger.i('AuthRepository: role=$role assigned to uid=${user.uid}');
    } catch (e, s) {
      AppLogger.w(
        'AuthRepository: setUserRole($role) failed; '
        'router will fall back to Firestore mirror. Error: $e',
        error: e,
        stackTrace: s,
      );
    }
  }

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
      String message = e.message ?? 'Authentication failed';
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        message = 'Invalid email or password. Please make sure you have an account.';
      }
      return Left(AuthFailure(message));
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
      final userProfile = UserProfile(
        uid: updatedUser?.uid ?? user.uid,
        role: _kRoleUser,
        displayName: updatedUser?.displayName ?? sanitizedUsername,
      );
      final profileMap = userProfile.toMap();
      profileMap['email'] = updatedUser?.email ?? user.email ?? '';
      profileMap['createdAt'] = FieldValue.serverTimestamp();

      // Remove null values to comply with Firestore security rule type checks
      // (isValidStats rejects null values for fields like photoUrl)
      profileMap.removeWhere((_, value) => value == null);

      await _firestore.collection('users').doc(userProfile.uid).set(profileMap);
      await _firestore
          .collection('user_stats')
          .doc(userProfile.uid)
          .set(profileMap);

      // Set the canonical `role` custom claim so the router has a
      // deterministic source of truth. Failure is non-fatal — the Firestore
      // mirror is the fallback read path.
      await _assignRoleAndRefresh(updatedUser ?? user, _kRoleUser);

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
  Future<Either<Failure, AuthUser>> signInWithGoogle({bool isLogin = false}) async {
    try {
      UserCredential userCredential;

      if (kIsWeb) {
        // On web, use redirect flow — signInWithPopup is incompatible with
        // Cross-Origin-Opener-Policy: same-origin (COOP severs window.opener
        // so the popup can never post its credential back, causing minified:JC).
        // signInWithRedirect navigates the current tab to the OAuth provider
        // and back; no cross-origin window messaging required.
        // Profile creation is handled in initApp() after getRedirectResult().
        final googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        await _firebaseAuth.signInWithRedirect(googleProvider);
        // signInWithRedirect never returns a credential synchronously.
        // The result is captured via getRedirectResult() on page reload, which
        // fires idTokenChanges() in the auth stream. Return empty here;
        // the router will react to the idTokenChanges() stream and navigate.
        return const Left(AuthFailure('redirect_initiated'));
      } else {
        // On mobile, use the GoogleSignIn package with 7.x API
        final googleUser = await GoogleSignIn.instance.authenticate();

        final googleAuth = googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );

        userCredential = await _firebaseAuth.signInWithCredential(credential);
      }

      final user = userCredential.user;

      if (user == null) {
        return const Left(AuthFailure('User not found'));
      }

      // Check if user exists in Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      
      // If logging in and user doesn't exist, fail and clean up
      if (isLogin && !userDoc.exists) {
        await user.delete();
        if (!kIsWeb) {
          await GoogleSignIn.instance.signOut();
        }
        return const Left(AuthFailure('No account found for this Google account. Please sign up first.'));
      }

      // If signing up and user doesn't exist, create profile
      if (!userDoc.exists) {
        final displayName = user.displayName?.isNotEmpty == true
            ? user.displayName!
            : user.email?.split('@').first ?? 'User';
        final userProfile = UserProfile(
          uid: user.uid,
          role: _kRoleUser,
          displayName: displayName,
        );
        final profileMap = userProfile.toMap();
        profileMap['email'] = user.email ?? '';
        profileMap['createdAt'] = FieldValue.serverTimestamp();
        // Remove null values to comply with Firestore security rule type checks
        profileMap.removeWhere((_, value) => value == null);
        await _firestore.collection('users').doc(user.uid).set(profileMap);
        await _firestore.collection('user_stats').doc(user.uid).set(profileMap);

        // Set the canonical `role` custom claim so the router has a
        // deterministic source of truth. Failure is non-fatal — the
        // Firestore mirror we just wrote is the fallback read path.
        await _assignRoleAndRefresh(user, _kRoleUser);
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
      await GoogleSignIn.instance.signOut();
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
      // Call the server-side deleteMyAccount function which uses Admin SDK
      // to wipe all user data across Firestore AND delete the Auth account.
      final functions = FirebaseFunctions.instance;
      final result = await functions.httpsCallable('deleteMyAccount').call();

      if (result.data != null && (result.data as Map)['success'] == true) {
        return const Right(null);
      }
      return const Left(ServerFailure('Account deletion failed unexpectedly'));
    } on FirebaseFunctionsException catch (e) {
      AppLogger.e('Delete account failed', e);
      if (e.code == 'unauthenticated') {
        return const Left(
          AuthFailure('Please log in again before deleting your account.'),
        );
      }
      return Left(ServerFailure(e.message ?? 'Delete failed'));
    } catch (e, s) {
      AppLogger.e('Delete account failed', e, s);
      return Left(ServerFailure(e.toString()));
    }
  }
}
