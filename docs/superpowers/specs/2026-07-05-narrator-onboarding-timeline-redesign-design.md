# Narrator, Onboarding & Timeline Redesign

**Date:** 2026-07-05
**Status:** Approved (visual mockup + 4 clarifications)
**Owners:** Product + Engineering

## 1. Problem statement

Three related UX issues currently degrade the Emerge app:

1. **The Narrator is everywhere and slows things down.** A `NarratorSheet` (glassmorphic modal with typewriter at 28 ms/char + punctuation pauses ≈ 7 s per message) is fired by 13 distinct triggers across onboarding, timeline, future-self studio, leveling, AI reflections, advanced create-habit, and streak recovery. There is no premium gate, no consistent voice, and no perceived value per interruption. Routine days still get narrated, killing the signal.
2. **The timeline home screen is overloaded.** `lib/features/timeline/presentation/screens/timeline_screen.dart` (~600 lines) renders a calendar strip, mission banner, streak widget, vote icon, today's timeline, hierarchical habit list, ad banner, narrator summary card, evening reflection indicator, and bonus-XP ad card. There is no dedicated reflection widget for logging habits inline; reflection only fires once at 18:00 from the narrator.
3. **Future Self Studio feels slow.** `lib/features/profile/presentation/screens/future_self_studio_screen.dart` is 1,170 lines with a stacked silhouette widget, multi-attribute aura renderer, recovery overlay, and a long narrator typewriter on first visit. Animation durations exceed Material 3's 400 ms "long" cap in places.

The combined effect: high cognitive load on the home screen, a narrator that has lost meaning through ubiquity, no perceived progression for premium users, and animations that fight perceived performance.

## 2. Goals & non-goals

### Goals
- Reduce the Narrator's audible/visual presence by ≥ 70 % (fires on < 30 % of app opens vs. today).
- Make the timeline home screen scannable in < 3 seconds (one hero progress ring + grouped habits + one reflection widget).
- Eliminate the typewriter animation everywhere; replace with streaming or instant text.
- Introduce a meaningful free vs. premium Narrator contrast (generic vs. personalised).
- Cut Future Self Studio's first-paint time and remove animation stacking that exceeds Material 3 motion caps.
- Preserve every existing data model, persistence layer, and route. No breaking migrations.

### Non-goals
- Replacing the Narrator character or writing a new LLM persona copy deck (handled separately).
- Restructuring the 5-milestone onboarding into fewer screens (user opted to keep current flow).
- Removing any existing feature (habits, blueprints, world map, tribes, gamification).
- Adding a new paywall screen or subscription tier.
- Changing the visual identity (cosmic/nebula theme, archetype colors).

## 3. Decisions (locked)

| # | Decision | Choice | Rationale |
|---|----------|--------|-----------|
| 1 | Narrator role | **Quiet companion** | NN/g "quiet beats chatty"; Spotify DJ precedent; less interruption fatigue. |
| 2 | Onboarding flow | **Keep 5-milestone structure** but remove all narrator sheets between milestones | User opted for lowest risk; narrator will not interrupt onboarding. |
| 3 | Reflection widget | **Inline mood + 1-line note on timeline** | Daylio/Reflectly precedent; low friction; fits user's explicit ask. |
| 4 | Freemium model | **Free generic lines + paid personalised insights** (Day One model) | Industry-standard; preserves trust, enables premium upsell. |
| 5 | Narrator placement | **Approach B — small persistent avatar top-right** | Visual mockup approved; character anchor without noise. |

## 4. Narrator: new behaviour

### 4.1 The avatar

A single 44 dp circular widget at the top-right of the timeline (`NarratorAvatar`). Idle state shows the gradient orb with a subtle 2 s breathing pulse; "has something to say" state shows a coloured ring + green status dot. Tapping it opens the narrator sheet instantly (no typewriter). The avatar is the only persistent narrator surface.

### 4.2 What the narrator will (and won't) say

The narrator now fires on **at most these 9 triggers** (down from 13). Removed triggers: `dailyInsight`, `newHabitCreation` (now via inline reflection), `screenFirstVisit` for excluded routes, and one-time welcome copy.

