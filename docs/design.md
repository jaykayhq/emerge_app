# Emerge Design System

**Version:** 1.0  
**Applies to:** emerge_app (Flutter)  
**Status:** Active — all agents MUST follow this document when designing or implementing UI.  
**Enforcement:** Referenced from `AGENTS.md`. Any UI implementation that contradicts this document must be flagged during code review.

---

## Table of Contents

1. [Design Philosophy](#1-design-philosophy)
2. [Visual Identity](#2-visual-identity)
3. [Design Tokens & Layout](#3-design-tokens--layout)
4. [Navigation Architecture](#4-navigation-architecture)
5. [State Management UX Patterns](#5-state-management-ux-patterns)
6. [Animation & Micro-interactions](#6-animation--micro-interactions)
7. [Accessibility](#7-accessibility)
8. [Gesture & Touch Patterns](#8-gesture--touch-patterns)
9. [Component Design System](#9-component-design-system)
10. [Form UX Patterns](#10-form-ux-patterns)
11. [Feedback & Notification Patterns](#11-feedback--notification-patterns)
12. [Habitual Engagement Model](#12-habitual-engagement-model)
13. [Platform Considerations](#13-platform-considerations)
14. [Edge Cases](#14-edge-cases)
15. [Copy & Content Standards](#15-copy--content-standards)

---

## 1. Design Philosophy

### 1.1 Core Identity

Emerge is an **identity-first habit engine**, not a task tracker. The app's visual language must communicate:

- **Cosmic scale** — habits shape who you become over time, like stars shaping a galaxy
- **Vitality** — the green accent (#2BEE79) represents growth, life, forward momentum
- **Depth** — glassmorphism and layered UI create a sense of space and dimensionality
- **Personal identity** — archetype theming makes every screen feel like *yours*

Every pixel must answer: *"Does this help the user feel like they're building their future self?"*

### 1.2 Design Principles

| # | Principle | Meaning |
|---|-----------|---------|
| 1 | **Ambient over intrusive** | The app lives in the background, not demanding attention. Notifications, the Narrator, and animations should complement rather than interrupt. |
| 2 | **<2s to value** | Every screen should deliver its primary value within 2 seconds of appearing. Habit completion must be possible in <2 taps. |
| 3 | **Proud, not guilty** | The emotional tone is aspirational pride, not streak anxiety. Empty states invite action; errors guide recovery; rewards celebrate identity. |
| 4 | **Cosmic, not chaotic** | The deep-space aesthetic should feel serene and ordered, not busy or overwhelming. Use negative space generously. |
| 5 | **One signature moment per screen** | Each screen gets one visually memorable element (a glowing orb, a particle burst, a morphing silhouette). Everything else recedes. |

### 1.3 The Three-Tier Presence

The app operates across three tiers of user attention, adapted from the Habitual Engagement Redesign:

```
TIER 0 — Ambient (widgets, notifications, Live Activities)
  User may never open the app. Habit completion in <2s.
  No full-screen UI, no navigation.

TIER 1 — Active (Timeline = home tab)
  The action zone. One-tap completion, inline reflection, glanceable progress.
  The app opens here. Never to an empty or confusing state.

TIER 2 — Immersive (World Map, Profile, Social)
  The reward and exploration zone. Deep engagement, visual richness.
  User comes here to feel proud, not to do work.
```

---

## 2. Visual Identity

### 2.1 Color System

#### 2.1.1 Cosmic Background (Primary)

The app's background is a deep cosmic void — the "Stitch World Map" aesthetic. Colors are defined in `lib/core/theme/emerge_colors.dart`.

| Token | Hex | Usage |
|-------|-----|-------|
| `cosmicVoidDark` | `#0A0A1A` | Near-black void — primary scaffold background |
| `cosmicVoidCenter` | `#1A0A2A` | Rich purple center — gradient midpoint |
| `cosmicMidPurple` | `#2A1A3A` | Mid-tone purple glow — card hover, backdrop |
| `cosmicBlue` | `#0A1A3A` | Cosmic blue nebula — alternate gradient direction |

#### 2.1.2 Green Accent (Preserved)

The green accent `#2BEE79` is the app's signature — it must not be changed or muted.

| Token | Hex | Usage |
|-------|-----|-------|
| `neonTeal` / `neonGreen` | `#2BEE79` | Primary green — buttons, active states, completion indicators |
| `neonGreenBright` | `#4ADE80` | Bright green — gradients, glow effects |
| `mintMuted` | `#92C9A8` | Muted green — secondary text, inactive states |

**Rule:** Never replace the green accent with another color for primary actions. Archetype colors accent *secondary* surfaces only.

#### 2.1.3 Archetype Colors

Each archetype gets a primary + accent color pair. Colors are used for card accents, badge fills, and the archetype-specific gradient in `IdentityThemeExtension`.

| Archetype | Primary | Accent | Gradient (dark → lighter) |
|-----------|---------|--------|--------------------------|
| Athlete | `#FF5252` | `#FF8E72` | `#1A1A2E` → `#16213E` |
| Scholar | `#7C3AED` | `#B794F6` | `#1A1B2E` → `#2D2B55` |
| Creator | `#FFD700` | `#FFD93D` | `#2C1810` → `#3D2317` |
| Stoic | `#26A69A` | `#4DD4AC` | `#0D1B1E` → `#1A3B3E` |
| Zealot | `#991B1B` | `#B45309` | `#450A0A` → `#1E1E1E` |
| Explorer | `#009688` | `#64FFDA` | `#1A1A2E` → `#16213E` |

#### 2.1.4 Glassmorphism Colors

All glass cards use these semi-transparent values consistently:

| Token | Value | Usage |
|-------|-------|-------|
| `glassWhite` | `#14FFFFFF` (8%) | Card background |
| `glassWhiteLight` | `#1FFFFFFF` (12%) | Brighter card background |
| `glassBorder` | `#26FFFFFF` (15%) | Card borders |

**Performance rule:** On any surface >30% of the viewport, replace `BackdropFilter` blur with a cached blurred image or `ImageFiltered` (single-pass). BackdropFilter is the single biggest GPU cost — use sparingly.

#### 2.1.5 Functional Colors

| Token | Hex | Usage |
|-------|-----|-------|
| `warmGold` | `#FFD700` | Rewards, XP, achievements |
| `errorColor` | `#f7768e` | Errors, destructive actions |
| `starBlue` | `#AACFFF` | Secondary text (dark theme) |
| `nebulaPrimary` | `#A5E7FF` | Social hub, interactive highlights |

### 2.2 Typography

#### 2.2.1 Typefaces

| Role | Face | Weight Range | Source |
|------|------|-------------|--------|
| **Display** | Spline Sans | Bold (700) | Google Fonts |
| **Body** | Spline Sans | Regular (400), Medium (500) | Google Fonts |
| **Utility** | Spline Sans Mono (future) | Regular | Google Fonts |

**Why Spline Sans:** Warm, humanist geometric sans-serif that balances the cosmic aesthetic with readability. Its open counters and moderate x-height make it legible at small sizes on mobile.

#### 2.2.2 Type Scale (Mobile)

| Level | Size | Weight | Line Height | Usage |
|-------|------|--------|-------------|-------|
| Display L | 36sp | Bold 700 | 44px | Hero numbers, world map labels |
| Display M | 28sp | Bold 700 | 36px | Screen titles, level-ups |
| Display S | 24sp | Bold 700 | 32px | Section headers |
| Headline | 20sp | SemiBold 600 | 28px | Card titles, archetype names |
| Title | 18sp | Medium 500 | 24px | Bottom nav labels, list titles |
| Body L | 16sp | Regular 400 | 24px | Primary content text |
| Body M | 14sp | Regular 400 | 20px | Secondary content, card body |
| Body S | 12sp | Regular 400 | 16px | Captions, timestamps, metadata |
| Label | 14sp | Medium 500 | 20px | Button text, form labels |
| Label S | 11sp | Medium 500 | 16px | Badges, small chips |

**Rule:** Never go below 12sp for interactive text. Never go above 36sp on a mobile viewport.

### 2.3 Iconography

- Use `MaterialIcons` rounded style wherever available (`Icons.*_rounded`)
- Icon sizes: `EmergeDimensions.iconSmall` (18), `iconMedium` (24), `iconLarge` (32)
- All interactive icons must be wrapped in at least 44×44dp tap target (use `EmergeIconLabel`)
- Never use outlined icons for active/selected states — use filled variants

### 2.4 Glassmorphism System

Glassmorphism is the app's signature surface treatment. Every card, sheet, and overlay should use it.

**Implementation rules:**

1. Always use `GlassmorphismCard` or `EmergeGlassCard` — never hand-roll `BackdropFilter`
2. Default blur sigma: 12px
3. Default glass opacity: 8% white (`glassWhite`)
4. Border: 1px at 15% white (`glassBorder`)
5. Border radius: 16dp (cards), 12dp (small cards)
6. For full-screen overlays (sheets, dialogs): increase opacity to 12% (`glassWhiteLight`)
7. For cards that are the primary interactive element on screen: add a green `glowColor`

**Anti-pattern:** Do not layer glassmorphism cards more than 2 deep. Nesting >2 layers creates visual noise.

---

## 3. Design Tokens & Layout

### 3.1 Spacing Grid

All spacing uses a **4dp base unit**, defined in `lib/core/theme/emerge_dimensions.dart`:

| Token | Value | Usage |
|-------|-------|-------|
| `gapSmall` | 8dp (2×) | Between related elements |
| `gapMedium` | 16dp (4×) | Between sections |
| `gapLarge` | 24dp (6×) | Section separation, card margins |
| `gapXLarge` | 32dp (8×) | Screen edge padding, major sections |

**Rule:** Never use odd spacing values. Avoid fractional dp values in layout.

### 3.2 Responsive Breakpoints

Use `LayoutBuilder` or `MediaQuery.sizeOf` (never `OrientationBuilder`, never device-type checks).

| Breakpoint | Width | Layout |
|------------|-------|--------|
| Mobile | < 600dp | Single column, bottom nav |
| Tablet | 600–1199dp | Two column, `NavigationRail` instead of bottom nav |
| Desktop | ≥ 1200dp | Multi-column, `NavigationRail` |

Switch between `BottomNavigationBar` and `NavigationRail` using:

```dart
final width = MediaQuery.sizeOf(context).width;
if (width >= EmergeDimensions.breakpointDesktop) {
  // NavigationRail
} else if (width >= EmergeDimensions.breakpointTablet) {
  // NavigationRail
} else {
  // BottomNavigationBar
}
```

### 3.3 Screen Layout

Every feature screen follows this structure:

```
┌──────────────────────────────┐
│  AppBar (transparent)        │  ← 56dp, transparent bg, elevation: 0
│  ┌─ Title ──── [action] ──┐ │
│  └──────────────────────────┘ │
├──────────────────────────────┤
│                              │
│  Content (scrollable)        │  ← 16dp horizontal padding
│                              │
│  ┌────────────────────────┐  │
│  │    Glass card content   │  │  ← 16dp padding inside card
│  └────────────────────────┘  │
│                              │
├──────────────────────────────┤
│  Bottom Nav (70dp)           │  ← only on tab screens, never on modal routes
└──────────────────────────────┘
```

**Rules:**
- Default horizontal padding: `EmergeDimensions.screenPaddingHorizontal` (16dp)
- Default vertical padding: `EmergeDimensions.screenPaddingVertical` (16dp)
- AppBar is always transparent with `elevation: 0`
- Content area should scroll; never use `SingleChildScrollView` + `Column` for fixed-height screens
- Use `SliverAppBar` + `CustomScrollView` for screens with collapsing headers

### 3.4 Card System

| Card Type | Radius | Elevation | When to Use |
|-----------|--------|-----------|-------------|
| `GlassmorphismCard` | 16dp | Shadow only | General purpose — the default |
| `EmergeGlassCard` | 16dp | Green glow | Primary content, action cards |
| `TodayArcCard` | 16dp | Shadow | Hero progress on timeline |
| Mini card | 12dp | Shadow | Small info chips, badges |
| Sheet | 24dp (top only) | Shadow | Bottom sheets, slide-up cards |

---

## 4. Navigation Architecture

### 4.1 Shell Structure

The app uses one `StatefulShellRoute.indexedStack` for the user shell and a separate `GoRouter` configuration for creator flows.

**User Shell (4 branches):**

| Index | Icon | Label | Route | Screen |
|-------|------|-------|-------|--------|
| 0 | `today_outlined` / `today` | Today | `/timeline` | TimelineScreen (HOME) |
| 1 | `public_outlined` / `public` | World | `/` | WorldMapScreen |
| 2 | `groups_outlined` / `groups` | Tribe | `/social` | PulseFeedScreen |
| 3 | `person_outlined` / `person` | Identity | `/profile` | FutureSelfStudioScreen |

**Icon rule:** Use outlined icons for inactive tabs, filled icons for the active tab. Never use custom icons for bottom nav — only Material symbols.

### 4.2 Tab Persistence

Each shell branch preserves its navigation stack. When switching tabs:

- The previous tab's scroll position is preserved
- No tab rebuilds unless the entire shell is disposed
- State is kept alive via `indexedStack`

### 4.3 Deep Links

Deep-linkable routes (page-backed in go_router):

| Route | Screen | Parent Nav |
|-------|--------|------------|
| `/creators/:id` | CreatorProfileScreen | `_rootNavigatorKey` |
| `/blueprint/:id` | BlueprintDetailScreen | `_rootNavigatorKey` |
| `/challenges` | ChallengesScreen | `_rootNavigatorKey` |
| `/paywall` | PaywallScreen | `_rootNavigatorKey` |

All deep links use `parentNavigatorKey: _rootNavigatorKey` to appear above the shell, not inside a tab.

### 4.4 Navigation UX Rules

| Rule | Rationale |
|------|-----------|
| Never use `Navigator.push` for tab-internal screens | Breaks deep linking |
| Use `context.goNamed()` for shell routes, `context.push()` for modals | Correctly manages shell state |
| `GoRouter` redirect must never `ref.watch` | Creates rebuild loops — use `ref.read` inside a `try/catch` |
| Wrap all `ref.read` in redirect with `try/catch` returning `null` | Prevents web `setState` during build race |
| Hold current path during role-claim race window | Router must not yank user before `setUserRole` resolves |

### 4.5 Transition Animations

| Route Type | Transition | Duration |
|------------|-----------|----------|
| Shell tab switch | Instant (no transition) | 0ms |
| Push route (deep link) | Slide up (Material) | 300ms |
| Bottom sheet | Slide up + fade | 300ms |
| Dialog | Fade + scale | 200ms |
| Hero (shared element) | `MaterialRectCenterArcTween` | 300ms |

---

## 5. State Management UX Patterns

### 5.1 The Three-State Contract

Every Riverpod provider that fetches data MUST expose three states through `AsyncValue`:

```dart
@riverpod
Stream<List<Habit>> todayHabits(Ref ref) { ... }

// Consumer reads:
final habitsAsync = ref.watch(todayHabitsProvider);
return habitsAsync.when(
  loading: () => const EmergeLoadingSkeleton(...),  // NEVER CircularProgressIndicator
  error: (e, _) => AppErrorWidget(message: ..., onRetry: () => ref.invalidate(...)),
  data: (habits) => habits.isEmpty
    ? EmptyStateWidget(...)  // NEVER blank screen
    : HabitsList(habits),
);
```

**Rule:** These three states (loading, error, data) must be handled for every async provider. The `data` branch must also handle the empty-array case with a meaningful empty state.

### 5.2 Loading States

| Scenario | UI Pattern | Widget |
|----------|-----------|--------|
| Content loading (list) | Shimmer skeleton matching content shape | `EmergeLoadingSkeleton` |
| Content loading (card) | Shimmer placeholder with correct border radius | `_ShimmerBox` |
| Button action | Button shows spinner, disables interaction | `IconData` → `CircularProgressIndicator` inside button |
| Page transition | Content stays (no flash); skeleton overlays new data | In-place replacement |
| Pull-to-refresh | Standard refresh indicator | `RefreshIndicator` |

**Anti-patterns:**
- ❌ Full-screen `CircularProgressIndicator` (spinner = "I have no idea what's loading")
- ❌ Blank white/black screen during load
- ❌ "Flash of loading" — if data resolves in <200ms, skip the loading state entirely

### 5.3 Empty States

Never show a blank screen. Every empty state must have:

1. **An illustration** (icon or asset, min 64×64dp)
2. **A title** explaining why the content is absent ("No habits yet")
3. **A subtitle** explaining what to do ("Tap + to create your first habit")
4. **A call-to-action** button ("Create Habit")

```dart
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback? onAction;
  // ...
}
```

### 5.4 Error States

| Error Type | UI Pattern | Duration |
|-----------|-----------|----------|
| Network failure | `AppErrorWidget` with retry button | Persistent until dismissed or retried |
| Sync failure | SnackBar with retry action | 4s (auto-dismiss) + action |
| Form validation | Inline error below field | Persistent until fixed |
| Write failure | SnackBar with undo + retry | 6s + action |
| Auth expiry | Full-screen re-auth prompt | Persistent, cannot dismiss |

**Error message rules:**
- Explain what happened in plain language
- Tell the user what to do next
- Never use technical jargon (no "HTTP 500", no "null reference")
- Never blame the user ("You caused an error")
- Always provide a recovery path (retry, go back, contact support)

### 5.5 Optimistic Updates

The app uses optimistic updates for habit completion (defined in `DashboardStateNotifier`):

```dart
// Pattern:
1. Update local state immediately (optimistic)
2. Write to Drift (local-first)
3. Enqueue sync to Firestore (background)
4. On failure: rollback optimistic state + show error SnackBar
5. On success: confirm state (no UI change needed)
```

**Rules:**
- Every optimistic update must have a rollback path
- Show success feedback immediately (particles, haptic, card state change)
- On failure, the SnackBar must say "Couldn't sync — will retry later" (not "Error saving")
- Never block the UI waiting for Firestore

### 5.6 Offline-First Pattern

```dart
// Always:
1. Return data from Drift (local SQLite) immediately
2. Trigger Firestore sync in the background (non-blocking)
3. If Drift has no data AND network is unavailable → show cached-or-empty state
4. Never await a Firestore read before rendering

// Drift queries must scope by userId:
database.habitDao.watchAll().watchWhere((t) => t.userId.equals(userId));
```

---

## 6. Animation & Micro-interactions

### 6.1 Duration Tokens

| Token | Duration | Usage |
|-------|----------|-------|
| `animationFast` | 150ms | Toggle states, color transitions, opacity changes |
| `animationMedium` | 200ms | Standard micro-interactions, button feedback |
| `animationSlow` | 300ms | Screen transitions, card expansions |
| Maximum (Material 3 cap) | 550ms | Complex sequences — never exceed this |

### 6.2 Animation Guidelines

**Prefer implicit animations** (Flutter built-ins) over explicit controllers:

| Need | Widget |
|------|--------|
| Color/size/shape change | `AnimatedContainer` |
| Widget swap (state toggle) | `AnimatedSwitcher` + `ValueKey` |
| Visibility | `AnimatedOpacity` |
| Layout shift | `AnimatedPadding`, `AnimatedPositioned` |
| Custom progress | `TweenAnimationBuilder` |

**When to use explicit `AnimationController`:**

- Staggered sequences (multiple properties animating at different intervals)
- Particle effects (`completion_particles.dart`)
- Looping ambient animations (Narrator pulse, nebula drift)
- Hero transitions

### 6.3 Micro-interaction Catalog

| Interaction | Animation | Duration | Target |
|------------|-----------|----------|--------|
| Habit complete tap | Particle burst (30-50 particles, archetype-colored) | 800ms | Tap point |
| Habit complete | Card shifts to dimmed state + checkmark draw | 200ms | Card |
| Button press | Scale to 0.96 + color shift | 150ms | Button |
| Bottom nav switch | Icon morph (outlined → filled) | 200ms | Icon |
| Card appearance | Fade in + slide up (20dp) | 300ms | Card |
| Narrator pulse (idle) | Subtle glow oscillation | 2s loop | Avatar |
| Progress fill | Width/height tween | 300ms | Bar/ring |
| Sheet appearance | Slide up (full height) + opacity | 300ms | Sheet |
| Error shake | Horizontal shake 3px, 3 cycles | 300ms | Widget |

### 6.4 Particle System

The `completion_particles.dart` widget implements a lightweight `CustomPainter`-based particle system:

```dart
// Rules:
- 30-50 particles on trigger
- Archetype-colored (map archetype to particle color)
- Gravity + fade over 800ms
- No physics engine dependency
- One instance per completion event, auto-disposed
```

### 6.5 Scroll Behavior

- Lists use `ListView.builder` (never `ListView(children: [...])`)
- Long lists (>30 items) should paginate or window
- Pull-to-refresh on data-driven screens
- Scroll position should be preserved when switching tabs (handled by `indexedStack`)
- On scroll, AppBar can collapse but never fully disappear (user must always know where they are)

---

## 7. Accessibility

### 7.1 Touch Targets (WCAG AAA)

**Every interactive element** must have a minimum touch target of 44×44dp.

```dart
// Use EmergeTappable for all custom tappable areas:
EmergeTappable(
  label: 'Complete habit',
  hint: 'Marks this habit as done for today',
  onTap: () => ...,
  child: YourWidget(),
)
```

| Element | Min Target | Notes |
|---------|-----------|-------|
| Buttons (all types) | 48×48dp | Flutter minimum |
| Icon buttons | 44×44dp | Use `EmergeIconLabel` padding |
| List items | 48×44dp | Full row height |
| Bottom nav items | 48×44dp | Applies per item |
| Slider thumbs | 48×48dp | Interactive only |
| Chips | 44×44dp | Per chip |

### 7.2 Color & Contrast

- All text must meet WCAG AA contrast ratio of **4.5:1** against its background
- The primary green `#2BEE79` on `#0A0A1A` (cosmic void) — test contrast; if it fails, use `#4ADE80` instead for text
- Never use color alone to convey state (add icon, text, or pattern)
- Support grayscale mode — all UI must remain functional without color

### 7.3 Screen Reader Support

Every custom widget must have a `Semantics` wrapper:

| Widget | Semantics Properties |
|--------|---------------------|
| Button | `label`, `hint`, `button: true`, `enabled` |
| Toggle | `label`, `checked/selected`, `enabled` |
| Progress | `label`, `value` (percentage string) |
| Decorative image | `ExcludeSemantics` |
| Custom gesture | `label`, `hint` describing the gesture |

Use `EmergeSemantics` for all custom widgets. For Flutter built-in widgets, prefer the default semantics (they're already accessible).

### 7.4 Reduced Motion

Respect the platform's reduced-motion setting:

```dart
final isReducedMotion = MediaQuery.of(context).disableAnimations;
// When true: disable all non-essential animations (skip to end state).
// Particle effects, ambient animations, and decorative sequences must be disabled.
// Essential transitions (sheet open/close, page transitions) can remain at minimum duration.
```

### 7.5 Focus Management

- Focusable elements must be reachable via Tab/arrow key navigation
- Custom focusable widgets use `Focus` + `FocusNode`
- Modal sheets and dialogs trap focus internally
- When a modal closes, restore focus to the triggering element

---

## 8. Gesture & Touch Patterns

### 8.1 Standard Gesture Map

| Action | Gesture | Widget |
|--------|---------|--------|
| Primary action | Tap | `ElevatedButton`, `InkWell`, `EmergeTappable` |
| Secondary action | Long press | `GestureDetector.onLongPress` |
| Item removal | Swipe left | `Dismissible` |
| Scroll | Vertical drag | `ListView.builder` (built-in) |
| Pinch zoom | Pinch | `InteractiveViewer` |
| Dismiss sheet | Swipe down | `DraggableScrollableSheet` or built-in bottom sheet |

### 8.2 Gesture Rules

- Every tap target must show visual feedback on `onTapDown` (ripple, color shift, or scale)
- Use `InkWell` / `InkResponse` for Material ripples — never use `GestureDetector` for simple taps
- Swipe-to-dismiss must update the data source in `onDismissed` (or item reappears)
- Never mix `onPan` and `onHorizontalDrag`/`onVerticalDrag` on the same widget (crashes)
- Custom gestures must not conflict with system navigation (iOS screen-edge swipe, Android back gesture)
- Bottom sheet dismiss must require a pull-down gesture (not a tap-outside — that's the back button's role)

### 8.3 Touch Feedback by Component

| Component | Tap Feedback |
|-----------|-------------|
| Primary button | Scale 0.96 → spring back (150ms) |
| Secondary button | Color opacity change |
| Card | Elevation lift + subtle scale |
| List item | Background color shift |
| Bottom nav tab | Icon morph (outlined → filled) |
| FAB | Ripple + scale |
| Chip | Color fill + scale |

---

## 9. Component Design System

### 9.1 Core Components

Reusable components live in `lib/core/presentation/widgets/`. Every new feature screen must use these before creating custom components.

| Component | File | Purpose |
|-----------|------|---------|
| `GlassmorphismCard` | `glassmorphism_card.dart` | Frosted-glass content container |
| `EmergeGlassCard` | `glassmorphism_card.dart` | Themed variant with green glow |
| `EmergeLoadingSkeleton` | `emerge_loading_skeleton.dart` | Shimmer loading placeholders |
| `AppErrorWidget` | `app_error_widget.dart` | Error state with optional retry |
| `EmergeSemantics` | `emerge_semantics.dart` | Accessibility label wrapper |
| `EmergeTappable` | `emerge_semantics.dart` | Accessible tap target (44dp min) |
| `EmergeIconLabel` | `emerge_semantics.dart` | Icon with accessibility label |
| `EmergeProgressIndicator` | `emerge_semantics.dart` | Accessible progress bar/ring |
| `WorldBackground` | `world_background.dart` | Full-screen environment layer |
| `CompletionParticles` | `completion_particles.dart` | Particle burst on habit complete |
| `OfflineBanner` | `offline_banner.dart` | Connectivity status banner |
| `WebUpdateBanner` | `web_update_banner.dart` | Web app update prompt |

### 9.2 Component Creation Rules

1. **Reuse before build** — check if a core component already satisfies the need
2. **One file per component** — no monolithic widget files
3. **Feature-specific components** live in `features/<feature>/presentation/widgets/`
4. **Cross-feature components** live in `core/presentation/widgets/`
5. **Each component must have a widget test**

### 9.3 Empty State Component

```dart
class EmergeEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmergeEmptyState({
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });
  // Renders: centered Column with icon (64dp), title (Headline),
  // subtitle (Body M), and optional action button.
}
```

**Note:** This component should be created if it doesn't exist yet — it's currently done inline in various screens.

---

## 10. Form UX Patterns

### 10.1 Form Structure

| Element | Widget | Purpose |
|---------|--------|---------|
| Form container | `Form` + `GlobalKey<FormState>` | Validation, save, reset |
| Text input | `TextFormField` | All text entry |
| Selection | `DropdownButtonFormField` or custom picker | Single selection |
| Toggle | `Switch` | Binary choices |
| Multi-select | `Wrap` + `FilterChip` | Archetype, habit attributes |
| Date | `showDatePicker` | Date selection |
| Time | `showTimePicker` | Time selection |

### 10.2 Validation Rules

| Rule | Implementation |
|------|---------------|
| Validate on submit | `formKey.currentState!.validate()` |
| Real-time feedback | `AutovalidateMode.onUserInteraction` |
| Errors below field | Default `TextFormField` behavior |
| Never over-validate | Don't show errors on untouched fields |
| Validators are pure | No side effects in `validator` callbacks |

### 10.3 Keyboard Handling

| Scenario | Pattern |
|----------|---------|
| Dismiss on tap-outside | `FocusScope.of(context).unfocus()` on background tap |
| Focus next field | `FocusScope.of(context).nextFocus()` from action button |
| Form submit from keyboard | `TextInputAction.next` on all fields except last |
| Last field action | `TextInputAction.done` → trigger form submit |
| Keyboard-aware layout | `resizeToAvoidBottomInset: true` on Scaffold |
| Long form scroll | Ensure last field is visible when keyboard opens |

### 10.4 Input Styling (Dark Theme)

```dart
InputDecorationTheme(
  filled: true,
  fillColor: surfaceDark,         // #222222
  border: OutlineInputBorder(
    borderRadius: 12,
    borderSide: BorderSide.none,
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: 12,
    borderSide: BorderSide.none,
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: 12,
    borderSide: BorderSide(color: archetypePrimaryColor, width: 2),
  ),
  labelStyle: TextStyle(color: textSecondaryDark),
  hintStyle: TextStyle(color: textSecondaryDark.withValues(alpha: 0.5)),
  errorStyle: TextStyle(color: errorColor),
)
```

---

## 11. Feedback & Notification Patterns

### 11.1 Feedback Hierarchy

| Urgency | Pattern | Duration | Action |
|---------|---------|----------|--------|
| Success (transient) | Inline state change + optional haptic | Instant | None — state speaks for itself |
| Success (confirm) | SnackBar, no action | 3s | None |
| Info | SnackBar or inline | 4s | Optional |
| Warning | SnackBar with action | 6s | Retry or dismiss |
| Error (recoverable) | SnackBar with retry | 6s | Retry button |
| Error (critical) | `AppErrorWidget` | Persistent | Retry or nav back |
| System status | Banner at top of screen | Persistent | None |

### 11.2 SnackBar Usage

```dart
// Transient success (no undo possible)
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('Habit completed')),
);

// Actionable feedback (undo available)
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('Habit deleted'),
    action: SnackBarAction(label: 'Undo', onPressed: () => habit.restore()),
  ),
);
```

**SnackBar rules:**
- Keep messages brief (≤60 characters)
- One line only — never truncate or scroll
- Action labels are imperative ("Undo", "Retry", "Dismiss")
- Never stack multiple SnackBars — cancel previous if new one appears

### 11.3 Banner Usage

Use `MaterialBanner` for system-level status:

| Banner | Trigger | Action |
|--------|---------|--------|
| `OfflineBanner` | Connectivity lost | Dismiss or retry |
| `WebUpdateBanner` | New version available | "Update" button |
| Premium upsell | Free user hits gated feature | "Upgrade" button |

Banners appear below the AppBar and persist until dismissed. Only one banner at a time (highest priority wins).

### 11.4 Haptic Feedback

| Interaction | Haptic Pattern |
|------------|---------------|
| Habit complete | `HapticFeedback.mediumImpact()` |
| Level up | `HapticFeedback.heavyImpact()` (multi-pulse) |
| Error | `HapticFeedback.heavyImpact()` |
| Success (minor) | `HapticFeedback.lightImpact()` |
| Toggle | `HapticFeedback.selectionClick()` |

### 11.5 The Narrator as Feedback

The Narrator is the app's character-driven feedback system — see `docs/design/narrator-ux.md` for full spec. Key rules:

- Narrator fires on ≤9 triggers (down from 13)
- Typewriter animation is removed everywhere — text renders instantly
- Free users see generic lines; Pro users see personalized data-grounded lines
- The Narrator never interrupts onboarding
- The persistent `NarratorAvatar` (44dp, top-right of timeline) is the only always-visible narrator surface
- Tap avatar → sheet opens instantly (≤200ms perceived)

---

## 12. Habitual Engagement Model

### 12.1 The Hook Loop

The app drives engagement through Nir Eyal's Hook Model:

```
TRIGGER → ACTION → VARIABLE REWARD → INVESTMENT
  │          │            │               │
  │          │            │               └─ "What will my world look
  │          │            │                  like tomorrow?" → opens app
  │          │            │
  │          │            └─ Surprise events: NPC visits, weather
  │          │               shifts, discovery bursts, biome changes
  │          │
  │          └─ <2s completion: widget tap, notification action,
  │             one-tap on timeline card + particles + haptic
  │
  └─ Notification, widget glance, time-of-day reminder
```

### 12.2 Completion Flow

```
User wakes up → sees widget → taps [✓] on morning habit
    ↓
HabitCompletionService.markComplete(habitId, source: widget)
    ↓
Local state updates (optimistic, <1ms)
    ↓
Particle burst + haptic on widget (non-app)
    ↓
If app opens → Timeline shows completed state + progress ring update
    ↓
Drift updated (offline-first)
    ↓
Sync queue enqueues for Firestore (background, non-blocking)
```

### 12.3 World Events (Variable Reward)

Maintain engagement through unpredictable positive events:

| Event | Trigger | Experience |
|-------|---------|-----------|
| Traveler Visit | 5-day streak | NPC on world map with message |
| Weather Shift | Daily random (seeded) | Rain/sun/storm transforms map |
| Discovery Burst | Momentum ≥ 0.9 | Hidden area + XP bonus |
| Biome Transition | Level milestone | World season shifts |
| Tribe Convergence | Top 10% consistency | Neighboring region appears |

### 12.4 Anti-Patterns (Explicitly Forbidden)

| Anti-pattern | Why | Instead |
|-------------|-----|---------|
| Streak shaming | Creates guilt, reduces retention | Momentum system with forgiveness |
| Confirmation dialogs for habitual actions | Adds friction to repeated behavior | Undo in SnackBar |
| Full-screen loading spinners | Opaque, anxiety-inducing | Skeleton loaders with content shape |
| Typewriter text anywhere | Feels slow, dated, AI-generated | Instant render or shimmer-then-fallback |
| Narrator on every app open | Desensitizes user, kills signal | 9 triggers max, cooldown enforced |

---

## 13. Platform Considerations

### 13.1 Platform-Specific Patterns

| Pattern | iOS | Android |
|---------|-----|---------|
| Page transition | Slide right → left | Slide up (Material) |
| Date picker | CupertinoDatePicker | Material date picker |
| Time picker | CupertinoTimerPicker | Material time picker |
| Bottom sheet | Drag to dismiss | Drag to dismiss (same) |
| Back navigation | Swipe from left edge | System back button/gesture |
| Haptic vibration | Core Haptics | VibrationService |
| Live Activities | Supported (iOS 17+) | Not available |
| Home screen widgets | WidgetKit | App Widgets |

### 13.2 Google Sign-In Fork

```dart
if (kIsWeb) {
  // Use signInWithRedirect(GoogleAuthProvider())
} else {
  // Use GoogleSignIn.instance.authenticate() + credential
}
// Never unify these paths.
```

### 13.3 Web-Specific Rules

| Issue | Fix |
|-------|-----|
| `setState` during build in redirect | Wrap `ref.read` in `try/catch` returning `null` |
| Back button behavior | `GoRouter` handles web history automatically |
| No haptic | Skip haptic calls on web |
| No Live Activities | Skip Live Activity registration on web |
| Progressive Web App | Ensure manifest and service worker are configured |

---

## 14. Edge Cases

### 14.1 Data Edge Cases

| Edge Case | Pattern |
|-----------|---------|
| User has no archetype selected | Default to "Explorer" theme, prompt archetype selection at first opportunity |
| Role is `null`/`unknown` (post-signup race) | Router holds current path; no redirect until resolved |
| Firestore write fails | Optimistic state + SnackBar with retry; Drift is source of truth |
| Drift read returns stale data | Always show Drift data first; Firestore sync updates silently in background |
| Multiple users on same device | Drift queries scoped by `userId` — never read without filter |
| `createdAt` is a `Timestamp` not `DateTime` | Check `createdAtRaw is Timestamp`, use `.toDate()`, fall back to `DateTime.now()` |
| Deep link to non-existent resource | Navigate to the resource's parent screen with a SnackBar error |

### 14.2 UI Edge Cases

| Edge Case | Pattern |
|-----------|---------|
| Very long habit name | Truncate at 2 lines with ellipsis; full text on tap |
| Very short screen (small device) | Scrollable content; never clip or overflow |
| Keyboard overlapping content | `resizeToAvoidBottomInset: true` + `SingleChildScrollView` |
| Orientation change mid-flow | Layout rebuilds via `LayoutBuilder`; state preserved via Riverpod |
| App backgrounded during mutation | Sync queue persists in Drift; processes on foreground |
| First launch with no data | Onboarding flow handles this — never show empty main screen |
| Mid-onboarding app kill | Onboarding milestones persisted; resume at last completed step |
| Notification tapped without app open | Deep link to relevant screen; never show blank scaffold |

### 14.3 Performance Edge Cases

| Edge Case | Pattern |
|-----------|---------|
| 100+ habits | Paginate or virtualize; never render all at once |
| Complex world map with many nodes | Use `RepaintBoundary` per node; cull offscreen nodes |
| Frequent Firestore updates | Batch writes; throttle at 1s intervals |
| Large particle effects (10+ simultaneous) | Cap active particle systems at 3; recycle oldest |
| Deeply nested glassmorphism (>2 layers) | Replace inner layers with solid surface color |

### 14.4 Accessibility Edge Cases

| Edge Case | Pattern |
|-----------|---------|
| Screen reader on complex gesture | Provide alternative tap-based interaction |
| Large text scaling (200%) | All layouts must be tested at 200% font size |
| High contrast mode | Respect platform `AccessibilityFeatures.highContrast` |
| Color blindness | Never use color alone for state; add icon or pattern indicators |

---

## 15. Copy & Content Standards

### 15.1 Voice Principles

| Principle | Do | Don't |
|-----------|----|-------|
| Active voice | "Complete your habit" | "Your habit can be completed" |
| Second person | "Your world is thriving" | "The world is thriving" |
| Brief | "3 of 5 done" | "You have completed 3 out of 5 habits" |
| Warm but not cutesy | "Great streak going!" | "You're a super-duper star! ⭐⭐⭐" |
| Specific | "Tuesday is your strongest day" | "You're doing well" |

### 15.2 Error Copy Formula

```
[What happened] + [What to do about it]
```

| Context | Formula | Example |
|---------|---------|---------|
| Network | "Couldn't load [thing]. Check your connection and try again." | "Couldn't load habits. Check your connection and try again." |
| Save failure | "Couldn't save [thing]. [Action]." | "Couldn't save reflection. Tap to retry." |
| Auth error | "Couldn't sign in. [Action]." | "Couldn't sign in. Check your email and password." |
| Empty state | "No [thing] yet. [Action]." | "No habits yet. Tap + to create your first one." |

### 15.3 Button Labels

- Imperative verb: "Save", "Complete", "Create", "Delete"
- Consistent across flow: "Publish" button → "Published" toast
- Never "Submit" (system language, not user language)
- Never "OK" (vague, dismissive — use specific action)
- Destructive actions: "Delete" (red), not "Remove" — be precise

### 15.4 Empty State Copy

| Screen | Title | Subtitle | Action |
|--------|-------|----------|--------|
| Timeline (no habits) | "No habits yet" | "Create your first habit to start building your future self" | "Create Habit" |
| Timeline (all done) | "All done! 🎉" | "You've completed everything for today" | "View World" |
| World Map (empty) | "Your world is waiting" | "Complete habits to bring it to life" | "Go to Timeline" |
| Social (no friends) | "No connections yet" | "Invite friends or join a tribe" | "Find Tribes" |
| Profile (no data) | "Your story starts here" | "Complete your first habit to begin" | "Go to Timeline" |
| Reflections (empty) | "No reflections yet" | "Evening check-ins help you see how far you've come" | "Log Tonight" |

---

## Document Maintenance

- This document is the single source of truth for design decisions in emerge_app
- All new features must have a design review pass referencing this document
- Update this document when design decisions change — do not let it drift
- Version bumps: minor for additions, major for breaking changes to tokens or principles
- File issues in the `emerge_app` repo for proposed changes

---

**Referenced from:** `AGENTS.md` (see "Design Authority" section)  
**Related documents:** `docs/superpowers/specs/*.md`, `docs/ARCHITECTURE.md`  
**Last updated:** 2026-07-11
