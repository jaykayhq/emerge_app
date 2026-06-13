# Creator Tribes Lobby Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create the entry point to the social experience. Implement the one-time choice screen (Archetype vs Creator Tribe) and the atmospheric Tribe Lobby with the portal transition.

**Architecture:** 
- `SocialOnboardingScreen`: Simple choice screen that writes a completion flag.
- `TribeLobbyScreen`: Atmospheric screen with live tribe pulse + ENTER TRIBE CTA. Uses `WorldBackground` with archetype-aware theming.
- Router: Update `go_router` to handle `/social` and `/social/onboarding`.

**Tech Stack:** Flutter, go_router, Riverpod

---

### Task 1: Update Router

**Files:**
- Modify: `lib/core/router/router.dart`

- [ ] **Step 1: Add new routes and redirect logic**

```dart
// Modify lib/core/router/router.dart

// 1. In the imports, add:
import 'package:emerge_app/features/social/presentation/screens/social_onboarding_screen.dart';
import 'package:emerge_app/features/social/presentation/screens/tribe_lobby_screen.dart';
import 'package:emerge_app/features/social/presentation/screens/tribe_space_scaffold.dart';

// 2. In the GoRouter redirect logic, check social onboarding:
// Add a provider to check if social onboarding is complete
// Or simply check it in the UI and redirect. For simplicity, we will let the UI handle the first-time redirect.

// 3. In the routes list, replace the Social branch:
// Replace this:
/*
          // Branch 3: Social (Tribe · Challenges · Discover)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tribes',
                builder: (context, state) => const SocialScreen(initialIndex: 0),
                ...
*/
// With this:
          // Branch 3: Social (Tribe Lobby)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/social',
                builder: (context, state) => const TribeLobbyScreen(),
                routes: [
                  GoRoute(
                    path: 'onboarding',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const SocialOnboardingScreen(),
                  ),
                  GoRoute(
                    path: 'space',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const TribeSpaceScaffold(),
                  ),
                  // Keep the existing sub-routes like challenges, leaderboard, etc. under the space route later.
                ],
              ),
            ],
          ),
```

- [ ] **Step 2: Commit**

```bash
git add lib/core/router/router.dart
git commit -m "feat: update router for new social lobby and onboarding screens"
```

### Task 2: Create Social Onboarding Screen

**Files:**
- Create: `lib/features/social/presentation/screens/social_onboarding_screen.dart`
- Create: `lib/features/social/presentation/providers/social_onboarding_provider.dart`

- [ ] **Step 1: Create the onboarding provider**

```dart
// lib/features/social/presentation/providers/social_onboarding_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final socialOnboardingCompletedProvider = StateNotifierProvider<SocialOnboardingNotifier, bool>((ref) {
  return SocialOnboardingNotifier();
});

class SocialOnboardingNotifier extends StateNotifier<bool> {
  SocialOnboardingNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('social_onboarding_complete') ?? false;
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('social_onboarding_complete', true);
    state = true;
  }
}
```

- [ ] **Step 2: Create the Social Onboarding Screen**

```dart
// lib/features/social/presentation/screens/social_onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/features/social/presentation/providers/social_onboarding_provider.dart';

class SocialOnboardingScreen extends ConsumerWidget {
  const SocialOnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.cosmicGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "YOUR TRIBE AWAITS",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Every legend belongs to a tribe. Choose yours.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 48),
                _buildOptionCard(
                  context,
                  title: "🏛️ ARCHETYPE TRIBE",
                  description: "Join thousands of Scholars, Athletes, Creators & more.\n✓ Matched to your identity\n✓ Global community",
                  buttonText: "JOIN ARCHETYPE TRIBE",
                  onTap: () {
                    ref.read(socialOnboardingCompletedProvider.notifier).completeOnboarding();
                    context.go('/social');
                  },
                ),
                const SizedBox(height: 24),
                _buildOptionCard(
                  context,
                  title: "⚡ CREATOR TRIBE",
                  description: "Follow a verified creator. Adopt their exact blueprint.\n✓ Curated habit blueprint\n✓ Tight-knit community",
                  buttonText: "BROWSE CREATORS",
                  onTap: () {
                    ref.read(socialOnboardingCompletedProvider.notifier).completeOnboarding();
                    // Go to discover tab later, for now just go to social
                    context.go('/social');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard(BuildContext context, {required String title, required String description, required String buttonText, required VoidCallback onTap}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(description, style: const TextStyle(color: Colors.white70, height: 1.5), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onTap,
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/social/presentation/screens/social_onboarding_screen.dart lib/features/social/presentation/providers/social_onboarding_provider.dart
git commit -m "feat: add SocialOnboardingScreen and provider"
```

### Task 3: Create Tribe Lobby Screen

**Files:**
- Create: `lib/features/social/presentation/screens/tribe_lobby_screen.dart`

- [ ] **Step 1: Create the Tribe Lobby Screen**

```dart
// lib/features/social/presentation/screens/tribe_lobby_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:emerge_app/core/presentation/widgets/world_background.dart';
import 'package:emerge_app/features/social/presentation/providers/social_onboarding_provider.dart';

class TribeLobbyScreen extends ConsumerStatefulWidget {
  const TribeLobbyScreen({super.key});

  @override
  ConsumerState<TribeLobbyScreen> createState() => _TribeLobbyScreenState();
}

class _TribeLobbyScreenState extends ConsumerState<TribeLobbyScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isComplete = ref.read(socialOnboardingCompletedProvider);
      if (!isComplete) {
        context.go('/social/onboarding');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WorldBackground(
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                children: [
                  const Text("THE SCHOLARS 🔰", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text("1,247 members · Your streak: 🔥14d", style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 24),
                  const Text("🗡️ Collective Quest: 73%", style: TextStyle(color: Colors.white)),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: 0.73, backgroundColor: Colors.white24, color: Colors.green),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.flash_on),
                    label: const Text("ENTER TRIBE"),
                    onPressed: () {
                      context.push('/social/space');
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Create a dummy scaffold to prevent router crash**

```dart
// lib/features/social/presentation/screens/tribe_space_scaffold.dart
import 'package:flutter/material.dart';

class TribeSpaceScaffold extends StatelessWidget {
  const TribeSpaceScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text("Tribe Space - Coming Soon")),
    );
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/social/presentation/screens/tribe_lobby_screen.dart lib/features/social/presentation/screens/tribe_space_scaffold.dart
git commit -m "feat: add TribeLobbyScreen with onboarding redirect"
```
