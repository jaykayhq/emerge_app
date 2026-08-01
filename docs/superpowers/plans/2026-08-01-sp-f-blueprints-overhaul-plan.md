# SP-F: Blueprints Overhaul — Fix Images, Remove Standalone Page, Per-Tribe Curated Blueprints — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix broken blueprint images (branded fallback, never blank), delete the standalone `/social/discover` blueprints page and its node-guide/migration entries, and give every tribe a curated per-archetype blueprint set via a new `recommendedArchetypes` field (seed v3) with a backward-compatible category fallback and a creator-tribe path. Also delete the dead gamification `Blueprint` model.

**Architecture:** Add a pure curation service (`categoryToArchetype` map + `archetypesFor` + `matchesTribe`) and a shared `BlueprintArtwork` image-or-fallback widget in the blueprints feature. Rework `tribe_blueprints_provider.dart` to use the service and add a `tribeCreatorBlueprintsProvider` family. Bump `seedBlueprintsIfEmpty` to v3: field-checked guard + merge-backfill + curated lists for all 30 seeds (and the 6 cb_* seeds). Remove the route, widget file, lobby CTA, section link, `discover` node guide, and the `'/discover'` migration entry. No new Firestore indexes, no rules changes, no drift changes.

**Tech Stack:** Flutter 3.x, Dart 3.10+, Riverpod 3.x (annotation + codegen), go_router, fake_cloud_firestore, mocktail, flutter_test.

**Spec:** `docs/superpowers/specs/2026-08-01-sp-f-blueprints-overhaul-design.md`

---

## ⚠️ Pre-flight (read first)

1. **The working tree is dirty** (pre-existing uncommitted changes from other sessions: `firestore.rules`, `lib/core/drift/*`, `lib/core/router/router.g.dart`, `lib/features/social/presentation/screens/tribe_lobby_screen.dart`, `lib/features/social/presentation/screens/social_hub_screen.dart`, and others). **Commit only the files each task names** — never `git add -A` or `git add lib` wholesale.
2. **Run `dart analyze lib` before starting** to establish the baseline error count. Only SP-F-introduced errors are this plan's responsibility.
3. `lib/core/router/router.g.dart` is already modified in the worktree. Task 8 regenerates it — after running build_runner, confirm with `git diff lib/core/router/router.g.dart` that the only change vs. the pre-task state is the removal of the `discover` route (and the corresponding `SocialDiscoverTab` import in `router.dart`).
4. **Admin-only data fixes are OUT of scope for code** (blueprints writes are `isAdmin()`-only in `firestore.rules:500-505`): purging legacy v1 docs and fixing the dead `morning_3` imageUrl (404, `photo-1545205597-3d9d02e29597`) are tracked for SP-H. See spec §2 D2d — the fallback widget makes the dead URL non-blocking.
5. `assets/images/blueprints/` is empty and undeclared in pubspec — the asset branch (`startsWith('images/')`) is deleted by design; do not add assets.
6. Existing test expectations that change with this plan (they are updated inside the tasks): `blueprint_repository_test.dart` seed-skip test (new guard), `tribe_lobby_screen_test.dart` CTA bar test, `local_settings_repository_test.dart` discover migration assertion.

## File structure

### New files

| Path | Responsibility |
|---|---|
| `lib/features/blueprints/domain/services/blueprint_curation.dart` | Pure: `categoryToArchetype`, `archetypesFor`, `matchesTribe` |
| `lib/features/blueprints/presentation/widgets/blueprint_artwork.dart` | Shared image-or-branded-fallback widget |
| `test/features/blueprints/domain/services/blueprint_curation_test.dart` | Pure curation tests |
| `test/features/blueprints/presentation/widgets/blueprint_artwork_test.dart` | Resolution + fallback widget tests |
| `test/features/social/presentation/providers/tribe_blueprints_provider_test.dart` | Provider curation tests |
| `test/features/social/presentation/widgets/tribe_blueprints_section_test.dart` | Section: curated sets, creator branch, no link |
| `test/features/social/presentation/widgets/blueprint_card_test.dart` | Card fallback tests |

### Modified files

