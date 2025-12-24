import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:equatable/equatable.dart';
import 'package:emerge_app/features/onboarding/data/repositories/local_settings_repository.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/gamification/presentation/providers/gamification_providers.dart';
import 'package:emerge_app/features/onboarding/domain/entities/onboarding_milestone.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:emerge_app/features/gamification/data/repositories/user_stats_repository.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:emerge_app/features/onboarding/data/services/remote_config_service.dart';
import 'package:uuid/uuid.dart';

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

    // Also update user stats to reflect onboarding completion
    final userAsync = ref.read(authStateChangesProvider);
    final user = userAsync.value;
    if (user != null) {
      try {
        final userStatsRepo = ref.read(userStatsRepositoryProvider);
        final currentProfile = await userStatsRepo.getUserStats(user.id);

        // Update the profile to mark onboarding as complete
        final updatedProfile = currentProfile.copyWith(
          onboardingProgress: 5, // Mark as completed
          onboardingCompletedAt: DateTime.now(),
        );

        await userStatsRepo.saveUserStats(updatedProfile);

        // Log the onboarding completion activity
        await userStatsRepo.logActivity(
          userId: user.id,
          type: 'onboarding_completed',
          date: DateTime.now(),
        );
      } catch (e, stack) {
        AppLogger.e(
          'Error updating user stats on onboarding completion',
          e,
          stack,
        );
      }
    }

    state = false;
  }

  /// Resets onboarding so user can go through the flow again
  Future<void> resetOnboarding() async {
    final repo = ref.read(localSettingsRepositoryProvider);
    await repo.resetOnboarding();
    state = true;
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
            onboardingCompletedAt: onboardingState.currentMilestoneStep >= 5
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
            onboardingCompletedAt: onboardingState.currentMilestoneStep >= 5
                ? DateTime.now()
                : null,
          );

      await userProfileRepo.updateProfile(updatedProfile);
      if (onboardingState.currentMilestoneStep >= 5) {
        await completeOnboarding();
      }
    }
  }

  List<String> _getSkippedStepsList(OnboardingState state) {
    final List<String> skipped = [];
    final stepNames = ['archetype', 'attributes', 'why', 'anchors', 'stacking'];
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
    if (milestoneIndex < 0 || milestoneIndex > 4) return;

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
    if (milestoneIndex < 0 || milestoneIndex > 4) return;

    final currentState = ref.read(onboardingStateProvider);
    final completed = List<bool>.from(currentState.completedMilestones);

    // Ensure list is long enough
    while (completed.length <= milestoneIndex) {
      completed.add(false);
    }
    completed[milestoneIndex] = true;

    final updatedState = currentState.copyWith(
      currentMilestoneStep: milestoneIndex + 1,
      completedMilestones: completed,
    );

    ref.read(onboardingStateProvider.notifier).update((state) => updatedState);

    // Save progress to user profile
    await saveOnboardingData();

    // Connect to gamification system by logging the milestone completion
    final user = ref.read(authStateChangesProvider).value;
    if (user != null) {
      try {
        final userStatsRepo = ref.read(userStatsRepositoryProvider);

        // Log the milestone completion activity
        await userStatsRepo.logActivity(
          userId: user.id,
          type: 'onboarding_milestone_completed',
          sourceId: 'milestone_$milestoneIndex',
          date: DateTime.now(),
        );

        // Update user stats to reflect progress
        final currentProfile = await userStatsRepo.getUserStats(user.id);
        final updatedProfile = currentProfile.copyWith(
          onboardingProgress: milestoneIndex + 1,
        );

        await userStatsRepo.saveUserStats(updatedProfile);
      } catch (e, stack) {
        AppLogger.e(
          'Error updating gamification stats for milestone completion',
          e,
          stack,
        );
      }
    }
  }

  Future<void> createOnboardingHabits() async {
    final state = ref.read(onboardingStateProvider);
    final user = ref.read(authStateChangesProvider).value;

    if (user == null || state.habitStacks.isEmpty) return;

    final habitRepo = ref.read(habitRepositoryProvider);
    final config = ref.read(remoteConfigServiceProvider).getOnboardingConfig();
    final suggestions = config.habitSuggestions;

    // Track created anchors to prevent duplicates: Map<AnchorSuggestionId, CreatedHabitId>
    final Map<String, String> createdAnchorMap = {};

    for (final stack in state.habitStacks) {
      final anchorSuggestion = suggestions.firstWhere(
        (s) => s.id == stack.anchorId,
        orElse: () => suggestions.first,
      );

      // 1. Create or Get existing Anchor Habit
      String realAnchorHabitId;
      if (createdAnchorMap.containsKey(anchorSuggestion.id)) {
        realAnchorHabitId = createdAnchorMap[anchorSuggestion.id]!;
      } else {
        realAnchorHabitId = const Uuid().v4();
        final anchorHabit = Habit(
          id: realAnchorHabitId,
          userId: user.id,
          title: anchorSuggestion.title,
          cue: 'My established routine',
          createdAt: DateTime.now(),
          difficulty: HabitDifficulty.easy,
          impact: HabitImpact.positive,
          attribute: HabitAttribute.vitality,
          isArchived: false,
          identityTags: ['anchor'],
        );

        final result = await habitRepo.createHabit(anchorHabit);
        result.fold(
          (failure) {
            AppLogger.e(
              'Failed to create onboarding anchor habit',
              failure,
              StackTrace.current,
            );
          },
          (_) {
            createdAnchorMap[anchorSuggestion.id] = realAnchorHabitId;

            // Connect to gamification system by logging the habit creation
            try {
              final userStatsRepo = ref.read(userStatsRepositoryProvider);
              userStatsRepo.logActivity(
                userId: user.id,
                type: 'habit_created',
                habitId: realAnchorHabitId,
                sourceId: 'onboarding',
                date: DateTime.now(),
              );
            } catch (e, stack) {
              AppLogger.e('Error logging habit creation activity', e, stack);
            }
          },
        );
      }

      // 2. Create Stack Habit linked to Anchor
      final newHabit = Habit(
        id: const Uuid().v4(),
        userId: user.id,
        title: stack.habitId,
        cue: 'After I ${anchorSuggestion.title}',
        anchorHabitId: realAnchorHabitId,
        createdAt: DateTime.now(),
        difficulty: HabitDifficulty.easy,
        impact: HabitImpact.positive,
        attribute: HabitAttribute.vitality,
        contractActive: false,
        isArchived: false,
      );

      final result = await habitRepo.createHabit(newHabit);
      result.fold(
        (failure) {
          AppLogger.e(
            'Failed to create onboarding stacked habit',
            failure,
            StackTrace.current,
          );
        },
        (_) {
          // Connect to gamification system by logging the habit creation
          try {
            final userStatsRepo = ref.read(userStatsRepositoryProvider);
            userStatsRepo.logActivity(
              userId: user.id,
              type: 'habit_created',
              habitId: newHabit.id,
              sourceId: 'onboarding_stack',
              date: DateTime.now(),
            );
          } catch (e, stack) {
            AppLogger.e(
              'Error logging stacked habit creation activity',
              e,
              stack,
            );
          }
        },
      );
    }
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
  final int currentMilestoneStep; // 0-5 (5-step flow)
  final List<bool>
  completedMilestones; // [archetype, attributes, why, anchors, stacking]
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
    this.completedMilestones = const [false, false, false, false, false],
    this.skippedMilestones = const [false, false, false, false, false],
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
/// Based on user's onboarding progress (0-5)
/// Returns empty list if onboarding is complete or if user profile isn't loaded
@riverpod
List<OnboardingMilestone> activeMilestones(Ref ref) {
  // Try userProfileProvider first, fall back to userStatsStreamProvider
  final userProfileAsync = ref.watch(userProfileProvider);
  final userStatsAsync = ref.watch(userStatsStreamProvider);

  // Get progress from either provider (prefer userProfile if available)
  int progress = 0;
  if (userProfileAsync.valueOrNull != null) {
    progress = userProfileAsync.valueOrNull?.onboardingProgress ?? 0;
  } else if (userStatsAsync.valueOrNull != null) {
    progress = userStatsAsync.valueOrNull?.onboardingProgress ?? 0;
  }

  // Define the 5 streamlined onboarding milestones
  // Note: Using null for backgroundImageUrl to use the gradient placeholder instead
  // of external network images which can fail to load and cause exceptions
  final allMilestones = [
    OnboardingMilestone(
      order: 1,
      title: 'Choose Your North Star',
      description:
          'Select the identity archetype that resonates with who you want to become',
      routePath: '/onboarding/archetype',
      icon: Icons.wb_sunny,
      isCompleted: progress > 0,
      canSkip: true,
      backgroundImageUrl: null, // Use gradient placeholder
    ),
    OnboardingMilestone(
      order: 2,
      title: 'Shape Your Identity',
      description: 'Allocate points to your core attributes',
      routePath: '/onboarding/attributes',
      icon: Icons.psychology,
      isCompleted: progress > 1,
      canSkip: true,
      backgroundImageUrl: null, // Use gradient placeholder
    ),
    OnboardingMilestone(
      order: 3,
      title: 'Integrate Your Why',
      description: 'Define your deep motivation',
      routePath: '/onboarding/why',
      icon: Icons.lightbulb,
      isCompleted: progress > 2,
      canSkip: true,
      backgroundImageUrl: null, // Use gradient placeholder
    ),
    OnboardingMilestone(
      order: 4,
      title: 'Map Your Day\'s Anchors',
      description: 'Identify existing routines to build new habits upon',
      routePath: '/onboarding/anchors',
      icon: Icons.anchor,
      isCompleted: progress > 3,
      canSkip: true,
      backgroundImageUrl: null, // Use gradient placeholder
    ),
    OnboardingMilestone(
      order: 5,
      title: 'Build Your Habit Chains',
      description: 'Create personalized habit stacks based on your archetype',
      routePath: '/onboarding/stacking',
      icon: Icons.link,
      isCompleted: progress > 4,
      canSkip: true,
      backgroundImageUrl: null, // Use gradient placeholder
    ),
  ];

  // Return only the current uncompleted milestone for active onboarding
  // If all milestones completed, return empty list
  if (progress >= 5) return [];

  // Return the next milestone to complete
  return [allMilestones[progress]];
}
