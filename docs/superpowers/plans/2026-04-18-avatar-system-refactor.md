# Avatar System Refactor — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refactor the Emerge avatar system from a skin-tone/hairstyle-based full-body PNG approach to a silhouette-reveal progression model — 21 generated image assets replace the planned 225, and the code-painted silhouette drives all rendering from Level 1 through 49.

**Architecture:** `AvatarAssetService` is updated to return the archetype's single `ascended.png` only at EvolutionPhase.ascended; all other phases fall through to the existing `_FallbackSilhouettePainter`. `AvatarConfig` drops `skinTone` and `hairStyle` from its rendering path. The asset directory layout is simplified to `base/{archetype}/ascended.png` + `evolved/{phase}/overlay.png`.

**Tech Stack:** Flutter/Dart, `CustomPainter`, `Image.asset`, `Stack` widget composition. No new packages required.

---

## File Map

| File | Action | Responsibility |
|------|--------|---------------|
| `lib/features/avatar/data/services/avatar_asset_service.dart` | **Modify** | Asset path resolution logic |
| `lib/features/avatar/domain/models/avatar_config.dart` | **Modify** | Remove skinTone/hairStyle from rendering fields |
| `lib/features/avatar/presentation/widgets/avatar_renderer.dart` | **Modify** | Wire phase-conditional character image path |
| `test/features/avatar/avatar_asset_service_test.dart` | **Create** | Unit tests for path resolution |
| `test/features/avatar/avatar_renderer_test.dart` | **Create** | Widget tests for layer rendering |
| `assets/images/avatars/` | **Reorganise** | Add placeholder PNGs at new paths |

---

## Task 1: Add Placeholder Asset Files

Before any code change, establish the expected directory structure so Flutter's asset bundler doesn't error during hot reload.

**Files:**
- Create directory tree: `assets/images/avatars/base/{archetype}/ascended.png` (5 files)
- Create directory tree: `assets/images/avatars/evolved/{phase}/overlay.png` (4 files)
- Create: `assets/images/avatars/effects/glow_soft.png`
- Create: `assets/images/avatars/effects/glow_strong.png`
- Create: `assets/images/avatars/effects/sparkles.png`

- [ ] **Step 1: Create placeholder PNGs via PowerShell**

  Run from the project root:

  ```powershell
  $pngBytes = [byte[]](137,80,78,71,13,10,26,10,0,0,0,13,73,72,68,82,0,0,0,1,0,0,0,1,8,6,0,0,0,31,21,196,137,0,0,0,11,73,68,65,84,8,215,99,248,15,0,0,1,1,0,5,24,213,78,0,0,0,0,73,69,78,68,174,66,96,130)

  $dirs = @(
    "assets/images/avatars/base/athlete",
    "assets/images/avatars/base/creator",
    "assets/images/avatars/base/scholar",
    "assets/images/avatars/base/stoic",
    "assets/images/avatars/base/zealot",
    "assets/images/avatars/evolved/construct",
    "assets/images/avatars/evolved/incarnate",
    "assets/images/avatars/evolved/radiant",
    "assets/images/avatars/evolved/ascended",
    "assets/images/avatars/effects",
    "assets/images/avatars/shop/artifacts"
  )

  foreach ($dir in $dirs) {
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
  }

  $files = @(
    "assets/images/avatars/base/athlete/ascended.png",
    "assets/images/avatars/base/creator/ascended.png",
    "assets/images/avatars/base/scholar/ascended.png",
    "assets/images/avatars/base/stoic/ascended.png",
    "assets/images/avatars/base/zealot/ascended.png",
    "assets/images/avatars/evolved/construct/overlay.png",
    "assets/images/avatars/evolved/incarnate/overlay.png",
    "assets/images/avatars/evolved/radiant/overlay.png",
    "assets/images/avatars/evolved/ascended/overlay.png",
    "assets/images/avatars/effects/glow_soft.png",
    "assets/images/avatars/effects/glow_strong.png",
    "assets/images/avatars/effects/sparkles.png"
  )

  foreach ($f in $files) {
    [System.IO.File]::WriteAllBytes($f, $pngBytes)
    Write-Host "Created $f"
  }
  ```

- [ ] **Step 2: Verify files exist**

  ```powershell
  Get-ChildItem -Recurse assets/images/avatars/ | Select-Object FullName
  ```

  Expected: 12 files listed.

