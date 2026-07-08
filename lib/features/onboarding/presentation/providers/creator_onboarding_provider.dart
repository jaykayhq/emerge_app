import 'package:cloud_functions/cloud_functions.dart';
import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/auth/presentation/providers/role_provider.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/social/data/repositories/creator_repository.dart';
import 'package:emerge_app/features/social/domain/entities/creator_profile.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'creator_onboarding_provider.g.dart';

/// In-memory state for the creator onboarding flow.
///
/// 3 steps:
///   0: archetype (identity)
///   1: bio + speciality tags (profile)
///   2: welcome / reveal
@immutable
class CreatorOnboardingDraft {
  final UserArchetype? archetype;
  final String? bio;
  final List<String> specialityTags;
  final int currentStep;

  const CreatorOnboardingDraft({
    this.archetype,
    this.bio,
    this.specialityTags = const [],
    this.currentStep = 0,
  });

  CreatorOnboardingDraft copyWith({
    UserArchetype? archetype,
    String? bio,
    List<String>? specialityTags,
    int? currentStep,
  }) {
    return CreatorOnboardingDraft(
      archetype: archetype ?? this.archetype,
      bio: bio ?? this.bio,
      specialityTags: specialityTags ?? this.specialityTags,
      currentStep: currentStep ?? this.currentStep,
    );
  }
}

@Riverpod(keepAlive: true)
class CreatorOnboardingDraftController
    extends _$CreatorOnboardingDraftController {
  @override
  CreatorOnboardingDraft build() => const CreatorOnboardingDraft();

  void setArchetype(UserArchetype archetype) {
    state = state.copyWith(archetype: archetype);
  }

  void setBio(String bio) {
    state = state.copyWith(bio: bio.trim());
  }

  void addTag(String tag) {
    final t = tag.trim();
    if (t.isEmpty) return;
    if (state.specialityTags.contains(t)) return;
    state = state.copyWith(specialityTags: [...state.specialityTags, t]);
  }

  void removeTag(String tag) {
    state = state.copyWith(
      specialityTags: state.specialityTags.where((t) => t != tag).toList(),
    );
  }

  void setStep(int step) {
    state = state.copyWith(currentStep: step);
  }

  void reset() {
    state = const CreatorOnboardingDraft();
  }
}

/// Persists the current draft to `creator_profiles/{uid}` and updates
/// `creatorOnboardingProgress` so the router stops redirecting.
///
/// Safe to call multiple times (idempotent merge). After the third step
/// (reveal screen) it also calls the setUserRole Cloud Function with
/// `creatorOnboardingCompletedAt` so the dashboard is reachable.
@riverpod
Future<void> saveCreatorOnboardingProgress(
  Ref ref, {
  required int progress,
}) async {
  assert(progress >= 0 && progress <= 3);

  final user = ref.read(firebaseAuthProvider).currentUser;
  if (user == null) {
    AppLogger.w('saveCreatorOnboardingProgress: no current user, skipping.');
    return;
  }

  final draft = ref.read(creatorOnboardingDraftControllerProvider);
  final repo = ref.read(creatorRepositoryProvider);

  final existing = await repo.getCreatorProfile(user.uid);
  final updated = (existing ??
          CreatorProfile(
            userId: user.uid,
            role: 'creator',
          ))
      .copyWith(
    role: 'creator',
    archetype: draft.archetype,
    bio: draft.bio ?? existing?.bio ?? '',
    specialityTags: draft.specialityTags.isNotEmpty
        ? draft.specialityTags
        : (existing?.specialityTags ?? const []),
    creatorOnboardingProgress: progress,
    creatorOnboardingCompletedAt: progress >= 3 ? DateTime.now() : null,
  );

  await repo.updateCreatorProfile(updated);

  // Mirror the progress in the role claim too, so the router can read
  // it without an extra Firestore round-trip if the caller wants.
  try {
    final functions = FirebaseFunctions.instance;
    await functions.httpsCallable('setUserRole').call(<String, dynamic>{
      'role': 'creator',
      'creatorOnboardingProgress': progress,
      if (progress >= 3)
        'creatorOnboardingCompletedAt': DateTime.now().toIso8601String(),
    });
    await user.getIdToken(true);
  } catch (e, s) {
    AppLogger.w(
      'saveCreatorOnboardingProgress: setUserRole mirror failed; '
      'router will re-read Firestore.',
      error: e,
      stackTrace: s,
    );
  } finally {
    ref.invalidate(currentCreatorOnboardingProvider);
  }
}
