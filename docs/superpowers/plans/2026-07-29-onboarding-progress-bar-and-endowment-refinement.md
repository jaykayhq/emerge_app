# Onboarding Progress Bar & Endowment Refinement — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix two UX psychology issues in onboarding: (1) animated progress bar with archetype-colored accent and small-area hypothesis framing replacing the overlapping step counter, (2) move endowment interstitial before sign-up with anonymous "Future You" preview.

**Architecture:** Single-file widget rewrite for `OnboardingProgressBar` (to animated stateful widget), copy/screen changes for endowment interstitial, and router redirect simplification. No new files needed.

**Tech Stack:** Flutter/Dart, Riverpod, go_router

---

## Global Constraints

- `onboarding_progress_bar.dart`: Convert `StatelessWidget` to `StatefulWidget` with `SingleTickerProviderStateMixin`
- `ArchetypeColors.all` from `archetype_theme.dart` is the color source for archetype accent
- `UserArchetype` enum values: `athlete`, `creator`, `scholar`, `stoic`, `zealot`, `none`
- Pre-auth endowment uses "Future You" placeholder (no `userName` parameter)
- `hasSeenEndowment` flag in `LocalSettingsRepository` stays, set before sign-up on CTA tap
- All "STEP X OF Y" text removed from interests, club, first_habits screens
- Percentage display switches from "X%" to "Y% to go" at 50% progress
- 300ms `Curves.easeInOut` animation for bar fill transitions

---

## File Structure

### New behavior (modified files only — no new files):

| File | What changes |
|------|-------------|
| `lib/features/onboarding/presentation/widgets/onboarding_progress_bar.dart` | Replace with `AnimatedOnboardingProgressBar` — animated, archetype-colored, adaptive label |
| `lib/features/onboarding/presentation/screens/interests_screen.dart` | Remove `_Header` step counter text; pass `archetypeColor` to progress bar |
| `lib/features/onboarding/presentation/screens/club_screen.dart` | Remove `_Header` step counter text; pass `archetypeColor` to progress bar |
| `lib/features/onboarding/presentation/screens/first_habits_screen.dart` | Remove `_Header` step counter text; pass `archetypeColor` to progress bar |
| `lib/features/onboarding/presentation/screens/identity_studio_screen.dart` | Pass archetype color to progress bar after selection |
| `lib/features/onboarding/presentation/screens/world_reveal_screen.dart` | Use animated bar (currently already using bar, minor API change) |
| `lib/features/onboarding/presentation/screens/endowment_interstitial_screen.dart` | Pre-auth version: no `userName`, "Future You" greeting, "CLAIM YOUR WORLD" CTA, "Sign in" link |
| `lib/features/onboarding/presentation/screens/welcome_screen.dart` | Route to endowmnet (pre-auth) instead of direct sign-up |
| `lib/core/router/router.dart` | Add pre-auth endowment route; simplify `decideRedirect` |

### Test files:

| File | What changes |
|------|-------------|
| `test/features/onboarding/presentation/widgets/onboarding_progress_bar_test.dart` | Update for animated bar: test animation, archetype color, adaptive label |
| `test/features/onboarding/presentation/screens/endowment_interstitial_screen_test.dart` | Update for pre-auth: "Future You" greeting, new CTA |
| `test/core/router/router_endowment_redirect_test.dart` | Remove endowment-gating tests (simplified redirect) |
| `test/core/router/router_redirect_test.dart` | Verify it still passes (endowment logic removed, existing branches unchanged) |

---

### Task 1: Animated + Archetype-Colored + Adaptive Progress Bar

**Files:**
- Modify: `lib/features/onboarding/presentation/widgets/onboarding_progress_bar.dart`
- Modify: `test/features/onboarding/presentation/widgets/onboarding_progress_bar_test.dart`

**Interfaces:**
- Consumes: `double progress`, `String label`, `Color? accentColor`, `bool showRemaining`
- Produces: `AnimatedOnboardingProgressBar` widget (replaces `OnboardingProgressBar`)
- Tests: widget renders with correct percentage, archetype color, adaptive "to go" label, animation

