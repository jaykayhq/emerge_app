# Reusable Feature Coach Marks & Habit Rune Indicator

Design specification for implementing a unified, reusable coach-mark overlay system across all key feature screens, and adding a subtle, dynamic "Rune & Socket" hint to habit cards to signal the availability of detailed habit settings.

## User Review Required

> [!NOTE]
> The Coach Mark system will be implemented using a new generic, reusable overlay widget (`FeatureCoachMark`) located in `lib/core/presentation/widgets/feature_coach_mark.dart`. This aligns with Option A and avoids duplicating UI code across the codebase.
> 
> The "Rune & Socket" indicator will be placed on all habit list items in the daily Timeline. When a habit has custom modifiers configured (such as a Two-Minute Version, Temptation Bundling, Environment Priming, or Screen Time/Step Limits), the rune is "Awakened" (illuminated with its attribute color). Otherwise, it remains a "Dormant" (dashed, pulsing outline).

## Open Questions

*None currently.* The user has selected the recommended shared widget structure (Option A) and approved the recommended visual styles for the coach marks and the "Rune & Socket" indicator.

---

## Proposed Changes

### Core Shared Presentation Component

#### [NEW] [feature_coach_mark.dart](file:///c:/Users/JOSHUA/Downloads/emerge_app/lib/core/presentation/widgets/feature_coach_mark.dart)
A highly customizable, dismissible full-screen overlay widget matching the styling of `_WorldMapCoachMark`.
- **Properties**:
  - `title`: The title of the guide.
  - `primaryColor`: Accent color for indicators, borders, and buttons.
  - `items`: A list of `CoachItemData` (icon, title, body).
  - `onDismiss`: Callback executed when the modal is dismissed.
- **Visuals**: Transparent black background, card with glassmorphism border and glow, list of key feature benefits, and a call-to-action button ("GOT IT — LET'S GO").

---

### Timeline & Habit Features

#### [NEW] [habit_rune_indicator.dart](file:///c:/Users/JOSHUA/Downloads/emerge_app/lib/features/timeline/presentation/widgets/habit_rune_indicator.dart)
A stateful widget displaying a small pulsing attribute orb next to the attribute badge on each habit card.
- **Behavior**:
  - Checks if the habit has any advanced details (`twoMinuteVersion` not empty, `reward` not empty, `environmentPriming` not empty, `integrationType != none`, or `anchorHabitId != null`).
  - **Dormant**: Dashed/dotted outline with lower opacity pulsing slowly (breathing animation).
  - **Awakened**: Fully filled, glowing neon orb matching the attribute's color.

#### [MODIFY] [habit_timeline_section.dart](file:///c:/Users/JOSHUA/Downloads/emerge_app/lib/features/timeline/presentation/widgets/habit_timeline_section.dart)
- Add `HabitRuneIndicator` next to the attribute badge (e.g., inside the attribute indicator container or immediately preceding it).
- Ensure the layout is responsive and hit targets remain >= 48px.

#### [MODIFY] [timeline_screen.dart](file:///c:/Users/JOSHUA/Downloads/emerge_app/lib/features/timeline/presentation/screens/timeline_screen.dart)
- Integrate `FeatureCoachMark` overlay inside a `Stack` wrapping the main layout.
- Check `!repo.hasVisited('/timeline')` in `initState` to show the coach mark.
- Call `repo.markVisited('/timeline')` and trigger first-visit companion event upon dismissal.

#### [MODIFY] [habit_detail_screen.dart](file:///c:/Users/JOSHUA/Downloads/emerge_app/lib/features/habits/presentation/screens/habit_detail_screen.dart)
- Ensure the screen uses `WorldBackground` and correctly displays/updates advanced details (streaks, timer, rewards) so they are reflected in the Rune state immediately.

---

### Other Feature Screens (Adding Coach Marks)

For each of the following files:
1. Check `!repo.hasVisited(route)` in `initState`.
2. Wrap the top-level layout in a `Stack`.
3. Render `FeatureCoachMark` as the top-most layer when `_showFirstVisitGuide` is true.
4. On dismiss, call `repo.markVisited(route)` and trigger the companion `firstFeatureVisit` event.

#### [MODIFY] [ai_reflections_screen.dart](file:///c:/Users/JOSHUA/Downloads/emerge_app/lib/features/ai/presentation/screens/ai_reflections_screen.dart)
- Route: `/profile/reflections`
- Coach Mark content: Focus on how AI Reflections analyze daily mood log entries and habit completions to output tailored guidance.

#### [MODIFY] [leveling_screen.dart](file:///c:/Users/JOSHUA/Downloads/emerge_app/lib/features/gamification/presentation/screens/leveling_screen.dart)
- Route: `/gamification`
- Coach Mark content: Explain XP multipliers, leveling tiers, and archetype-specific progression rewards.

#### [MODIFY] [advanced_create_habit_dialog.dart](file:///c:/Users/JOSHUA/Downloads/emerge_app/lib/features/habits/presentation/screens/advanced_create_habit_dialog.dart)
- Route: `/habits/create`
- Coach Mark content: Guide the user in setting up cues, routines, 2-minute limits, and rewards to lock in a new habit loop.

#### [MODIFY] [future_self_studio_screen.dart](file:///c:/Users/JOSHUA/Downloads/emerge_app/lib/features/profile/presentation/screens/future_self_studio_screen.dart)
- Route: `/profile/future-self`
- Coach Mark content: Orient the user on defining their ultimate archetype avatar and allocating attribute stats.

#### [MODIFY] [challenges_screen.dart](file:///c:/Users/JOSHUA/Downloads/emerge_app/lib/features/social/presentation/screens/challenges_screen.dart)
- Route: `/challenges`
- Coach Mark content: Explain tribal and personal challenges, target habits, and leaderboard scoring.

#### [MODIFY] [social_discover_tab.dart](file:///c:/Users/JOSHUA/Downloads/emerge_app/lib/features/social/presentation/screens/social_discover_tab.dart)
- Route: `/discover`
- Coach Mark content: Guide on discovering new user tribes, filtering by archetype, and viewing community milestones.

#### [MODIFY] [tribe_tab_content.dart](file:///c:/Users/JOSHUA/Downloads/emerge_app/lib/features/social/presentation/screens/tribe_tab_content.dart)
- Route: `/tribes`
- Coach Mark content: Highlight member chats, joint momentum scores, and tribe-level challenges.

#### [MODIFY] [level_immersive_screen.dart](file:///c:/Users/JOSHUA/Downloads/emerge_app/lib/features/world_map/presentation/screens/level_immersive_screen.dart)
- Route: `/world-map/immersive`
- Coach Mark content: Instruct the user on tapping node-specific quests and activating procedural world visuals.

---

## Verification Plan

### Automated Tests
- Run `flutter test` to ensure there are no compilation errors or broken widget layout assertions.
- Add unit/widget tests for the `HabitRuneIndicator` to verify it transitions between dormant and active states depending on habit configurations.

### Manual Verification
- Clear app local storage or reset `companion_visited_` keys in shared preferences.
- Launch the app and visit each screen one by one to verify that:
  - The coach mark slides/fades in beautifully.
  - The content is readable, accessible, and correctly themed to the screen's primary color.
  - Dismissing the guide correctly persists in local storage, and the screen returns to normal function.
- Create a new habit and confirm it displays with a **Dormant Rune**.
- Tap the card to enter the detail screen, set a 2-minute version/reward, save, and return to the timeline. Confirm the Rune is now **Awakened/Glowing**.
