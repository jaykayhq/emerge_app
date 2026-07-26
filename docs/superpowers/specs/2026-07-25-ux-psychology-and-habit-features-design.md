# Emerge App — UX Psychology Fixes & Habit Feature Redesign

**Date:** 2026-07-25  
**Status:** Draft  
**Applies to:** emerge_app (Flutter)

---

## Overview

This spec covers 8 independent work plans addressing UX psychology violations found in the codebase audit, plus the redesign of habit creation, a new habit activity screen, an undo button on completed habit cards, and a psychology-driven freemium model redesign.

Each plan is independently implementable and testable.

**Git update (2026-07-25):** Pulled origin/main. Plan 1e is already implemented (Pulse Feed empty state now has animated `_PulseRing` + 3 action buttons). Router's social onboarding redirect was removed — simplifies Plan 5g.

---

## Plan 1: State Pattern Violations

**Principles:** Loading state UX (§5.2), Error UX (§5.4, §15.2), Three-State Contract (§5.1), Empty States (§5.3)

### 1a. Replace CircularProgressIndicator with EmergeLoadingSkeleton

| File | Line | Current | Replace With |
|------|------|---------|--------------|
| `timeline_screen.dart` | 190-193 | `Center(child: CircularProgressIndicator(...))` | `EmergeLoadingSkeleton(itemCount: 3)` matching habit card shape |
| `world_map_screen.dart` | 70 | `Center(child: CircularProgressIndicator())` | `EmergeLoadingSkeleton(itemCount: 1, itemHeight: 300)` |

### 1b. Fix error states with technical jargon

| File | Line | Current | Replace With |
|------|------|---------|--------------|
| `timeline_screen.dart` | 460 | `e.toString()` displayed to user | User-friendly per §15.2: "Couldn't load habits. Check your connection and try again." |
| `future_self_studio_screen.dart` | 562 | `Text('Error: $e')` — no retry, no icon | `AppErrorWidget(message: "Couldn't load profile", onRetry: ...)` |

### 1c. Fix silent swallowing of loading/error states

| File | Line | Current | Replace With |
|------|------|---------|--------------|
| `future_self_studio_screen.dart` | 730-734 | `loading: () => SizedBox.shrink()` / `error: (_, _) => SizedBox.shrink()` | `EmergeLoadingSkeleton(itemCount: 1)` for loading, `AppErrorWidget` for error |

### 1d. Fix retroactively-empty timeline

When `habits.isEmpty`, show only the empty state (no calendar, recap, or header UI). The full dashboard skeleton should not render when there's no data.

### 1e. Add CTA to Pulse Feed empty state ⚠️ ALREADY DONE IN LATEST PULL

Pulse Feed empty state now has:
- Animated `_PulseRing` with expanding ring circles
- "Your Pulse is just getting started" headline
- 3 action buttons: Complete a habit, Explore tribes, Invite friends

No work needed. Verified in `pulse_feed_screen.dart` lines 108-270.

---

## Plan 2: Goal Gradient + Zeigarnik Effect

**Principles:** Goal Gradient Effect, Zeigarnik Effect, Law of Least Effort

### 2a. FAB completion ring

- Stack a `CircularProgressIndicator` overlay on the "Log Habit" FAB showing today's completion fraction
- Ring color: green at ≥80%, amber at 50-79%, coral below 50%
- Uses `Stack` + `SizedBox` wrapping the existing FAB

### 2b. Bottom nav badge for incomplete habits

- Badge on Timeline tab icon showing count of incomplete habits for today
- Only visible when count > 0
- Pulses subtly if < 2 hours of daylight remaining

### 2c. Momentum indicator in app bar

- Small momentum dot/ring in `ArchetypeSliverAppBar`
- Uses existing momentum data from dashboard state

### Files: `timeline_screen.dart`, `emerge_bottom_nav.dart` / `scaffold_with_nav_bar.dart`, `archetype_sliver_app_bar.dart`, `dashboard_state_provider.dart`

---

## Plan 3: Peak-End Rule + Social Proof

**Principles:** Peak-End Rule, Social Proof, Sunk Cost Fallacy, Endowment Effect

### 3a. All-done celebration

When the last habit for today is completed:
- Gentle full-screen glow pulse (300ms)
- Haptic heavy impact
- Narrator one-liner: "All done. Your future self thanks you."
- Glow fades over 1s

