# Spec: Habit Forge and Tribe Tabs Reorganization

## Goal Description
Reorganize the primary application navigation to replace the direct "Identity" (Profile) bottom tab with a new root-level **Habit Forge** (formerly Discover / blueprints & templates library) section. Reorder the primary tabs to flow as `World` | `Habits` | `[FAB]` | `Habit Forge` | `Tribe`. Remove page title labels from the top of these main screens and replace them with a unified **RPG Status HUD Top Bar** that displays the user's level, journey biome, XP progress, and a direct Profile action button. Reorganize the "Tribe" section into a sub-tab layout (Sanctum, Quests, Members, Bonds) to reduce scrolling and provide structured group progress monitoring.

## Proposed Changes

### Core UI Components

#### [NEW] [emerge_status_hud_top_bar.dart](file:///c:/Users/HP/Downloads/emerge_app/lib/core/presentation/widgets/emerge_status_hud_top_bar.dart)
Create a unified, reusable HUD header widget to replace the individual page titles.
*   **Layout**: Left-aligned journey icon and title ("THE ATHLETE'S APEX" or matching the user's archetype). Right-aligned user level badge (e.g., "LVL 12") and a profile circle avatar button that pushes to `/profile`.
*   **XP Progress Bar**: A thin linear progress indicator showing the user's fractional progress toward the next level (total XP % 500 / 500).
*   **Glassmorphic Design**: 60% opacity dark background with 12px backdrop blur and a 15% opacity neon accent border outline matching the user's active archetype.
*   **No Static Title**: The screen name is omitted entirely since the active bottom nav item communicates the context.

---

### Navigation & Routing

#### [MODIFY] [router.dart](file:///c:/Users/HP/Downloads/emerge_app/lib/core/router/router.dart)
Reorder the `StatefulShellRoute.indexedStack` branches:
*   **Branch 0**: `/` (`WorldMapScreen`)
*   **Branch 1**: `/timeline` (`TimelineScreen`)
*   **Branch 2**: `/discover` (New route serving the **Habit Forge** view, mapped to `SocialDiscoverTab`).
*   **Branch 3**: `/tribes` (Serving the consolidated `SocialScreen` tab controller).
*   *Note*: `/profile` is removed from the bottom shell branches and remains as a standalone root route (pushed from the HUD app bar).

#### [MODIFY] [emerge_bottom_nav.dart](file:///c:/Users/HP/Downloads/emerge_app/lib/core/presentation/widgets/emerge_bottom_nav.dart)
*   Update bottom nav items right of the center diamond FAB:
    *   Item 2: **Habit Forge** (Icon: `Icons.explore_outlined`, Label: 'Forge').
    *   Item 3: **Tribe** (Icon: `Icons.groups`, Label: 'Tribe').
*   Ensure state indexes are aligned with the new router branch order (0 = World, 1 = Habits, 2 = Habit Forge, 3 = Tribe).

---

### Screen Reorganizations

#### [MODIFY] [social_screen.dart](file:///c:/Users/HP/Downloads/emerge_app/lib/features/social/presentation/screens/social_screen.dart)
*   Remove the `IconButton(icon: Icons.person_outline)` action and other redundant profile controls from the header.
*   Use the new `EmergeStatusHudTopBar` as a sliver header.
*   Reduce the main `TabBar` to two items:
    1.  **Tribe** (renders the tabbed `TribeTabContent`).
    2.  **Challenges** (renders `ChallengesScreen(showAppBar: false)`).
*   Update `TabController` length to 2.

#### [MODIFY] [timeline_screen.dart](file:///c:/Users/HP/Downloads/emerge_app/lib/features/timeline/presentation/screens/timeline_screen.dart)
*   Replace `ArchetypeSliverAppBar` with the new unified `EmergeStatusHudTopBar`.
*   Verify that any archetype-specific layout logic works natively.

#### [MODIFY] [tribe_tab_content.dart](file:///c:/Users/HP/Downloads/emerge_app/lib/features/social/presentation/screens/tribe_tab_content.dart)
Refactor the single scrollable list into a clean sub-tabbed view:
*   **Sub-Tab Bar**: Glassmorphic capsule chip bar showing tabs: `Sanctum` | `Quests` | `Members` | `Bonds`.
*   **Tab Contents**:
    *   **Sanctum**: Showcases the Club Emblem, Member Count, daily momentum metrics, and live logs activity feed.
    *   **Quests**: Displays active collective quests (e.g., Step Marathon) and past archived victories.
    *   **Members**: Displays top contributors and search/roster listing.
    *   **Bonds**: Displays accountability partners and active habit contracts.

---

## Verification Plan

### Automated Tests
*   Run the test suites in `test/features/social/` to ensure no breaks.
    *   `flutter test test/features/social/presentation/providers/tribe_stats_cache_test.dart`
*   Verify app builds cleanly with no router path errors:
    *   `flutter analyze`

### Manual Verification
*   Verify bottom navigation tab switching works correctly (World -> Habits -> Habit Forge -> Tribe).
*   Click the Profile avatar button in the HUD Top Bar on each screen and confirm it opens the "Future Self Studio" (`/profile`) correctly.
*   Select the Tribes tab and toggle between Sanctum, Quests, Members, and Bonds sub-tabs to ensure smooth transitions without layout overflow.
