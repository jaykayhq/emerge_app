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

  Future<Either<Failure, AuthUser>> signInWithGoogle();

  Future<Either<Failure, void>> sendPasswordResetEmail(String email);

  Future<void> signOut();

  Future<Either<Failure, void>> updateDisplayName(String displayName);

  Future<Either<Failure, AuthUser>> signInAnonymously();
}