- [ ] **Step 3: Update `pubspec.yaml` asset declarations**

  Add under `flutter.assets:`:

  ```yaml
      - assets/images/avatars/base/athlete/
      - assets/images/avatars/base/creator/
      - assets/images/avatars/base/scholar/
      - assets/images/avatars/base/stoic/
      - assets/images/avatars/base/zealot/
      - assets/images/avatars/evolved/construct/
      - assets/images/avatars/evolved/incarnate/
      - assets/images/avatars/evolved/radiant/
      - assets/images/avatars/evolved/ascended/
      - assets/images/avatars/effects/
      - assets/images/avatars/shop/artifacts/
  ```

- [ ] **Step 4: Verify Flutter sees assets**

  ```bash
  flutter pub get
  ```

  Expected: exits 0, no asset errors.

- [ ] **Step 5: Commit**

  ```bash
  git add assets/ pubspec.yaml
  git commit -m "chore: scaffold avatar asset directory with placeholder PNGs"
  ```

---

## Task 2: Refactor `AvatarAssetService`

Replace the skin-tone/hairstyle path builder with a phase-aware path builder.

**Files:**
- Modify: `lib/features/avatar/data/services/avatar_asset_service.dart`
- Create: `test/features/avatar/avatar_asset_service_test.dart`

- [ ] **Step 1: Write failing tests**

  Create `test/features/avatar/avatar_asset_service_test.dart`:

  ```dart
  import 'package:emerge_app/features/avatar/data/services/avatar_asset_service.dart';
  import 'package:emerge_app/features/avatar/domain/models/avatar_config.dart';
  import 'package:emerge_app/features/profile/domain/models/silhouette_evolution.dart';
  import 'package:flutter_test/flutter_test.dart';

  void main() {
    late AvatarAssetService service;

    setUp(() => service = AvatarAssetService());

    group('getCharacterPath', () {
      test('returns ascended path when phase is ascended', () {
        expect(
          service.getCharacterPath(UserArchetype.athlete, EvolutionPhase.ascended),
          'assets/images/avatars/base/athlete/ascended.png',
        );
      });

      test('returns empty string for phantom phase', () {
        expect(
          service.getCharacterPath(UserArchetype.creator, EvolutionPhase.phantom),
          '',
        );
      });

      test('returns empty string for construct phase', () {
        expect(
          service.getCharacterPath(UserArchetype.scholar, EvolutionPhase.construct),
          '',
        );
      });

      test('returns empty string for incarnate phase', () {
        expect(
          service.getCharacterPath(UserArchetype.stoic, EvolutionPhase.incarnate),
          '',
        );
      });

      test('returns empty string for radiant phase', () {
        expect(
          service.getCharacterPath(UserArchetype.zealot, EvolutionPhase.radiant),
          '',
        );
      });
    });

    group('getEvolvedOverlayPath', () {
      test('returns correct path for construct', () {
        expect(
          service.getEvolvedOverlayPath(EvolutionPhase.construct),
          'assets/images/avatars/evolved/construct/overlay.png',
        );
      });

      test('returns correct path for radiant', () {
        expect(
          service.getEvolvedOverlayPath(EvolutionPhase.radiant),
          'assets/images/avatars/evolved/radiant/overlay.png',
        );
      });

      test('returns empty string for phantom', () {
        expect(
          service.getEvolvedOverlayPath(EvolutionPhase.phantom),
          '',
        );
      });
    });
  }
  ```

- [ ] **Step 2: Run tests — verify they fail**

  ```bash
  flutter test test/features/avatar/avatar_asset_service_test.dart -v
  ```

  Expected: compile errors or failures — `getCharacterPath` still takes old signature.

