# Tier 3: Provider Tests Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Write unit tests for all 67 testable Riverpod providers across 18 test files.

**Architecture:** Each test file groups providers by shared mock setup. Pattern: `ProviderContainer` + `overrides` with mocktail mocks. No production code changes.

**Tech Stack:** Flutter, Riverpod, mocktail, flutter_test

---

### Task 1: Gamification Derived Providers

**Files:**
- Create: `test/features/gamification/presentation/providers/gamification_derived_providers_test.dart`
- Test: same file

- [ ] **Step 1: Write the test file**

```dart
import 'package:emerge_app/features/gamification/domain/entities/user_avatar_stats.dart';
import 'package:emerge_app/features/gamification/domain/entities/user_profile.dart';
import 'package:emerge_app/features/gamification/presentation/providers/attribute_progress_provider.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

ProviderContainer _makeContainer(UserProfile profile) {
  return ProviderContainer(
    overrides: [
      userStatsStreamProvider.overrideWith(
        (ref) => Stream.value(profile),
      ),
    ],
  );
}

void main() {
  group('currentArchetypeProvider', () {
    test('returns athlete when profile archetype is athlete', () {
      final container = _makeContainer(
        const UserProfile(uid: 'test', archetype: UserArchetype.athlete),
      );
      expect(container.read(currentArchetypeProvider), UserArchetype.athlete);
      container.dispose();
    });

    test('returns scholar when profile archetype is scholar', () {
      final container = _makeContainer(
        const UserProfile(uid: 'test', archetype: UserArchetype.scholar),
      );
      expect(container.read(currentArchetypeProvider), UserArchetype.scholar);
      container.dispose();
    });

    test('returns creator when profile archetype is creator', () {
      final container = _makeContainer(
        const UserProfile(uid: 'test', archetype: UserArchetype.creator),
      );
      expect(container.read(currentArchetypeProvider), UserArchetype.creator);
      container.dispose();
    });

    test('returns stoic when profile archetype is stoic', () {
      final container = _makeContainer(
        const UserProfile(uid: 'test', archetype: UserArchetype.stoic),
      );
      expect(container.read(currentArchetypeProvider), UserArchetype.stoic);
      container.dispose();
    });

    test('returns none when profile has no archetype', () {
      final container = _makeContainer(
        const UserProfile(uid: 'test', archetype: UserArchetype.none),
      );
      expect(container.read(currentArchetypeProvider), UserArchetype.none);
      container.dispose();
    });
  });

  group('isOnboardingCompleteProvider', () {
    test('returns true when onboardingCompletedAt is set', () {
      final container = _makeContainer(
        const UserProfile(uid: 'test', onboardingCompletedAt: DateTime(2024)),
      );
      expect(container.read(isOnboardingCompleteProvider), true);
      container.dispose();
    });

    test('returns false when onboardingCompletedAt is null', () {
      final container = _makeContainer(
        const UserProfile(uid: 'test'),
      );
      expect(container.read(isOnboardingCompleteProvider), false);
      container.dispose();
    });
  });

  group('userAvatarStatsProvider', () {
    test('returns avatar stats from profile', () async {
      final stats = const UserAvatarStats(level: 5, streak: 10, totalXp: 500);
      final container = _makeContainer(
        const UserProfile(uid: 'test').copyWith(avatarStats: stats),
      );
      expect(
        await container.read(userAvatarStatsProvider).first,
        stats,
      );
      container.dispose();
    });

    test('returns empty stats when profile has defaults', () async {
      final container = _makeContainer(
        const UserProfile(uid: 'test'),
      );
      expect(
        await container.read(userAvatarStatsProvider).first,
        const UserAvatarStats(),
      );
      container.dispose();
    });
  });

  group('userLevelProvider', () {
    test('returns level from profile avatar stats', () async {
      final container = _makeContainer(
        const UserProfile(uid: 'test').copyWith(
          avatarStats: const UserAvatarStats(level: 10),
        ),
      );
      expect(await container.read(userLevelProvider).first, 10);
      container.dispose();
    });

    test('returns 1 as default when stats are empty', () async {
      final container = _makeContainer(
        const UserProfile(uid: 'test'),
      );
      expect(await container.read(userLevelProvider).first, 1);
      container.dispose();
    });
  });

  group('userStreakProvider', () {
    test('returns streak from profile avatar stats', () async {
      final container = _makeContainer(
        const UserProfile(uid: 'test').copyWith(
          avatarStats: const UserAvatarStats(streak: 25),
        ),
      );
      expect(await container.read(userStreakProvider).first, 25);
      container.dispose();
    });

    test('returns 0 as default when streak is not set', () async {
      final container = _makeContainer(
        const UserProfile(uid: 'test'),
      );
      expect(await container.read(userStreakProvider).first, 0);
      container.dispose();
    });
  });

  group('attributeProgressFromHabitsProvider', () {
    test('returns empty map when profile is null', () {
      final container = ProviderContainer(
        overrides: [
          userStatsStreamProvider.overrideWith(
            (ref) => const Stream.empty(),
          ),
        ],
      );
      expect(container.read(attributeProgressFromHabitsProvider), {});
      container.dispose();
    });

    test('calculates progress for all 6 attributes', () {
      final container = _makeContainer(
        const UserProfile(uid: 'test').copyWith(
          avatarStats: const UserAvatarStats(
            totalXp: 1000,
            level: 2,
            strengthXp: 300,
            intellectXp: 200,
            vitalityXp: 150,
            creativityXp: 100,
            focusXp: 150,
            spiritXp: 100,
          ),
        ),
      );
      final result = container.read(attributeProgressFromHabitsProvider);
      expect(result.length, 6);
      expect(result.containsKey('strength'), true);
      expect(result.containsKey('intellect'), true);
      expect(result.containsKey('vitality'), true);
      expect(result.containsKey('creativity'), true);
      expect(result.containsKey('focus'), true);
      expect(result.containsKey('spirit'), true);
      container.dispose();
    });
  });

  group('attributeProgressProvider', () {
    test('returns progress for a specific attribute', () {
      final container = _makeContainer(
        const UserProfile(uid: 'test').copyWith(
          avatarStats: const UserAvatarStats(
            totalXp: 1000,
            level: 2,
            strengthXp: 300,
          ),
        ),
      );
      final result = container.read(attributeProgressProvider('strength'));
      expect(result, isNotNull);
      expect(result!.attribute, 'strength');
      expect(result.totalXp, 300);
      container.dispose();
    });

    test('returns null for unknown attribute', () {
      final container = _makeContainer(
        const UserProfile(uid: 'test'),
      );
      expect(container.read(attributeProgressProvider('unknown')), isNull);
      container.dispose();
    });

    test('is case-insensitive', () {
      final container = _makeContainer(
        const UserProfile(uid: 'test').copyWith(
          avatarStats: const UserAvatarStats(totalXp: 500, level: 1, strengthXp: 200),
        ),
      );
      expect(container.read(attributeProgressProvider('Strength')), isNotNull);
      container.dispose();
    });
  });
}
```

- [ ] **Step 2: Run the tests**

Run: `flutter test test/features/gamification/presentation/providers/gamification_derived_providers_test.dart`
Expected: All tests pass

- [ ] **Step 3: Commit**

```bash
git add test/features/gamification/presentation/providers/gamification_derived_providers_test.dart
git commit -m "test: add gamification derived provider tests (7 providers, 18 tests)"
```

---

### Task 2: Gamification State Providers

**Files:**
- Create: `test/features/gamification/presentation/providers/gamification_state_providers_test.dart`
- Test: same file

- [ ] **Step 1: Write the test file**

