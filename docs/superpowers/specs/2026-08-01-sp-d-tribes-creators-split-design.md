# SP-D Design — "Tribes / Creators Split": All-Tribes Creators Section, Switch-Tribes CTA, Blueprint-Creator Removal

> **Date:** 2026-08-01
> **Status:** Approved (design review 2026-08-01)
> **Scope:** SP-D of the 8-sub-project program (A→H). Client-only: split the All Tribes screen into a CREATORS section + tribes grid, retarget the tribe-lobby primary CTA to "Switch Tribes", and remove the seeded fake creators + their blueprints (code + UI only). **No** `firestore.rules`, `firestore.indexes.json`, or `functions/` changes — the 12 seeded Firestore docs are deleted admin-side in SP-H.
> **Predecessor plans:** `2026-06-13-creator-tribes-data-layer.md` (introduced the creator_profiles seed), `2026-06-13-creator-tribes-hub.md` (lobby CREATORS strip), `2026-06-23-creator-routes.md` (browse/profile routes), `2026-07-29-tribe-membership-unified-social-plan.md` (tribe/membership rework SP-G touches), `2026-08-01-sp-a-narrator-coach-tutorials-premium-limits.md` (SP-A, landed 2026-08-01 — its `tribe_lobby` node guide already promises a "Switch tribes" bottom button; this sub-project makes the copy true).

---

## 1. Goals

1. **Split the All Tribes screen** (`/social/all`) into a **CREATORS section** (verified creators) above the existing **tribes grid** — one screen, two communities.
2. **Change the tribe-lobby primary CTA** from "BROWSE BLUEPRINTS" to **"SWITCH TRIBES"**, targeting the split All Tribes screen. The blueprints entry point dies here (the whole member-facing blueprints page dies in SP-F).
3. **Delete the blueprint creators** — the 6 seeded fake `creator_*` profiles and their 6 `cb_*` blueprints. Only creators that sign in through the creator login (SP-E completes their verification loop) remain.
4. **Remove the lobby's "CREATORS" strip and the `/creators` browse-all screen** — the two surfaces that existed only to showcase the seeds.
5. Keep everything real creators need: `CreatorProfileScreen`, the `/creators/:id` + `/social/creator/:id` routes, the `creator_profiles` collection, `CreatorRepository`'s client API, and `verifiedCreatorsStreamProvider` (which now feeds the new All Tribes creators section).

## 2. Recorded design decisions

| # | Decision | Choice |
|---|---|---|
| D1 | All-Tribes split | Add a "CREATORS" heading + horizontal row of compact creator cards **above** the tribes grid, fed by `verifiedCreatorsStreamProvider` (same source the strip/browse screen used). Empty state (post-removal, pre-SP-E): a tasteful **"Creators are coming"** empty state — never an error. |
| D2 | Lobby CTA | Primary button becomes **"SWITCH TRIBES"** → `context.push('/social/all')`. "CHALLENGES" stays as the outlined button. "BROWSE BLUEPRINTS" (and its `/social/discover` push) is removed — that page dies in SP-F. |
| D3 | Seed removal | Delete `seedCreatorsIfEmpty` + `seedCreatorBlueprintsIfEmpty` (code + seed data) and both call sites (`lib/main.dart` + `lib/core/data/seed_runner.dart`). Delete `TribeCreatorsStrip` + its lobby mount. Delete `CreatorsBrowseScreen` + the `/creators` route. **Keep** `CreatorProfileScreen` + `/creators/:id` + `/social/creator/:id`, the `creator_profiles` collection, and `CreatorRepository`'s read/write API (SP-E builds on it). |
| D4 | Registry cleanup | Verify the SP-A `tribe_lobby` node-guide copy stays accurate after the CTA change ("Switch tribes — Use the bottom button to browse and switch tribes." — accurate: the bottom button now literally says SWITCH TRIBES; no edit). The `discover` node guide dies with the blueprints page in SP-F — **do not touch it here**. |
| D5 | Data deletion | The 6 `creator_*` + 6 `cb_*` Firestore docs already exist in prod; client deletion is denied by rules (blueprints admin-only, creator_profiles owner-only) → one-off admin script/console cleanup, **deferred to SP-H**. SP-D ships only the code removal; document the `purgeOrphanedUserData` `creator_*` skip list (currently a system-seed guard) for update when the docs are deleted. |
| D6 | Out of scope | Creator verification/invites (SP-E), member-facing blueprints page + per-tribe blueprints (SP-F), tribe member counts/XP accounting (SP-G). |

