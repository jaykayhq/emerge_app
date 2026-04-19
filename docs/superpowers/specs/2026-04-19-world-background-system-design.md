# Emerge World Background System — Design Spec
**Date:** 2026-04-19  
**Status:** Approved for implementation

---

## Overview

Replace the current code-driven `GrowthBackground` and `NebulaBackground` widgets with a unified `WorldBackground` system. The background becomes a **living environment** that reflects the user's world health — thriving, neutral, or decaying — through a user-selected world theme.

`LevelImmersiveScreen` is explicitly excluded; it keeps its existing per-node asset backgrounds.

---

## Themes

Six selectable world themes. The user picks one in their profile settings. Theme choice is global — the same theme applies on every screen.

| ID | Name | Visual |
|----|------|--------|
| `nebula` | Cosmic Nebula | Existing code-driven animated background (no new assets) |
| `forest` | Living Forest | Ancient canopy, light shafts, misty floor |
| `city` | Neon City | Urban skyline, rain-slicked streets, neon signs |
| `mountain` | Sacred Mountain | Misty peaks, stone steps, temple silhouettes |
| `ocean` | Ocean Abyss | Deep sea floor, bioluminescent life |
| `volcanic` | Volcanic Realm | Ember sky, lava rivers, ash and flame |

---

## Health States

Three states derived from world health percentage (0.0–1.0):

| State | Threshold | Visual character |
|-------|-----------|-----------------|
| `thriving` | 0.70–1.0 | Warm golden light, vivid colour, life and motion |
| `neutral` | 0.30–0.69 | Muted palette, soft haze, calm stillness |
| `decaying` | 0.0–0.29 | Desaturated, dark, fog and shadow, visual entropy |

---

## Asset Structure

```
assets/images/backgrounds/
  forest/
    thriving.png
    neutral.png
    decaying.png
  city/
    thriving.png
    neutral.png
    decaying.png
  mountain/
    thriving.png
    neutral.png
    decaying.png
  ocean/
    thriving.png
    neutral.png
    decaying.png
  volcanic/
    thriving.png
    neutral.png
    decaying.png
```

**Total: 15 new portrait-orientation PNG images.**  
`nebula` theme uses the existing `CosmicBackground` widget — zero new assets.

### Image specifications
- **Orientation:** Portrait (vertical), 9:19.5 aspect ratio or taller
- **Resolution:** 1080×2340 (or equivalent high-res portrait)  
- **Fit:** `BoxFit.cover`, anchor `Alignment.topCenter`
- **Format:** PNG (static); same paths with `.mp4` extension for future video upgrade

---

## Widget Architecture

### `WorldBackground`
The single replacement widget. Wraps any screen content.

```dart
WorldBackground({
  required Widget child,
  PreferredSizeWidget? appBar,
})
```

**Rendering layers (back to front):**
1. Background image (`Image.asset` with `BoxFit.cover`, `Alignment.topCenter`)  
   — OR the existing `CosmicBackground` widget when theme = `nebula`
2. Dark gradient overlay (top 15% and bottom 40%) — always present for text legibility
3. `SafeArea(child: child)`

**Internal logic:**
1. Read `worldThemeProvider` → get selected theme ID
2. Read `worldHealthStreamProvider` → resolve health state enum
3. Resolve asset path: `assets/images/backgrounds/{theme}/{healthState}.png`
4. Crossfade (200ms `AnimatedSwitcher`) when health state crosses a threshold
5. Fallback: if asset fails to load, render a solid dark gradient matching the theme's accent colour

### `WorldTheme` enum
```dart
enum WorldTheme { nebula, forest, city, mountain, ocean, volcanic }
```

### `WorldHealthState` enum
```dart
enum WorldHealthState { thriving, neutral, decaying }

extension WorldHealthStateX on double {
  WorldHealthState get asHealthState {
    if (this >= 0.70) return WorldHealthState.thriving;
    if (this >= 0.30) return WorldHealthState.neutral;
    return WorldHealthState.decaying;
  }
}
```

### `worldThemeProvider`
Riverpod `NotifierProvider` backed by `SharedPreferences`.  
Persists the user's chosen theme across sessions.  
Default: `WorldTheme.nebula` (no change from current state for existing users).

---

## Screens Updated

| Screen | Current widget | Replaced with |
|--------|---------------|---------------|
| Main scaffold (all nav tabs) | `GrowthBackground` | `WorldBackground` |
| World Map | `NebulaBackground` (inside map) | `WorldBackground` |
| Leveling Screen | `GrowthBackground` | `WorldBackground` |
| Recap Screen | `GrowthBackground` | `WorldBackground` |
| Reflections Screen | `GrowthBackground` | `WorldBackground` |
| Paywall Screen | `GrowthBackground` | `WorldBackground` |
| Splash Screen | `GrowthBackground` | `WorldBackground` |

**Not changed:** `LevelImmersiveScreen` (keeps per-node asset backgrounds).

---

## Theme Picker UI

A new section in the user's profile/settings screen: **"World Theme"**.

- Horizontally scrollable row of 6 themed cards
- Each card shows: theme name, a colour swatch / representative gradient, a ✓ if selected
- Tapping a card writes to `worldThemeProvider` and immediately updates all backgrounds
- Location: Profile → Appearance (or Settings → Appearance)

---

## Video Upgrade Path

When video loops are generated, place them at the same paths with `.mp4` extension:

```
assets/images/backgrounds/forest/thriving.mp4
```

`WorldBackground` checks for `.mp4` first and plays it with `video_player` in a looping controller. Falls back to `.png` if not found. No restructuring needed.

---

## No-Archetype / Onboarding State

If the user has not selected an archetype yet, `WorldBackground` still works normally — theme is independent of archetype. New users default to `nebula` until they pick a theme.

---

## Out of Scope

- Per-archetype theme restrictions — all themes available to all archetypes
- Progression-gated theme unlocks
- Any changes to `LevelImmersiveScreen`
- Changes to the Level background asset pipeline (`assets/images/levels/`)
