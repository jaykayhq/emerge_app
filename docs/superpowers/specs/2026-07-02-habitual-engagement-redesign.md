# Habitual Engagement Redesign — UltaThink Spec

**Status:** Draft
**Date:** 2026-07-02
**Owner:** Product / Architecture

---

## 1. The Interrogation

### 1.1 The Uncomfortable Fact

People don't have a "habit tracking" bone in their body. Research into 2026
daily phone habits tells a clear story: the apps with the highest daily
activation are the ones with **low friction, ambient presence, and immediate
visual reward**.

| Habitual 2026 Task | Activation Steps |
|---|---|
| Messages | Tap icon → see list |
| Music | Tap icon → press play |
| Bank | Notification → open → tap |
| Short video | Open → scroll |
| Photo | Camera → snap |

> **Emerge's habit completion requires more steps than any of the above.**

### 1.2 Core Thesis

Emerge must stop feeling like a *tool you go to* and start feeling like a
*space you live in*. The redesign does three things:

1. **The lock screen is the app** — habit completion in <2s without entering
   the app via widgets, Live Activities, and notification actions
2. **The app opens to the action** — Timeline (not World Map) is the home tab
   and primary entry point; one-tap completion with immediate satisfying feedback
3. **The world is ambient** — via widgets, wallpaper, and glanceable previews,
   the world map follows the user throughout the day, not just during app sessions

---

## 2. Current State — The Habituality Gap

| Element | Current | Problem |
|---|---|---|
| **Home tab** | World Map (visual, no action) | 8-12s to complete a habit |
| **Bottom nav order** | World → Timeline → [FAB] → Tribes → Profile | Timeline is tab 2, completion is buried |
| **Completion UX** | Habit card → [✓] button → modal/animation | Requires navigation, has friction |
| **World visibility** | Only inside app | Zero ambient presence |
| **Reward timing** | XP bars + delayed world change | Delayed, subtle, easy to miss |
| **Notification actions** | None (tap → app open only) | Forces full app entry |
| **Home screen widgets** | None | No glanceable habit state |
| **Primary emotion** | Guilt/anxiety about streaks | Polar Habits built a business on fixing this |

---

## 3. Redesigned UX Architecture

### 3.1 Information Hierarchy

```
TIER 0 — Lock Screen / Home Screen
  Widget: today's habit stack with [Complete] buttons
  World slice preview widget

TIER 1 — App Open → TIMELINE (the action zone)
  Chronological habit stack by time-of-day
  One-tap completion per habit
  Immediate satisfying feedback (particles + haptic)

TIER 2 — World Map (the reward zone)
  Beautiful Flame-powered map
  YOU DON'T COME HERE TO DO WORK
  YOU COME HERE TO FEEL PROUD

TIER 3 — Profile / Settings (the customization zone)
  Avatar, AI coach, notification prefs, health integrations
```

### 3.2 Navigation Changes

**Bottom nav becomes 4 tabs (FAB removed from center):**

```
[World Map (tab 0)]   [Timeline (tab 1)]   [Tribes (tab 2)]   [Profile (tab 3)]
     visual               action (HOME)        social             identity
     reward zone          completion zone      community          customization
```

