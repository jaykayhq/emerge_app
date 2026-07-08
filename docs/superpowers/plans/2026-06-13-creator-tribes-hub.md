# Creator Profile & Hub Dashboard Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create the creator's public profile (Peloton-style) and the private hub where creators can manage their tribe and build blueprints.

**Architecture:** 
- `CreatorProfileScreen`: Public view of a creator. Shows their bio, stats, and blueprints.
- `CreatorHubScreen`: Private dashboard for verified creators.
- `BlueprintDetailScreen`: Update to support creator attribution.

**Tech Stack:** Flutter, Riverpod, go_router

---

### Task 1: Create Creator Profile Screen

**Files:**
- Create: `lib/features/social/presentation/screens/creator_profile_screen.dart`
- Modify: `lib/core/router/router.dart`

- [ ] **Step 1: Create CreatorProfileScreen**

```dart
// lib/features/social/presentation/screens/creator_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:emerge_app/features/social/presentation/providers/creator_provider.dart';

class CreatorProfileScreen extends ConsumerWidget {
  final String creatorId;

  const CreatorProfileScreen({super.key, required this.creatorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(creatorProfileProvider(creatorId));

    return Scaffold(
      appBar: AppBar(title: const Text('Creator Profile')),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) return const Center(child: Text('Profile not found'));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
              const SizedBox(height: 16),
              Text(profile.bio, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 24),
              const Text('Blueprints', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              // Display blueprints here
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
```

- [ ] **Step 2: Update Router**

```dart
// Modify lib/core/router/router.dart
import 'package:emerge_app/features/social/presentation/screens/creator_profile_screen.dart';

// Inside the social branch routes, add:
                  GoRoute(
                    path: 'creator/:id',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => CreatorProfileScreen(
                      creatorId: state.pathParameters['id']!,
                    ),
                  ),
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/social/presentation/screens/creator_profile_screen.dart lib/core/router/router.dart
git commit -m "feat: add CreatorProfileScreen"
```

### Task 2: Create Creator Hub Dashboard

**Files:**
- Create: `lib/features/social/presentation/screens/creator_hub_screen.dart`

- [ ] **Step 1: Create CreatorHubScreen**

```dart
// lib/features/social/presentation/screens/creator_hub_screen.dart
import 'package:flutter/material.dart';

class CreatorHubScreen extends StatelessWidget {
  const CreatorHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Creator Hub')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Text('Welcome, Creator!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          Card(child: ListTile(title: Text('Manage Tribe'), trailing: Icon(Icons.chevron_right))),
          Card(child: ListTile(title: Text('Blueprint Builder'), trailing: Icon(Icons.chevron_right))),
          Card(child: ListTile(title: Text('Analytics'), trailing: Icon(Icons.chevron_right))),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/social/presentation/screens/creator_hub_screen.dart
git commit -m "feat: add CreatorHubScreen dashboard"
```

### Task 3: Update Blueprint Detail Screen

**Files:**
- Modify: `lib/features/blueprints/presentation/screens/blueprint_detail_screen.dart`

- [ ] **Step 1: Add creator attribution**

Modify `BlueprintDetailScreen` to show the `creatorName` and `tribeMemberCount` if `isCreatorBlueprint` is true. Add a button to navigate to the creator's profile using `context.push('/social/creator/${blueprint.creatorUserId}')`.

- [ ] **Step 2: Commit**

```bash
git add lib/features/blueprints/presentation/screens/blueprint_detail_screen.dart
git commit -m "feat: show creator details on BlueprintDetailScreen"
```
