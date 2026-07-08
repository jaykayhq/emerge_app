# Creator Route Separation Design

**Date:** 2026-06-23
**Status:** Approved

## Problem

The main router (`lib/core/router/router.dart`) is 708 lines with creator routes, normal user routes, auth routes, onboarding routes, and deep-link routes all mixed together. This makes it hard to find/modify creator-specific routing. Additionally:
- Dead email-verification code exists for creators (`_sendVerificationIfAvailable`, `/creator/verify-email` path reference)
- Creator signup navigates directly to `/onboarding/creator/archetype` instead of letting the splash screen handle role-aware routing

## Solution

Extract all creator route definitions into a separate file while keeping redirect logic centralized.

### Files Changed

| File | Action |
|------|--------|
| `lib/core/router/creator_routes.dart` | **New** — exports `List<RouteBase> creatorRoutes` |
| `lib/core/router/router.dart` | Import + spread `creatorRoutes`; remove inline creator routes; remove dead `/creator/verify-email` references; remove unused `emailVerified` from `RedirectContext` |
| `lib/features/auth/presentation/screens/creator_signup_screen.dart` | Change post-signup navigation to `/splash`; remove dead `_sendVerificationIfAvailable()` |

### What moves to `creator_routes.dart`

| Route(s) | Screen(s) |
|----------|-----------|
| `/creator/login` | `CreatorLoginScreen` |
| `/creator/signup` | `CreatorSignUpScreen` |
| `/onboarding/creator/archetype` | `CreatorOnboardingArchetypeScreen` |
| `/onboarding/creator/profile` | `CreatorOnboardingProfileScreen` |
| `/onboarding/creator/reveal` | `CreatorOnboardingRevealScreen` |
| `/creator/dashboard` (shell + 3 branches) | `CreatorDashboardScaffold`, `CreatorOverviewTab`, `CreatorBlueprintsTab`, `BlueprintBuilderScreen`, `CreatorTribeManagementTab` |

### What stays in `router.dart`

- Public/auth routes: `/splash`, `/paywall`, `/world-splash`, `/welcome`, `/login`, `/signup`
- Normal user onboarding: `/onboarding/identity-studio`, `/onboarding/first-habit`, `/onboarding/world-reveal`
- User bottom-nav shell (`StatefulShellRoute.indexedStack` with 4 branches)
- Top-level deep-links: `/creators/:id`, `/blueprint/:id`, `/creators`, `/challenges`
- The entire `decideRedirect()` function and `RedirectContext`
- Social routes and fullscreen routes

### Dead Code Removal

1. **`_sendVerificationIfAvailable()`** in `creator_signup_screen.dart` — empty method, comment says "Email verification requirement has been removed"
2. **`/creator/verify-email`** from `authPaths` set in `decideRedirect()` — no GoRoute exists for this path
3. **`currentPath == '/creator/verify-email'`** redirect branch in `decideRedirect()` creator section — dead code
4. **`emailVerified`** field from `RedirectContext` — never used in any redirect condition

### Splash After Signup

Change `context.go('/onboarding/creator/archetype')` to `context.go('/splash')` in both `_signUp()` and `_signUpWithGoogle()` in `creator_signup_screen.dart`. The splash screen (`splash_screen.dart`) already has complete role-aware routing:
- For creators: reads `currentCreatorOnboardingProvider` and routes to the correct onboarding step or `/creator/dashboard`
- For normal users: reads `userStatsStreamProvider` and routes to onboarding or home

### Architecture

```txt
router.dart (single GoRouter)
  ├── Public routes (splash, paywall, welcome, login, signup)
  ├── Normal user onboarding routes
  ├── creatorRoutes ← imported from creator_routes.dart
  ├── Top-level deep-links (/creators/:id, /blueprint/:id, etc.)
  └── User bottom-nav shell (StatefulShellRoute)
```

`decideRedirect()` stays in `router.dart` — it operates on path matching and role state, not route definitions.

### What does NOT change

- Splash screen navigation logic
- `decideRedirect()` redirect logic
- Auth state providers (`authStateChangesProvider`, `currentUserRoleProvider`)
- All normal user routes and screens
- Any test files

### Verification

1. `dart analyze` passes with no errors
2. Existing router redirect tests pass (`test/core/router/router_redirect_test.dart`)
3. App starts, splash screen routes correctly for both users and creators
