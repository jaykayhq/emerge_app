import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:emerge_app/features/onboarding/data/repositories/local_settings_repository.dart';

part 'tutorial_provider.g.dart';

/// Supported tutorial IDs
enum TutorialStep { timeline, worldMap, profile, community, createHabit }

/// State for tracking completed tutorials
class TutorialState {
  final Map<TutorialStep, bool> completedSteps;
  final bool enabled;

  const TutorialState({
    this.completedSteps = const {},
    this.enabled = false,
  });

  bool isCompleted(TutorialStep step) => completedSteps[step] ?? false;

  TutorialState copyWith({
    Map<TutorialStep, bool>? completedSteps,
    bool? enabled,
  }) {
    return TutorialState(
      completedSteps: completedSteps ?? this.completedSteps,
      enabled: enabled ?? this.enabled,
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
    );
  }

  Future<void> completeStep(TutorialStep step) async {
    if (state.isCompleted(step)) return;

    await _repository.completeTutorial(step.name);
    state = state.copyWith(
      completedSteps: {...state.completedSteps, step: true},
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
    );
  }
}
