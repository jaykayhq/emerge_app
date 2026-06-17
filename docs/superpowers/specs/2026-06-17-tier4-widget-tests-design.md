# Tier 4: Widget/Screen Tests — Design Document

## Overview

Write comprehensive widget tests for all 43 screens across the Emerge app. Every screen gets full state coverage — loading, empty, data, error, and key interactions. Builds directly on Tier 3's provider testing infrastructure (`ProviderContainer` + `ProviderScope` override pattern with mocktail mocks).

## Current State

| Layer | Tier | Tests | Status |
|-------|------|-------|--------|
| Models | T1 | ~300 | Complete |
| Services | T2 | ~400 | Complete |
| Providers | T3 | ~107 | Complete |
| Screen widgets | T4 | 6/49 (12%) | **Target** |

## Approach

- **Coverage**: Full state coverage for every screen (loading, empty, data, error, interaction)
- **Grouping**: By feature area, implemented in parallel phases
- **Pattern**: `ProviderScope` wrapping + `ProviderContainer` overrides (same as Tier 3)
- **Scaffolding**: Shared `createScreenUnderTest()` utility to reduce boilerplate
- **Mocks**: Reuse mock classes and patterns from Tier 3 test files; extract shared mocks into `test/helpers/`

## Screen Inventory

### Onboarding (4 screens, ~16 tests)

| Screen | Key States | Dependencies |
|--------|-----------|--------------|
| `welcome_screen` | initial render, exit button | None (static) |
| `identity_studio_screen` | archetype grid, selected state, confirm flow | `onboardingStateControllerProvider`, `selectedArchetypeProvider` |
| `first_habit_screen` | empty, template list, selection, skip | `onboardingStateControllerProvider`, `habitRepositoryProvider` |
| `world_reveal_screen` | loading, reveal animation, continue | `onboardingStateControllerProvider` |

### Auth (3 screens, ~12 tests)

| Screen | Key States | Dependencies |
|--------|-----------|--------------|
| `login_screen` | form render, validation error, submission loading, error toast | `authRepositoryProvider` |
| `signup_screen` | form render, validation, submission, error | `authRepositoryProvider` |
| `creator_login_screen` | initial, login flow, error | `authRepositoryProvider` |

### Habits (3 screens, ~15 tests)

| Screen | Key States | Dependencies |
|--------|-----------|--------------|
| `habit_detail_screen` | loading, habit data, empty, completion toggle, delete | `habitsProvider`, `habitActivityProvider` |
| `advanced_create_habit_dialog` | form render, validation, submission, premium gate | `createHabitProvider`, `isPremiumProvider` |
| `streak_recovery_screen` | loading, streak data, recovery options, boost action | `userStreakProvider`, `completeHabitProvider` |

### Dashboard/Gamification (3 screens, ~15 tests)

| Screen | Key States | Dependencies |
|--------|-----------|--------------|
| `weekly_recap_screen` | loading, recap data, empty week, share action | `historicalRecapsProvider`, `userStatsStreamProvider` |
| `recap_hub_screen` | loading, recaps list, empty, tap recap | `historicalRecapsProvider` |
| `leveling_screen` | loading, level data, progress bar, rank-up animation | `userLevelProvider`, `userAvatarStatsProvider` |

### Timeline (1 screen, ~5 tests)

| Screen | Key States | Dependencies |
|--------|-----------|--------------|
| `timeline_screen` | loading, timeline entries, empty, reflection toggle | `todayReflectionStateProvider`, `habitsProvider` |

### World Map (2 screens, ~10 tests)

| Screen | Key States | Dependencies |
|--------|-----------|--------------|
| `world_map_screen` | loading, health data, region rendering | `worldHealthProvider`, `worldHealthStreamProvider` |
| `level_immersive_screen` | loading, level data, immersion animation | `worldHealthProvider`, `userLevelProvider`, `worldEntropyStreamProvider` |

### Social (12 screens, ~55 tests)

| Screen | Key States | Dependencies |
|--------|-----------|--------------|
| `social_screen` | loading, tabs render, content | `userClubProvider`, `globalActivityProvider` |
| `challenges_screen` | loading, challenge lists, empty, filter tabs | `featuredChallengesProvider`, `allChallengesProvider`, `userChallengesProvider` |
| `challenge_detail_screen` | loading, challenge data, join action, progress | `challengeByIdProvider`, `challengeLeaderboardProvider` |
| `create_solo_challenge_dialog` | form render, validation, submission | `challengeRepositoryProvider` |
| `leaderboard_screen` | loading, entries list, empty | `clubLeaderboardProvider`, `challengeLeaderboardProvider` |
| `friends_screen` | loading, friends list, empty, add friend | `tribeRepositoryProvider` |
| `social_onboarding_screen` | initial, complete action | `socialOnboardingCompletedProvider` |
| `invite_code_dialog` | initial, submit code, error | `tribeRepositoryProvider` |
| `blueprint_detail_screen` | loading, blueprint data, apply action | `blueprintDetailControllerProvider` |
| `accountability_screen` | loading, partners, stats | `tribeRepositoryProvider` |
| `all_tribes_screen` | loading, tribes list, empty, join | `allArchetypeClubsProvider` |
| `tribe_lobby_screen` | loading, tribe data, members, activity | `userClubProvider`, `clubContributorsProvider`, `clubActivityProvider` |

