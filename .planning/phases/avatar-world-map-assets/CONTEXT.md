# Phase: Avatar & World Map Asset System — Context

**Gathered:** 2026-04-16
**Status:** Ready for production

<domain>
## Phase Boundary

This phase covers the complete generation specification for all visual assets in Emerge's avatar system and world map backgrounds. Scope includes:

1. **5 archetype character sheets** — base 2D character images (skin tone × hairstyle grid)
2. **Outfit variants** — 2–3 outfits per archetype, baked into separate base PNGs
3. **5 evolution phase overlays** — shared across all archetypes
4. **Item shop assets** — 9 artifact icons + outfit skin thumbnails + blueprint scroll icons
5. **World map biome backgrounds** — 5 biomes × 5 health states = 25 images

**Out of scope:** world zone buildings (Garden/Library/Forge/Studio/Shrine), Grok animations, Blender pipeline, HUD elements, seasonal events.
</domain>

<decisions>
## Implementation Decisions

### Art Style
- **D-01:** Stylized 2D game art — cel-shaded, flat vector fills with bold ink outlines (2–3px). No photorealism, no 3D render, no painterly illustration.
- **D-02:** No gradients on characters. Gradients only permitted in biome sky strips (top 20% of background tiles).
- **D-03:** Head-to-body ratio: 1:5.5 (slightly stylized, not extreme chibi). Full body, front-facing.
- **D-04:** All character images on solid RGB(0,255,0) background for chroma key extraction, or transparent PNG directly if tool supports alpha output.
- **D-05:** Resolution: 1024×1024px per character cell.

### Character Base Sheets
- **D-06:** Each archetype produces a 3×5 grid (skin tones × hairstyles) = 15 characters per archetype, 75 total.
- **D-07:** Each cell is a complete full-body image. No separate body part composition.
- **D-08:** Hair drawn in archetype default colour (locked per archetype). Skin tone is the variable per row.
- **D-09:** Asset path: `assets/images/avatars/base/{archetype}/{skinTone}_{hairStyle}.png`

### Outfit Variants
- **D-10:** Each archetype gets **2–3 outfit variants** baked as separate complete character images.
- **D-11:** Outfit variants follow the same 3×5 grid (skin tones × hairstyles) as the base sheet.
- **D-12:** Each outfit variant saved in: `assets/images/avatars/base/{archetype}/outfits/{outfitId}/{skinTone}_{hairStyle}.png`

### Outfit Variants per Archetype (locked)
| Archetype | Outfit 1 (default) | Outfit 2 | Outfit 3 |
|-----------|-------------------|----------|----------|
| Athlete | Training Gear | Competition Day | Recovery Mode |
| Creator | Studio Session | Gallery Opening | Sketchbook Day |
| Scholar | Academic | Field Research | Lecture Hall |
| Stoic | Training Gi | Minimalist Casual | Ceremonial |
| Zealot | Monastic Robe | Battle Vestment | Pilgrim Cloak |

### Evolution Phases
- **D-13:** 5 phases, shared across all archetypes. Applied as code-driven overlay (glow/effects), NOT a separate image per archetype.
- **D-14:** Each phase has its own PNG overlay: `assets/images/avatars/evolved/{phase}/overlay.png`
- **D-15:** Phases: phantom (Lv 1–5) → construct (Lv 6–15) → incarnate (Lv 16–30) → radiant (Lv 31–50) → ascended (Lv 50+)

### Item Shop
- **D-16:** Three categories of shop assets: **(A)** 9 predefined artifact icons, **(B)** outfit skin thumbnails, **(C)** blueprint scroll icons by difficulty tier.
- **D-17:** Artifact icons at 2 sizes: 64×64px (grid view) and 128×128px (detail view).
- **D-18:** Outfit thumbnail size: 256×384px (portrait card, showing full character preview).
- **D-19:** Blueprint scrolls: 3 icons (beginner / intermediate / advanced) at 128×128px.
- **D-20:** All shop assets on solid green or transparent bg.

