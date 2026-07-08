# Social Hub Redesign: Lobby-Only Hub Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove the 4-tab Tribe Space and embed all content (feed, leaderboard, challenges, discover) directly into the Tribe Lobby as scrollable sections, making the lobby the single social hub.

**Architecture:** Delete `TribeSpaceScaffold` and its 4 tab screens. Extract reusable widgets from the tab screens into standalone widget files. Expand `TribeLobbyScreen` to include all sections as a single scrollable view. Remove `/social/space/*` routes from the router. The lobby is accessed via the bottom nav Tribe tab at `/social`.

**Tech Stack:** Flutter, Riverpod, GoRouter, Firestore

---

## File Structure

### Files to Delete
| File | Reason |
|------|--------|
| `lib/features/social/presentation/screens/tribe_space_scaffold.dart` | The 4-tab shell with its own bottom nav |
| `lib/features/social/presentation/screens/tribe_feed_tab.dart` | Thin wrapper around `TribeActivitySection` - content moves to lobby |
| `lib/features/social/presentation/screens/my_tribe_tab.dart` | Tribe header + accountability + quests - content moves to lobby |
| `lib/features/social/presentation/screens/tribe_board_tab.dart` | Leaderboard - content moves to lobby, widgets extracted |
| `lib/features/social/presentation/screens/social_discover_tab.dart` | Blueprint browser - content moves to lobby |

### New Files to Create
| File | Content |
|------|---------|
| `lib/features/social/presentation/widgets/tribe_leaderboard_widget.dart` | `TribeLeaderboardSection`, `LeaderboardRow`, `YouPinnedRow` - extracted from `tribe_board_tab.dart` |
| `lib/features/social/presentation/widgets/tribe_discover_section.dart` | `TribeDiscoverSection`, `DiscoverCategoryStrip`, `DiscoverBlueprintCard` - extracted from `social_discover_tab.dart` |

### Files to Modify
| File | Changes |
|------|---------|
| `lib/features/social/presentation/screens/tribe_lobby_screen.dart` | Add feed section, leaderboard section, challenges section, discover section as scrollable slivers |
| `lib/core/router/router.dart` | Remove `/social/space/*` routes and `TribeSpaceScaffold`; update redirects |
| `lib/features/social/presentation/screens/social_onboarding_screen.dart` | Update navigation targets (remove `/social/space/discover` refs) |

### Widgets Already Reusable (in `lib/features/social/presentation/widgets/`)
- `tribe_activity_feed.dart` — `TribeActivitySection`, `TribeActivityTile`
- `tribe_accountability_section.dart` — `TribeAccountabilitySection`
- `tribe_quests_section.dart` — `TribeQuestsSection`, `TribeChallengeMiniCard`

---

### Task 1: Extract Leaderboard Widget

**Files:**
- Create: `lib/features/social/presentation/widgets/tribe_leaderboard_widget.dart`
- Source (read-only): `lib/features/social/presentation/screens/tribe_board_tab.dart`

- [ ] **Step 1: Write the failing test**

Create `test/features/social/presentation/widgets/tribe_leaderboard_widget_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/features/social/presentation/widgets/tribe_leaderboard_widget.dart';

void main() {
  testWidgets('TribeLeaderboardSection renders time toggle', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: TribeLeaderboardSection()),
        ),
      ),
    );
    expect(find.text('Weekly'), findsOneWidget);
    expect(find.text('Monthly'), findsOneWidget);
    expect(find.text('All-time'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/social/presentation/widgets/tribe_leaderboard_widget_test.dart`
Expected: FAIL with "TribeLeaderboardSection not found"

- [ ] **Step 3: Create the extracted widget file**

