import 'dart:async';

import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/features/auth/domain/entities/auth_user.dart';
import 'package:emerge_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:fpdart/fpdart.dart';

class FakeAuthRepository implements AuthRepository {
  final _controller = StreamController<AuthUser>();
  AuthUser _currentUser = AuthUser.empty;

  FakeAuthRepository() {
    _controller.add(_currentUser);
  }

  @override
  Stream<AuthUser> get user => _controller.stream;

  @override
  Future<Either<Failure, AuthUser>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    if (email == 'test@emerge.com' && password == 'password') {
      _currentUser = AuthUser(
        id: '123',
        email: email,
        displayName: 'Test User',
      );
      _controller.add(_currentUser);
      return Right(_currentUser);
    }
    return const Left(AuthFailure('Invalid credentials'));
  }

  @override
  Future<Either<Failure, AuthUser>> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String username,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    _currentUser = AuthUser(id: '123', email: email, displayName: username);
    _controller.add(_currentUser);
    return Right(_currentUser);
  }

  @override
  Future<Either<Failure, AuthUser>> signInWithGoogle() async {
    await Future.delayed(const Duration(seconds: 1));
    _currentUser = const AuthUser(
      id: 'google-123',
      email: 'google@emerge.com',
      displayName: 'Google User',
    );
    _controller.add(_currentUser);
    return Right(_currentUser);
  }

  @override
  Future<Either<Failure, void>> sendPasswordResetEmail(String email) async {
    await Future.delayed(const Duration(seconds: 1));
    return const Right(null);
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _currentUser = AuthUser.empty;
    _controller.add(_currentUser);
  }

  void dispose() {
    _controller.close();
  }
}