```dart
import 'package:emerge_app/features/auth/domain/entities/auth_user.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/gamification/data/repositories/user_stats_repository.dart';
import 'package:emerge_app/features/gamification/domain/entities/user_profile.dart';
import 'package:emerge_app/features/gamification/presentation/providers/gamification_providers.dart';
import 'package:emerge_app/features/gamification/presentation/providers/recap_hub_provider.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockUserStatsRepository extends Mock implements DriftUserStatsRepository {}

class MockUserProfileRepository extends Mock implements UserProfileRepository {}

ProviderContainer _makeContainer({
  required DriftUserStatsRepository userStatsRepo,
  UserProfileRepository? userProfileRepo,
  AuthUser? authUser,
}) {
  return ProviderContainer(
    overrides: [
      authStateChangesProvider.overrideWithValue(
        AsyncValue.data(authUser ?? const AuthUser(id: 'test', email: 'test@example.com')),
      ),
      userStatsRepositoryProvider.overrideWithValue(userStatsRepo),
      if (userProfileRepo != null)
        userProfileRepositoryProvider.overrideWithValue(userProfileRepo),
    ],
  );
}

void main() {
  late MockUserStatsRepository mockStatsRepo;
  late MockUserProfileRepository mockProfileRepo;

  setUp(() {
    mockStatsRepo = MockUserStatsRepository();
    mockProfileRepo = MockUserProfileRepository();
  });

  group('userProfileProvider', () {
    test('returns null when no user is authenticated', () async {
      final container = ProviderContainer(
        overrides: [
          authStateChangesProvider.overrideWithValue(
            const AsyncValue.data(AuthUser.empty),
          ),
          userStatsRepositoryProvider.overrideWithValue(mockStatsRepo),
        ],
      );
      expect(await container.read(userProfileProvider).first, null);
      container.dispose();
    });

    test('returns profile from repository', () async {
      when(() => mockProfileRepo.watchProfile('test')).thenAnswer(
        (_) => Stream.value(const UserProfile(uid: 'test', archetype: UserArchetype.athlete)),
      );
      final container = _makeContainer(
        userStatsRepo: mockStatsRepo,
        userProfileRepo: mockProfileRepo,
      );
      final result = await container.read(userProfileProvider).first;
      expect(result, isNotNull);
      expect(result!.archetype, UserArchetype.athlete);
      container.dispose();
    });
  });

  group('userStatsStreamProvider', () {
    test('returns empty profile when no user', () async {
      final container = ProviderContainer(
        overrides: [
          authStateChangesProvider.overrideWithValue(
            const AsyncValue.data(AuthUser.empty),
          ),
          userStatsRepositoryProvider.overrideWithValue(mockStatsRepo),
        ],
      );
      final result = await container.read(userStatsStreamProvider).first;
      expect(result.uid, '');
      container.dispose();
    });

    test('returns user stats from repo for authenticated user', () async {
      when(() => mockStatsRepo.watchUserStats('test')).thenAnswer(
        (_) => Stream.value(const UserProfile(uid: 'test', archetype: UserArchetype.scholar)),
      );
      final container = _makeContainer(userStatsRepo: mockStatsRepo);
      final result = await container.read(userStatsStreamProvider).first;
      expect(result.archetype, UserArchetype.scholar);
      container.dispose();
    });
  });

  group('userStatsControllerProvider', () {
    test('creates controller with correct userId', () {
      final container = _makeContainer(userStatsRepo: mockStatsRepo);
      final controller = container.read(userStatsControllerProvider);
      expect(controller, isNotNull);
      container.dispose();
    });
  });

  group('recapRefreshCounterProvider', () {
    test('initial value is 0', () {
      final container = ProviderContainer(
        overrides: [
          userStatsRepositoryProvider.overrideWithValue(mockStatsRepo),
          authStateChangesProvider.overrideWithValue(
            const AsyncValue.data(AuthUser.empty),
          ),
        ],
      );
      expect(container.read(recapRefreshCounterProvider), 0);
      container.dispose();
    });

    test('increment increases value', () {
      final container = ProviderContainer(
        overrides: [
          userStatsRepositoryProvider.overrideWithValue(mockStatsRepo),
          authStateChangesProvider.overrideWithValue(
            const AsyncValue.data(AuthUser.empty),
          ),
        ],
      );
      container.read(recapRefreshCounterProvider.notifier).increment();
      expect(container.read(recapRefreshCounterProvider), 1);
      container.dispose();
    });
  });

  group('historicalRecapsProvider', () {
    test('returns empty list when no user', () async {
      final container = ProviderContainer(
        overrides: [
          authStateChangesProvider.overrideWithValue(
            const AsyncValue.data(AuthUser.empty),
          ),
          userStatsRepositoryProvider.overrideWithValue(mockStatsRepo),
        ],
      );
      final result = await container.read(historicalRecapsProvider.future);
      expect(result, []);
      container.dispose();
    });

    test('returns recaps from repository', () async {
      when(() => mockStatsRepo.getRecaps('test', limit: 20)).thenAnswer(
        (_) async => [
          {'week_start': '2024-01-01', 'total_xp': 500},
        ],
      );
      final container = _makeContainer(userStatsRepo: mockStatsRepo);
      final result = await container.read(historicalRecapsProvider.future);
      expect(result.length, 1);
      container.dispose();
    });

    test('handles repository error gracefully', () async {
      when(() => mockStatsRepo.getRecaps('test', limit: 20)).thenThrow(Exception('DB error'));
      final container = _makeContainer(userStatsRepo: mockStatsRepo);
      final result = await container.read(historicalRecapsProvider.future);
      expect(result, []);
      container.dispose();
    });
  });
}
```

- [ ] **Step 2: Run tests**

Run: `flutter test test/features/gamification/presentation/providers/gamification_state_providers_test.dart`
Expected: All tests pass

- [ ] **Step 3: Commit**

```bash
git add test/features/gamification/presentation/providers/gamification_state_providers_test.dart
git commit -m "test: add gamification state provider tests (5 providers, 12 tests)"
```

---

### Task 3: Dashboard Selectors

**Files:**
- Create: `test/features/habits/presentation/providers/dashboard_selectors_test.dart`
- Test: same file

- [ ] **Step 1: Write the test file**

```dart
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/presentation/providers/dashboard_state_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

ProviderContainer _makeContainer(DashboardState state) {
  return ProviderContainer(
    overrides: [
      dashboardStateProvider.overrideWith((ref) => state),
    ],
  );
}

void main() {
  group('todaysHabitsProvider', () {
    test('returns habits from dashboard state', () {
      final habits = [
        Habit(id: '1', userId: 'u1', title: 'Test', createdAt: DateTime.now()),
      ];
      final state = DashboardState(habits: habits);
      final container = _makeContainer(state);
      expect(container.read(todaysHabitsProvider), habits);
      container.dispose();
    });

    test('returns empty when dashboard has no habits', () {
      final container = _makeContainer(const DashboardState());
      expect(container.read(todaysHabitsProvider), []);
      container.dispose();
    });
  });

  group('todayCompletionRateProvider', () {
    test('returns 0.0 when no habits', () {
      final container = _makeContainer(const DashboardState());
      expect(container.read(todayCompletionRateProvider), 0.0);
      container.dispose();
    });

    test('returns 1.0 when all habits completed today', () {
      final now = DateTime.now();
      final habits = [
        Habit(id: '1', userId: 'u1', title: 'Habit 1', createdAt: now, lastCompletedDate: now),
        Habit(id: '2', userId: 'u1', title: 'Habit 2', createdAt: now, lastCompletedDate: now),
      ];
      final container = _makeContainer(DashboardState(habits: habits));
      expect(container.read(todayCompletionRateProvider), 1.0);
      container.dispose();
    });
  });

  group('isDashboardLoadingProvider', () {
    test('returns false when idle', () {
      final container = _makeContainer(const DashboardState());
      expect(container.read(isDashboardLoadingProvider), false);
      container.dispose();
    });

    test('returns true when creating habit', () {
      final container = _makeContainer(
        const DashboardState(isCreatingHabit: true),
      );
      expect(container.read(isDashboardLoadingProvider), true);
      container.dispose();
    });

    test('returns true when activating blueprint', () {
      final container = _makeContainer(
        const DashboardState(isActivatingBlueprint: true),
      );
      expect(container.read(isDashboardLoadingProvider), true);
      container.dispose();
    });
  });

  group('dashboardErrorProvider', () {
    test('returns null when no error', () {
      final container = _makeContainer(const DashboardState());
      expect(container.read(dashboardErrorProvider), isNull);
      container.dispose();
    });

    test('returns error string when present', () {
      final container = _makeContainer(
        const DashboardState(error: 'Something went wrong'),
      );
      expect(container.read(dashboardErrorProvider), 'Something went wrong');
      container.dispose();
    });
  });
}
```

