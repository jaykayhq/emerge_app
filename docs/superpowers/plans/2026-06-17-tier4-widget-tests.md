# Tier 4: Widget/Screen Tests Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Write widget tests for all 43 screens across the Emerge app with full state coverage (loading, empty, data, error, interactions).

**Architecture:** 43 test files organized by feature area, built on Tier 3's `ProviderContainer` + `ProviderScope` override pattern with mocktail. Shared test utilities in `test/helpers/` reduce boilerplate.

**Tech Stack:** Flutter, flutter_test, Riverpod, mocktail

---

### Phase 0: Shared Infrastructure

**Files:**
- Create: `test/helpers/widget_test_utils.dart`
- Create: `test/helpers/mocks/auth_mocks.dart`
- Create: `test/helpers/mocks/habit_mocks.dart`
- Create: `test/helpers/mocks/social_mocks.dart`
- Create: `test/helpers/mocks/gamification_mocks.dart`
- Create: `test/helpers/mocks/onboarding_mocks.dart`

#### Task 0.1: `widget_test_utils.dart`

**File:** `test/helpers/widget_test_utils.dart`

- [ ] **Step 1: Write the shared widget test utility**

```dart
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

extension PumpForRiverpod on WidgetTester {
  Future<void> pumpForRiverpod() async {
    await pump();
    await pump(const Duration(milliseconds: 50));
  }
}
```

- [ ] **Step 2: Verify the utility is importable**

Run: `dart analyze test/helpers/widget_test_utils.dart`
Expected: No issues found

- [ ] **Step 3: Commit**

```bash
git add test/helpers/widget_test_utils.dart
git commit -m "test: add shared widget test utility"
```

#### Task 0.2: Auth mock helpers

**File:** `test/helpers/mocks/auth_mocks.dart`

- [ ] **Step 1: Write auth mock classes**

```dart
import 'package:mocktail/mocktail.dart';
import 'package:emerge_app/features/auth/domain/entities/auth_user.dart';
import 'package:emerge_app/features/auth/domain/repositories/auth_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class FakeAuthUser extends Fake implements AuthUser {}

final testAuthUser = AuthUser(
  id: 'test-uid',
  email: 'test@example.com',
  displayName: 'Test User',
);
```

- [ ] **Step 2: Verify**

Run: `dart analyze test/helpers/mocks/auth_mocks.dart`
Expected: No issues found

- [ ] **Step 3: Commit**

```bash
git add test/helpers/mocks/auth_mocks.dart
git commit -m "test: add auth mock helpers"
```

#### Task 0.3: Habit mock helpers

**File:** `test/helpers/mocks/habit_mocks.dart`

- [ ] **Step 1: Write habit mock classes**

```dart
import 'package:mocktail/mocktail.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/domain/repositories/habit_repository.dart';

class MockHabitRepository extends Mock implements HabitRepository {}

final testHabits = [
  Habit(id: 'h1', title: 'Morning Run', frequency: HabitFrequency.daily, category: HabitCategory.fitness),
  Habit(id: 'h2', title: 'Read 30m', frequency: HabitFrequency.daily, category: HabitCategory.mindfulness),
];
```

- [ ] **Step 2: Verify + commit**

Run: `dart analyze test/helpers/mocks/habit_mocks.dart`

```bash
git add test/helpers/mocks/habit_mocks.dart
git commit -m "test: add habit mock helpers"
```

#### Task 0.4: Social mock helpers

**File:** `test/helpers/mocks/social_mocks.dart`

- [ ] **Step 1: Write social mock classes**

```dart
import 'package:mocktail/mocktail.dart';
import 'package:emerge_app/features/social/domain/entities/challenge.dart';
import 'package:emerge_app/features/social/domain/repositories/challenge_repository.dart';
import 'package:emerge_app/features/social/domain/repositories/tribe_repository.dart';
import 'package:emerge_app/features/social/domain/repositories/leaderboard_repository.dart';
// ... other social entities

class MockChallengeRepository extends Mock implements ChallengeRepository {}
class MockTribeRepository extends Mock implements TribeRepository {}
class MockLeaderboardRepository extends Mock implements LeaderboardRepository {}
```

- [ ] **Step 2: Verify + commit**

#### Task 0.5: Gamification mock helpers

**File:** `test/helpers/mocks/gamification_mocks.dart`

- [ ] **Step 1: Write gamification mock classes**

