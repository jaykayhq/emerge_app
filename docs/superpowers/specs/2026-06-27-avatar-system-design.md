# Avatar System — Hybrid 3D Rendered Figure

**Date:** 2026-06-27
**Status:** Draft

---

## 1. Overview

Replace the current PNG-based avatar system (`AvatarRenderer` + `EvolvingSilhouette`) with a **hybrid procedural/3D avatar** — soft, rounded, cartoon-style figures inspired by 3D-rendered character illustrations (reference: `istockphoto-931288824`). Two renderers share one data model:

- **Procedural 3D (CustomPainter)** — capsule shapes + radial gradient shading, zero dependencies, used for lists/tribes/shop/customization
- **ThreeFlutter 3D (three_flutter package)** — real 3D primitives with lighting/shadows, used for the profile showcase view

---

## 2. Architecture

### 2.1 Shared Data Model

```
AvatarProportions — archetype-based body dimensions
AvatarColors — skin/outline/accent/glow/equipment colors
EquipmentMap — Map<EquipmentSlot, ShopItem>
EvolutionState — phase enum + body artifact list
```

### 2.2 Renderers

```
                    ┌──────────────────────┐
                    │    AvatarData         │
                    │  (shared immutable)   │
                    └──┬───────────────┬────┘
                       │               │
                       ▼               ▼
              ┌────────────────┐ ┌────────────────────┐
              │ Procedural     │ │ ThreeFlutter 3D    │
              │ CustomPainter  │ │ (three_flutter)    │
              │                │ │                    │
              │ • capsules     │ │ • SphereGeometry   │
              │ • gradients    │ │ • CapsuleGeometry  │
              │ • 60fps        │ │ • MeshStandardMat  │
              │ • zero deps    │ │ • OrbitControls    │
              │ • draw order   │ │ • lighting         │
              └────────┬───────┘ └─────────┬──────────┘
                       │                   │
                       ▼                   ▼
              StickmanAvatar widget (switches by RendererType enum)
```

### 2.3 State Management (Riverpod)

```
@riverpod
Stream<AvatarData> avatarData(Ref ref, String userId) → Firestore stream

@riverpod
List<ShopItem> avatarShopCatalog(Ref ref) → Firestore collection

@riverpod
class AvatarCustomizationNotifier extends _$AvatarCustomizationNotifier {
  // Equip/unequip items, change colors, preview
}

@riverpod
AvatarRendererType avatarRendererType(Ref ref) → based on route
```

- `avatarDataProvider` — listens to Firestore `users/{uid}/avatar` doc
- `avatarShopCatalogProvider` — listens to `shop/items` collection
- `avatarCustomizationProvider` — local state for unsaved changes in customizer screen
- `avatarRendererTypeProvider` — returns `procedural` or `threeD` based on current route

---

## 3. Body Structure

### 3.1 Components

| Body Part | Shape | Joint Count |
|-----------|-------|-------------|
| Head | Sphere | 1 (center) |
| Neck | Capsule | 1 (midpoint) |
| Torso | Tapered capsule (wider top) | 2 (chest, pelvis) |
| Upper Arm (L/R) | Capsule | 2 (shoulder, elbow) |
| Forearm (L/R) | Capsule | 2 (elbow, wrist) |
| Thigh (L/R) | Capsule | 2 (hip, knee) |
| Shin (L/R) | Capsule | 2 (knee, ankle) |
| Hand (L/R) | Small sphere | 1 (wrist) |
| Foot (L/R) | Rounded box | 1 (ankle) |

### 3.2 Proportions by Archetype

Each archetype scales the base proportions differently:

| Archetype | Torso Width | Arm Length | Leg Length | Head Size | Character |
|-----------|-------------|------------|------------|-----------|-----------|
| Hero | 1.0x | 1.0x | 1.0x | 1.0x | Balanced |
| Athlete | 1.15x | 1.05x | 1.05x | 0.9x | Broader |
| Scholar | 0.9x | 0.95x | 0.95x | 1.1x | Larger head |
| Creator | 0.95x | 0.95x | 1.0x | 1.0x | Leaner |
| Stoic | 1.0x | 1.0x | 1.0x | 1.0x | Disciplined |
| Zealot | 1.05x | 1.05x | 1.05x | 0.95x | Forward-leaning |

