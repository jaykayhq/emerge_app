import 'package:emerge_app/features/auth/domain/entities/auth_user.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/core/drift/database.dart';
import 'package:emerge_app/core/drift_repositories/repositories_barrel.dart';
import 'package:emerge_app/core/sync/sync_engine.dart';
import 'package:emerge_app/core/sync/sync_providers.dart';
import 'package:emerge_app/features/gamification/data/repositories/user_stats_repository.dart';
import 'package:emerge_app/features/gamification/presentation/providers/gamification_providers.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/domain/repositories/habit_repository.dart';
import 'package:emerge_app/features/habits/presentation/providers/dashboard_state_provider.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:emerge_app/features/onboarding/domain/entities/onboarding_milestone.dart';
import 'package:emerge_app/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:emerge_app/features/social/domain/services/club_activity_service.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockHabitRepository extends Mock implements HabitRepository {}
class MockUserStatsRepository extends Mock implements DriftUserStatsRepository {}
class MockAppDatabase extends Mock implements AppDatabase {}
class MockSyncEngine extends Mock implements EnhancedSyncEngine {}
class MockSocialActivityService extends Mock implements SocialActivityService {}

ProviderContainer _makeContainer({
  List<Habit> habits = const [],
  UserProfile? profile,
  List<OnboardingMilestone> milestones = const [],
  AuthUser? authUser,
}) {
  return ProviderContainer(
    overrides: [
      authStateChangesProvider.overrideWithValue(
        AsyncValue.data(authUser ?? const AuthUser(id: 'test', email: 'test@example.com')),
      ),
      habitsProvider.overrideWith((ref) => Stream.value(habits)),
      userProfileProvider.overrideWith((ref) => Stream.value(profile)),
      activeMilestonesProvider.overrideWith((ref) => milestones),
      habitRepositoryProvider.overrideWithValue(MockHabitRepository()),
      userStatsRepositoryProvider.overrideWithValue(MockUserStatsRepository()),
      appDatabaseProvider.overrideWithValue(MockAppDatabase()),
      enhancedSyncEngineProvider.overrideWithValue(MockSyncEngine()),
      socialActivityServiceProvider.overrideWithValue(MockSocialActivityService()),
    ],
  );
}

void main() {
  group('DashboardStateNotifier', () {
    test('initial state has empty habits', () {
      final container = _makeContainer();
      final state = container.read(dashboardStateProvider);
      expect(state.habits, []);
      expect(state.isCreatingHabit, false);
      expect(state.error, null);
      container.dispose();
    });

    test('syncs onboarding state through syncOnboardingState', () {
      final container = _makeContainer();
      final notifier = container.read(dashboardStateProvider.notifier);
      notifier.syncOnboardingState(
        const OnboardingState(selectedArchetype: UserArchetype.athlete, why: 'test'),
      );
      final state = container.read(dashboardStateProvider);
      expect(state.archetype, UserArchetype.athlete);
      expect(state.why, 'test');
      container.dispose();
    });

    test('clearError resets error state', () {
      final container = _makeContainer();
      final notifier = container.read(dashboardStateProvider.notifier);
      notifier.clearError();
      expect(container.read(dashboardStateProvider).error, null);
      container.dispose();
    });

    test('habitsByTimeOfDay groups correctly', () {
      final habits = [
        Habit(id: '1', userId: 'u1', title: 'Morning', createdAt: DateTime.now(), timeOfDayPreference: TimeOfDayPreference.morning),
        Habit(id: '2', userId: 'u1', title: 'Evening', createdAt: DateTime.now(), timeOfDayPreference: TimeOfDayPreference.evening),
      ];
      final state = DashboardState(habits: habits);
      final grouped = state.habitsByTimeOfDay;
      expect(grouped[TimeOfDayPreference.morning]!.length, 1);
      expect(grouped[TimeOfDayPreference.evening]!.length, 1);
    });
  });
}
