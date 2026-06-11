# Habit Forge and Tribe Tabs Reorganization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reorganize Emerge's main navigation flow to include "The Habit Forge" (formerly Discover) and "Tribe Sanctum" as separate bottom navigation tabs, replacing the direct Profile tab, and adding a unified status HUD top bar across all main screens.

**Architecture:** Use GoRouter StatefulShellRoute branches to re-map navigation. Refactor the single-page Tribe Sanctum layout into a secondary nested TabController inside `TribeTabContent`.

**Tech Stack:** Flutter, Riverpod, GoRouter, flutter_animate

---

### Task 1: Create Unified Status HUD Top Bar

**Files:**
- Create: `lib/core/presentation/widgets/emerge_status_hud_top_bar.dart`
- Test: `test/core/presentation/widgets/emerge_status_hud_top_bar_test.dart`

- [ ] **Step 1: Write widget interface and implementation**
  Write a reusable SliverAppBar widget that listens to `userStatsStreamProvider` to render the user's active archetype map name, level badge, XP progress bar, and profile icon avatar.

  ```dart
  import 'dart:ui';
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:go_router/go_router.dart';
  import 'package:emerge_app/core/theme/emerge_colors.dart';
  import 'package:emerge_app/core/theme/archetype_theme.dart';
  import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
  import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
  import 'package:emerge_app/features/world_map/domain/models/archetype_maps_catalog.dart';

  class EmergeStatusHudTopBar extends ConsumerWidget {
    final PreferredSizeWidget? bottom;
    
    const EmergeStatusHudTopBar({super.key, this.bottom});

    @override
    Widget build(BuildContext context, WidgetRef ref) {
      final userProfileAsync = ref.watch(userStatsStreamProvider);
      
      final profile = userProfileAsync.value;
      if (profile == null) {
        return const SliverToBoxAdapter(child: SizedBox.shrink());
      }
      
      final archetype = profile.archetype;
      final config = ArchetypeMapsCatalog.getMapForArchetype(archetype);
      final level = profile.effectiveLevel;
      final theme = ArchetypeTheme.forArchetype(archetype);
      final xpProgress = (profile.avatarStats.totalXp % 500) / 500.0;

      return SliverAppBar(
        expandedHeight: bottom != null ? 140.0 : 100.0,
        floating: false,
        pinned: true,
        elevation: 0,
        backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
        automaticallyImplyLeading: false,
        flexibleSpace: FlexibleSpaceBar(
          background: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.primaryColor.withValues(alpha: 0.3),
                      theme.accentColor.withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ],
          ),
          titlePadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          title: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(config.journeyIcon, color: theme.primaryColor, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          config.mapName.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          theme.tagline.toUpperCase(),
                          style: TextStyle(
                            color: theme.accentColor.withValues(alpha: 0.8),
                            fontSize: 8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.primaryColor.withValues(alpha: 0.6)),
                    ),
                    child: Text(
                      'LVL $level',
                      style: TextStyle(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => context.push('/profile'),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: theme.primaryColor.withValues(alpha: 0.4), width: 1.5),
                      ),
                      child: CircleAvatar(
                        radius: 12,
                        backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
                        child: Icon(Icons.person_outline, color: theme.primaryColor, size: 14),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: xpProgress,
                backgroundColor: theme.primaryColor.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
                minHeight: 2,
                borderRadius: BorderRadius.circular(99),
              ),
            ],
          ),
        ),
        bottom: bottom,
      );
    }
  }
  ```

- [ ] **Step 2: Write widget unit test**
  Write `test/core/presentation/widgets/emerge_status_hud_top_bar_test.dart` to verify that the widget renders stats information and triggers navigation when the profile button is clicked.

- [ ] **Step 3: Verify and Commit**
  Run tests and commit the new widget files.

---

### Task 2: Reorganize GoRouter App Routes

**Files:**
- Modify: `lib/core/router/router.dart`

- [ ] **Step 1: Reorder StatefulShellBranch branches**
  Update the shell branches in `router.dart` so that:
  - Branch 0 remains `/` (`WorldMapScreen`).
  - Branch 1 remains `/timeline` (`TimelineScreen`).
  - Branch 2 becomes `/discover` (`SocialDiscoverTab`).
  - Branch 3 becomes `/tribes` (`SocialScreen`).

  *Code changes in StatefulShellRoute.indexedStack branches in router.dart:*
  ```dart
  // Branch 3: Discover (NEW ROOT TAB)
  StatefulShellBranch(
    routes: [
      GoRoute(
        path: '/discover',
        builder: (context, state) => const SocialDiscoverTab(showAsRoot: true),
      ),
    ],
  ),
  // Branch 4: Social (Tribe & Challenges)
  StatefulShellBranch(
    routes: [
      GoRoute(
        path: '/tribes',
        builder: (context, state) => const SocialScreen(initialIndex: 0),
        routes: [
          // Subroutes (challenges, leaderboard, friends, etc.) stay here
  ```

