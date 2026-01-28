import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/gamification/data/repositories/user_stats_repository.dart';
import 'package:emerge_app/features/gamification/presentation/providers/gamification_providers.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/presentation/providers/dashboard_state_provider.dart';
import 'package:emerge_app/features/onboarding/data/services/remote_config_service.dart';
import 'package:emerge_app/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'onboarding_state_notifier.g.dart';

/// Enhanced Onboarding State with persistence and dashboard sync
class EnhancedOnboardingState extends Equatable {
  /// Selected archetype (identity foundation)
  final UserArchetype? selectedArchetype;

  /// Attribute point distribution
  final Map<String, int> attributes;

  /// Remaining points to allocate
  final int remainingPoints;

  /// User's core motivation
  final String? motive;

  /// User's deep "why" statement
  final String? why;

  /// Selected anchor routines
  final List<String> anchors;

  /// Created habit stacks
  final List<HabitStack> habitStacks;

  /// Current milestone step (0-5)
  final int currentStep;

  /// Completed milestones tracking
  final List<bool> completedMilestones;

  /// Skipped milestones tracking
  final List<bool> skippedMilestones;

  /// Whether onboarding is in progress
  final bool isOnboardingActive;

  /// Whether data is being saved
  final bool isSaving;

  /// Error message if any
  final String? error;

  const EnhancedOnboardingState({
    this.selectedArchetype,
    this.attributes = const {
      'Vitality': 0,
      'Focus': 0,
      'Creativity': 0,
      'Strength': 0,
      'Spirit': 0,
    },
    this.remainingPoints = 10,
    this.motive,
    this.why,
    this.anchors = const [],
    this.habitStacks = const [],
    this.currentStep = 0,
    this.completedMilestones = const [false, false, false, false, false],
    this.skippedMilestones = const [false, false, false, false, false],
    this.isOnboardingActive = true,
    this.isSaving = false,
    this.error,
  });

  /// Check if onboarding is complete
  bool get isComplete => currentStep >= 5;

  /// Get progress percentage
  double get progressPercentage => currentStep / 5.0;

  /// Check if a specific milestone can be skipped
  bool canSkipMilestone(int index) {
    if (index < 0 || index >= 5) return false;
    // All milestones are skippable in this flow
    return true;
  }

  /// Get the next uncompleted milestone index
  int get nextMilestoneIndex {
    for (int i = 0; i < 5; i++) {
      if (!completedMilestones[i] && !skippedMilestones[i]) {
        return i;
      }
    }
    return 5; // All complete
  }

  EnhancedOnboardingState copyWith({
    UserArchetype? selectedArchetype,
    Map<String, int>? attributes,
    int? remainingPoints,
    String? motive,
    String? why,
    List<String>? anchors,
    List<HabitStack>? habitStacks,
    int? currentStep,
    List<bool>? completedMilestones,
    List<bool>? skippedMilestones,
    bool? isOnboardingActive,
    bool? isSaving,
    String? error,
  }) {
    return EnhancedOnboardingState(
      selectedArchetype: selectedArchetype ?? this.selectedArchetype,
      attributes: attributes ?? this.attributes,
      remainingPoints: remainingPoints ?? this.remainingPoints,
      motive: motive ?? this.motive,
      why: why ?? this.why,
      anchors: anchors ?? this.anchors,
      habitStacks: habitStacks ?? this.habitStacks,
      currentStep: currentStep ?? this.currentStep,
      completedMilestones: completedMilestones ?? this.completedMilestones,
      skippedMilestones: skippedMilestones ?? this.skippedMilestones,
      isOnboardingActive: isOnboardingActive ?? this.isOnboardingActive,
      isSaving: isSaving ?? this.isSaving,
      error: error,
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
    currentStep,
    completedMilestones,
    skippedMilestones,
    isOnboardingActive,
    isSaving,
    error,
  ];
}

/// Enhanced Onboarding State Notifier with dashboard sync
@Riverpod(keepAlive: true)
class EnhancedOnboardingNotifier extends _$EnhancedOnboardingNotifier {
  @override
  EnhancedOnboardingState build() {
    // Check if user has completed onboarding
    final localSettings = ref.read(localSettingsRepositoryProvider);
    final isFirstLaunch = localSettings.isFirstLaunch;

    // Try to restore state from user profile
    final profile = ref.read(userProfileProvider).valueOrNull;

    if (profile != null && !isFirstLaunch) {
      final progress = profile.onboardingProgress;
      return EnhancedOnboardingState(
        selectedArchetype: profile.archetype,
        why: profile.why,
        currentStep: progress,
        isOnboardingActive: progress < 5,
      );
    }

    return EnhancedOnboardingState(isOnboardingActive: isFirstLaunch);
  }

  /// Select an archetype (Milestone 1)
  void selectArchetype(UserArchetype archetype) {
    state = state.copyWith(selectedArchetype: archetype);

    // Sync to dashboard immediately
    _syncToDashboard();
  }

