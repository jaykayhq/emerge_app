# Emerge App — Onboarding Progress Bar & Endowment Interstitial Refinement

**Date:** 2026-07-29  
**Status:** Draft  
**Amends:** `2026-07-25-ux-psychology-and-habit-features-design.md` Plan 5c, Plan 5d  
**Applies to:** emerge_app (Flutter)

---

## Overview

Two UX psychology issues in the onboarding flow:

1. **Progress bar vs step counter overlap** — `OnboardingProgressBar` and `"STEP X OF Y"` text appear simultaneously in 3 screens, creating visual redundancy. The progress bar itself is static and doesn't leverage known psychological effects (goal-gradient, small-area hypothesis).
2. **Endowment interstitial placed post-commitment** — the endowment effect screen shows *after* sign-up, wasting the psychological trigger. The endowment effect is most powerful *before* the user has committed resources.

Both are refinements to Plan 5 in the parent spec. This document overrides Plan 5c and 5d with psychologically-optimized designs.

---

## Design Principles Applied

| Principle | Application |
|-----------|-------------|
| **Goal-Gradient Effect** | Animated progress bar accelerates motivation as the user nears completion. Each screen transition visibly moves the bar. |
| **Endowed Progress Effect** | 20% head start from endowment interstitial is real (the user has "claimed" their preview). Bar never opens at 0%. |
| **Small-Area Hypothesis** | Before 50%: show completed fraction ("40%"). After 50%: show remaining fraction ("40% to go"). The smaller number is always the motivating frame. |
| **Endowment Effect** | Show users what they already "own" (starter pack, tribe, world) *before* they sign up. Creates ownership feeling pre-commitment. |
| **Zeigarnik Effect** | 80% bar on abandon creates open loop — users return to close it. |

---

## Issue A: Progress Bar vs Step Counter Overlap

### Current State

`OnboardingProgressBar` (percentage + linear bar + milestone label) exists in 6 screens. **3 of those screens also show `"STEP X OF Y"` text** in their `_Header` widgets:

| Screen | Has ProgressBar | Has `STEP X OF Y` |
|--------|----------------|-------------------|
| EndowmentInterstitialScreen | ✅ 20% | No |
| IdentityStudioScreen | ✅ 40% | No |
| InterestsScreen | ✅ 60% | Yes (1/5) |
| ClubScreen | ✅ 60%–80% | Yes (2/5) |
| FirstHabitsScreen | ✅ 80% | Yes (3/5) |
| WorldRevealScreen | ✅ 100% | No |

The progress bar is also static (instant jump, no animation), hardcoded to `cyanAccent`, and always frames progress as "X% done" regardless of whether the user is near the start or the finish.

### Solution

#### 1. Remove `"STEP X OF Y"` from all screens

Delete the `_Header` step counter text in:
- `interests_screen.dart:222`
- `club_screen.dart:346`
- `first_habits_screen.dart:262`

The `OnboardingProgressBar` becomes the single source of truth for progress signaling everywhere.

#### 2. Upgrade OnboardingProgressBar to animated, adaptive widget

Convert from `StatelessWidget` to `StatefulWidget` with `AnimationController`:

**Animation:**
- 300ms `Curves.easeInOut` tween when `targetProgress` changes
- Bar smoothly fills from previous value to new value
- Percentage text also animates (cross-fade or slide)

**Archetype-colored accent:**
- Pre-archetype (20%–40%): `Colors.cyanAccent`
- Post-archetype (60%–100%): Use the selected archetype's signature color
- Color source: `archetypeColorFor(archetype)` from existing archetype service

**Adaptive percentage label (small-area hypothesis):**

| Step | Progress | Display | Framing |
|------|----------|---------|---------|
| Endowment seen | 20% | `"20%"` | Completed (small completed area) |
| Archetype set | 40% | `"40%"` | Completed |
| Interests picked | 60% | `"40% to go"` | Remaining (small remaining area) |
| Club decision | 80% | `"20% to go"` | Remaining |
| World revealed | 100% | `"100%"` | Completion |

The milestone labels from the parent spec remain:

| Progress | Label |
|----------|-------|
| 20% | "You've begun. Now define yourself." |
| 40% | "Your archetype is set. What shapes you?" |
| 60% | "40% to go. Your interests give texture." |
| 80% | "20% to go. Almost forged. Choose your company." |
| 100% | "Ready to emerge." |

Note: 60% and 80% labels gain the "X% to go" prefix that dynamically matches the bar's percentage display.

**Widget signature change:**

```dart
class AnimatedOnboardingProgressBar extends StatefulWidget {
  final double targetProgress;      // 0.0–1.0
  final String label;               // milestone label
  final Color? accentColor;         // null → cyanAccent (pre-archetype)
  final bool showRemaining;         // true → "X% to go", false → "X%"
}
```

`showRemaining` is derived from `targetProgress >= 0.5` automatically, but can be overridden.

### Files Modified

| File | Change |
|------|--------|
| `widgets/onboarding_progress_bar.dart` | Rewrite to animated stateful widget |
| `screens/interests_screen.dart` | Remove `STEP X OF Y` text |
| `screens/club_screen.dart` | Remove `STEP X OF Y` text |
| `screens/first_habits_screen.dart` | Remove `STEP X OF Y` text |
| `screens/identity_studio_screen.dart` | Pass archetype color to bar after selection |
| `screens/world_reveal_screen.dart` | No change (already only uses bar) |

---

## Issue B: Endowment Interstitial Placement

### Current State

`EndowmentInterstitialScreen` appears **after** Firebase Auth sign-up, routed via `decideRedirect` checking `hasSeenEndowment`. The user has already created an account — the endowment effect arrives *after* the commitment decision.