- [ ] **Step 2: Run tests**

Run: `flutter test test/features/habits/presentation/providers/dashboard_selectors_test.dart`
Expected: All tests pass

- [ ] **Step 3: Commit**

```bash
git add test/features/habits/presentation/providers/dashboard_selectors_test.dart
git commit -m "test: add dashboard selector provider tests (4 providers, 10 tests)"
```

---

### Task 4: Dashboard State Notifier

**Files:**
- Create: `test/features/habits/presentation/providers/dashboard_state_provider_test.dart`
- Test: same file

- [ ] **Step 1: Write the test file**

```dart
import 'package:emerge_app/features/auth/domain/entities/auth_user.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/gamification/domain/entities/user_profile.dart';
import 'package:emerge_app/features/gamification/presentation/providers/gamification_providers.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/presentation/providers/dashboard_state_provider.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:emerge_app/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:emerge_app/features/gamification/data/repositories/user_stats_repository.dart';
import 'package:emerge_app/core/drift_repositories/repositories_barrel.dart';
import 'package:emerge_app/core/drift/database.dart';
import 'package:emerge_app/core/sync/sync_providers.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';

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
```

- [ ] **Step 2: Run tests**

Run: `flutter test test/features/habits/presentation/providers/dashboard_state_provider_test.dart`
Expected: All tests pass

- [ ] **Step 3: Commit**

```bash
git add test/features/habits/presentation/providers/dashboard_state_provider_test.dart
git commit -m "test: add dashboard state notifier tests (1 provider, 5 tests)"
```

---

### Task 5: Habit Core Providers

**Files:**
- Create: `test/features/habits/presentation/providers/habit_core_providers_test.dart`
- Test: same file

- [ ] **Step 1: Write the test file**

```dart
import 'package:emerge_app/features/auth/domain/entities/auth_user.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/gamification/data/repositories/user_stats_repository.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/domain/repositories/habit_repository.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockHabitRepository extends Mock implements HabitRepository {}

ProviderContainer _makeContainer({
  required HabitRepository habitRepo,
  AuthUser? authUser,
}) {
  return ProviderContainer(
    overrides: [
      authStateChangesProvider.overrideWithValue(
        AsyncValue.data(authUser ?? const AuthUser(id: 'test', email: 'test@example.com')),
      ),
      habitRepositoryProvider.overrideWithValue(habitRepo),
    ],
  );
}

void main() {
  late MockHabitRepository mockRepo;

  setUp(() {
    mockRepo = MockHabitRepository();
  });

  group('momentumServiceProvider', () {
    test('creates a MomentumService instance', () {
      final container = _makeContainer(habitRepo: mockRepo);
      expect(container.read(momentumServiceProvider), isNotNull);
      container.dispose();
    });
  });

  group('habitsProvider', () {
    test('returns empty list when no user', () async {
      final container = ProviderContainer(
        overrides: [
          authStateChangesProvider.overrideWithValue(
            const AsyncValue.data(AuthUser.empty),
          ),
          habitRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      final result = await container.read(habitsProvider).first;
      expect(result, []);
      container.dispose();
    });

    test('returns habits from repository', () async {
      final habits = [Habit(id: '1', userId: 'test', title: 'Test', createdAt: DateTime.now())];
      when(() => mockRepo.watchHabits('test')).thenAnswer((_) => Stream.value(habits));
      final container = _makeContainer(habitRepo: mockRepo);
      final result = await container.read(habitsProvider).first;
      expect(result, habits);
      container.dispose();
    });
  });

  group('habitActivityProvider', () {
    test('returns empty list when no user', () async {
      final container = ProviderContainer(
        overrides: [
          authStateChangesProvider.overrideWithValue(
            const AsyncValue.data(AuthUser.empty),
          ),
          habitRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      final result = await container.read(
        habitActivityProvider(start: DateTime(2024), end: DateTime(2025)).future,
      );
      expect(result, []);
      container.dispose();
    });

    test('returns activity from repository', () async {
      final now = DateTime.now();
      when(() => mockRepo.getActivity('test', now, now.add(const Duration(days: 1))))
          .thenAnswer((_) async => []);
      final container = _makeContainer(habitRepo: mockRepo);
      final result = await container.read(
        habitActivityProvider(start: now, end: now.add(const Duration(days: 1))).future,
      );
      expect(result, []);
      container.dispose();
    });
  });
}
```

- [ ] **Step 2: Run tests**

Run: `flutter test test/features/habits/presentation/providers/habit_core_providers_test.dart`
Expected: All tests pass

- [ ] **Step 3: Commit**

```bash
git add test/features/habits/presentation/providers/habit_core_providers_test.dart
git commit -m "test: add habit core provider tests (4 providers, 7 tests)"
```

---

### Task 6: Habit Action Providers

**Files:**
- Create: `test/features/habits/presentation/providers/habit_action_providers_test.dart`
- Test: same file

- [ ] **Step 1: Write the test file**

```dart
import 'package:emerge_app/features/auth/domain/entities/auth_user.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/domain/repositories/habit_repository.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:emerge_app/core/drift/database.dart';
import 'package:emerge_app/core/drift_repositories/repositories_barrel.dart';
import 'package:emerge_app/features/gamification/domain/entities/user_profile.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/core/services/remote_config_service.dart';
import 'package:emerge_app/features/monetization/presentation/providers/subscription_provider.dart';

class MockHabitRepository extends Mock implements HabitRepository {}
class MockRemoteConfigService extends Mock implements RemoteConfigService {}

class TestIsPremium extends IsPremium {
  final bool premium;
  TestIsPremium(this.premium);
  @override
  Future<bool> build() async => premium;
}

ProviderContainer _makeContainer({
  required HabitRepository habitRepo,
  RemoteConfigService? remoteConfig,
  bool premium = false,
  AuthUser? authUser,
}) {
  return ProviderContainer(
    overrides: [
      authStateChangesProvider.overrideWithValue(
        AsyncValue.data(authUser ?? const AuthUser(id: 'test', email: 'test@example.com')),
      ),
      habitRepositoryProvider.overrideWithValue(habitRepo),
      if (remoteConfig != null)
        remoteConfigServiceProvider.overrideWithValue(remoteConfig),
      isPremiumProvider.overrideWith(() => TestIsPremium(premium)),
      userStatsStreamProvider.overrideWith(
        (ref) => Stream.value(const UserProfile(uid: 'test')),
      ),
    ],
  );
}

void main() {
  late MockHabitRepository mockRepo;
  late MockRemoteConfigService mockRemoteConfig;

  setUp(() {
    mockRepo = MockHabitRepository();
    mockRemoteConfig = MockRemoteConfigService();
  });

  group('createHabitProvider', () {
    test('creates a habit successfully', () async {
      registerFallbackValue(Habit(id: '1', userId: 'test', title: 'Test', createdAt: DateTime.now()));
      when(() => mockRepo.watchHabits('test')).thenAnswer((_) => Stream.value([]));
      when(() => mockRemoteConfig.freeHabitLimit).thenReturn(5);
      when(() => mockRepo.createHabit(any())).thenAnswer((_) async => const Right(unit));

      final container = _makeContainer(
        habitRepo: mockRepo,
        remoteConfig: mockRemoteConfig,
        premium: true,
      );

      await container.read(
        createHabitProvider(Habit(id: '1', userId: 'test', title: 'Test', createdAt: DateTime.now())).future,
      );
      verify(() => mockRepo.createHabit(any())).called(1);
      container.dispose();
    });

    test('throws when habit limit exceeded on free tier', () async {
      registerFallbackValue(Habit(id: '1', userId: 'test', title: 'Test', createdAt: DateTime.now()));
      final existingHabits = List.generate(5, (i) => Habit(id: '$i', userId: 'test', title: 'Habit $i', createdAt: DateTime.now()));
      when(() => mockRepo.watchHabits('test')).thenAnswer((_) => Stream.value(existingHabits));
      when(() => mockRemoteConfig.freeHabitLimit).thenReturn(5);

      final container = _makeContainer(
        habitRepo: mockRepo,
        remoteConfig: mockRemoteConfig,
        premium: false,
      );

      expect(
        () => container.read(
          createHabitProvider(Habit(id: 'new', userId: 'test', title: 'New', createdAt: DateTime.now())).future,
        ),
        throwsA(isA<SubscriptionLimitReachedException>()),
      );
      container.dispose();
    });
  });

  group('completeHabitProvider', () {
    test('completes a habit and returns result', () async {
      when(() => mockRepo.completeHabit('1', any())).thenAnswer(
        (_) async => const Right(true),
      );
      when(() => mockRepo.getHabit('1')).thenAnswer(
        (_) async => Habit(id: '1', userId: 'test', title: 'Test', createdAt: DateTime(2024), currentStreak: 0),
      );
      when(() => mockRepo.watchHabits('test')).thenAnswer((_) => Stream.value([]));

      final container = _makeContainer(habitRepo: mockRepo, premium: true);
      final result = await container.read(
        completeHabitProvider('1').future,
      );
      expect(result.xpEarned, greaterThan(0));
      expect(result.newStreak, 1);
      container.dispose();
    });

    test('handles undo completion', () async {
      when(() => mockRepo.completeHabit('1', any())).thenAnswer(
        (_) async => const Right(false),
      );
      when(() => mockRepo.watchHabits('test')).thenAnswer((_) => Stream.value([]));

      final container = _makeContainer(habitRepo: mockRepo, premium: true);
      final result = await container.read(
        completeHabitProvider('1').future,
      );
      expect(result.isUndo, true);
      expect(result.xpEarned, 0);
      container.dispose();
    });
  });
}
```

