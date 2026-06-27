# Creator Route Separation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extract all creator route definitions into a dedicated file, clean up dead email-verification code, and route creators through splash after signup.

**Architecture:** Creator routes live in `lib/core/router/creator_routes.dart` as a `List<RouteBase>` exported function, imported and spread into the single `GoRouter` in `router.dart`. Redirect logic stays centralized in `decideRedirect()`.

**Tech Stack:** Flutter, GoRouter, Riverpod

---

### Task 1: Create `lib/core/router/creator_routes.dart`

**Files:**
- Create: `lib/core/router/creator_routes.dart`

- [ ] **Step 1: Write the file**

Create `lib/core/router/creator_routes.dart` with all creator route definitions extracted from `router.dart`:

```dart
import 'package:emerge_app/features/auth/presentation/screens/creator_login_screen.dart';
import 'package:emerge_app/features/auth/presentation/screens/creator_signup_screen.dart';
import 'package:emerge_app/features/onboarding/presentation/screens/creator_onboarding/creator_onboarding_archetype_screen.dart';
import 'package:emerge_app/features/onboarding/presentation/screens/creator_onboarding/creator_onboarding_profile_screen.dart';
import 'package:emerge_app/features/onboarding/presentation/screens/creator_onboarding/creator_onboarding_reveal_screen.dart';
import 'package:emerge_app/features/social/presentation/screens/creator/creator_dashboard_scaffold.dart';
import 'package:emerge_app/features/social/presentation/screens/creator/creator_overview_tab.dart';
import 'package:emerge_app/features/social/presentation/screens/creator/creator_blueprints_tab.dart';
import 'package:emerge_app/features/social/presentation/screens/creator/blueprint_builder_screen.dart';
import 'package:emerge_app/features/social/presentation/screens/creator/creator_tribe_management_tab.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

List<RouteBase> get creatorRoutes => [
      // Creator auth routes
      GoRoute(
        path: '/creator/login',
        builder: (context, state) => const CreatorLoginScreen(),
      ),
      GoRoute(
        path: '/creator/signup',
        builder: (context, state) => const CreatorSignUpScreen(),
      ),
      // Creator onboarding routes
      GoRoute(
        path: '/onboarding/creator/archetype',
        builder: (context, state) => const CreatorOnboardingArchetypeScreen(),
      ),
      GoRoute(
        path: '/onboarding/creator/profile',
        builder: (context, state) => const CreatorOnboardingProfileScreen(),
      ),
      GoRoute(
        path: '/onboarding/creator/reveal',
        builder: (context, state) => const CreatorOnboardingRevealScreen(),
      ),
      // Creator dashboard shell with 3 tabs
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            CreatorDashboardScaffold(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/creator/dashboard',
                builder: (context, state) => const CreatorOverviewTab(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/creator/dashboard/blueprints',
                builder: (context, state) => const CreatorBlueprintsTab(),
                routes: [
                  GoRoute(
                    path: 'blueprint-builder',
                    builder: (context, state) =>
                        const BlueprintBuilderScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/creator/dashboard/tribe',
                builder: (context, state) =>
                    const CreatorTribeManagementTab(),
              ),
            ],
          ),
        ],
      ),
    ];
```

- [ ] **Step 2: Run analyzer to check the new file**

Run: `dart analyze lib/core/router/creator_routes.dart`
Expected: No issues found.

---

### Task 2: Update `router.dart` — import creator routes, remove inline routes and dead code

**Files:**
- Modify: `lib/core/router/router.dart`

- [ ] **Step 1: Replace creator screen imports with `creator_routes.dart` import**

Remove these imports (lines 33-35, 53-59):
```dart
import 'package:emerge_app/features/onboarding/presentation/screens/creator_onboarding/creator_onboarding_archetype_screen.dart';
import 'package:emerge_app/features/onboarding/presentation/screens/creator_onboarding/creator_onboarding_profile_screen.dart';
import 'package:emerge_app/features/onboarding/presentation/screens/creator_onboarding/creator_onboarding_reveal_screen.dart';
// ...
import 'package:emerge_app/features/auth/presentation/screens/creator_login_screen.dart';
import 'package:emerge_app/features/auth/presentation/screens/creator_signup_screen.dart';
import 'package:emerge_app/features/social/presentation/screens/creator/creator_dashboard_scaffold.dart';
import 'package:emerge_app/features/social/presentation/screens/creator/creator_overview_tab.dart';
import 'package:emerge_app/features/social/presentation/screens/creator/creator_blueprints_tab.dart';
import 'package:emerge_app/features/social/presentation/screens/creator/blueprint_builder_screen.dart';
import 'package:emerge_app/features/social/presentation/screens/creator/creator_tribe_management_tab.dart';
```

Add this import:
```dart
import 'package:emerge_app/core/router/creator_routes.dart';
```

- [ ] **Step 2: Remove `/creator/verify-email` from `authPaths` and redirect logic**

In `decideRedirect()`:

