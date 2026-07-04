# Narrator Glass Dialog, Tribe Drift-First, & Performance Fixes — Spec

## Summary

1. **Narrator**: Replace modal bottom sheet with centered, expanding glassmorphic dialog. Remove all remaining old node-guide (`_WorldMapCoachMark`) code.
2. **Onboarding redirect**: Land on Timeline (`/timeline`) instead of World Map (`/`).
3. **Tribe lobby drift-first**: Eliminate Firestore permission errors by making tribe data work entirely from local Drift, with Firestore as optional background sync.
4. **Performance**: Fix typewriter rebuild scope, fix narrator entry/exit animation efficiency.

---

## 1. Remove Old Node Guide Remnants

### 1.1 `world_map_screen.dart`

Delete from `_WorldMapScreenState`:

- `Timer? _initTimer` field
- `bool _showFirstVisitGuide` field
- `_initTimer` setup in `initState` (currently lines 48–62)
- `_initTimer?.cancel()` in `dispose`
- `if (_showFirstVisitGuide) _WorldMapCoachMark(...)` rendering
- Entire `_WorldMapCoachMark` and `_WorldMapCoachMarkState` classes

**Replace with:** A first-visit trigger that calls `NarratorSheet.show()` with `NarratorTrigger.screenFirstVisit`, following the same pattern as `level_immersive_screen.dart:_checkFirstNodeVisit()`.

Remove now-unused imports (`companion_repository`, `companion_providers`, `companion_enums`).

### 1.2 `local_settings_repository.dart`

Keep `getHasSeenNodeGuide` / `setHasSeenNodeGuide` — used by `level_immersive_screen.dart`.

---

## 2. NarratorSheet → Centered Glass Dialog

### 2.1 Entry point

Replace `showModalBottomSheet(...)` with `showDialog(...)`:

```dart
static Future<void> show(
  BuildContext context,
  NarratorAppearance appearance, {
  void Function(String buttonLabel, String? typedText)? onResponse,
}) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black54,
    builder: (_) => NarratorSheet(
      appearance: appearance,
      onResponse: onResponse,
    ),
  );
}
```

### 2.2 Container / Card

- Outer: `BackdropFilter` with `ImageFilter.blur(sigmaX: 12, sigmaY: 12)` + `Colors.white.withOpacity(0.08)` background.
- Border: 1px `Colors.white.withOpacity(0.15)`, radius 20.
- Box shadow: green glow (`#2BEE79`) matching `EmergeGlassCard` pattern.
- Width: 85% of screen width, max 400px.
- Positioned center-screen via `Align` or `Center` inside the dialog.

### 2.3 Size animation — expand with text

Wrap the content column in `AnimatedSize` (`duration: 300ms, curve: Curves.easeOut`).

- Initial state (before typewriter reveals text): shows only header (pulse + EMERGE).
- As `_displayedText` grows, `AnimatedSize` smoothly expands the container.
- Action buttons still fade in after text completes via `AnimatedOpacity`.

This prevents a blank card from appearing before there's content.

### 2.4 Entry animation

- `FadeTransition` + `ScaleTransition` wrapping the entire card.
- `AnimationController` 400ms, `Curves.easeOut` — same feel as the old coach mark.

### 2.5 Skip button

- Positioned top-right inside the card.
- Small "×" icon, opacity 0.3, no background, minimal hit area.
- Only visible while typewriter is typing (`!_textComplete`).
- On tap: instantly reveals all remaining text, triggers `onComplete`, shows action buttons. Does NOT dismiss.

### 2.6 Content (unchanged from current)

- Header: `NarratorPulseIndicator` + "EMERGE" text.
- Typewriter text.
- Optional text field (evening reflection).
- Action buttons (fade in after text completes).
- Dismiss: barrier tap, or tapping an action button.

### 2.7 Dismiss behavior

- Barrier dismiss allowed.
- Calls `widget.onResponse` (null button label) and `narratorStateProvider.notifier.dismiss()`.
- Exit animation: reverse the entry `FadeTransition` + `ScaleTransition`.

---

## 3. Onboarding Redirect Fix

### 3.1 `world_reveal_screen.dart`

Change:
```dart
context.go('/');
```
→
```dart
context.go('/timeline');
```

### 3.2 `router.dart` `decideRedirect`

Change line 217:
```dart
if (isOnAuthPath) return '/';
```
→
```dart
if (isOnAuthPath) return '/timeline';
```