- [ ] **Step 3: Rewrite `AvatarAssetService`**

  Replace entire content of `lib/features/avatar/data/services/avatar_asset_service.dart`:

  ```dart
  import 'package:emerge_app/features/avatar/domain/models/avatar_config.dart';
  import 'package:emerge_app/core/theme/archetype_theme.dart';
  import 'package:emerge_app/features/profile/domain/models/silhouette_evolution.dart';

  /// Service for resolving avatar asset paths.
  ///
  /// Uses a silhouette-reveal progression model:
  /// - Levels 1-49: returns empty string, renderer falls back to code painter
  /// - Level 50+ (Ascended): returns archetype-specific character art path
  class AvatarAssetService {
    static const String _basePath = 'assets/images/avatars';

    /// Returns character image path. Empty string for non-Ascended phases.
    String getCharacterPath(UserArchetype archetype, EvolutionPhase phase) {
      if (phase == EvolutionPhase.ascended) {
        return '$_basePath/base/${archetype.name}/ascended.png';
      }
      return '';
    }

    /// Returns overlay PNG path. Empty string for phantom (no overlay).
    String getEvolvedOverlayPath(EvolutionPhase phase) {
      if (phase == EvolutionPhase.phantom) return '';
      return '$_basePath/evolved/${phase.name}/overlay.png';
    }

    /// Static archetype silhouette PNG (mid-level fallback).
    String getSilhouettePath(UserArchetype archetype) {
      return '$_basePath/${archetype.name}_silhouette.png';
    }

    /// Archetype portrait for onboarding/selection UI.
    String getArchetypePortraitPath(UserArchetype archetype) {
      return ArchetypeTheme.forArchetype(archetype).assetPath;
    }

    /// Glow effect asset path.
    String getGlowEffectPath({bool strong = false}) {
      return strong
          ? '$_basePath/effects/glow_strong.png'
          : '$_basePath/effects/glow_soft.png';
    }

    /// Sparkles effect asset path (Ascended only).
    String getSparklesPath() {
      return '$_basePath/effects/sparkles.png';
    }
  }
  ```

- [ ] **Step 4: Run tests — verify they pass**

  ```bash
  flutter test test/features/avatar/avatar_asset_service_test.dart -v
  ```

  Expected: all 8 tests PASS.

- [ ] **Step 5: Commit**

  ```bash
  git add lib/features/avatar/data/services/avatar_asset_service.dart
  git add test/features/avatar/avatar_asset_service_test.dart
  git commit -m "refactor(avatar): phase-aware asset path resolution, remove skin/hair params"
  ```

---

## Task 3: Update `AvatarConfig` — Remove Unused Rendering Fields

**Files:**
- Modify: `lib/features/avatar/domain/models/avatar_config.dart`

- [ ] **Step 1: Read the current file**

  Open `lib/features/avatar/domain/models/avatar_config.dart`. Note all constructor params, `copyWith`, `fromJson`/`toJson` methods and any `skinTone`/`hairStyle` references.

- [ ] **Step 2: Slim down `AvatarConfig`**

  Replace the class with (preserving any fields not related to skin/hair):

  ```dart
  /// Configuration for avatar rendering.
  ///
  /// Avatar is fully defined by [archetype] and [evolvedState].
  /// Skin tone and hairstyle are not used — silhouette is archetype-defined.
  class AvatarConfig {
    final UserArchetype archetype;
    final EvolutionPhase evolvedState;

    const AvatarConfig({
      required this.archetype,
      this.evolvedState = EvolutionPhase.phantom,
    });

    /// Show the evolved overlay for all phases except phantom.
    bool get showEvolvedOverlay => evolvedState != EvolutionPhase.phantom;

    AvatarConfig copyWith({
      UserArchetype? archetype,
      EvolutionPhase? evolvedState,
    }) {
      return AvatarConfig(
        archetype: archetype ?? this.archetype,
        evolvedState: evolvedState ?? this.evolvedState,
      );
    }
  }
  ```

- [ ] **Step 3: Fix all callsite compile errors**

  ```bash
  flutter analyze
  ```

  For every error where `skinTone:` or `hairStyle:` is passed to `AvatarConfig(...)`, remove that named argument.

- [ ] **Step 4: Verify zero analysis errors**

  ```bash
  flutter analyze
  ```

  Expected: `No issues found!`

- [ ] **Step 5: Commit**

  ```bash
  git add lib/features/avatar/domain/models/avatar_config.dart
  git commit -m "refactor(avatar): remove skinTone and hairStyle from AvatarConfig"
  ```

---

## Task 4: Update `AvatarRenderer`

**Files:**
- Modify: `lib/features/avatar/presentation/widgets/avatar_renderer.dart`
- Create: `test/features/avatar/avatar_renderer_test.dart`