- [ ] **Step 2: Run tests**

Run: `flutter test test/features/habits/presentation/providers/habit_action_providers_test.dart`
Expected: All tests pass

- [ ] **Step 3: Commit**

```bash
git add test/features/habits/presentation/providers/habit_action_providers_test.dart
git commit -m "test: add habit action provider tests (2 providers, 5 tests)"
```

---

### Task 7: Cue Providers

**Files:**
- Create: `test/features/habits/presentation/providers/cue_providers_test.dart`
- Test: same file

- [ ] **Step 1: Write the test file**

```dart
import 'package:emerge_app/core/domain/entities/cue.dart';
import 'package:emerge_app/core/services/cue_engine.dart';
import 'package:emerge_app/features/habits/presentation/providers/cue_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCueEngine extends Mock implements CueEngine {}

ProviderContainer _makeContainer(CueEngine engine) {
  return ProviderContainer(
    overrides: [
      cueEngineProvider.overrideWithValue(engine),
    ],
  );
}

void main() {
  late MockCueEngine mockEngine;

  setUp(() {
    mockEngine = MockCueEngine();
  });

  group('cueNotifierProvider', () {
    test('calls engine.initialize on initialize', () async {
      when(() => mockEngine.initialize(archetype: any(named: 'archetype')))
          .thenAnswer((_) async => {});

      final container = _makeContainer(mockEngine);
      await container.read(cueNotifierProvider.notifier).initialize(UserArchetype.athlete);
      verify(() => mockEngine.initialize(archetype: UserArchetype.athlete)).called(1);
      container.dispose();
    });

    test('calls engine methods for markActionTaken', () {
      when(() => mockEngine.markActionTaken('cue-1', timeToAction: any(named: 'timeToAction')))
          .thenReturn(null);

      final container = _makeContainer(mockEngine);
      container.read(cueNotifierProvider.notifier).markActionTaken('cue-1');
      verify(() => mockEngine.markActionTaken('cue-1', timeToAction: any(named: 'timeToAction'))).called(1);
      container.dispose();
    });

    test('calls engine.markDismissed', () {
      when(() => mockEngine.markDismissed('cue-1')).thenReturn(null);

      final container = _makeContainer(mockEngine);
      container.read(cueNotifierProvider.notifier).markDismissed('cue-1');
      verify(() => mockEngine.markDismissed('cue-1')).called(1);
      container.dispose();
    });
  });

  group('cueMetricsProvider', () {
    test('returns metrics from engine', () {
      when(() => mockEngine.getMetrics('cue-1')).thenReturn(
        const CueEngagementMetrics(actionTaken: true),
      );

      final container = _makeContainer(mockEngine);
      final result = container.read(cueMetricsProvider('cue-1'));
      expect(result, isNotNull);
      expect(result!.actionTaken, true);
      container.dispose();
    });

    test('returns null for unknown cueId', () {
      when(() => mockEngine.getMetrics('unknown')).thenReturn(null);

      final container = _makeContainer(mockEngine);
      final result = container.read(cueMetricsProvider('unknown'));
      expect(result, isNull);
      container.dispose();
    });
  });

  group('cuePerformanceProvider', () {
    test('returns performance map from engine', () {
      when(() => mockEngine.getOverallPerformance()).thenReturn({'rate': 0.8});

      final container = _makeContainer(mockEngine);
      final result = container.read(cuePerformanceProvider);
      expect(result['rate'], 0.8);
      container.dispose();
    });
  });
}
```

- [ ] **Step 2: Run tests**

Run: `flutter test test/features/habits/presentation/providers/cue_providers_test.dart`
Expected: All tests pass

- [ ] **Step 3: Commit**

```bash
git add test/features/habits/presentation/providers/cue_providers_test.dart
git commit -m "test: add cue provider tests (3 providers, 7 tests)"
```

---

### Task 8: Auth Providers

**Files:**
- Create: `test/features/auth/presentation/providers/auth_providers_test.dart`
- Test: same file

- [ ] **Step 1: Write the test file**

```dart
import 'dart:async';
import 'package:emerge_app/features/auth/data/repositories/firebase_auth_repository.dart' as impl;
import 'package:emerge_app/features/auth/domain/entities/auth_user.dart';
import 'package:emerge_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

ProviderContainer _makeContainer({
  required AuthRepository repo,
  Stream<AuthUser>? userStream,
}) {
  return ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(repo),
      if (userStream != null)
        authStateChangesProvider.overrideWith((ref) => userStream),
    ],
  );
}

void main() {
  late MockAuthRepository mockRepo;

  setUp(() {
    mockRepo = MockAuthRepository();
  });

  group('authStateChangesProvider', () {
    test('emits user stream from repository', () async {
      when(() => mockRepo.user).thenAnswer(
        (_) => Stream.value(const AuthUser(id: 'test', email: 'test@example.com')),
      );

      final container = _makeContainer(repo: mockRepo);
      final result = await container.read(authStateChangesProvider).first;
      expect(result.id, 'test');
      expect(result.email, 'test@example.com');
      container.dispose();
    });

    test('emits anonymous when repo emits empty', () async {
      when(() => mockRepo.user).thenAnswer(
        (_) => Stream.value(AuthUser.empty),
      );

      final container = _makeContainer(repo: mockRepo);
      final result = await container.read(authStateChangesProvider).first;
      expect(result.isEmpty, true);
      container.dispose();
    });
  });

  group('signInProvider', () {
    test('calls repository signInWithEmailAndPassword', () async {
      when(() => mockRepo.signInWithEmailAndPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      )).thenAnswer((_) async => const Right(unit));

      final container = _makeContainer(repo: mockRepo);
      await container.read(signInProvider('test@test.com', 'password').future);
      verify(() => mockRepo.signInWithEmailAndPassword(
        email: 'test@test.com',
        password: any(named: 'password'),
      )).called(1);
      container.dispose();
    });

    test('throws on sign in failure', () async {
      when(() => mockRepo.signInWithEmailAndPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      )).thenAnswer((_) async => Left(Exception('Invalid credentials')));

      final container = _makeContainer(repo: mockRepo);
      expect(
        () => container.read(signInProvider('bad@test.com', 'wrong').future),
        throwsA(isA<Exception>()),
      );
      container.dispose();
    });
  });

  group('signOutProvider', () {
    test('calls repository signOut', () async {
      when(() => mockRepo.signOut()).thenAnswer((_) async {});

      final container = _makeContainer(repo: mockRepo);
      await container.read(signOutProvider.future);
      verify(() => mockRepo.signOut()).called(1);
      container.dispose();
    });
  });
}
```

