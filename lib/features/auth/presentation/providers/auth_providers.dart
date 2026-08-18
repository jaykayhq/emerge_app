import 'package:emerge_app/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:emerge_app/features/auth/domain/entities/auth_user.dart';
import 'package:emerge_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:emerge_app/core/drift/database.dart';
import 'package:emerge_app/core/sync/sync_providers.dart';
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
    FirebaseFunctions.instance,
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
  // Flush pending mutations before sign-out
  try {
    final syncEngine = ref.read(enhancedSyncEngineProvider);
    await syncEngine.processMutationQueue().timeout(const Duration(seconds: 5));
  } catch (e) {
    AppLogger.w('[Auth] Failed to flush sync queue on sign-out: $e');
  }
  // Clear local data for this user
  await ref.read(appDatabaseProvider).clearAll();

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
Future<void> signUpCreator(
  Ref ref,
  String email,
  String password,
  String username,
  String inviteCode,
) async {
  final auth = ref.read(firebaseAuthProvider);
  final credential = await auth.createUserWithEmailAndPassword(
    email: email.trim(),
    password: password,
  );

  final user = credential.user;
  if (user == null) throw Exception('User creation failed');

  await user.updateDisplayName(username.trim());

  // Claim the globally-unique username (same `usernames` lock collection as
  // the normal-user signup). redeemCreatorInvite does NOT claim it (verified
  // in functions/src/creator_invites.ts), so this client-side claim is what
  // keeps creator usernames unique. On collision the freshly-created account
  // is deleted — no half-registered creator lingers.
  final claim =
      await ref.read(authRepositoryProvider).claimUsername(username.trim());
  final claimFailure = claim.fold<Failure?>((f) => f, (_) => null);
  if (claimFailure != null) {
    try {
      await user.delete();
    } catch (_) {
      // Best-effort rollback; deleteMyAccount remains the cleanup path.
    }
    throw Exception(claimFailure.message);
  }

  // Server-side redemption creates creator_profiles (isVerifiedCreator: true)
  // and sets the role custom claim. The old client-side profile write and the
  // admin-gated setUserRole call are removed (SP-E).
  final functions = FirebaseFunctions.instance;
  await functions.httpsCallable('redeemCreatorInvite').call(<String, dynamic>{
    'code': inviteCode.trim().toUpperCase(),
    'displayName': username.trim(),
  });
  await user.getIdToken(true);
}

@Riverpod(keepAlive: true)
Future<void> signUpCreatorWithGoogle(
  Ref ref,
  String inviteCode,
  String username,
) async {
  final auth = ref.read(firebaseAuthProvider);
  final firestore = ref.read(firestoreProvider);

  firebase_auth.UserCredential userCredential;

  if (kIsWeb) {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pending_creator_signup', true);
    // Stashed for the post-redirect redemption in init_app.dart.
    await prefs.setString('pending_creator_invite_code', inviteCode.trim().toUpperCase());
    // The typed username too — the redirect return path must not silently
    // swap it for the Google display name (which would discard the name the
    // user explicitly chose and validated in the form).
    if (username.trim().isNotEmpty) {
      await prefs.setString('pending_creator_username', username.trim());
    }

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

  // Claim the username the UI collected (falls back to a normalized Google
  // display name when the field was left empty). Creators are covered by the
  // same uniqueness rule as normal users; redeemCreatorInvite has no claim,
  // so this is the enforceable gate. A typed-username collision fails the
  // sign-up (the form's live availability check already warned); a derived
  // name that cannot be claimed would just keep the fallback display name.
  final typedUsername = username.trim();
  String? effectiveUsername;
  if (typedUsername.isNotEmpty) {
    effectiveUsername = typedUsername;
  } else {
    effectiveUsername = deriveUsernameCandidate(user.displayName, user.email);
  }
  if (effectiveUsername != null) {
    final claim =
        await ref.read(authRepositoryProvider).claimUsername(effectiveUsername);
    final claimFailure = claim.fold<Failure?>((f) => f, (_) => null);
    if (claimFailure != null) {
      if (typedUsername.isNotEmpty) {
        await auth.signOut();
        if (!kIsWeb) {
          await GoogleSignIn.instance.signOut();
        }
        throw Exception(claimFailure.message);
      }
      AppLogger.w(
        'Creator Google signup: derived username claim skipped '
        '(${claimFailure.message}) — keeping display-name fallback.',
      );
    }
  } else {
    AppLogger.w(
      'Creator Google signup: no username typed and the Google display name '
      'cannot map to a valid username — keeping display-name fallback.',
    );
  }

  final redeemName = effectiveUsername ??
      (user.displayName?.trim().isNotEmpty == true
          ? user.displayName!
          : user.email?.split('@').first ?? 'Creator');

  // Server-side redemption (same as email path): the creator_profiles doc,
  // verification flag, and role claim are all function-owned.
  final functions = FirebaseFunctions.instance;
  await functions.httpsCallable('redeemCreatorInvite').call(<String, dynamic>{
    'code': inviteCode.trim().toUpperCase(),
    'displayName': redeemName,
  });
  await user.getIdToken(true);
}