### Tribe Tabs (4 screens, ~16 tests)

| Screen | Key States | Dependencies |
|--------|-----------|--------------|
| `tribe_space_scaffold` | loading, tabs, content areas | `userClubProvider`, `tribeAggregateProvider` |
| `tribe_feed_tab` | loading, posts, empty | `clubActivityProvider` |
| `tribe_board_tab` | loading, board data, empty | `realTimeTribeStatsProvider` |
| `tribe_tab_content` | loading, content, empty | Various tribe providers |

### Creator (3 screens, ~15 tests)

| Screen | Key States | Dependencies |
|--------|-----------|--------------|
| `creator_dashboard_scaffold` | loading, metrics, empty | `userClubProvider`, `tribeAggregateProvider` |
| `creator_overview_tab` | loading, stats, charts | `tribeAggregateProvider`, `globalAggregateStatsProvider` |
| `creator_tribe_management_tab` | loading, members, management actions | `userClubProvider`, `clubContributorsProvider` |

### Profile (1 screen, ~5 tests)

| Screen | Key States | Dependencies |
|--------|-----------|--------------|
| `future_self_studio_screen` | loading, profile data, avatar, edit | `userProfileProvider`, `userAvatarStatsProvider` |

### Settings (2 screens, ~8 tests)

| Screen | Key States | Dependencies |
|--------|-----------|--------------|
| `settings_screen` | render, toggles, sign out | `authRepositoryProvider`, `localSettingsRepositoryProvider` |
| `notification_settings_screen` | render, toggle permissions | `localSettingsRepositoryProvider` |

### Monetization (3 screens, ~15 tests)

| Screen | Key States | Dependencies |
|--------|-----------|--------------|
| `paywall_screen` | loading, plans, purchase, restore | `isPremiumProvider`, RevenueCat |
| `paystack_checkout_screen` | loading, checkout form, success, error | Purchase provider |
| `habit_contract_screen` | loading, contract data, sign action | `habitRepositoryProvider` |

### AI (2 screens, ~8 tests)

| Screen | Key States | Dependencies |
|--------|-----------|--------------|
| `goldilocks_screen` | loading, recommendation, empty, refresh | AI service provider |
| `ai_reflections_screen` | loading, reflections, empty | AI service provider |

## Testing Pattern

### Shared Utility

```dart
// test/helpers/widget_test_utils.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Widget createScreenUnderTest({
  required Widget screen,
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      home: screen,
    ),
  );
}
```

### Standard Test Template

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
// feature imports
import 'package:emerge/features/<feature>/presentation/screens/<screen>.dart';
// provider imports for overrides
import 'package:emerge/features/<feature>/presentation/providers/...dart';

class MockRepository extends Mock implements Repository {}