| Trigger | Fires when | Visible to | Card style |
|---------|------------|------------|-----------|
| `onboardingPostArchetype` | Once, after archetype pick in onboarding | Free + Pro | Bottom sheet (existing) |
| `morningBriefEarlyDays` | First 5 days, after first habit | Free (generic) / Pro (personal) | Slide-up card |
| `streakBreakFirstMiss` | First miss after a streak ≥ 3 | Free + Pro | Slide-up card |
| `onFireState` | Momentum ≥ 0.8 for ≥ 7 days | Free + Pro | Slide-up card |
| `levelUp` | `currentLevel > previousLevel` | Free + Pro | Slide-up card |
| `weeklyRecap` | Day 7, 14, 21… | Pro only (gated) | Slide-up card |
| `longAbsence` | ≥ 3 days since last open | Free + Pro | Slide-up card |
| `eveningReflection` | After 18:00, ≥ 1 habit done, not yet prompted today | Free + Pro | Slide-up card |
| `askNarrator` | User taps avatar or in-context "Ask" CTA | Free (generic) / Pro (personal) | Centered sheet |

Every other place that called `NarratorSheet.show(context, ...)` will be deleted or routed through the avatar / slide-up card instead.

### 4.3 Free vs. Pro

The narrator's text generator returns one of two outputs:

```dart
sealed class NarratorLine {
  const NarratorLine();
}
class GenericLine extends NarratorLine {
  final String text; // pre-written or LLM-with-no-user-data
}
class PersonalLine extends NarratorLine {
  final String text; // references user's own metrics
  final String dataBasis; // e.g. "Tuesday 6-week streak"
}
```

Resolution order:

1. If trigger is `weeklyRecap` and `isPremiumProvider` is false → render the existing `monetization` upsell sheet (full-screen paywall), do not render a narrator card. The recap is fully gated, not partially shown.
2. Otherwise, if `isPremiumProvider` is true → request `PersonalLine` from the LLM.
3. Otherwise → return a `GenericLine` from a curated pool (one line per trigger, randomly chosen, no LLM call).

Free users see the same line another free user would see for that trigger. Pro users see data-grounded lines ("Tuesday is your strongest day — 6 weeks running"). This is the gating seam — no other Narrator code path needs to know about Pro.

### 4.4 No more typewriter

The `NarratorTypewriter` widget is removed from `narrator_sheet.dart`. Lines render instantly on the first frame. LLM timing thresholds (single source of truth, used by both UI and error handling):

- **0 → 800 ms** — sheet/slide-up opens with shimmer (3-dot) in the text body.
- **800 ms → 4 s** — shimmer continues; user perceives progress.
- **> 4 s** — resolver falls back to a curated `GenericLine` for the same trigger; LLM call is cancelled.

Streaming is **not** used — for the Narrator, "instant or shimmer-then-fallback" tests better than typewriter because the mental model is "the narrator speaks" not "the narrator is typing."

`NarratorTypewriterState`, `narrator_typewriter.dart`, and all `baseDelayMs`/`pauseDurations` config are deleted.

## 5. Timeline: new home screen

### 5.1 Layout (top → bottom)

1. **Header** — Date ("Tuesday, July 5"), subtitle ("4 of 6 done · 12-day streak"), and the new `NarratorAvatar` (44 dp) at top-right. **Removes:** the 3-icon action row (share / recap / profile); these move to a single overflow menu (⋯) at top-right.
2. **Date strip** — unchanged behaviour, but with one focused day (the day with the strongest streak) given a subtle accent.
3. **Today's arc** — one card, 72 dp tall, with a circular progress ring on the left (conic-gradient), single sentence ("You're on track · 2 habits left today · evening slot"), and a tap target that scrolls to the first incomplete habit. **Replaces:** `CurrentMissionBanner`, `_buildBestStreakWidget`, `_buildVoteIcon`.
4. **Habit groups** — `HierarchicalHabitTimeline` grouped by time-of-day, unchanged. Streak / vote / share affordances move *inside* each habit card (per-tap), not as a screen-wide row.
5. **Inline reflection widget** *(new)* — `TimelineReflectionCard`. 5-emoji row (😞 😐 🙂 😊 🔥), optional 1-line note input, "Save" button. Saves to a new `daily_reflections` drift table keyed by `(user_id, local_date)`. On save, the card collapses to a 1-line summary ("You felt 🙂 today — 'morning was tough'") with an edit affordance. **Replaces:** `NarratorSummaryCard`, `_buildEveningReflectionIndicator`, and the `Bonus XP Boost` ad card (the rewarded-ad entry point moves to the overflow menu).
6. **Bottom — narrator slide-up anchor** — invisible to the user; this is just where the milestone card slides in from when fired.

