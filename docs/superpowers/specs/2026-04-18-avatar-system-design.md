# Avatar System Design
**Date:** 2026-04-18  
**Status:** Approved

---

## Overview

The Emerge avatar system uses a **silhouette-reveal progression model**. Every user begins as an
anonymous energy signature and earns their visual identity through consistent habit completion.
The avatar is fully defined by the user's archetype — there are no skin tone or hairstyle choices.
Gender is intentionally undefined at all stages until Ascended, where each archetype has a single
canonical character design.

---

## Evolution Stages

The system has 5 evolution phases keyed to user level. The silhouette is code-painted at all
stages; only the overlay texture and (at Ascended) the character art are image assets.

| Phase | Levels | Name | Visual Description |
|-------|--------|------|-------------------|
| 1 | 1–5 | **Phantom** | Smoky nebulous wisps. No defined shape. Pure potential. |
| 2 | 6–15 | **Construct** | Wireframe mesh visible. A form emerging. |
| 3 | 16–30 | **Incarnate** | Solid matte silhouette. Defined. Consistent. |
| 4 | 31–50 | **Radiant** | Kintsugi gold cracks glowing through the silhouette. |
| 5 | 50+ | **Ascended** | Full archetype character art replaces the silhouette. Pure energy transcendence. |

---

## Rendering Pipeline

The `AvatarRenderer` widget uses a Flutter `Stack` with 4–5 layers composited back-to-front:

```
Layer 1: Background glow       — code-driven, intensity scales with phase
Layer 2: Body image            — code-painted silhouette (Phantom–Radiant)
                                 OR archetype character PNG (Ascended only)
Layer 3: Evolution overlay     — transparent PNG texture (Construct onward)
Layer 4: Sparkles              — sparkles.png (Ascended only)
Layer 5: Phase label           — "THE PHANTOM" / "THE ASCENDED" etc. (code text)
```

### Per-phase rendering behaviour

| Phase | Layer 2 | Layer 3 |
|-------|---------|---------|
| Phantom | `_FallbackSilhouettePainter` (code) | none |
| Construct | `_FallbackSilhouettePainter` | `evolved/construct/overlay.png` |
| Incarnate | `_FallbackSilhouettePainter` | `evolved/incarnate/overlay.png` |
| Radiant | `_FallbackSilhouettePainter` | `evolved/radiant/overlay.png` |
| Ascended | `base/{archetype}/ascended.png` | `evolved/ascended/overlay.png` |

---

## Asset Manifest (21 images)

### Ascended Character Art — 5 PNGs

> One canonical character design per archetype. Full body, transparent background,
> cel-shaded 2D game art style, no explicit gender markers.

```
assets/images/avatars/base/athlete/ascended.png
assets/images/avatars/base/creator/ascended.png
assets/images/avatars/base/scholar/ascended.png
assets/images/avatars/base/stoic/ascended.png
assets/images/avatars/base/zealot/ascended.png
```

**Generation style lock (all 5):**  
`2D game character art, cel-shaded coloring, flat vector fills, bold clean ink outline 2-3px, full body
front-facing standing idle pose, no explicit male or female markers, archetype-specific silhouette
proportions, solid green screen background RGB(0,255,0), no text, no watermark`

Each archetype adds its defining visual language on top of the base style:
- **Athlete** — lean muscular build, electric-blue competition suit, radiating energy lines
- **Creator** — slender expressive build, paint-splattered linen drape, floating tools aura
- **Scholar** — upright lean build, deep green academic gown, amber spectacles, open book aura
- **Stoic** — balanced strong build, slate blue ceremonial robe, indigo obi, prayer beads
- **Zealot** — tall willowy build, dark indigo armour vestment, flowing silver hair, violet eye glow

---

### Evolution Overlay Textures — 4 PNGs

> Transparent PNGs composited over the code-painted silhouette.
> Should respect the silhouette's border shape — designed as a vignette/texture not a solid fill.

```
assets/images/avatars/evolved/construct/overlay.png
assets/images/avatars/evolved/incarnate/overlay.png
assets/images/avatars/evolved/radiant/overlay.png
assets/images/avatars/evolved/ascended/overlay.png
```

| File | Visual Effect |
|------|---------------|
| `construct/overlay.png` | Blue-white geometric wireframe grid lines, faint, confined to silhouette shape |
| `incarnate/overlay.png` | Archetype-tinted edge glow with faint inner highlight stripe |
| `radiant/overlay.png` | Gold kintsugi crack network spreading from core outward |
| `ascended/overlay.png` | Cyan-white energy aura emanating outward from body edges |

---

### Artifact Icons — 9 PNGs

> 64×64px game icons with transparent background. These appear in the item shop and on the
> avatar body zone when unlocked.

```
assets/images/avatars/shop/artifacts/hermes_wings.png
assets/images/avatars/shop/artifacts/golden_shoes.png
assets/images/avatars/shop/artifacts/halo.png
assets/images/avatars/shop/artifacts/third_eye.png
assets/images/avatars/shop/artifacts/aegis.png
assets/images/avatars/shop/artifacts/core_glow.png
assets/images/avatars/shop/artifacts/midas_touch.png
assets/images/avatars/shop/artifacts/floating_tools.png
assets/images/avatars/shop/artifacts/the_flow.png
```

---

### Effect PNGs — 3 PNGs

```
assets/images/avatars/effects/glow_soft.png     — ambient glow, low-intensity phases
assets/images/avatars/effects/glow_strong.png   — strong glow, Radiant/Ascended
assets/images/avatars/effects/sparkles.png      — foreground sparkle particles, Ascended only
```

---

## Code Changes Required

### 1. `AvatarAssetService.getCharacterPath()`

**Current behaviour:** Builds path from `archetype + skinTone + hairStyle`.  
**New behaviour:** Returns the Ascended character art path only at level 50+; empty string otherwise,
allowing the renderer's fallback chain to engage the code-painted silhouette.

```dart
String getCharacterPath(UserArchetype archetype, EvolutionPhase phase) {
  if (phase == EvolutionPhase.ascended) {
    return '$_basePath/base/${archetype.name}/ascended.png';
  }
  return ''; // Renderer falls through to code silhouette
}
```

### 2. `AvatarConfig` — remove unused fields

`skinTone` and `hairStyle` are no longer used in rendering. Remove from `AvatarConfig` or
mark as deprecated. If stored in Firestore for legacy users, keep the field in the data model
but stop reading it in the renderer.

### 3. `AvatarAssetService.getAvailableHairstyles()` / `getAvailableSkinTones()`

These methods become unused. Deprecate and remove after confirming no UI references them
(onboarding character creation screen, profile edit screen).

---

## What Is NOT Needed

The following assets were planned but are **not required** under this design:

- ~~225 full-body character PNGs (skin × hair × outfit combinations)~~
- ~~15 outfit overlay PNGs~~
- ~~75 base body PNGs~~

Skin tone and hairstyle selection screens in onboarding should be removed or repurposed.

---

## Open Questions (resolved)

| Question | Decision |
|----------|----------|
| Layered compositing vs flat PNGs? | Flat full-body PNGs (simpler, no alignment risk) |
| Gender in prompts? | No gender — silhouette is gender-neutral through Radiant; Ascended is archetype-defined |
| Hairstyle / skin tone as user choices? | Removed — avatar is fully archetype-defined |
| Ascended art: shared or archetype-specific? | Archetype-specific (5 unique designs) |
