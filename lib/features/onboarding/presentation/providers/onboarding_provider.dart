import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:equatable/equatable.dart';
import 'package:emerge_app/features/onboarding/data/repositories/local_settings_repository.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/gamification/presentation/providers/gamification_providers.dart';
import 'package:emerge_app/features/onboarding/domain/entities/onboarding_milestone.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'onboarding_provider.g.dart';

@Riverpod(keepAlive: true)
LocalSettingsRepository localSettingsRepository(Ref ref) {
  return LocalSettingsRepository();
}

@Riverpod(keepAlive: true)
class OnboardingController extends _$OnboardingController {
  @override
  bool build() {
    final repo = ref.watch(localSettingsRepositoryProvider);
    return repo.isFirstLaunch;
  }

  Future<void> completeOnboarding() async {
    final repo = ref.read(localSettingsRepositoryProvider);
    await repo.completeOnboarding();
    state = false;
  }

  Future<void> saveOnboardingData() async {
    final onboardingState = ref.read(onboardingStateProvider);
    final userAsync = ref.read(authStateChangesProvider);
    final user = userAsync.value;

    if (user != null) {
      final userProfileRepo = ref.read(userProfileRepositoryProvider);

      // Fetch existing profile or create new one
      final existingProfileAsync = await ref.read(userProfileProvider.future);

      final updatedProfile =
          existingProfileAsync?.copyWith(
            archetype: onboardingState.selectedArchetype ?? UserArchetype.none,
            motive: onboardingState.motive,
            why: onboardingState.why,
            anchors: onboardingState.anchors,
            habitStacks: onboardingState.habitStacks,
            onboardingProgress: onboardingState.currentMilestoneStep,
            skippedOnboardingSteps: _getSkippedStepsList(onboardingState),
            onboardingCompletedAt: onboardingState.currentMilestoneStep >= 3
                ? DateTime.now()
                : null,
          ) ??
          UserProfile(
            uid: user.id,
            archetype: onboardingState.selectedArchetype ?? UserArchetype.none,
            motive: onboardingState.motive,
            why: onboardingState.why,
            anchors: onboardingState.anchors,
            habitStacks: onboardingState.habitStacks,
            onboardingProgress: onboardingState.currentMilestoneStep,
            skippedOnboardingSteps: _getSkippedStepsList(onboardingState),
            onboardingStartedAt: DateTime.now(),
            onboardingCompletedAt: onboardingState.currentMilestoneStep >= 3
                ? DateTime.now()
                : null,
          );

      await userProfileRepo.updateProfile(updatedProfile);
      if (onboardingState.currentMilestoneStep >= 3) {
        await completeOnboarding();
      }
    }
  }

  List<String> _getSkippedStepsList(OnboardingState state) {
    final List<String> skipped = [];
    final stepNames = ['archetype', 'anchors', 'stacking'];
    for (
      int i = 0;
      i < state.skippedMilestones.length && i < stepNames.length;
      i++
    ) {
      if (state.skippedMilestones[i]) {
        skipped.add(stepNames[i]);
      }
    }
    return skipped;
  }

  Future<void> skipMilestone(int milestoneIndex) async {
    if (milestoneIndex < 0 || milestoneIndex > 2) return;

    final currentState = ref.read(onboardingStateProvider);
    final skipped = List<bool>.from(currentState.skippedMilestones);

    // Ensure list is long enough
    while (skipped.length <= milestoneIndex) {
      skipped.add(false);
    }
    skipped[milestoneIndex] = true;

    ref
        .read(onboardingStateProvider.notifier)
        .update(
          (state) => state.copyWith(
            currentMilestoneStep: milestoneIndex + 1,
            skippedMilestones: skipped,
          ),
        );

    // Save progress to user profile
    await saveOnboardingData();
  }

  Future<void> completeMilestone(int milestoneIndex) async {
    if (milestoneIndex < 0 || milestoneIndex > 2) return;

    final currentState = ref.read(onboardingStateProvider);
    final completed = List<bool>.from(currentState.completedMilestones);

    // Ensure list is long enough
    while (completed.length <= milestoneIndex) {
      completed.add(false);
    }
    completed[milestoneIndex] = true;

    ref
        .read(onboardingStateProvider.notifier)
        .update(
          (state) => state.copyWith(
            currentMilestoneStep: milestoneIndex + 1,
            completedMilestones: completed,
          ),
        );

    // Save progress to user profile
    await saveOnboardingData();
  }
}

class OnboardingState extends Equatable {
  final UserArchetype? selectedArchetype;
  final Map<String, int> attributes;
  final int remainingPoints;
  final String? motive;
  final String? why;
  final List<String> anchors;
  final List<HabitStack> habitStacks;
  final int currentMilestoneStep; // 0-3 (3-step flow)
  final List<bool> completedMilestones; // [archetype, anchors, stacking]
  final List<bool> skippedMilestones; // Track which steps user skipped

  const OnboardingState({
    this.selectedArchetype,
    this.attributes = const {
      'Vitality': 0,
      'Focus': 0,
      'Creativity': 0,
      'Strength': 0,
    },
    this.remainingPoints = 10,
    this.motive,
    this.why,
    this.anchors = const [],
    this.habitStacks = const [],
    this.currentMilestoneStep = 0,
    this.completedMilestones = const [false, false, false],
    this.skippedMilestones = const [false, false, false],
  });