- [ ] **Step 1: Write failing widget tests**

  Create `test/features/avatar/avatar_renderer_test.dart`:

  ```dart
  import 'package:emerge_app/features/avatar/domain/models/avatar_config.dart';
  import 'package:emerge_app/features/avatar/presentation/widgets/avatar_renderer.dart';
  import 'package:emerge_app/features/profile/domain/models/silhouette_evolution.dart';
  import 'package:flutter/material.dart';
  import 'package:flutter_test/flutter_test.dart';

  Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  void main() {
    group('AvatarRenderer', () {
      testWidgets('renders without error at phantom phase', (tester) async {
        await tester.pumpWidget(_wrap(
          AvatarRenderer(
            config: AvatarConfig(
              archetype: UserArchetype.athlete,
              evolvedState: EvolutionPhase.phantom,
            ),
          ),
        ));
        expect(find.byType(AvatarRenderer), findsOneWidget);
      });

      testWidgets('renders without error at ascended phase', (tester) async {
        await tester.pumpWidget(_wrap(
          AvatarRenderer(
            config: AvatarConfig(
              archetype: UserArchetype.zealot,
              evolvedState: EvolutionPhase.ascended,
            ),
          ),
        ));
        expect(find.byType(AvatarRenderer), findsOneWidget);
      });

      testWidgets('shows phase label by default', (tester) async {
        await tester.pumpWidget(_wrap(
          AvatarRenderer(
            config: AvatarConfig(
              archetype: UserArchetype.scholar,
              evolvedState: EvolutionPhase.incarnate,
            ),
          ),
        ));
        expect(find.text('THE INCARNATE'), findsOneWidget);
      });

      testWidgets('hides phase label when showPhaseLabel is false', (tester) async {
        await tester.pumpWidget(_wrap(
          AvatarRenderer(
            config: AvatarConfig(
              archetype: UserArchetype.stoic,
              evolvedState: EvolutionPhase.radiant,
            ),
            showPhaseLabel: false,
          ),
        ));
        expect(find.text('THE RADIANT'), findsNothing);
      });
    });
  }
  ```

- [ ] **Step 2: Run tests — verify compile/failures**

  ```bash
  flutter test test/features/avatar/avatar_renderer_test.dart -v
  ```

- [ ] **Step 3: Update `_buildCharacterImage()` in `AvatarRenderer`**

  Replace `_buildCharacterImage()` with:

  ```dart
  Widget _buildCharacterImage() {
    final characterPath = _assetService.getCharacterPath(
      config.archetype,
      config.evolvedState,
    );

    if (characterPath.isEmpty) {
      return _buildSilhouetteFallback();
    }

    return SizedBox(
      width: size,
      height: size * 1.2,
      child: Image.asset(
        characterPath,
        width: size,
        height: size * 1.2,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _buildSilhouetteFallback(),
      ),
    );
  }

  Widget _buildSilhouetteFallback() {
    return SizedBox(
      width: size,
      height: size * 1.2,
      child: Image.asset(
        _assetService.getSilhouettePath(config.archetype),
        width: size,
        height: size * 1.2,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => CustomPaint(
          size: Size(size, size * 1.2),
          painter: _FallbackSilhouettePainter(color: _primaryColor),
        ),
      ),
    );
  }
  ```

- [ ] **Step 4: Update `_buildEvolvedOverlay()` to guard empty path**

  ```dart
  Widget _buildEvolvedOverlay(EvolutionPhase phase) {
    final overlayPath = _assetService.getEvolvedOverlayPath(phase);
    final overlayColor = _getEvolvedOverlayColor(phase);

    return SizedBox(
      width: size,
      height: size * 1.2,
      child: Stack(
        children: [
          if (overlayPath.isNotEmpty)
            Image.asset(
              overlayPath,
              width: size,
              height: size * 1.2,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          Container(
            width: size,
            height: size * 1.2,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(size * 0.45),
              border: Border.all(
                color: overlayColor.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
  ```

- [ ] **Step 5: Run all avatar tests**

  ```bash
  flutter test test/features/avatar/ -v
  ```

  Expected: all tests PASS.

- [ ] **Step 6: Hot reload visual check**

  ```bash
  flutter run
  ```

  Navigate to avatar screen. Confirm: phantom silhouette renders, phase label shows, no console errors.

- [ ] **Step 7: Commit**

  ```bash
  git add lib/features/avatar/presentation/widgets/avatar_renderer.dart
  git add test/features/avatar/avatar_renderer_test.dart
  git commit -m "refactor(avatar): wire phase-aware character path, extract silhouette fallback"
  ```

---

## Task 5: Remove Deprecated Helpers from `AvatarAssetService`

**Files:**
- Modify: `lib/features/avatar/data/services/avatar_asset_service.dart`

- [ ] **Step 1: Search for remaining usages**

  ```powershell
  Select-String -Path "lib/**/*.dart" -Pattern "getCharacterPathFromConfig|getAvailableHairstyles|getAvailableSkinTones|getGenerationPrompt|getNegativePrompt" -Recurse
  ```

  Expected: zero results.

