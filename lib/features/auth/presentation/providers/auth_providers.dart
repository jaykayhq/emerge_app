import 'package:emerge_app/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:emerge_app/features/auth/domain/entities/auth_user.dart';
import 'package:emerge_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:emerge_app/features/social/presentation/providers/creator_provider.dart';
import 'package:emerge_app/features/social/domain/entities/creator_profile.dart';
import 'package:google_sign_in/google_sign_in.dart';
part 'auth_providers.g.dart';

@Riverpod(keepAlive: true)
firebase_auth.FirebaseAuth firebaseAuth(Ref ref) {
  return firebase_auth.FirebaseAuth.instance;
}

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  return FirebaseAuthRepository(
    ref.watch(firebaseAuthProvider),
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

@Riverpod(keepAlive: true)
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

@Riverpod(keepAlive: true)
Future<void> signUpCreator(Ref ref, String email, String password, String username) async {
  final auth = ref.read(firebaseAuthProvider);
  final credential = await auth.createUserWithEmailAndPassword(
    email: email.trim(),
    password: password,
  );

  final user = credential.user;
  if (user == null) throw Exception('User creation failed');

  await user.updateDisplayName(username.trim());

  final creatorProfile = CreatorProfile(
    userId: user.uid,
    role: 'creator',
    displayName: username.trim(),
    isVerifiedCreator: false,
  );

  await ref.read(creatorRepositoryProvider).updateCreatorProfile(creatorProfile);
  AppLogger.d('signUpCreator: wrote creator_profiles/${user.uid}');

  try {
    final functions = FirebaseFunctions.instance;
    await functions.httpsCallable('setUserRole').call(<String, dynamic>{
      'role': 'creator',
    });
    await user.getIdToken(true);
  } catch (e, s) {
    AppLogger.w(
      'signUpCreator: setUserRole failed; router will fall back to mirror.',
      error: e,
      stackTrace: s,
    );
  }
}

@Riverpod(keepAlive: true)
Future<void> signUpCreatorWithGoogle(Ref ref) async {
  final auth = ref.read(firebaseAuthProvider);
  final firestore = ref.read(firestoreProvider);
  final creatorRepo = ref.read(creatorRepositoryProvider);

  firebase_auth.UserCredential userCredential;

  if (kIsWeb) {
    final googleProvider = firebase_auth.GoogleAuthProvider();
    googleProvider.addScope('email');
    googleProvider.addScope('profile');
    await auth.signInWithRedirect(googleProvider);
    return;
  } else {
    final googleUser = await GoogleSignIn.instance.authenticate();
    final googleAuth = googleUser.authentication;
    final credential = firebase_auth.GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );
    userCredential = await auth.signInWithCredential(credential);
  }

  final user = userCredential.user;
  if (user == null) throw Exception('Google sign-up failed');

  final userDoc = await firestore.collection('users').doc(user.uid).get();
  if (userDoc.exists) {
    await auth.signOut();
    if (!kIsWeb) {
      await GoogleSignIn.instance.signOut();
    }
    throw Exception('This Google account is already registered as a normal user.');
  }

  final creatorProfile = CreatorProfile(
    userId: user.uid,
    role: 'creator',
    displayName: user.displayName ?? user.email?.split('@').first ?? 'Creator',
    isVerifiedCreator: false,
  );

  await creatorRepo.updateCreatorProfile(creatorProfile);

  try {
    final functions = FirebaseFunctions.instance;
    await functions.httpsCallable('setUserRole').call(<String, dynamic>{
      'role': 'creator',
    });
    await user.getIdToken(true);
  } catch (e, s) {
    AppLogger.w(
      'signUpCreatorWithGoogle: setUserRole failed; '
      'router will fall back to mirror.',
      error: e,
      stackTrace: s,
    );
  }
}