  OnboardingState copyWith({
    UserArchetype? selectedArchetype,
    Map<String, int>? attributes,
    int? remainingPoints,
    String? motive,
    String? why,
    List<String>? anchors,
    List<HabitStack>? habitStacks,
    int? currentMilestoneStep,
    List<bool>? completedMilestones,
    List<bool>? skippedMilestones,
  }) {
    return OnboardingState(
      selectedArchetype: selectedArchetype ?? this.selectedArchetype,
      attributes: attributes ?? this.attributes,
      remainingPoints: remainingPoints ?? this.remainingPoints,
      motive: motive ?? this.motive,
      why: why ?? this.why,
      anchors: anchors ?? this.anchors,
      habitStacks: habitStacks ?? this.habitStacks,
      currentMilestoneStep: currentMilestoneStep ?? this.currentMilestoneStep,
      completedMilestones: completedMilestones ?? this.completedMilestones,
      skippedMilestones: skippedMilestones ?? this.skippedMilestones,
    );
  }

  @override
  List<Object?> get props => [
    selectedArchetype,
    attributes,
    remainingPoints,
    motive,
    why,
    anchors,
    habitStacks,
    currentMilestoneStep,
    completedMilestones,
    skippedMilestones,
  ];
}

final onboardingStateProvider = StateProvider<OnboardingState>(
  (ref) => const OnboardingState(),
);

// Keep legacy providers for backward compatibility if needed, or refactor screens to use onboardingStateProvider
final selectedArchetypeProvider = StateProvider<UserArchetype?>((ref) {
  return ref.watch(onboardingStateProvider).selectedArchetype;
});

final attributePointsProvider = StateProvider<int>((ref) {
  return ref.watch(onboardingStateProvider).remainingPoints;
});

final attributesProvider = StateProvider<Map<String, int>>((ref) {
  return ref.watch(onboardingStateProvider).attributes;
});

/// Provider that returns the currently active onboarding milestones
/// Based on user's onboarding progress (0-3)
/// Returns empty list if onboarding is complete or if user profile isn't loaded
@riverpod
List<OnboardingMilestone> activeMilestones(Ref ref) {
  final userProfile = ref.watch(userProfileProvider).valueOrNull;
  final progress = userProfile?.onboardingProgress ?? 0;

  // Define the 3 streamlined onboarding milestones
  final allMilestones = [
    OnboardingMilestone(
      order: 1,
      title: 'Choose Your North Star',
      description:
          'Select the identity archetype that resonates with who you want to become',
      routePath: '/onboarding/archetype',
      icon: Icons.wb_sunny, // Morning icon matching mockup timeline
      isCompleted: progress > 0,
      canSkip: true,
      backgroundImageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuB7vvlopJkR4rgsae5H2MI2s3F4-79z1kHlY0_9fnL3AlwO9_S_Nf1T3yQ0y9o4iErmVjo95wmXqQIcn5fGSRg-sqWbOQD2dnX-y_7ESMCuf6PYzRI85AumRdQItGd8Z2o7GXtSkMKQH-SrF9mks_CpRy7WFVTEXM5LDJPaqY-de95hWsH2Pa9AQZrIjYs_AdHsDPw1I9Tt90Q-tm59XRtJb3RUYYPqP1mtlBOx8jbrF3IHdOZk8cN5Po_RsZ-HaVWUzdkTCM5KFj0',
    ),
    OnboardingMilestone(
      order: 2,
      title: 'Map Your Day\'s Anchors',
      description: 'Identify existing routines to build new habits upon',
      routePath: '/onboarding/anchors',
      icon: Icons.anchor,
      isCompleted: progress > 1,
      canSkip: true,
      backgroundImageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuB7vvlopJkR4rgsae5H2MI2s3F4-79z1kHlY0_9fnL3AlwO9_S_Nf1T3yQ0y9o4iErmVjo95wmXqQIcn5fGSRg-sqWbOQD2dnX-y_7ESMCuf6PYzRI85AumRdQItGd8Z2o7GXtSkMKQH-SrF9mks_CpRy7WFVTEXM5LDJPaqY-de95hWsH2Pa9AQZrIjYs_AdHsDPw1I9Tt90Q-tm59XRtJb3RUYYPqP1mtlBOx8jbrF3IHdOZk8cN5Po_RsZ-HaVWUzdkTCM5KFj0',
    ),
    OnboardingMilestone(
      order: 3,
      title: 'Build Your Habit Chains',
      description: 'Create personalized habit stacks based on your archetype',
      routePath: '/onboarding/stacking',
      icon: Icons.link,
      isCompleted: progress > 2,
      canSkip: true,
      backgroundImageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuB7vvlopJkR4rgsae5H2MI2s3F4-79z1kHlY0_9fnL3AlwO9_S_Nf1T3yQ0y9o4iErmVjo95wmXqQIcn5fGSRg-sqWbOQD2dnX-y_7ESMCuf6PYzRI85AumRdQItGd8Z2o7GXtSkMKQH-SrF9mks_CpRy7WFVTEXM5LDJPaqY-de95hWsH2Pa9AQZrIjYs_AdHsDPw1I9Tt90Q-tm59XRtJb3RUYYPqP1mtlBOx8jbrF3IHdOZk8cN5Po_RsZ-HaVWUzdkTCM5KFj0',
    ),
  ];

  // Return only the current uncompleted milestone for active onboarding
  // If all milestones completed, return empty list
  if (progress >= 3) return [];

  // Return the next milestone to complete
  return [allMilestones[progress]];
}