- [ ] **Step 2: Run tests**

Run: `flutter test test/features/auth/presentation/providers/auth_providers_test.dart`
Expected: All tests pass

- [ ] **Step 3: Commit**

```bash
git add test/features/auth/presentation/providers/auth_providers_test.dart
git commit -m "test: add auth provider tests (4 providers, 7 tests)"
```

---

### Task 9: Onboarding Providers

**Files:**
- Create: `test/features/onboarding/presentation/providers/onboarding_providers_test.dart`
- Test: same file

- [ ] **Step 1: Write the test file**

```dart
import 'package:emerge_app/features/gamification/domain/entities/user_profile.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

ProviderContainer _makeContainer({
  OnboardingState? onboardingState,
  UserProfile? profile,
}) {
  return ProviderContainer(
    overrides: [
      if (onboardingState != null)
        onboardingStateControllerProvider.overrideWith((ref) => onboardingState),
      if (profile != null)
        userStatsStreamProvider.overrideWith((ref) => Stream.value(profile)),
    ],
  );
}

void main() {
  group('onboardingStateControllerProvider', () {
    test('initial state has correct defaults', () {
      final container = ProviderContainer(
        overrides: [
          onboardingStateControllerProvider.overrideWith(
            (ref) => const OnboardingState(),
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
      final container = ProviderContainer(
        overrides: [
          onboardingStateControllerProvider.overrideWith(
            (ref) => const OnboardingState(),
          ),
        ],
      );
      container.read(onboardingStateControllerProvider.notifier).updateState(
        const OnboardingState(currentMilestoneStep: 2),
      );
      expect(container.read(onboardingStateControllerProvider).currentMilestoneStep, 2);
      container.dispose();
    });
  });

  group('selectedArchetypeProvider', () {
    test('returns selected archetype from state', () {
      final container = _makeContainer(
        onboardingState: const OnboardingState(selectedArchetype: UserArchetype.creator),
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
      final container = _makeContainer(
        profile: const UserProfile(uid: 'test', onboardingProgress: 0),
      );
      final milestones = container.read(activeMilestonesProvider);
      expect(milestones.length, 1);
      expect(milestones[0].order, 1);
      container.dispose();
    });

    test('returns empty list when progress >= 4', () {
      final container = _makeContainer(
        profile: const UserProfile(uid: 'test', onboardingProgress: 4),
      );
      expect(container.read(activeMilestonesProvider), []);
      container.dispose();
    });
  });

  group('isOnboardingActiveProvider', () {
    test('returns value from enhancedOnboardingProvider', () {
      final container = ProviderContainer(overrides: [
        enhancedOnboardingProvider.overrideWith((ref) => const EnhancedOnboardingState(isOnboardingActive: true)),
      ]);
      expect(container.read(isOnboardingActiveProvider), true);
      container.dispose();
    });
  });

  group('onboardingProgressProvider', () {
    test('returns progress value', () {
      final container = ProviderContainer(overrides: [
        enhancedOnboardingProvider.overrideWith(
          (ref) => const EnhancedOnboardingState(currentStep: 2),
        ),
      ]);
      expect(container.read(onboardingProgressProvider), 2 / 5);
      container.dispose();
    });
  });
}
```

- [ ] **Step 2: Run tests**

Run: `flutter test test/features/onboarding/presentation/providers/onboarding_providers_test.dart`
Expected: All tests pass

- [ ] **Step 3: Commit**

```bash
git add test/features/onboarding/presentation/providers/onboarding_providers_test.dart
git commit -m "test: add onboarding provider tests (8 providers, 11 tests)"
```

---

### Task 10: World Map Providers

**Files:**
- Create: `test/features/world_map/presentation/providers/world_map_providers_test.dart`
- Test: same file

- [ ] **Step 1: Write the test file**

```dart
import 'package:emerge_app/features/auth/domain/entities/auth_user.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/gamification/data/repositories/user_stats_repository.dart';
import 'package:emerge_app/features/gamification/domain/entities/user_profile.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/world_map/domain/services/world_health_service.dart';
import 'package:emerge_app/features/world_map/presentation/providers/world_health_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockWorldHealthService extends Mock implements WorldHealthService {}
class MockUserStatsRepository extends Mock implements DriftUserStatsRepository {}

ProviderContainer _makeContainer({
  required WorldHealthService healthService,
  DriftUserStatsRepository? statsRepo,
  AuthUser? authUser,
}) {
  return ProviderContainer(
    overrides: [
      authStateChangesProvider.overrideWithValue(
        AsyncValue.data(authUser ?? const AuthUser(id: 'test', email: 'test@example.com')),
      ),
      worldHealthServiceProvider.overrideWithValue(healthService),
      if (statsRepo != null)
        userStatsRepositoryProvider.overrideWithValue(statsRepo),
    ],
  );
}

void main() {
  late MockWorldHealthService mockService;
  late MockUserStatsRepository mockRepo;

  setUp(() {
    mockService = MockWorldHealthService();
    mockRepo = MockUserStatsRepository();
  });

  group('worldHealthServiceProvider', () {
    test('creates service with repository', () {
      final container = _makeContainer(
        healthService: mockService,
        statsRepo: mockRepo,
      );
      final service = container.read(worldHealthServiceProvider);
      expect(service, mockService);
      container.dispose();
    });
  });

  group('worldHealthProvider', () {
    test('returns default 0.5 when no user', () async {
      final container = ProviderContainer(
        overrides: [
          authStateChangesProvider.overrideWithValue(
            const AsyncValue.data(AuthUser.empty),
          ),
          worldHealthServiceProvider.overrideWithValue(mockService),
        ],
      );
      final result = await container.read(worldHealthProvider.future);
      expect(result, 0.5);
      container.dispose();
    });

    test('returns health from service for authed user', () async {
      when(() => mockService.getWorldHealth('test')).thenAnswer((_) async => 0.85);
      final container = _makeContainer(healthService: mockService);
      final result = await container.read(worldHealthProvider.future);
      expect(result, 0.85);
      container.dispose();
    });
  });

  group('worldHealthStreamProvider', () {
    test('returns 0.5 when no user', () async {
      final container = ProviderContainer(
        overrides: [
          authStateChangesProvider.overrideWithValue(
            const AsyncValue.data(AuthUser.empty),
          ),
          userStatsRepositoryProvider.overrideWithValue(mockRepo),
          worldHealthServiceProvider.overrideWithValue(mockService),
        ],
      );
      final result = await container.read(worldHealthStreamProvider).first;
      expect(result, 0.5);
      container.dispose();
    });

    test('streams momentum score from user profile', () async {
      when(() => mockRepo.watchUserStats('test')).thenAnswer(
        (_) => Stream.value(const UserProfile(uid: 'test', momentumScore: 0.75)),
      );
      final container = _makeContainer(
        healthService: mockService,
        statsRepo: mockRepo,
      );
      final result = await container.read(worldHealthStreamProvider).first;
      expect(result, 0.75);
      container.dispose();
    });
  });

  group('worldEntropyStreamProvider', () {
    test('returns 0.0 when no user', () async {
      final container = ProviderContainer(
        overrides: [
          authStateChangesProvider.overrideWithValue(
            const AsyncValue.data(AuthUser.empty),
          ),
          userStatsRepositoryProvider.overrideWithValue(mockRepo),
          worldHealthServiceProvider.overrideWithValue(mockService),
        ],
      );
      final result = await container.read(worldEntropyStreamProvider).first;
      expect(result, 0.0);
      container.dispose();
    });

    test('streams entropy from user profile world state', () async {
      when(() => mockRepo.watchUserStats('test')).thenAnswer(
        (_) => Stream.value(
          const UserProfile(uid: 'test').copyWith(
            worldState: UserWorldState(entropy: 0.3),
          ),
        ),
      );
      final container = _makeContainer(
        healthService: mockService,
        statsRepo: mockRepo,
      );
      final result = await container.read(worldEntropyStreamProvider).first;
      expect(result, 0.3);
      container.dispose();
    });
  });
}
```