### 3b. Move ad banner

`AdBannerWidget` moves from between habit list and Narrator to below the Narrator summary card.

### 3c. Tribal presence strip

- Compact 1-line pill above habit list: "🏟️ Tribe: 3 members done morning habits so far"
- Data from tribe stats service
- Only shown for users in a tribe
- Tapping navigates to Pulse Feed

### 3d. Miss Recovery Sheet with quick action

- Add streak-at-stake visualization (fading streak number)
- "Complete Now" button per missed habit — completes without leaving sheet
- If habit has a `twoMinuteVersion`, show it as the suggested action

### Files: `timeline_screen.dart`, `completion_celebration.dart`, `narrator_providers.dart`, `miss_recovery_sheet.dart`, `tribe_stats_service.dart`

---

## Plan 4: Anchoring + Defaults + Loss Aversion

**Principles:** Anchoring, Default Effect, Loss Aversion, Endowment Effect, Law of Least Effort

### 4a. Smart defaults in habit creation

Pre-fill based on existing habits and archetype:
- **Time**: most common time slot among user's habits; archetype default if none
- **Attribute**: archetype's primary attribute
- **Difficulty**: Easy if <3 active habits, Medium otherwise
- **Timer**: 5 min default, median of existing if available

### 4b. EMERGE button reframing

Locked state shows: preview of ceremony, progress ("Level 3/5"), descriptive text of what unlocks.

### 4c. Typeahead sort order

Suggestions sorted by: habits user has created before → archetype+interest match → curated fallback.

### Files: `habit_create_screen.dart` (new), `future_self_studio_screen.dart`, `miss_recovery_sheet.dart`

---

## Plan 5: Onboarding Housekeeping + Endowment + Club Redesign + Tribes Discovery

**Principles:** Endowment Effect, Goal Gradient, Jakob's Law, Tesler's Law, Law of Least Effort

### 5a. Remove motive step

Delete the second page of `IdentityStudioScreen` (motive selection). Identity studio becomes single-screen archetype carousel only. Delete `_buildMotiveSelection()`, `_buildMotiveCard()`, `_customMotiveController`, `_selectedMotive`, `_isCustomMotive`, `_stepController` (2-page controller no longer needed).

### 5b. Compact color-coded interest grid

- Single flat grid — no category section headers
- Each chip colored by category: Mind & Body (green), Creative (purple), Social (blue), Career (amber), Lifestyle (coral), Learning (teal)
- Smaller chip padding: 8px vertical, 14px horizontal (down from 12px/16px)
- Category indicated by a colored dot or left border on each chip

### 5c. Goal progress bar

Replace "STEP X OF 5" text with a horizontal goal progress bar across all onboarding screens:

| Milestone | Progress |
|-----------|----------|
| After sign-up (endowment interstitial seen) | 20% |
| Archetype selected | 40% |
| Interests picked | 60% |
| Club joined or skipped | 80% (joined) / 60% (skipped, advances on next step) |
| Starter pack + world revealed | 100% |

Text below bar changes per step:
- 20%: "You've begun. Now define yourself."
- 40%: "Your archetype is set. What shapes you?"
- 60%: "Good. Your interests give texture."
- 80%: "Almost forged. Choose your company."
- 100%: "Ready to emerge."

### 5d. Endowment interstitial after sign-up

New screen shown once after sign-up, before onboarding flow begins:

```
┌─────────────────────────────┐
│     ✨ Welcome, [Name]      │
│                             │
│     Your world seed is      │
│     planted. Here's what    │
│     you already have:       │
│                             │
│     🎁 Starter habit pack   │
│         reserved for you    │
│     🏟️ Archetype tribe      │
│         waiting for you     │
│     🌍 Your world map       │
│         ready to grow       │
│                             │
│     [BEGIN FORGING →]       │
└─────────────────────────────┘
```

Tracked via SharedPreferences flag to show only once.

### 5e. World reveal escape hatch

Add "Skip" text button in top-right and back arrow in top-left of `WorldRevealScreen`. Skip jumps directly to "Enter Your World" button state.

### 5f. Club screen redesign

**Card layout — box card with image + micro-info:**

```
┌─────────────┐
│  [club      │  ← gradient/emblem image (top ~60%)
│   emblem]   │
├─────────────┤
│  ATHLETE    │  ← title, bold, one line
│  ARENA      │
│             │
│  342 🏃🔥   │  ← micro-info: member count + activity status
│             │
│  [TAP FOR   │  ← subtle CTA
│   DETAILS]  │
└─────────────┘
```

