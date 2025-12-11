import 'package:emerge_app/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:emerge_app/features/auth/domain/entities/auth_user.dart';
import 'package:emerge_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_providers.g.dart';

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  return FirebaseAuthRepository(
    firebase_auth.FirebaseAuth.instance,
    FirebaseFirestore.instance,
  );
}

@Riverpod(keepAlive: true)
Stream<AuthUser> authStateChanges(Ref ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.user;
}

@riverpod
Future<void> signIn(Ref ref, String email, String password) async {
  final repository = ref.read(authRepositoryProvider);
  final result = await repository.signInWithEmailAndPassword(
    email: email,
    password: password,
  );
  result.fold((error) => throw Exception(error), (_) => null);
}

@riverpod
Future<void> signOut(Ref ref) async {
  final repository = ref.read(authRepositoryProvider);
  await repository.signOut();
}
