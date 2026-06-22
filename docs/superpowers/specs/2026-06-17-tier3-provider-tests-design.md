# Tier 3: Provider Tests — Design Document

## Overview

Test all 67 testable Riverpod providers across the Emerge app. Providers are grouped into test files by logical concern (shared mock setup). No providers carved out — every Easy and Medium provider gets coverage. Hard providers (24 — Firebase-instance, RevenueCat, platform API) are excluded from unit testing.

## Testability Classification

| Category | Count | Description |
|----------|-------|-------------|
| Easy | 32 | Pure derived/selector providers — override parent provider, assert output |
| Medium | 35 | Require mock repository/service overrides in ProviderContainer |
| Hard (excluded) | 24 | Firebase.instance, RevenueCat, platform SDK — not unit-testable |

## Approach

- **Grouping**: Test files grouped by shared mock dependencies (not one-per-provider, not one-per-feature)
- **Pattern**: `ProviderContainer` + `overrides` with mocktail mocks — established by `onboarding_state_notifier_test.dart`
- **Mocking**: Inline mocktail `Mock` classes per test file; `registerFallbackValue` in `setUpAll`
- **Order**: All files implemented in one pass (no phased rollout)

## Complete File List

### 1. `test/features/gamification/presentation/providers/gamification_derived_providers_test.dart`

**Mock setup**: Override `userStatsStreamProvider` with mock `UserProfile` stream.

| Provider | Type | Dependencies |
|----------|------|--------------|
| `currentArchetypeProvider` | `Provider<UserArchetype>` | `userStatsStreamProvider` |
| `isOnboardingCompleteProvider` | `Provider<bool>` | `userStatsStreamProvider` |
| `userAvatarStatsProvider` | `StreamProvider<UserAvatarStats>` | `userStatsStreamProvider` |
| `userLevelProvider` | `StreamProvider<int>` | `userStatsStreamProvider` |
| `userStreakProvider` | `StreamProvider<int>` | `userStatsStreamProvider` |
| `attributeProgressFromHabitsProvider` | `Provider<Map<String, AttributeProgress>>` | `userStatsStreamProvider` |
| `attributeProgressProvider` | `Provider.family<AttributeProgress?, String>` | `attributeProgressFromHabitsProvider` |

**Tests** (~18): archetype mapping for all 4 archetypes, onboarding true/false, avatar stats empty vs populated, level calculation boundary (0, 1, 50, 100), streak display (0, 1, 365), attribute progress calculation, per-attribute lookup by key, missing attribute returns null.

### 2. `test/features/gamification/presentation/providers/gamification_state_providers_test.dart`

**Mock setup**: Override `userStatsRepositoryProvider` (mock Drift repo) + `authStateChangesProvider`.

| Provider | Type | Dependencies |
|----------|------|--------------|
| `userProfileProvider` | `StreamProvider<UserProfile?>` | `authStateChangesProvider`, `userProfileRepositoryProvider` |
| `userStatsStreamProvider` | `StreamProvider<UserProfile>` | `authStateChangesProvider`, `userStatsRepositoryProvider` |
| `userStatsControllerProvider` | `Provider<UserStatsController>` | Drift repo, Auth, SocialActivityService |
| `historicalRecapsProvider` | `FutureProvider<List<UserWeeklyRecap>>` | `authStateChangesProvider`, `userStatsRepositoryProvider` |
| `recapRefreshCounterProvider` | `NotifierProvider<RecapRefreshCounter, int>` | None (pure) |

**Tests** (~15): profile stream returns null when not authed, profile stream returns user, stats stream wraps profile, UserStatsController delegates to repo, recaps list empty/with data, recap error fallback, counter increment/reset.

### 3. `test/features/habits/presentation/providers/dashboard_selectors_test.dart`

**Mock setup**: Override `dashboardStateProvider` with specific `DashboardState` instances.

| Provider | Type | Dependencies |
|----------|------|--------------|
| `todaysHabitsProvider` | `Provider<List<Habit>>` | `dashboardStateProvider` |
| `todayCompletionRateProvider` | `Provider<double>` | `dashboardStateProvider` |
| `isDashboardLoadingProvider` | `Provider<bool>` | `dashboardStateProvider` |
| `dashboardErrorProvider` | `Provider<String?>` | `dashboardStateProvider` |

**Tests** (~12): todaysHabits filters by today, completionRate 0% when none done, 50% when half done, 100% when all done, loading true/false, error string, error null.

