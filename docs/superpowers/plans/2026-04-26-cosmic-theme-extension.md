# Cosmic Theme Extension & Universal Rollout Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform the Cosmic Nebula into a 3-state dynamic environment and apply the selected theme globally across all post-onboarding screens.

**Architecture:** Use a configuration-driven approach where `NebulaBackground` receives a `WorldHealthState` and selects a `NebulaStateConfig` to drive its procedural painters. Wrap key screens in `WorldBackground` to ensure visual continuity.

**Tech Stack:** Flutter, Riverpod, CustomPainters.

---

### Task 1: Define Nebula State Configuration

**Files:**
- Modify: `lib/core/domain/models/app_world_theme.dart`

- [ ] **Step 1: Add NebulaStateConfig model and health-state mapping**

```dart
/// Configuration for the procedural Nebula background based on health.
class NebulaStateConfig {
  final double starDensityFactor;
  final double driftSpeedFactor;
  final double nebulaOpacity;
  final double colorSaturation;
  final double twinkleSpeedFactor;
  final double particleCountFactor;

  const NebulaStateConfig({
    required this.starDensityFactor,
    required this.driftSpeedFactor,
    required this.nebulaOpacity,
    required this.colorSaturation,
    required this.twinkleSpeedFactor,
    required this.particleCountFactor,
  });

  static NebulaStateConfig forState(WorldHealthState state) {
    switch (state) {
      case WorldHealthState.thriving:
        return const NebulaStateConfig(
          starDensityFactor: 1.5,
          driftSpeedFactor: 1.2,
          nebulaOpacity: 0.20,
          colorSaturation: 1.3,
          twinkleSpeedFactor: 1.5,
          particleCountFactor: 2.0,
        );
      case WorldHealthState.neutral:
        return const NebulaStateConfig(
          starDensityFactor: 1.0,
          driftSpeedFactor: 1.0,
          nebulaOpacity: 0.12,
          colorSaturation: 1.0,
          twinkleSpeedFactor: 1.0,
          particleCountFactor: 1.0,
        );
      case WorldHealthState.decaying:
        return const NebulaStateConfig(
          starDensityFactor: 0.4,
          driftSpeedFactor: 0.5,
          nebulaOpacity: 0.05,
          colorSaturation: 0.3,
          twinkleSpeedFactor: 0.4,
          particleCountFactor: 0.3,
        );
    }
  }
}
```

- [ ] **Step 2: Commit Task 1**

```bash
git add lib/core/domain/models/app_world_theme.dart
git commit -m "feat(theme): add NebulaStateConfig for health-based cosmic states"
```

---

### Task 2: Refactor NebulaBackground for State-Awareness

**Files:**
- Modify: `lib/features/world_map/presentation/widgets/nebula_background.dart`

- [ ] **Step 1: Add healthState property and update state logic**

Update the constructor and `_generateElements` to use `NebulaStateConfig`.

```dart
// Update constructor
const NebulaBackground({
  super.key,
  required this.biome,
  required this.primaryColor,
  required this.accentColor,
  this.level = 1,
  this.healthState = WorldHealthState.neutral, // New property
});

final WorldHealthState healthState;

// Update _generateElements
void _generateElements() {
  final config = NebulaStateConfig.forState(widget.healthState);
  final random = math.Random(widget.biome.index * 42 + widget.level);
  
  // Use config.starDensityFactor and config.particleCountFactor
  final starCount = (60 + (evolutionPhase * 15)) * config.starDensityFactor;
  // ... similar for particles
}
```

- [ ] **Step 2: Apply color saturation and speed factors to painters**

Update `_NebulaPainter`, `_StarFieldPainter`, and `_ParticleFieldPainter` to receive and use the config values.

- [ ] **Step 3: Commit Task 2**

```bash
git add lib/features/world_map/presentation/widgets/nebula_background.dart
git commit -m "feat(ui): implement dynamic cosmic states in NebulaBackground"
```

---

### Task 3: Integrate with WorldBackground

**Files:**
- Modify: `lib/core/presentation/widgets/world_background.dart`

- [ ] **Step 1: Pass healthState to NebulaBackground fallback**

```dart
// Inside _WorldBackgroundLayer.build
if (assetPath == null) {
  return NebulaBackground(
    biome: BiomeType.valley,
    primaryColor: const Color(0xFF00FFCC),
    accentColor: const Color(0xFF6C63FF),
    healthState: healthState, // Pass the healthState here
  );
}
```

- [ ] **Step 2: Commit Task 3**

```bash
git add lib/core/presentation/widgets/world_background.dart
git commit -m "feat(theme): connect WorldBackground health state to NebulaBackground"
```

---

### Task 4: Universal Theme Rollout

**Files:**
- Modify: `lib/features/habits/presentation/screens/habit_detail_screen.dart`
- Modify: `lib/features/settings/presentation/screens/settings_screen.dart`
- Modify: `lib/features/settings/presentation/screens/notification_settings_screen.dart`
- Modify: `lib/features/monetization/presentation/screens/paywall_screen.dart`

- [ ] **Step 1: Wrap key screens in WorldBackground**

Replace the top-level `Scaffold` in these files with `WorldBackground` (which contains its own Scaffold).

- [ ] **Step 2: Commit Task 4**

```bash
git add lib/features/habits/presentation/screens/habit_detail_screen.dart lib/features/settings/presentation/screens/settings_screen.dart lib/features/settings/presentation/screens/notification_settings_screen.dart lib/features/monetization/presentation/screens/paywall_screen.dart
git commit -m "feat(ui): roll out WorldBackground as universal screen wrapper"
```

---

### Task 5: Verification & Polish

- [ ] **Step 1: Verify Cosmic state transitions in World Map**
- [ ] **Step 2: Verify theme persistence in Settings screen**
- [ ] **Step 3: Check Paywall and Detail screens for correct background rendering**
- [ ] **Step 4: Final Commit**

```bash
git commit --allow-empty -m "chore(theme): finalize cosmic extension and universal rollout"
```