- [ ] **Step 2: Delete dead methods if still in file**

  Remove: `getCharacterPathFromConfig`, `getAvailableHairstyles`, `getAvailableSkinTones`, `getGenerationPrompt`, `getNegativePrompt`, and all their private helpers.

- [ ] **Step 3: Verify**

  ```bash
  flutter analyze
  flutter test -v
  ```

  Expected: zero issues, all tests pass.

- [ ] **Step 4: Commit**

  ```bash
  git add lib/features/avatar/data/services/avatar_asset_service.dart
  git commit -m "chore(avatar): remove deprecated skinTone/hair helpers from AvatarAssetService"
  ```

---

## Task 6: Remove Onboarding Skin/Hair Picker UI

**Files:**
- Search and modify any file in `lib/features/onboarding/` or `lib/features/profile/` referencing `SkinTone`, `hairStyle`, `skinTone`, `getAvailableHairstyles`

- [ ] **Step 1: Find all UI references**

  ```powershell
  Select-String -Path "lib/**/*.dart" -Pattern "SkinTone|hairStyle|skinTone|getAvailableHairstyles" -Recurse
  ```

- [ ] **Step 2: Remove picker widgets and their state**

  For each file found: remove the picker widget, its local state variable, and its on-change handler.
  If the entire screen was only the picker, delete the file and remove its route from `go_router`.

- [ ] **Step 3: Remove `SkinTone` enum if unused**

  ```powershell
  Select-String -Path "lib/**/*.dart" -Pattern "SkinTone" -Recurse
  ```

  If zero results, delete the enum definition.

- [ ] **Step 4: Verify**

  ```bash
  flutter analyze
  flutter test -v
  ```

- [ ] **Step 5: Commit**

  ```bash
  git add -A
  git commit -m "chore(onboarding): remove skin tone and hairstyle selection UI"
  ```

---

## Task 7: Update Asset Generation Documentation

**Files:**
- Create: `docs/asset_generation/avatar_ascended.md`
- Create: `docs/asset_generation/evolution_overlays.md`
- Move old files to: `docs/asset_generation/archive/`

- [ ] **Step 1: Archive old prompt files**

  ```powershell
  New-Item -ItemType Directory -Force "docs/asset_generation/archive"
  @("athlete","athlete_outfits_2_3","creator","creator_outfits_2_3","scholar","scholar_outfits_2_3","stoic","stoic_outfits_2_3","zealot","zealot_outfits_2_3") | ForEach-Object {
    Move-Item "docs/asset_generation/$_.md" "docs/asset_generation/archive/$_.md" -ErrorAction SilentlyContinue
  }
  ```

- [ ] **Step 2: Create `docs/asset_generation/avatar_ascended.md`**

  File content — 5 generation prompts, one per archetype:

  **athlete/ascended.png**
  ```
  2D game character art, cel-shaded coloring, flat vector fills, bold clean ink outline 2-3px,
  full body front-facing standing idle pose, slight forward weight dynamic energy,
  lean muscular build no explicit gender markers, solid green screen background RGB(0,255,0),
  no text no watermark. The Ascended Athlete: electric-blue competition race suit #2D87F0
  with navy block panels at shoulders and outer thighs, lightweight pointed race shoes,
  vertical energy lines radiating upward from both feet like speed trails, faint electric
  aura emanating from the body edge, archetype color electric-blue #2D87F0.
  Cel-shading flat fill plus 1 hard shadow tone plus 1 bright highlight no gradients.
  ```

  **creator/ascended.png**
  ```
  2D game character art, cel-shaded coloring, flat vector fills, bold clean ink outline 2-3px,
  full body front-facing standing idle pose, relaxed open posture arms slightly away from body,
  slender expressive build no explicit gender markers, solid green screen background RGB(0,255,0),
  no text no watermark. The Ascended Creator: paint-splattered linen drape in off-white
  with magenta cobalt and yellow paint marks, chunky platform shoes, three small glowing tools
  orbiting at mid-torso a quill brush and amber orb each trailing a faint circular orbit arc,
  soft magenta glow aura around the entire figure, archetype color magenta #E040FB.
  Cel-shading flat fill plus 1 hard shadow tone plus 1 bright highlight no gradients.
  ```

  **scholar/ascended.png**
  ```
  2D game character art, cel-shaded coloring, flat vector fills, bold clean ink outline 2-3px,
  full body front-facing standing idle pose, maximally upright chin slightly raised,
  lean upright build no explicit gender markers, solid green screen background RGB(0,255,0),
  no text no watermark. The Ascended Scholar: deep forest green academic gown floor-length
  #1B5E20 open front over parchment shirt, amber wire oval spectacles, right hand holds
  an open glowing book pages emitting soft amber light #E0AF68, faint green knowledge-web
  aura of geometric lines around the figure, archetype color forest-green #2E7D32.
  Cel-shading flat fill plus 1 hard shadow tone plus 1 bright highlight no gradients.
  ```

  **stoic/ascended.png**
  ```
  2D game character art, cel-shaded coloring, flat vector fills, bold clean ink outline 2-3px,
  full body front-facing standing idle pose, perfectly balanced weight completely still,
  balanced strong build no explicit gender markers, solid green screen background RGB(0,255,0),
  no text no watermark. The Ascended Stoic: slate blue column robe #455A64 floor-length
  high mandarin neck, deep indigo structured obi belt #1A237E rectangular knot, grey prayer
  beads at left wrist, faint concentric circle aura rings emanating outward at ground level,
  archetype color slate-grey #546E7A.
  Cel-shading flat fill plus 1 hard shadow tone plus 1 bright highlight no gradients.
  ```

  **zealot/ascended.png**
  ```
  2D game character art, cel-shaded coloring, flat vector fills, bold clean ink outline 2-3px,
  full body front-facing standing idle pose, upright with faint forward intensity,
  tall willowy build no explicit gender markers, solid green screen background RGB(0,255,0),
  no text no watermark. The Ascended Zealot: dark indigo armour chest panel #1A237E over
  pale silver inner robe #CFD8DC, long flowing silver hair #B0BEC5, bright violet iris glow
  #BB9AF7, two long streaming indigo sash panels behind the figure, strong violet aura column
  rising through the figure upward, archetype color deep-indigo #303F9F.
  Cel-shading flat fill plus 1 hard shadow tone plus 1 bright highlight no gradients.
  ```