### 4. `test/features/habits/presentation/providers/dashboard_state_provider_test.dart`

**Mock setup**: Override all dependencies of `DashboardStateNotifier` — `habitsProvider`, `userProfileProvider`, `activeMilestonesProvider`, etc.

| Provider | Type | Dependencies |
|----------|------|--------------|
| `dashboardStateProvider` | `NotifierProvider<DashboardStateNotifier, DashboardState>` | habits, profile, milestones, etc. |

**Tests** (~10): initial state, state transitions, error handling.

### 5. `test/features/habits/presentation/providers/habit_core_providers_test.dart`

**Mock setup**: Override `habitRepositoryProvider` (mock Drift) + `authStateChangesProvider` + `enhancedSyncEngineProvider` + `socialActivityServiceProvider`.

| Provider | Type | Dependencies |
|----------|------|--------------|
| `habitRepositoryProvider` | `Provider<HabitRepository>` | Drift, Sync, Social |
| `habitsProvider` | `StreamProvider<List<Habit>>` | `habitRepositoryProvider`, `authStateChangesProvider` |
| `habitActivityProvider` | `FutureProvider<List<HabitActivity>>` | `habitRepositoryProvider`, `authStateChangesProvider` |
| `momentumServiceProvider` | `Provider<MomentumService>` | None |

**Tests** (~12): repository creation, habit stream emits list, empty stream, activity log, activity empty/filtered, momentumService is singleton.

### 6. `test/features/habits/presentation/providers/habit_action_providers_test.dart`

**Mock setup**: Override `habitRepositoryProvider`, `authStateChangesProvider`, `remoteConfigServiceProvider`, `isPremiumProvider`.

| Provider | Type | Dependencies |
|----------|------|--------------|
| `createHabitProvider` | `FutureProvider<void>` (family) | habitRepo, RemoteConfig, isPremium |
| `completeHabitProvider` | `FutureProvider<HabitCompletionResult>` (family) | habitRepo, XP calc, streak, world health, social |

**Tests** (~10): create habit success, creation blocked by subscription limit, complete habit XP calculation, streak milestone triggers, error propagation.

### 7. `test/features/habits/presentation/providers/cue_providers_test.dart`

**Mock setup**: Override `cueEngineProvider` with mock `CueEngine`.

| Provider | Type | Dependencies |
|----------|------|--------------|
| `cueNotifierProvider` | `NotifierProvider<CueNotifier, void>` | `cueEngineProvider` |
| `cueMetricsProvider` | `Provider.family<CueEngagementMetrics?, String>` | `cueEngineProvider` |
| `cuePerformanceProvider` | `Provider<Map<String, dynamic>>` | `cueEngineProvider` |

**Tests** (~9): cue stream subscription, metrics for specific cue, metrics null for unknown, performance map structure.

### 8. `test/features/auth/presentation/providers/auth_providers_test.dart`

**Mock setup**: Override `authRepositoryProvider` with mock `AuthRepository`.

| Provider | Type | Dependencies |
|----------|------|--------------|
| `authRepositoryProvider` | `Provider<AuthRepository>` | Firebase (can mock the DI itself) |
| `authStateChangesProvider` | `StreamProvider<AuthUser>` | `authRepositoryProvider` |
| `signInProvider` | `FutureProvider<void>` (family) | `authRepositoryProvider` |
| `signOutProvider` | `FutureProvider<void>` | `authRepositoryProvider` |

**Tests** (~10): authStateChanges maps null to unknown, maps Firebase user to AuthUser, signIn calls repo, signOut calls repo, error handling.

### 9. `test/features/onboarding/presentation/providers/onboarding_providers_test.dart`

**Mock setup**: Override `onboardingStateControllerProvider` + `userStatsStreamProvider`.

| Provider | Type | Dependencies |
|----------|------|--------------|
| `onboardingStateControllerProvider` | `NotifierProvider<OnboardingStateController, OnboardingState>` | None (pure) |
| `selectedArchetypeProvider` | `Provider<UserArchetype?>` | `onboardingStateControllerProvider` |
| `attributePointsProvider` | `Provider<int>` | `onboardingStateControllerProvider` |
| `attributesProvider` | `Provider<Map<String, int>>` | `onboardingStateControllerProvider` |
| `activeMilestonesProvider` | `Provider<List<OnboardingMilestone>>` | `userStatsStreamProvider` |
| `isOnboardingActiveProvider` | `Provider<bool>` | `enhancedOnboardingProvider` |
| `onboardingProgressProvider` | `Provider<double>` | `enhancedOnboardingProvider` |
| `localSettingsRepositoryProvider` | `Provider<LocalSettingsRepository>` | SharedPrefs |