Remove `/creator/verify-email` from the `authPaths` set:
```dart
const authPaths = {
  '/welcome',
  '/login',
  '/signup',
  '/creator/login',
  '/creator/signup',
  // '/creator/verify-email',  ← DELETE
};
```

Remove the dead `'if (currentPath == '/creator/verify-email') return null;'` branch in the creator section (around line 166):
```dart
if (onboarding == null || !onboarding.isComplete) {
  // DELETE these 2 lines:
  // if (currentPath == '/creator/verify-email') return null;
  // Allow creator-onboarding screens through.
  if (isOnCreatorOnboardingPath) return null;
  // ...
```

- [ ] **Step 3: Remove `emailVerified` from `RedirectContext`**

Remove the `emailVerified` field from the `RedirectContext` class:
```dart
class RedirectContext {
  final bool isLoggedIn;
  final UserRole? role;
  // final bool emailVerified;  ← DELETE
  final bool isFirstLaunch;
  // ...
```

- [ ] **Step 4: Remove `emailVerified` from the redirect callback in `router()`**

In the `redirect` callback (lines 284-285):
```dart
// DELETE these 2 lines:
// final firebaseUser = ref.read(firebaseAuthProvider).currentUser;
// final emailVerified = firebaseUser?.emailVerified ?? false;
```

And remove `emailVerified: emailVerified,` from the `RedirectContext` construction.

- [ ] **Step 5: Remove inline creator route definitions and add spread**

Remove these route blocks from the `routes:` list:
1. Creator onboarding GoRoutes (lines 331-342)
2. Creator auth GoRoutes (lines 348-355)
3. Creator dashboard `StatefulShellRoute.indexedStack` (lines 356-391)

Add `...creatorRoutes,` after the public routes block (after `/world-splash` route, before `/welcome`):

```dart
GoRoute(
  path: '/world-splash',
  builder: (context, state) => const WorldSplashScreen(),
),
// Creator routes (login, signup, onboarding, dashboard)
...creatorRoutes,
GoRoute(
  path: '/welcome',
  builder: (context, state) => const WelcomeScreen(),
),
```

- [ ] **Step 6: Run analyzer to verify**

Run: `dart analyze lib/core/router/router.dart`
Expected: No issues found.

---

### Task 3: Update `creator_signup_screen.dart` — route to splash, remove dead method

**Files:**
- Modify: `lib/features/auth/presentation/screens/creator_signup_screen.dart`

- [ ] **Step 1: Change post-signup navigation to `/splash`**

In `_signUp()` (line 58):
```dart
// Change from:
context.go('/onboarding/creator/archetype');
// To:
context.go('/splash');
```

In `_signUpWithGoogle()` (line 79):
```dart
// Change from:
context.go('/onboarding/creator/archetype');
// To:
context.go('/splash');
```

- [ ] **Step 2: Remove dead `_sendVerificationIfAvailable()` method**

Remove the entire method (lines 94-101):
```dart
// DELETE this entire method:
// Future<void> _sendVerificationIfAvailable() async {
//   // Email verification requirement has been removed from the creator flow.
//   try {
//     final user = ref.read(firebaseAuthProvider).currentUser;
//     if (user == null) return;
//     if (user.emailVerified) return;
//   } catch (_) {}
// }
```

Also remove the import for `firebaseAuthProvider` if it's no longer used:
```dart
// Check if this import is still needed (it may be used elsewhere in the file):
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
```
If it's only used in the removed method, remove it.

- [ ] **Step 3: Run analyzer to verify**

Run: `dart analyze lib/features/auth/presentation/screens/creator_signup_screen.dart`
Expected: No issues found.

---

### Task 4: Update redirect tests — remove `emailVerified` field

**Files:**
- Modify: `test/core/router/router_redirect_test.dart`

- [ ] **Step 1: Remove `emailVerified: ` from every `RedirectContext` constructor**

Every test constructor passes `emailVerified: false` or `emailVerified: true`. Remove this parameter from all ~20 `RedirectContext` constructors in the file.

Example change:
```dart
// Before:
final ctx = const RedirectContext(
  isLoggedIn: false,
  role: null,
  emailVerified: false,
  isFirstLaunch: true,
  userOnboardingProgress: null,
  userOnboardingCompletedAt: null,
  creatorOnboarding: null,
);

// After:
final ctx = const RedirectContext(
  isLoggedIn: false,
  role: null,
  isFirstLaunch: true,
  userOnboardingProgress: null,
  userOnboardingCompletedAt: null,
  creatorOnboarding: null,
);
```

- [ ] **Step 2: Run tests to verify**

Run: `flutter test test/core/router/router_redirect_test.dart`
Expected: All tests pass (same as before, since `emailVerified` was never used in any condition).

---

### Task 5: Full project validation

- [ ] **Step 1: Run full Dart analyzer**

Run: `dart analyze`
Expected: No errors (warnings from pre-existing code are acceptable).

- [ ] **Step 2: Run all redirect tests**

Run: `flutter test test/core/router/router_redirect_test.dart`
Expected: All 20+ tests pass.