```dart
import 'package:mocktail/mocktail.dart';
import 'package:emerge_app/features/gamification/domain/entities/user_profile.dart';
import 'package:emerge_app/features/gamification/domain/services/world_health_service.dart';
// ... other imports

class MockWorldHealthService extends Mock implements WorldHealthService {}
```

- [ ] **Step 2: Verify + commit**

#### Task 0.6: Onboarding mock helpers

**File:** `test/helpers/mocks/onboarding_mocks.dart`

- [ ] **Step 1: Write onboarding mock classes**

```dart
import 'package:mocktail/mocktail.dart';

class MockOnboardingStateController extends Mock implements OnboardingStateController {}
```

- [ ] **Step 2: Verify + commit**


### Phase A: Onboarding + Auth (7 screens)

#### Task A1: welcome_screen_test.dart

**Files:**
- Create: `test/features/onboarding/presentation/screens/welcome_screen_test.dart`

- [ ] **Step 1: Write tests**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:emerge_app/features/onboarding/presentation/screens/welcome_screen.dart';

void main() {
  group('WelcomeScreen - initial state', () {
    testWidgets('renders without crash', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: WelcomeScreen()),
      );
      expect(find.byType(WelcomeScreen), findsOneWidget);
    });
  });

  group('WelcomeScreen - content', () {
    testWidgets('displays welcome title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: WelcomeScreen()),
      );
      expect(find.textContaining('Welcome'), findsWidgets);
    });
  });

  group('WelcomeScreen - navigation', () {
    testWidgets('get started button navigates to identity studio', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: WelcomeScreen()),
      );
      await tester.tap(find.byType(ElevatedButton).first);
      await tester.pumpAndSettle();
      // verify navigation — look for target screen or route change
    });
  });
}
```

- [ ] **Step 2: Run tests**

Run: `flutter test test/features/onboarding/presentation/screens/welcome_screen_test.dart`
Expected: All tests pass

- [ ] **Step 3: Commit**

```bash
git add test/features/onboarding/presentation/screens/welcome_screen_test.dart
git commit -m "test: add WelcomeScreen widget tests"
```

#### Task A2: identity_studio_screen_test.dart

**Files:**
- Create: `test/features/onboarding/presentation/screens/identity_studio_screen_test.dart`

- [ ] **Step 1: Write tests**

Mock setup: Override `onboardingStateControllerProvider` + `selectedArchetypeProvider`.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:emerge_app/features/onboarding/presentation/screens/identity_studio_screen.dart';
import 'package:emerge_app/features/onboarding/presentation/providers/onboarding_providers.dart';
import 'package:emerge_app/helpers/widget_test_utils.dart';

class MockOnboardingCtrl extends Mock implements OnboardingStateController {}

void main() {
  late MockOnboardingCtrl mockCtrl;

  setUp(() {
    mockCtrl = MockOnboardingCtrl();
  });

  Widget _buildTest() {
    return createScreenUnderTest(
      screen: const IdentityStudioScreen(),
      overrides: [
        onboardingStateControllerProvider.overrideWith(mockCtrl),
      ],
    );
  }

  group('IdentityStudioScreen - loading', () {
    testWidgets('shows archetype grid', (tester) async {
      await tester.pumpWidget(_buildTest());
      expect(find.byType(GridView), findsOneWidget);
    });
  });

  group('IdentityStudioScreen - interaction', () {
    testWidgets('selecting archetype updates state', (tester) async {
      await tester.pumpWidget(_buildTest());
      await tester.tap(find.text('Athlete'));
      await tester.pump();
      verify(() => mockCtrl.selectArchetype(UserArchetype.athlete)).called(1);
    });
  });
}
```

- [ ] **Step 2: Run tests**

Run: `flutter test test/features/onboarding/presentation/screens/identity_studio_screen_test.dart`
Expected: All tests pass

- [ ] **Step 3: Commit**

```bash
git add test/features/onboarding/presentation/screens/identity_studio_screen_test.dart
git commit -m "test: add IdentityStudioScreen widget tests"
```

#### Task A3: first_habit_screen_test.dart

**Files:**
- Create: `test/features/onboarding/presentation/screens/first_habit_screen_test.dart`

- [ ] **Step 1: Write tests**

Mock setup: Override `onboardingStateControllerProvider` + `habitRepositoryProvider`. Cover: empty template list, template selection, skip action, form submission.

