# Timeline Header & World Map Redesign Plan

## Summary
Four workstreams: (1) new glassmorphic header per `docs/timeline-redesign-preview.html`, (2) header rollout across main screens, (3) world map flame-video background + orb removal, (4) splash logo replacement (native + web). Verified facts: video files exist at workspace root (`neutral and increasing flame/Plasma_flame_surge_cycle_loop_202607300232.mp4`, `decreasing and dimming flame/Plasma_flame_cycle_background_video_202607300232.mp4`); `video_player` is NOT in `pubspec.yaml`; `/paywall` route exists in `lib/core/router/router.dart` (line ~326); `flutter_native_splash.yaml` has `web: false`; new logo source is a JPG (transparency likely flattened — needs processing).

## Shared Header Component (Workstream A)

**New file: `lib/core/presentation/widgets/emerge_header.dart`** — a reusable `EmergeHeader` ConsumerWidget matching the HTML spec exactly:
- Layout: `Row` with `spaceBetween`; container padding `18h / 12v(bottom)`; bottom border `Colors.white.withValues(alpha: 0.08)`; background `Colors.white.withValues(alpha: 0.02)`; wrap in `SafeArea`.
- Left: 38×38 circular avatar — background 8% white, 1px border 14% white, centered user initial in teal (`#34D4B8` at 85% alpha), bold. `onTap` param (timeline passes `context.push('/profile')`).
- Right: chip row (8px gap). Chip style: padding `6v/10h`, radius 999, 1px border 8% white, background 4% white, font 12, color `rgba(246,247,251,0.65)`.
  - **"Today" chip**: shown when `showToday: true` (timeline passes `_isToday(_selectedDate)`).
  - **Subscription chip** (the pro/free differentiation): watch `isPremiumProvider` (`lib/features/monetization/presentation/providers/subscription_provider.dart`). Premium → "PRO" chip in teal accent (teal text `#34D4B8`, teal 12% bg, teal 30% border). Non-premium → "Free Trial" chip (standard chip style, amber text `#F5A623` at 85%) wrapped in `InkWell` → `context.push('/paywall')`. Handle `AsyncValue` loading branch by rendering `SizedBox.shrink()` (no flicker of wrong tier).
- Params: `displayName`, `showToday`, `selectedDate?`, `onAvatarTap`, optional `trailing` extras. Keep it const-friendly; no `userStatsStreamProvider` watch (only `isPremiumProvider`).

**Riverpod/codegen**: plain ConsumerWidget, no new providers needed. Follow project chip/glass tokens from `docs/design.md` (glassWhite 8%, glassBorder 15% where applicable).

## Timeline Integration (Workstream A, same Coding agent)

**Edit `lib/features/timeline/presentation/screens/timeline_screen.dart` (lines 309–360):**
- Replace the `ArchetypeSliverAppBar(...)` block (lines 311–360) with `SliverToBoxAdapter(child: EmergeHeader(...))` passing `displayName`, `showToday: <selectedDate is today>`, `onAvatarTap: () => context.push('/profile')`.
- Remove the inline amber PRO `badge:` Consumer (lines 339–358) and the `momentumDot` Consumer (lines 317–337) — the HTML design intentionally compresses the header to avatar + chips. Keep `_ProfileInitialAvatar` logic by folding the initial-derivation into `EmergeHeader` (reuse its display-name→initial code from lines 708–726); delete `_ProfileInitialAvatar` if no longer referenced.
- Do NOT touch the calendar strip, tribal presence strip, hero/milestone rows, or habit sections.
- Remove now-unused imports (`ArchetypeSliverAppBar`, `momentumColorValue` if unused).

## Header Rollout Across Screens (Workstream B — after A completes)

Apply `EmergeHeader` to the other main-tab screens, adapted per screen:
- **Social** (`lib/features/social/presentation/screens/social_screen.dart`, header ~line 113): insert `EmergeHeader` (no "Today" chip) above the existing tab-bar delegate as a `SliverToBoxAdapter`; keep the TabBar.
- **Profile** (`lib/features/profile/presentation/screens/future_self_studio_screen.dart`, ~line 198): add `EmergeHeader` at top; avatar tap is a no-op or navigates to `/profile/settings` (choose settings — gives the header a purpose on this screen).
- **World Map** (`lib/features/world_map/presentation/screens/world_map_screen.dart`): replace the top `WorldStateHUD` Positioned wrapper (lines 131–144) area with a top-aligned column: `EmergeHeader` (no "Today" chip) followed by `WorldStateHUD` beneath it.
- Screens keep their own body content; only the top identity strip is unified. Detail/modal screens (Settings, Leaderboard, Creator) are explicitly out of scope.

## World Map Flame Videos + Orb Removal (Workstream C)

**1. Dependency & assets:**
- `pubspec.yaml`: add `video_player: ^2.8.0` to dependencies (after line 82); add asset entry `- assets/videos/world_health/` to the `flutter.assets` list (~line 150).
- Copy videos: `neutral and increasing flame/Plasma_flame_surge_cycle_loop_202607300232.mp4` → `assets/videos/world_health/neutral_increasing.mp4`; `decreasing and dimming flame/Plasma_flame_cycle_background_video_202607300232.mp4` → `assets/videos/world_health/decreasing_dimming.mp4`. Run `flutter pub get`.

