# World Background System — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace `GrowthBackground` and `NebulaBackground` across all screens (except `LevelImmersiveScreen`) with a unified `WorldBackground` widget driven by user-selected world theme and world health state.

**Architecture:** A new `WorldBackground` widget reads two Riverpod providers: `worldThemeProvider` (persisted user preference via `SharedPreferences`) and `worldHealthStreamProvider` (existing). It resolves a portrait PNG asset path from the combination and renders it full-screen with a gradient overlay. A theme picker section is added to `SettingsScreen`. The existing `WorldTheme` enum in `user_extension.dart` is **not touched** — a new separate `AppWorldTheme` enum is introduced to avoid breaking the existing data model.

**Tech Stack:** Flutter, Riverpod (v2 code-gen), SharedPreferences, `Image.asset` with `BoxFit.cover`

---

## File Map

| Action | File | Responsibility |
|--------|------|----------------|
| **Create** | `lib/core/presentation/widgets/world_background.dart` | The main replacement widget |
| **Create** | `lib/core/domain/models/app_world_theme.dart` | `AppWorldTheme` enum + `WorldHealthState` enum + path resolver |
| **Create** | `lib/core/presentation/providers/world_theme_provider.dart` | Riverpod `Notifier` backed by SharedPreferences |
| **Modify** | `lib/features/settings/presentation/screens/settings_screen.dart` | Add world theme picker section |
| **Modify** | `lib/core/presentation/widgets/growth_background.dart` | Keep file, delegate to `WorldBackground` |
| **Modify** | `lib/features/world_map/presentation/screens/world_map_screen.dart` | Swap `NebulaBackground` → `WorldBackground` |
| **Modify** | `lib/features/world_map/presentation/widgets/nebula_background.dart` | Keep file intact (still used by `nebula` theme) |
| **Modify** | `pubspec.yaml` | Declare `assets/images/backgrounds/` asset path |

**Screens modified indirectly** (already use `GrowthBackground`, no code change needed once Task 4 is done):  
`scaffold_with_nav_bar.dart`, `leveling_screen.dart`, `recap_screen.dart`, `reflections_screen.dart`, `paywall_screen.dart`, `splash_screen.dart`, `accountability_screen.dart`

---

## Task 1: Create the Domain Models

**Files:**
- Create: `lib/core/domain/models/app_world_theme.dart`

- [ ] **Step 1: Create the file**

```dart
// lib/core/domain/models/app_world_theme.dart

/// The six selectable world background themes.
/// Named AppWorldTheme to avoid collision with the existing
/// WorldTheme enum in user_extension.dart (which is a Firestore model field).
enum AppWorldTheme {
  nebula,
  forest,
  city,
  mountain,
  ocean,
  volcanic;

  String get displayName {
    switch (this) {
      case AppWorldTheme.nebula:
        return 'Cosmic Nebula';
      case AppWorldTheme.forest:
        return 'Living Forest';
      case AppWorldTheme.city:
        return 'Neon City';
      case AppWorldTheme.mountain:
        return 'Sacred Mountain';
      case AppWorldTheme.ocean:
        return 'Ocean Abyss';
      case AppWorldTheme.volcanic:
        return 'Volcanic Realm';
    }
  }

  String get emoji {
    switch (this) {
      case AppWorldTheme.nebula:
        return '🌌';
      case AppWorldTheme.forest:
        return '🌲';
      case AppWorldTheme.city:
        return '🏙️';
      case AppWorldTheme.mountain:
        return '🌅';
      case AppWorldTheme.ocean:
        return '🌊';
      case AppWorldTheme.volcanic:
        return '🌋';
    }
  }

  /// Returns null for the nebula theme (it uses a code-driven widget).
  /// Returns the folder name for image-based themes.
  String? get assetFolder {
    if (this == AppWorldTheme.nebula) return null;
    return name; // 'forest', 'city', 'mountain', 'ocean', 'volcanic'
  }
}

/// Three visual states derived from world health percentage.
enum WorldHealthState {
  thriving,  // 0.70–1.0
  neutral,   // 0.30–0.69
  decaying;  // 0.0–0.29

  static WorldHealthState fromHealth(double health) {
    if (health >= 0.70) return WorldHealthState.thriving;
    if (health >= 0.30) return WorldHealthState.neutral;
    return WorldHealthState.decaying;
  }

  String get assetName => name; // 'thriving', 'neutral', 'decaying'
}

/// Resolves the asset path for a given theme and health state.
/// Returns null when the theme is [AppWorldTheme.nebula].
String? resolveBackgroundAsset(AppWorldTheme theme, WorldHealthState state) {
  final folder = theme.assetFolder;
  if (folder == null) return null;
  return 'assets/images/backgrounds/$folder/${state.assetName}.png';
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/core/domain/models/app_world_theme.dart
git commit -m "feat: add AppWorldTheme + WorldHealthState domain models"
```