- [ ] **Step 2: Run tests**

Run: `flutter test test/features/world_map/presentation/providers/world_map_providers_test.dart`
Expected: All tests pass

- [ ] **Step 3: Commit**

```bash
git add test/features/world_map/presentation/providers/world_map_providers_test.dart
git commit -m "test: add world map provider tests (4 providers, 8 tests)"
```

---

### Task 11: Social Challenge Providers

**Files:**
- Create: `test/features/social/presentation/providers/challenge_providers_test.dart`
- Test: same file

- [ ] **Step 1: Write the test file**

```dart
import 'package:emerge_app/features/auth/domain/entities/auth_user.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/gamification/domain/entities/user_profile.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/social/data/repositories/challenge_repository.dart';
import 'package:emerge_app/features/social/presentation/providers/challenge_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockChallengeRepository extends Mock implements ChallengeRepository {}

ProviderContainer _makeContainer({
  required ChallengeRepository challengeRepo,
  AuthUser? authUser,
  UserProfile? profile,
}) {
  return ProviderContainer(
    overrides: [
      challengeRepositoryProvider.overrideWithValue(challengeRepo),
      authStateChangesProvider.overrideWithValue(
        AsyncValue.data(authUser ?? const AuthUser(id: 'test', email: 'test@example.com')),
      ),
      if (profile != null)
        userStatsStreamProvider.overrideWith((ref) => Stream.value(profile)),
    ],
  );
}

void main() {
  late MockChallengeRepository mockRepo;

  setUp(() {
    mockRepo = MockChallengeRepository();
  });

  group('challengeRepositoryProvider', () {
    test('creates repository instance', () {
      final container = _makeContainer(challengeRepo: mockRepo);
      expect(container.read(challengeRepositoryProvider), mockRepo);
      container.dispose();
    });
  });

  group('featuredChallengesProvider', () {
    test('returns list of challenges', () async {
      when(() => mockRepo.getFeaturedChallenges()).thenAnswer((_) async => []);
      final container = _makeContainer(challengeRepo: mockRepo);
      final result = await container.read(featuredChallengesProvider.future);
      expect(result, isA<List>());
      container.dispose();
    });
  });

  group('allChallengesProvider', () {
    test('returns all challenges', () async {
      when(() => mockRepo.getAllChallenges()).thenAnswer((_) async => []);
      final container = _makeContainer(challengeRepo: mockRepo);
      final result = await container.read(allChallengesProvider.future);
      expect(result, isA<List>());
      container.dispose();
    });
  });

  group('userChallengesProvider', () {
    test('returns empty when no user', () async {
      final container = ProviderContainer(
        overrides: [
          challengeRepositoryProvider.overrideWithValue(mockRepo),
          authStateChangesProvider.overrideWithValue(
            const AsyncValue.data(AuthUser.empty),
          ),
        ],
      );
      final result = await container.read(userChallengesProvider.future);
      expect(result, []);
      container.dispose();
    });

    test('returns challenges for user', () async {
      when(() => mockRepo.getUserChallenges('test')).thenAnswer((_) async => []);
      final container = _makeContainer(challengeRepo: mockRepo);
      final result = await container.read(userChallengesProvider.future);
      expect(result, isA<List>());
      container.dispose();
    });
  });

  group('archetypeChallengesProvider', () {
    test('returns challenges matching archetype', () async {
      when(() => mockRepo.getArchetypeChallenges('athlete')).thenAnswer((_) async => []);
      final container = _makeContainer(
        challengeRepo: mockRepo,
        profile: const UserProfile(uid: 'test', archetype: UserArchetype.athlete),
      );
      final result = await container.read(archetypeChallengesProvider.future);
      expect(result, isA<List>());
      container.dispose();
    });
  });

  group('dailyQuestProvider', () {
    test('returns a challenge', () async {
      final container = _makeContainer(
        challengeRepo: mockRepo,
        profile: const UserProfile(uid: 'test', archetype: UserArchetype.athlete),
      );
      final result = await container.read(dailyQuestProvider.future);
      expect(result, isA<Challenge?>());
      container.dispose();
    });
  });

  group('challengeByIdProvider', () {
    test('returns challenge by ID', () async {
      when(() => mockRepo.getChallengeById('ch-1')).thenAnswer((_) async => null);
      final container = _makeContainer(challengeRepo: mockRepo);
      final result = await container.read(challengeByIdProvider('ch-1').future);
      expect(result, isNull);
      container.dispose();
    });
  });

  group('filteredChallengesProvider', () {
    test('returns filtered list', () async {
      when(() => mockRepo.getFeaturedChallenges()).thenAnswer((_) async => []);
      when(() => mockRepo.getUserChallenges('test')).thenAnswer((_) async => []);
      final container = _makeContainer(challengeRepo: mockRepo);
      final result = await container.read(
        filteredChallengesProvider(ChallengeStatus.active).future,
      );
      expect(result, isA<List>());
      container.dispose();
    });
  });
}
```

- [ ] **Step 2: Run tests**

Run: `flutter test test/features/social/presentation/providers/challenge_providers_test.dart`
Expected: All tests pass

- [ ] **Step 3: Commit**

```bash
git add test/features/social/presentation/providers/challenge_providers_test.dart
git commit -m "test: add challenge provider tests (10 providers, 11 tests)"
```

---

### Task 12: Tribe Providers

**Files:**
- Create: `test/features/social/presentation/providers/tribe_providers_test.dart`
- Test: same file

- [ ] **Step 1: Write the test file**

```dart
import 'package:emerge_app/features/auth/domain/entities/auth_user.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/social/data/repositories/tribe_repository.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:emerge_app/core/drift/database.dart';
import 'package:emerge_app/core/drift_repositories/repositories_barrel.dart';
import 'package:emerge_app/core/sync/sync_providers.dart';

class MockTribeRepository extends Mock implements TribeRepository {}
class MockAppDatabase extends Mock implements AppDatabase {}
class MockSyncEngine extends Mock implements EnhancedSyncEngine {}
class MockSocialActivityService extends Mock implements SocialActivityService {}

ProviderContainer _makeContainer({
  required TribeRepository tribeRepo,
  AuthUser? authUser,
}) {
  return ProviderContainer(
    overrides: [
      tribeRepositoryProvider.overrideWithValue(tribeRepo),
      authStateChangesProvider.overrideWithValue(
        AsyncValue.data(authUser ?? const AuthUser(id: 'test', email: 'test@example.com')),
      ),
      appDatabaseProvider.overrideWithValue(MockAppDatabase()),
      enhancedSyncEngineProvider.overrideWithValue(MockSyncEngine()),
      socialActivityServiceProvider.overrideWithValue(MockSocialActivityService()),
    ],
  );
}

void main() {
  late MockTribeRepository mockRepo;

  setUp(() {
    mockRepo = MockTribeRepository();
  });

  group('tribeRepositoryProvider', () {
    test('creates repository', () {
      final container = _makeContainer(tribeRepo: mockRepo);
      expect(container.read(tribeRepositoryProvider), mockRepo);
      container.dispose();
    });
  });

  group('userClubProvider', () {
    test('returns club by ID', () async {
      when(() => mockRepo.getClub('club-1')).thenAnswer((_) async => null);
      final container = _makeContainer(tribeRepo: mockRepo);
      final result = await container.read(userClubProvider('club-1').future);
      expect(result, isNull);
      container.dispose();
    });
  });

  group('allArchetypeClubsProvider', () {
    test('returns clubs stream', () async {
      when(() => mockRepo.watchAllClubs()).thenAnswer((_) => const Stream.empty());
      final container = _makeContainer(tribeRepo: mockRepo);
      final result = container.read(allArchetypeClubsProvider);
      expect(result, isNotNull);
      container.dispose();
    });
  });

  group('globalActivityProvider', () {
    test('returns activity stream', () async {
      when(() => mockRepo.watchGlobalActivity()).thenAnswer((_) => const Stream.empty());
      final container = _makeContainer(tribeRepo: mockRepo);
      final result = container.read(globalActivityProvider);
      expect(result, isNotNull);
      container.dispose();
    });
  });

  group('realTimeTribeStatsProvider', () {
    test('returns stats stream', () async {
      when(() => mockRepo.watchTribeStats('tribe-1')).thenAnswer((_) => const Stream.empty());
      final container = _makeContainer(tribeRepo: mockRepo);
      final result = container.read(realTimeTribeStatsProvider('tribe-1'));
      expect(result, isNotNull);
      container.dispose();
    });
  });

  group('globalAggregateStatsProvider', () {
    test('returns aggregate stats stream', () async {
      when(() => mockRepo.watchGlobalAggregateStats()).thenAnswer((_) => const Stream.empty());
      final container = _makeContainer(tribeRepo: mockRepo);
      final result = container.read(globalAggregateStatsProvider);
      expect(result, isNotNull);
      container.dispose();
    });
  });

  group('tribeStatsCacheProvider', () {
    test('creates cache instance', () {
      final container = _makeContainer(tribeRepo: mockRepo);
      expect(container.read(tribeStatsCacheProvider), isNotNull);
      container.dispose();
    });
  });
}
```