---

## 4. Color System

### 4.1 Archetype Default Palettes

| Archetype | Skin/Base | Outline/Rim | Accent (Eyes) | Glow/Aura |
|-----------|-----------|-------------|---------------|-----------|
| Hero/Core | #12161F | #35E0FF (cyan) | #BDF4FF | #35E0FF |
| Athlete | #1A0A0A | #FF6B35 (coral) | #FFB26B | #FF6B35 |
| Scholar | #0A0A1A | #B886FF (violet) | #DABFFF | #B886FF |
| Creator | #1A1200 | #FFD600 (gold) | #FFF0B3 | #FFD600 |
| Stoic | #0A1A16 | #00E5C7 (teal) | #B3FFF6 | #00E5C7 |
| Zealot | #1A0A1A | #E040FF (magenta) | #FFB3FF | #E040FF |

### 4.2 User Customization

Users can override:
- `skinColor` — base body color
- `outlineColor` — rim/edge accent
- `accentColor` — eyes, small details
- `glowColor` — evolution glow/aura
- `equipmentColors` — per equipped item (per-slot tint)

Customization is saved to Firestore `users/{uid}/avatar/colors` on save.

---

## 5. Equipment System

### 5.1 Slots

| Slot | Items | Draw Position |
|------|-------|---------------|
| `head` | Hats, helmets, halos, horns, hair | Above head sphere |
| `back` | Capes, wings, backpacks, floating auras | Behind torso |
| `leftHand` | Swords, staves, tools, instruments | Attached to left hand |
| `rightHand` | Shields, orbs, secondary weapons | Attached to right hand |
| `waist` | Belts, sashes, floating rings | At torso-pelvis midpoint |
| `feet` | Shoes, boots, ankle effects | Below foot joints |
| `aura` | Full-body effects, energy fields | Behind entire figure |

### 5.2 Item Model

```dart
class ShopItem {
  final String id;
  final String name;
  final EquipmentSlot slot;
  final Rarity rarity; // common, rare, epic, legendary
  final int? priceXP;
  final int? priceGems;
  final int? levelRequired;
  final RenderInstructions procedural; // for CustomPainter
  final RenderInstructions threeD;     // for ThreeFlutter
}
```

### 5.3 Rarities & Pricing

| Rarity | XP Cost | Gems (IAP) | Visual |
|--------|---------|-------------|--------|
| Common | 0 (starter) | — | Basic shape, flat color |
| Rare | 500 | — | Extra details, tinted |
| Epic | 2,000 | — | Glowing, animated |
| Legendary | 10,000 | 50-200 | Full effect, unique animation |

---

## 6. Evolution System Integration

### 6.1 Phase → Visual Mapping

| Phase | Effect on Renderer |
|-------|-------------------|
| Phantom (1-5) | Alpha 30%, no glow, faint outline |
| Construct (6-15) | Alpha 60%, wireframe overlay lines |
| Incarnate (16-30) | Solid (alpha 90%), core glow appears at chest |
| Radiant (31-50) | Full opacity, kintsugi-crack lines, core pulses |
| Ascended (50+) | Full opacity, sparkle particles, aura flourish |

### 6.2 Body Artifacts

Existing `BodyArtifact` items (Hermes Wings, Halo, Aegis, etc.) render as:

| Artifact | Procedural Draw | 3D Mesh |
|----------|----------------|---------|
| Hermes Wings | Two curved arcs from ankles | Flat planes on ankle joints |
| Golden Shoes | Gold gradient on foot shapes | Gold material on foot spheres |
| Halo | Ring arc above head | Torus geometry above head |
| Third Eye | Small gem circle on forehead | Small emissive sphere |
| Aegis | Rounded shield shape over torso | Curved plane in front of chest |
| Core Glow | Radial gradient circle at center | Emissive point light at chest center |
| Midas Touch | Gold gradient on hand circles | Gold material on hand spheres |
| Floating Tools | Small shapes near hand | Small meshes near hand |
| The Flow | Glowing vein lines on torso | Emissive line path on torso |

---

## 7. Procedural Renderer (CustomPainter)

### 7.1 Draw Order

1. Ground shadow (dark ellipse at feet level)
2. Back equipment (cape, wings, backpack)
3. Back limbs (upper arm + forearm)
4. Pelvis region
5. Torso (tapered capsule with vertical gradient)
6. Front limbs (upper arm + forearm)
7. Neck
8. Head (filled circle with radial gradient)
9. Face accent (eyes, details)
10. Head equipment (hats, halos)
11. Held equipment (weapons in hands)
12. Hand/Foot accent spheres
13. Waist equipment
14. Front equipment overlay
15. Evolution glow (blur pass)
16. Body artifacts
17. Aura overlay (if any)

### 7.2 Shading Technique

Each body part is a **capsule shape** (rounded rectangle or pair of circles + rectangle) filled with:

- **Base fill**: solid color from `AvatarColors`
- **Gradient overlay**: lighter at upper-left, darker at lower-right (simulates fixed light source at 45°)
- **Rim highlight**: thin lighter stroke on upper-left edge (fake rim light)

This produces the soft 3D look without actual 3D.

### 7.3 Equipment Rendering

Each `ShopItem` provides procedural draw instructions:

```dart
abstract class ProceduralRenderInstruction {
  void draw(Canvas canvas, Offset jointPosition, double scale, Color tint);
}
```

Example for a hat:
```dart
class HatRenderInstruction extends ProceduralRenderInstruction {
  void draw(Canvas canvas, Offset headTop, double scale, Color tint) {
    final paint = Paint()..color = tint;
    final path = Path()
      ..moveTo(headTop.dx - 12*scale, headTop.dy)
      ..lineTo(headTop.dx + 12*scale, headTop.dy)
      ..lineTo(headTop.dx + 8*scale, headTop.dy - 15*scale)
      ..lineTo(headTop.dx - 8*scale, headTop.dy - 15*scale)
      ..close();
    canvas.drawPath(path, paint);
  }
}
```

---

## 8. ThreeFlutter 3D Renderer

### 8.1 Scene Construction

```dart
class Avatar3DSceneBuilder {
  Scene build(AvatarData data) {
    final scene = Scene();
    final body = Group();
    
    // Build each body part as a Mesh
    body.add(buildSphere(data.headPosition, data.colors.skin));
    body.add(buildCapsule(data.neckPosition, data.colors.skin));
    body.add(buildCapsule(data.torsoPosition, data.colors.skin, tapered: true));
    body.add(buildCapsule(data.leftArmPosition, data.colors.skin));
    // etc.
    
    // Add equipment meshes
    for (final item in data.equipment.values.whereNotNull()) {
      body.add(buildEquipmentMesh(item, data.colors.equipment(item.id)));
    }
    
    // Add evolution glow
    scene.add(DirectionalLight(...));
    
    scene.add(body);
    return scene;
  }
}
```

### 8.2 Controls

- `OrbitControls` — drag to rotate, pinch to zoom
- Auto-rotation toggle (slow Y-axis spin)
- Pose cycling (idle → wave → attack → special via skeleton animation)

### 8.3 Performance

- Scene built once (or rebuilt on data change)
- ~4-8ms per frame on mid-range devices
- RepaintBoundary around the widget

---

## 9. Routes

