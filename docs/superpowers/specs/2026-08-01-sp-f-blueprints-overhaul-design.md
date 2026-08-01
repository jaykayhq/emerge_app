# SP-F: Blueprints Overhaul — Fix Images, Remove Standalone Page, Per-Tribe Curated Blueprints — Design Spec

**Date:** 2026-08-01
**Status:** Ready for implementation
**Plan:** `docs/superpowers/plans/2026-08-01-sp-f-blueprints-overhaul-plan.md`

---

## 1. Goals

User requirements (verbatim intent):

1. **"Some images for the blueprints arent showing"** — broken blueprint images must never render blank. Every blueprint surface falls back to a branded gradient+icon treatment when the image is missing, malformed, or fails to load.
2. **"The blueprints page shouldn't exist"** — the standalone browse page (`/social/discover`) is removed entirely, along with every entry point, its node-guide definition, and its visited-flag migration entry. Blueprint detail pages stay (they are reachable from tribe sections and deep links).
3. **"Give each tribe blueprints custom made for them from the ones available or new ones"** — each tribe gets a curated, per-archetype set of blueprints. Curation is explicit data (`recommendedArchetypes` on each blueprint) with the current category→archetype heuristic kept as a backward-compatible fallback for legacy docs, plus a creator-tribe path (blueprints pinned to a tribe via `creatorTribeId`, written by SP-E).

Secondary (housekeeping):

4. Delete the dead duplicate `lib/features/gamification/domain/models/blueprint.dart` (zero imports in `lib` and `test`).

---

## 2. Recorded decisions

### D1 — Remove the standalone blueprints page

- Delete the `/social/discover` GoRoute (`lib/core/router/router.dart:558-564`) and the entire widget file `lib/features/social/presentation/screens/social_discover_tab.dart` (its only consumers are the router at `router.dart:563` and its own `NodeGuideHost` hosts at `social_discover_tab.dart:85-102`; verified: no other file references `SocialDiscoverTab`).
- Remove the "Discover →" header link in `lib/features/social/presentation/widgets/tribe_blueprints_section.dart:39-49`.
- **CONFIRM-WITH-USER fork (D1a): the lobby CTA.** `TribeLobbyScreen`'s bottom bar has a "BROWSE BLUEPRINTS" `EmergePrimaryButton` (`tribe_lobby_screen.dart:196-204`) that pushes `/social/discover`. SP-D is scheduled to replace it with a "Switch Tribes" CTA, but if SP-D lands after SP-F, the button would push an unregistered route (GoRouter throws "no route found" → runtime crash on tap). **Recommendation (implemented in the plan):** SP-F removes the button so the bottom bar shows a single full-width CHALLENGES button; SP-D reintroduces a "Switch Tribes" CTA in its own task. This keeps the app shippable at every commit and does not duplicate SP-D's work. (Alternative rejected: repointing the CTA to `/social/all` keeps a misleading label; leaving it is a guaranteed broken button.)
- **Node-guide fallout:** the `discover` node in `NodeGuideRegistry` (`node_guide_registry.dart:232-242`) is deleted — its registry comment already anticipates this ("when a screen dies (e.g. the blueprints page in SP-F), its node entry dies with it"). Registry tests have no node-count assertion, so no test change is forced there (plan adds `forNode('discover') == null` for regression safety).
- **Migration fallout:** remove the `'/discover': 'discover'` entry from `migrateVisitedFlags` (`lib/features/onboarding/data/repositories/local_settings_repository.dart:222`). **Decision: remove** (not keep-harmless): the comment above the map already declares the node dies in SP-F, and keeping the entry migrates users' legacy flags to a node that no longer exists. The legacy key `companion_visited_/discover` is still removed by the loop's unconditional cleanup — no data leak. Update `test/features/onboarding/data/local_settings_repository_test.dart` (it currently asserts the flag migrates, line ~26).
- **Keep:** `/blueprint/:id` (`router.dart:363-372`), `/social/blueprint/:id` (`router.dart:566-577`), and `_BlueprintByIdLoader` (`router.dart:626-669`). They are reachable from `BlueprintCard` (tribe sections), creator dashboard, and deep links.
- Regenerate `router.g.dart` via build_runner (see plan pre-flight re: pre-existing dirty file).

