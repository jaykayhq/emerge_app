# Creator Tribes Space Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the immersive Tribe Space that replaces the main bottom navigation. Implement the Feed, My Tribe, Board, and Discover tabs within this new scaffold.

**Architecture:** 
- `TribeSpaceScaffold`: A new scaffold with its own BottomNavigationBar.
- `TribeFeedTab`: Shows tribe activity.
- `MyTribeTab`: Shows quests, challenges, and roles.
- `TribeBoardTab`: Shows the leaderboard.
- `TribeDiscoverTab`: Shows blueprints and creators (migrated from existing SocialDiscoverTab).

**Tech Stack:** Flutter, Riverpod, go_router

---

### Task 1: Create Tribe Space Scaffold

**Files:**
- Modify: `lib/features/social/presentation/screens/tribe_space_scaffold.dart`

- [ ] **Step 1: Implement the scaffold**

```dart
// Modify lib/features/social/presentation/screens/tribe_space_scaffold.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';

class TribeSpaceScaffold extends StatefulWidget {
  const TribeSpaceScaffold({super.key});

  @override
  State<TribeSpaceScaffold> createState() => _TribeSpaceScaffoldState();
}

class _TribeSpaceScaffoldState extends State<TribeSpaceScaffold> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    Center(child: Text("Feed", style: TextStyle(color: Colors.white))),
    Center(child: Text("My Tribe", style: TextStyle(color: Colors.white))),
    Center(child: Text("Board", style: TextStyle(color: Colors.white))),
    Center(child: Text("Discover", style: TextStyle(color: Colors.white))),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EmergeColors.cosmicVoidCenter,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text("Tribe Space"),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: EmergeColors.cosmicVoidDark,
        selectedItemColor: EmergeColors.neonTeal,
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.campaign), label: 'Feed'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance), label: 'My Tribe'),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: 'Board'),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Discover'),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/social/presentation/screens/tribe_space_scaffold.dart
git commit -m "feat: implement TribeSpaceScaffold with bottom nav"
```

### Task 2: Create Feed and My Tribe Tabs

**Files:**
- Create: `lib/features/social/presentation/screens/tribe_feed_tab.dart`
- Create: `lib/features/social/presentation/screens/my_tribe_tab.dart`

- [ ] **Step 1: Create Feed Tab**

```dart
// lib/features/social/presentation/screens/tribe_feed_tab.dart
import 'package:flutter/material.dart';

class TribeFeedTab extends StatelessWidget {
  const TribeFeedTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Feed content goes here", style: TextStyle(color: Colors.white)));
  }
}
```

- [ ] **Step 2: Create My Tribe Tab**

```dart
// lib/features/social/presentation/screens/my_tribe_tab.dart
import 'package:flutter/material.dart';

class MyTribeTab extends StatelessWidget {
  const MyTribeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("My Tribe content goes here", style: TextStyle(color: Colors.white)));
  }
}
```

- [ ] **Step 3: Update Scaffold to use the tabs**

Modify `lib/features/social/presentation/screens/tribe_space_scaffold.dart` to use `TribeFeedTab()` and `MyTribeTab()` instead of placeholders.

- [ ] **Step 4: Commit**

```bash
git add lib/features/social/presentation/screens/tribe_feed_tab.dart lib/features/social/presentation/screens/my_tribe_tab.dart lib/features/social/presentation/screens/tribe_space_scaffold.dart
git commit -m "feat: add Feed and My Tribe tabs"
```

### Task 3: Create Board and Discover Tabs

**Files:**
- Create: `lib/features/social/presentation/screens/tribe_board_tab.dart`
- Modify: `lib/features/social/presentation/screens/tribe_space_scaffold.dart`

- [ ] **Step 1: Create Board Tab**

```dart
// lib/features/social/presentation/screens/tribe_board_tab.dart
import 'package:flutter/material.dart';

class TribeBoardTab extends StatelessWidget {
  const TribeBoardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Leaderboard goes here", style: TextStyle(color: Colors.white)));
  }
}
```

- [ ] **Step 2: Integrate Discover Tab**

Modify `lib/features/social/presentation/screens/tribe_space_scaffold.dart` to use `TribeBoardTab()` and the existing `SocialDiscoverTab()` (imported from `social_discover_tab.dart`).

- [ ] **Step 3: Commit**

```bash
git add lib/features/social/presentation/screens/tribe_board_tab.dart lib/features/social/presentation/screens/tribe_space_scaffold.dart
git commit -m "feat: add Board and Discover tabs to Tribe Space"
```