- [ ] **Step 3: Create `docs/asset_generation/evolution_overlays.md`**

  File content — 4 overlay texture prompts:

  **construct/overlay.png**
  ```
  Transparent PNG overlay texture 512x614px for compositing over a human silhouette.
  Blue-white geometric wireframe grid, thin lines 1-2px, triangular mesh topology,
  concentrated at body outline edge fading to transparent toward center,
  color electric-blue #7AA2F7 at 60% opacity on lines, rest fully transparent,
  no solid fill, no background, no text.
  ```

  **incarnate/overlay.png**
  ```
  Transparent PNG overlay texture 512x614px for compositing over a human silhouette.
  Soft inner-edge highlight band tracing body outline, 8-12px wide glowing edge stroke,
  slightly lighter than silhouette fill, secondary faint vertical highlight streak
  at center-left of torso, all elements at 70% opacity, rest fully transparent,
  no solid fill, no background, no text.
  ```

  **radiant/overlay.png**
  ```
  Transparent PNG overlay texture 512x614px for compositing over a human silhouette.
  Kintsugi gold crack network, irregular branching crack lines in bright gold #E0AF68
  3-4px wide with bright center and darker outer edge, cracks originate from chest-center
  branching to hands head knees, glowing gold inner light bleeding from each crack,
  cracks at 80-90% opacity, areas between cracks fully transparent,
  no solid fill, no background, no text.
  ```

  **ascended/overlay.png**
  ```
  Transparent PNG overlay texture 512x614px for compositing over a human character.
  Cyan-white energy aura emanating outward from body perimeter, soft diffuse outer glow
  from bright #00F0FF at body edge to fully transparent at 40-50px out, inner highlight ring
  pure white #FFFFFF at 30% opacity tight to body edge, faint vertical energy streaks
  rising from shoulders and head, all fading outward, center interior fully transparent,
  no solid fill, no background, no text.
  ```

- [ ] **Step 4: Commit**

  ```bash
  git add docs/asset_generation/
  git commit -m "docs(assets): replace 225-png approach with 21-image manifest; archive old prompts"
  ```

---

## Verification Checklist

- [ ] `flutter analyze` → `No issues found!`
- [ ] `flutter test` → all tests pass
- [ ] `flutter run` → avatar renders at Phantom phase, no runtime errors
- [ ] Phase label shows "THE PHANTOM" at profile screen
- [ ] Setting `evolvedState = EvolutionPhase.ascended` in debug → attempts `base/athlete/ascended.png`, falls back gracefully to code silhouette
- [ ] Onboarding has no skin tone or hairstyle picker
- [ ] `SkinTone` enum references = 0 (or removed)
