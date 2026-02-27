import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/features/onboarding/data/repositories/local_settings_repository.dart';

/// Supported tutorial IDs
enum TutorialStep {
  timeline,
  worldMap,
  profile,
  community,
  createHabit,
}

/// State for tracking completed tutorials
class TutorialState {
  final Map<TutorialStep, bool> completedSteps;

  const TutorialState({this.completedSteps = const {}});

  bool isCompleted(TutorialStep step) => completedSteps[step] ?? false;

  TutorialState copyWith({Map<TutorialStep, bool>? completedSteps}) {
    return TutorialState(completedSteps: completedSteps ?? this.completedSteps);
  }
}

/// Provider for managing tutorial state
class TutorialNotifier extends StateNotifier<TutorialState> {
  final LocalSettingsRepository _repository;

  TutorialNotifier(this._repository) : super(const TutorialState()) {
    _loadState();
  }

  void _loadState() {
    final completed = <TutorialStep, bool>{};
    for (final step in TutorialStep.values) {
      completed[step] = _repository.isTutorialCompleted(step.name);
    }
    state = TutorialState(completedSteps: completed);
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
    state = const TutorialState();
  }
}

final localSettingsRepositoryProvider = Provider<LocalSettingsRepository>((
  ref,
) {
  return LocalSettingsRepository();
});

final tutorialProvider = StateNotifierProvider<TutorialNotifier, TutorialState>(
  (ref) {
    final repository = ref.watch(localSettingsRepositoryProvider);
    return TutorialNotifier(repository);
  },
);
