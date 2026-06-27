# Visual Companion: Procedural Stickman Avatar System

## Overview

A fully procedural, customizable stickman avatar that replaces the current PNG-based avatar system. Rendered via `CustomPainter` — no asset bundles, infinite resolution, runtime color/equipment swapping.

---

## 1. The Stickman — Anatomy & Proportions

### Skeleton (11 Joints)

```
         [Head]
           |
        [Chest] --[BackElbow]--[BackHand]
        /    \
  [FrontElbow] [Spine]
       |        |
  [FrontHand] [Pelvis] --[BackKnee]--[BackFoot]
              /     \
        [FrontKnee] [BackKnee]
             |           |
        [FrontFoot] [BackFoot]
```

### Archetype-Specific Proportions

Each archetype gets unique bone lengths for silhouette variety:

```
   Hero         Athlete        Scholar        Creator        Stoic        Zealot
 ┌──────┐     ┌──────┐      ┌──────┐       ┌──────┐       ┌──────┐      ┌──────┐
 │ ○    │     │ ○    │      │ ○    │       │ ○    │       │ ○    │      │ ○    │
 │ │    │     │ │    │      │ │    │       │ │    │       │ │    │      │ │    │
 │ │ ░░ │     │█│ ██ │      │ │ ░░ │       │ │ ░░ │       │ │ ░░ │      │ │ ██ │
 │/ \   │     │/ \ ██│      │/ \   │       │/ \   │       │/ \   │      │/ \ ██│
 └──────┘     └──────┘      └──────┘       └──────┘       └──────┘      └──────┘
 Neutral     Broader       Larger Head    Leaner        Balanced      Forward-lean
 (1.0x)      (1.15x)       (1.1x head)    (0.9x)        (1.0x)        (1.1x)
```

---

## 2. Evolution Phases — Visual Style

### Phantom (Levels 1-5) — Hazy, semi-transparent

```
     ░░░░░
    ░ ○ ░░░░
     ░│░░░░
    ░░│ ░░░
   ░░/ \░░░
   ░░░░░░░░

  Alpha: 30%     LineWidth: 0.8x
  Glow: None     Rim: Off
  "Faint outline — barely visible"
```

### Construct (Levels 6-15) — Wireframe mesh visible

```
     ▒▒▒▒▒
    ▒ ○ ▒▒▒▒
     ▒│▒▒▒▒
    ▒▒│ ▒▒▒
   ▒▒/ \▒▒▒
   ▒▒▒▒▒▒▒▒

  Alpha: 60%     LineWidth: 1.0x
  Glow: 3px      Rim: 10%
  "Structural lines appearing"
```

### Incarnate (Levels 16-30) — Solid matte silhouette

```
     █████
    █ ○ ████
     █│████
    ██│ ███
   ██/ \███
   ████████

  Alpha: 90%     LineWidth: 1.0x
  Glow: 4px      Rim: 18%
  Core Glow: ON
  "Solid presence"
```

### Radiant (Levels 31-50) — Kintsugi cracks glowing gold

```
     █████
    █ ○ ████
     █│══█▓
    ██│ ═██
   ██/ \█▓█
   ████████

  Alpha: 100%    LineWidth: 1.2x
  Glow: 6px      Rim: 25%
  Core Pulse: ON (breathes)
  Gold fissure lines on body
```

### Ascended (Level 50+) — Pure energy transcendence

```
     █████  ✦
    █ ○ ████ ✦
     ▢│▢▢▢█   ✦
    ██│ ███
   ██/ \███
   ████████

  Alpha: 100%    LineWidth: 1.4x
  Glow: 8px      Rim: 35%
  Core Pulse: pulsing
  Sparkles: animated
  Flourish: ON (energy wisps)
```

---

## 3. Archetype Color Palettes

```
Athlete ──── Coral Orange
  Fill: #1A0A0A    Outline: #FF6B35
  Core: #FFB26B

Scholar ──── Violet Purple
  Fill: #0A0A1A    Outline: #B886FF
  Core: #DABFFF

Creator ──── Golden Yellow
  Fill: #1A1200    Outline: #FFD600
  Core: #FFF0B3

Stoic ────── Teal Cyan
  Fill: #0A1A16    Outline: #00E5C7
  Core: #B3FFF6

Zealot ───── Magenta Pink
  Fill: #1A0A1A    Outline: #E040FF
  Core: #FFB3FF
```

### Color Customization (User Can Change)

Each user gets their archetype's palette as defaults, but can customize:

```
 ○ Head Fill: ______ (hex picker)
 ○ Outline/Glow: ______ (hex picker)
 ○ Limb Color: ______ (hex picker)
 ○ Body Fill: ______ (hex picker)
 ○ Core Glow: ______ (hex picker)
```

All color changes render in real-time on the stickman preview.

---

## 4. Equipment Slots & Items

### Slot Map

```
  ┌───────────────────────┐
  │      [Head Slot]       │  ← Hats, halos, horns, helmets, hair
  │       (★ Halo)         │
  │                        │
  │  [Back Slot]           │  ← Capes, wings, backpacks, auras
  │    ╱    (★ Wings)      │
  │ ╱      ╲               │
  │         [Waist Slot]   │  ← Belts, sashes, floating orbs
  │          (★ Belt)      │
  │                        │
  │ [Left Hand] [Right Hand]│ ← Weapons, tools, instruments, pets
  │    (★ Sword)   (☆)     │
  │                        │
  │      [Feet Slot]       │  ← Shoes, boots, anklets, trails
  │       (★ Wings)        │
  ├────────────────────────┤
  │      [Aura Slot]       │  ← Full-body effect overlays
  │    (★ Dark Flame)      │
  └───────────────────────┘
```

### Item Examples by Rarity

```
Common ─── Basic color variants
  [▓] Plain Hair     [▓] Cloth Belt     [▓] Wooden Stick
  Cost: 0 XP (starter)

Rare ──── Themed items
  [█] Warrior Helm   [█] Leather Cape   [█] Iron Sword
  Cost: 500 XP

Epic ──── Glowing items with effects
  [★] Crystal Halo   [★] Phoenix Wings [★] Mage Staff
  Cost: 2000 XP

Legendary ──── Animated, unique effects
  [✦] Crown of Stars [✦] Void Cloak    [✦] Thunder Hammer
  Cost: 10000 XP or $4.99 IAP
```

---

## 5. Animation System

### Locomotion States (Looping)

```
Idle ──── Gentle breathing, micro-weight-shift
  Spine: -90° → -93° → -87° → -90° (3s loop)

        ○    ○      ○     ○
        |    |\     |     |
       / \  / \    / \   / \
       ██   ██     ██    ██
       ││   ││     ││    ││
      t=0  t=0.7  t=2.0 t=3.0

Run ──── Arms pump, legs alternate (0.4s cycle)
      \○/    ○    /○\    ○
       |    /|    |    \|
      / \  / \   / \  / \
      ██   █▒    ██   ▒█
      ││   │     ││    │
     Left Mid  Right Mid

Jump ──── Arms up, legs tucked
      \○/
       |↑
      /↑\
     ██ ██
      │ │
```

### Action Clips (One-Shot, Upper-Body Only)

```
Attack1 ── Quick swing (0.3s)
  \○/   \○/   \○/
   | →   |\    |←
  / \   / \   / \

Attack2 ── Overhead smash (0.4s)
  \○/   ○/    \○/
   |    /| →   |\ 
  / \  / \    / \

Special ── Charged blast (0.6s)
  \○/   -○-   ○←    \○/
   |     |    /| →   |\
  / \   / \  / \    / \

Hurt ── Flinch back (0.2s)
  \○/   ○←
   |     |\
  / \   /  \

Emote Thumbs Up
  ○      \○/
  |  →    |
 / \     / \

Emote Wave
  ○
  |  →  👋
 / \

Emote Point
  ○
  |  →  ☞
 / \
```

### Animation Blending (Upper-Lower Separation)

The animator supports **layered animation** — upper body (arms, spine, neck) can play action clips while lower body (legs) continues locomotion:

```
Example: Running + Attacking
  Upper: Attack clip (~0.3s)
  Lower: Run loop (continues cycling)
  
  Animation state machine:
  ┌─────────────────────┐
  │    Locomotion       │←── idle, run, jump, fall
  │  (full body, loop)  │
  └───────┬─────────────┘
          │ blend
  ┌───────▼─────────────┐
  │    Action (upper)   │←── attack1/2/3, special, cast, hurt, emote
  │  (one-shot, blend)  │
  └───────┬─────────────┘
          │ composite
  ┌───────▼─────────────┐
  │   Composite Pose    │──→ StickSkeleton → StickFrame → Painter
  └─────────────────────┘
```

---

## 6. Body Artifacts — Evolution Rewards

Visual rewards that appear on the stickman as the user levels habits:

```
Zone     │ Artifact         │ Habit         │ Unlock │ Visual
─────────┼──────────────────┼───────────────┼────────┼────────────────────
Ankles   │ Hermes Wings     │ Cardio        │ 50     │ Glowing ankle trails
         │ Golden Shoes     │ Cardio        │ 100    │ Gold soles with sparks
Head     │ Halo             │ Mindfulness   │ 30     │ Floating ring of light
Eyes     │ Third Eye        │ Mindfulness   │ 100    │ Forehead gem
Chest    │ Aegis            │ Strength      │ 50     │ Spectral breastplate
Core     │ Core Glow        │ Strength      │ 100    │ Pulsing center
Hands    │ Midas Touch      │ Creativity    │ 50     │ Gold-glowing hands
         │ Floating Tools   │ Creativity    │ 100    │ Orb near hands
Core     │ The Flow         │ Hydration     │ 30     │ Visible light veins

Rendering on the stickman:
  Hermes Wings ──── Two glowing arcs trailing from ankle joint
  Halo ──────────── Circle drawn above headCenter + headRadius
  Aegis ─────────── Tapered quad overlay on torso outline
  Core Glow ─────── Animated circle at centerOfMass (pulses)
  Midas Touch ──── Gold tint on frontHand/backHand circles
```

---

## 7. Renderer Draw Order

How the `StickmanPainter` builds the final image, layer by layer:

```
Layer 1: Ground shadow (faint ellipse at feet)
Layer 2: Outer glow (single blurred stroke pass)
Layer 3: Back limbs (dimmed: ~55% of outline color)
Layer 4: Back equipment (cape, backpack, wings)
Layer 5: Torso fill (gradient chest→pelvis)
Layer 6: Torso outline + shoulder/hip nubs
Layer 7: Neck bone
Layer 8: Head fill + outline + eye dot
Layer 9: Head equipment (halos, hats, helmets)
Layer 10: Body artifacts (hermes wings, aegis, gold hands)
Layer 11: Weapon motion trail (if attacking)
Layer 12: Held weapon / front equipment
Layer 13: Front equipment overlays
Layer 14: Front limbs (full color)
Layer 15: Torso rim light (lit side)
Layer 16: Chest core glow (pulsing dot)
Layer 17: Foreground sparkles (Ascended phase)
Layer 18: Per-style flourishes (horns, wisps)
```

---

## 8. Shop System

### Catalog Structure

```
ShopItem {
  id: "warrior_helm"
  name: "Warrior's Helm"
  type: EquipmentType.head
  rarity: Rare (★)
  priceXP: 500
  priceIAP: null
  unlocksAtLevel: 10
  previewPose: "attack1"
  styleOverrides: {
    headFill: #333333
    headOutline: #FF6B6B
  }
  drawOverride: "WarriorHelm" // Optional custom drawn piece
}
```

### Shop Screen Layout (Wireframe)

```
┌──────────────────────────────────┐
│  [XP: 2,450]  [Gems: 12]        │
├──────────────────────────────────┤
│ [Feature] [Head] [Back]          │
│ [Hands]  [Waist] [Feet] [Auras] │
├──────────────────────────────────┤
│ ┌──────┐ ┌──────┐ ┌──────┐      │
│ │ ○/|\ │ │ \○/ │ │  ○   │      │
│ │  /\  │ │  |   │ │ /|\  │      │
│ │ Warrior│ │ Mage's│ │Crown │      │
│ │  Helm  │ │Staff  │ │ofStars│     │
│ │ ★ Rare│ │★ Epic│ │✦Legnd│     │
│ │ 500 XP│ │2000XP │ │$4.99 │     │
│ │ [Buy] │ │ [Buy] │ │ [Buy] │     │
│ └──────┘ └──────┘ └──────┘      │
└──────────────────────────────────┘
```

### Currency System

```
XP (Earned) ──── For Common, Rare, Epic items
  → Completing habits, streaks, challenges
  → Levels, milestone rewards
  
Gems (IAP) ──── For Legendary items
  → Purchased via RevenueCat (mobile) / Paystack (web)
  → 100 Gems = $0.99, 1100 Gems = $9.99
  → Some Legendary items also cost gems
```

---

## 9. Customization UI Flow