### 5.2 The reflection widget in detail

```dart
// lib/features/timeline/presentation/widgets/timeline_reflection_card.dart
class TimelineReflectionCard extends ConsumerStatefulWidget {
  final DateTime date;
  // ...
}
```

State:
- `Mood? _mood` (5 values).
- `String _note` (controller-bound, max 140 chars).
- `DailyReflection? _existing` (loaded once on `initState`).
- `bool _isSaving`.

Behaviour:
- On mount, load `daily_reflections` for `(user.uid, date)`. If exists → render collapsed.
- If not exists → render expanded.
- Tap "Save" → optimistically collapse, write to drift, write to Firestore mirror in background.
- Tap collapsed card → re-expand for editing.

Persistence uses the existing `appDatabaseProvider` drift schema; a new table is added (see §8).

### 5.3 Removed widgets

The following widgets / helpers are **deleted** (not just hidden):
- `_buildVoteIcon`
- `_buildBestStreakWidget` (streak moves to the hero ring as a numeric badge)
- `_buildEveningReflectionIndicator`
- `NarratorSummaryCard` import on the timeline screen
- The "BONUS XP BOOST" `GlassmorphismCard`

Existing components stay in the codebase but are unused (kept for the recap / insights screens which still consume them).

## 6. Onboarding changes

The 5-milestone structure is preserved: `welcome → archetype → attributes → why → anchors → habit stack`. Changes:

1. **All `NarratorSheet.show(...)` calls between milestones are removed.** The narrator does not appear during onboarding.
2. **`onboardingPostArchetype` is preserved** but its copy is rewritten to acknowledge the archetype choice in one short sentence. It appears as a slide-up card (same component as milestone cards), not a centered sheet. Tap avatar → opens the existing sheet for deeper talk.
3. **Step indicator** — a "Step 2 of 5" pill is shown at the top of every milestone screen (currently absent). Research: NN/g progress indicators reduce abandonment.
4. **Skip on every milestone** — the `skipMilestone(i)` API already exists; the screens gain a persistent "Skip" text button (top-right of each step).
5. **Custom motive option** — already present in `identity_studio_screen.dart` as `_isCustomMotive`. The "Write your own" CTA is moved above the preset motives (currently below them) and is highlighted with a subtle border so users see it first.

The narrator's `onboardingPostArchetype` content pool is rewritten to ~6 short lines, one per archetype, ending in the user's archetype name: *"You've chosen the Athlete. Show me what that looks like tomorrow."*

## 7. Future Self Studio performance fixes

Current slowness comes from: (a) the screen-first-visit narrator typewriter; (b) stacked animations in `EvolvingSilhouetteWidget`, `StickmanAvatar`, `AvatarRenderer`; (c) unbounded `RepaintBoundary` placement.

Fixes:
1. **Remove the typewriter.** Replace the `screenFirstVisit` `NarratorAppearance` with the slide-up card style and instant text. (Same fix as §4.4.)
2. **Cap animations to Material 3.** Any `Duration(milliseconds: ...)` in those files is clamped: durations below 150 ms are raised to 150 ms (avoid instant pops); durations above 550 ms are lowered to 550 ms (avoid sluggishness). Files: `future_self_studio_screen.dart`, `evolving_silhouette_widget.dart`, `stickman_avatar.dart`, `avatar_renderer`, `synergy_card.dart`, `decay_recovery_overlay.dart`.
3. **Wrap animated subtrees in `RepaintBoundary`.** The silhouette widget, the avatar aura, and the synergy card each get their own `RepaintBoundary` so a state change in one doesn't repaint the other.
4. **Lazy-load the avatar renderer.** The `AvatarRenderer` switch is gated behind `useNewAvatarRendererProvider`; the screen reads the provider and `const SizedBox.shrink()`s the legacy path's silhouette widget until first user interaction with the profile tab.
5. **Replace `BackdropFilter` blur in `GlassmorphismCard` with a pre-baked blurred background** (cached PNG or `ImageFiltered` once) where the surface area is > 30 % of the viewport. BackdropFilter is the single biggest GPU cost on this screen.

## 8. Data model changes

### 8.1 New drift table