---

## Task 2: Create the World Theme Provider

**Files:**
- Create: `lib/core/presentation/providers/world_theme_provider.dart`

- [ ] **Step 1: Create the provider**

```dart
// lib/core/presentation/providers/world_theme_provider.dart
import 'package:emerge_app/core/domain/models/app_world_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kWorldThemeKey = 'app_world_theme';

/// Persisted Riverpod notifier for the user's selected world theme.
/// Defaults to [AppWorldTheme.nebula] so existing users see no change.
class WorldThemeNotifier extends Notifier<AppWorldTheme> {
  @override
  AppWorldTheme build() {
    // Load persisted value synchronously — SharedPreferences.getInstance()
    // is async, so we return the default immediately and schedule a load.
    _loadFromPrefs();
    return AppWorldTheme.nebula;
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kWorldThemeKey);
    if (saved != null) {
      final theme = AppWorldTheme.values.firstWhere(
        (t) => t.name == saved,
        orElse: () => AppWorldTheme.nebula,
      );
      state = theme;
    }
  }

  Future<void> setTheme(AppWorldTheme theme) async {
    state = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kWorldThemeKey, theme.name);
  }
}

final worldThemeProvider =
    NotifierProvider<WorldThemeNotifier, AppWorldTheme>(WorldThemeNotifier.new);
```

- [ ] **Step 2: Commit**

```bash
git add lib/core/presentation/providers/world_theme_provider.dart
git commit -m "feat: add WorldThemeNotifier provider backed by SharedPreferences"
```

---

## Task 3: Create the WorldBackground Widget

**Files:**
- Create: `lib/core/presentation/widgets/world_background.dart`

This widget is the core of the system. It wraps screen content exactly like `GrowthBackground` does today (same `child` + optional `appBar` API) so call-sites need minimal changes.

- [ ] **Step 1: Create the widget**

```dart
// lib/core/presentation/widgets/world_background.dart
import 'package:emerge_app/core/domain/models/app_world_theme.dart';
import 'package:emerge_app/core/presentation/providers/world_theme_provider.dart';
import 'package:emerge_app/features/world_map/presentation/providers/world_health_provider.dart';
import 'package:emerge_app/features/world_map/presentation/widgets/nebula_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Full-screen world background driven by the user's selected theme
/// and current world health state.
///
/// Drop-in replacement for [GrowthBackground] and [NebulaBackground].
/// Wraps [child] inside a [Scaffold] with the background layered behind it.
class WorldBackground extends ConsumerWidget {
  final Widget child;
  final PreferredSizeWidget? appBar;

  const WorldBackground({
    super.key,
    required this.child,
    this.appBar,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(worldThemeProvider);
    final healthAsync = ref.watch(worldHealthStreamProvider);
    final health = healthAsync.when(
      data: (h) => h,
      loading: () => 0.5,
      error: (_, __) => 0.5,
    );
    final healthState = WorldHealthState.fromHealth(health);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: appBar,
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Layer 1: World background (image or animated nebula)
          _WorldBackgroundLayer(theme: theme, healthState: healthState),

          // Layer 2: Gradient overlay for text legibility
          const _GradientOverlay(),

          // Layer 3: Screen content
          SafeArea(child: child),
        ],
      ),
    );
  }
}

// ─── Private Widgets ──────────────────────────────────────────────────────────

class _WorldBackgroundLayer extends StatelessWidget {
  final AppWorldTheme theme;
  final WorldHealthState healthState;

  const _WorldBackgroundLayer({
    required this.theme,
    required this.healthState,
  });

  @override
  Widget build(BuildContext context) {
    final assetPath = resolveBackgroundAsset(theme, healthState);

    if (assetPath == null) {
      // Nebula theme — code-driven animated background
      return const NebulaBackground(
        biome: BiomeType.valley, // Generic — nebula ignores biome for global bg
        primaryColor: Color(0xFF00FFCC),
        accentColor: Color(0xFF6C63FF),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      child: Image.asset(
        assetPath,
        key: ValueKey(assetPath),
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => _FallbackBackground(theme: theme),
      ),
    );
  }
}

class _GradientOverlay extends StatelessWidget {
  const _GradientOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 0.15, 0.60, 1.0],
          colors: [
            Color(0x33000000), // Top vignette — 20% dark
            Color(0x00000000), // Transparent mid-upper
            Color(0x66000000), // 40% dark mid-lower
            Color(0xCC000000), // 80% dark bottom for UI legibility
          ],
        ),
      ),
    );
  }
}

class _FallbackBackground extends StatelessWidget {
  final AppWorldTheme theme;

  const _FallbackBackground({required this.theme});

  static const _themeColors = {
    AppWorldTheme.forest: Color(0xFF1B4332),
    AppWorldTheme.city: Color(0xFF1a0a3e),
    AppWorldTheme.mountain: Color(0xFF3D405B),
    AppWorldTheme.ocean: Color(0xFF0a1a3e),
    AppWorldTheme.volcanic: Color(0xFF3a0a0a),
    AppWorldTheme.nebula: Color(0xFF0A0A1A),
  };

  @override
  Widget build(BuildContext context) {
    final base = _themeColors[theme] ?? const Color(0xFF0A0A1A);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [base, const Color(0xFF0A0A1A)],
        ),
      ),
    );
  }
}
```