| Route | Widget | Renderer | Notes |
|-------|--------|----------|-------|
| `/profile` | FutureSelfStudio | ThreeFlutter | Main avatar showcase |
| `/avatar/customize` | AvatarCustomizer | Procedural | Tabs for colors/equipment |
| `/avatar/shop` | AvatarShop | Procedural | Grid with item cards |
| `/social` (lists) | SocialActivityScreen | Procedural | 20+ avatar thumbnails |
| `/leaderboard` | LeaderboardScreen | Procedural | Small thumbnails |

---

## 10. File Manifest

```
lib/features/avatar/
├── domain/models/
│   ├── avatar_data.dart               — AvatarData sealed class
│   ├── avatar_colors.dart             — AvatarColors value class
│   ├── avatar_proportions.dart        — AvatarProportions + archetype map
│   ├── equipment_data.dart            — EquipmentSlot enum, ShopItem
│   ├── evolution_data.dart            — EvolutionPhase + artifact data
│   ├── avatar_pose.dart               — Pose data (idle, wave, attack, etc.)
│   └── equipment_catalog.dart         — All equipment item definitions
├── data/
│   ├── avatar_repository.dart         — Firestore read/write avatar data
│   ├── avatar_repository.g.dart       — Generated
│   └── shop_repository.dart           — Firestore read shop items
├── presentation/
│   ├── renderers/
│   │   ├── procedural_avatar_painter.dart   — CustomPainter implementation
│   │   └── three_d_avatar_view.dart         — ThreeFlutter widget wrapper
│   ├── widgets/
│   │   ├── stickman_avatar.dart             — Unified widget (switches renderer)
│   │   ├── avatar_customizer.dart           — Customization screen (4 tabs)
│   │   └── avatar_shop_screen.dart          — Shop screen with grid
│   └── providers/
│       └── avatar_providers.dart            — Riverpod providers + g.dart
└── avatar_helpers.dart                      — Shared utility functions
```

---

## 11. Testing

### 11.1 Unit Tests

| File | Tests |
|------|-------|
| `avatar_data_test.dart` | Serialization, archetype → proportions mapping |
| `avatar_colors_test.dart` | Palette generation, copyWith |
| `equipment_data_test.dart` | equip/unequip logic, slot validation |
| `evolution_data_test.dart` | Phase → visual param mapping |

### 11.2 Widget Tests

| File | Tests |
|------|-------|
| `procedural_avatar_painter_test.dart` | Draws all body parts, renders equipment |
| `stickman_avatar_test.dart` | Switches renderer, responsive sizing |
| `avatar_customizer_test.dart` | Tab navigation, color picker interaction |
| `avatar_shop_test.dart` | Item grid display, currency display |

---

## 12. Migration Path

1. Create data models and providers (no visual changes)
2. Implement procedural renderer alongside existing `AvatarRenderer`
3. Gate with feature flag: `useNewAvatarRenderer`
4. Once procedural renderer is verified, replace `AvatarRenderer` in all screens
5. Add ThreeFlutter renderer for profile view
6. Add customization UI and shop
7. Remove old silhouette assets and dead code

---

## 13. Implementation Phasing

### Phase 1: Procedural Renderer (v1)
Build the procedural CustomPainter renderer + data models + Riverpod providers. This replaces the current `AvatarRenderer` in all list/profile screens with soft 3D-style figures. No ThreeFlutter yet. This phase provides immediate visual improvement with zero dependency risk.

### Phase 2: ThreeFlutter 3D (v2)
Add the ThreeFlutter renderer for the profile showcase view. Requires verifying `three_flutter` package stability on target platforms (web, iOS, Android) before committing.

### Phase 3: Customization + Shop (v2/v3)
After both renderers are stable, add the customization UI and item shop. Both renderers consume the same equipment data, so items designed during Phase 1 can preview in both views.

## 14. Open Questions

- ThreeFlutter platform support: verify web vs mobile stability before committing to 3D profile view
- Equipment visual complexity: start with a limited set of procedurally-drawable items (hats, capes, basic weapons), expand to fancier items (animated auras, particle effects) later
- Legacy migration: existing `Avatar` model (hair type, skin tone, outfit) → one-time Firestore migration script