**Layout:**
- 3-column grid on phones, 4-column on tablets
- Initially shows 6 clubs. "See more clubs →" expands to ~15.
- Club pool: archetype-matched clubs first, then popular clubs

**Tap to preview:** Bottom sheet with full description, benefits, [JOIN] button.

**Skippable:** "Skip" link in header (reuse pattern from `FirstHabitsScreen`). User advances without joining.

**Progress bar:** 60% at this step (from interests). Advances to 80% when joined, or stays at 60% if skipped (catches up on next step).

### 5g. Tribes tab: empty state + club discovery

**When user has no club** (skipped onboarding or left tribe):
- Replace the 4-tab club view with a discovery view
- Search bar: "🔍 Search clubs..."
- Filter chips: "All" / "By Archetype" / "Creator"
- Grid of club cards (same box card design as 5f) mixing creator + archetype clubs
- Tapping a club opens a preview sheet with [JOIN] button
- After joining, view re-fetches and switches to the 4-tab club view

**When user has a club:**
- Current 4-tab layout (Sanctum, Quests, Members, Bonds) stays unchanged
- "SEE ALL TRIBES" button navigates to the new discovery view

**Data source:** Merged from `archetypeClubsProvider` + `creatorClubsProvider`. Search filters by club name/description.

---

## Plan 6: Card Polish + Recap Redesign

**Principles:** Law of Least Effort, Von Restorff Effect, Peak-End Rule

### 6a. Reduce habit card sizing

- Card padding: 12px → 8px vertical, 10px horizontal
- Title font: 14px → 13px
- XP badge: 12px → 11px
- Category circle: 12dp → 10dp
- Card spacing: 8px → 4px
- Connector line: 2px → 1.5px

### 6b. Reposition ad banner

Move `AdBannerWidget` from between habit list and Narrator summary to below Narrator summary card.

### 6c. Card contrast

- Completed cards: background +5% darker tint than pending
- First incomplete "next" habit: subtle green glow border (`#2BEE79` at 20% opacity)

### 6d. Recap card redesign

Replace current stats row with **Momentum Arc + Streak Flame** combined card:

- **Left:** Circular progress arc (40×40dp) showing today's completion fraction
  - Green at ≥50%, amber at 25-50%, coral below 25%
  - Percentage number centered inside
- **Right:** Streak flame icon + number + "day streak" label
  - Flame larger for streaks ≥7, pulsing for ≥21
- **Narrative line below:** dynamic based on state:
  - All done: "All done today! You're in the top 10% of your tribe."
  - ≥50%: "You're ahead of [X]% of your tribe today."
  - <50%: "Every habit counts — you're at [X]%."
  - No data: "Your day hasn't started yet."
- Card padding: `horizontal: 16, vertical: 12` (reduced from current 20/16)
- Tap → navigates to `/world-map/recap`

---

## Plan 7: Habit Create Screen + Activity Screen + Undo Button

**Principles:** Law of Least Effort, Anchoring, Default Effect, IKEA Effect, Zeigarnik Effect, Peak-End Rule

### 7a. Habit Create Screen

**Route:** `/timeline/create-habit` (full-screen, replaces dialog)

**Layout (top to bottom):**

1. **App bar:** "← CREATE HABIT [X]"
2. **Emoji picker row:** Horizontal row of 5 recently-used emojis + "+" button. Tapping "+" opens full emoji grid sheet (18 emojis: 🔥💧🌿📖💪🧠✨🎯🏃💤🍎🧘🎸🎨💼🏡🔋🚀).
3. **Identity sentence:** Static prefix "I am the type of person who" with 4 tappable pill segments below:
   - `[action ►]` — focuses title text field
   - `[at 7am ►]` — opens time picker
   - `[in the living room ►]` — focuses location text field
   - `[daily ►]` — opens frequency picker
4. **Attribute badge:** `🔥 VITALITY` — tappable, opens attribute picker
5. **Typeahead suggestions:** When field empty → curated grid (2 columns). As user types → inline dropdown filtered by match. Selecting fills title + configures defaults.
6. **Basics section (always visible):** Time, Location, Frequency fields
7. **Advanced section (collapsible):** 2-minute version, timer duration, difficulty, health integration
8. **CTA:** "[FORGE HABIT →]" green button at bottom