```
┌──────────────────────────────────┐
│      CUSTOMIZE YOUR STICKMAN     │
├──────────────────────────────────┤
│                                  │
│         ┌──────────┐             │
│         │   ○/|\   │             │
│         │    /\    │             │
│         │   /\  \  │             │
│         └──────────┘             │
│     [Rotate] [Zoom] [Pose]       │
│                                  │
├─ Tab Bar ────────────────────────┤
│ [Colors] [Equipment] [Emotes]    │
├──────────────────────────────────┤
│                                  │
│ COLORS TAB:                      │
│ ┌────┐ ┌────┐ ┌────┐ ┌────┐    │
│ │ ██ │ │ ██ │ │ ██ │ │ ██ │    │
│ │Skin│ │Out-│ │Limbs│ │Torso│    │
│ │    │ │line│ │     │ │     │    │
│ └────┘ └────┘ └────┘ └────┘    │
│                                  │
│ EQUIPMENT TAB:                   │
│ Head: [Equipped: Halo] [Change▾] │
│ Back: [Equipped: None] [Change▾] │
│ Hands: [Equipped: Staff] [Change▾]│
│                                  │
│ EMOTES TAB:                      │
│ [Wave] [Point] [ThumbsUp] [Dance]│
│    ○      ○       ○        ○    │
│   /|\    /|\     /|\      \|/   │
│    /\     /\      /\      /\   │
│                                  │
└──────────────────────────────────┘
```

---

## 10. Evolution Integration

### How the Existing System Maps to the Stickman

```
Current System              →    Stickman System
─────────────────────────────────────────────────
AvatarConfig.archetype      →    StickProportions.forArchetype()
AvatarConfig.evolvedState   →    StickStyle.fromArchetypeAndPhase()
SilhouetteEvolutionState    →    Passed as overlay list to painter
BodyArtifact (all)          →    Procedural overlays at body zones
UserProfile.level           →    EvolutionPhase.phaseFromLevel()
Legacy Avatar model         →    Migrated to customization presets
```

### BodyArtifact → Procedural Drawing Mapping

Each artifact becomes a small drawing function in the painter:

```dart
void _drawHermesWings(Canvas c, StickFrame f, Color color, double a) {
  // Two glowing arcs trailing from ankle joint
  final paint = Paint()
    ..color = color.withAlpha(a)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3);
  
  // Left wing arc
  final path = Path()
    ..moveTo(f.backFoot.dx, f.backFoot.dy)
    ..quadraticBezierTo(
      f.backFoot.dx - 15, f.backFoot.dy - 10,
      f.backFoot.dx - 10, f.backFoot.dy + 5,
    );
  canvas.drawPath(path, paint);
  
  // Right wing arc (mirrored)
  // ... similar path for frontFoot
}
```

---

## 11. Tech Stack & Dependencies

```
Rendering:    CustomPainter (Canvas API) — no external packages
Animation:    Pure Dart timer-based — no animation framework needed
State:        Riverpod (existing project pattern)
Data:         Firestore (existing Firebase integration)
Shop:         Existing RevenueCat/Paystack paywall integration
Testing:      flutter_test + mocktail (existing pattern)

Zero new dependencies. Zero asset bundles. Pure code.
```

---

## 12. Performance Budget

```
Target: 60fps on mid-range Android/iOS devices

Cost breakdown per frame:
  Skeleton resolve (FK): <0.01ms
  StickStyle building: <0.01ms
  StickmanPainter.paint():
    - Ground shadow: 2 drawOval calls
    - Outer glow: ~12 drawLine + 1 drawCircle (blurred)
    - Back limbs: 4 tapered bone quads + 2 circles
    - Equipment: 0-N custom draw calls
    - Torso: 1 gradient path + 1 stroke
    - Head: 2 circles + 1 tiny dot
    - Front limbs: 4 tapered bone quads + 2 circles
    - Weapon/effects: 0-N draw calls
  Total: ~25-40 draw calls per frame

Optimization hooks (if needed):
  → RepaintBoundary (already in widget)
  → Avoid MaskFilter.blur on lower-end devices (use layered ellipses)
  → Cache StickFrame if pose hasn't changed
```

---

## Evaluation

**Is this what you want?**

Before I write any code, review this document and let me know:

1. **Visual style** — Does the stickman aesthetic (neon outlines, dark fill, archetype colors) match your vision?
2. **Evolution phases** — The 5-phase system (Phantom → Ascended) maps your existing system — any tweaks?
3. **Customization depth** — Color pickers per body part + equipment slots + emotes. Too much? Too little?
4. **Equipment slots** — 7 slots (head, back, hands×2, waist, feet, aura). Good or simplify?
5. **Shop currency** — XP + Gems (IAP). Match your existing monetization model?
6. **Animation scope** — Idle + run + 3 attacks + hurt + emotes for v1. Enough or too many?
7. **Item shop** — Full catalog UI or start with a simple grid view?

Take a look and let me know what you think!
