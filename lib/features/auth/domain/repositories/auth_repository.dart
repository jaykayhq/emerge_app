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

  Future<void> signOut();

  Future<Either<Failure, void>> updateDisplayName(String displayName);

  Future<Either<Failure, void>> deleteAccount();

  /// Sends a 6-digit verification code to the current user's email.
  Future<Either<Failure, void>> sendEmailVerificationCode();

  /// Submits a 6-digit code; on success the account is marked verified.
  Future<Either<Failure, void>> verifyEmailCode(String code);

  /// Claims a globally-unique (case-insensitive) username for the current user.
  Future<Either<Failure, void>> claimUsername(String username);

  /// True when the current user's email is verified.
  Future<Either<Failure, bool>> checkEmailVerified();
}