  /// Update attribute points (Milestone 2)
  void updateAttribute(String attribute, int delta) {
    final current = state.attributes[attribute] ?? 0;
    final newValue = (current + delta).clamp(0, 10);

    if (delta > 0 && state.remainingPoints <= 0) return;
    if (delta < 0 && current <= 0) return;

    final newAttributes = Map<String, int>.from(state.attributes);
    newAttributes[attribute] = newValue;

    final pointsDelta = newValue - current;
    final newRemaining = state.remainingPoints - pointsDelta;

    state = state.copyWith(
      attributes: newAttributes,
      remainingPoints: newRemaining,
    );

    _syncToDashboard();
  }

  /// Set the user's "why" statement (Milestone 3)
  void setWhy(String why) {
    state = state.copyWith(why: why);
    _syncToDashboard();
  }

  /// Set the user's motive
  void setMotive(String motive) {
    state = state.copyWith(motive: motive);
  }

  /// Add an anchor routine (Milestone 4)
  void addAnchor(String anchor) {
    if (!state.anchors.contains(anchor)) {
      state = state.copyWith(anchors: [...state.anchors, anchor]);
    }
  }

  /// Remove an anchor routine
  void removeAnchor(String anchor) {
    state = state.copyWith(
      anchors: state.anchors.where((a) => a != anchor).toList(),
    );
  }

  /// Add a habit stack (Milestone 5)
  void addHabitStack(HabitStack stack) {
    state = state.copyWith(habitStacks: [...state.habitStacks, stack]);
  }

  /// Remove a habit stack
  void removeHabitStack(String stackId) {
    state = state.copyWith(
      habitStacks: state.habitStacks
          .where((s) => s.anchorId != stackId)
          .toList(),
    );
  }

  /// Complete a milestone and sync to backend + dashboard
  Future<void> completeMilestone(int milestoneIndex) async {
    if (milestoneIndex < 0 || milestoneIndex > 4) return;

    state = state.copyWith(isSaving: true, error: null);

    try {
      // Update completed milestones
      final completed = List<bool>.from(state.completedMilestones);
      while (completed.length <= milestoneIndex) {
        completed.add(false);
      }
      completed[milestoneIndex] = true;

      state = state.copyWith(
        currentStep: milestoneIndex + 1,
        completedMilestones: completed,
        isSaving: false,
      );

      // Sync to legacy onboarding state for backward compatibility
      _syncToLegacyProvider();

      // Persist to backend
      await _persistToBackend();

      // Sync to dashboard
      _syncToDashboard();

      // Log activity for gamification
      await _logMilestoneActivity(milestoneIndex);

      AppLogger.i('Milestone $milestoneIndex completed');
    } catch (e, s) {
      AppLogger.e('Failed to complete milestone', e, s);
      state = state.copyWith(
        isSaving: false,
        error: 'Failed to save progress: ${e.toString()}',
      );
    }
  }

  /// Skip a milestone
  Future<void> skipMilestone(int milestoneIndex) async {
    if (milestoneIndex < 0 || milestoneIndex > 4) return;

    state = state.copyWith(isSaving: true, error: null);

    try {
      final skipped = List<bool>.from(state.skippedMilestones);
      while (skipped.length <= milestoneIndex) {
        skipped.add(false);
      }
      skipped[milestoneIndex] = true;

      state = state.copyWith(
        currentStep: milestoneIndex + 1,
        skippedMilestones: skipped,
        isSaving: false,
      );

      _syncToLegacyProvider();
      await _persistToBackend();

      AppLogger.i('Milestone $milestoneIndex skipped');
    } catch (e, s) {
      AppLogger.e('Failed to skip milestone', e, s);
      state = state.copyWith(
        isSaving: false,
        error: 'Failed to save progress: ${e.toString()}',
      );
    }
  }

  /// Complete onboarding and create habits from stacks
  Future<void> completeOnboarding() async {
    // Update state FIRST so router sees onboarding is complete
    state = state.copyWith(
      isOnboardingActive: false,
      currentStep: 5,
      isSaving: false,
    );

    // Sync to dashboard immediately
    _syncToDashboard();

    try {
      // Create habits from habit stacks
      await _createHabitsFromStacks();

      // Mark onboarding as complete locally
      final localSettings = ref.read(localSettingsRepositoryProvider);
      await localSettings.completeOnboarding();

      // Persist final state
      await _persistToBackend();

      AppLogger.i('Onboarding completed successfully');
    } catch (e, s) {
      AppLogger.e('Failed to complete onboarding', e, s);
      state = state.copyWith(
        error: 'Failed to complete onboarding: ${e.toString()}',
      );
    }
  }

