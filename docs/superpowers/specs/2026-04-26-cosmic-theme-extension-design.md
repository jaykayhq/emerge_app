# Design Spec: Cosmic Theme Extension & Universal Background

**Date:** 2026-04-26
**Status:** Draft
**Topic:** Extending the Cosmic (Nebula) theme with health states and making the background system universal post-onboarding.

## 1. Objective
Transform the `NebulaBackground` into a dynamic, state-aware environment that reflects the user's world health (Thriving, Neutral, Decaying). Establish the background system as a universal visual layer across all post-onboarding screens.

## 2. Architecture

### 2.1 Nebula State Configuration
Introduce a configuration-driven approach for `NebulaBackground`. Each `WorldHealthState` will map to a specific set of visual parameters.

| Parameter | Decaying | Neutral (Base) | Thriving |
|-----------|----------|----------------|----------|
| **Star Density** | 0.4x | 1.0x | 1.5x |
| **Drift Speed** | 0.5x | 1.0x | 1.2x |
| **Nebula Opacity** | 0.05 | 0.12 | 0.20 |
| **Color Saturation** | 0.3 (Dim/Gray) | 1.0 (Vibrant) | 1.3 (Electric) |
| **Twinkle Speed** | 0.4x | 1.0x | 1.5x |
| **Particle Count** | 0.3x | 1.0x | 2.0x |

### 2.2 Global State Injection
`WorldBackground` will be updated to explicitly pass the `WorldHealthState` and current `AppWorldTheme` to its child layers.

## 3. Component Enhancements

### 3.1 `NebulaBackground` (lib/features/world_map/presentation/widgets/nebula_background.dart)
- Add `WorldHealthState healthState` property.
- Update `_generateElements()` to respond to `healthState` changes.
- Update `_NebulaPainter`, `_StarFieldPainter`, and `_ParticleFieldPainter` to use the parameters defined in the active `NebulaStateConfig`.
- Implement color desaturation/vibrancy logic using `Color.lerp` with a grayscale/white target.

### 3.2 `WorldBackground` (lib/core/presentation/widgets/world_background.dart)
- Ensure the `Scaffold` background remains deep cosmic (`0xFF0A0A1A`) to prevent flickering during transitions.
- Maintain the legacy `GrowthBackground` delegation for backward compatibility.

## 4. Universal Theme Rollout

### 4.1 Post-Onboarding Default
- Ensure the first-time transition to the dashboard sets `AppWorldTheme.nebula` as the explicit user preference.

### 4.2 Screen Auditing & Wrapping
The following screen types will be updated to use `WorldBackground`:
1. **Settings & Sub-settings**: `SettingsScreen`, `NotificationSettingsScreen`.
2. **Detail Views**: `HabitDetailScreen`.
3. **Overlays/Dialogs**: Ensure full-screen dialogs (like `AdvancedCreateHabitDialog`) maintain the background vibe.
4. **Paywalls**: `PaywallScreen`.

## 5. Visual Progression (The Vibe)
- **Thriving**: "Living Universe" — high energy, vibrant purples/teals, dense stars.
- **Neutral**: "Calm Void" — the current balanced Stitch design.
- **Decaying**: "Cold Space" — desaturated, dim, slow-moving, sparse.

## 6. Verification Plan
- **State Toggle**: Manually override health state in a test harness to verify visual transitions.
- **Theme Switcher**: Verify that switching to Forest/City still applies globally, even if assets are currently fallback gradients.
- **Performance**: Monitor frame times on lower-end devices to ensure 3-layer parallax + particles remain efficient.