| Path | Change |
|---|---|
| `lib/features/blueprints/domain/models/blueprint.dart` | Add `recommendedArchetypes` (field/ctor/copyWith/toMap/fromMap/props) |
| `lib/features/blueprints/data/repositories/blueprint_repository.dart` | Seed v3: `_seedVersion=3`, field-checked guard, `merge: true` batch, `_createSeed` param, 30 curated lists, 6 cb_* lists |
| `lib/features/social/presentation/providers/tribe_blueprints_provider.dart` | Use `matchesTribe`; add `tribeCreatorBlueprintsProvider`; active-tribe creator path |
| `lib/features/social/presentation/widgets/tribe_blueprints_section.dart` | Remove Discover link; creator-tribe branch |
| `lib/features/social/presentation/screens/tribe_lobby_screen.dart` | Remove BROWSE BLUEPRINTS CTA |
| `lib/features/social/presentation/widgets/blueprint_card.dart` | Use `BlueprintArtwork` |
| `lib/features/social/presentation/screens/blueprint_detail_screen.dart` | Hero uses `BlueprintArtwork(cached: true)` |
| `lib/core/router/router.dart` (+ regenerated `router.g.dart`) | Remove `/social/discover` route |
| `lib/features/tutorials/domain/node_guide_registry.dart` | Remove `discover` node |
| `lib/features/onboarding/data/repositories/local_settings_repository.dart` | Remove `'/discover'` from `routeToNode` |
| `test/features/blueprints/domain/models/blueprint_test.dart` | Symmetry incl. new field; fromMap fallback |
| `test/features/blueprints/data/repositories/blueprint_repository_test.dart` | Seed v3 guard/backfill/merge tests |
| `test/features/social/presentation/screens/tribe_lobby_screen_test.dart` | Single CTA button expectation |
| `test/features/onboarding/data/local_settings_repository_test.dart` | Discover flag no longer migrates |
| `test/features/tutorials/domain/node_guide_registry_test.dart` | `forNode('discover')` is null |

### Deleted files

| Path | Reason |
|---|---|
| `lib/features/social/presentation/screens/social_discover_tab.dart` | Standalone page dies; only consumers were the router + its own NodeGuideHost |
| `lib/features/gamification/domain/models/blueprint.dart` | Dead duplicate; zero imports in `lib` and `test` |

---

# Phase 1 — Model + pure curation (TDD)

## Task 1: `recommendedArchetypes` on the Blueprint model

**Files:**
- Modify: `lib/features/blueprints/domain/models/blueprint.dart`
- Modify: `test/features/blueprints/domain/models/blueprint_test.dart`

- [ ] **Step 1: Write the failing tests** — add to `blueprint_test.dart`: (a) toMap/fromMap symmetric including `recommendedArchetypes: ['scholar', 'zealot']`; (b) `fromMap` without the key → empty list; (c) `copyWith(recommendedArchetypes: [...])` replaces.
- [ ] **Step 2: Implement** — add `final List<String> recommendedArchetypes` (ctor default `const []`, `copyWith`, `toMap` → `'recommendedArchetypes': recommendedArchetypes`, `fromMap` → `List<String>.from(map['recommendedArchetypes'] ?? [])`, add to `props`).
- [ ] **Step 3: Run** `flutter test test/features/blueprints/domain/models/blueprint_test.dart` — green.
- [ ] **Step 4: Commit**
```bash
git add lib/features/blueprints/domain/models/blueprint.dart test/features/blueprints/domain/models/blueprint_test.dart
git commit -m "feat(blueprints): add recommendedArchetypes to Blueprint model"
```

## Task 2: Pure curation service

**Files:**
- Create: `lib/features/blueprints/domain/services/blueprint_curation.dart`
- Create: `test/features/blueprints/domain/services/blueprint_curation_test.dart`

- [ ] **Step 1: Write the failing tests** — `categoryToArchetype` maps `Fitness→athlete`, `Mindfulness→stoic`, `Learning→scholar`, `Productivity→zealot`, `Creativity→creator`, `Faith→zealot`; `archetypesFor` returns `recommendedArchetypes` when non-empty; falls back to `[categoryToArchetype[category]]` when empty (incl. `Morning` → `[]`); `matchesTribe` true when curated id matches, true when `creatorArchetype.toLowerCase() == archetypeId`, false otherwise, false on empty archetypeId.
- [ ] **Step 2: Implement** — pure functions over `Blueprint` (import only the model + `package:flutter/foundation.dart` if needed; prefer zero Flutter imports — plain Dart lists/strings suffice).
- [ ] **Step 3: Run** `flutter test test/features/blueprints/domain/services/blueprint_curation_test.dart` — green.
- [ ] **Step 4: Commit**
```bash
git add lib/features/blueprints/domain/services/blueprint_curation.dart test/features/blueprints/domain/services/blueprint_curation_test.dart
git commit -m "feat(blueprints): pure curation service — category fallback + archetype matching"
```