### D2 — Image fixes

Root causes, verified:

1. **Legacy v1 docs** (old archetype blueprints) still exist in Firestore with expired `https://lh3.googleusercontent.com/aida-public/...` URLs (ephemeral Google AI Studio links). Acknowledged in code at `blueprint_repository.dart:74-76`. The claimed UI filter ("allowed categories list") exists only in the page we are deleting (`social_discover_tab.dart:27-33`) and is incomplete anyway — v1 docs carry matching categories (`Morning`, `Fitness`, …), so they render blank wherever they surface. Removing the page removes the only surface that showed them categorically; the tribe sections filter by curation (D3), which v1 docs (category `Athlete`/`Creator`/`Scholar`/`Stoic`/`Zealot`, or stale `lh3` URLs) generally fail. The docs themselves still must be purged by an admin (D2d).
2. **One dead v2 URL.** `https://images.unsplash.com/photo-1545205597-3d9d02e29597?w=800` → HTTP 404 (verified 2026-08-01). **Correction to earlier findings:** this URL belongs to `morning_3` "Mindful Awakening" (`blueprint_repository.dart:110`), **not** `mindfulness_3` "Gratitude Practice" — `mindfulness_3`'s URL (`photo-1489710437720-ebb67ec84dd2`) returns 200. All other v2 seed URLs spot-checked return 200 (12/13). `photo-1506126613408-eca07ce68773` (shared by `morning_1` and `mindfulness_4`) returns 200. The dead `morning_3` URL is a prod-data fix (D2d); in the meantime the new fallback (D2a) makes it render the branded treatment instead of a blank.
3. **Creator-made blueprints have `imageUrl == null`** (e.g. `blueprint_builder_screen.dart:266-278` constructs `Blueprint` without an image). These already render a gradient+icon fallback — the fix standardizes and brands it.
4. **Asset branch is broken by construction.** All three render sites split on `startsWith('images/')` → `Image.asset`, but (a) registered asset paths begin with `assets/`, (b) `assets/images/blueprints/` is **empty**, and (c) it is not declared in pubspec.yaml (assets block `pubspec.yaml:131-153` is non-recursive). Seven blueprint PNGs were deleted from that folder in an old commit; any doc pointing at `images/blueprints/blueprint_*.png` breaks twice. **Decision: delete the asset branch entirely.** Blueprint art is network-only: `http(s)://` → network image with error fallback; anything else (`null`, `''`, `images/…`, `assets/…`) → branded fallback. (No local assets will be added; pubspec stays unchanged.)

Decisions (a)–(d) mapped:

- **(a) Fallback everywhere:** one shared widget `BlueprintArtwork` (`lib/features/blueprints/presentation/widgets/blueprint_artwork.dart`) renders image or branded fallback. Wired into the two surviving render sites: `blueprint_card.dart:35-38` (currently no errorBuilder → silent blank) and `blueprint_detail_screen.dart:78-86` (currently `CachedNetworkImage` with a bare `Icons.error` errorWidget). The third site (`social_discover_tab.dart:218-242`) dies with D1. `creator_blueprints_tab.dart`'s `_CreatorBlueprintCard` renders no image (verified) — no change.
- **(b) URL resolution rule** (inside `BlueprintArtwork`): `http://`/`https://` prefix → network image (`Image.network` with `errorBuilder` in cards; `CachedNetworkImage` with `errorWidget` in the detail hero to preserve caching); everything else → branded fallback.
- **(c) Builder:** leave `imageUrl` null — the fallback widget handles it. **No builder change.** (Rejected alternative: mapping category → default image in the builder adds seed-like data to user-authored docs with no product need.)
- **(d) Prod-data fixes are admin work, not app code:** (i) purge v1 docs — any `blueprints` doc whose `category` is an old archetype name (`Athlete`, `Creator`, `Scholar`, `Stoic`, `Zealot`) or whose `imageUrl` starts with `https://lh3.googleusercontent.com/aida-public/`; (ii) fix `morning_3`'s `imageUrl` to a verified-good URL, e.g. `https://images.unsplash.com/photo-1528715471579-d1bcf0ba5e83?w=800` (meditation art, verified 200). **Decision: no in-app repair function** — blueprints writes are admin-only (`firestore.rules:500-505`, `allow create, update, delete: if isAdmin()`), so any app-side repair would need rule changes. The v3 seed backfill (D3) does update the 30 seeded docs in-app via the normal seed path; the v1 purge is tracked for SP-H (Firestore doc surgery). SP-H should also fix the `morning_3` URL; the fallback makes it non-blocking.