- [ ] **Step 2: Verify and Commit**
  Ensure compilation is clean and commit.

---

### Task 3: Update Bottom Navigation Bar (EmergeBottomNav)

**Files:**
- Modify: `lib/core/presentation/widgets/emerge_bottom_nav.dart`

- [ ] **Step 1: Reorder navigation items**
  Adjust `EmergeBottomNav` so the right side of the FAB contains:
  - Forge (Index 2, Icon: `Icons.explore_outlined`)
  - Tribe (Index 3, Icon: `Icons.groups`)
  Remove the Profile/Identity nav item.

  *Code update in emerge_bottom_nav.dart:*
  ```dart
  // Right side: Forge + Tribe
  Expanded(
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _NavItem(
          icon: Icons.explore_outlined,
          label: 'Forge',
          isSelected: currentIndex == 2,
          onTap: () => _onItemTapped(2),
        ),
        _NavItem(
          icon: Icons.groups,
          label: 'Tribe',
          isSelected: currentIndex == 3,
          onTap: () => _onItemTapped(3),
        ),
      ],
    ),
  ),
  ```

- [ ] **Step 2: Verify and Commit**
  Ensure that bottom navigation index matching works flawlessly.

---

### Task 4: Reorganize SocialScreen and Discover Tab Scaffold

**Files:**
- Modify: `lib/features/social/presentation/screens/social_screen.dart`
- Modify: `lib/features/social/presentation/screens/social_discover_tab.dart`

- [ ] **Step 1: Update SocialScreen tabs**
  Remove the third "DISCOVER" tab from `SocialScreen`. Reduce the `TabController` length to 2.
  Use `EmergeStatusHudTopBar` as the top sliver header.
  ```dart
  tabs: const [
    Tab(text: 'TRIBE'),
    Tab(text: 'CHALLENGES'),
  ],
  ```

- [ ] **Step 2: Add scaffold wrapper to SocialDiscoverTab**
  Update `SocialDiscoverTab` to accept a `showAsRoot` parameter. If true, wrap it in a `Scaffold` and use `EmergeStatusHudTopBar` as its app bar.

  *Code changes in social_discover_tab.dart:*
  ```dart
  class SocialDiscoverTab extends ConsumerStatefulWidget {
    final bool showAsRoot;
    const SocialDiscoverTab({super.key, this.showAsRoot = false});
    // ...
  }

  // Inside build():
  Widget content = Stack(children: [ ... ]);
  if (widget.showAsRoot) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const EmergeStatusHudTopBar(),
            SliverFillRemaining(child: content),
          ],
        ),
      ),
    );
  }
  return content;
  ```

- [ ] **Step 3: Verify and Commit**
  Verify social screen and forge loading, run tests, and commit.

---

### Task 5: Refactor TribeTabContent to Sub-Tabbed Layout

**Files:**
- Modify: `lib/features/social/presentation/screens/tribe_tab_content.dart`

- [ ] **Step 1: Add nested TabController and capsule selector**
  Wrap the layout in a nested `DefaultTabController` with 4 tabs: Sanctum, Quests, Members, Bonds.
  Place a glassmorphic pill TabBar below the header.

  *Code structure for sub-tab bar inside tribe_tab_content.dart:*
  ```dart
  return DefaultTabController(
    length: 4,
    child: Column(
      children: [
        const Gap(12),
        // Sub-Tab Bar
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: TabBar(
            indicator: BoxDecoration(
              color: EmergeColors.teal.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: EmergeColors.teal.withValues(alpha: 0.3)),
            ),
            labelColor: EmergeColors.teal,
            unselectedLabelColor: Colors.white60,
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: const [
              Tab(text: 'Sanctum'),
              Tab(text: 'Quests'),
              Tab(text: 'Members'),
              Tab(text: 'Bonds'),
            ],
          ),
        ),
        const Gap(16),
        // Tab views containing existing components
        Expanded(
          child: TabBarView(
            children: [
              _buildSanctumTab(userClub, theme),
              _buildQuestsTab(userClub),
              _buildMembersTab(userClub, profile.archetype.name),
              _buildBondsTab(),
            ],
          ),
        ),
      ],
    ),
  );
  ```

- [ ] **Step 2: Group existing list elements into tab builders**
  Partition the elements originally listed vertically inside `tribe_tab_content.dart`:
  - `_buildSanctumTab`: Emblem, club name, description, member count, activity log feed.
  - `_buildQuestsTab`: `TribeQuestsSection`.
  - `_buildMembersTab`: `ContributorsSection`, `_TribeLeaderboardSection`.
  - `_buildBondsTab`: `TribeAccountabilitySection`.

- [ ] **Step 3: Run and verify**
  Run the test suites and check visual tab toggles inside the simulator/simulator logs. Commit the changes.