- [ ] **Step 1: Update the test to match the new API**

```dart
// test/features/onboarding/presentation/widgets/onboarding_progress_bar_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/onboarding/presentation/widgets/onboarding_progress_bar.dart';

void main() {
  testWidgets('shows correct progress percentage and label', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: AnimatedOnboardingProgressBar(
        targetProgress: 0.4,
        label: 'Your archetype is set. What shapes you?',
      ),
    ));
    expect(find.text('40%'), findsOneWidget);
    expect(find.text('Your archetype is set. What shapes you?'), findsOneWidget);
  });

  testWidgets('shows remaining percentage after 50%', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: AnimatedOnboardingProgressBar(
        targetProgress: 0.8,
        label: '20% to go. Almost forged. Choose your company.',
      ),
    ));
    expect(find.text('20% to go'), findsOneWidget);
  });

  testWidgets('applies archetype accent color', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: AnimatedOnboardingProgressBar(
        targetProgress: 0.6,
        label: '40% to go. Your interests give texture.',
        accentColor: const Color(0xFF7C3AED), // scholar primary
      ),
    ));
    // Verify the bar renders without error; color applied via LinearProgressIndicator.valueColor
    expect(find.byType(AnimatedOnboardingProgressBar), findsOneWidget);
  });

  testWidgets('percentage label switches at 50% threshold', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: AnimatedOnboardingProgressBar(
        targetProgress: 0.6,
        label: '40% to go. Your interests give texture.',
      ),
    ));
    // Below 50% shows "X%", at/above 50% shows "Y% to go"
    expect(find.text('40%'), findsNothing);
    expect(find.text('40% to go'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/onboarding/presentation/widgets/onboarding_progress_bar_test.dart`
Expected: FAIL — `AnimatedOnboardingProgressBar` not defined

- [ ] **Step 3: Rewrite the widget**

```dart
// lib/features/onboarding/presentation/widgets/onboarding_progress_bar.dart
import 'package:flutter/material.dart';

class AnimatedOnboardingProgressBar extends StatefulWidget {
  final double targetProgress;
  final String label;
  final Color? accentColor;

  const AnimatedOnboardingProgressBar({
    super.key,
    required this.targetProgress,
    required this.label,
    this.accentColor,
  });

  @override
  State<AnimatedOnboardingProgressBar> createState() =>
      _AnimatedOnboardingProgressBarState();
}

class _AnimatedOnboardingProgressBarState
    extends State<AnimatedOnboardingProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.value = widget.targetProgress;
  }

  @override
  void didUpdateWidget(AnimatedOnboardingProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetProgress != widget.targetProgress) {
      _controller.animateTo(widget.targetProgress);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showRemaining = widget.targetProgress >= 0.5;
    final percentageText = showRemaining
        ? '${((1 - widget.targetProgress) * 100).toInt()}% to go'
        : '${(widget.targetProgress * 100).toInt()}%';
    final barColor = widget.accentColor ?? Colors.cyanAccent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                percentageText,
                style: TextStyle(
                  color: barColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) => LinearProgressIndicator(
                value: _animation.value,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
                minHeight: 4,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

final onboardingProgressLabels = {
  0.2: "You've begun. Now define yourself.",
  0.4: "Your archetype is set. What shapes you?",
  0.6: "40% to go. Your interests give texture.",
  0.8: "20% to go. Almost forged. Choose your company.",
  1.0: "Ready to emerge.",
};

String onboardingLabelFor(double progress) {
  final keys = onboardingProgressLabels.keys.toList()..sort();
  double best = keys.first;
  for (final k in keys) {
    if (progress >= k) best = k;
  }
  return onboardingProgressLabels[best]!;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/onboarding/presentation/widgets/onboarding_progress_bar_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/onboarding/presentation/widgets/onboarding_progress_bar.dart test/features/onboarding/presentation/widgets/onboarding_progress_bar_test.dart
git commit -m "feat(onboarding): animated archetype-colored progress bar with adaptive label"
```