---

## 4. Tribe Lobby — Drift-First (Fix Firestore Permission Error)

### 4.1 Root cause

`DriftTribeRepository.watchArchetypeClubs()` (drift_tribe_repository.dart:45–140) uses a `StreamController` that **waits for both local and remote** before emitting merged data:

```dart
void emitMerged() {
  if (!localReady || !remoteReady) return;  // blocks UI
  ...
}
```

The remote subscription does:
```dart
_firestore.collection('tribes')
    .where('type', isEqualTo: TribeType.official.name)
    .snapshots()
```

If this query fails (permission denied, missing composite index, network timeout), the error handler sets `remoteReady = true` and falls back to local. **But** if the Firestore listener silently hangs or the initial snapshot is delayed, the merged stream never emits and the user sees an infinite loading spinner.

Additionally, `TribeLobbyScreen` and `AllTribesScreen` both use `allArchetypeClubsProvider` which depends on this stream. A Firestore failure at this point blocks the entire social tab.

### 4.2 Fix: emit local immediately, merge remote asynchronously

Change `watchArchetypeClubs()` to:

1. **Emit local data immediately** from Drift (no waiting for remote).
2. **Start remote listener in the background** — when remote data arrives, re-emit merged.
3. **Remote failure is non-blocking** — log the error, never block the stream.
4. **Add a timeout** (5s) to the remote fetch; if it doesn't arrive in time, emit local data and keep listening for remote in the background.

### 4.3 Same fix for `worldLeaderboardProvider`

The `worldLeaderboardProvider` in `tribes_provider.dart` has the same pattern (lines 207–319). Apply the same fix: emit local data immediately, merge remote when it arrives.

### 4.4 Firestore rules note

The current rules allow `read: if true` on `/tribes/{tribeId}` — world-readable. If the issue is a missing composite index for `.where('type', ...)`, the drift-first approach sidesteps this entirely because the UI never blocks on Firestore. The index can be created later for the background sync.

### 4.5 Seed data verification

Ensure `OfficialClubsSeed` contains all expected archetype clubs so local-only mode shows a complete list. The seed currently covers: athlete, scholar, strategist, creator. Verify all user archetypes are represented.

---

## 5. Typewriter Performance Fix

### 5.1 Current problem

`NarratorTypewriter` calls `setState()` on every character (36 calls/sec at 28ms). This rebuilds the entire widget tree of the NarratorSheet on each tick.

### 5.2 Fix

Replace `setState` + `_displayedText` with a `ValueNotifier<String>` owned by the typewriter state:

- `_displayedTextNotifier = ValueNotifier<String>('')`
- Timer ticks update `_displayedTextNotifier.value = ...`
- Build returns `ValueListenableBuilder<Text>` that only rebuilds the `Text` widget.
- The `onComplete` callback still fires when the full text is revealed.

This scopes rebuilds to just the `Text` widget instead of the entire narrator dialog.

### 5.3 Narrator entry animation

Ensure the `AnimationController` is disposed properly and the `TickerProvider` is used correctly. Current `NarratorSheet` is `ConsumerStatefulWidget` — if converting to dialog, ensure it still has a valid `vsync` (the dialog `builder` provides a `BuildContext` that can reach a `TickerProvider`).

---

## 6. Files Changed

| File | Change |
|------|--------|
| `lib/features/world_map/presentation/screens/world_map_screen.dart` | Remove old coach mark, add narrator first-visit |
| `lib/features/narrator/presentation/widgets/narrator_sheet.dart` | Bottom sheet → centered glass dialog, AnimatedSize, skip button |
| `lib/features/narrator/presentation/widgets/narrator_typewriter.dart` | Performance: ValueNotifier + ValueListenableBuilder |
| `lib/features/onboarding/presentation/screens/world_reveal_screen.dart` | `'/'` → `'/timeline'` |
| `lib/core/router/router.dart` | `return '/'` → `return '/timeline'` |
| `lib/core/drift_repositories/drift_tribe_repository.dart` | Emit local immediately, background remote merge |
| `lib/features/social/presentation/providers/tribes_provider.dart` | Same drift-first fix for worldLeaderboardProvider |

---

## 7. Not In Scope (for this pass)

- Changing Firestore security rules (drift-first approach makes this less urgent).
- Social features beyond tribe lobby loading (friends, challenges, partner matching).
- General app performance outside the narrator and tribe loading paths.