> **Note on `NebulaBackground` import:** The nebula widget requires `BiomeType` from `archetype_map_config.dart`. Pass `BiomeType.valley` as a neutral default — the global nebula doesn't need biome-specific colours.

- [ ] **Step 2: Commit**

```bash
git add lib/core/presentation/widgets/world_background.dart
git commit -m "feat: create WorldBackground widget with theme + health-state-driven backgrounds"
```

---

## Task 4: Register Assets in pubspec.yaml

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Add the backgrounds asset path**

In `pubspec.yaml`, find the `assets:` section (it currently lists `assets/images/avatars/`, etc.). Add the new directory:

```yaml
  # Add this line alongside the existing asset declarations:
  - assets/images/backgrounds/
```

The full section should look like (existing entries will differ; just add the one line):
```yaml
flutter:
  assets:
    - assets/images/avatars/
    - assets/images/levels/
    - assets/images/backgrounds/   # ← ADD THIS
    # ... other existing entries
```

- [ ] **Step 2: Create placeholder directories so Flutter doesn't error on missing assets**

```bash
# Run in project root
mkdir -p assets/images/backgrounds/forest
mkdir -p assets/images/backgrounds/city
mkdir -p assets/images/backgrounds/mountain
mkdir -p assets/images/backgrounds/ocean
mkdir -p assets/images/backgrounds/volcanic
```

Create a `.gitkeep` in each to track them:
```bash
New-Item assets/images/backgrounds/forest/.gitkeep -Force
New-Item assets/images/backgrounds/city/.gitkeep -Force
New-Item assets/images/backgrounds/mountain/.gitkeep -Force
New-Item assets/images/backgrounds/ocean/.gitkeep -Force
New-Item assets/images/backgrounds/volcanic/.gitkeep -Force
```

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml assets/images/backgrounds/
git commit -m "chore: register assets/images/backgrounds/ in pubspec + create placeholder dirs"
```

---

## Task 5: Update GrowthBackground to Delegate to WorldBackground

**Files:**
- Modify: `lib/core/presentation/widgets/growth_background.dart`

`GrowthBackground` is used on 7 screens. Rather than changing every call-site, rewrite `GrowthBackground` to delegate to `WorldBackground`. All screens continue to compile unchanged.

- [ ] **Step 1: Rewrite growth_background.dart**

```dart
// lib/core/presentation/widgets/growth_background.dart
import 'package:emerge_app/core/presentation/widgets/world_background.dart';
import 'package:flutter/material.dart';