**Current flow:**
```
WelcomeScreen → SignUp → [Auth creates profile] → EndowmentInterstitial → IdentityStudio → ...
```

This wastes the endowment effect. The user has nothing to lose by this point — they've already committed.

### Solution

**Move the endowment screen to *before* sign-up**, using anonymous "Future You" copy.

**New flow:**
```
WelcomeScreen → EndowmentInterstitial (pre-auth, "Future You") → SignUp/Login → IdentityStudio → ...
```

#### Why this works psychologically

1. **Endowment effect pre-commitment:** The user sees what they "own" (starter habit pack, archetype tribe, world map) before paying anything. Signing up becomes *claiming* what's theirs, not *starting* something new.
2. **Loss aversion activates:** Once shown, not signing up means *losing* the reserved items. This is stronger than the pull of gaining them.
3. **Answers "why sign up?":** The endowment screen IS the value proposition. The user doesn't need to imagine what they'll get — it's shown concretely.
4. **Endowed progress head start:** The 20% progress bar checkpoint is now earned honestly (the user "claimed" their preview), triggering goal-gradient from the first onboarding step.

#### Screen Changes

| Aspect | Current (post-auth) | New (pre-auth) |
|--------|-------------------|----------------|
| Auth state | Authenticated | Unauthenticated |
| Greeting | `"Welcome, [Name]"` | `"Welcome, Future You"` |
| CTA | `"BEGIN FORGING →"` | `"CLAIM YOUR WORLD →"` |
| CTA action | `markEndowmentSeen()` → `/onboarding/identity-studio` | `markEndowmentSeen()` → `/signup` |
| Secondary | None | `"Already a member? Sign in"` → `/login` |
| `hasSeenEndowment` | Set after CTA | Set after CTA (same flag) |

#### WelcomeScreen Changes

```dart
// Current:
// "Begin Your Journey" → /signup

// New:
if (!hasSeenEndowment) {
  // → /onboarding/endowment
} else {
  // → /signup (returning user who already saw endowment)
}
```

#### Router Changes

The `/onboarding/endowment` route moves from the auth-guarded shell to the top-level (unauthenticated) routes alongside `/welcome`.

**Before (current `decideRedirect`, post-auth):**
```dart
if (onboardingProgress == 0) {
  return ctx.hasSeenEndowment
      ? '/onboarding/identity-studio' 
      : '/onboarding/endowment';
}
```

**After (simplified):**
```dart
if (onboardingProgress == 0) return '/onboarding/identity-studio';
```

The endowment is no longer part of the post-auth redirect chain at all.

#### LocalSettingsRepository

`hasSeenEndowment` flag stays, same key (`endowment_interstitial_seen`). Set when user taps "CLAIM YOUR WORLD" (whether they complete sign-up or not). Prevents showing endowment again on return visit.

### Files Modified

| File | Change |
|------|--------|
| `screens/endowment_interstitial_screen.dart` | Rewrite for pre-auth: anonymous greeting, new CTA, sign-in link |
| `screens/welcome_screen.dart` | Route to pre-auth endowment instead of direct sign-up |
| `core/router/router.dart` | Add pre-auth endowment route; simplify `decideRedirect` |
| `presentation/providers/onboarding_state_notifier.dart` | Remove endowment from post-auth flow (no longer calls it) |

---

## Full New Flow

```
WelcomeScreen (unauthenticated)
  │
  ├─ hasSeenEndowment=false → EndowmentInterstitialScreen
  │     │  progress bar: 20%
  │     │  "Welcome, Future You" with 3 endowment items
  │     │  "CLAIM YOUR WORLD" → markEndowmentSeen() → /signup
  │     │  "Sign in" → /login
  │     ▼
  ├─ hasSeenEndowment=true → /signup (returning user)
  │
  └─ Has account? → /login

[User authenticates → onboardingProgress=0]
  │
  ▼
IdentityStudioScreen (archetype carousel)
  │  progress bar: 40% (cyanAccent)
  │  archetype selected → advances
  ▼
InterestsScreen (interest grid)
  │  progress bar: 60% (archetype color)
  │  interests picked → advances
  ▼
ClubScreen (club grid)
  │  progress bar: 60%→80% (joined) / 60% (skipped→catches up next)
  │  club joined or skipped → advances
  ▼
FirstHabitsScreen (starter pack)
  │  progress bar: 80%
  │  habits accepted → advances
  ▼
WorldRevealScreen (animated reveal)
  │  progress bar: 100%
  │  "ENTER YOUR WORLD" → /timeline
```

---

## Verification

Each change must pass:
- `dart analyze` — no new warnings
- `flutter test` — existing tests pass
- Visual inspection at 320dp, 375dp, 414dp widths
- `decideRedirect` unit tests updated for simplified redirect

### Specific Test Cases

1. **Endowment not shown twice:** User sees endowment → taps "CLAIM YOUR WORLD" → goes to sign-up → returns to welcome screen later → routes directly to sign-up (no second endowment)
2. **Unauthenticated access:** Endowment screen loads without auth (no provider calls that require `user.id`)
3. **Progress bar animation:** Bar animates smoothly from 0.2→0.4→0.6→0.8→1.0 across screen transitions
4. **Label framing:** Pre-50% shows "X%", post-50% shows "Y% to go"
5. **Archetype color swap:** At IdentityStudio, before selection bar is cyanAccent; after selection, subsequent screens show archetype color
6. **Router redirect:** New user with `onboardingProgress=0` redirects to `/onboarding/identity-studio` (not endowment)
