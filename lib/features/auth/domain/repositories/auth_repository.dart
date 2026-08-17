import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/features/auth/domain/entities/auth_user.dart';
import 'package:fpdart/fpdart.dart';

abstract class AuthRepository {
  Stream<AuthUser> get user;

  Future<Either<Failure, AuthUser>> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<Either<Failure, AuthUser>> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String username,
  });

  Future<Either<Failure, AuthUser>> signInWithGoogle({bool isLogin = false});

  Future<Either<Failure, void>> sendPasswordResetEmail(String email);

  /// Completes a password reset with the oobCode from the reset link the
  /// native Firebase email sent (deep link back into the app's
  /// /reset-password screen), then signs the user out of any stale session.
  Future<Either<Failure, void>> resetPasswordWithCode({
    required String oobCode,
    required String newPassword,
  });

  Future<void> signOut();

  Future<Either<Failure, void>> updateDisplayName(String displayName);

  Future<Either<Failure, void>> deleteAccount();

  /// Sends the native Firebase verification link to the current user's email.
  /// Clicking the link marks the account verified server-side; the client
  /// watches `emailVerified` on the auth stream.
  Future<Either<Failure, void>> sendVerificationEmail();

  /// Applies a Firebase Auth oobCode from the verification link the email
  /// worker sent (deep link back into the app), then reloads the user so
  /// emailVerified reflects the new state.
  Future<Either<Failure, void>> applyVerificationCode(String oobCode);

  /// Claims a globally-unique (case-insensitive) username for the current user.
  Future<Either<Failure, void>> claimUsername(String username);

  /// Probes whether a username is still free (case-insensitive). Used by the
  /// signup form to flag "username in use" while the user is typing.
  Future<Either<Failure, bool>> checkUsernameAvailability(String username);

  /// True when the current user's email is verified. Reloads auth state so it
  /// reflects a verification link that was clicked (possibly outside the app)
  /// before the user taps "I've verified".
  Future<Either<Failure, bool>> checkEmailVerified();
}