---

# Phase 2 — Seed v3 (TDD)

## Task 3: Seed v3 — curated `recommendedArchetypes` for all seeds + merge backfill

**Files:**
- Modify: `lib/features/blueprints/data/repositories/blueprint_repository.dart`
- Modify: `test/features/blueprints/data/repositories/blueprint_repository_test.dart`

- [ ] **Step 1: Write the failing tests** — in `blueprint_repository_test.dart`: (a) **update** the existing "skips when collection already has data" test: pre-seed `morning_1` with `{'title': 'Existing', 'recommendedArchetypes': ['athlete']}` → still skips (1 doc); (b) new: pre-seed `morning_1` with only `{'title': 'Existing', 'adoptionCount': 7}` → `seedBlueprintsIfEmpty` backfills: 30 docs exist, `morning_1` has non-empty `recommendedArchetypes` **and** `adoptionCount == 7` (merge preserved it); (c) new: after seeding, every one of the 30 docs has a non-empty `recommendedArchetypes` list; (d) new: `seedCreatorBlueprintsIfEmpty` writes `recommendedArchetypes` on all 6 cb_* docs.
- [ ] **Step 2: Implement** — bump `_seedVersion` to 3; replace the guard (`morning_1` exists **and** `data()?['recommendedArchetypes'] is List` → return); change `batch.set(docRef, bp.toMap())` → `batch.set(docRef, bp.toMap(), SetOptions(merge: true))`; add `required List<String> recommendedArchetypes` to `_createSeed` and pass curated lists per the spec §4.1 table (morning_1 `[athlete, stoic]`, morning_2 `[athlete]`, morning_3 `[stoic]`, morning_4 `[scholar, zealot]`, morning_5 `[athlete]`, productivity_1 `[scholar, zealot]`, productivity_2 `[scholar, zealot]`, productivity_3 `[scholar, zealot]`, productivity_4 `[stoic, scholar]`, productivity_5 `[scholar, athlete]`, fitness_1..2 `[athlete]`, fitness_3 `[athlete, stoic]`, fitness_4 `[athlete, zealot]`, fitness_5 `[athlete, stoic]`, mindfulness_1 `[stoic]`, mindfulness_2 `[stoic, scholar]`, mindfulness_3 `[stoic, zealot]`, mindfulness_4 `[stoic]`, mindfulness_5 `[stoic, scholar]`, learning_1 `[scholar]`, learning_2 `[scholar, creator]`, learning_3 `[scholar, creator]`, learning_4 `[scholar]`, learning_5 `[scholar, zealot]`); add `recommendedArchetypes` to the 6 cb_* constructors per spec §4.2 (aria `[scholar, zealot]`, marcus `[athlete]`, sora `[creator]`, julian `[stoic]`, naia `[zealot]`, elias `[creator]`).
- [ ] **Step 3: Run** `flutter test test/features/blueprints/data/repositories/blueprint_repository_test.dart` — green.
- [ ] **Step 4: Commit**
```bash
git add lib/features/blueprints/data/repositories/blueprint_repository.dart test/features/blueprints/data/repositories/blueprint_repository_test.dart
git commit -m "feat(blueprints): seed v3 — curated recommendedArchetypes + merge backfill"
```

---

# Phase 3 — Provider + section rework (TDD)

## Task 4: Providers use curation service; creator-tribe stream

**Files:**
- Modify: `lib/features/social/presentation/providers/tribe_blueprints_provider.dart`
- Create: `test/features/social/presentation/providers/tribe_blueprints_provider_test.dart`