**Tests** (~18): state transitions through onboarding steps, archetype selection updates state, attribute points accumulate, milestones unlock based on stats, progress percentage, local settings creation.

### 10. `test/features/world_map/presentation/providers/world_map_providers_test.dart`

**Mock setup**: Override `worldHealthServiceProvider` (mock `WorldHealthService`) + `authStateChangesProvider`.

| Provider | Type | Dependencies |
|----------|------|--------------|
| `worldHealthServiceProvider` | `Provider<WorldHealthService>` | Drift repo |
| `worldHealthProvider` | `FutureProvider<double>` | `authStateChangesProvider`, `worldHealthServiceProvider` |
| `worldHealthStreamProvider` | `StreamProvider<double>` | `authStateChangesProvider`, Drift |
| `worldEntropyStreamProvider` | `StreamProvider<double>` | `authStateChangesProvider`, Drift |

**Tests** (~10): health service creation, worldHealth returns correct value, stream emits health updates, entropy stream, error handling.

### 11. `test/features/social/presentation/providers/challenge_providers_test.dart`

**Mock setup**: Override `challengeRepositoryProvider` (mock `ChallengeRepository`) + `authStateChangesProvider` + `userStatsStreamProvider`.

| Provider | Type | Dependencies |
|----------|------|--------------|
| `challengeRepositoryProvider` | `Provider<ChallengeRepository>` | Drift, GameLoop, Sync |
| `featuredChallengesProvider` | `FutureProvider<List<Challenge>>` | `challengeRepositoryProvider` |
| `allChallengesProvider` | `FutureProvider<List<Challenge>>` | `challengeRepositoryProvider` |
| `userChallengesProvider` | `FutureProvider<List<Challenge>>` | `challengeRepositoryProvider`, `authStateChangesProvider` |
| `archetypeChallengesProvider` | `FutureProvider<List<Challenge>>` | `challengeRepositoryProvider`, `userStatsStreamProvider` |
| `weeklySpotlightProvider` | `FutureProvider<Challenge?>` | `challengeRepositoryProvider`, `userStatsStreamProvider` |
| `dailyQuestProvider` | `FutureProvider<Challenge?>` | `userStatsStreamProvider` |
| `challengeLeaderboardProvider` | `FutureProvider.family<List<Map>, String>` | `challengeRepositoryProvider` |
| `challengeByIdProvider` | `FutureProvider.family<Challenge?, String>` | `challengeRepositoryProvider` |
| `filteredChallengesProvider` | `FutureProvider.family<List<Challenge>, ChallengeStatus>` | `featuredChallengesProvider`, `userChallengesProvider` |

**Tests** (~20): featured list, all challenges, user challenges filters by auth, archetype challenges filters by archetype, weekly spotlight picks one, daily quest from catalog, leaderboard per challenge, challenge by ID, filtered by status.

### 12. `test/features/social/presentation/providers/challenge_bundle_provider_test.dart`

**Mock setup**: Override all deps of `ChallengeBundle` AsyncNotifier — Auth, UserStats, ChallengeRepository.

| Provider | Type | Dependencies |
|----------|------|--------------|
| `challengeBundleProvider` | `AsyncNotifierProvider<ChallengeBundle, ChallengeBundleData>` | Auth, UserStats, ChallengeRepository |
| Bundle selectors (×5) | Various `Provider` | `challengeBundleProvider` |

**Tests** (~10): bundle loading state, bundle loaded with data, selector derivations, error state.

### 13. `test/features/social/presentation/providers/tribe_providers_test.dart`

**Mock setup**: Override `tribeRepositoryProvider` (mock `TribeRepository`) + `authStateChangesProvider`.

