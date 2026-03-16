import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:emerge_app/features/onboarding/data/repositories/local_settings_repository.dart';

part 'tutorial_provider.g.dart';

/// Supported tutorial IDs
enum TutorialStep {
  timeline,
  worldMap,
  profile,
  community,
  createHabit,
  insights,
  aiCoach,
  gamification,
  challenges,
  friends,
}

/// State for tracking completed tutorials
class TutorialState {
  final Map<TutorialStep, bool> completedSteps;
  final bool enabled;
  final bool autoShow;

  const TutorialState({
    this.completedSteps = const {},
    this.enabled = false,
    this.autoShow = false,
  });

  bool isCompleted(TutorialStep step) => completedSteps[step] ?? false;

  TutorialState copyWith({
    Map<TutorialStep, bool>? completedSteps,
    bool? enabled,
    bool? autoShow,
  }) {
    return TutorialState(
      completedSteps: completedSteps ?? this.completedSteps,
      enabled: enabled ?? this.enabled,
      autoShow: autoShow ?? this.autoShow,
    );
  }
}

final localSettingsRepositoryProvider = Provider<LocalSettingsRepository>((
  ref,
) {
  return LocalSettingsRepository();
});

/// Provider for managing tutorial state
@Riverpod(keepAlive: true)
class TutorialNotifier extends _$TutorialNotifier {
  LocalSettingsRepository get _repository =>
      ref.read(localSettingsRepositoryProvider);

  @override
  TutorialState build() {
    // Load initial state synchronously
    final completed = <TutorialStep, bool>{};
    for (final step in TutorialStep.values) {
      completed[step] = _repository.isTutorialCompleted(step.name);
    }

    return TutorialState(
      completedSteps: completed,
      enabled: _repository.tutorialsEnabled,
      autoShow: _repository.tutorialAutoShow,
    );
  }

  Future<void> completeStep(TutorialStep step) async {
    if (state.isCompleted(step)) return;

    await _repository.completeTutorial(step.name);
    // Disable auto-show after completing a tutorial (one-time show per screen visit)
    await _repository.disableTutorialAutoShow();
    state = state.copyWith(
      completedSteps: {...state.completedSteps, step: true},
      autoShow: false,
    );
  }

  Future<void> resetTutorials() async {
    await _repository.resetTutorials();
    // Reload state after reset
    final completed = <TutorialStep, bool>{};
    for (final step in TutorialStep.values) {
      completed[step] = _repository.isTutorialCompleted(step.name);
    }
    state = TutorialState(
      completedSteps: completed,
      enabled: _repository.tutorialsEnabled,
      autoShow: _repository.tutorialAutoShow,
    );
  }

  Future<void> setTutorialsEnabled(bool enabled) async {
    await _repository.setTutorialsEnabled(enabled);
    // Reload state to ensure sync with repository
    final completed = <TutorialStep, bool>{};
    for (final step in TutorialStep.values) {
      completed[step] = _repository.isTutorialCompleted(step.name);
    }
    state = TutorialState(
      completedSteps: completed,
      enabled: _repository.tutorialsEnabled,
      autoShow: _repository.tutorialAutoShow,
    );
  }

  /// Re-enable auto-show for tutorials (called when navigating to a new screen)
  Future<void> enableTutorialAutoShow() async {
    if (!state.enabled) return;
    await _repository.enableTutorialAutoShow();
    state = state.copyWith(autoShow: true);
  }

  /// Check if tutorial should auto-show on current screen visit
  bool shouldShowTutorial() {
    return state.enabled && state.autoShow;
  }
}