- [ ] **Step 1: Write the failing tests** — new provider test file (fake_cloud_firestore; override `blueprintRepositoryProvider` via `ProviderScope(overrides:)`; for `tribeBlueprintsForActiveTribeProvider`, also override `activeMembershipProvider`/`allArchetypeClubsProvider` following the patterns in `test/features/social/presentation/providers/tribe_providers_test.dart`): (a) `tribeBlueprintsProvider('scholar')` emits blueprints whose `recommendedArchetypes` contains `scholar` (e.g. `productivity_1` with `['scholar','zealot']`) plus creatorArchetype matches; (b) legacy doc without the field matches via category (`Fitness` → `athlete`); (c) `Morning`-category doc matches nothing; (d) `tribeCreatorBlueprintsProvider('tribe_x')` emits only docs with `creatorTribeId == 'tribe_x'`.
- [ ] **Step 2: Implement** — delete the local `_categoryToArchetype` const (moved to curation service); replace both filter bodies with `matchesTribe(bp, archetypeId)` (keeping `.toLowerCase()` on the archetype id input); add `tribeCreatorBlueprintsProvider` (`StreamProvider.autoDispose.family<List<Blueprint>, String>`) filtering `bp.creatorTribeId == tribeId`; in `tribeBlueprintsForActiveTribeProvider`, when the resolved tribe's `archetypeId` is null, filter by `creatorTribeId == membership.tribeId` instead.
- [ ] **Step 3: Run** `flutter test test/features/social/presentation/providers/tribe_blueprints_provider_test.dart` — green.
- [ ] **Step 4: Commit**
```bash
git add lib/features/social/presentation/providers/tribe_blueprints_provider.dart test/features/social/presentation/providers/tribe_blueprints_provider_test.dart
git commit -m "feat(social): tribe blueprint providers use curation service; creator-tribe stream"
```

## Task 5: `TribeBlueprintsSection` — remove Discover link, creator-tribe branch

**Files:**
- Modify: `lib/features/social/presentation/widgets/tribe_blueprints_section.dart`
- Create: `test/features/social/presentation/widgets/tribe_blueprints_section_test.dart`

- [ ] **Step 1: Write the failing tests** — new section test file (fake_cloud_firestore + repo override; pump `TribeBlueprintsSection(tribe: ...)` inside `MaterialApp`): (a) archetype tribe renders its curated blueprints as `BlueprintCard`s; (b) `find.text('Discover →')` finds nothing; (c) null-archetype tribe (`Tribe(archetypeId: null)`) with a doc whose `creatorTribeId == tribe.id` renders it; (d) null-archetype tribe with no pinned docs shows 'No blueprints for this tribe yet.'; (e) empty curated list keeps the empty state text.
- [ ] **Step 2: Implement** — replace `archetypeId.isEmpty → SizedBox.shrink` with: `archetypeId != null` → `ref.watch(tribeBlueprintsProvider(archetypeId))`; else → `ref.watch(tribeCreatorBlueprintsProvider(tribe.id))`; remove the `GestureDetector`/`Text('Discover →')` from the header row (keep the BLUEPRINTS title + Spacer).
- [ ] **Step 3: Run** `flutter test test/features/social/presentation/widgets/tribe_blueprints_section_test.dart` — green.
- [ ] **Step 4: Commit**
```bash
git add lib/features/social/presentation/widgets/tribe_blueprints_section.dart test/features/social/presentation/widgets/tribe_blueprints_section_test.dart
git commit -m "feat(social): per-tribe curated blueprint section; creator-tribe branch; Discover link removed"
```

---

# Phase 4 — Image fallback (TDD)

## Task 6: `BlueprintArtwork` shared widget

**Files:**
- Create: `lib/features/blueprints/presentation/widgets/blueprint_artwork.dart`
- Create: `test/features/blueprints/presentation/widgets/blueprint_artwork_test.dart`

