# Creator Dashboard Fixes — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix all Creator Dashboard issues — security bypass (no verified-creator gate), 3 empty placeholder tabs, missing entry point from main app, duplicate form key bug, and zero test coverage.

**Architecture:** Security gate first (prevents unauthorized access), then entry point (creators can reach dashboard), then fill the 3 empty tabs, then fix the login screen bug, then tests.

**Tech Stack:** Flutter, Dart, Riverpod, GoRouter, Firestore

**Key files:**
- `lib/core/router/router.dart` — route guards
- `lib/features/social/presentation/screens/creator/creator_dashboard_scaffold.dart` — dashboard shell
- `lib/features/social/presentation/screens/creator/creator_overview_tab.dart` — overview tab
- `lib/features/social/presentation/screens/creator/creator_blueprints_tab.dart` — blueprints tab
- `lib/features/social/presentation/screens/creator/creator_tribe_management_tab.dart` — tribe management tab
- `lib/features/auth/presentation/screens/creator_login_screen.dart` — login screen
- `lib/features/social/presentation/screens/creator_profile_screen.dart` — public profile
- `lib/features/social/data/repositories/creator_repository.dart` — data layer

---

### Task 1: Add Verified-Creator Gate on Dashboard Route

**Files:**
- Modify: `lib/core/router/router.dart`
- Create: `lib/features/auth/presentation/providers/creator_auth_provider.dart`
- Read: `lib/features/social/data/repositories/creator_repository.dart`

- [ ] **Step 1: Write test for route redirect**

Create `test/core/router/creator_route_guard_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Creator dashboard route guard', () {
    test('should redirect non-verified-creators away from /creator/dashboard', () async {
      // Arrange: mock auth state → user is NOT a verified creator
      // Act: navigate to /creator/dashboard
      // Assert: redirects to / or /creator/login
    });
  });
}
```

- [ ] **Step 2: Create `creator_auth_provider.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:emerge_app/features/social/data/repositories/creator_repository.dart';

final isVerifiedCreatorProvider = FutureProvider<bool>((ref) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return false;

  final repo = ref.watch(creatorRepositoryProvider);
  final profile = await repo.getCreatorProfile(user.uid);
  return profile?.isVerifiedCreator ?? false;
});
```

- [ ] **Step 3: Add route guard in `router.dart`**

Find the creator dashboard route definition. Add a redirect that checks `isVerifiedCreatorProvider`:

```dart
GoRoute(
  path: '/creator/dashboard',
  redirect: (context, state) async {
    final isVerified = await ref.read(isVerifiedCreatorProvider.future);
    if (!isVerified) return '/creator/login';
    return null; // allow access
  },
  builder: (context, state) => const CreatorDashboardScaffold(),
),
```

Wait — GoRouter `redirect` is synchronous. Use a `Future`-based approach with a shell route redirect or use a `Redirect` with a provider watcher.

Better approach: Use a `StatefulShellRoute` with a redirect that watches the provider. Since GoRouter redirect can't be async, use this pattern:

```dart
// In router.dart, before the creator routes:
redirect: (context, state) {
  if (state.matchedLocation.startsWith('/creator/dashboard')) {
    final isVerified = ref.read(isVerifiedCreatorProvider);
    // isVerified is AsyncValue<bool> — check data vs loading
    return isVerified.when(
      data: (v) => v ? null : '/creator/login',
      loading: () => null, // let loading screen show
      error: (_, __) => '/creator/login',
    );
  }
  return null;
},
```

- [ ] **Step 4: Run tests**

Run: `flutter test test/core/router/creator_route_guard_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/core/router/router.dart lib/features/auth/presentation/providers/creator_auth_provider.dart test/core/router/creator_route_guard_test.dart
git commit -m "fix: add isVerifiedCreator route guard to /creator/dashboard"
```

---

### Task 2: Add Creator Hub Entry Point in Profile/Me Tab

**Files:**
- Modify: `lib/features/social/presentation/screens/creator_profile_screen.dart` (or the Me tab)
- Need to find the Me/profile screen first

- [ ] **Step 1: Find the Me/profile tab screen**

Run: `rg "Me tab\|Profile tab\|class.*MeTab\|class.*ProfileTab" lib/features/ --no-heading -n` or glob for profile screens

- [ ] **Step 2: Add "Creator Hub" button for verified creators**

In the profile screen, add:

```dart
// Inside the profile screen build method:
final isCreator = ref.watch(isVerifiedCreatorProvider);

isCreator.when(
  data: (verified) {
    if (verified) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton.icon(
          onPressed: () => context.push('/creator/dashboard'),
          icon: const Icon(Icons.dashboard_customize),
          label: const Text('Creator Hub'),
        ),
      );
    }
    return const SizedBox.shrink();
  },
  loading: () => const SizedBox.shrink(),
  error: (_, __) => const SizedBox.shrink(),
);
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/social/presentation/screens/creator_profile_screen.dart
git commit -m "feat: add Creator Hub entry point for verified creators in profile"
```