| Provider | Type | Dependencies |
|----------|------|--------------|
| `tribeRepositoryProvider` | `Provider<TribeRepository>` | Drift, Sync |
| `socialActivityServiceProvider` | `Provider<SocialActivityService>` | Sync, Drift |
| `userClubProvider` | `FutureProvider.family<Tribe?, String>` | `tribeRepositoryProvider` |
| `allArchetypeClubsProvider` | `StreamProvider<List<Tribe>>` | `tribeRepositoryProvider` |
| `clubContributorsProvider` | `StreamProvider.family<List<Map>, String>` | Drift DAO |
| `clubActivityProvider` | `StreamProvider.family<List<Map>, String>` | `tribeRepositoryProvider` |
| `globalActivityProvider` | `StreamProvider<List<Map>>` | `tribeRepositoryProvider` |
| `tribeAggregateProvider` | `StreamProvider.family<Map, String>` | `tribeRepositoryProvider` |
| `realTimeTribeStatsProvider` | `StreamProvider.family<TribeStats, String>` | `tribeRepositoryProvider` |
| `globalAggregateStatsProvider` | `StreamProvider<TribeStats>` | `tribeRepositoryProvider` |
| `tribeStatsCacheProvider` | `Provider<TribeStatsCache>` | None |

**Tests** (~20): tribe repo creation, user club by ID, all archetype clubs, club contributors, activity stream, aggregate stats, real-time stats, global stats, cache operations.

### 14. `test/features/social/presentation/providers/leaderboard_providers_test.dart`

**Mock setup**: Override `leaderboardRepositoryProvider` (mock `LeaderboardRepository`).

| Provider | Type | Dependencies |
|----------|------|--------------|
| `leaderboardRepositoryProvider` | `Provider<LeaderboardRepository>` | Drift |
| `clubLeaderboardProvider` | `StreamProvider.family<List<LeaderboardEntry>, String>` | `leaderboardRepositoryProvider` |
| `challengeLeaderboardProvider` | `StreamProvider.family<List<LeaderboardEntry>, String>` | `leaderboardRepositoryProvider` |

**Tests** (~6): club leaderboard, challenge leaderboard, empty states, error handling.

### 15. `test/features/social/presentation/providers/social_onboarding_provider_test.dart`

**Mock setup**: Override provider that wraps `SharedPreferences`.

| Provider | Type | Dependencies |
|----------|------|--------------|
| `socialOnboardingCompletedProvider` | `AsyncNotifierProvider<SocialOnboardingNotifier, bool>` | `SharedPreferences` |

**Tests** (~6): initial state (false), mark completed, reset, error handling.

### 16. `test/features/companion/presentation/providers/companion_providers_test.dart`

**Mock setup**: Override `companionEngineProvider` with mock `CompanionEngine`.

| Provider | Type | Dependencies |
|----------|------|--------------|
| `companionRepositoryProvider` | `Provider<CompanionRepository>` | SharedPrefs |
| `companionPersonaProvider` | `Provider<PersonaConfig?>` | `companionEngineProvider` |
| `companionVisibilityProvider` | `Provider<CompanionState?>` | `companionEngineProvider` |

**Tests** (~8): repo creation, persona derives from engine state, persona null when engine idle, visibility derives from state.

### 17. `test/features/blueprints/presentation/providers/blueprint_detail_controller_test.dart`

**Mock setup**: Override auth, subscription, habit repository, blueprint repository.

| Provider | Type | Dependencies |
|----------|------|--------------|
| `blueprintDetailControllerProvider` | `AsyncNotifierProvider<BlueprintDetailController, void>` | Auth, Subscription, HabitRepository, BlueprintRepository |

**Tests** (~8): apply blueprint creates habits, error on missing auth, error on repository failure.

### 18. `test/features/timeline/presentation/providers/timeline_providers_test.dart`

**Mock setup**: None — pure logic.

| Provider | Type | Dependencies |
|----------|------|--------------|
| `todayReflectionStateProvider` | `NotifierProvider<TodayReflectionState, bool>` | None |

**Tests** (~4): initial false, toggle true, toggle back to false.

## Testing Pattern

```dart
// Per-file factory factory
ProviderContainer _makeContainer({
  required MockUserStatsRepository repo,
  AuthUser? authUser,
}) {
  return ProviderContainer(
    overrides: [
      authStateChangesProvider.overrideWithValue(
        AsyncValue.data(authUser ?? const AuthUser(id: 'test', email: 'test@example.com')),
      ),
      userStatsRepositoryProvider.overrideWithValue(repo),
    ],
  );
}

// Standard test
group('currentArchetypeProvider', () {
  test('returns athlete archetype from profile', () {
    when(() => mockRepo.watchUserProfile(any())).thenAnswer(
      (_) => Stream.value(const UserProfile(uid: 'test', archetype: UserArchetype.athlete)),
    );
    final container = _makeContainer(repo: mockRepo);
    expect(container.read(currentArchetypeProvider), UserArchetype.athlete);
  });
});
```

## Verification

Run `flutter test` — all new tests + existing suite must pass.
