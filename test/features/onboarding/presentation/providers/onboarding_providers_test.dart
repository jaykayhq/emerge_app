import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:emerge_app/features/onboarding/presentation/providers/onboarding_state_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

ProviderContainer _makeContainer({
  OnboardingState? onboardingState,
}) {
  return ProviderContainer(
    overrides: [
      if (onboardingState != null)
        onboardingStateControllerProvider.overrideWithValue(onboardingState),
    ],
  );
}

void main() {
  group('onboardingStateControllerProvider', () {
    test('initial state has correct defaults', () {
      final container = ProviderContainer(
        overrides: [
          onboardingStateControllerProvider.overrideWithValue(
            const OnboardingState(),
          ),
        ],
      );
      final state = container.read(onboardingStateControllerProvider);
      expect(state.selectedArchetype, isNull);
      expect(state.remainingPoints, 15);
      expect(state.currentMilestoneStep, 0);
      container.dispose();
    });

    test('updateState replaces state', () {
      final container = ProviderContainer();
      container
          .read(onboardingStateControllerProvider.notifier)
          .updateState(const OnboardingState(currentMilestoneStep: 2));
      expect(
        container.read(onboardingStateControllerProvider).currentMilestoneStep,
        2,
      );
      container.dispose();
    });
  });

  group('selectedArchetypeProvider', () {
    test('returns selected archetype from state', () {
      final container = _makeContainer(
        onboardingState:
            const OnboardingState(selectedArchetype: UserArchetype.creator),
      );
      expect(container.read(selectedArchetypeProvider), UserArchetype.creator);
      container.dispose();
    });

    test('returns null when not selected', () {
      final container = _makeContainer(
        onboardingState: const OnboardingState(),
      );
      expect(container.read(selectedArchetypeProvider), isNull);
      container.dispose();
    });
  });

  group('attributePointsProvider', () {
    test('returns remaining points', () {
      final container = _makeContainer(
        onboardingState: const OnboardingState(remainingPoints: 10),
      );
      expect(container.read(attributePointsProvider), 10);
      container.dispose();
    });
  });

  group('attributesProvider', () {
    test('returns attribute map', () {
      final attrs = {'Strength': 5, 'Vitality': 5};
      final container = _makeContainer(
        onboardingState: OnboardingState(attributes: attrs),
      );
      expect(container.read(attributesProvider), attrs);
      container.dispose();
    });
  });

  group('activeMilestonesProvider', () {
    test('returns first milestone when progress is 0', () {
      final container = ProviderContainer(overrides: [
        userStatsStreamProvider.overrideWithValue(
          AsyncValue.data(
            const UserProfile(uid: 'test', onboardingProgress: 0),
          ),
        ),
      ]);
      final milestones = container.read(activeMilestonesProvider);
      expect(milestones.length, 1);
      expect(milestones[0].order, 1);
      container.dispose();
    });

    test('returns empty list when progress >= 4', () {
      final container = ProviderContainer(overrides: [
        userStatsStreamProvider.overrideWithValue(
          AsyncValue.data(
            const UserProfile(uid: 'test', onboardingProgress: 4),
          ),
        ),
      ]);
      expect(container.read(activeMilestonesProvider), []);
      container.dispose();
    });
  });

  group('isOnboardingActiveProvider', () {
    test('returns value from enhancedOnboardingProvider', () {
      final container = ProviderContainer(overrides: [
        enhancedOnboardingProvider.overrideWithValue(
          const EnhancedOnboardingState(isOnboardingActive: true),
        ),
      ]);
      expect(container.read(isOnboardingActiveProvider), true);
      container.dispose();
    });
  });

  group('onboardingProgressProvider', () {
    test('returns progress value', () {
      final container = ProviderContainer(overrides: [
        enhancedOnboardingProvider.overrideWithValue(
          const EnhancedOnboardingState(currentStep: 2),
        ),
      ]);
      expect(container.read(onboardingProgressProvider), 2 / 5);
      container.dispose();
    });
  });
}