### D3 — Per-tribe curated blueprints

- Add `recommendedArchetypes: List<String>` to `Blueprint` (`lib/features/blueprints/domain/models/blueprint.dart`): constructor default `const []`, `copyWith`, `toMap`, `fromMap` (missing field → `[]`), `props`.
- Pure curation service `lib/features/blueprints/domain/services/blueprint_curation.dart`:
  - `categoryToArchetype` — the existing map, moved verbatim from `tribe_blueprints_provider.dart:6-13` (`Fitness→athlete`, `Mindfulness→stoic`, `Learning→scholar`, `Productivity→zealot`, `Creativity→creator`, `Faith→zealot`).
  - `archetypesFor(Blueprint)` — returns `recommendedArchetypes` when non-empty, else `[categoryToArchetype[category]]` (may be `[]`, e.g. `Morning` legacy docs).
  - `matchesTribe(Blueprint, String archetypeId)` — `archetypesFor(bp).contains(id) || bp.creatorArchetype.toLowerCase() == id` (preserves today's creator-archetype matching, `tribe_blueprints_provider.dart:24`).
- Providers (`tribe_blueprints_provider.dart`) rework:
  - `tribeBlueprintsProvider(archetypeId)` — same signature; filter becomes `matchesTribe` (recommendedArchetypes → legacy category fallback → creatorArchetype). Backward compatible for legacy docs without the field.
  - `tribeBlueprintsForActiveTribeProvider` — same logic via the helper; also gains the creator-tribe path below.
  - **New** `tribeCreatorBlueprintsProvider(tribeId)` — streams blueprints where `creatorTribeId == tribeId` (SP-E writes `creatorTribeId` when creators publish to their tribe). Official archetype tribes never take this path.
  - No new Firestore indexes — the whole collection keeps being streamed and filtered client-side.
- `TribeBlueprintsSection` (`tribe_blueprints_section.dart`) rework:
  - Remove the "Discover →" link (`:39-49`).
  - Branch: `tribe.archetypeId != null` → `tribeBlueprintsProvider(archetypeId)`; `tribe.archetypeId == null` (creator tribes; the official "Financial Freedom" club also has `archetypeId: null` per `official_clubs_seed.dart:277`) → `tribeCreatorBlueprintsProvider(tribe.id)`. Today a null-archetype tribe renders `SizedBox.shrink()` (`:17-18`); after this change it renders its creator-pinned blueprints (empty initially — SP-E populates them).
  - Empty curated set keeps the "No blueprints for this tribe yet." empty state (`:90-106`).
- **Seed v3** (`blueprint_repository.dart`):
  - `_seedVersion` 2 → 3 (`:57`).
  - Guard change: today it short-circuits when `morning_1` exists (`:62-72`), which would **not** backfill deployed docs. New guard: skip only when `morning_1` exists **and** carries a `recommendedArchetypes` list; otherwise re-run the seed batch. The batch switches to `SetOptions(merge: true)` so the backfill adds `recommendedArchetypes` without clobbering `adoptionCount`/`createdAt` on live docs.
  - `_createSeed` (`:383-405`) gains a `recommendedArchetypes` param; all 30 seeds get curated lists (table in §4).
  - The 6 creator seeds in `seedCreatorBlueprintsIfEmpty` (`:413-660`) get `recommendedArchetypes` too (they already match via `creatorArchetype`; the field makes curation explicit and keeps them working if `creatorArchetype` ever diverges).
  - `creatorTribeId` stays unset on seeds — SP-E assigns it when creators publish to a tribe.
- Legacy docs without the field: `archetypesFor` falls back to the category map — exactly today's behavior. No UI change for existing tribes beyond the curated sets on re-seeded docs.

### D4 — Delete the dead gamification model

- Delete `lib/features/gamification/domain/models/blueprint.dart` (verified: zero imports in `lib` and `test`). No tests reference it. Its `getDefaultImageForCategory` is dead code (and its `morning` URL `photo-1470252649378-9c29740c9fa8` is itself a 404 — a sign it is stale).

### D5 — Out of scope

- Blueprint creation rights / creator publishing flows (SP-E).
- The "Switch Tribes" CTA redesign (SP-D) — SP-F only removes the dead CTA (D1a).
- Firestore doc surgery for v1 blueprints + `morning_3` URL (SP-H; see D2d).
- New blueprint content ("or new ones" from the user requirement is satisfied by curation of existing blueprints; new seed blueprints can be added later by extending the v3 table — the seed guard makes that a data-only change).

---

## 3. Component specs

### 3.1 `BlueprintArtwork` — shared blueprint image widget (new)

`lib/features/blueprints/presentation/widgets/blueprint_artwork.dart`

```
BlueprintArtwork(blueprint: Blueprint)  // or BlueprintArtwork(imageUrl: String?)
```

- Resolution: `imageUrl` starts with `http://` or `https://` → network branch; otherwise (null, empty, `images/…`, `assets/…`) → branded fallback.
- Network branch exposes `useCachedNetworkImage` flag: cards pass false (`Image.network` + `errorBuilder`), the detail hero passes true (`CachedNetworkImage` + `errorWidget` + placeholder) to preserve current caching behavior.
- Branded fallback (single source, matches the detail screen's existing art direction `blueprint_detail_screen.dart:88-103`): `LinearGradient(topLeft: Color(0xFF2A1B4E), bottomRight: Color(0xFF1A0A2E))` + centered `Icons.auto_awesome_rounded` at `color: Colors.white10`. The existing per-site fallbacks in `blueprint_card.dart:39-49` and `blueprint_detail_screen.dart:88-103` are replaced by this widget's fallback (removing the duplicated white-glass gradient in the card).
- No errorBuilder on the fallback path needed — the fallback *is* the error state.

### 3.2 Page removal

| Item | Location | Action |
|---|---|---|
| Route `/social/discover` | `lib/core/router/router.dart:558-564` | Delete GoRoute |
| `SocialDiscoverTab` widget file | `lib/features/social/presentation/screens/social_discover_tab.dart` | Delete file |
| "Discover →" link | `tribe_blueprints_section.dart:39-49` | Remove link (header row keeps the BLUEPRINTS title) |
| "BROWSE BLUEPRINTS" CTA | `tribe_lobby_screen.dart:196-204` | Remove button; CHALLENGES button becomes full-width (see D1a) |
| `discover` node guide | `node_guide_registry.dart:232-242` | Remove definition (registry 11 → 10 nodes) |
| Migration entry | `local_settings_repository.dart:222` | Remove `'/discover': 'discover'` from `routeToNode` |
| `router.g.dart` | `lib/core/router/router.g.dart` | Regenerate via build_runner |

Deep links `/blueprint/:id`, `/social/blueprint/:id`, and `_BlueprintByIdLoader` are untouched.

### 3.3 Curation service + providers

`lib/features/blueprints/domain/services/blueprint_curation.dart` (pure, no Flutter imports beyond the model — unit-testable):

```dart
const categoryToArchetype = {
  'Fitness': 'athlete',
  'Mindfulness': 'stoic',
  'Learning': 'scholar',
  'Productivity': 'zealot',
  'Creativity': 'creator',
  'Faith': 'zealot',
};

List<String> archetypesFor(Blueprint bp);          // recommendedArchetypes ?? category fallback
bool matchesTribe(Blueprint bp, String archetypeId); // archetypesFor OR creatorArchetype
```

Provider changes (`tribe_blueprints_provider.dart`):
- `tribeBlueprintsProvider` filter body replaced by `matchesTribe(bp, tribeArchetypeId)` (keeps `toLowerCase()` on the input, matching current behavior).
- `tribeBlueprintsForActiveTribeProvider` uses the same helper; when the resolved tribe's `archetypeId` is null it delegates to the creator path with the tribe id.
- New `tribeCreatorBlueprintsProvider` family: `repo.getBlueprints()` filtered on `bp.creatorTribeId == tribeId`.

### 3.4 Seed v3

`seedBlueprintsIfEmpty` (`blueprint_repository.dart:59-381`):

```dart
static const int _seedVersion = 3;                      // :57

final v3Check = await _firestore.collection('blueprints').doc('morning_1').get();
final isV3 = v3Check.exists && v3Check.data()?['recommendedArchetypes'] is List;
if (isV3) return;                                        // already v3
// ... batch.set(docRef, bp.toMap(), SetOptions(merge: true));  // backfill-safe
```

- `_createSeed` signature gains `required List<String> recommendedArchetypes`; all 30 calls updated.
- The 6 `cb_*` seeds gain `recommendedArchetypes` in their constructors.
- Merge semantics: on backfill, only fields in `toMap()` are written; `adoptionCount` and `createdAt` on live docs survive. Fresh installs behave identically (docs don't exist).
- Log message updates: "already seeded (v$_seedVersion)" and "Seeding complete (v3)".

---

## 4. `recommendedArchetypes` curation table (all seeds)

Canonical archetype ids (lowercase): `athlete`, `scholar`, `stoic`, `creator`, `zealot` (from `UserArchetype` enum and `official_clubs_seed.dart`).

### 4.1 Category seeds (30) — `seedBlueprintsIfEmpty`

| id | title | category | recommendedArchetypes | rationale |
|---|---|---|---|---|
| morning_1 | Sunrise Ritual | Morning | `[athlete, stoic]` | early rise + light (athlete); intention/calm (stoic) |
| morning_2 | Power Morning | Morning | `[athlete]` | cold shower, stretch, protein — pure physical priming |
| morning_3 | Mindful Awakening | Morning | `[stoic]` | meditation, gratitude journal, tea |
| morning_4 | Early Bird Stack | Morning | `[scholar, zealot]` | 5AM + deep work (scholar); strict discipline (zealot) |
| morning_5 | Morning Mobility | Morning | `[athlete]` | stretching/foam rolling — body work |
| productivity_1 | Deep Work Protocol | Productivity | `[scholar, zealot]` | focus blocks (scholar); keeps legacy zealot tie |
| productivity_2 | Ivy Lee Method | Productivity | `[scholar, zealot]` | prioritization system (scholar); legacy zealot kept |
| productivity_3 | Time Block Master | Productivity | `[scholar, zealot]` | scheduling (scholar); legacy zealot kept |
| productivity_4 | Digital Declutter | Productivity | `[stoic, scholar]` | attention hygiene — natural fit for Digital Detox stoics; cross-listed scholar |
| productivity_5 | Pomodoro Flow | Productivity | `[scholar, athlete]` | sprints (scholar); interval structure (athlete) |
| fitness_1 | Bodyweight Foundation | Fitness | `[athlete]` | legacy category default |
| fitness_2 | Cardio Builder | Fitness | `[athlete]` | legacy category default |
| fitness_3 | Flexibility & Mobility | Fitness | `[athlete, stoic]` | range-of-motion work; cross-listed for Mindful Masters |
| fitness_4 | Iron Will | Fitness | `[athlete, zealot]` | heavy discipline (athlete); devotional grind (zealot) |
| fitness_5 | Active Recovery | Fitness | `[athlete, stoic]` | rest-day recovery; calm cross-listing |
| mindfulness_1 | Daily Meditation | Mindfulness | `[stoic]` | legacy category default |
| mindfulness_2 | Digital Sabbath | Mindfulness | `[stoic, scholar]` | legacy stoic default + cross-listed scholar |
| mindfulness_3 | Gratitude Practice | Mindfulness | `[stoic, zealot]` | legacy stoic default + Gratitude Circle/Lunar Seekers tie |
| mindfulness_4 | Stress Shield | Mindfulness | `[stoic]` | legacy category default |
| mindfulness_5 | Evening Wind Down | Mindfulness | `[stoic, scholar]` | legacy stoic default + reading element (scholar) |
| learning_1 | Daily Reader | Learning | `[scholar]` | legacy category default |
| learning_2 | Skill Sprint | Learning | `[scholar, creator]` | deliberate practice; making skills (creator) |
| learning_3 | Curious Mind | Learning | `[scholar, creator]` | documentaries/articles; creative curiosity |
| learning_4 | Memory Master | Learning | `[scholar]` | legacy category default |
| learning_5 | Course Completer | Learning | `[scholar, zealot]` | structured completion; mission-finisher (zealot) |

### 4.2 Creator seeds (6) — `seedCreatorBlueprintsIfEmpty`

| id | title | creatorArchetype | recommendedArchetypes |
|---|---|---|---|
| cb_aria_deep_work | Scholar's Deep Work Stack | Scholar | `[scholar, zealot]` |
| cb_marcus_morning | Athlete's Morning Prep | Athlete | `[athlete]` |
| cb_sora_creative | Creator's Studio Ritual | Creator | `[creator]` |
| cb_julian_calm | Stoic Anchor Day | Stoic | `[stoic]` |
| cb_naia_devotion | Devoted Day | Zealot | `[zealot]` |
| cb_elias_studio | Daily Sketch Studio | Creator | `[creator]` |

### 4.3 Resulting per-archetype sets (30 seeds only)

| Tribe archetype | Blueprints shown (curated) |
|---|---|
| athlete (Morning Warriors, Plant-Based Tribe, HIIT Heroes) | morning_1, morning_2, morning_5, productivity_5, fitness_1..5 (9) + cb_marcus_morning (10) |
| scholar (Deep Work Society, Night Owl Readers, Language Learners) | morning_4, productivity_1..5, mindfulness_2, mindfulness_5, learning_1..5 (13) + cb_aria_deep_work (14) |
| stoic (Mindful Masters, Digital Detox Weekend, Gratitude Circle) | morning_1, morning_3, productivity_4, fitness_3, fitness_5, mindfulness_1..5 (10) + cb_julian_calm (11) |
| creator (Creative Collective, Music Practice 21) | learning_2, learning_3 (2) + cb_sora_creative, cb_elias_studio (4) |
| zealot (Lunar Seekers, Breathwork Circle) | morning_4, productivity_1..3, fitness_4, mindfulness_3, learning_5 (7) + cb_naia_devotion (8) |
| null (Financial Freedom) | creatorTribeId == tribe.id (empty until SP-E writes assignments) |

Every set differs from the category-derived default (e.g. scholar now sees Pomodoro + Digital Declutter; zealot sees Gratitude Practice + Course Completer), which satisfies "custom made for them".

---

## 5. Data & storage changes

| Change | Type | Detail |
|---|---|---|
| `recommendedArchetypes` field | Firestore doc field (additive) | Written by seed v3 on the 36 seed docs; `merge: true` preserves `adoptionCount`/`createdAt` |
| Seed version | Code constant | `_seedVersion` 2 → 3; guard now checks the field, not doc existence |
| v1 archetype docs purge | Admin-only (SP-H) | Delete docs with old archetype categories or `lh3.googleusercontent.com/aida-public/` imageUrls; blueprints writes are admin-only in `firestore.rules:500-505` |
| `morning_3` imageUrl fix | Admin-only (SP-H) | Replace dead `photo-1545205597-3d9d02e29597` URL with verified `photo-1528715471579-d1bcf0ba5e83?w=800` |
| Indexes | None | Filtering stays client-side on the streamed collection |
| Drift | None | Blueprint is Firestore-only |
| pubspec assets | None | `assets/images/blueprints/` stays empty and undeclared; asset branch is deleted |

---

## 6. File inventory

### New files

| Path | Responsibility |
|---|---|
| `lib/features/blueprints/domain/services/blueprint_curation.dart` | Pure curation: `categoryToArchetype`, `archetypesFor`, `matchesTribe` |
| `lib/features/blueprints/presentation/widgets/blueprint_artwork.dart` | Shared image-or-fallback widget |
| `test/features/blueprints/domain/services/blueprint_curation_test.dart` | Pure curation tests |
| `test/features/blueprints/presentation/widgets/blueprint_artwork_test.dart` | Fallback/resolution widget tests |
| `test/features/social/presentation/providers/tribe_blueprints_provider_test.dart` | Provider curation tests (fake_cloud_firestore) |
| `test/features/social/presentation/widgets/tribe_blueprints_section_test.dart` | Section tests (curated sets, creator tribe, empty state, no link) |
| `test/features/social/presentation/widgets/blueprint_card_test.dart` | Card tests (fallback on bad URL) |

### Modified files

| Path | Change |
|---|---|
| `lib/features/blueprints/domain/models/blueprint.dart` | `recommendedArchetypes` field/ctor/copyWith/toMap/fromMap/props |
| `lib/features/blueprints/data/repositories/blueprint_repository.dart` | Seed v3: version, guard, merge, `_createSeed` param, 30 curated lists, cb_* lists |
| `lib/features/social/presentation/providers/tribe_blueprints_provider.dart` | Use curation helper; add `tribeCreatorBlueprintsProvider`; active-tribe creator path |
| `lib/features/social/presentation/widgets/tribe_blueprints_section.dart` | Remove link; creator-tribe branch |
| `lib/features/social/presentation/screens/tribe_lobby_screen.dart` | Remove BROWSE BLUEPRINTS CTA (single CHALLENGES button) |
| `lib/features/social/presentation/widgets/blueprint_card.dart` | Use `BlueprintArtwork` (errorBuilder fallback) |
| `lib/features/social/presentation/screens/blueprint_detail_screen.dart` | Hero uses `BlueprintArtwork(cached: true)` |
| `lib/core/router/router.dart` + `router.g.dart` | Remove `/social/discover`; regenerate |
| `lib/features/tutorials/domain/node_guide_registry.dart` | Remove `discover` node |
| `lib/features/onboarding/data/repositories/local_settings_repository.dart` | Remove `'/discover'` migration entry |
| `test/features/blueprints/domain/models/blueprint_test.dart` | Symmetry incl. new field; fromMap missing → `[]` |
| `test/features/blueprints/data/repositories/blueprint_repository_test.dart` | Seed v3 guard/backfill/merge tests |
| `test/features/social/presentation/screens/tribe_lobby_screen_test.dart` | CTA bar expectation (single button) |
| `test/features/onboarding/data/local_settings_repository_test.dart` | Discover flag no longer migrates |
| `test/features/tutorials/domain/node_guide_registry_test.dart` | `forNode('discover')` is null |

### Deleted files

| Path | Reason |
|---|---|
| `lib/features/social/presentation/screens/social_discover_tab.dart` | Standalone page dies (D1); no other consumers |
| `lib/features/gamification/domain/models/blueprint.dart` | Dead duplicate (D4); zero imports |

---

## 7. Error handling & edge cases

| Case | Behavior |
|---|---|
| `imageUrl` null / empty (creator blueprints) | Branded fallback (existing behavior, now shared/branded) |
| `imageUrl` = `images/...` or `assets/...` (stale docs) | Branded fallback — asset branch deleted |
| `imageUrl` 404/network error (e.g. `morning_3` until SP-H) | `errorBuilder`/`errorWidget` → branded fallback; never blank |
| Legacy doc without `recommendedArchetypes` | `archetypesFor` falls back to `categoryToArchetype`; `Morning` legacy docs match nothing in tribes (same as today) |
| Null-archetype tribe (Financial Freedom, future creator tribes) | Shows `creatorTribeId`-pinned blueprints; empty state until SP-E assigns |
| Seed backfill on live DB | `merge: true` — `adoptionCount`/`createdAt` preserved; 30 docs updated, v1 docs untouched |
| `seedBlueprintsIfEmpty` throws | Existing try/catch logs and rethrows nothing (swallowed) — unchanged |
| Deep link `/blueprint/:id` or `/social/blueprint/:id` | Unchanged; `_BlueprintByIdLoader` handles miss/error |
| Stale `companion_visited_/discover` key after migration entry removal | Key still deleted by the migration loop; no node flag written |
| Tap on removed route (pre-SP-D window) | Impossible — CTA removed in SP-F (D1a) |
| Duplicate images (`morning_1`/`mindfulness_4` share a URL) | Cosmetic; acceptable, no action |

---

## 8. Testing strategy

1. **Pure curation tests** (`blueprint_curation_test.dart`): explicit `recommendedArchetypes` wins; legacy fallback per category incl. `Fitness→athlete`; `Morning` → empty; `creatorArchetype` match (case-insensitive); non-matching archetype → false; empty archetypeId → false.
2. **Model tests** (`blueprint_test.dart`): toMap/fromMap symmetric with `recommendedArchetypes`; fromMap missing field → `[]`; copyWith replaces list; props include it.
3. **Repository tests** (`blueprint_repository_test.dart`): skip when `morning_1` exists **with** the field; backfill when it exists **without** the field (all 30 docs get `recommendedArchetypes`, pre-existing `adoptionCount` preserved via merge); all 30 seeds have non-empty curated lists; `seedCreatorBlueprintsIfEmpty` writes `recommendedArchetypes` on cb_* docs. (Note: the existing "skips when morning_1 exists" test must be updated — under the new guard a bare `{'title': 'Existing'}` doc triggers a backfill.)
4. **Provider tests** (`tribe_blueprints_provider_test.dart`, fake_cloud_firestore + ProviderScope overrides): archetype family returns curated set; legacy doc (no field) matches via category; creator tribe family returns `creatorTribeId`-pinned docs only.
5. **Widget tests**: `blueprint_artwork_test.dart` — null/'images/…' → fallback icon; `https` → `NetworkImage` in tree; failing network load → fallback (flutter_test's default HttpClient returns 400, driving the errorBuilder). `blueprint_card_test.dart` — card with dead URL renders fallback + title; null image renders fallback. `tribe_blueprints_section_test.dart` — renders curated blueprints for archetype tribe; no "Discover →" text; null-archetype tribe renders creator blueprints or empty state; empty state text unchanged. `tribe_lobby_screen_test.dart` — CTA bar has one full-width CHALLENGES button, no BROWSE BLUEPRINTS.
6. **Registry/migration tests**: `node_guide_registry_test.dart` — `forNode('discover')` is null; `local_settings_repository_test.dart` — `companion_visited_/discover` key removed but no `hasSeenNodeGuide_discover` flag written.

No manual device testing required beyond the standard smoke pass; image fallback is deterministic and covered by widget tests.

---

## 9. Out of scope

- SP-E: creator blueprint publishing, `creatorTribeId` writes, creation rights.
- SP-D: "Switch Tribes" CTA design (SP-F only removes the dead button).
- SP-H: Firestore doc surgery — v1 blueprint purge, `morning_3` URL replacement (documented here for handoff).
- New blueprint content beyond curation of the existing 36.
- pubspec/assets work, drift changes, Firestore rules changes, new indexes.

---

## 10. Risks

| Risk | Mitigation |
|---|---|
| **CTA regression window** (D1a): if SP-F ships before SP-D, the removed CTA changes the lobby bottom bar (CHALLENGES becomes full-width). | Accepted as part of the flagged fork; SP-D reintroduces a CTA. Explicitly flagged CONFIRM-WITH-USER in §2 D1a. |
| Seed backfill writes 30 docs on every non-v3 install | Idempotent (field-checked guard); merge keeps counters; batch is cheap. First post-deploy launch performs it once. |
| `financial_freedom` (null-archetype official club) changes from nothing to creator-pinned blueprints | Intended per D3; will show empty state until SP-E data exists. |
| v1 docs remain queryable by the full-collection stream until SP-H purge | The only categorical surface (the discover page) is deleted; curation filters them out of tribe sections (their categories don't map: `Athlete` etc. are archetype names, and stale `lh3` docs fail the image fallback gracefully). |
| `router.g.dart` regeneration collides with pre-existing dirty file | Plan pre-flight: `git diff` the generated file before/after; confirm the only change is the removed route. |
| Build-route removal breaks nothing else | Only two `push('/social/discover')` call sites exist; both are removed in SP-F. |
| Adoption counts reset by re-seed | Avoided via `merge: true` (verified in repository tests). |