/// Legacy wrapper — delegates to [WorldBackground].
/// Kept for backward compatibility so existing call-sites need no changes.
class GrowthBackground extends StatelessWidget {
  final Widget child;
  final PreferredSizeWidget? appBar;

  /// [showPattern] and [overrideGradient] are ignored in the new system.
  /// Retained in the constructor so no call-sites need updating.
  const GrowthBackground({
    super.key,
    required this.child,
    this.appBar,
    @Deprecated('No longer used') bool showPattern = true,
    @Deprecated('No longer used') List<Color>? overrideGradient,
  });

  @override
  Widget build(BuildContext context) {
    return WorldBackground(child: child, appBar: appBar);
  }
}
```

- [ ] **Step 2: Verify build compiles**

```bash
flutter pub get
flutter analyze lib/core/presentation/widgets/growth_background.dart
```

Expected: No errors. Deprecation warnings on call-sites are acceptable.

- [ ] **Step 3: Commit**

```bash
git add lib/core/presentation/widgets/growth_background.dart
git commit -m "refactor: GrowthBackground delegates to WorldBackground"
```

---

## Task 6: Replace NebulaBackground on World Map Screen

**Files:**
- Modify: `lib/features/world_map/presentation/screens/world_map_screen.dart`

The world map currently renders `NebulaBackground` as a positioned full-screen layer inside its own `Stack`. We replace it with `WorldBackground` wrapping the entire screen body.

- [ ] **Step 1: Locate the current background code**

In `world_map_screen.dart`, find the `NebulaBackground` usage (around line 151–157). It currently looks like:

```dart
// Inside the world map's Stack:
statsAsync.when(
  data: (config) => NebulaBackground(...),
  orElse: () => NebulaBackground(...),
)
```

- [ ] **Step 2: Replace with WorldBackground wrapping**

The `WorldMapScreen`'s `build` method currently returns a `Scaffold`. Change it so the `Scaffold` body is wrapped by `WorldBackground`. Remove the inline `NebulaBackground` widget from the Stack entirely.

Find the `build` method return in `world_map_screen.dart` and update the body structure:

```dart
// BEFORE (approximate existing structure):
return Scaffold(
  body: Stack(
    children: [
      // NebulaBackground positioned layer
      Positioned.fill(
        child: statsAsync.when(
          data: (config) => NebulaBackground(biome: ..., primaryColor: ..., accentColor: ...),
          orElse: () => NebulaBackground(biome: BiomeType.valley, primaryColor: ..., accentColor: ...),
        ),
      ),
      // ... rest of world map content
    ],
  ),
);

// AFTER:
return WorldBackground(
  child: Stack(
    children: [
      // NebulaBackground REMOVED from here
      // ... rest of world map content unchanged
    ],
  ),
);
```

Add the import at the top of the file:
```dart
import 'package:emerge_app/core/presentation/widgets/world_background.dart';
```

Remove the `nebula_background.dart` import from `world_map_screen.dart` if it is no longer used there.

- [ ] **Step 3: Verify compile**

```bash
flutter analyze lib/features/world_map/presentation/screens/world_map_screen.dart
```

Expected: No errors.

- [ ] **Step 4: Commit**

```bash
git add lib/features/world_map/presentation/screens/world_map_screen.dart
git commit -m "refactor: replace NebulaBackground with WorldBackground on world map screen"
```

---

## Task 7: Add Theme Picker to Settings Screen

**Files:**
- Modify: `lib/features/settings/presentation/screens/settings_screen.dart`

The settings screen already has a `currentTheme` variable (`userProfile?.worldTheme`) that references the old Firestore theme. We add a new **"World Theme"** section using the new `worldThemeProvider`.

- [ ] **Step 1: Add the import**

At the top of `settings_screen.dart`, add:
```dart
import 'package:emerge_app/core/domain/models/app_world_theme.dart';
import 'package:emerge_app/core/presentation/providers/world_theme_provider.dart';
```

- [ ] **Step 2: Add the watch in the build method**

Inside `SettingsScreen.build`, add alongside the existing watches:
```dart
final selectedTheme = ref.watch(worldThemeProvider);
```

- [ ] **Step 3: Insert the theme picker section into the settings body**

In the `SingleChildScrollView > Column` of the settings screen, add `_WorldThemeSection` as a new card section. Place it near the top of the settings, before "Notifications":

```dart
// Insert in the Column children list:
_buildSectionCard(
  context,
  title: 'World Theme',
  icon: Icons.landscape_outlined,
  child: _WorldThemePicker(
    selected: selectedTheme,
    onSelect: (theme) =>
        ref.read(worldThemeProvider.notifier).setTheme(theme),
  ),
),
```

- [ ] **Step 4: Add the `_WorldThemePicker` widget at the bottom of settings_screen.dart**

```dart
class _WorldThemePicker extends StatelessWidget {
  final AppWorldTheme selected;
  final ValueChanged<AppWorldTheme> onSelect;