---

### Task 2: Integrate New Bar into Onboarding Screens + Remove Step Counters

**Files:**
- Modify: `lib/features/onboarding/presentation/screens/interests_screen.dart`
- Modify: `lib/features/onboarding/presentation/screens/club_screen.dart`
- Modify: `lib/features/onboarding/presentation/screens/first_habits_screen.dart`
- Modify: `lib/features/onboarding/presentation/screens/identity_studio_screen.dart`
- Modify: `lib/features/onboarding/presentation/screens/world_reveal_screen.dart`

**Interfaces:**
- Consumes: `AnimatedOnboardingProgressBar` (was `OnboardingProgressBar`)
- All screens: replace `OnboardingProgressBar` import/usage with `AnimatedOnboardingProgressBar`
- `interests/club/first_habits`: remove `_Header` "STEP X OF Y" text
- `identity_studio`: after archetype selection, pass `accentColor` derived from archetype

- [ ] **Step 1: Update InterestsScreen — replace import + remove step counter + add color**

In `interests_screen.dart`:
  - Change `OnboardingProgressBar` → `AnimatedOnboardingProgressBar`
  - Change `progress:` → `targetProgress:`
  - Remove `_Header` widget's `'STEP $stepIndex OF $totalSteps'` text (line 222)
  - Add `accentColor: ...` from archetype state

```dart
// After archetype provider exists in the widget
final archetype = ref.watch(selectedArchetypeProvider);
final archetypeColor = archetype != null && archetype != UserArchetype.none
    ? ArchetypeColors.all[archetype.name]?.accent
    : null;

// In the build method
AnimatedOnboardingProgressBar(
  targetProgress: 0.6,
  label: "40% to go. Your interests give texture.",
  accentColor: archetypeColor,
)
```

- [ ] **Step 2: Run test to verify existing tests still pass**

Run: `flutter test test/features/onboarding/`
Expected: PASS

- [ ] **Step 3: Update ClubScreen — same pattern**

In `club_screen.dart`:
  - Change `OnboardingProgressBar` → `AnimatedOnboardingProgressBar`
  - Change `progress:` → `targetProgress:`
  - Remove `'STEP $stepIndex OF $totalSteps'` text (line 346)
  - Pass `accentColor` from archetype provider

- [ ] **Step 4: Update FirstHabitsScreen — same pattern**

In `first_habits_screen.dart`:
  - Change `OnboardingProgressBar` → `AnimatedOnboardingProgressBar`
  - Change `progress:` → `targetProgress:`
  - Remove `'STEP $stepIndex OF $totalSteps'` text (line 262)
  - Pass `accentColor` from archetype provider

- [ ] **Step 5: Update IdentityStudioScreen and WorldRevealScreen**

In `identity_studio_screen.dart`:
  - Change `OnboardingProgressBar` → `AnimatedOnboardingProgressBar`
  - Change `progress: 0.4` → `targetProgress: 0.4`
  - After archetype selected, pass `accentColor` to the bar

In `world_reveal_screen.dart`:
  - Change `OnboardingProgressBar` → `AnimatedOnboardingProgressBar`
  - Change `progress: 1.0` → `targetProgress: 1.0`

- [ ] **Step 6: Run focused tests**

Run: `flutter test test/features/onboarding/`
Expected: PASS

- [ ] **Step 7: Commit**

```bash
git add lib/features/onboarding/presentation/screens/interests_screen.dart lib/features/onboarding/presentation/screens/club_screen.dart lib/features/onboarding/presentation/screens/first_habits_screen.dart lib/features/onboarding/presentation/screens/identity_studio_screen.dart lib/features/onboarding/presentation/screens/world_reveal_screen.dart
git commit -m "feat(onboarding): integrate animated progress bar and remove step counter overlap"
```

---

