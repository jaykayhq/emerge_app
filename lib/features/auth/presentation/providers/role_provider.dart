import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/social/data/repositories/creator_repository.dart';

/// Canonical role values exposed to the rest of the app.
///
/// These MUST match the strings written by
/// `functions/src/setUserRole.ts` (VALID_ROLES) and stored in
/// `users/{uid}.role` / `creator_profiles/{uid}.role`.
enum UserRole {
  /// Normal end-user. Must complete the identity-studio onboarding flow.
  user,

  /// Creator account. Has its own onboarding flow and email verification.
  creator,

  /// Role could not be determined (legacy user before this field existed,
  /// or signup in flight before the custom claim propagates).
  unknown,
}

/// State of the currently-authenticated user's onboarding progress.
///
/// For normal users this is driven by `users/{uid}.onboardingProgress` /
/// `onboardingCompletedAt` (handled separately by the user-stats provider).
/// For creators we have a separate `creatorOnboardingProgress` field on
/// `creator_profiles/{uid}`. This provider exposes the creator-side state
/// so the router can decide where to send an authenticated creator.
class CreatorOnboardingState {
  final int progress; // 0-3
  final bool isComplete;
  final DateTime? completedAt;

  const CreatorOnboardingState({
    required this.progress,
    required this.isComplete,
    this.completedAt,
  });

  static const empty = CreatorOnboardingState(progress: 0, isComplete: false);
}

/// Reads the canonical `role` of the currently-authenticated user.
///
/// Resolution order (first non-null wins):
///   1. Firebase Auth custom claim `role` from the current ID token
///      (always fresh — we call `getIdToken(true)` so freshly-set claims
///      propagate immediately after `setUserRole` returns).
///   2. `users/{uid}.role` mirror written by the setUserRole Cloud Function.
///   3. Inference from collection-existence (legacy users who pre-date the
///      role field): `creator_profiles/{uid}` exists => creator,
///      `users/{uid}` exists => user, otherwise unknown.
///
/// Returns `null` when there is no authenticated user.
final currentUserRoleProvider = FutureProvider<UserRole?>((ref) async {
  final authUser = await ref.watch(authStateChangesProvider.future);
  if (authUser.isEmpty) return null;

  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return null;

  // 1. Custom claim (always force refresh — covers the "we just set the
  //    claim via setUserRole" path; cheap on subsequent reads since the
  //    token is cached for ~1h).
  try {
    final tokenResult = await user.getIdTokenResult(true);
    final claim = tokenResult.claims?['role'];
    if (claim == 'user') return UserRole.user;
    if (claim == 'creator') return UserRole.creator;
  } catch (_) {
    // Fall through to mirror / inference below.
  }

  // 2. Firestore mirror on users/{uid}.
  try {
    final firestore = FirebaseFirestore.instance;
    final userDoc =
        await firestore.collection('users').doc(user.uid).get();
    final mirror = userDoc.data()?['role'];
    if (mirror == 'user') return UserRole.user;
    if (mirror == 'creator') return UserRole.creator;
  } catch (_) {
    // Fall through to inference below.
  }

  // 3. Inference (legacy users).
  try {
    final firestore = FirebaseFirestore.instance;
    final creatorDoc = await firestore
        .collection('creator_profiles')
        .doc(user.uid)
        .get();
    if (creatorDoc.exists) return UserRole.creator;
    final userDoc = await firestore.collection('users').doc(user.uid).get();
    if (userDoc.exists) return UserRole.user;
  } catch (_) {
    // Give up — return unknown.
  }

  // Return unknown when nothing resolves, rather than defaulting to user.
  // The splash screen's determineSplashRoute and the router's decideRedirect
  // both handle UserRole.unknown by either falling back to a direct Firestore
  // check (splash) or holding the current path (router redirect) until the
  // role resolves.
  return UserRole.unknown;
});

/// Reads the creator onboarding state for the currently-authenticated user.
/// Returns `null` if the user is not a creator (or not signed in).
final currentCreatorOnboardingProvider =
    FutureProvider<CreatorOnboardingState?>((ref) async {
  final role = await ref.watch(currentUserRoleProvider.future);
  if (role != UserRole.creator) return null;

  final authUser = await ref.watch(authStateChangesProvider.future);
  if (authUser.isEmpty) return null;

  final repo = ref.watch(creatorRepositoryProvider);
  final profile = await repo.getCreatorProfile(authUser.id);
  if (profile == null) return CreatorOnboardingState.empty;

  return CreatorOnboardingState(
    progress: profile.creatorOnboardingProgress,
    isComplete: profile.creatorOnboardingCompletedAt != null ||
        profile.creatorOnboardingProgress >= 3,
    completedAt: profile.creatorOnboardingCompletedAt,
  );
});