  const _WorldThemePicker({
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: AppWorldTheme.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final theme = AppWorldTheme.values[index];
          final isSelected = theme == selected;
          return GestureDetector(
            onTap: () => onSelect(theme),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 80,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.6)
                      : Colors.white.withValues(alpha: 0.15),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    theme.emoji,
                    style: const TextStyle(fontSize: 26),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    theme.displayName
                        .split(' ')
                        .first, // First word only for brevity
                    style: TextStyle(
                      color: Colors.white.withValues(
                        alpha: isSelected ? 0.9 : 0.5,
                      ),
                      fontSize: 10,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (isSelected)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
```

> **Note:** `_buildSectionCard` is an existing helper in `settings_screen.dart`. Verify its exact signature by searching the file before using it. If no such helper exists, wrap the picker directly in a `Card` or `Container` with the same style used by other settings sections.

- [ ] **Step 5: Verify compile**

```bash
flutter analyze lib/features/settings/presentation/screens/settings_screen.dart
```

Expected: No errors.

- [ ] **Step 6: Commit**

```bash
git add lib/features/settings/presentation/screens/settings_screen.dart
git commit -m "feat: add world theme picker to settings screen"
```

---

## Task 8: Smoke Test on Device/Emulator

- [ ] **Step 1: Run the app**

```bash
flutter run
```

- [ ] **Step 2: Verify the following manually**

| Check | Expected |
|-------|----------|
| App launches | No crash, background renders (nebula by default) |
| Home/Timeline tab | `WorldBackground` visible, content on top |
| World Map | `WorldBackground` instead of nebula (or nebula if theme=nebula) |
| Settings → World Theme | Picker visible, 6 tiles displayed |
| Select "Living Forest" | Background updates immediately on all screens |
| Select "Cosmic Nebula" | Animated nebula restores |
| Force-quit, relaunch | Selected theme persists |
| Missing PNG (before assets generated) | Fallback dark gradient, no crash |

- [ ] **Step 3: Fix any issues found, commit fixes**

```bash
git add -A
git commit -m "fix: world background smoke test corrections"
```

---

## Self-Review

**Spec coverage check:**

| Spec requirement | Task |
|-----------------|------|
| 6 themes incl. nebula | Tasks 1, 3 |
| 3 health states (thriving/neutral/decaying) | Task 1 |
| Portrait PNG, BoxFit.cover, topCenter | Task 3 |
| Gradient overlay (top + bottom) | Task 3 |
| CrossFade on health state change | Task 3 (`AnimatedSwitcher`) |
| Fallback dark gradient on missing asset | Task 3 (`_FallbackBackground`) |
| SharedPreferences persistence | Task 2 |
| Default = nebula (no change for existing users) | Task 2 |
| GrowthBackground delegation (7 screens) | Task 5 |
| NebulaBackground removed from world map | Task 6 |
| Theme picker in Settings | Task 7 |
| Asset path declaration in pubspec | Task 4 |
| Placeholder dirs for missing images | Task 4 |
| LevelImmersiveScreen untouched | ✅ Not in file map |

**No placeholders found.** All steps contain actual code.

**Type consistency check:**
- `AppWorldTheme` defined Task 1, used in Tasks 2, 3, 7 ✅
- `WorldHealthState` defined Task 1, used in Task 3 ✅
- `resolveBackgroundAsset()` defined Task 1, used in Task 3 ✅
- `worldThemeProvider` defined Task 2, used in Tasks 3, 7 ✅
- `WorldBackground` constructor `({required child, appBar})` matches all usage ✅