### Task 3: Pre-Auth Endowment Interstitial Screen

**Files:**
- Modify: `lib/features/onboarding/presentation/screens/endowment_interstitial_screen.dart`
- Modify: `test/features/onboarding/presentation/screens/endowment_interstitial_screen_test.dart`

**Interfaces:**
- Consumes: `LocalSettingsRepository.hasSeenEndowment` (check), `markEndowmentSeen()`
- Produces: Screen with anonymous "Future You" greeting, "CLAIM YOUR WORLD" CTA navigating to `/signup`, "Sign in" link
- No longer takes `userName` parameter

- [ ] **Step 1: Update the test for pre-auth endowment**

```dart
// test/features/onboarding/presentation/screens/endowment_interstitial_screen_test.dart
import 'package:emerge_app/features/onboarding/presentation/screens/endowment_interstitial_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows anonymous welcome and starter items', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const EndowmentInterstitialScreen(),
      ),
    );

    expect(find.text('Welcome, Future You'), findsOneWidget);
    expect(find.text('Starter habit pack'), findsOneWidget);
    expect(find.text('Archetype tribe'), findsOneWidget);
    expect(find.text('Your world map'), findsOneWidget);
    expect(find.text('CLAIM YOUR WORLD →'), findsOneWidget);
    expect(find.text('Already a member?'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/onboarding/presentation/screens/endowment_interstitial_screen_test.dart`
Expected: FAIL — "Welcome, Future You" not found (old code still shows "Welcome, Alex")

- [ ] **Step 3: Rewrite the screen for pre-auth**

```dart
// lib/features/onboarding/presentation/screens/endowment_interstitial_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/emerge_theme.dart';
import '../widgets/onboarding_progress_bar.dart';
import '../../data/repositories/local_settings_repository.dart';

class EndowmentInterstitialScreen extends ConsumerWidget {
  const EndowmentInterstitialScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A0A1A),
              Color(0xFF1A0A2A),
              Color(0xFF2A1A3A),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const AnimatedOnboardingProgressBar(
                targetProgress: 0.2,
                label: "You've begun. Now define yourself.",
              ),
              const Spacer(flex: 2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Text(
                      '✨ Welcome, Future You',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Your world seed is planted.\nHere\'s what\'s already yours:',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              _EndowmentItem(
                emoji: '🎁',
                title: 'Starter habit pack',
                subtitle: 'reserved for you',
              ),
              const SizedBox(height: 20),
              _EndowmentItem(
                emoji: '🏟️',
                title: 'Archetype tribe',
                subtitle: 'waiting for you',
              ),
              const SizedBox(height: 20),
              _EndowmentItem(
                emoji: '🌍',
                title: 'Your world map',
                subtitle: 'ready to grow',
              ),
              const Spacer(flex: 2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () async {
                      final settings = ref.read(localSettingsRepositoryProvider);
                      await settings.markEndowmentSeen();
                      if (context.mounted) context.go('/signup');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyanAccent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                    child: const Text(
                      'CLAIM YOUR WORLD →',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/login'),
                child: Text(
                  'Already a member? Sign in',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _EndowmentItem extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;

  const _EndowmentItem({
    required this.emoji,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/onboarding/presentation/screens/endowment_interstitial_screen_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/onboarding/presentation/screens/endowment_interstitial_screen.dart test/features/onboarding/presentation/screens/endowment_interstitial_screen_test.dart
git commit -m "feat(onboarding): pre-auth endowment interstitial with anonymous Future You"
```

---

### Task 4: WelcomeScreen Routes + Router Redirect Simplification

**Files:**
- Modify: `lib/features/onboarding/presentation/screens/welcome_screen.dart`
- Modify: `lib/core/router/router.dart`
- Modify: `test/core/router/router_endowment_redirect_test.dart`

**Interfaces:**
- Consumes: `LocalSettingsRepository.hasSeenEndowment`
- Consumes: `decideRedirect()` — remove endowment branch
- Produces: WelcomeScreen routes to pre-auth endowment if `!hasSeenEndowment`, else sign-up

