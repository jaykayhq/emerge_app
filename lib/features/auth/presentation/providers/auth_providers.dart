import 'package:emerge_app/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:emerge_app/features/auth/domain/entities/auth_user.dart';
import 'package:emerge_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_providers.g.dart';

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  return FirebaseAuthRepository(
    firebase_auth.FirebaseAuth.instance,
    ref.watch(firestoreProvider),
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
  result.fold((error) => throw Exception(error.message), (_) => null);
}

@riverpod
Future<void> signOut(Ref ref) async {
  final repository = ref.read(authRepositoryProvider);
  await repository.signOut();
}

@Riverpod(keepAlive: true)
FirebaseFirestore firestore(Ref ref) {
  return FirebaseFirestore.instance;
}

@riverpod
Future<bool> isNormalUser(Ref ref, String uid) async {
  if (uid.trim().isEmpty) return false;
  final firestore = ref.watch(firestoreProvider);
  final doc = await firestore.collection('users').doc(uid).get();
  return doc.exists;
}

@riverpod
Future<bool> isCreator(Ref ref, String uid) async {
  if (uid.trim().isEmpty) return false;
  final firestore = ref.watch(firestoreProvider);
  final doc = await firestore.collection('creator_profiles').doc(uid).get();
  return doc.exists;
}

@riverpod
Future<bool> isCurrentNormalUser(Ref ref) async {
  final authUser = await ref.watch(authStateChangesProvider.future);
  if (authUser.isEmpty) return false;
  return ref.watch(isNormalUserProvider(authUser.id).future);
}

@riverpod
Future<bool> isCurrentCreator(Ref ref) async {
  final authUser = await ref.watch(authStateChangesProvider.future);
  if (authUser.isEmpty) return false;
  return ref.watch(isCreatorProvider(authUser.id).future);
}