**2. New file `lib/features/world_map/presentation/widgets/world_flame_video_background.dart`:**
- `WorldFlameVideoBackground` StatefulWidget with params: `healthState` (reuse `WorldHealthState.fromHealth(health)` mapping — healthy/neutral → `neutral_increasing.mp4`, degraded → `decreasing_dimming.mp4`; threshold consistent with existing `WorldHealthState` enum semantics), `fallback` widget.
- Pre-initialize BOTH `VideoPlayerController.asset(...)` controllers in `initState` with `setLooping(true)` and `setVolume(0)` (muted — required for web autoplay). Crossfade between them on state change via `AnimatedOpacity`/`AnimatedCrossFade` (400ms), both wrapped in `FittedBox`/`SizedBox.expand` cover-fit.
- While neither controller is initialized OR on init error: render `fallback` (the existing `NebulaBackground`). Never throw. Dispose both controllers in `dispose()`.

**3. Edit `lib/features/world_map/presentation/screens/world_map_screen.dart`:**
- Replace the `NebulaBackground` Stack child (lines 95–100) with `WorldFlameVideoBackground(healthState: ..., fallback: NebulaBackground(...))` as base layer. Keep `AmbientParticles`, `ConstellationLines`, `WorldRingLayout` on top.
- **Remove the orb**: delete the `Center(child: CentralHealthOrb(...))` block (lines 113–119) and the import (line 12). Leave `central_health_orb.dart` file in place (unused).
- **Preserve status-panel access**: orb tap currently toggles `_showStatus`. Wrap the `WorldStateHUD` in a `GestureDetector` toggling `_showStatus` instead (restructuring permitted by user).

**4. Test updates** (`test/features/world_map/presentation/screens/world_map_screen_test.dart`): remove/adjust any orb-related expectations (~lines 82–84); the video widget renders its fallback in tests (asset video won't initialize under flutter_test), so assert `NebulaBackground`/ring layout presence instead.

## Splash Logo Replacement (Workstream D — independent)

1. **Process source image**: source `C:\Users\HP\AppData\Roaming\Qoder\SharedClientCache\cache\images\d5c5e55d\app_icon.png_202607300234-90cb3942.jpg` is JPEG — the transparent background is likely flattened into a checkerboard. Convert to PNG with true transparency (Python/PIL script: remove checkerboard/near-white background via chroma threshold, or flatten onto `#121214` if clean removal fails). Save as `assets/icons/splash_logo_flame.png`. Visually verify against dark `#121214` before wiring up.
2. **`flutter_native_splash.yaml`**: change `image:` (line 3) and `android_12.image:` (line 5) to `assets/icons/splash_logo_flame.png`; change `web: false` (line 10) to `web: true` so the web splash is generated too. Keep `#121214` colors.
3. Run `dart run flutter_native_splash:create` and confirm generated Android/iOS/web splash artifacts; spot-check `web/index.html` still boots correctly.

## Execution Order & Dependencies
- Workstream A (header + timeline), C (world map), D (splash) run in **parallel** — disjoint files, separate Coding agents. Exception: C owns `world_map_screen.dart`; B's world-map header edit must wait for C.
- Workstream B (rollout) starts **after A and C complete** (depends on `EmergeHeader` existing and C's world_map_screen changes).
- Verify after each workstream: `dart analyze` + focused tests only (`flutter test test/features/timeline/...`, `test/features/world_map/...`). **No full test suite.**
- Final: Browser E2E on web build — timeline header (avatar → profile nav, Today + PRO/Free Trial chips), world map (video plays muted, no orb, status panel toggles via HUD tap), splash shows new flame; then 3-dimension code review (completeness / correctness / impact).

## Test Plan
- `dart analyze` clean after each workstream.
- Focused widget tests: timeline screen test still passes (header change doesn't break FAB/skeleton assertions); world map test updated for orb removal + video fallback.
- Browser verification of web build for header behavior, video autoplay (muted), and splash.

## Risks & Mitigations
- **JPG checkerboard baked into logo** → mandatory background-removal step with visual verification before splash regeneration.
- **Web video autoplay blocked** → controllers muted (`setVolume(0)`); fallback NebulaBackground always available.
- **State-transition jank** → both controllers pre-initialized; 400ms crossfade.
- **Orb removal kills status-panel toggle** → toggle moved to WorldStateHUD tap.
- **isPremiumProvider async flicker** → render nothing until value resolves; never show "Free Trial" during loading.
- **Test regressions** → world map test updated in the same task as the orb removal; timeline tests unaffected by additive header.

## Rejected Alternatives
- **Keep orb hidden behind a flag** (Alex's option): violates the explicit "remove the orb" requirement.
- **Single video controller recreated on state change** (Tina's approach): smaller memory footprint but causes a visible black gap/jank on health-state transitions; dual pre-initialized controllers chosen instead (~5MB extra memory, acceptable).
- **Rive/Lottie instead of video**: cannot reproduce the provided realistic plasma-flame footage; larger integration effort.
- **Web splash via manifest icons only**: doesn't actually change the boot splash; enabling `web: true` in flutter_native_splash is the correct mechanism.
- **Timeline-only header (defer rollout)**: rejected because the user explicitly required the new header style across screens; rollout is scoped to the 4 main tabs to bound risk.