### World Map Backgrounds
- **D-21:** 5 health states per biome — **all 5** generated as distinct images (not code-filter approximations): thriving, healthy, neutral, decaying, withered.
- **D-22:** Total: 5 biomes × 5 states = **25 background images**.
- **D-23:** Resolution: 1920×1080px (landscape), seamlessly tileable horizontally.
- **D-24:** No evolved biome states beyond the 5 defined biomes. Level progression advances biome, not an alternate evolved map.
- **D-25:** Biome health state is driven by `ZoneVisualState` enum in `world_zone.dart`.

### Document Structure
- **D-26:** One MD file per archetype containing: visual identity brief, color palette, outfit table, hairstyle list, then all generation prompts.
- **D-27:** Supporting files: `evolution_stages.md`, `world_map_backgrounds.md`, `item_shop.md`.
</decisions>

<canonical_refs>
## Canonical References

Downstream agents MUST read these before planning or implementing.

### Avatar System
- `lib/features/avatar/domain/models/avatar_config.dart` — AvatarConfig, SkinTone, HairColor enums; asset key convention; default hair per archetype
- `lib/features/avatar/data/services/avatar_asset_service.dart` — getCharacterPath() convention, hairstyle lists per archetype, generation prompt template
- `lib/features/avatar/presentation/widgets/avatar_renderer.dart` — rendering layers, evolved overlay logic, showEvolvedOverlay condition

### Evolution Phases
- `lib/features/profile/domain/models/silhouette_evolution.dart` — EvolutionPhase enum, phaseFromLevel() thresholds, BodyArtifact catalog (9 artifacts), BodyZone, ArtifactCategory

### World Map
- `lib/features/world_map/domain/models/archetype_map_config.dart` — BiomeType enum, getBiomeForLevel(), getBiomeColors(), getBiomeName()
- `lib/features/gamification/domain/models/world_zone.dart` — WorldZone, ZoneState, ZoneVisualState (5 health states)

### Item Shop
- `lib/features/gamification/domain/models/blueprint.dart` — Blueprint, BlueprintDifficulty (beginner/intermediate/advanced)
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `AvatarAssetService.getGenerationPrompt()` — existing prompt template. New prompts must maintain style lock.
- `AvatarAssetService.getAvailableHairstyles()` — hairstyle IDs already defined per archetype. Asset filenames must match exactly.
- `ArchetypeMapConfig.getBiomeColors()` — hex colours already definitive for biome backgrounds.

### Established Patterns
- Single baked PNG per character (no body-part composition at runtime). Outfit variant = separate baked PNG.
- Asset path convention uses `{skinTone.name}_{hairStyle}` as filename. E.g., `mediumBrown_short_spiky.png`.
- Evolution overlay is archetype-agnostic (one overlay PNG per phase, not per archetype).
- World map biome unlocks by level bracket, not by evolved state after level 50.

### Integration Points
- `AvatarRenderer._buildCharacterImage()` → calls `AvatarAssetService.getCharacterPathFromConfig()` → path must match D-09
- `AvatarRenderer._buildEvolvedOverlay()` → calls `AvatarAssetService.getEvolvedOverlayPath(phase)` → path must match D-14
- `ZoneState.visualState` getter → maps health 0.0–1.0 to `ZoneVisualState` → determines which of the 5 background images is shown
</code_context>

<specifics>
## Specific Ideas

- Each archetype file should read as a style bible — visual identity paragraph first, then palette chips, then outfits, then prompts.
- Item shop blueprint scrolls: 3 tiers (beginner = common parchment, intermediate = aged scroll with seal, advanced = glowing relic scroll). These are shop purchase icons, not the blueprint content itself.
- World map backgrounds must look naturalistic — not game-UI flat. Think environmental art that feels like a living world painting.
</specifics>

<deferred>
## Deferred Ideas

- Grok animation prompts for character idle/attack loops → separate phase
- Blender chroma key extraction pipeline → separate phase
- Season overlay event assets (Spring Bloom, Winter Wonderland) → separate phase
- World zone buildings (Garden, Library, Forge, Studio, Shrine) → separate phase
- Animated evolution transition (Ascension cinematic) → separate phase
</deferred>

---

*Phase: avatar-world-map-assets*
*Context gathered: 2026-04-16*