**Key change:** Timeline moves to **tab 1** (index 0 internally in code since
it's first). The World Map shifts to **tab 0** (positioned as reward, not work).

### 3.3 Completion Loop — Before vs. After

| Step | Before | After |
|---|---|---|
| **Trigger** | User decides to open app | Notification / widget glance |
| **Action** | Find app → open → scroll → locate habit → tap | Tap notification action / widget button |
| **Reward** | XP bar fills, world changes subtly | Card explodes into particles, haptic fires, avatar on map visibly shifts |
| **Investment** | "Did it grow?" (notices hours later) | "What will my world look like tomorrow?" (anticipation) |

### 3.4 The Hook Model (Nir Eyal) Applied

```
 TRIGGER          ACTION           VARIABLE REWARD          INVESTMENT
──────────      ──────────       ──────────────────      ───────────────
Notif/widget    <2s tap           • Card particle burst    • Curious about
 pushes you     on widget         • Haptic confirmation       tomorrow's world
                               • Avatar moves visibly     → Opens app later
                               • World glow brightens       to explore
                               • Surprise events (NPCs,
                                 weather, discoveries)
```

---

## 4. Widget System (the Lock Screen Layer)

### 4.1 Architecture

```
                    ┌─────────────────────────┐
                    │   HabitCompletionWidget   │
                    │   (new feature module)    │
                    └───────┬─────────────────┘
                            │
              ┌─────────────┼─────────────┐
              ▼             ▼             ▼
    ┌──────────────────┐ ┌──────────┐ ┌──────────────┐
    │ CompletionIntent │ │ Provider │ │ Service      │
    │ (freezed)        │ │ methods │ │ layer        │
    │ { habitId,       │ │         │ │              │
    │   completedAt,   │ │• today  │ │• widgetKits  │
    │   source }       │ │• streak │ │• LiveActivit │
    └──────────────────┘ └──────────┘ └──────────────┘
```

### 4.2 Widget Types

| Type | Size | Platform | Content |
|---|---|---|---|
| **HabitStackWidget** | 4x2 | iOS + Android | Today's habits with completion buttons |
| **WorldSliceWidget** | 2x2 | iOS + Android | World region preview + health indicator |
| **MomentumBarWidget** | 2x1 | iOS + Android | Current momentum score (0-100) |
| **DayOverviewWidget** | 4x4 | iOS + Android | Combines stack + world + momentum |

### 4.3 Completion Flow from Widget

```
User taps [✓] on widget
  → HabitCompletionService.markComplete(habitId, source: widget)
  → LocalGameLoopEngine processes (offscreen, <1ms)
  → Drift updated offline-first
  → Sync queue enqueue for Firestore
  → Widget updates via Riverpod provider (StreamBuilder)
  → App opens later → Timeline shows updated state
```

**Critical constraint:** Widget completion must work **fully offline**. The
sync happens lazily when connectivity returns. This is the primary use case —
people completing habits on the bus, in the gym, anywhere.

### 4.4 Notification Actions

Replace the current "tap-to-open" notification behavior with **inline actions**:

```
Current:   [Morning Meditation due]  → tap → opens full app
New:       [Morning Meditation due]  → [Snooze 10m] [Complete] [Open App]

Notifications show:
  • Snooze button (10min / 1hr / custom)
  • Complete button (one-tap, same as widget)
  • Open App button (navigates to Timeline)
```

Implementation: `flutter_local_notifications` `ActionType` on Android,
`UNNotificationCategory` with actions on iOS.

### 4.5 Live Activities (iOS 17+)

```
HabitStackLiveActivity — shows on lock screen
  • Today's incomplete habits
  • Each tapable (Quick Action → complete)
  • Auto-updates as habits are completed
  • Expires at midnight
```

---

## 5. Notification Service Changes

### 5.1 Current State

`NotificationService` (in `core/services/notification_service.dart`) handles:

- Permission requests (FCM + local)
- Scheduled notifications with `flutter_local_notifications`
- `onDidReceiveNotificationResponse` — currently logs, no action routing

### 5.2 Required Changes

| Change | Implementation |
|---|---|
| **Action buttons on notifications** | Register `AndroidAction` / `iOS` inline actions per habit group |
| **Deep-link from action** | "Complete" action → calls `HabitCompletionService` directly |
| **Snooze support** | New `NotificationSnoozeService` — reschedules notification |
| **Today summary notification** | Morning push: "You have 5 habits today. 3 are morning stack." |
| **Live Activity registration** | iOS 17+ `Activities.start()` when timeline loads |
| **Widget update trigger** | `HabitCompletionNotifier` notifies all active widgets |

---

## 6. Timeline as Home — UX Changes

### 6.1 Current Timeline Structure (from `timeline_screen.dart`)

```dart
TimelineScreen
  ├── MonthCalendarStrip
  ├── CurrentMissionBanner
  ├── HabitTimelineSection (Morning/Afternoon/Evening stacks)
  ├── ReflectionCard
  └── AdBannerWidget (freemium)
```

### 6.2 Redesigned Timeline

```dart
EnhancedTimelineScreen  (now the app's identity layer)
  ├── DayHeader               ← NEW: date, motivational line, world mood
  ├── HabitStackSection
  │   ├── MorningStack
  │   │   ├── HabitCard (one-tap complete)    ← SIMPLIFIED: no swipe needed
  │   │   ├── HabitCard
  │   │   └── HabitCard
  │   ├── AfternoonStack
  │   │   └── ...
  │   └── EveningStack
  │       └── ...
  ├── CompletionCelebration (floating, on habit complete)
  ├── QuickAddFloatingButton  ← moves to bottom-right, not center FAB
  └── BottomNav
      ├── [World] → WorldMapScreen (rewards zone)
      ├── [Timeline] ← HOME (this screen)
      ├── [Tribes] → TribeLobbyScreen
      └── [Profile] → FutureSelfStudioScreen
```

### 6.3 One-Tap Completion

**Current:** Habit card shows `[✓]` but requires a tap on the card body,
sometimes triggering detail navigation. Confirmation modal adds friction.

**New:** Each habit card has a dedicated **completion zone** — a fixed-area
circle/button that:
- Fills with archetype-themed color on tap
- Triggers particle burst animation (200ms)
- Fires satisfying haptic (VibrationPattern.shortDouble)
- Instantly moves card to "completed" state (dimmed, checkmark animated)
- Does NOT navigate away
- Does NOT show a confirmation dialog

### 6.4 Completion Particles

```
New file: lib/core/presentation/widgets/completion_particles.dart

Particle system on tap:
  • 30-50 particles burst from tap point
  • Archetype-colored (Athlete = fire orange, Scholar = gold, etc.)
  • Gravity + fade over 800ms
  • Reusable across all habit card types
  • Lightweight: CustomPainter, no physics engine needed
```

---

## 7. The World as Ambient Layer

### 7.1 Three-Tier Presence

| Tier | Mechanism | Frequency | Purpose |
|---|---|---|---|
| **Tier 1 (Lock Screen Widget)** | HabitStackWidget 4x2 | 90x/day | Ambient awareness |
| **Tier 2 (Home Screen Widget)** | WorldSliceWidget 2x2 | 50x/day | Glanceable progress |
| **Tier 3 (In-App)** | Flame World Map | 5-10x/day | Deep exploration |

### 7.2 World Live Activity (iOS)

```
WorldStateLiveActivity
  • Shows current world health % (thriving / neutral / decaying)
  • Mini-map preview (low-res Flame render)
  • Last update timestamp
  • Auto-updates on world state change
  • Tapping opens app to full world map
```

### 7.3 Ambient World Changes

The world must feel **alive** even when not being observed:

| Change | Frequency | Mechanism |
|---|---|---|
| Time-of-day lighting | Continuous | Flame engine time-of-day shader |
| Weather system | Random daily | WeatherProvider seeded by date |
| NPC/traveler movement | Hourly | Animated sprites on idle map |
| Building glow pulse | Continuous | Subtle emission animation |

**Goal:** When the user opens the app after 4+ hours, they think "whoa, my
world looks different" — same feeling as opening Animal Crossing after a real
day passing.

---

## 8. Variable Reward Engine

### 8.1 Surprise Events

The world evolves in **unpredictable** ways to maintain engagement through
curiosity. These events fire based on a combination of consistency streaks
and randomness:

| Event | Trigger | Effect |
|---|---|---|
| **Traveler Visit** | 5-day consistency streak | NPC appears on world map with message |
| **Weather Shift** | Daily random (seeded) | Rain/sun/storm transforms map mood |
| **Discovery Burst** | "On Fire" momentum (90+) | Hidden area revealed with XP bonus |
| **Biome Transition** | Level milestone | World season shifts (forest→winter, city→night) |
| **Tribe Convergence** | Top 10% weekly consistency | Neighboring tribe region appears on map |

### 8.2 Implementation

```
lib/features/gamification/
  ├── domain/
  │   ├── models/world_event.dart          — WorldEvent (type, payload, timestamp)
  │   └── services/world_event_engine.dart  — Pure logic: evaluateAndFire()
  ├── data/
  │   └── repositories/world_event_repository.dart — Firestore persistence
  └── presentation/
      └── providers/world_event_providers.dart    — Riverpod + event stream
```

`WorldEventEngine.evaluateAndFire()` is a **pure function** — testable without
Riverpod, Firebase, or Flutter. Takes `UserStats` + `DateTime.now()` and returns
`List<WorldEvent>`.

---

## 9. Riverpod Provider Changes

### 9.1 New Providers

```dart
// Habit completion
@riverpod
HabitCompletionService habitCompletionService(Ref ref) ...

// Today's habits for widget
@riverpod
AsyncValue<List<Habit>> todayHabits(Ref ref) ...

// World events for ambient layer
@riverpod
Stream<List<WorldEvent>> worldEventStream(Ref ref) ...

// Widget completion state
@riverpod
class HabitCompletionNotifier extends _$HabitCompletionNotifier {
  Future<void> complete(String habitId, CompletionSource source) async ...
}
```

### 9.2 Modified Providers

```dart
// Timeline home tab index changes from 1 to 0
// BottomNav tab config needs reordering
```

---

## 10. Navigation Changes (`router.dart`)

### 10.1 Bottom Nav Tab Order

```
Current:
  branch 0 → / (WorldMap)
  branch 1 → /timeline
  branch 2 → /social
  branch 3 → /profile

New:
  branch 0 → /timeline          ← moves to first slot (HOME)
  branch 1 → / (WorldMap)       ← visual reward tab
  branch 2 → /social            ← unchanged
  branch 3 → /profile           ← unchanged
```

### 10.2 FAB Removal

The center `+` FAB was the entry point for habit creation. This moves to:
- A `+` button on the Timeline screen (bottom-right corner, compact)
- The `ScaffoldWithNavBar` loses the `ExtendedFAB` position 1

---

## 11. File Structure

### 11.1 New Files

```
lib/features/habit_widget/
  ├── data/
  │   ├── datasources/
  │   │   └── completion_service.dart          — Pure habit completion logic
  │   └── repositories/
  │       └── completion_repository.dart        — Drift + Firestore paths
  ├── domain/
  │   └── services/
  │       └── habit_completion_service.dart     — Public API: markComplete, snooze
  └── presentation/
      └── providers/
          └── habit_completion_providers.dart    — Riverpod providers
          └── habit_completion_providers.g.dart  — Generated

lib/core/presentation/widgets/
  ├── completion_particles.dart                 — Particle burst animation
  ├── habit_stack_widget.dart                   — 4x2 home screen widget
  ├── world_slice_widget.dart                   — 2x2 world preview widget
  ├── day_overview_widget.dart                  — 4x4 combined widget
  └── one_tap_habit_card.dart                   — Simplified habit card

lib/features/gamification/
  ├── domain/
  │   ├── models/
  │   │   └── world_event.dart                  — WorldEvent model
  │   └── services/
  │       └── world_event_engine.dart            — Pure evaluation logic
  ├── data/
  │   └── repositories/
  │       └── world_event_repository.dart        — Persistence layer
  └── presentation/
      └── providers/
          └── world_event_providers.dart         — Event stream provider

lib/core/services/
  ├── notification_snooze_service.dart           — Reschedule cancelled notifs
  └── world_live_activity_service.dart            — iOS Live Activity management
```

### 11.2 Modified Files

```
lib/core/router/router.dart                     — Tab order: timeline (0), world (1)
lib/core/presentation/widgets/scaffold_with_nav_bar.dart — Remove center FAB, reorder tabs
lib/features/timeline/presentation/screens/timeline_screen.dart
  → EnhancedTimelineScreen: one-tap completion, particles, DayHeader
lib/features/habits/presentation/widgets/habit_timeline_section.dart
  → HabitCard redesign: one-tap zone, particle target
lib/core/services/notification_service.dart
  → Action buttons, snooze, deep-link from action
lib/features/settings/presentation/screens/settings_screen.dart
  → Widget config, notification action prefs, Live Activity toggle
```

### 11.3 New test directories

```
test/features/habit_widget/
  ├── domain/services/habit_completion_service_test.dart
  └── presentation/providers/habit_completion_providers_test.dart

test/features/gamification/
  ├── domain/models/world_event_test.dart
  └── domain/services/world_event_engine_test.dart

test/core/presentation/widgets/
  ├── completion_particles_test.dart
  ├── habit_stack_widget_test.dart
  └── world_slice_widget_test.dart
```

---

## 12. Data Model: `WorldEvent`

```dart
enum WorldEventType {
  travelerVisit,    // NPC appears with message
  weatherShift,     // Rain, sun, storm, fog
  discoveryBurst,   // Hidden area revealed
  biomeTransition,  // Season/time-of-day shift
  tribeConvergence, // Neighboring tribe region appears
}

class WorldEvent {
  final String id;
  final WorldEventType type;
  final Map<String, dynamic> payload;  // position, message, visual config
  final DateTime triggeredAt;
  final DateTime? expiresAt;

  const WorldEvent({
    required this.id,
    required this.type,
    required this.payload,
    required this.triggeredAt,
    this.expiresAt,
  });
}
```

Persisted to Firestore: `users/{uid}/worldEvents/{eventId}`. Auto-cleaned by
Cloud Function after `expiresAt`.

---

## 13. Data Model: `CompletionSource` (enum)

```dart
enum CompletionSource {
  timeline,       // Completed inside the app via Timeline
  widget,         // Completed via home screen widget
  notification,   // Completed via notification action button
  voice,          // Completed via voice command (future)
  healthSync,     // Auto-completed via health/screen time
}

class HabitCompletionIntent {
  final String habitId;
  final CompletionSource source;
  final DateTime completedAt;

  const HabitCompletionIntent({
    required this.habitId,
    required this.source,
    required this.completedAt,
  });
}
```

---

## 14. Non-Goals (Out of Scope)

| Item | Reason |
|---|---|
| **Full 3D avatar integration** | Separate spec (avatar system) |
| **Social ambient layer** (friend worlds visible on map) | Phase 5, later |
| **Live wallpaper (Flame render to texture)** | Technical risk; evaluate after widgets ship |
| **Health auto-completion** | Already spec'd in `2026-06-09-health-screen-time-integration-design.md` |
| **Creator routes changes** | Separate spec |
| **New monetization** | Existing RevenueCat + AdMob flow is sufficient |

---

## 15. Risks & Mitigations

| Risk | Severity | Mitigation |
|---|---|---|
| Widget API differences per platform | Medium | Abstract behind `HabitCompletionService` interface |
| Live Activity battery impact (iOS) | Low | Set reasonable update interval (15min max) |
| Notification action spam (users annoyed) | Medium | Only show actions at scheduled time, not as push |
| Flame engine performance on widgets | Low | Widgets use static images, not Flame rendering |
| Completion from widget without opening app breaks streak anxiety | Low | This is intentional — momentum system already handles forgiveness |

---

## 16. Verification Strategy

| Layer | What to verify | How |
|---|---|---|
| **Widget** | Habits complete in <2s from home screen | Manual: timestamp tap → completion timestamp |
| **Notification** | Action buttons appear and complete habit | Manual: schedule → open shade → tap Complete |
| **Timeline** | One-tap completion works without navigation | Widget + integration test |
| **Sync** | Offline completions sync when online | Test: airplane mode → complete → reconnect → Firestore |
| **Particles** | Animation fires on completion | Widget test (pump timeline, tap card, verify animation controller) |
| **Bottom nav** | Timeline is tab 1, tab order correct | Integration test: verify ordered children |
| **World events** | Events fire based on consistency | Unit test: `WorldEventEngine.evaluateAndFire()` with mock stats |

---

## Appendix A: Research Sources

| Source | Key Finding |
|---|---|
| BankMyCell (2025) | 96 checks/day, 2,617 touches/day, 71% check within 10 min of waking |
| Demandsage | 83% use for email/photos, 76% browse web, 79% mobile shoppers |
| Zippia/BusinessofApps | 5h 24min avg daily US screen time, 70% of digital media time |
| Polar Habits (competitor) | Momentum-based (no streaks) is a key differentiation |
| Habitica reviews | "Too many tabs, messy, difficult to navigate" |

## Appendix B: Competitive Positioning After Redesign

| Dimension | Before | After |
|---|---|---|
| Mindshare | "Another habit tracker" | "Your phone's personality" |
| Activation energy | 8-12s | <2s |
| Open frequency | Motivation-dependent | Trigger + ambient |
| Reward timing | Delayed/small | Immediate + ambient |
| Emotional hook | Streak anxiety | Pride/curiosity |
| Retention driver | Willpower | Variable reward + ambient presence |