- [ ] **Step 1: Update redirect tests — remove endowment gating tests**

```dart
// test/core/router/router_endowment_redirect_test.dart
// This file is now renamed/repurposed since endowment is no longer in post-auth redirect.
// Tests for the simplified redirect (just onboardingProgress based routing).

import 'package:emerge_app/core/router/router.dart';
import 'package:emerge_app/features/auth/presentation/providers/role_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('decideRedirect — simplified onboarding redirect (no endowment gate)', () {
    RedirectContext ctxWith({required int? progress}) {
      return RedirectContext(
        isLoggedIn: true,
        role: UserRole.user,
        isFirstLaunch: false,
        userOnboardingProgress: progress,
        userOnboardingCompletedAt: null,
        creatorOnboarding: null,
        hasSeenEndowment: true, // endowment no longer gates post-auth redirect
      );
    }

    test('progress=0 -> /onboarding/identity-studio', () {
      expect(
        decideRedirect(
          currentPath: '/world-map',
          ctx: ctxWith(progress: 0),
        ),
        '/onboarding/identity-studio',
      );
    });

    test('progress=null -> /onboarding/identity-studio', () {
      expect(
        decideRedirect(
          currentPath: '/world-map',
          ctx: ctxWith(progress: null),
        ),
        '/onboarding/identity-studio',
      );
    });

    test('progress=1 -> /onboarding/interests', () {
      expect(
        decideRedirect(
          currentPath: '/world-map',
          ctx: ctxWith(progress: 1),
        ),
        '/onboarding/interests',
      );
    });

    test('onboarding screen path returns null (no redirect loop)', () {
      expect(
        decideRedirect(
          currentPath: '/onboarding/identity-studio',
          ctx: ctxWith(progress: 0),
        ),
        isNull,
      );
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/router/router_endowment_redirect_test.dart`
Expected: FAIL — old `decideRedirect` still has endowment branch

- [ ] **Step 3: Simplify router redirect — remove endowment check**

In `lib/core/router/router.dart`, find the `decideRedirect` function (around line 105-244). Locate the onboarding progress routing section (around line 213-234):

```dart
// BEFORE (current):
if (onboardingProgress == 0) {
  return ctx.hasSeenEndowment
      ? '/onboarding/identity-studio'
      : '/onboarding/endowment';
}

// AFTER (simplified):
if (onboardingProgress == 0) return '/onboarding/identity-studio';
```

Also remove the `/onboarding/endowment` route from the auth-guarded `StatefulShellRoute` and add it as a top-level (unauthenticated) route alongside `/welcome`:

```dart
// Add to top-level routes (unauthenticated):
GoRoute(
  path: '/onboarding/endowment',
  builder: (_, __) => const EndowmentInterstitialScreen(),
)
```

- [ ] **Step 4: Update WelcomeScreen**

In `lib/features/onboarding/presentation/screens/welcome_screen.dart`, find the "Begin Your Journey" button handler:

```dart
// BEFORE:
onPressed: () => context.go('/signup'),

// AFTER:
onPressed: () {
  final settings = ref.read(localSettingsRepositoryProvider);
  if (settings.hasSeenEndowment) {
    context.go('/signup');
  } else {
    context.go('/onboarding/endowment');
  }
},
```

- [ ] **Step 5: Run tests**

Run: `flutter test test/core/router/router_endowment_redirect_test.dart`
Expected: PASS

Run: `flutter test test/core/router/`
Expected: PASS (router_redirect_test.dart still passes with simplified redirect)

- [ ] **Step 6: Run full analysis**

Run: `dart analyze`
Expected: No errors

- [ ] **Step 7: Commit**

```bash
git add lib/core/router/router.dart lib/features/onboarding/presentation/screens/welcome_screen.dart test/core/router/router_endowment_redirect_test.dart
git commit -m "refactor(router): move endowment to pre-auth, simplify post-auth redirect"
```
