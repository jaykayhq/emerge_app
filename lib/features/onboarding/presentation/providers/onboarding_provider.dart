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
import 'package:emerge_app/features/habits/presentation/providers/dashboard_state_provider.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';
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
    // Update state FIRST so router sees onboarding is complete
    state = false;

    final repo = ref.read(localSettingsRepositoryProvider);
    await repo.completeOnboarding();

    // Also update user stats to reflect onboarding completion
    final userAsync = ref.read(authStateChangesProvider);
    final user = userAsync.value;
    if (user?.isNotEmpty == true) {
      try {
        final userProfileRepo = ref.read(userProfileRepositoryProvider);
        final userStatsRepo = ref.read(userStatsRepositoryProvider);

        // Get current profile
        final profileResult = await userProfileRepo.getProfile(user!.id);
        final currentProfile = profileResult.fold(
          (failure) => UserProfile(uid: user.id),
          (profile) => profile,
        );

        // Update the profile to mark onboarding as complete
        final updatedProfile = currentProfile.copyWith(
          onboardingProgress:
              4, // Mark as completed (3 pre-reveal steps + reveal)
          onboardingCompletedAt: DateTime.now(),
        );

        // SYNC: Atomically save to both users and user_stats collections
        await userStatsRepo.syncUserIdentity(updatedProfile);

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
  }

  /// Resets onboarding so user can go through the flow again
  Future<void> resetOnboarding() async {
    final repo = ref.read(localSettingsRepositoryProvider);
    await repo.resetOnboarding();
    state = true;
  }

  Future<void> saveOnboardingData() async {
    final onboardingState = ref.read(onboardingStateControllerProvider);
    final userAsync = ref.read(authStateChangesProvider);
    final user = userAsync.value;

    if (user?.isNotEmpty == true) {
      final userProfileRepo = ref.read(userProfileRepositoryProvider);

      // Fetch existing profile directly from repository (not provider) to avoid disposal issues
      // The provider might be disposed during navigation, but repository always works
      final existingProfileResult = await userProfileRepo.getProfile(user!.id);

      // Get existing profile or use onboarding state as source of truth
      final UserProfile? existingProfile = existingProfileResult.fold(
        (failure) => null,
        (profile) => profile,
      );

      // Prefer onboarding state values (most recent user selections) over stored values
      final updatedProfile =
          existingProfile?.copyWith(
            archetype:
                onboardingState.selectedArchetype ?? existingProfile.archetype,
            motive: onboardingState.motive ?? existingProfile.motive,
            why: onboardingState.why ?? existingProfile.why,
            anchors: onboardingState.anchors.isNotEmpty
                ? onboardingState.anchors
                : existingProfile.anchors,
            habitStacks: onboardingState.habitStacks.isNotEmpty
                ? onboardingState.habitStacks
                : existingProfile.habitStacks,
            onboardingProgress: onboardingState.currentMilestoneStep,
            skippedOnboardingSteps: _getSkippedStepsList(onboardingState),
            onboardingCompletedAt: onboardingState.currentMilestoneStep >= 4
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
            onboardingCompletedAt: onboardingState.currentMilestoneStep >= 4
                ? DateTime.now()
                : null,
          );

      // SYNC: Atomically save to both users and user_stats collections
      final userStatsRepo = ref.read(userStatsRepositoryProvider);
      await userStatsRepo.syncUserIdentity(updatedProfile);

      if (onboardingState.currentMilestoneStep >= 4) {
        // Officially join the archetype club
        if (updatedProfile.archetype != UserArchetype.none) {
          try {
            final tribeRepo = ref.read(tribeRepositoryProvider);
            final club = await tribeRepo.getArchetypeClub(
              updatedProfile.archetype.name,
            );
            debugPrint(
              '🔍 Looking for club for archetype: ${updatedProfile.archetype.name}',
            );
            if (club != null) {
              debugPrint(
                '🔍 Found club: ${club.id}, joining user ${user.id}...',
              );
              await tribeRepo.joinClub(user.id, club.id);
              debugPrint('✅ Successfully joined club ${club.id}');
            } else {
              debugPrint(
                '❌ Club not found for archetype: ${updatedProfile.archetype.name}',
              );
            }
          } catch (e, stack) {
            AppLogger.e(
              'Failed to join official club during onboarding',
              e,
              stack,
            );
            debugPrint('❌ Stack trace: $stack');
          }
        }
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
    if (milestoneIndex < 0 || milestoneIndex > 3) return;

    final currentState = ref.read(onboardingStateControllerProvider);
    final skipped = List<bool>.from(currentState.skippedMilestones);

    // Ensure list is long enough
    while (skipped.length <= milestoneIndex) {
      skipped.add(false);
    }
    skipped[milestoneIndex] = true;

    ref
        .read(onboardingStateControllerProvider.notifier)
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
    if (milestoneIndex < 0 || milestoneIndex > 3) return;

    final currentState = ref.read(onboardingStateControllerProvider);
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

    ref
        .read(onboardingStateControllerProvider.notifier)
        .update((state) => updatedState);

    // Save progress to user profile (includes archetype, motive, progress, etc.)
    // Uses atomic batch write to both users and user_stats under the hood
    await saveOnboardingData();

    // Connect to gamification system by logging the milestone completion
    final user = ref.read(authStateChangesProvider).value;
    if (user?.isNotEmpty == true) {
      try {
        final userStatsRepo = ref.read(userStatsRepositoryProvider);

        // Log the milestone completion activity
        await userStatsRepo.logActivity(
          userId: user!.id,
          type: 'onboarding_milestone_completed',
          sourceId: 'milestone_$milestoneIndex',
          date: DateTime.now(),
        );

        AppLogger.i('Milestone $milestoneIndex completed');
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
    final state = ref.read(onboardingStateControllerProvider);
    final user = ref.read(authStateChangesProvider).value;

    if (user?.isNotEmpty == true && state.habitStacks.isNotEmpty) {
      // Use DashboardNotifier for optimistic updates
      final dashboardNotifier = ref.read(dashboardStateProvider.notifier);
      // We only create one habit per stack (the action). The anchor is treated as a cue.
      for (int i = 0; i < state.habitStacks.length; i++) {
        final stack = state.habitStacks[i];
        final anchorText = state.anchors.length > i
            ? state.anchors[i]
            : 'After waking up';

        // Map anchor text to TimeOfDayPreference and specify default times
        TimeOfDayPreference tdp = TimeOfDayPreference.morning;
        TimeOfDay? reminderTime;

        final lowerAnchor = anchorText.toLowerCase();
        if (lowerAnchor.contains('wake') || lowerAnchor.contains('morning')) {
          tdp = TimeOfDayPreference.morning;
          reminderTime = const TimeOfDay(hour: 8, minute: 0);
        } else if (lowerAnchor.contains('lunch') ||
            lowerAnchor.contains('afternoon')) {
          tdp = TimeOfDayPreference.afternoon;
          reminderTime = const TimeOfDay(hour: 12, minute: 0);
        } else if (lowerAnchor.contains('bed') ||
            lowerAnchor.contains('evening') ||
            lowerAnchor.contains('night')) {
          tdp = TimeOfDayPreference.evening;
          reminderTime = const TimeOfDay(hour: 21, minute: 0);
        } else if (lowerAnchor.contains('work')) {
          // Explicitly map After work to Evening as requested
          tdp = TimeOfDayPreference.evening;
          reminderTime = const TimeOfDay(hour: 18, minute: 0);
        }

        // Map attribute based on archetype for consistent coloring
        HabitAttribute attribute = HabitAttribute.vitality;
        final archetype = state.selectedArchetype ?? UserArchetype.athlete;
        switch (archetype) {
          case UserArchetype.athlete:
            attribute = HabitAttribute.vitality;
            break;
          case UserArchetype.scholar:
            attribute = HabitAttribute.focus;
            break;
          case UserArchetype.creator:
            attribute = HabitAttribute.creativity;
            break;
          case UserArchetype.stoic:
            attribute = HabitAttribute.focus;
            break;
          case UserArchetype.zealot:
            attribute = HabitAttribute.spirit;
            break;
          default:
            attribute = HabitAttribute.vitality;
        }

        // Create the Habit linked to the anchor text (cue)
        // We do NOT create a separate habit for the anchor itself as it's an existing routine
        final newHabit = Habit(
          id: const Uuid().v4(),
          userId: user!.id,
          title: stack
              .habitId, // This is now the description/action from FirstHabitScreen
          cue: 'After I $anchorText',
          createdAt: DateTime.now(),
          difficulty: HabitDifficulty.easy,
          impact: HabitImpact.positive,
          attribute: attribute,
          contractActive: false,
          isArchived: false,
          timeOfDayPreference: tdp,
          reminderTime: reminderTime,
          identityTags: ['onboarding'], // Tag for limit bypass
        );

        try {
          await dashboardNotifier.createHabitOptimistic(newHabit);

          // Log activity
          final userStatsRepo = ref.read(userStatsRepositoryProvider);
          await userStatsRepo.logActivity(
            userId: user.id,
            type: 'habit_created',
            habitId: newHabit.id,
            sourceId: 'onboarding',
            date: DateTime.now(),
          );
        } catch (e) {
          AppLogger.e(
            'Failed to create onboarding habit',
            e,
            StackTrace.current,
          );
        }
      }

      // Force refresh of habits after creating onboarding habits
      // This ensures the dashboard gets updated with the newly created habits
      ref.invalidate(habitsProvider);
    }
  }
}

class OnboardingState extends Equatable {
  final UserArchetype? selectedArchetype;
  final String? archetypeAvatarUrl; // Avatar image URL for selected archetype
  final Map<String, int> attributes;
  final int remainingPoints;
  final String? motive;
  final String? why;
  final List<String> anchors;
  final List<HabitStack> habitStacks;
  final int
  currentMilestoneStep; // 0-3 (3-step flow: identity, first-habit, world-reveal)
  final List<bool>
  completedMilestones; // [archetype, attributes, first_habit, world_reveal]
  final List<bool> skippedMilestones; // Track which steps user skipped

  const OnboardingState({
    this.selectedArchetype,
    this.archetypeAvatarUrl,
    this.attributes = const {
      'Vitality': 0,
      'Focus': 0,
      'Creativity': 0,
      'Strength': 0,
      'Spirit': 0,
      'Intellect': 0,
    },
    this.remainingPoints = 15,
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
    String? archetypeAvatarUrl,
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
      archetypeAvatarUrl: archetypeAvatarUrl ?? this.archetypeAvatarUrl,
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
    archetypeAvatarUrl,
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

@Riverpod(keepAlive: true)
class OnboardingStateController extends _$OnboardingStateController {
  @override
  OnboardingState build() => const OnboardingState();

  void updateState(OnboardingState newState) => state = newState;

  // Riverpod 3.x: update method for compatibility with existing code
  void update(OnboardingState Function(OnboardingState) fn) =>
      state = fn(state);
}

// Keep legacy providers for backward compatibility if needed, or refactor screens to use onboardingStateControllerProvider
final selectedArchetypeProvider = Provider<UserArchetype?>((ref) {
  return ref.watch(onboardingStateControllerProvider).selectedArchetype;
});

final attributePointsProvider = Provider<int>((ref) {
  return ref.watch(onboardingStateControllerProvider).remainingPoints;
});

final attributesProvider = Provider<Map<String, int>>((ref) {
  return ref.watch(onboardingStateControllerProvider).attributes;
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
  if (userProfileAsync.value != null) {
    progress = userProfileAsync.value?.onboardingProgress ?? 0;
  } else if (userStatsAsync.value != null) {
    progress = userStatsAsync.value?.onboardingProgress ?? 0;
  }

  // Define the 4 steps in the flow
  // 1. Identity Select (Identity Studio Page 0)
  // 2. Motive Select (Identity Studio Page 1)
  // 3. First Identity Vote (First Habit Screen)
  // 4. Reveal Your World (World Reveal Screen)
  final allMilestones = [
    OnboardingMilestone(
      order: 1,
      title: 'Define Your Archetype',
      description: 'Select the identity that resonates with you',
      routePath: '/onboarding/identity-studio',
      icon: Icons.person_outline,
      isCompleted: progress > 0,
      canSkip: false,
      backgroundImageUrl: null,
    ),
    OnboardingMilestone(
      order: 2,
      title: 'Find Your Motive',
      description: 'Why do you want to embark on this journey?',
      routePath: '/onboarding/identity-studio',
      icon: Icons.auto_awesome,
      isCompleted: progress > 1,
      canSkip: false,
      backgroundImageUrl: null,
    ),
    OnboardingMilestone(
      order: 3,
      title: 'Your First Identity Vote',
      description: 'Prove to yourself you are becoming who you aspire to be',
      routePath: '/onboarding/first-habit',
      icon: Icons.check_circle_outline,
      isCompleted: progress > 2,
      canSkip: true,
      backgroundImageUrl: null,
    ),
    OnboardingMilestone(
      order: 4,
      title: 'Reveal Your World',
      description: 'Step into the realm you have forged',
      routePath: '/onboarding/world-reveal',
      icon: Icons.public,
      isCompleted: progress > 3,
      canSkip: false,
      backgroundImageUrl: null,
    ),
  ];

  // If all milestones completed, return empty list
  if (progress >= 4) return [];

  // Return the next milestone to complete
  return [allMilestones[progress]];
}
