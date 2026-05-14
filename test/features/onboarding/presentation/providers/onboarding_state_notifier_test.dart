import 'package:emerge_app/features/auth/domain/entities/auth_user.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/onboarding/presentation/providers/onboarding_state_notifier.dart';
import 'package:emerge_app/features/gamification/domain/repositories/user_profile_repository.dart';
import 'package:emerge_app/features/gamification/data/repositories/user_stats_repository.dart';
import 'package:emerge_app/features/onboarding/data/repositories/local_settings_repository.dart';
import 'package:emerge_app/core/drift_repositories/drift_user_stats_repository.dart';
import 'package:emerge_app/core/drift/database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:emerge_app/features/gamification/presentation/providers/gamification_providers.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/presentation/providers/dashboard_state_provider.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';
import 'package:emerge_app/features/onboarding/data/services/remote_config_service.dart';
import 'package:emerge_app/features/onboarding/domain/entities/onboarding_config.dart';
import 'package:emerge_app/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:emerge_app/features/social/data/repositories/tribe_repository.dart';
import 'package:fpdart/fpdart.dart';

class MockUserProfileRepository extends Mock implements UserProfileRepository {}

class MockUserStatsRepository extends Mock
    implements DriftUserStatsRepository {}

class MockLocalSettingsRepository extends Mock
    implements LocalSettingsRepository {}

class MockAppDatabase extends Mock implements AppDatabase {}

class MockRemoteConfigService extends Mock implements RemoteConfigService {}

class TestDashboardNotifier extends DashboardStateNotifier {
  @override
  DashboardState build() => const DashboardState();
  @override
  void syncOnboardingState(covariant OnboardingState state) {}
  @override
  Future<void> createHabitOptimistic(Habit habit) async {}
}

class MockTribeRepository extends Mock implements TribeRepository {}

void main() {
  late ProviderContainer container;
  late MockUserProfileRepository mockUserProfileRepo;
  late MockUserStatsRepository mockUserStatsRepo;
  late MockLocalSettingsRepository mockLocalSettingsRepo;
  late MockAppDatabase mockDb;
  late TestDashboardNotifier testDashboardNotifier;
  late MockTribeRepository mockTribeRepo;
  late MockRemoteConfigService mockRemoteConfig;

  setUpAll(() {
    registerFallbackValue(
      Habit(id: '', userId: '', title: '', createdAt: DateTime(0)),
    );
  });

  setUp(() {
    mockUserProfileRepo = MockUserProfileRepository();
    mockUserStatsRepo = MockUserStatsRepository();
    mockLocalSettingsRepo = MockLocalSettingsRepository();
    mockDb = MockAppDatabase();
    testDashboardNotifier = TestDashboardNotifier();
    mockTribeRepo = MockTribeRepository();
    mockRemoteConfig = MockRemoteConfigService();

    // Register fallbacks
    registerFallbackValue(const UserProfile(uid: 'test-user'));
    registerFallbackValue(const OnboardingState());
    registerFallbackValue(const EnhancedOnboardingState());

    container = ProviderContainer(
      overrides: [
        userProfileRepositoryProvider.overrideWithValue(mockUserProfileRepo),
        userStatsRepositoryProvider.overrideWithValue(mockUserStatsRepo),
        localSettingsRepositoryProvider.overrideWithValue(
          mockLocalSettingsRepo,
        ),
        appDatabaseProvider.overrideWithValue(mockDb),
        dashboardStateProvider.overrideWith(() => testDashboardNotifier),
        tribeRepositoryProvider.overrideWithValue(mockTribeRepo),
        remoteConfigServiceProvider.overrideWithValue(mockRemoteConfig),
        // Mock auth state
        authStateChangesProvider.overrideWithValue(
          AsyncValue.data(
            const AuthUser(id: 'test-user', email: 'test@example.com'),
          ),
        ),
        // Mock profile stream
        userProfileProvider.overrideWith(
          (ref) => Stream.value(const UserProfile(uid: 'test-user')),
        ),
      ],
    );

    // Mock setup
    when(() => mockLocalSettingsRepo.isFirstLaunch).thenReturn(true);
    when(() => mockRemoteConfig.getOnboardingConfig()).thenReturn(
      const OnboardingConfig(
        archetypes: [],
        attributes: [],
        habitSuggestions: [],
      ),
    );
    when(() => mockDb.clearAll()).thenAnswer((_) async {});
  });

  tearDown(() {
    container.dispose();
  });

  group('EnhancedOnboardingNotifier Tests', () {
    test('initial state is correct for first launch', () {
      final state = container.read(enhancedOnboardingProvider);
      expect(state.isOnboardingActive, true);
      expect(state.currentStep, 0);
      expect(state.selectedArchetype, null);
    });

    test('selectArchetype updates state and persists', () async {
      when(
        () => mockUserProfileRepo.updateProfile(any()),
      ).thenAnswer((_) async => const Right(unit));
      when(
        () => mockUserStatsRepo.saveUserStats(any()),
      ).thenAnswer((_) async {});

      final notifier = container.read(enhancedOnboardingProvider.notifier);
      await notifier.selectArchetype(UserArchetype.athlete);

      final state = container.read(enhancedOnboardingProvider);
      expect(state.selectedArchetype, UserArchetype.athlete);

      verify(() => mockUserProfileRepo.updateProfile(any())).called(1);
    });

    test('completeMilestone updates progress', () async {
      when(
        () => mockUserProfileRepo.updateProfile(any()),
      ).thenAnswer((_) async => const Right(unit));
      when(
        () => mockUserStatsRepo.saveUserStats(any()),
      ).thenAnswer((_) async {});

      final notifier = container.read(enhancedOnboardingProvider.notifier);
      await notifier.completeMilestone(0);

      final state = container.read(enhancedOnboardingProvider);
      expect(state.currentStep, 1);
      expect(state.completedMilestones[0], true);
    });

    test(
      'completeOnboarding transitions to dashboard and joins club',
      () async {
        when(
          () => mockUserProfileRepo.updateProfile(any()),
        ).thenAnswer((_) async => const Right(unit));
        when(
          () => mockUserStatsRepo.saveUserStats(any()),
        ).thenAnswer((_) async {});
        when(
          () => mockLocalSettingsRepo.completeOnboarding(),
        ).thenAnswer((_) async {});
        when(
          () => mockTribeRepo.getArchetypeClub(any()),
        ).thenAnswer((_) async => null);

        final notifier = container.read(enhancedOnboardingProvider.notifier);

        // Setup some state
        await notifier.selectArchetype(UserArchetype.athlete);

        await notifier.completeOnboarding();

        final state = container.read(enhancedOnboardingProvider);
        expect(state.isOnboardingActive, false);
        expect(state.currentStep, 5);

        verify(() => mockLocalSettingsRepo.completeOnboarding()).called(1);
      },
    );
  });
}