void main() {
  late MockRepository mockRepo;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(FakeObject());
  });

  setUp(() {
    mockRepo = MockRepository();
  });

  ProviderContainer _makeContainer() {
    return ProviderContainer(
      overrides: [
        repositoryProvider.overrideWithValue(mockRepo),
      ],
    );
  }

  Widget _buildTestWidget() {
    return ProviderScope(
      overrides: _makeContainer().overrides,
      child: MaterialApp(
        home: const ScreenName(),
      ),
    );
  }

  group('$ScreenName - loading', () {
    testWidgets('shows loading indicator when data is loading', (tester) async {
      // Simulate loading by not answering the mock
      await tester.pumpWidget(_buildTestWidget());
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('$ScreenName - data', () {
    testWidgets('renders screen elements with provided data', (tester) async {
      when(() => mockRepo.someMethod()).thenAnswer((_) async => testData);
      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();
      expect(find.text('Expected Element'), findsOneWidget);
    });
  });

  group('$ScreenName - error', () {
    testWidgets('shows error state when provider fails', (tester) async {
      when(() => mockRepo.someMethod()).thenThrow(Exception('fail'));
      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();
      expect(find.textContaining('Error'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget); // retry button
    });
  });

  group('$ScreenName - interactions', () {
    testWidgets('handles key user interaction', (tester) async {
      when(() => mockRepo.someMethod()).thenAnswer((_) async => testData);
      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Action Button'));
      await tester.pumpAndSettle();
      verify(() => mockRepo.actionCalled()).called(1);
    });
  });

  tearDown(() {
    container.dispose();
  });
}
```

### StreamProvider Handling

For screens that depend on `StreamProvider`, use the `container.listen()` + `sub.close()` pattern established in Tier 3 to keep the stream alive through the test lifecycle:

```dart
// In setUp or test:
final sub = container.listen(streamProvider, (_, __) {});
addTearDown(sub.close);
```

### Riverpod 3 Disposal Semantics

For screens using `FutureProvider.family` or `AsyncNotifierProvider`, use the same `ProviderLatch` pattern from Tier 3 to handle Riverpod 3's autoDispose behavior in widget tests:

```dart
// Pump then wait for async resolution
await tester.pumpWidget(_buildTestWidget());
await tester.pump(); // Let Riverpod 3 schedule microtasks
await tester.pump(const Duration(milliseconds: 100));
```

## Shared Infrastructure

### Test Helpers (`test/helpers/`)

| File | Purpose |
|------|---------|
| `widget_test_utils.dart` | `createScreenUnderTest()` + pump helpers |
| `mocks/auth_mocks.dart` | `MockAuthRepository`, `FakeAuthUser` (extracted from Tier 3) |
| `mocks/habit_mocks.dart` | `MockHabitRepository`, `MockMomentumService` |
| `mocks/social_mocks.dart` | `MockChallengeRepository`, `MockTribeRepository`, `MockLeaderboardRepository` |
| `mocks/gamification_mocks.dart` | `MockUserStatsRepository`, `MockWorldHealthService` |
| `mocks/onboarding_mocks.dart` | `MockOnboardingStateController` |

## Execution Phases

### Phase A: Shared infrastructure + Onboarding + Auth (7 screens, ~28 tests)
1. Create `test/helpers/` with shared utilities
2. Extract common mocks from Tier 3 into shared test helpers
3. Implement onboarding screens (welcome, identity_studio, first_habit, world_reveal)
4. Implement auth screens (login, signup, creator_login)
5. Run tests, commit

### Phase B: Habits + Dashboard + Timeline + World Map (9 screens, ~45 tests)
1. Implement habit screens (habit_detail, advanced_create_habit_dialog, streak_recovery)
2. Implement gamification screens (weekly_recap, recap_hub, leveling)
3. Implement timeline screen
4. Implement world map screens
5. Run tests, commit

### Phase C: Social + Tribe tabs (16 screens, ~71 tests)
1. Implement social screens (social, challenges, challenge_detail, create_solo_challenge_dialog, leaderboard, friends, social_onboarding, invite_code_dialog, blueprint_detail, accountability, all_tribes, tribe_lobby)
2. Implement tribe tab screens (tribe_space_scaffold, tribe_feed_tab, tribe_board_tab, tribe_tab_content)
3. Run tests, commit

### Phase D: Creator + Profile + Settings (6 screens, ~28 tests)
1. Implement creator screens (creator_dashboard_scaffold, creator_overview_tab, creator_tribe_management_tab)
2. Implement profile screen
3. Implement settings screens
4. Run tests, commit

### Phase E: Monetization + AI (5 screens, ~23 tests)
1. Implement monetization screens (paywall, paystack_checkout, habit_contract)
2. Implement AI screens (goldilocks, ai_reflections)
3. Run tests, commit

## Estimation

| Phase | Screens | Test files | Tests |
|-------|---------|-----------|-------|
| A: Infra + Onboarding + Auth | 7 | 7 | ~28 |
| B: Habits + Dashboard + Timeline + World Map | 9 | 9 | ~45 |
| C: Social + Tribe tabs | 16 | 16 | ~71 |
| D: Creator + Profile + Settings | 6 | 6 | ~28 |
| E: Monetization + AI | 5 | 5 | ~23 |
| **Total** | **43** | **43** | **~195** |

## Verification

- Each test file must pass with `flutter test <path>`
- Full suite must pass with `flutter test` — zero regressions against 803 existing tests
- Static analysis: `dart analyze` on test files must show no issues

## Screens with Existing Coverage (6)

These screens already have test files. Review and enhance if they don't meet the full-state-coverage standard:

| Screen | Existing test file | Enhancement needed? |
|--------|-------------------|-------------------|
| `level_up_reward_screen` | `gamification/presentation/screens/level_up_reward_screen_test.dart` | Review |
| `leveling_screen` | `gamification/presentation/screens/leveling_screen_test.dart` | Review |
| `streak_recovery_screen` | `habits/presentation/screens/streak_recovery_screen_test.dart` | Review |
| `creator_profile_screen` | `social/presentation/screens/creator_profile_screen_test.dart` | Review |
| `creator_blueprints_tab` | `social/presentation/screens/creator/creator_blueprints_tab_test.dart` | Review |
| `blueprint_builder_screen` | `social/presentation/screens/creator/blueprint_builder_screen_test.dart` | Review |