**Smart defaults:** Match Plan 4a.

### 7b. Habit Activity Screen

**Route:** `/timeline/habit/:habitId`

**Layout (top to bottom):**

1. **App bar:** "← [habit title] [✎]" — edit button opens create screen in edit mode
2. **Identity card:** Read-only display of the "I am the type of person who..." statement, the user's original declaration
3. **Activity section:**
   - **Heatmap:** GitHub-style 90-day contribution grid. 7 rows (days of week), ~13 columns (weeks). Each cell 10×10dp. Color scale: dark gray (missed) → light green → bright green (streak). Tap cell for tooltip.
   - **Stats:** Momentum bar, current streak, best streak, total completions
4. **Log section:**
   - Text field: "Write a reflection..." + [SAVE] button
   - Past reflection entries listed chronologically

### 7c. Undo Button

**Completed card** gets an undo icon after the XP badge:

```
✓ Meditate for 5 min    +10 XP  ↺
```

- Undo icon: `Icons.undo`, 18dp, opacity 0.6
- Tapping calls `onCheckboxTap` / `onHabitToggle` to revert completion
- Existing snackbar undo (for immediate accidental complete) also remains

### Files

| File | Action |
|------|--------|
| `features/habits/presentation/screens/habit_create_screen.dart` | **New** |
| `features/habits/presentation/screens/habit_activity_screen.dart` | **New** |
| `features/habits/presentation/providers/habit_activity_provider.dart` | **New** |
| `features/habits/presentation/widgets/habit_heatmap.dart` | **New** |
| `features/habits/presentation/widgets/emoji_picker_row.dart` | **New** |
| `features/timeline/presentation/widgets/habit_timeline_section.dart` | **Modify** |
| `features/habits/presentation/screens/advanced_create_habit_dialog.dart` | **Delete** |
| `core/router/router.dart` | **Modify** |

---

## Plan 8: Psychology-Driven Freemium Model + Paywall Redesign

**Principles:** Scarcity, Curiosity Gap, Hyperbolic Discounting, Contrast Effect, Framing Effect, Von Restorff Effect, Social Proof, Loss Aversion

**SCOPE NOTE:** Narrator AI coaching gating and baby-face narrator avatar are out of scope. Handled separately.

### 8a. Psychology-to-Feature Gating Map

| Principle | Free Tier | Premium Tier | Trigger at Paywall |
|-----------|-----------|-------------|-------------------|
| **Scarcity** | 5 active habits max, 1 club, 1 world theme | Unlimited habits, join multiple clubs, all world themes | "You've hit your 5th habit. Free users focus on 5 — Premium users grow without limits" |
| **Curiosity Gap** | Locked features show as blurred/greyed previews | Full access to everything | Greyed world map themes: "What lies beyond your world?" Tap to see a 3-second animated preview, then paywall |
| **Hyperbolic Discounting** | Free: flat XP, basic streak recovery | Premium: daily login bonus (+5 XP per consecutive day), exclusive nameplate, priority streak recovery | "For less than a coffee per day, unlock the full Emerge experience" |
| **Contrast Effect** | Dark glass cards (existing) | Premium cards get gold/shimmer border and subtle glow | The paywall screen itself is visually richer than any free screen — full animated background, particle effects, golden accents |
| **Framing Effect** | "You're on the free plan" (neutral) | "You've unlocked your potential" (aspirational) | Title reframe: "Go Beyond the 5" — scarcity-driven, personal |
| **Von Restorff Effect** | All UI elements similar | Premium badge on profile, gold shimmer on premium-owned items, distinct styling | The UPGRADE/UNLOCK button pulses with a gold shimmer — visually unique from every other button in the app |

### 8b. Feature Tier Breakdown

| Feature | Free | Premium | Psychology |
|---------|------|---------|------------|
| Active habits | 5 max | Unlimited | Scarcity — hitting limit triggers desire |
| Archetype clubs | Join 1 | Join unlimited | Scarcity — "your tribe vs the world" |
| World themes | 1 (archetype) | All 6 + exclusive | Curiosity Gap — locked theme previews |
| Weekly recaps | Text summary | Full animated recap | Curiosity Gap — golden locked cards |
| EMERGE ceremony | Level 5 | Level 5 | Both — universal aspirational goal |
| Habit emoji picker | Basic 18 emojis | Full + custom icons | Von Restorff — premium icons shimmer |
| Daily login bonus | None | +5 XP per day streak | Hyperbolic Discounting — small immediate reward |
| Evolution graphs | Current month | Full history | Contrast — gold-accented premium graphs |
| Nameplate/badge | Default | Custom title + gold | Von Restorff — stands out on leaderboard |