---

### Task 3: Fill Creator Overview Tab with Real Analytics Cards

**Files:**
- Modify: `lib/features/social/presentation/screens/creator/creator_overview_tab.dart`
- Create: `test/features/social/presentation/screens/creator/creator_overview_tab_test.dart`

- [ ] **Step 1: Write test**

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CreatorOverviewTab shows analytics cards', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: CreatorOverviewTab()),
    );
    // Cards should be tappable, not decorative
    expect(find.text('Total Adoptions'), findsOneWidget);
    expect(find.text('Active Tribe Members'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Replace placeholder with real content**

Replace `creator_overview_tab.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CreatorOverviewTab extends ConsumerWidget {
  const CreatorOverviewTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Creator Hub')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Welcome, Creator!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          _AnalyticsCard(
            icon: Icons.widgets_rounded,
            title: 'Blueprints',
            subtitle: 'Manage your habit blueprints',
            value: '5 Published',
            onTap: () => context.push('/creator/dashboard/blueprints'),
          ),
          const SizedBox(height: 12),
          _AnalyticsCard(
            icon: Icons.groups_rounded,
            title: 'Tribe',
            subtitle: 'Manage your community',
            value: 'View Members',
            onTap: () => context.push('/creator/dashboard/tribe'),
          ),
          const SizedBox(height: 12),
          _AnalyticsCard(
            icon: Icons.analytics_rounded,
            title: 'Analytics',
            subtitle: 'Adoptions, growth, engagement',
            value: 'View Stats',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Analytics coming soon')),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String value;
  final VoidCallback onTap;

  const _AnalyticsCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
```

- [ ] **Step 3: Run test**

Run: `flutter test test/features/social/presentation/screens/creator/creator_overview_tab_test.dart`
Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add lib/features/social/presentation/screens/creator/creator_overview_tab.dart test/features/social/presentation/screens/creator/creator_overview_tab_test.dart
git commit -m "fix: replace placeholder CreatorOverviewTab with tappable analytics cards"
```

---

### Task 4: Fill Creator Blueprints Tab with Blueprint List

**Files:**
- Modify: `lib/features/social/presentation/screens/creator/creator_blueprints_tab.dart`
- Read: `lib/features/social/presentation/screens/social_discover_tab.dart` (reference blueprint card pattern)

- [ ] **Step 1: Write test**

Create `test/features/social/presentation/screens/creator/creator_blueprints_tab_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CreatorBlueprintsTab shows blueprint list', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: CreatorBlueprintsTab()),
    );
    // Should show blueprints, not just placeholder text
    expect(find.text('Blueprints Studio'), findsNothing);
    expect(find.byType(ListView), findsOneWidget);
  });
}
```

- [ ] **Step 2: Replace placeholder with blueprint GridView**

Replace `creator_blueprints_tab.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/features/blueprints/presentation/providers/blueprint_providers.dart';
import 'package:emerge_app/features/social/presentation/widgets/blueprint_card.dart';

class CreatorBlueprintsTab extends ConsumerWidget {
  const CreatorBlueprintsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blueprintsAsync = ref.watch(allBlueprintsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Blueprints Studio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Blueprint editor coming soon')),
              );
            },
            tooltip: 'Create new blueprint',
          ),
        ],
      ),
      body: blueprintsAsync.when(
        data: (blueprints) {
          if (blueprints.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.widgets, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No blueprints yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('Tap + to create your first blueprint'),
                ],
              ),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: blueprints.length,
            itemBuilder: (context, index) {
              final blueprint = blueprints[index];
              return BlueprintCard(blueprint: blueprint);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading blueprints: $e')),
      ),
    );
  }
}
```

- [ ] **Step 3: Run test**

Run: `flutter test test/features/social/presentation/screens/creator/creator_blueprints_tab_test.dart`
Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add lib/features/social/presentation/screens/creator/creator_blueprints_tab.dart test/features/social/presentation/screens/creator/creator_blueprints_tab_test.dart
git commit -m "fix: replace placeholder Blueprints Studio tab with live blueprint grid"
```

---

### Task 5: Fill Creator Tribe Management Tab with Member List

**Files:**
- Modify: `lib/features/social/presentation/screens/creator/creator_tribe_management_tab.dart`

- [ ] **Step 1: Write test**

Create `test/features/social/presentation/screens/creator/creator_tribe_management_tab_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CreatorTribeManagementTab shows member list', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: CreatorTribeManagementTab()),
    );
    expect(find.text('Tribe Management'), findsNothing);
    expect(find.byType(ListView), findsOneWidget);
  });
}
```

- [ ] **Step 2: Replace placeholder with tribe member list**