Create `lib/features/social/presentation/widgets/tribe_leaderboard_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_loading_skeleton.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';

class TribeLeaderboardSection extends ConsumerStatefulWidget {
  const TribeLeaderboardSection({super.key});

  @override
  ConsumerState<TribeLeaderboardSection> createState() => _TribeLeaderboardSectionState();
}

class _TribeLeaderboardSectionState extends ConsumerState<TribeLeaderboardSection> {
  int _timeScope = 0;

  static const _timeLabels = ['Weekly', 'Monthly', 'All-time'];

  @override
  Widget build(BuildContext context) {
    final leaderboardAsync = ref.watch(worldLeaderboardProvider);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'LEADERBOARD',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            GestureDetector(
              onTap: () => context.push('/social/leaderboard'),
              child: const Text(
                'See full board →',
                style: TextStyle(color: EmergeColors.neonTeal, fontSize: 11),
              ),
            ),
          ],
        ),
        const Gap(8),
        SegmentedButton<int>(
          selected: {_timeScope},
          onSelectionChanged: (s) => setState(() => _timeScope = s.first),
          showSelectedIcon: false,
          style: SegmentedButton.styleFrom(
            selectedBackgroundColor: EmergeColors.neonTeal.withValues(alpha: 0.2),
            selectedForegroundColor: EmergeColors.neonTeal,
          ),
          segments: List.generate(
            _timeLabels.length,
            (i) => ButtonSegment(value: i, label: Text(_timeLabels[i], style: const TextStyle(fontSize: 11))),
          ),
        ),
        const Gap(12),
        leaderboardAsync.when(
          data: (entries) {
            if (entries.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text('No rankings yet', style: TextStyle(color: Colors.white38)),
                ),
              );
            }

            final display = entries.take(5).toList();
            final maxXp = display.first.stats.totalXp.toDouble().clamp(1.0, double.infinity);

            return Column(
              children: [
                ...display.asMap().entries.map((entry) {
                  final i = entry.key;
                  final e = entry.value;
                  final rank = i + 1;
                  final medalEmoji = rank == 1 ? '🥇' : rank == 2 ? '🥈' : rank == 3 ? '🥉' : null;
                  final barFraction = (e.stats.totalXp / maxXp).clamp(0.0, 1.0);
                  return _LeaderboardRow(
                    rank: rank,
                    medalEmoji: medalEmoji,
                    name: e.tribe.name,
                    xp: e.stats.totalXp,
                    barFraction: barFraction,
                    isTop3: rank <= 3,
                  );
                }),
                const _YouPinnedRow(),
              ],
            );
          },
          loading: () => const EmergeLoadingSkeleton(itemCount: 5),
          error: (e, _) => const Center(child: Text('Could not load leaderboard', style: TextStyle(color: Colors.white38))),
        ),
      ],
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final int rank;
  final String? medalEmoji;
  final String name;
  final int xp;
  final double barFraction;
  final bool isTop3;

  const _LeaderboardRow({
    required this.rank,
    required this.medalEmoji,
    required this.name,
    required this.xp,
    required this.barFraction,
    required this.isTop3,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isTop3
              ? EmergeColors.neonTeal.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: isTop3
              ? Border.all(color: EmergeColors.neonTeal.withValues(alpha: 0.2))
              : null,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 30,
              child: Text(
                medalEmoji ?? '#$rank',
                style: TextStyle(fontSize: isTop3 ? 20 : 12, color: Colors.white70, fontWeight: FontWeight.bold),
              ),
            ),
            const Gap(8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: TextStyle(color: Colors.white, fontWeight: isTop3 ? FontWeight.bold : FontWeight.normal, fontSize: 13), overflow: TextOverflow.ellipsis),
                  const Gap(4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: barFraction,
                      backgroundColor: Colors.white10,
                      color: isTop3 ? EmergeColors.neonTeal : Colors.white38,
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            ),
            const Gap(8),
            Text('${(xp / 1000).toStringAsFixed(1)}K XP', style: TextStyle(color: isTop3 ? EmergeColors.neonTeal : Colors.white54, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _YouPinnedRow extends StatelessWidget {
  const _YouPinnedRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          SizedBox(width: 30, child: Text('📍', style: TextStyle(fontSize: 16))),
          Gap(8),
          Expanded(child: Text('Your Tribe', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13))),
          Text('Check in to rank up 🔥', style: TextStyle(color: Colors.amber, fontSize: 11)),
        ],
      ),
    );
  }
}
```

Note: Add `import 'package:go_router/go_router.dart';` at the top.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/social/presentation/widgets/tribe_leaderboard_widget_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/social/presentation/widgets/tribe_leaderboard_widget.dart test/features/social/presentation/widgets/tribe_leaderboard_widget_test.dart
git commit -m "feat: extract TribeLeaderboardSection widget from tribe_board_tab"
```

---

### Task 2: Extract Discover Section Widget

**Files:**
- Create: `lib/features/social/presentation/widgets/tribe_discover_section.dart`
- Source (read-only): `lib/features/social/presentation/screens/social_discover_tab.dart`

- [ ] **Step 1: Write the failing test**

Create `test/features/social/presentation/widgets/tribe_discover_section_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/features/social/presentation/widgets/tribe_discover_section.dart';