## 3. Architecture

### Before (SP-D)

```
verifiedCreatorsStreamProvider (creator_profiles, isVerifiedCreator==true, orderBy blueprintCount desc, limit 12)
 ├─ TribeCreatorsStrip      → lobby "CREATORS" strip ("View All →" → /creators)   [SHOWS SEEDS]
 ├─ CreatorsBrowseScreen    → /creators 2-col grid                                [SHOWS SEEDS]
 └─ (AllTribesScreen        → pure tribes grid; no creators at all)

seeds (called on every sign-in, lib/main.dart:172-176):
 seedCreators()            → CreatorRepository.seedCreatorsIfEmpty  → 6 creator_* docs (isVerifiedCreator: true)
 seedCreatorBlueprints()   → BlueprintRepository.seedCreatorBlueprintsIfEmpty → 6 cb_* docs (+ blueprintCount bumps)

lobby CTA bar: [CHALLENGES (outlined)] [BROWSE BLUEPRINTS (primary → /social/discover)]
```

### After (SP-D)

```
verifiedCreatorsStreamProvider  ──►  AllTribesScreen "CREATORS" section (horizontal CreatorCards)
                                     ├─ creators empty → "Creators are coming" state (pre-SP-E / post-removal)
                                     └─ creators error → treated as empty (same precedent as the old strip)
lobby CTA bar: [CHALLENGES (outlined)] [SWITCH TRIBES (primary → /social/all)]
lobby slivers: ... CREATORS strip removed ... → TribeBlueprintsSection stays until SP-F
seeds: seedCreators / seedCreatorBlueprints gone from lib; /creators route + browse screen gone;
       CreatorProfileScreen + /creators/:id + /social/creator/:id KEPT for real creators (SP-E)
```

Layers touched:

- **Social presentation:** `AllTribesScreen` gains a creators section (D1); `TribeLobbyScreen` CTA + strip removal (D2/D3); new shared `CreatorCard` widget (D1).
- **Social data:** `CreatorRepository` loses only `seedCreatorsIfEmpty`; read/write client API (`getCreatorProfile`, `watchCreatorProfile`, `watchVerifiedCreators`, `updateCreatorProfile`) and the provider layer stay.
- **Blueprints data:** `BlueprintRepository` loses only `seedCreatorBlueprintsIfEmpty`. The `Blueprint.isCreatorBlueprint` field, `blueprint_detail_screen.dart:39` "creator link", and `blueprint_builder_screen.dart:277` (real creators set the flag) all stay.
- **Routing:** `/creators` (exact) dies; `/creators/:id` alias + `/social/creator/:id` stay. `router.g.dart` regenerated.
- **App bootstrap:** `lib/main.dart` seed calls reduced from 5 to 3; `seed_runner.dart` wrappers for creators removed.
- **Functions (no change now):** `purgeOrphanedUserData.ts:48` keeps `SYSTEM_PREFIXES = ["creator_"]` — harmless until the docs are deleted; SP-H updates/removes it then.

## 4. Component specs

### 4.1 All Tribes split screen (`lib/features/social/presentation/screens/all_tribes_screen.dart`)

Current shape (verified): `ConsumerStatefulWidget` watching `allArchetypeClubsProvider`, wrapped in `NodeGuideHost(nodeId: 'all_tribes')`, AppBar "ALL TRIBES" with back arrow, body = `RefreshIndicator` + `GridView.builder` (2 cols <600dp, 3 cols ≥600dp, `childAspectRatio: 0.72`, `TribeCard`), loading skeleton, error `AppErrorWidget`, empty text "No tribes available".

New shape:

1. Watch both `allArchetypeClubsProvider` (existing) and `verifiedCreatorsStreamProvider` (new watch).
2. Replace the body with a `CustomScrollView` (kept inside the existing `RefreshIndicator`, which keeps its `onRefresh` invalidating `allArchetypeClubsProvider`):

   ```
   slivers:
     1. SliverToBoxAdapter — "CREATORS" heading (reuse the strip's heading style:
        EmergeColors.nebulaPrimary, 12, bold, letterSpacing 2, padding fromLTRB(20, 24, 20, 12))
     2. SliverToBoxAdapter — creators body (h ≈ 120):
          data & non-empty  → SizedBox(height: 120) + horizontal ListView.separated of CreatorCard
          data & empty      → _CreatorsEmptyState ("Creators are coming…")
          loading           → compact centered spinner (strip precedent)
          error             → _CreatorsEmptyState (strip precedent — errors never break the screen)
     3. SliverToBoxAdapter — "TRIBES" heading (same style, padding fromLTRB(20, 24, 20, 12))
     4. SliverPadding + SliverGrid — existing grid delegate + TribeCard builder (unchanged)
     5. If tribes empty → SliverFillRemaining with the existing "No tribes available" center text
   ```

3. Tribes loading/error states are unchanged in spirit (skeleton / `AppErrorWidget`), rendered as `SliverFillRemaining` equivalents so the layout compiles to a single scrollable.
4. There is deliberately **no "View All" link**: with the browse-all screen gone, the horizontal row (limit 12) *is* the complete list.

### 4.2 `CreatorCard` (new shared widget, `lib/features/social/presentation/widgets/creator_card.dart`)

Verified: no public reusable creator card exists today — `_CreatorFace` (private in `tribe_creators_strip.dart`) and `_CreatorTile` (private in `creators_browse_screen.dart`), and `FallbackInitialAvatar` already lives in `lib/core/presentation/widgets/fallback_initial_avatar.dart`.

Spec — `class CreatorCard extends StatelessWidget { final CreatorProfile creator; }`:

- `SizedBox(width: 96)` inside a horizontal list; `InkWell` with rounded 12 border radius; tap → `context.push('/social/creator/${creator.userId}')` (the route `CreatorProfileScreen` lives under; same target the old strip used).
- `FallbackInitialAvatar(name, size: 64, imageUrl: avatarUrl, borderColor: EmergeColors.nebulaPrimaryContainer, borderWidth: 1.5)` — drop-in from the old strip.
- Name: maxLines 1, ellipsis, white, 11, w600, centered.
- Sub-line: `'$n blueprint${n == 1 ? '' : 's'}'` in white54, 10 (from `_CreatorTile`; survives the seed removal because real creators' `blueprintCount` is maintained by their own publish flow).
- Fallbacks: `displayName` empty → 'Creator'; never throws on a partial profile.

### 4.3 Switch-Tribes CTA (`lib/features/social/presentation/screens/tribe_lobby_screen.dart:168-208`)

- Primary `EmergePrimaryButton`: label `'SWITCH TRIBES'`, `leadingIcon: Icons.swap_horiz` (matches the node guide's `swap_horiz` icon), `onPressed: () => context.push('/social/all')` — same navigation style as the outgoing `/social/discover` push; `push` (not `go`) so the All Tribes screen keeps its back arrow, and the Social-tab-root lobby (no history) still works.
- "CHALLENGES" outlined button unchanged (`context.push('/challenges')`).
- The `bottomNavigationBar` `profileAsync.value == null ? null : ...` guard is untouched.
- **Same edit removes the CREATORS strip mount** (see 4.4) so the dirty file is touched exactly once.

### 4.4 CREATORS strip removal

- `lib/features/social/presentation/widgets/tribe_creators_strip.dart` — delete file (widget + private `_CreatorFace` + `_EmptyState`).
- `lib/features/social/presentation/screens/tribe_lobby_screen.dart` — remove the `SliverToBoxAdapter` mount (`Padding(bottom: 8, child: TribeCreatorsStrip())`, lines 110-115) + the import (line 20). The lobby's sequence doc comment (lines 29-32) drops "Creators (faces only)".
- Nothing else consumed the strip.

### 4.5 Browse-all-creators removal

- `lib/features/social/presentation/screens/creators_browse_screen.dart` — delete file.
- `lib/core/router/router.dart` — remove `GoRoute(path: '/creators', ...)` (lines 373-377) + the import (line 47). **Keep** `GoRoute(path: '/creators/:id', ...)` (lines 353-359, deep-link alias used by `creator_overview_tab.dart:227`) and `GoRoute(path: 'creator/:id', ...)` (lines 551-556).
- Regenerate `lib/core/router/router.g.dart` via build_runner (it currently carries a trivial pre-existing hash-line WIP diff — see Risks).

### 4.6 Creators empty state (post-removal / pre-SP-E)

Between this sub-project and SP-E there are **zero** verified creators (`isVerifiedCreator: false` for every real signup — `auth_providers.dart` `signUpCreator`/`signUpCreatorWithGoogle`). The section must read as intentional, not broken:

- Title: **"Creators are coming"** (white, 13, w600).
- Sub-copy: "Verified creators will appear here soon." (white54, 12) — one-liner, no icons/illustration, consistent with the app's dark glass aesthetic.
- Never show an error widget for the creators stream (loading spinner or empty state only).

## 5. Data & storage changes

### Removed from code (this sub-project)

| Item | Location | Notes |
|---|---|---|
| `seedCreatorsIfEmpty` + 6-profile seed data | `lib/features/social/data/repositories/creator_repository.dart:70-193` | Also drops now-unused imports `core/utils/app_logger.dart` + `auth/domain/entities/user_extension.dart` (both were seed-only) |
| `seedCreatorBlueprintsIfEmpty` + 6-blueprint seed data + count-bump batch | `lib/features/blueprints/data/repositories/blueprint_repository.dart:405-660` | `FieldValue`/`AppLogger` stay (used elsewhere in the file) |
| `seedCreators` + `seedCreatorBlueprints` wrappers + `creator_repository.dart` import | `lib/core/data/seed_runner.dart:123-139` | |
| Seed call sites | `lib/main.dart:175-176` | `seedOfficialClubs/seedChallenges/seedBlueprints` stay |
| `TribeCreatorsStrip` widget + test | `lib/features/social/presentation/widgets/tribe_creators_strip.dart`, `test/.../widgets/tribe_creators_strip_test.dart` | |
| `CreatorsBrowseScreen` + test | `lib/features/social/presentation/screens/creators_browse_screen.dart`, `test/.../screens/creators_browse_screen_test.dart` | |
| `/creators` route | `lib/core/router/router.dart:373-377` + import; regen `router.g.dart` | |

### Unchanged (kept for SP-E / SP-F)

- `creator_profiles` collection, `CreatorProfile` entity (incl. `isVerifiedCreator`, `blueprintCount`, `tribeId`, `archetype`), `CreatorRepository` client API, `creator_provider.dart` (`creatorProfileProvider`, `isVerifiedCreatorProvider`, `verifiedCreatorsStreamProvider`, `tribeCreatorsProvider` — the latter has no app consumers today and is reserved for SP-E).
- `CreatorProfileScreen` + `/creators/:id` + `/social/creator/:id` + `creator_profile_screen_test.dart`.
- `Blueprint.isCreatorBlueprint` field + `blueprint_builder_screen.dart:277` (real creators) + `blueprint_detail_screen.dart:39` creator link.
- Node guides `all_tribes` + `tribe_lobby` (copy verified accurate; see D4). `discover` untouched (dies in SP-F).
- `functions/src/purgeOrphanedUserData.ts` `SYSTEM_PREFIXES = ["creator_"]` (line 48) — still correct as a system-seed guard until SP-H deletes the docs.

### Deferred admin-side deletion (SP-H)

| Docs | Collection | Why deferred |
|---|---|---|
| `creator_aria_chen`, `creator_marcus_okafor`, `creator_sora_tanaka`, `creator_julian_cross`, `creator_naia_singh`, `creator_elias_vance` | `creator_profiles` | rules: owner-only delete |
| `cb_aria_deep_work`, `cb_marcus_morning`, `cb_sora_creative`, `cb_julian_calm`, `cb_naia_devotion`, `cb_elias_studio` | `blueprints` | rules: admin-only delete |

SP-H work items to hand off: (1) one-off admin script or console batch deleting the 12 docs (optionally the `blueprintCount: 1` bumps die with the profiles); (2) after deletion, drop/neutralize the `creator_` prefix from `SYSTEM_PREFIXES` in `purgeOrphanedUserData.ts` (real creator uids never start with `creator_`, so the guard becomes dead weight).

Post-SP-D behavior with prod data intact: the 12 docs remain in Firestore but **no client code reads them** (strip + browse gone; the All Tribes section renders the empty state because the docs are still `isVerifiedCreator: true`... — see note below).

> **Note on interim state:** until SP-H deletes the docs, `verifiedCreatorsStreamProvider` will still emit the 6 fake profiles, so the new CREATORS section will render them on the All Tribes screen (they are gone from the lobby and browse-all). This is the accepted interim state — the seeds stop being *created* and stop having their two dedicated surfaces; the residual list on the split screen disappears permanently at SP-H. If a zero-fake interim is required, SP-H can be pulled forward (out of SP-D's scope).

## 6. File inventory

### New files

| Path | Responsibility |
|---|---|
| `lib/features/social/presentation/widgets/creator_card.dart` | Public compact `CreatorCard` (avatar, name, blueprint count, tap → `/social/creator/:id`) |
| (test additions) `test/features/social/presentation/screens/all_tribes_screen_test.dart` | Creators-section + empty-state coverage (extended, not new file) |

### Modified files

| Path | Change |
|---|---|
| `lib/features/social/presentation/screens/all_tribes_screen.dart` | Watch `verifiedCreatorsStreamProvider`; CustomScrollView with CREATORS section + TRIBES grid; empty states |
| `lib/features/social/presentation/screens/tribe_lobby_screen.dart` | CTA → "SWITCH TRIBES" → `/social/all`; remove strip mount + import; doc comment |
| `lib/core/router/router.dart` | Remove `/creators` route + `creators_browse_screen.dart` import |
| `lib/core/router/router.g.dart` | Regenerated (removes the route) |
| `lib/main.dart` | Drop `seedCreators()` + `seedCreatorBlueprints()` calls |
| `lib/core/data/seed_runner.dart` | Drop both wrappers + `creator_repository.dart` import |
| `lib/features/social/data/repositories/creator_repository.dart` | Drop `seedCreatorsIfEmpty` + seed-only imports |
| `lib/features/blueprints/data/repositories/blueprint_repository.dart` | Drop `seedCreatorBlueprintsIfEmpty` |
| `test/features/social/presentation/screens/all_tribes_screen_test.dart` | Add `verifiedCreatorsStreamProvider` overrides + 2 new tests |
| `test/features/social/presentation/screens/tribe_lobby_screen_test.dart` | CTA test → SWITCH TRIBES (⚠️ file already dirty with WIP — see Risks) |

### Deleted files

| Path | Reason |
|---|---|
| `lib/features/social/presentation/widgets/tribe_creators_strip.dart` | Seed showcase surface; creators move to All Tribes |
| `test/features/social/presentation/widgets/tribe_creators_strip_test.dart` | ditto |
| `lib/features/social/presentation/screens/creators_browse_screen.dart` | Seed showcase surface; no other entry points once strip is gone |
| `test/features/social/presentation/screens/creators_browse_screen_test.dart` | ditto |

## 7. Error handling & edge cases

| Case | Behavior |
|---|---|
| Creators stream errors | Section renders the "Creators are coming" empty state (old strip precedent). Never an error widget; tribes grid unaffected. |
| Creators stream loading | Compact centered spinner inside the section. |
| Zero creators (post-removal, pre-SP-E) | "Creators are coming" + "Verified creators will appear here soon." |
| Zero tribes | CREATORS section still renders; tribes area shows existing "No tribes available" via `SliverFillRemaining`. |
| Real creator pre-SP-E | `isVerifiedCreator: false` → invisible in the section by design; their `CreatorProfileScreen` still reachable via `/creators/:id` deep links from `creator_overview_tab.dart:227`. |
| Creator with empty `displayName` / `avatarUrl` null | Card falls back to 'Creator' + initials avatar (existing `FallbackInitialAvatar`). |
| Lobby as Social-tab root (canPop false) | `SWITCH TRIBES` push still works (same as old `/social/discover` push). |
| Back-stack loop (grid → lobby → SWITCH TRIBES → grid) | Acceptable: back arrow pops to the lobby; same pattern the old BROWSE BLUEPRINTS push had. |
| Existing widget tests without a creators override | `AllTribesScreen` will subscribe `verifiedCreatorsStreamProvider`; un-mocked Firebase throws into the stream → error → empty state → tests stay green but nondeterministic; all affected tests get an explicit override anyway. |
| Router regen | `router.g.dart` is generated; run build_runner after removing the route (it will fold the pre-existing hash-only WIP line — see Risks). |
| Blueprints section after seed removal | `tribeBlueprintsSection` (lobby) loses the `cb_*` rows (they matched by `creatorArchetype`); only official blueprints remain until SP-F. No code change in SP-D. |

## 8. Testing strategy

Delete-tests-first is not applicable to removed code; TDD applies to the two additive changes, and deletion is verified by grep/analyze (mirrors SP-A Task 15).

1. **AllTribes split (new tests):**
   - Renders the "CREATORS" heading + a creator's name when `verifiedCreatorsStreamProvider` yields one profile.
   - Renders "Creators are coming" when the provider yields `[]`.
   - Existing 3 tests updated: add `verifiedCreatorsStreamProvider.overrideWith((ref) => Stream.value(const <CreatorProfile>[]))` next to the existing `allArchetypeClubsProvider` overrides.
2. **Lobby CTA (updated test):** `tribe_lobby_screen_test.dart` CTA test renamed → expects `'SWITCH TRIBES'` present, `'BROWSE BLUEPRINTS'` absent (harness already overrides `verifiedCreatorsStreamProvider`, so the strip removal needs no harness change).
3. **Removal verification (grep, not tests):**
   - `grep -rn "TribeCreatorsStrip|CreatorsBrowseScreen" lib test` → nothing.
   - `grep -rn "seedCreatorsIfEmpty|seedCreatorBlueprintsIfEmpty|seedCreators\(|seedCreatorBlueprints\(" lib` → nothing.
   - `grep -n "BROWSE BLUEPRINTS" lib` → nothing.
   - `dart analyze lib test` → 0 issues (vs. pre-flight baseline).
   - Deleted tests: `tribe_creators_strip_test.dart`, `creators_browse_screen_test.dart` removed with their widgets.
4. **Focused suites:** `flutter test test/features/social/presentation/screens test/features/social/presentation/widgets` after each task; full targeted run in the verification task.
5. **No golden/image tests** are affected (none render the strip or browse screen).

## 9. Out of scope (later sub-projects)

- **SP-E — creator verification/invites:** flips real creators to `isVerifiedCreator: true` (fixes the dashboard bounce + populates the All Tribes creators section). SP-D must leave the plumbing (`verifiedCreatorsStreamProvider`, `CreatorRepository` API, profile screen, routes) intact and must NOT depend on SP-E.
- **SP-F — blueprints page:** removes the member-facing blueprints surface (`/social/discover`, `SocialDiscoverTab`, `TribeBlueprintsSection`, `discover` node guide). SP-D only removes the blueprint *entry point* from the lobby CTA.
- **SP-G — member counts/XP accounting:** tribe membership service fixes (pre-existing failing `tribe_membership_service_test.dart` joinTribe test noted in SP-A belongs here).
- **SP-H — data cleanup:** admin deletion of the 12 seeded docs + `purgeOrphanedUserData` skip-list update (see §5).
- `Blueprint.isCreatorBlueprint` field/flow for real creators, `blueprint_builder_screen`, `blueprint_detail_screen` creator link — untouched by SP-D.

## 10. Risks

1. **Dirty working tree (HIGH):** `lib/features/social/presentation/screens/tribe_lobby_screen.dart` carries an uncommitted 270-line WIP (back-button/`canPop` refactor, +160/−110) — the exact file Task 2 edits. `test/features/social/presentation/screens/tribe_lobby_screen_test.dart` is dirty too. The plan commits by explicit path; staging the lobby file folds the WIP into the SP-D commit. Execution must (a) never `git add -A`, (b) coordinate with the WIP owner — ask them to commit first, or accept the combined commit — and (c) never revert/discard WIP hunks.
2. **`router.g.dart` regen:** carries a pre-existing 1-line hash-only WIP diff; build_runner output will fold it. Harmless, but the commit should be named accordingly.
3. **Interim prod data:** until SP-H, the 6 fake profiles still appear in the new All Tribes CREATORS section (they are gone from the lobby and browse-all). Accepted; documented in §5.
4. **Unused-import trap:** after seed removal, `creator_repository.dart` loses its only `AppLogger` + `UserArchetype` usage — analyzer fails if imports aren't dropped in the same task.
5. **Test harness drift:** `all_tribes_screen_test.dart` currently passes with no creators override; the new watch makes un-overridden runs hit Firebase in tests → add the override in the same task as the UI change.
6. **Node-guide copy:** `tribe_lobby` guide says "Use the bottom button to browse and switch tribes" — becomes accurate only after Task 2; verify in the same task (no edit expected).