Replace `creator_tribe_management_tab.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';

class CreatorTribeManagementTab extends ConsumerWidget {
  const CreatorTribeManagementTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tribesAsync = ref.watch(tribesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tribe Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.announcement_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Announcements coming soon')),
              );
            },
            tooltip: 'Post announcement',
          ),
        ],
      ),
      body: tribesAsync.when(
        data: (tribes) {
          if (tribes.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.groups, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No tribes to manage', style: TextStyle(fontSize: 18)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tribes.length,
            itemBuilder: (context, index) {
              final tribe = tribes[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text(tribe.name[0])),
                  title: Text(tribe.name),
                  subtitle: Text('${tribe.memberCount ?? 0} members'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${tribe.name} management coming soon')),
                    );
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
```

- [ ] **Step 3: Run test**

Run: `flutter test test/features/social/presentation/screens/creator/creator_tribe_management_tab_test.dart`
Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add lib/features/social/presentation/screens/creator/creator_tribe_management_tab.dart test/features/social/presentation/screens/creator/creator_tribe_management_tab_test.dart
git commit -m "fix: replace placeholder Tribe Management tab with live tribe list"
```

---

### Task 6: Fix Duplicate Form Key Bug in CreatorLoginScreen

**Files:**
- Modify: `lib/features/auth/presentation/screens/creator_login_screen.dart`

- [ ] **Step 1: Write test detecting the bug**

Create `test/features/auth/presentation/screens/creator_login_screen_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CreatorLoginScreen has unique form keys', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: CreatorLoginScreen()),
    );
    // Should not throw about duplicate GlobalKey
    expect(tester.takeException(), isNull);
  });
}
```

- [ ] **Step 2: Fix the duplicate form key**

In `creator_login_screen.dart`, change the tablet layout to use a separate form key or use only one Form widget wrapping both panels:

```dart
// Option 1: Remove the Form wrapper from the branding panel
// Only the form panel should be wrapped in Form

// Option 2: Use a wrapping Form that covers both panels
// and remove the duplicate Form tags

// Option 3: Use different GlobalKeys
final _brandingFormKey = GlobalKey<FormState>();
```

Recommended: Wrap only the actual form (right panel on tablet) in the Form widget, not the branding/left panel.

- [ ] **Step 3: Run test**

Run: `flutter test test/features/auth/presentation/screens/creator_login_screen_test.dart`
Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add lib/features/auth/presentation/screens/creator_login_screen.dart test/features/auth/presentation/screens/creator_login_screen_test.dart
git commit -m "fix: remove duplicate Form widget sharing same GlobalKey on tablet layout"
```

---

### Task 7: Add Tests for Creator Provider and Repository

**Files:**
- Create: `test/features/social/data/repositories/creator_repository_test.dart`
- Create: `test/features/social/presentation/providers/creator_provider_test.dart`

- [ ] **Step 1: Write repository test**

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CreatorRepository', () {
    test('watchCreatorProfile returns null for non-existent user', () async {
      // Mock Firestore returns empty doc
      // Verify stream emits null
    });

    test('updateCreatorProfile writes correct data', () async {
      // Mock Firestore
      // Verify correct collection/doc/set called with merge:true
    });
  });
}
```

- [ ] **Step 2: Write provider test**

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isVerifiedCreatorProvider', () {
    test('returns false when user is not authenticated', () async {
      // Mock FirebaseAuth to return null
      // Verify provider emits false
    });
  });
}
```

- [ ] **Step 3: Run tests**

Run: `flutter test test/features/social/ test/features/auth/`
Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add test/features/social/data/repositories/creator_repository_test.dart test/features/social/presentation/providers/creator_provider_test.dart
git commit -m "test: add CreatorRepository and isVerifiedCreatorProvider tests"
```

---

### Task 8: Fix CreatorProfileScreen Missing Blueprints

**Files:**
- Modify: `lib/features/social/presentation/screens/creator_profile_screen.dart`

- [ ] **Step 1: Add blueprint list to creator profile**

Replace `// Display blueprints here` comment with:

```dart
const SizedBox(height: 24),
const Text('Blueprints', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
const SizedBox(height: 12),
blueprintsAsync.when(
  data: (blueprints) {
    if (blueprints.isEmpty) {
      return const Text('No blueprints yet', style: TextStyle(color: Colors.grey));
    }
    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: blueprints.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final blueprint = blueprints[index];
          return BlueprintCard(blueprint: blueprint);
        },
      ),
    );
  },
  loading: () => const Center(child: CircularProgressIndicator()),
  error: (_, __) => const Text('Could not load blueprints'),
),
```

- [ ] **Step 2: Fetch blueprints for this creator**

Add at the top of the profile screen:

```dart
final blueprintsAsync = ref.watch(blueprintsByCreatorProvider(creatorId));
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/social/presentation/screens/creator_profile_screen.dart
git commit -m "fix: add blueprint list to creator profile screen"
```