void main() {
  testWidgets('TribeDiscoverSection renders header', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: TribeDiscoverSection()),
        ),
      ),
    );
    expect(find.text('DISCOVER'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/social/presentation/widgets/tribe_discover_section_test.dart`
Expected: FAIL with "TribeDiscoverSection not found"

- [ ] **Step 3: Create the extracted widget file**

Create `lib/features/social/presentation/widgets/tribe_discover_section.dart`:

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/core/presentation/widgets/skeleton_shimmer.dart';
import 'package:emerge_app/core/presentation/widgets/app_error_widget.dart';
import 'package:emerge_app/features/blueprints/domain/models/blueprint.dart';
import 'package:emerge_app/features/blueprints/data/repositories/blueprint_repository.dart';

const _displayedCategories = {'Morning', 'Productivity', 'Fitness', 'Mindfulness', 'Learning'};

class TribeDiscoverSection extends ConsumerWidget {
  const TribeDiscoverSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blueprintsAsync = ref.watch(allBlueprintsStreamProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'DISCOVER',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            GestureDetector(
              onTap: () => context.push('/social/space/discover'),
              child: Text(
                'Browse all →',
                style: TextStyle(color: EmergeColors.neonTeal, fontSize: 11),
              ),
            ),
          ],
        ),
        const Gap(12),
        blueprintsAsync.when(
          data: (blueprints) {
            final grouped = <String, List<Blueprint>>{};
            for (final bp in blueprints) {
              if (!_displayedCategories.contains(bp.category)) continue;
              grouped.putIfAbsent(bp.category, () => []).add(bp);
            }
            final categories = grouped.keys.toList()..sort();
            if (categories.isEmpty) {
              return const Center(child: Text('No blueprints yet', style: TextStyle(color: Colors.white38)));
            }
            return SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 4),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  return _DiscoverCategoryCard(
                    title: cat,
                    blueprints: grouped[cat]!,
                  );
                },
              ),
            );
          },
          loading: () => const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (err, _) => const SizedBox(height: 200, child: Center(child: Text('Could not load blueprints', style: TextStyle(color: Colors.white38)))),
        ),
      ],
    );
  }
}

class _DiscoverCategoryCard extends StatelessWidget {
  final String title;
  final List<Blueprint> blueprints;

  const _DiscoverCategoryCard({required this.title, required this.blueprints});

  @override
  Widget build(BuildContext context) {
    final bp = blueprints.first;
    return GestureDetector(
      onTap: () => context.push('/blueprint/${bp.id}', extra: bp),
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withValues(alpha: 0.06),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.white.withValues(alpha: 0.1), Colors.white.withValues(alpha: 0.03)],
                    ),
                  ),
                  child: Center(child: Text(title, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 28, fontWeight: FontWeight.bold))),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  const Gap(2),
                  Text('${blueprints.length} blueprints', style: const TextStyle(color: Colors.white38, fontSize: 11)),
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

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/social/presentation/widgets/tribe_discover_section_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/social/presentation/widgets/tribe_discover_section.dart test/features/social/presentation/widgets/tribe_discover_section_test.dart
git commit -m "feat: extract TribeDiscoverSection widget from social_discover_tab"
```

---

### Task 3: Remove Tribe Space Routes from Router

**Files:**
- Modify: `lib/core/router/router.dart`
- Delete: `lib/features/social/presentation/screens/tribe_space_scaffold.dart`
- Delete: `lib/features/social/presentation/screens/tribe_feed_tab.dart`
- Delete: `lib/features/social/presentation/screens/tribe_board_tab.dart`
- Delete: `lib/features/social/presentation/screens/my_tribe_tab.dart`
- Delete: `lib/features/social/presentation/screens/social_discover_tab.dart`

- [ ] **Step 1: Remove imports and routes for tribe space**

In `lib/core/router/router.dart`:

Remove these imports (lines 44-50):
```dart
import 'package:emerge_app/features/social/presentation/screens/tribe_space_scaffold.dart';
import 'package:emerge_app/features/social/presentation/screens/tribe_feed_tab.dart';
import 'package:emerge_app/features/social/presentation/screens/my_tribe_tab.dart';
import 'package:emerge_app/features/social/presentation/screens/tribe_board_tab.dart';
import 'package:emerge_app/features/social/presentation/screens/social_discover_tab.dart';
```

Remove the entire `StatefulShellRoute.indexedStack` block for tribe space (router.dart lines 342-410), including:
- `StatefulShellRoute.indexedStack` with `TribeSpaceScaffold`
- All 4 branches (space, space/my-tribe, space/board, space/discover)
- The `/social/space/discover/creator/:id` sub-route

Keep the `/social/onboarding`, `/social/challenges`, `/social/challenge/:id`, `/social/accountability`, `/social/contracts`, `/social/leaderboard`, `/social/all`, `/social/creator/:id` routes.

Also update the `SocialScreen` import if it's still needed at line 36. Keep the `SocialScreen` import since it's used by the `/social/challenges` route.

- [ ] **Step 2: Update navigation calls in the lobby**

The "ENTER TRIBE SPACE" button currently does `context.push('/social/space')`. This needs to be removed (the button itself will be replaced in Task 4, but ensure no stale route references remain).

Update the "Creators" button redirect from `/social/space/discover` to just `/social/discover` or remove it (the discover section is embedded in the lobby now).

Since we no longer have a `/social/space/discover` route, change the navigation calls in the lobby. For now the discover section is embedded in the lobby, so explore cards will be removed in Task 4.

- [ ] **Step 3: Delete the tab screen files**

```bash
git rm lib/features/social/presentation/screens/tribe_space_scaffold.dart
git rm lib/features/social/presentation/screens/tribe_feed_tab.dart
git rm lib/features/social/presentation/screens/tribe_board_tab.dart
git rm lib/features/social/presentation/screens/my_tribe_tab.dart
git rm lib/features/social/presentation/screens/social_discover_tab.dart
```

- [ ] **Step 4: Run analyzer to verify no broken imports**

Run: `dart analyze lib/core/router/router.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/core/router/router.dart
git commit -m "refactor: remove tribe space routes and delete 4-tab screens"
```

---

### Task 4: Expand Tribe Lobby Screen with All Sections

**Files:**
- Modify: `lib/features/social/presentation/screens/tribe_lobby_screen.dart`

This is the core task. The lobby screen gets expanded from its current state to include all sections as scrollable sliver sections, in this order:
1. Header + stats card (keep existing)
2. Activity Feed section (new - uses `TribeActivitySection`)
3. Leaderboard section (new - uses `TribeLeaderboardSection`)
4. Challenges section (new - uses `TribeQuestsSection`)
5. Discover section (new - uses `TribeDiscoverSection`)
6. Global stats + Switch/Creators buttons (keep existing)

- [ ] **Step 1: Write the failing test**

Create `test/features/social/presentation/screens/tribe_lobby_screen_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/features/social/presentation/screens/tribe_lobby_screen.dart';

void main() {
  testWidgets('TribeLobbyScreen renders your tribe header', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: TribeLobbyScreen(),
        ),
      ),
    );
    expect(find.text('YOUR TRIBE'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/social/presentation/screens/tribe_lobby_screen_test.dart`
Expected: FAIL (or passes as-is since the screen already exists - the test will validate the header renders)

- [ ] **Step 3: Expand the lobby screen**

Modify `lib/features/social/presentation/screens/tribe_lobby_screen.dart`:

Add imports:
```dart
import 'package:emerge_app/features/social/presentation/widgets/tribe_activity_feed.dart';
import 'package:emerge_app/features/social/presentation/widgets/tribe_leaderboard_widget.dart';
import 'package:emerge_app/features/social/presentation/widgets/tribe_discover_section.dart';
import 'package:emerge_app/features/social/presentation/widgets/tribe_quests_section.dart';
```

Replace the existing `CustomScrollView` slivers (from line 84 onwards) with the expanded version. The new sliver list should be:

1. **Header** (keep existing - lines 86-149)
2. **Stats card** (keep existing - lines 151-254, but REPLACE the "ENTER TRIBE SPACE" button with a section label)
3. **Live Activity Ticker** (keep existing - lines 256-318)
4. **FEED section** (NEW - replaces old explore)

```dart
// ── FEED Section ────────────────────────────────────
SliverToBoxAdapter(
  child: Padding(
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('FEED', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2)),
        GestureDetector(
          onTap: () => context.push('/social/leaderboard'),
          child: Text('View all →', style: TextStyle(color: EmergeColors.neonTeal, fontSize: 11)),
        ),
      ],
    ),
  ),
),
SliverToBoxAdapter(
  child: Padding(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
    child: SizedBox(
      height: 300,
      child: TribeActivitySection(clubId: userClub.id, isGlobal: false),
    ),
  ),
),
```

5. **LEADERBOARD section** (NEW)

```dart
// ── LEADERBOARD Section ─────────────────────────────
SliverToBoxAdapter(
  child: Padding(
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
    child: TribeLeaderboardSection(),
  ),
),
```

6. **CHALLENGES section** (NEW)

```dart
// ── CHALLENGES Section ──────────────────────────────
SliverToBoxAdapter(
  child: Padding(
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('CHALLENGES', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2)),
            GestureDetector(
              onTap: () => context.push('/social/challenges'),
              child: Text('View all →', style: TextStyle(color: EmergeColors.neonTeal, fontSize: 11)),
            ),
          ],
        ),
        const Gap(12),
        const TribeQuestsSection(),
      ],
    ),
  ),
),
```

7. **DISCOVER section** (NEW)

```dart
// ── DISCOVER Section ────────────────────────────────
SliverToBoxAdapter(
  child: Padding(
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
    child: TribeDiscoverSection(),
  ),
),
```

8. **Global Stats** (keep existing - lines 373-419)
9. **Switch Tribe / Browse Creators** (keep existing - lines 422-467)

Remove the old EXPLORE header and 3 explore cards (old lines 320-369).

The complete expanded lobby structure:
```
CustomScrollView
├── Header (tribe name + emblem)
├── Stats Card (members, streak, collective quest)
├── Live Ticker
├── FEED section (TribeActivitySection)
├── LEADERBOARD section (TribeLeaderboardSection)
├── CHALLENGES section (TribeQuestsSection)
├── DISCOVER section (TribeDiscoverSection)
├── Global Stats
├── Switch Tribe / Browse Creators
```

- [ ] **Step 4: Run the test**

Run: `flutter test test/features/social/presentation/screens/tribe_lobby_screen_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/social/presentation/screens/tribe_lobby_screen.dart test/features/social/presentation/screens/tribe_lobby_screen_test.dart
git commit -m "feat: expand tribe lobby with feed, leaderboard, challenges, discover sections"
```

---

### Task 5: Update Social Onboarding Navigation

**Files:**
- Modify: `lib/features/social/presentation/screens/social_onboarding_screen.dart`

- [ ] **Step 1: Check current navigation targets**

The onboarding screen currently navigates to `/social` and `/social/space/discover`. Since we removed `/social/space/discover`, the "Browse Creators" option should navigate to `/social/discover` instead. Since we no longer have a full discover route (it's embedded in the lobby), the "Browse Creators" can simply navigate to `/social` (the lobby, where discover is embedded) or we can keep a `/social/discover` route as a full-screen discover page.

- [ ] **Step 2: Update navigation targets**

In `social_onboarding_screen.dart`, change any `context.push('/social/space/discover')` navigation to either:
- `context.push('/social')` — goes to lobby where discover is embedded
- Or `context.push('/social/discover')` — if we want to add a full-screen discover route

- [ ] **Step 3: Commit**

```bash
git add lib/features/social/presentation/screens/social_onboarding_screen.dart
git commit -m "fix: update onboarding navigation after removing tribe space"
```

---

### Task 6: Clean Up and Verify

- [ ] **Step 1: Run full analyzer**

```bash
dart analyze lib/
```

Expected: No errors. If there are import errors from deleted files, fix them by updating imports in the remaining files.

- [ ] **Step 2: Run existing tests**

```bash
flutter test
```

Expected: No regressions.

- [ ] **Step 3: Run the new tests specifically**

```bash
flutter test test/features/social/
```

Expected: All new test files pass.

- [ ] **Step 4: Commit any remaining fixes**

```bash
git add -A
git commit -m "chore: fix imports and clean up after social hub redesign"
```

---

## Self-Review Checklist

1. **Spec coverage:**
   - Social Onboarding gate → Kept in `social_onboarding_screen.dart`
   - Tribe Lobby as central hub → Expanded in `tribe_lobby_screen.dart`
   - Feed embedded in lobby → `TribeActivitySection` added as sliver
   - Leaderboard embedded in lobby → New `TribeLeaderboardSection` widget
   - Challenges embedded in lobby → Existing `TribeQuestsSection` reused
   - Discover embedded in lobby → New `TribeDiscoverSection` widget
   - Tribe Space 4-tab system removed → All 5 files deleted, routes removed
   - Portal transition removed → No longer needed

2. **Placeholder scan:** All steps contain actual code — no TODOs or TBDs.

3. **Type consistency:** `TribeLeaderboardSection`, `TribeDiscoverSection` names are consistent across widget files, tests, and the lobby screen.