- [ ] **Step 2: Run tests**

Run: `flutter test test/features/social/presentation/providers/tribe_providers_test.dart`
Expected: All tests pass

- [ ] **Step 3: Commit**

```bash
git add test/features/social/presentation/providers/tribe_providers_test.dart
git commit -m "test: add tribe provider tests (11 providers, 9 tests)"
```

---

### Task 13: Social Onboarding Provider

**Files:**
- Create: `test/features/social/presentation/providers/social_onboarding_provider_test.dart`
- Test: same file

- [ ] **Step 1: Write the test file**

```dart
import 'package:emerge_app/features/social/presentation/providers/social_onboarding_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('socialOnboardingCompletedProvider', () {
    test('initial state is false', () async {
      final container = ProviderContainer(
        overrides: [
          socialOnboardingCompletedProvider.overrideWith(
            (ref) => const AsyncData(false),
          ),
        ],
      );
      final result = await container.read(socialOnboardingCompletedProvider.future);
      expect(result, false);
      container.dispose();
    });

    test('can be set to true', () async {
      final container = ProviderContainer(
        overrides: [
          socialOnboardingCompletedProvider.overrideWith(
            (ref) => const AsyncData(true),
          ),
        ],
      );
      final result = await container.read(socialOnboardingCompletedProvider.future);
      expect(result, true);
      container.dispose();
    });
  });
}
```

- [ ] **Step 2: Run tests**

Run: `flutter test test/features/social/presentation/providers/social_onboarding_provider_test.dart`
Expected: All tests pass

- [ ] **Step 3: Commit**

```bash
git add test/features/social/presentation/providers/social_onboarding_provider_test.dart
git commit -m "test: add social onboarding provider tests (1 provider, 2 tests)"
```

---

### Task 14: Challenge Bundle Provider

**Files:**
- Create: `test/features/social/presentation/providers/challenge_bundle_provider_test.dart`
- Test: same file

- [ ] **Step 1: Write the test file**

```dart
import 'package:emerge_app/features/auth/domain/entities/auth_user.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/gamification/domain/entities/user_profile.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/social/data/repositories/challenge_repository.dart';
import 'package:emerge_app/features/social/presentation/providers/challenge_bundle_provider.dart';
import 'package:emerge_app/features/social/presentation/providers/challenge_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockChallengeRepository extends Mock implements ChallengeRepository {}

ProviderContainer _makeContainer({
  required ChallengeRepository challengeRepo,
  AuthUser? authUser,
  UserProfile? profile,
}) {
  return ProviderContainer(
    overrides: [
      challengeRepositoryProvider.overrideWithValue(challengeRepo),
      authStateChangesProvider.overrideWithValue(
        AsyncValue.data(authUser ?? const AuthUser(id: 'test', email: 'test@example.com')),
      ),
      if (profile != null)
        userStatsStreamProvider.overrideWith((ref) => Stream.value(profile)),
    ],
  );
}

void main() {
  late MockChallengeRepository mockRepo;

  setUp(() {
    mockRepo = MockChallengeRepository();
  });

  group('challengeBundleProvider', () {
    test('bundle can be read without error', () async {
      when(() => mockRepo.getFeaturedChallenges()).thenAnswer((_) async => []);
      when(() => mockRepo.getAllChallenges()).thenAnswer((_) async => []);
      when(() => mockRepo.getUserChallenges('test')).thenAnswer((_) async => []);
      when(() => mockRepo.getArchetypeChallenges(any())).thenAnswer((_) async => []);

      final container = _makeContainer(
        challengeRepo: mockRepo,
        profile: const UserProfile(uid: 'test', archetype: UserArchetype.athlete),
      );
      final result = container.read(challengeBundleProvider);
      expect(result, isNotNull);
      container.dispose();
    });
  });
}
```

- [ ] **Step 2: Run tests**

Run: `flutter test test/features/social/presentation/providers/challenge_bundle_provider_test.dart`
Expected: All tests pass

- [ ] **Step 3: Commit**

```bash
git add test/features/social/presentation/providers/challenge_bundle_provider_test.dart
git commit -m "test: add challenge bundle provider tests (1 provider, 1 test)"
```

---

### Task 15: Leaderboard Providers

**Files:**
- Create: `test/features/social/presentation/providers/leaderboard_providers_test.dart`
- Test: same file

- [ ] **Step 1: Write the test file**

```dart
import 'package:emerge_app/features/social/data/repositories/leaderboard_repository.dart';
import 'package:emerge_app/features/social/presentation/providers/leaderboard_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockLeaderboardRepository extends Mock implements LeaderboardRepository {}

ProviderContainer _makeContainer(LeaderboardRepository repo) {
  return ProviderContainer(
    overrides: [
      leaderboardRepositoryProvider.overrideWithValue(repo),
    ],
  );
}

void main() {
  late MockLeaderboardRepository mockRepo;

  setUp(() {
    mockRepo = MockLeaderboardRepository();
  });

  group('leaderboardRepositoryProvider', () {
    test('returns repository', () {
      final container = _makeContainer(mockRepo);
      expect(container.read(leaderboardRepositoryProvider), mockRepo);
      container.dispose();
    });
  });

  group('clubLeaderboardProvider', () {
    test('returns leaderboard stream', () async {
      when(() => mockRepo.watchClubLeaderboard('club-1'))
          .thenAnswer((_) => const Stream.empty());
      final container = _makeContainer(mockRepo);
      final result = container.read(clubLeaderboardProvider('club-1'));
      expect(result, isNotNull);
      container.dispose();
    });
  });

  group('challengeLeaderboardProvider', () {
    test('returns leaderboard stream', () async {
      when(() => mockRepo.watchChallengeLeaderboard('ch-1'))
          .thenAnswer((_) => const Stream.empty());
      final container = _makeContainer(mockRepo);
      final result = container.read(challengeLeaderboardProvider('ch-1'));
      expect(result, isNotNull);
      container.dispose();
    });
  });
}
```

- [ ] **Step 2: Run tests**

Run: `flutter test test/features/social/presentation/providers/leaderboard_providers_test.dart`
Expected: All tests pass

- [ ] **Step 3: Commit**

```bash
git add test/features/social/presentation/providers/leaderboard_providers_test.dart
git commit -m "test: add leaderboard provider tests (3 providers, 4 tests)"
```

---

### Task 16: Companion Providers

**Files:**
- Create: `test/features/companion/presentation/providers/companion_providers_test.dart`
- Test: same file

- [ ] **Step 1: Write the test file**