- [ ] **Step 1: Write the failing tests** — (a) `imageUrl: null` → fallback: `find.byIcon(Icons.auto_awesome_rounded)`; (b) `imageUrl: 'images/blueprints/blueprint_morning.png'` → fallback (asset branch deleted); (c) `imageUrl: 'https://images.unsplash.com/photo-x'` → an `Image` whose `ImageProvider` is a `NetworkImage`; (d) network failure → fallback icon (flutter_test's default HttpClient returns 400, exercising the `errorBuilder`; use `await tester.pump()` after initial pump to settle the error frame).
- [ ] **Step 2: Implement** — `BlueprintArtwork({required this.imageUrl, this.useCachedNetworkImage = false})`; `String? _resolve(String? url)` returns the url only when it starts with `http://` or `https://`; network branch renders `Image.network(..., fit: BoxFit.cover, errorBuilder: (_, _, _) => const _Fallback())` or `CachedNetworkImage(..., errorWidget: ..., placeholder: ...)` when `useCachedNetworkImage`; otherwise `const _Fallback()` (gradient `Color(0xFF2A1B4E)`→`Color(0xFF1A0A2E)`, centered `Icons.auto_awesome_rounded` at `Colors.white10`).
- [ ] **Step 3: Run** `flutter test test/features/blueprints/presentation/widgets/blueprint_artwork_test.dart` — green.
- [ ] **Step 4: Commit**
```bash
git add lib/features/blueprints/presentation/widgets/blueprint_artwork.dart test/features/blueprints/presentation/widgets/blueprint_artwork_test.dart
git commit -m "feat(blueprints): BlueprintArtwork widget with branded fallback"
```

## Task 7: Wire `BlueprintArtwork` into card + detail; card fallback tests

**Files:**
- Modify: `lib/features/social/presentation/widgets/blueprint_card.dart`
- Modify: `lib/features/social/presentation/screens/blueprint_detail_screen.dart`
- Create: `test/features/social/presentation/widgets/blueprint_card_test.dart`

- [ ] **Step 1: Write the failing tests** — new `blueprint_card_test.dart`: (a) blueprint with dead URL (`https://images.unsplash.com/photo-1545205597-3d9d02e29597?w=800`) renders the fallback icon, not a blank area, and still shows the title; (b) blueprint with `imageUrl: null` renders the fallback icon. Also extend `blueprint_detail_screen_test.dart` (if it asserts the hero) so the hero shows the fallback icon on a dead URL.
- [ ] **Step 2: Implement** — in `blueprint_card.dart`, replace the `Stack`'s first child (`:35-49`: the `imageUrl != null ? (...Image.asset/Image.network...) : Container(gradient...)`) with `BlueprintArtwork(imageUrl: blueprint.imageUrl)`; in `blueprint_detail_screen.dart`, replace the hero `if (blueprint.imageUrl != null) ... else Container(...)` block (`:78-103`) with `BlueprintArtwork(imageUrl: blueprint.imageUrl, useCachedNetworkImage: true)`. Remove the now-unused `cached_network_image` import from the card if unused there (it is not imported in the card; the detail screen keeps it — `BlueprintArtwork` owns it).
- [ ] **Step 3: Run** `flutter test test/features/social/presentation/widgets/blueprint_card_test.dart test/features/social/presentation/screens/blueprint_detail_screen_test.dart` — green.
- [ ] **Step 4: Commit**
```bash
git add lib/features/social/presentation/widgets/blueprint_card.dart lib/features/social/presentation/screens/blueprint_detail_screen.dart test/features/social/presentation/widgets/blueprint_card_test.dart
git commit -m "fix(social): blueprint card + detail use BlueprintArtwork — broken images fall back, never blank"
```

---

# Phase 5 — Page removal (TDD)

## Task 8: Remove `/social/discover` route, widget file, and lobby CTA

**Files:**
- Modify: `lib/core/router/router.dart` (+ regenerate `lib/core/router/router.g.dart`)
- Delete: `lib/features/social/presentation/screens/social_discover_tab.dart`
- Modify: `lib/features/social/presentation/screens/tribe_lobby_screen.dart`
- Modify: `test/features/social/presentation/screens/tribe_lobby_screen_test.dart`

- [ ] **Step 1: Write the failing tests** — update `tribe_lobby_screen_test.dart` (currently asserts both CHALLENGES and BROWSE BLUEPRINTS, `:129-136`): CTA bar shows a single full-width CHALLENGES button and `find.text('BROWSE BLUEPRINTS')` finds nothing.
- [ ] **Step 2: Implement** — delete the `discover` GoRoute (`router.dart:558-564`) and the `SocialDiscoverTab` import (`router.dart:52`); delete the widget file; regenerate: `dart run build_runner build --delete-conflicting-outputs` (confirm `git diff lib/core/router/router.g.dart` shows only the route-table delta); in `tribe_lobby_screen.dart` remove the `EmergePrimaryButton` BROWSE BLUEPRINTS block (`:197-204`) so the `Expanded` CHALLENGES `OutlinedButton` spans the full row (keep the `Row`/padding structure).
- [ ] **Step 3: Verify no stragglers** — `grep -rn "social/discover\|SocialDiscoverTab" lib test` → no matches.
- [ ] **Step 4: Run** `flutter test test/features/social/presentation/screens/tribe_lobby_screen_test.dart test/core/router` — green.
- [ ] **Step 5: Commit**
```bash
git add lib/core/router/router.dart lib/core/router/router.g.dart lib/features/social/presentation/screens/tribe_lobby_screen.dart test/features/social/presentation/screens/tribe_lobby_screen_test.dart
git add -u lib/features/social/presentation/screens/social_discover_tab.dart
git commit -m "feat(router): remove /social/discover page; drop BROWSE BLUEPRINTS CTA"
```
(If the `git add -u` of the deleted file is not enough in your git version, use `git add -A lib/features/social/presentation/screens/social_discover_tab.dart`.)

## Task 9: Drop the `discover` node guide + migration entry

**Files:**
- Modify: `lib/features/tutorials/domain/node_guide_registry.dart`
- Modify: `lib/features/onboarding/data/repositories/local_settings_repository.dart`
- Modify: `test/features/tutorials/domain/node_guide_registry_test.dart`
- Modify: `test/features/onboarding/data/local_settings_repository_test.dart`

- [ ] **Step 1: Write the failing tests** — registry test: `expect(NodeGuideRegistry.forNode('discover'), isNull)`; migration test: seed `companion_visited_/discover: true` → after `migrateVisitedFlags()`, `getHasSeenNodeGuide('discover')` is false and the legacy key is removed.
- [ ] **Step 2: Implement** — remove the `NodeGuideDefinition(nodeId: 'discover', ...)` block (`node_guide_registry.dart:232-242`); remove `'/discover': 'discover',` from `routeToNode` (`local_settings_repository.dart:222`).
- [ ] **Step 3: Run** `flutter test test/features/tutorials/domain/node_guide_registry_test.dart test/features/onboarding/data/local_settings_repository_test.dart` — green.
- [ ] **Step 4: Commit**
```bash
git add lib/features/tutorials/domain/node_guide_registry.dart lib/features/onboarding/data/repositories/local_settings_repository.dart test/features/tutorials/domain/node_guide_registry_test.dart test/features/onboarding/data/local_settings_repository_test.dart
git commit -m "chore(tutorials): drop discover node guide and its visited-flag migration entry"
```

---

# Phase 6 — Cleanup + verification

## Task 10: Delete dead gamification Blueprint model; full verification

**Files:**
- Delete: `lib/features/gamification/domain/models/blueprint.dart`

- [ ] **Step 1: Verify zero references** — `grep -rn "gamification/domain/models/blueprint" lib test` → no matches (verified at spec time; re-check before deleting).
- [ ] **Step 2: Delete the file** — `git rm lib/features/gamification/domain/models/blueprint.dart`.
- [ ] **Step 3: Analyze** — `dart analyze lib` → 0 issues introduced by SP-F (compare against pre-flight baseline).
- [ ] **Step 4: Full focused test run** — `flutter test test/features/blueprints test/features/social/presentation/screens/tribe_lobby_screen_test.dart test/features/social/presentation/providers test/features/social/presentation/widgets/tribe_blueprints_section_test.dart test/features/tutorials test/features/onboarding/data/local_settings_repository_test.dart` — all green (note: the pre-existing `tribe_membership_service_test.dart` joinTribe failure belongs to SP-G and fails identically at HEAD; not SP-F's responsibility).
- [ ] **Step 5: Final grep sweep** — `grep -rn "social/discover\|SocialDiscoverTab\|images/blueprints" lib test` → no matches.
- [ ] **Step 6: Commit**
```bash
git commit -m "chore(gamification): delete dead Blueprint model"
```

---

## Commit summary (expected)

| Task | Message |
|---|---|
| T1 | `feat(blueprints): add recommendedArchetypes to Blueprint model` |
| T2 | `feat(blueprints): pure curation service — category fallback + archetype matching` |
| T3 | `feat(blueprints): seed v3 — curated recommendedArchetypes + merge backfill` |
| T4 | `feat(social): tribe blueprint providers use curation service; creator-tribe stream` |
| T5 | `feat(social): per-tribe curated blueprint section; creator-tribe branch; Discover link removed` |
| T6 | `feat(blueprints): BlueprintArtwork widget with branded fallback` |
| T7 | `fix(social): blueprint card + detail use BlueprintArtwork — broken images fall back, never blank` |
| T8 | `feat(router): remove /social/discover page; drop BROWSE BLUEPRINTS CTA` |
| T9 | `chore(tutorials): drop discover node guide and its visited-flag migration entry` |
| T10 | `chore(gamification): delete dead Blueprint model` |

**Handoff notes for later sub-projects:** SP-H performs the admin-only Firestore surgery (purge v1 archetype docs + fix `morning_3` imageUrl to `photo-1528715471579-d1bcf0ba5e83?w=800`); SP-D reintroduces the "Switch Tribes" CTA in the tribe lobby bottom bar; SP-E writes `creatorTribeId` on creator blueprints, which populates the creator-tribe sections.
