# Avatar System Design — Full-Character Variants

> **Last Updated**: February 2026
> **Status**: Active — Strategy A (Full-Character Variants)

## Architecture Overview

The Emerge avatar system renders pre-generated full-body character images
based on the user's archetype, skin tone, and hairstyle selection. Each
unique combination maps to a single PNG with transparent background.

**No runtime composition** of separate body parts. No animation controllers.
No Rive/Lottie integration. One image per character variant.

## How It Works

```
User selects: (Archetype: Athlete) × (Skin: mediumBrown) × (Hair: short_spiky)
        ↓
Asset lookup: assets/images/avatars/base/athlete/mediumBrown_short_spiky.png
        ↓
Render: Stack [background glow → character image → evolution overlay → phase label]
```

## Art Style

All characters follow a **2D flat vector** style enforced via prompt template:

- Thick clean black outlines
- Cell-shaded coloring, no gradients
- Pastel color palette
- Front-facing standing pose
- Character sheet style composition
- Transparent background (via gptimage `transparent=true`)

## Generation Pipeline

**Script**: `tools/generate_complete_avatars.dart`

**Models** (Pollinations.ai):
- **Primary**: `gptimage` — supports `transparent=true`, high quality
- **Fallback**: `flux`, `zimage` — free tier, no native transparency

**Combinations**: 5 archetypes × 3 skin tones × 5 hairstyles = **75 images**

**Seeds per archetype** (for style consistency):
| Archetype | Seed |
|-----------|------|
| Athlete   | 42   |
| Creator   | 84   |
| Scholar   | 126  |
| Stoic     | 168  |
| Mystic    | 210  |

## Asset Structure

```
assets/images/avatars/
├── base/
│   ├── athlete/
│   │   ├── lightOlive_buzz_cut.png
│   │   ├── lightOlive_short_spiky.png
│   │   ├── mediumBrown_buzz_cut.png
│   │   └── ... (15 per archetype)
│   ├── creator/
│   ├── scholar/
│   ├── stoic/
│   └── mystic/
├── effects/
│   ├── glow_soft.png
│   ├── glow_strong.png
│   └── sparkles.png
└── *_silhouette.png (fallbacks)
```

## Key Files

| File | Purpose |
|------|---------|
| `avatar_config.dart` | Data model (archetype, skinTone, hairStyle, evolvedState) |
| `avatar_asset_service.dart` | Path resolution + prompt generation |
| `avatar_renderer.dart` | StatelessWidget rendering stack |
| `avatar_provider.dart` | Riverpod state management |
| `generate_complete_avatars.dart` | Generation script |

## Evolution Phases

Characters progress through 5 phases based on user level:

| Phase | Level | Visual Effect |
|-------|-------|---------------|
| Phantom | 1-5 | Minimal glow |
| Construct | 6-15 | Subtle aura |
| Incarnate | 16-30 | Full glow + border |
| Radiant | 31-49 | Gold kintsugi border |
| Ascended | 50+ | Cyan transcendence + sparkles |

## Customization UX

Users customize by **selecting variant cards** (not mixing parts):
1. Pick skin tone (3 options)
2. Pick hairstyle (5 per archetype)
3. Preview updates instantly (image swap)
4. Clothing = default per archetype (baked in)

## Future Expansion

- **Phase 2**: Clothing variants (generate additional images per outfit)
- **Phase 3**: Lazy generation (generate on first selection, cache locally)
- **Phase 4**: User-uploaded reference images for AI character customization