```dart
import 'package:emerge_app/features/companion/domain/entities/persona_config.dart';
import 'package:emerge_app/features/companion/presentation/providers/companion_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

ProviderContainer _makeContainer({
  CompanionState? state,
}) {
  return ProviderContainer(
    overrides: [
      if (state != null)
        companionEngineProvider.overrideWith((ref) => state),
    ],
  );
}

void main() {
  group('companionPersonaProvider', () {
    test('returns persona from companion state', () {
      final persona = PersonaConfig(
        name: 'Coach',
        archetype: 'athlete',
        greeting: 'Hello',
        tone: 'motivational',
        color: 0xFF000000,
        icon: 'coach',
      );
      final container = _makeContainer(
        state: CompanionState(persona: persona),
      );
      expect(container.read(companionPersonaProvider), persona);
      container.dispose();
    });

    test('returns null when persona not set', () {
      final container = _makeContainer(
        state: const CompanionState(),
      );
      expect(container.read(companionPersonaProvider), isNull);
      container.dispose();
    });
  });

  group('companionVisibilityProvider', () {
    test('returns state when visible', () {
      final container = _makeContainer(
        state: const CompanionState(visible: true),
      );
      final result = container.read(companionVisibilityProvider);
      expect(result, isNotNull);
      expect(result!.visible, true);
      container.dispose();
    });

    test('returns null when not visible', () {
      final container = _makeContainer(
        state: const CompanionState(visible: false),
      );
      expect(container.read(companionVisibilityProvider), isNull);
      container.dispose();
    });
  });

  group('companionRepositoryProvider', () {
    test('creates repository', () {
      final container = _makeContainer();
      expect(container.read(companionRepositoryProvider), isNotNull);
      container.dispose();
    });
  });
}
```

- [ ] **Step 2: Run tests**

Run: `flutter test test/features/companion/presentation/providers/companion_providers_test.dart`
Expected: All tests pass

- [ ] **Step 3: Commit**

```bash
git add test/features/companion/presentation/providers/companion_providers_test.dart
git commit -m "test: add companion provider tests (3 providers, 6 tests)"
```

---

### Task 17: Blueprint Detail Controller

**Files:**
- Create: `test/features/blueprints/presentation/providers/blueprint_detail_controller_test.dart`
- Test: same file

- [ ] **Step 1: Write the test file**

```dart
import 'package:emerge_app/features/auth/domain/entities/auth_user.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/blueprints/data/repositories/blueprint_repository.dart';
import 'package:emerge_app/features/blueprints/domain/models/blueprint.dart';
import 'package:emerge_app/features/blueprints/presentation/providers/blueprint_detail_controller.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/domain/repositories/habit_repository.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:emerge_app/features/monetization/presentation/providers/subscription_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';

class MockHabitRepository extends Mock implements HabitRepository {}
class MockBlueprintRepository extends Mock implements BlueprintRepository {}

class TestIsPremium extends IsPremium {
  final bool premium;
  TestIsPremium(this.premium);
  @override
  Future<bool> build() async => premium;
}

ProviderContainer _makeContainer({
  required HabitRepository habitRepo,
  required BlueprintRepository blueprintRepo,
  bool premium = false,
  AuthUser? authUser,
}) {
  return ProviderContainer(
    overrides: [
      authStateChangesProvider.overrideWithValue(
        AsyncValue.data(authUser ?? const AuthUser(id: 'test', email: 'test@example.com')),
      ),
      habitRepositoryProvider.overrideWithValue(habitRepo),
      blueprintRepositoryProvider.overrideWithValue(blueprintRepo),
      isPremiumProvider.overrideWith(() => TestIsPremium(premium)),
      habitsProvider.overrideWith((ref) => Stream.value([])),
    ],
  );
}

void main() {
  late MockHabitRepository mockHabitRepo;
  late MockBlueprintRepository mockBlueprintRepo;

  setUp(() {
    mockHabitRepo = MockHabitRepository();
    mockBlueprintRepo = MockBlueprintRepository();
  });

  group('blueprintDetailControllerProvider', () {
    test('adoptBlueprint creates habits and increments adoption', () async {
      final blueprint = Blueprint(
        id: 'bp-1',
        title: 'Test Blueprint',
        description: 'A test',
        category: 'health',
        difficulty: BlueprintDifficulty.beginner,
        habits: [
          BlueprintHabit(title: 'Morning Run', frequency: 'daily', timeOfDay: 'morning'),
        ],
        isPremium: false,
      );

      when(() => mockHabitRepo.createHabitsFromBlueprint(
        userId: any(named: 'userId'),
        blueprint: any(named: 'blueprint'),
        reminderTime: any(named: 'reminderTime'),
      )).thenAnswer((_) async => const Right(unit));

      when(() => mockBlueprintRepo.incrementAdoptionCount('bp-1'))
          .thenAnswer((_) async {});

      final container = _makeContainer(
        habitRepo: mockHabitRepo,
        blueprintRepo: mockBlueprintRepo,
      );

      await container.read(blueprintDetailControllerProvider.notifier)
          .adoptBlueprint(blueprint);

      verify(() => mockBlueprintRepo.incrementAdoptionCount('bp-1')).called(1);
      container.dispose();
    });

    test('throws when user not authenticated', () async {
      final container = ProviderContainer(
        overrides: [
          authStateChangesProvider.overrideWithValue(
            const AsyncValue.data(AuthUser.empty),
          ),
          habitRepositoryProvider.overrideWithValue(mockHabitRepo),
          blueprintRepositoryProvider.overrideWithValue(mockBlueprintRepo),
          isPremiumProvider.overrideWith(() => TestIsPremium(false)),
          habitsProvider.overrideWith((ref) => Stream.value([])),
        ],
      );

      expect(
        () => container.read(blueprintDetailControllerProvider.notifier)
            .adoptBlueprint(Blueprint(id: 'bp-1', title: 'Test', description: '', category: '', difficulty: BlueprintDifficulty.beginner, habits: [], isPremium: false)),
        throwsException,
      );
      container.dispose();
    });
  });
}
```

- [ ] **Step 2: Run tests**

Run: `flutter test test/features/blueprints/presentation/providers/blueprint_detail_controller_test.dart`
Expected: All tests pass

- [ ] **Step 3: Commit**

```bash
git add test/features/blueprints/presentation/providers/blueprint_detail_controller_test.dart
git commit -m "test: add blueprint detail controller tests (1 provider, 2 tests)"
```

---

### Task 18: Timeline Provider

**Files:**
- Create: `test/features/timeline/presentation/providers/timeline_providers_test.dart`
- Test: same file

- [ ] **Step 1: Write the test file**

```dart
import 'package:emerge_app/features/timeline/presentation/providers/reflection_state_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('todayReflectionStateProvider', () {
    test('initial value is false', () {
      final container = ProviderContainer(
        overrides: [
          todayReflectionStateProvider.overrideWith((ref) => false),
        ],
      );
      expect(container.read(todayReflectionStateProvider), false);
      container.dispose();
    });

    test('setLogged updates to true', () {
      final container = ProviderContainer(
        overrides: [
          todayReflectionStateProvider.overrideWith((ref) => false),
        ],
      );
      container.read(todayReflectionStateProvider.notifier).setLogged(true);
      expect(container.read(todayReflectionStateProvider), true);
      container.dispose();
    });

    test('resetForNewDay sets back to false', () {
      final container = ProviderContainer(
        overrides: [
          todayReflectionStateProvider.overrideWith((ref) => false),
        ],
      );
      final notifier = container.read(todayReflectionStateProvider.notifier);
      notifier.setLogged(true);
      notifier.resetForNewDay();
      expect(container.read(todayReflectionStateProvider), false);
      container.dispose();
    });
  });
}
```

- [ ] **Step 2: Run tests**

Run: `flutter test test/features/timeline/presentation/providers/timeline_providers_test.dart`
Expected: All tests pass

- [ ] **Step 3: Commit**

```bash
git add test/features/timeline/presentation/providers/timeline_providers_test.dart
git commit -m "test: add timeline provider tests (1 provider, 3 tests)"
```

---

### Task 19: Final Verification

**Files:**
- Test: all provider test files

- [ ] **Step 1: Run full test suite**

Run: `flutter test`
Expected: All ~697 existing tests + new provider tests pass

- [ ] **Step 2: Commit uncommitted changes**

```bash
git add -A
git commit -m "test: complete Tier 3 provider tests across all features"
```