```
Tests:
- renders habit template grid when data loaded
- shows empty state when no templates returned
- tapping template calls selectTemplate on controller
- skip button navigates to next screen
```

- [ ] **Step 2: Run tests + commit**

#### Task A4: world_reveal_screen_test.dart

**Files:**
- Create: `test/features/onboarding/presentation/screens/world_reveal_screen_test.dart`

- [ ] **Step 1: Write tests**

Mock setup: Override `onboardingStateControllerProvider`. Cover: reveal animation, continue button.

```
Tests:
- renders world reveal screen without crash
- shows continue button after reveal animation
- tapping continue navigates forward
```

- [ ] **Step 2: Run tests + commit**

#### Task A5: login_screen_test.dart

**Files:**
- Create: `test/features/auth/presentation/screens/login_screen_test.dart`

- [ ] **Step 1: Write tests**

Mock setup: Override `authRepositoryProvider`.

```
Tests:
- renders login form without crash
- shows validation error on empty email
- shows loading indicator during submission
- shows error snackbar on auth failure
- successful login navigates to dashboard
```

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:emerge_app/features/auth/presentation/screens/login_screen.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/helpers/widget_test_utils.dart';
import 'package:emerge_app/helpers/mocks/auth_mocks.dart';

void main() {
  late MockAuthRepository mockAuth;

  setUp(() {
    mockAuth = MockAuthRepository();
  });

  Widget _buildTest() {
    return createScreenUnderTest(
      screen: const LoginScreen(),
      overrides: [
        authRepositoryProvider.overrideWithValue(mockAuth),
      ],
    );
  }

  group('LoginScreen - initial state', () {
    testWidgets('renders login form with email and password fields', (tester) async {
      await tester.pumpWidget(_buildTest());
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Sign In'), findsOneWidget);
    });
  });

  group('LoginScreen - validation', () {
    testWidgets('shows validation error when fields are empty', (tester) async {
      await tester.pumpWidget(_buildTest());
      await tester.tap(find.text('Sign In'));
      await tester.pump();
      expect(find.textContaining('required'), findsWidgets);
    });
  });

  group('LoginScreen - loading', () {
    testWidgets('shows loading indicator during submission', (tester) async {
      when(() => mockAuth.signInWithEmailAndPassword(any(), any()))
          .thenAnswer((_) => Future.delayed(const Duration(seconds: 1), () => testAuthUser));
      await tester.pumpWidget(_buildTest());
      await tester.enterText(find.byType(TextFormField).at(0), 'test@example.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      await tester.tap(find.text('Sign In'));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('LoginScreen - error state', () {
    testWidgets('shows error on auth failure', (tester) async {
      when(() => mockAuth.signInWithEmailAndPassword(any(), any()))
          .thenThrow(Exception('Invalid credentials'));
      await tester.pumpWidget(_buildTest());
      await tester.enterText(find.byType(TextFormField).at(0), 'test@example.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'wrong');
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Error'), findsWidgets);
    });
  });
}
```

- [ ] **Step 2: Run tests + commit**

#### Task A6: signup_screen_test.dart

**Files:**
- Create: `test/features/auth/presentation/screens/signup_screen_test.dart`

- [ ] **Step 1: Write tests**

Same pattern as login_screen_test.dart but for registration form. Override `authRepositoryProvider`.

```
Tests:
- renders signup form with name, email, password, confirm password
- shows validation error on password mismatch
- shows loading during submission
- shows error on registration failure
```

- [ ] **Step 2: Run tests + commit**

#### Task A7: creator_login_screen_test.dart

**Files:**
- Create: `test/features/auth/presentation/screens/creator_login_screen_test.dart`

- [ ] **Step 1: Write tests**

```
Tests:
- renders creator login screen
- login form works
- error state handling
```

- [ ] **Step 2: Run tests + commit**

Run full suite: `flutter test` — verify no regressions.


### Phase B: Habits + Dashboard/Gamification + Timeline + World Map (9 screens)

#### Task B1: habit_detail_screen_test.dart

**Files:**
- Create: `test/features/habits/presentation/screens/habit_detail_screen_test.dart`

- [ ] **Step 1: Write tests**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:emerge_app/features/habits/presentation/screens/habit_detail_screen.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_core_providers.dart';
import 'package:emerge_app/helpers/widget_test_utils.dart';
import 'package:emerge_app/helpers/mocks/habit_mocks.dart';

void main() {
  late MockHabitRepository mockRepo;

  setUp(() {
    mockRepo = MockHabitRepository();
  });

  Widget _buildTest({List<Habit> habits = const []}) {
    return createScreenUnderTest(
      screen: const HabitDetailScreen(habitId: 'h1'),
      overrides: [
        habitRepositoryProvider.overrideWithValue(mockRepo),
        habitsProvider.overrideWithValue(AsyncValue.data(habits)),
      ],
    );
  }

  group('HabitDetailScreen - loading', () {
    testWidgets('shows loading indicator initially', (tester) async {
      await tester.pumpWidget(_buildTest());
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('HabitDetailScreen - data', () {
    testWidgets('renders habit details when loaded', (tester) async {
      await tester.pumpWidget(_buildTest(habits: testHabits));
      await tester.pumpAndSettle();
      expect(find.text('Morning Run'), findsOneWidget);
      expect(find.text('Read 30m'), findsOneWidget);
    });
  });

  group('HabitDetailScreen - interaction', () {
    testWidgets('completion toggle calls repo', (tester) async {
      when(() => mockRepo.completeHabit(any())).thenAnswer((_) async => HabitCompletionResult.success());
      await tester.pumpWidget(_buildTest(habits: testHabits));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();
      verify(() => mockRepo.completeHabit(any())).called(1);
    });
  });
}
```

- [ ] **Step 2: Run tests + commit**

#### Task B2: advanced_create_habit_dialog_test.dart

**Files:**
- Create: `test/features/habits/presentation/screens/advanced_create_habit_dialog_test.dart`

- [ ] **Step 1: Write tests**

Mock setup: Override `createHabitProvider`, `isPremiumProvider`.

```
Tests:
- renders dialog with form fields
- shows validation errors for empty required fields
- shows premium gate for advanced features
- calls createHabit on submit
```

- [ ] **Step 2: Run tests + commit**

#### Task B3: streak_recovery_screen_test.dart (review existing)

**Files:**
- Read: `test/features/habits/presentation/screens/streak_recovery_screen_test.dart`

- [ ] **Step 1: Review existing tests for state coverage gaps**

Check if existing tests cover: loading, empty streak data, recovery boost action.

- [ ] **Step 2: Add missing tests if needed + commit**

#### Task B4: weekly_recap_screen_test.dart

**Files:**
- Create: `test/features/gamification/presentation/screens/weekly_recap_screen_test.dart`

- [ ] **Step 1: Write tests**

```
Tests:
- shows loading for empty recap data
- renders recap with completed habits
- shows empty state for week with no activity
- share action triggers
```

- [ ] **Step 2: Run tests + commit**

#### Task B5: recap_hub_screen_test.dart

**Files:**
- Create: `test/features/gamification/presentation/screens/recap_hub_screen_test.dart`

```
Tests:
- shows loading initially
- renders list of recaps
- shows empty state
- tapping recap navigates to detail
```

- [ ] **Step 1: Write tests + Step 2: Run + Step 3: Commit**

#### Task B6: leveling_screen_test.dart (review existing)

**Files:**
- Read: `test/features/gamification/presentation/screens/leveling_screen_test.dart`

- [ ] **Step 1: Review + enhance if needed**

#### Task B7: timeline_screen_test.dart

**Files:**
- Create: `test/features/timeline/presentation/screens/timeline_screen_test.dart`

- [ ] **Step 1: Write tests**

```
Tests:
- shows loading initially
- renders timeline entries when data loaded
- shows empty state with no entries
- reflection toggle works
```

- [ ] **Step 2: Run tests + commit**

#### Task B8: world_map_screen_test.dart

**Files:**
- Create: `test/features/world_map/presentation/screens/world_map_screen_test.dart`

- [ ] **Step 1: Write tests**

```
Tests:
- shows loading initially
- renders world map with health data
- health value updates via stream
```

- [ ] **Step 2: Run tests + commit**

#### Task B9: level_immersive_screen_test.dart

**Files:**
- Create: `test/features/world_map/presentation/screens/level_immersive_screen_test.dart`

- [ ] **Step 1: Write tests**

```
Tests:
- shows loading initially
- renders immersive level display
- level data renders correctly
```

- [ ] **Step 2: Run tests + commit**

Run full suite: `flutter test` — verify no regressions.


### Phase C: Social + Tribe tabs (16 screens)

#### Task C1: social_screen_test.dart

**Files:**
- Create: `test/features/social/presentation/screens/social_screen_test.dart`

- [ ] **Step 1: Write tests**

```
Tests:
- renders social screen with tabs
- tab switching works
- content renders per tab
```

- [ ] **Step 2: Run tests + commit**

#### Task C2: challenges_screen_test.dart

**Files:**
- Create: `test/features/social/presentation/screens/challenges_screen_test.dart`

- [ ] **Step 1: Write tests**

```
Tests:
- shows loading initially
- renders featured and user challenges
- shows empty state
- filter tabs change content
```

- [ ] **Step 2: Run tests + commit**

#### Task C3: challenge_detail_screen_test.dart

**Files:**
- Create: `test/features/social/presentation/screens/challenge_detail_screen_test.dart`

```
Tests:
- shows loading initially
- renders challenge details
- loading, data, error states
- join button works
```

- [ ] **Step 2: Run tests + commit**

#### Task C4: create_solo_challenge_dialog_test.dart

**Files:**
- Create: `test/features/social/presentation/screens/create_solo_challenge_dialog_test.dart`

```
Tests:
- renders dialog form
- validation errors
- submission
```

- [ ] **Step 2: Run tests + commit**

#### Task C5: leaderboard_screen_test.dart

**Files:**
- Create: `test/features/social/presentation/screens/leaderboard_screen_test.dart`

```
Tests:
- shows loading initially
- renders leaderboard entries
- shows empty state
- switching between club/challenge leaderboards
```

- [ ] **Step 2: Run tests + commit**

#### Task C6: friends_screen_test.dart

**Files:**
- Create: `test/features/social/presentation/screens/friends_screen_test.dart`

```
Tests:
- shows loading initially
- renders friends list
- empty state
- add friend action
```

- [ ] **Step 2: Run tests + commit**

#### Task C7: social_onboarding_screen_test.dart

**Files:**
- Create: `test/features/social/presentation/screens/social_onboarding_screen_test.dart`

```
Tests:
- renders onboarding content
- complete action updates state
```

- [ ] **Step 2: Run tests + commit**

#### Task C8: invite_code_dialog_test.dart

**Files:**
- Create: `test/features/social/presentation/screens/invite_code_dialog_test.dart`

```
Tests:
- renders dialog with code input
- submit code action
- error on invalid code
```

- [ ] **Step 2: Run tests + commit**

#### Task C9: blueprint_detail_screen_test.dart

**Files:**
- Create: `test/features/social/presentation/screens/blueprint_detail_screen_test.dart`

```
Tests:
- shows loading initially
- renders blueprint details
- apply blueprint action
- error handling
```

- [ ] **Step 2: Run tests + commit**

#### Task C10: accountability_screen_test.dart

**Files:**
- Create: `test/features/social/presentation/screens/accountability_screen_test.dart`

```
Tests:
- shows loading initially
- renders accountability partners
- empty state
```

- [ ] **Step 2: Run tests + commit**

#### Task C11: all_tribes_screen_test.dart

**Files:**
- Create: `test/features/social/presentation/screens/all_tribes_screen_test.dart`

```
Tests:
- shows loading initially
- renders tribe list
- empty state
- join tribe action
```

- [ ] **Step 2: Run tests + commit**

#### Task C12: tribe_lobby_screen_test.dart

**Files:**
- Create: `test/features/social/presentation/screens/tribe_lobby_screen_test.dart`

```
Tests:
- shows loading initially
- renders tribe info, members, activity
- loading/error states for each section
```

- [ ] **Step 2: Run tests + commit**

#### Task C13: tribe_space_scaffold_test.dart

**Files:**
- Create: `test/features/social/presentation/screens/tribe_space_scaffold_test.dart`

```
Tests:
- shows loading initially
- renders tabs
- tab content renders
```

- [ ] **Step 2: Run tests + commit**

#### Task C14: tribe_feed_tab_test.dart

**Files:**
- Create: `test/features/social/presentation/screens/tribe_feed_tab_test.dart`

```
Tests:
- shows loading initially
- renders feed posts
- empty state
```

- [ ] **Step 2: Run tests + commit**

#### Task C15: tribe_board_tab_test.dart

**Files:**
- Create: `test/features/social/presentation/screens/tribe_board_tab_test.dart`

```
Tests:
- shows loading initially
- renders board data
- empty state
```

- [ ] **Step 2: Run tests + commit**

#### Task C16: tribe_tab_content_test.dart

**Files:**
- Create: `test/features/social/presentation/screens/tribe_tab_content_test.dart`

```
Tests:
- shows loading initially
- renders content
- empty state
- tab switching
```

- [ ] **Step 2: Run tests + commit**

Run full suite: `flutter test` — verify no regressions.


### Phase D: Creator + Profile + Settings (6 screens)

#### Task D1: creator_dashboard_scaffold_test.dart

**Files:**
- Create: `test/features/social/presentation/screens/creator/creator_dashboard_scaffold_test.dart`

- [ ] **Step 1: Write tests**

```
Tests:
- shows loading initially
- renders creator metrics
- empty metrics state
```

- [ ] **Step 2: Run tests + commit**

#### Task D2: creator_overview_tab_test.dart

**Files:**
- Create: `test/features/social/presentation/screens/creator/creator_overview_tab_test.dart`

```
Tests:
- shows loading initially
- renders stats/charts
- empty state
```

- [ ] **Step 2: Run tests + commit**

#### Task D3: creator_tribe_management_tab_test.dart

**Files:**
- Create: `test/features/social/presentation/screens/creator/creator_tribe_management_tab_test.dart`

```
Tests:
- shows loading initially
- renders member list
- management actions
```

- [ ] **Step 2: Run tests + commit**

#### Task D4: future_self_studio_screen_test.dart

**Files:**
- Create: `test/features/profile/presentation/screens/future_self_studio_screen_test.dart`

```
Tests:
- shows loading initially
- renders profile/avatar data
- edit action
```

- [ ] **Step 2: Run tests + commit**

#### Task D5: settings_screen_test.dart

**Files:**
- Create: `test/features/settings/presentation/screens/settings_screen_test.dart`

```
Tests:
- renders settings options
- toggle works
- sign out action
```

- [ ] **Step 2: Run tests + commit**

#### Task D6: notification_settings_screen_test.dart

**Files:**
- Create: `test/features/settings/presentation/screens/notification_settings_screen_test.dart`

```
Tests:
- renders notification settings
- toggle permissions
```

- [ ] **Step 2: Run tests + commit**

Run full suite: `flutter test` — verify no regressions.


### Phase E: Monetization + AI (5 screens)

#### Task E1: paywall_screen_test.dart

**Files:**
- Create: `test/features/monetization/presentation/screens/paywall_screen_test.dart`

- [ ] **Step 1: Write tests**

Mock RevenueCat/purchase service.

```
Tests:
- shows loading for purchase options
- renders plan list
- purchase action
- restore purchases
```

- [ ] **Step 2: Run tests + commit**

#### Task E2: paystack_checkout_screen_test.dart

**Files:**
- Create: `test/features/monetization/presentation/screens/paystack_checkout_screen_test.dart`

```
Tests:
- shows loading initially
- renders checkout form
- success state
- error state
```

- [ ] **Step 2: Run tests + commit**

#### Task E3: habit_contract_screen_test.dart

**Files:**
- Create: `test/features/monetization/presentation/screens/habit_contract_screen_test.dart`

```
Tests:
- shows loading initially
- renders contract data
- sign action
```

- [ ] **Step 2: Run tests + commit**

#### Task E4: goldilocks_screen_test.dart

**Files:**
- Create: `test/features/ai/presentation/screens/goldilocks_screen_test.dart`

```
Tests:
- shows loading initially
- renders AI recommendation
- empty/no recommendation state
- refresh action
```

- [ ] **Step 2: Run tests + commit**

#### Task E5: ai_reflections_screen_test.dart

**Files:**
- Create: `test/features/ai/presentation/screens/ai_reflections_screen_test.dart`

```
Tests:
- shows loading initially
- renders reflections list
- empty state
```

- [ ] **Step 2: Run tests + commit**

Run full suite: `flutter test` — verify no regressions.


### Final Verification

- [ ] **Step 1: Run full test suite**

Run: `flutter test`
Expected: All tests pass (803 baseline + ~195 new = ~998 total)

- [ ] **Step 2: Run static analysis**

Run: `dart analyze lib/ test/`
Expected: No new issues

- [ ] **Step 3: Print coverage summary**

```bash
flutter test --reporter expanded 2>&1 | Select-String -Pattern "All tests passed|Some tests failed|tests:"
```