In `lib/core/drift/database.dart`, add:

```dart
@DataClassName('DailyReflection')
class DailyReflections extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  DateTimeColumn get localDate => dateTime()();
  IntColumn get mood => intEnum<Mood>()(); // 1..5
  TextColumn get note => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
```

Indexed on `(userId, localDate)` via a custom migration. Mood enum: `Mood.terrible=1, .meh=2, .ok=3, .good=4, .great=5`.

### 8.2 New narrator types

In `lib/features/narrator/domain/models/`:

```dart
sealed class NarratorLine {
  const NarratorLine();
}
class GenericLine extends NarratorLine {
  final String text;
  const GenericLine(this.text);
}
class PersonalLine extends NarratorLine {
  final String text;
  final String dataBasis; // e.g. "Tuesday 6-week streak"
  const PersonalLine({required this.text, required this.dataBasis});
}
```

Pattern-matching on `NarratorLine` is the recommended consumer style (Dart 3+, exhaustive). The resolver (§4.3) is the single producer.

A new service `NarratorLineResolver` lives at `lib/features/narrator/domain/services/narrator_line_resolver.dart`. Its public API is the single entry point every narrator UI calls. Internally it reads `isPremiumProvider`, the current `NarratorUserStats`, and the trigger.

### 8.3 Removed narrator types

`narrator_typewriter.dart` is deleted. `NarratorAppearance.hasTextField` and the related reflection text-input are removed from `narrator_sheet.dart` (the reflection widget on the timeline replaces this affordance).

## 9. Architecture

```
lib/features/narrator/
├── domain/
│   ├── models/
│   │   ├── narrator_appearance.dart          (slimmed: no hasTextField)
│   │   ├── narrator_line.dart                (NEW)
│   │   ├── narrator_note.dart                (unchanged)
│   │   └── narrator_trigger.dart             (4 triggers removed: dailyInsight, newHabitCreation, screenFirstVisit, nodeFirstVisit)
│   └── services/
│       ├── narrator_line_resolver.dart       (NEW — single entry point)
│       └── narrator_trigger_engine.dart      (slimmed: removed triggers)
├── presentation/
│   ├── providers/narrator_providers.dart     (+ lineResolverProvider)
│   └── widgets/
│       ├── narrator_avatar.dart              (NEW — persistent avatar)
│       ├── narrator_milestone_card.dart      (NEW — slide-up card)
│       ├── narrator_pulse_indicator.dart     (kept)
│       ├── narrator_sheet.dart               (no typewriter; uses NarratorLine)
│       ├── narrator_summary_card.dart        (deprecated on timeline; keep for recap)
│       └── narrator_typewriter.dart          (DELETED)
```

```
lib/features/timeline/presentation/
├── screens/timeline_screen.dart               (slimmed: remove 6 widgets, add 2)
└── widgets/
    ├── today_arc_card.dart                    (NEW)
    ├── timeline_reflection_card.dart          (NEW)
    ├── hierarchical_habit_timeline.dart       (unchanged)
    ├── month_calendar_strip.dart              (unchanged)
    └── … (others unchanged)
```

```
lib/features/reflections/                       (NEW feature folder)
├── data/datasources/reflection_local_datasource.dart
├── data/datasources/reflection_remote_datasource.dart
├── data/repositories/reflection_repository.dart
├── domain/entities/daily_reflection.dart
└── presentation/providers/reflection_providers.dart
```

The new `reflections` feature is the canonical home for the reflection data model; the timeline widget consumes it via Riverpod.

## 10. Component API (selected, for planning reference)

```dart
// Avatar (NEW)
class NarratorAvatar extends ConsumerWidget {
  const NarratorAvatar({super.key});
  // Reads narratorLineResolverProvider, narratorStateProvider.
  // Renders 44dp circle, idle pulse animation, status dot.
  // onTap → opens NarratorSheet or shows slide-up if line is waiting.
}

// Slide-up milestone card (NEW)
class NarratorMilestoneCard extends ConsumerStatefulWidget {
  final NarratorLine line;
  final NarratorTrigger trigger;
  final Duration autoDismissAfter;
  const NarratorMilestoneCard({
    required this.line,
    required this.trigger,
    this.autoDismissAfter = const Duration(seconds: 6),
  });
}

// Reflection widget (NEW)
class TimelineReflectionCard extends ConsumerStatefulWidget {
  final DateTime date;
  const TimelineReflectionCard({required this.date});
}

// Hero progress (NEW)
class TodayArcCard extends ConsumerWidget {
  final int completed;
  final int total;
  final int streakDays;
  final VoidCallback? onTap;
}
```