### 8c. Premium Limit Dialog Redesign

Replace `premium_limit_dialog.dart` — current: lock icon, neutral text, "MAYBE LATER" / "UPGRADE".

New — **aspiration + loss aversion + social proof**:

```
┌─────────────────────────────────┐
│  🔒                             │
│                                 │
│  You've created 5 habits.       │
│                                 │
│  That's the free limit — a      │
│  focused start. But your        │
│  potential goes further.        │
│                                 │
│  Premium users average 8 habits │
│  and 2x faster streak growth.   │
│                                 │
│  [SHOW ME WHAT I'M MISSING]     │
│        → opens paywall          │
│                                 │
│  [Stay focused for now]         │
└─────────────────────────────────┘
```

### 8d. Paywall Screen Redesign

Replace `paywall_screen.dart` — current: 4 benefit rows + pricing, "Evolve Your Avatar" headline.

New layout:

```
┌─────────────────────────────────┐
│  ←                        [X]  │
│                                 │
│  (full-screen animated cosmic   │
│   background + particles —      │
│   richer than any free screen)  │
│                                 │
│  "Go Beyond the 5"              │
│                                 │
│  You've built your foundation.  │
│  Now unlock what's waiting.     │
│                                 │
│  ┌─────────────────────────────┐│
│  │ 🔓 UNLIMITED                ││
│  │  Habits, clubs, themes      ││
│  │                             ││
│  │ ⭐ PREMIUM INSIGHTS         ││
│  │  Full evolution graphs      ││
│  │                             ││
│  │ ✨ EXCLUSIVE STYLE          ││
│  │  Gold nameplate + shimmer   ││
│  └─────────────────────────────┘│
│                                 │
│  ┌─────────────────────────┐   │
│  │ [UNLOCK YOUR POTENTIAL] │   │  ← gold shimmer CTA, pulsing
│  └─────────────────────────┘   │
│          $X.XX / month          │
│     (less than a coffee/day)    │
│                                 │
│  [Restore] • [Terms & Privacy]  │
└─────────────────────────────────┘
```

### 8e. Files

| File | Action | Notes |
|------|--------|-------|
| `paywall_screen.dart` | **Rewrite** | New headline, benefit layout, CTA, hyperbolic discounting line |
| `premium_limit_dialog.dart` | **Rewrite** | Aspiration + social proof + loss aversion frame |
| `subscription_provider.dart` | **Modify** | Expose daily login bonus state and streak count |
| New: `widgets/premium_badge.dart` | **New** | Gold shimmer badge widget for premium-owned items |
| New: `widgets/premium_theme_preview.dart` | **New** | Blurred/blurred world theme preview for curiosity gap |
| `features/habits/presentation/providers/habit_providers.dart` | **Modify** | Gate habit creation at 5 for free tier |
| `features/social/presentation/providers/tribes_provider.dart` | **Modify** | Gate club joins at 1 for free tier |

---

## Implementation Order

Plans are designed to be executed independently. Recommended order:

1. **Plan 1** (State Patterns) — easiest, highest design-doc compliance impact. Note: 1e is already done.
2. **Plan 6** (Card Polish) — visual-only, no behavioral changes
3. **Plan 4** (Anchoring + Defaults) — data-layer changes for smart defaults
4. **Plan 2** (Goal Gradient + Zeigarnik) — adds FAB ring + badges
5. **Plan 3** (Peak-End + Social Proof) — celebration + tribal strip
6. **Plan 5** (Onboarding) — larger, touches many screens
7. **Plan 8** (Freemium Model) — gating changes + paywall redesign
8. **Plan 7** (Feature) — largest, depends on Plan 4's smart defaults

---

## Verification

Each plan must pass:
- `flutter analyze` — no new warnings
- `flutter test` — existing tests pass
- Plan-specific test coverage for new/modified widgets
- Visual inspection on 320dp, 375dp, and 414dp width screens
- Plan 8: Free users cannot exceed 5 habits, 1 club. Verify gate after purchase lifts immediately.
