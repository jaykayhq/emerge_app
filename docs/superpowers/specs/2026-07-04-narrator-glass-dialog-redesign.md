# Narrator Glass Dialog Redesign — Spec

## Summary

Replace the narrator modal bottom sheet with a centered, expanding glassmorphic dialog. Remove all remaining old node-guide (`FeatureCoachMark` / `_WorldMapCoachMark`) code from `world_map_screen.dart`. Fix onboarding redirect to land on Timeline instead of World Map. Improve typewriter performance.

---

## 1. Remove Old Node Guide Remnants

### 1.1 `world_map_screen.dart`

Delete the following from `_WorldMapScreenState`:

- `Timer? _initTimer` field (line 39)
- `bool _showFirstVisitGuide` field (line 43)
- `_initTimer` setup in `initState` (lines 48-62)
- `_initTimer?.cancel()` in `dispose` (line 67)
- `if (_showFirstVisitGuide) _WorldMapCoachMark(...)` rendering (lines 189-193)
- The entire `_WorldMapCoachMark` and `_WorldMapCoachMarkState` classes (lines 896-970+)

**Replace with:** A first-visit trigger that calls `NarratorSheet.show()` with a `NarratorTrigger.screenFirstVisit` appearance, following the same pattern as `level_immersive_screen.dart:_checkFirstNodeVisit()` — but for the world map screen itself.

Remove imports that are no longer needed (`companion_repository`, `companion_providers`, `companion_enums` — verify).

### 1.2 `local_settings_repository.dart`

Keep `getHasSeenNodeGuide` / `setHasSeenNodeGuide` / `resetTutorials` — these are used by `level_immersive_screen.dart`'s narrator-based node guide. No change.

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
- Border: `Colors.white.withOpacity(0.15)` at 1px width.
- Border radius: 20.
- Box shadow: optional glow (same pattern as `GlassmorphismCard`).
- Width: constrained to ~85% of screen width, max 400px.
- Positioned center-screen via `Align` or `Center` inside `Dialog`.

### 2.3 Size animation — expand with text

Wrap the content column in `AnimatedSize` (`duration: 300ms, curve: Curves.easeOut`).

- Initial state (before typewriter starts / first chars): shows only the header row (pulse + EMERGE).
- As `_displayedText` grows, `AnimatedSize` smoothly expands the container height.
- Action buttons still fade in after text completes (`AnimatedOpacity`).

This prevents a blank large card from appearing before there's text to read.

### 2.4 Entry animation

- Use `FadeTransition` + `ScaleTransition` (or `AnimatedScale`) for the card entry — same feel as the old coach mark.
- `AnimationController` with 400ms, `Curves.easeOut`.

### 2.5 Skip button

- Positioned top-right inside the card (not outside).
- Small "×" icon.
- Opacity: 0.3, no background, minimal size.
- Only visible while typewriter is still typing (`!_textComplete`).
- Fades out with `AnimatedOpacity` when text completes.
- On tap: instantly reveals all remaining text, triggers `onComplete`, and shows action buttons. Does NOT dismiss the dialog — that's the user's choice via action buttons or barrier tap.

### 2.6 Content structure (unchanged)

- Header: `NarratorPulseIndicator` + "EMERGE" text.
- Typewriter text (with `onComplete` callback).
- Optional text field (evening reflection).
- Action buttons (fade in after text completes).
- Dismiss: tapping outside the card (barrier dismiss) or tapping action buttons dismisses.

### 2.7 Dismiss behavior

- Barrier dismiss: allowed.
- On dismiss: call `widget.onResponse` if set (with null button label) and `narratorStateProvider.notifier.dismiss()`.

---

## 3. Onboarding Redirect Fix

### 3.1 `world_reveal_screen.dart` line 116

Change:
```dart
context.go('/');
```
To:
```dart
context.go('/timeline');
```

### 3.2 `router.dart` `decideRedirect` line 217

Change:
```dart
if (isOnAuthPath) return '/';
```
To:
```dart
if (isOnAuthPath) return '/timeline';
```

This ensures that after onboarding completion, the user lands on Timeline (the intended home/daily command center) rather than the World Map.

---

## 4. Typewriter Performance

### 4.1 Current problem

`NarratorTypewriter` calls `setState()` on every character (36 calls/sec at 28ms). This rebuilds the entire `Text` widget 36 times per second, causing unnecessary widget tree rebuilds in the host screen.

### 4.2 Fix

Replace `setState` + `Timer` with a `ValueNotifier<String>`:

- `_displayedTextNotifier = ValueNotifier<String>('')`
- Timer ticks update `_displayedTextNotifier.value`
- The `build()` method uses `ValueListenableBuilder<Text>` or `AnimatedBuilder` to listen to the notifier
- Only the text widget rebuilds per character, not the entire NarratorSheet

Alternatively, keep `Timer` but use `AnimatedBuilder` with a `Listenable` to scope rebuilds to the `Text` widget only.

---

## 5. Files Changed

| File | Change |
|------|--------|
| `lib/features/world_map/presentation/screens/world_map_screen.dart` | Remove old coach mark, add narrator first-visit |
| `lib/features/narrator/presentation/widgets/narrator_sheet.dart` | Bottom sheet → centered glass dialog, AnimatedSize, skip button |
| `lib/features/narrator/presentation/widgets/narrator_typewriter.dart` | Performance: scope rebuilds to Text widget |
| `lib/features/onboarding/presentation/screens/world_reveal_screen.dart` | `context.go('/')` → `context.go('/timeline')` |
| `lib/core/router/router.dart` | `return '/'` → `return '/timeline'` |

---

## 6. Not In Scope

- Changing Narrator trigger logic (trigger engine, cooldowns, etc.)
- Changing the Drift persistence layer
- Changing tribe/social Firestore permissions (separate investigation)
- Performance improvements outside the narrator typewriter