## 11. State and routing

- `narratorStateProvider` is extended with `pendingMilestone: NarratorLine?`. When non-null, the timeline renders the slide-up card.
- `completeHabitProvider` does not change; reflection persistence is decoupled.
- The router (`lib/core/router/router.dart`) is unchanged. No new routes are added.
- The `reflectionLogged` narrator note type stays — it's now written by `TimelineReflectionCard.save`, not by the narrator sheet.

## 12. Error handling

- **Line resolver LLM timeout (> 4 s)** → fall back to a curated generic line for the same trigger. Log to Crashlytics with a "llm_fallback" tag.
- **Reflection save failure (drift)** → keep the optimistic collapsed state but show a snackbar with retry. The collapsed state is the local-first source of truth; sync retries in the background.
- **Reflection save failure (Firestore)** → drift remains the truth; a queue retry runs on next app open via the existing sync service.
- **Premium gate misfire** → `weeklyRecap` checks `isPremiumProvider` synchronously; if the provider is mid-load, the card is held off-screen (skeleton) rather than rendering a free card and then swapping (which flashes).

## 13. Testing strategy

Pure-logic tests (no Firebase/Riverpod):

- `test/features/narrator/narrator_line_resolver_test.dart` — given `(premium, stats, trigger)`, returns correct `NarratorLine` kind + text. Covers all 9 triggers × {free, pro} × {with stats, without stats} = 36 cases.
- `test/features/narrator/narrator_trigger_engine_test.dart` — slimmed engine. Cooldown, priority ordering, removed triggers never fire.
- `test/features/reflections/daily_reflection_test.dart` — entity equality, mood enum mapping.
- `test/features/timeline/today_arc_card_test.dart` — pure widget test with mock stats; verifies the percent rendering, the "2 left" copy, and the tap target scrolls to the first incomplete habit.

Widget tests (tester + fakes):

- `test/features/timeline/timeline_reflection_card_test.dart` — uses `fake_cloud_firestore` + a fake drift; verifies: empty state → save → collapsed state with summary → re-expand → edit → save updates updatedAt.
- `test/features/narrator/narrator_avatar_test.dart` — verifies avatar renders idle, shows status dot when `pendingMilestone != null`, and `onTap` opens the sheet.
- `test/features/narrator/narrator_milestone_card_test.dart` — verifies slide-up animation, auto-dismiss timer, swipable-to-dismiss, and personal-line badge.

Manual QA checklist (do once before merging):
- [ ] Cold-start timeline → no typewriter anywhere.
- [ ] Complete 7-day streak → narrator slide-up card appears within 1 s.
- [ ] Tap avatar → sheet opens instantly (≤ 200 ms perceived).
- [ ] Free user sees generic line; Pro user sees "Tuesday is your strongest…" line on same trigger.
- [ ] Onboarding milestones advance without any narrator interruption.
- [ ] Reflection save → collapsed card → re-edit → updatedAt changes.
- [ ] Future Self Studio first paint < 800 ms on Pixel 5 emulator.

## 14. Migration / data safety

- The drift migration adds one table — non-destructive. Existing drift version is bumped (e.g., `6 → 7`); migration handler `onUpgrade` adds the new table without touching existing ones.
- Firestore: a new top-level collection `daily_reflections/{uid}/days/{localDate}` is written in addition to drift. No existing collection is renamed.
- Users mid-onboarding at deploy time: their `EnhancedOnboardingState.isOnboardingActive` is unchanged. The narrator sheets they would have seen are now silent; they will simply not see those cards. No broken state.

## 15. Out of scope (call out for follow-up specs)

- Rewriting narrator copy deck per archetype (handled by content team).
- Adding a paywall entry point to the overflow menu (currently in `monetization` feature).
- Replacing `GlassmorphismCard` with a cached-blur surface across the entire app (only done for Future Self Studio in this spec).
- Adding a "narrator settings" screen to fully mute by trigger (future iteration; current mute is global via `isMutedProvider`).

## 16. Open questions

None for this spec. All clarifications were answered (4 questionnaire responses) and the visual mockup was approved.