  /// Create habits from the configured habit stacks
  Future<void> _createHabitsFromStacks() async {
    final user = ref.read(authStateChangesProvider).value;
    if (user == null) return;

    final dashboardNotifier = ref.read(dashboardStateNotifierProvider.notifier);
    final config = ref.read(remoteConfigServiceProvider).getOnboardingConfig();
    final suggestions = config.habitSuggestions;

    for (final stack in state.habitStacks) {
      final anchorSuggestion = suggestions.firstWhere(
        (s) => s.id == stack.anchorId,
        orElse: () => suggestions.first,
      );

      final habit = Habit(
        id: const Uuid().v4(),
        userId: user.id,
        title: stack.habitId,
        cue: 'After I ${anchorSuggestion.title}',
        createdAt: DateTime.now(),
        difficulty: HabitDifficulty.easy,
        attribute: HabitAttribute.vitality,
        identityTags: ['onboarding', state.selectedArchetype?.name ?? ''],
      );

      // Use optimistic creation through dashboard
      await dashboardNotifier.createHabitOptimistic(habit);
    }
  }

  /// Sync state to the legacy onboarding provider for backward compatibility
  void _syncToLegacyProvider() {
    ref
        .read(onboardingStateProvider.notifier)
        .update(
          (legacyState) => legacyState.copyWith(
            selectedArchetype: state.selectedArchetype,
            attributes: state.attributes,
            remainingPoints: state.remainingPoints,
            motive: state.motive,
            why: state.why,
            anchors: state.anchors,
            habitStacks: state.habitStacks,
            currentMilestoneStep: state.currentStep,
            completedMilestones: state.completedMilestones,
            skippedMilestones: state.skippedMilestones,
          ),
        );
  }

  /// Sync to dashboard state notifier
  void _syncToDashboard() {
    // Convert to OnboardingState format for dashboard sync
    final onboardingState = OnboardingState(
      selectedArchetype: state.selectedArchetype,
      attributes: state.attributes,
      remainingPoints: state.remainingPoints,
      motive: state.motive,
      why: state.why,
      anchors: state.anchors,
      habitStacks: state.habitStacks,
      currentMilestoneStep: state.currentStep,
      completedMilestones: state.completedMilestones,
      skippedMilestones: state.skippedMilestones,
    );

    ref
        .read(dashboardStateNotifierProvider.notifier)
        .syncOnboardingState(onboardingState);
  }

  /// Persist state to backend (Firestore)
  Future<void> _persistToBackend() async {
    final user = ref.read(authStateChangesProvider).value;
    if (user?.isNotEmpty != true) return;

    final userProfileRepo = ref.read(userProfileRepositoryProvider);
    final existingProfile = await ref.read(userProfileProvider.future);

    final updatedProfile =
        existingProfile?.copyWith(
          archetype: state.selectedArchetype ?? UserArchetype.none,
          motive: state.motive,
          why: state.why,
          anchors: state.anchors,
          habitStacks: state.habitStacks,
          onboardingProgress: state.currentStep,
          skippedOnboardingSteps: _getSkippedStepNames(),
          onboardingCompletedAt: state.currentStep >= 5 ? DateTime.now() : null,
        ) ??
        UserProfile(
          uid: user!.id,
          archetype: state.selectedArchetype ?? UserArchetype.none,
          motive: state.motive,
          why: state.why,
          anchors: state.anchors,
          habitStacks: state.habitStacks,
          onboardingProgress: state.currentStep,
          skippedOnboardingSteps: _getSkippedStepNames(),
          onboardingStartedAt: DateTime.now(),
          onboardingCompletedAt: state.currentStep >= 5 ? DateTime.now() : null,
        );

    await userProfileRepo.updateProfile(updatedProfile);
  }

  List<String> _getSkippedStepNames() {
    final stepNames = ['archetype', 'attributes', 'why', 'anchors', 'stacking'];
    final skipped = <String>[];
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

  Future<void> _logMilestoneActivity(int milestoneIndex) async {
    final user = ref.read(authStateChangesProvider).value;
    if (user?.isNotEmpty != true) return;

    try {
      final userStatsRepo = ref.read(userStatsRepositoryProvider);
      await userStatsRepo.logActivity(
        userId: user!.id,
        type: 'onboarding_milestone_completed',
        sourceId: 'milestone_$milestoneIndex',
        date: DateTime.now(),
      );
    } catch (e, s) {
      AppLogger.e('Failed to log milestone activity', e, s);
    }
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Reset onboarding (for testing or re-onboarding)
  Future<void> resetOnboarding() async {
    final localSettings = ref.read(localSettingsRepositoryProvider);
    await localSettings.resetOnboarding();

    state = const EnhancedOnboardingState();
  }
}

/// Provider for checking if onboarding is active
@riverpod
bool isOnboardingActive(Ref ref) {
  final state = ref.watch(enhancedOnboardingNotifierProvider);
  return state.isOnboardingActive;
}

/// Provider for onboarding progress percentage
@riverpod
double onboardingProgress(Ref ref) {
  final state = ref.watch(enhancedOnboardingNotifierProvider);
  return state.progressPercentage;
}
