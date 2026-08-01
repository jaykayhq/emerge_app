# SP-D: Tribes/Creators Split, Switch-Tribes CTA, Blueprint-Creator Removal — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Split the All Tribes screen (`/social/all`) into a CREATORS section (verified creators, horizontal cards) above the existing tribes grid; change the tribe-lobby primary CTA from "BROWSE BLUEPRINTS" to "SWITCH TRIBES" (→ `/social/all`); delete the 6 seeded fake creators + their 6 `cb_*` blueprints (code only) and remove the two surfaces that showcased them (lobby `TribeCreatorsStrip`, `/creators` browse-all screen). Real creator surfaces stay: `CreatorProfileScreen`, `/creators/:id` + `/social/creator/:id`, the `creator_profiles` collection and `CreatorRepository` client API (SP-E builds on them).

**Architecture:** One new shared widget (`CreatorCard`) feeding a new "CREATORS" sliver in `AllTribesScreen` from the existing `verifiedCreatorsStreamProvider`; one CTA swap in the lobby bottom bar; four deletion sets (strip widget+test, browse screen+route+test, seed methods + call sites, seed_runner wrappers). No rules/functions changes — the 12 prod Firestore docs are deleted admin-side in SP-H.

**Tech Stack:** Flutter 3.x, Dart 3.10+, Riverpod 3.x, go_router, fake_cloud_firestore, mocktail (tests).

**Spec:** `docs/superpowers/specs/2026-08-01-sp-d-tribes-creators-split-design.md`

---

## ⚠️ Pre-flight (read first)

1. **The working tree is dirty with OTHER workstream WIP.** Critical files:
   - `lib/features/social/presentation/screens/tribe_lobby_screen.dart` — uncommitted 270-line WIP (back-button/`canPop` refactor, +160/−110). **Task 2 edits this file.** Never revert or discard the WIP hunks; commit by explicit path only.
   - `test/features/social/presentation/screens/tribe_lobby_screen_test.dart` — dirty (same WIP).
   - `lib/core/router/router.g.dart` — pre-existing 1-line hash-only diff (build_runner artifact; Task 4's regen will fold it in — harmless).
   - Other WIP: `firestore.rules`, drift tables/daos (`app_database.dart`, `habits_*`), `social_hub_screen.dart`, `ad_banner_widget.dart`, `month_calendar_strip.dart`, several untracked new test/provider files. **None of these are touched by SP-D.**
2. **Commit ONLY the files each task names — never `git add -A`, never `git add lib` wholesale.**
3. Run `dart analyze lib` before starting and record the baseline. Only SP-D-introduced errors are this plan's responsibility.
4. Do not run the full test suite (slow; `tribe_membership_service_test.dart` joinTribe test fails pre-existing, belongs to SP-G). Run only the focused suites each task names.
5. No Drift schema changes, no rules changes, no functions changes in this plan.

## File structure

### New files

| Path | Responsibility |
|---|---|
| `lib/features/social/presentation/widgets/creator_card.dart` | Public compact `CreatorCard` (avatar, name, blueprint count; tap → `/social/creator/:id`) |

### Modified files

| Path | Change |
|---|---|
| `lib/features/social/presentation/screens/all_tribes_screen.dart` | Watch `verifiedCreatorsStreamProvider`; `CustomScrollView` with CREATORS sliver + TRIBES grid; empty states |
| `lib/features/social/presentation/screens/tribe_lobby_screen.dart` | CTA → `SWITCH TRIBES` → `push('/social/all')`; remove `TribeCreatorsStrip` mount + import; doc comment (⚠️ dirty) |
| `lib/core/router/router.dart` | Remove `/creators` route + `creators_browse_screen.dart` import |
| `lib/core/router/router.g.dart` | Regenerated (Task 4) |
| `lib/main.dart` | Remove `seedCreators()` + `seedCreatorBlueprints()` calls |
| `lib/core/data/seed_runner.dart` | Remove `seedCreators` + `seedCreatorBlueprints` wrappers + `creator_repository.dart` import |
| `lib/features/social/data/repositories/creator_repository.dart` | Remove `seedCreatorsIfEmpty` + seed-only imports (`app_logger.dart`, `user_extension.dart`) |
| `lib/features/blueprints/data/repositories/blueprint_repository.dart` | Remove `seedCreatorBlueprintsIfEmpty` |
| `test/features/social/presentation/screens/all_tribes_screen_test.dart` | Add `verifiedCreatorsStreamProvider` overrides to all 3 existing tests + 2 new tests |
| `test/features/social/presentation/screens/tribe_lobby_screen_test.dart` | CTA test → SWITCH TRIBES (⚠️ dirty) |

### Deleted files

| Path | Reason |
|---|---|
| `lib/features/social/presentation/widgets/tribe_creators_strip.dart` | Seed showcase surface; creators move to All Tribes |
| `test/features/social/presentation/widgets/tribe_creators_strip_test.dart` | ditto |
| `lib/features/social/presentation/screens/creators_browse_screen.dart` | Seed showcase surface; only entry was the strip's "View All" |
| `test/features/social/presentation/screens/creators_browse_screen_test.dart` | ditto |

---

# Phase 1 — All Tribes split (TDD)

## Task 1: `CreatorCard` widget + CREATORS section on the All Tribes screen

**Files:**
- Create: `lib/features/social/presentation/widgets/creator_card.dart`
- Modify: `lib/features/social/presentation/screens/all_tribes_screen.dart`
- Modify: `test/features/social/presentation/screens/all_tribes_screen_test.dart`

- [ ] **Step 1: Write the failing tests**

Append to `test/features/social/presentation/screens/all_tribes_screen_test.dart` (and update its imports):

```dart
import 'package:emerge_app/features/social/domain/entities/creator_profile.dart';
import 'package:emerge_app/features/social/presentation/providers/creator_provider.dart';
```

New tests:

```dart
  testWidgets('AllTribesScreen renders the CREATORS section with creator cards',
      (tester) async {
    const creator = CreatorProfile(
      userId: 'creator_test',
      displayName: 'Test Creator',
      isVerifiedCreator: true,
      blueprintCount: 2,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allArchetypeClubsProvider.overrideWith(
            (ref) => Stream.value(<Tribe>[]),
          ),
          authStateChangesProvider.overrideWith(
            (ref) => Stream.value(emptyUser),
          ),
          verifiedCreatorsStreamProvider.overrideWith(
            (ref) => Stream.value(const [creator]),
          ),
        ],
        child: const MaterialApp(home: AllTribesScreen()),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('CREATORS'), findsOneWidget);
    expect(find.text('Test Creator'), findsOneWidget);
    expect(find.text('2 blueprints'), findsOneWidget);
  });

  testWidgets('AllTribesScreen shows the creators empty state when no creators exist',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allArchetypeClubsProvider.overrideWith(
            (ref) => Stream.value(<Tribe>[]),
          ),
          authStateChangesProvider.overrideWith(
            (ref) => Stream.value(emptyUser),
          ),
          verifiedCreatorsStreamProvider.overrideWith(
            (ref) => Stream.value(const <CreatorProfile>[]),
          ),
        ],
        child: const MaterialApp(home: AllTribesScreen()),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Creators are coming'), findsOneWidget);
  });
```

Also add the same `verifiedCreatorsStreamProvider.overrideWith((ref) => Stream.value(const <CreatorProfile>[]))` override to the **3 existing tests** (`renders loading skeleton initially`, `renders tribe list`, `shows empty state`) so the new watch never hits real Firebase in tests.

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/features/social/presentation/screens/all_tribes_screen_test.dart`
Expected: FAIL — no 'CREATORS' text / no 'Creators are coming' (section doesn't exist yet).

- [ ] **Step 3: Create `CreatorCard`**

`lib/features/social/presentation/widgets/creator_card.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:emerge_app/core/presentation/widgets/fallback_initial_avatar.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/features/social/domain/entities/creator_profile.dart';

/// Compact verified-creator card for the All Tribes CREATORS section.
/// Taps through to the creator's profile ([CreatorProfileScreen]).
class CreatorCard extends StatelessWidget {
  final CreatorProfile creator;

  const CreatorCard({super.key, required this.creator});

  @override
  Widget build(BuildContext context) {
    final name = creator.displayName?.isNotEmpty == true
        ? creator.displayName!
        : 'Creator';
    final count = creator.blueprintCount;
    final blueprintsLabel =
        '$count ${count == 1 ? 'blueprint' : 'blueprints'}';

    return SizedBox(
      width: 96,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/social/creator/${creator.userId}'),
        child: Column(
          children: [
            FallbackInitialAvatar(
              name: name,
              size: 64,
              imageUrl: creator.avatarUrl,
              borderColor: EmergeColors.nebulaPrimaryContainer,
              borderWidth: 1.5,
            ),
            const Gap(8),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(2),
            Text(
              blueprintsLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white54, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Split the screen**

In `lib/features/social/presentation/screens/all_tribes_screen.dart`:

1. Add imports: `package:emerge_app/features/social/presentation/providers/creator_provider.dart`, `package:emerge_app/features/social/presentation/widgets/creator_card.dart`.
2. In `build`, add `final creatorsAsync = ref.watch(verifiedCreatorsStreamProvider);` next to the existing `tribesAsync` watch.
3. Replace the `body:` so the grid becomes the last sliver of a `CustomScrollView` (keep the existing `RefreshIndicator` wrapping it):

```dart
        body: tribesAsync.when(
          data: (tribes) {
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(allArchetypeClubsProvider);
              },
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // ── CREATORS ──
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
                      child: Text(
                        'CREATORS',
                        style: TextStyle(
                          color: EmergeColors.nebulaPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(child: _creatorsBody(creatorsAsync)),
                  // ── TRIBES ──
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
                      child: Text(
                        'TRIBES',
                        style: TextStyle(
                          color: EmergeColors.nebulaPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                  if (tribes.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text(
                          'No tribes available',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount:
                              MediaQuery.of(context).size.width > 600 ? 3 : 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.72,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => TribeCard(tribe: tribes[index]),
                          childCount: tribes.length,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
          loading: () =>
              const Center(child: EmergeLoadingSkeleton(itemCount: 5)),
          error: (error, stack) => Center(
            child: AppErrorWidget(
              message: 'Could not load tribes',
              onRetry: () => ref.invalidate(allArchetypeClubsProvider),
            ),
          ),
        ),
```

4. Add the private builders at the bottom of the state class:

```dart
  /// CREATORS section body: horizontal card row, spinner while loading, or
  /// the "coming soon" empty state. Errors degrade to the empty state —
  /// the tribes grid must never be blocked by the creators stream.
  Widget _creatorsBody(AsyncValue<List<CreatorProfile>> creatorsAsync) {
    return SizedBox(
      height: 118,
      child: creatorsAsync.when(
        data: (creators) {
          if (creators.isEmpty) return const _CreatorsEmptyState();
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            physics: const BouncingScrollPhysics(),
            itemCount: creators.length,
            separatorBuilder: (_, _) => const Gap(14),
            itemBuilder: (context, index) =>
                CreatorCard(creator: creators[index]),
          );
        },
        loading: () => const Center(
          child: SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        error: (_, _) => const _CreatorsEmptyState(),
      ),
    );
  }
```

5. Add the empty-state widget (same file, bottom):

```dart
class _CreatorsEmptyState extends StatelessWidget {
  const _CreatorsEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Creators are coming',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            Gap(4),
            Text(
              'Verified creators will appear here soon.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
```

Required imports to add: `package:emerge_app/core/theme/emerge_colors.dart`, `package:emerge_app/features/social/domain/entities/creator_profile.dart`, `package:gap/gap.dart`, plus the two from step 1.

- [ ] **Step 5: Run tests to verify they pass**

Run: `flutter test test/features/social/presentation/screens/all_tribes_screen_test.dart`
Expected: PASS — 5 tests (3 existing + 2 new).

- [ ] **Step 6: Analyze + commit**

Run: `dart analyze lib/features/social/presentation/screens/all_tribes_screen.dart lib/features/social/presentation/widgets/creator_card.dart`
Expected: 0 issues.

```bash
git add lib/features/social/presentation/widgets/creator_card.dart lib/features/social/presentation/screens/all_tribes_screen.dart test/features/social/presentation/screens/all_tribes_screen_test.dart
git commit -m "feat(social): split All Tribes screen — CREATORS section above the tribes grid"
```

---

# Phase 2 — Lobby CTA + strip unmount

## Task 2: CTA → "SWITCH TRIBES" and unmount `TribeCreatorsStrip`

**Files:**
- Modify: `lib/features/social/presentation/screens/tribe_lobby_screen.dart` (⚠️ dirty — see protocol below)
- Modify: `test/features/social/presentation/screens/tribe_lobby_screen_test.dart` (⚠️ dirty)

> **⚠️ Dirty-file protocol (read before touching):** `tribe_lobby_screen.dart` carries uncommitted WIP (canPop/back-button refactor). Your edit touches the CTA `EmergePrimaryButton` (lines ~198-204) and the strip sliver (lines ~109-115) — both disjoint from the WIP hunks, so editing on top is safe. **Before committing, confirm with the coordinator that the WIP owner has committed (or agreed to fold) their changes; never revert WIP hunks, never `git stash`.** If the WIP is still uncommitted at commit time, stop and ask — do not stage the file without approval.

- [ ] **Step 1: Update the failing test**

In `test/features/social/presentation/screens/tribe_lobby_screen_test.dart`, replace the CTA test (lines ~129-137):

```dart
  testWidgets(
      'TribeLobbyScreen renders CTA bar with CHALLENGES and SWITCH TRIBES buttons',
      (tester) async {
    await tester.pumpWidget(buildTest());
    await tester.pump(const Duration(milliseconds: 100));

    // CTA bar buttons.
    expect(find.text('CHALLENGES'), findsOneWidget);
    expect(find.text('SWITCH TRIBES'), findsOneWidget);
    expect(find.text('BROWSE BLUEPRINTS'), findsNothing);
  });
```

(The harness already overrides `verifiedCreatorsStreamProvider` with `Stream.empty()`, so unmounting the strip needs no harness change.)

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/social/presentation/screens/tribe_lobby_screen_test.dart`
Expected: FAIL — 'SWITCH TRIBES' not found; 'BROWSE BLUEPRINTS' still present.

- [ ] **Step 3: Change the CTA**

In `lib/features/social/presentation/screens/tribe_lobby_screen.dart`, the primary button (lines ~198-204):

```dart
                    Expanded(
                      child: EmergePrimaryButton(
                        label: 'SWITCH TRIBES',
                        leadingIcon: Icons.swap_horiz,
                        onPressed: () => context.push('/social/all'),
                      ),
                    ),
```

- [ ] **Step 4: Unmount the strip**

1. Delete the sliver (lines ~109-115):

```dart
                        const SliverToBoxAdapter(child: Gap(8)),
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: TribeCreatorsStrip(),
                          ),
                        ),
```

2. Remove the import `package:emerge_app/features/social/presentation/widgets/tribe_creators_strip.dart` (line 20).
3. Update the class doc-comment sequence (lines ~29-32): `Hero → Stats → Status chips → Your Circle (partners) → Live (feed / leaderboard) → Creators (faces only) → Your Quests …` becomes `Hero → Stats → Status chips → Your Circle (partners) → Live (feed / leaderboard) → Your Quests …`.
4. Verify the SP-A `tribe_lobby` node guide stays accurate (no edit expected): `NodeGuideRegistry.forNode('tribe_lobby')` item "Switch tribes — Use the bottom button to browse and switch tribes." (`lib/features/tutorials/domain/node_guide_registry.dart` lines ~562-566) now matches the real button.

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/features/social/presentation/screens/tribe_lobby_screen_test.dart`
Expected: PASS.

- [ ] **Step 6: Analyze + commit (per dirty-file protocol)**

Run: `dart analyze lib/features/social/presentation/screens/tribe_lobby_screen.dart`
Expected: 0 issues.

```bash
git add lib/features/social/presentation/screens/tribe_lobby_screen.dart test/features/social/presentation/screens/tribe_lobby_screen_test.dart
git commit -m "feat(social): lobby CTA \"SWITCH TRIBES\" → /social/all; drop CREATORS strip from lobby"
```

If the coordinator has not approved folding the WIP into this commit, stop and hand back instead of committing.

---

# Phase 3 — Remove the strip surface

## Task 3: Delete `TribeCreatorsStrip` + its test

**Files:**
- Delete: `lib/features/social/presentation/widgets/tribe_creators_strip.dart`
- Delete: `test/features/social/presentation/widgets/tribe_creators_strip_test.dart`

- [ ] **Step 1: Verify no live references remain**

Run: `grep -rn "TribeCreatorsStrip" lib test --include="*.dart"`
Expected: nothing (Task 2 removed the only mount; the widget file itself will show).

- [ ] **Step 2: Delete the files**

```bash
rm lib/features/social/presentation/widgets/tribe_creators_strip.dart
rm test/features/social/presentation/widgets/tribe_creators_strip_test.dart
```

- [ ] **Step 3: Verify**

Run: `grep -rn "TribeCreatorsStrip" lib test --include="*.dart"`
Expected: nothing.

Run: `dart analyze lib`
Expected: 0 errors.

Run: `flutter test test/features/social/presentation/widgets`
Expected: pass (remaining widget tests untouched).

- [ ] **Step 4: Commit**

```bash
git add -u lib/features/social/presentation/widgets test/features/social/presentation/widgets
git commit -m "refactor(social): delete TribeCreatorsStrip widget + test"
```

---

# Phase 4 — Remove the browse-all surface

## Task 4: Delete `CreatorsBrowseScreen` + the `/creators` route

**Files:**
- Delete: `lib/features/social/presentation/screens/creators_browse_screen.dart`
- Delete: `test/features/social/presentation/screens/creators_browse_screen_test.dart`
- Modify: `lib/core/router/router.dart`
- Modify (generated): `lib/core/router/router.g.dart`

- [ ] **Step 1: Verify the only entry point is the strip's "View All"**

Run: `grep -rn "push('/creators'\|go('/creators'" lib --include="*.dart" | grep -v "\.g\.dart"`
Expected: only `lib/features/social/presentation/widgets/tribe_creators_strip.dart:37` (deleted in Task 3) — i.e. nothing now. The `/creators/:id` alias and `/social/creator/:id` are **kept**; do not touch them.

- [ ] **Step 2: Delete the screen + test**

```bash
rm lib/features/social/presentation/screens/creators_browse_screen.dart
rm test/features/social/presentation/screens/creators_browse_screen_test.dart
```

- [ ] **Step 3: Remove the route**

In `lib/core/router/router.dart`:
1. Remove the `GoRoute(path: '/creators', ...)` block (lines ~373-377, `CreatorsBrowseScreen`).
2. Remove the import `package:emerge_app/features/social/presentation/screens/creators_browse_screen.dart` (line 47).

- [ ] **Step 4: Regenerate the router**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: BUILD SUCCESSFUL. `lib/core/router/router.g.dart` regenerates (folds the pre-existing hash-only WIP line — harmless).

- [ ] **Step 5: Verify**

Run: `grep -rn "CreatorsBrowseScreen\|path: '/creators'" lib --include="*.dart" | grep -v "\.g\.dart"`
Expected: nothing (the `/creators/:id` alias matches a different pattern — confirm it remains).

Run: `dart analyze lib`
Expected: 0 errors.

Run: `flutter test test/features/social/presentation/screens`
Expected: pass.

- [ ] **Step 6: Commit**

```bash
git add -u lib/core/router lib/features/social/presentation/screens test/features/social/presentation/screens
git commit -m "refactor(social): delete CreatorsBrowseScreen + /creators route (deep-link alias kept)"
```

---

# Phase 5 — Remove the seeds

## Task 5: Delete `seedCreatorsIfEmpty` + `seedCreatorBlueprintsIfEmpty` + call sites

**Files:**
- Modify: `lib/features/social/data/repositories/creator_repository.dart`
- Modify: `lib/features/blueprints/data/repositories/blueprint_repository.dart`
- Modify: `lib/core/data/seed_runner.dart`
- Modify: `lib/main.dart`

- [ ] **Step 1: Delete `seedCreatorsIfEmpty`**

In `lib/features/social/data/repositories/creator_repository.dart`: delete the method + its doc comment (lines ~70-193). Then remove the two imports that become unused (both were seed-only):
- `package:emerge_app/core/utils/app_logger.dart`
- `package:emerge_app/auth/domain/entities/user_extension.dart` (from `package:emerge_app/features/auth/domain/entities/user_extension.dart`)

Verify: `grep -n "AppLogger\|UserArchetype" lib/features/social/data/repositories/creator_repository.dart` → nothing.

- [ ] **Step 2: Delete `seedCreatorBlueprintsIfEmpty`**

In `lib/features/blueprints/data/repositories/blueprint_repository.dart`: delete the method + its doc comment (lines ~405-660). Keep everything else — `FieldValue` (used at line 37) and `AppLogger` (used at lines 48/51/68/377) stay. Do not touch `seedBlueprintsIfEmpty` or the `isCreatorBlueprint` field/flow.

- [ ] **Step 3: Delete the `seed_runner.dart` wrappers**

In `lib/core/data/seed_runner.dart`: delete `seedCreators` (lines ~123-130) + `seedCreatorBlueprints` (lines ~132-139) and the now-unused import `package:emerge_app/features/social/data/repositories/creator_repository.dart` (line 4).

- [ ] **Step 4: Remove the `main.dart` call sites**

In `lib/main.dart`, delete the two lines (lines 175-176):

```dart
            unawaited(seedCreators());
            unawaited(seedCreatorBlueprints());
```

Keep `seedOfficialClubs()`, `seedChallenges()`, `seedBlueprints()`.

- [ ] **Step 5: Verify no references remain**

Run: `grep -rn "seedCreatorsIfEmpty\|seedCreatorBlueprintsIfEmpty\|seedCreators\|seedCreatorBlueprints" lib --include="*.dart"`
Expected: nothing.

Run: `dart analyze lib`
Expected: 0 errors (watch for unused-import errors — Step 1 must have removed them).

Run: `flutter test test/features/social test/features/blueprints`
Expected: pass (no test referenced the seeds).

- [ ] **Step 6: Commit**

```bash
git add lib/main.dart lib/core/data/seed_runner.dart lib/features/social/data/repositories/creator_repository.dart lib/features/blueprints/data/repositories/blueprint_repository.dart
git commit -m "refactor(seeds): remove fake creator + creator-blueprint seeding (real creators only)"
```

---

# Phase 6 — Verification

## Task 6: Final verification sweep

- [ ] **Step 1: Full static analysis**

Run: `dart analyze lib test`
Expected: 0 issues. Compare against the pre-flight baseline — only SP-D-introduced issues are in scope.

- [ ] **Step 2: Deletion greps (all must be empty)**

```bash
grep -rn "TribeCreatorsStrip" lib test --include="*.dart"
grep -rn "CreatorsBrowseScreen" lib test --include="*.dart"
grep -rn "seedCreatorsIfEmpty\|seedCreatorBlueprintsIfEmpty" lib --include="*.dart"
grep -n "BROWSE BLUEPRINTS" lib --include="*.dart"
```

- [ ] **Step 3: Route audit**

Run: `grep -n "creators" lib/core/router/router.dart`
Expected: exactly two surviving creator routes — `path: '/creators/:id'` (alias → `CreatorProfileScreen`) and `path: 'creator/:id'` (`/social/creator/:id`). No `path: '/creators'`.

- [ ] **Step 4: Focused test sweep**

Run: `flutter test test/features/social/presentation/screens test/features/social/presentation/widgets`
Expected: all pass (do not run the full suite; the pre-existing `tribe_membership_service_test.dart` failure belongs to SP-G).

- [ ] **Step 5: Node-guide copy audit (D4)**

Read `lib/features/tutorials/domain/node_guide_registry.dart` entries `tribe_lobby` (lines ~547-568) and `all_tribes` (lines ~528-545). Expected: no edits — "Switch tribes — Use the bottom button to browse and switch tribes." now matches the real CTA; `all_tribes` "Switch freely" is unaffected; the `discover` node stays untouched (dies in SP-F).

- [ ] **Step 6: Hand off to coordinator**

Report:
- Done: split screen, CTA, strip/browse/seed removals, tests updated, analyze clean.
- Deferred (SP-H): admin deletion of the 12 seeded Firestore docs (`creator_aria_chen`, `creator_marcus_okafor`, `creator_sora_tanaka`, `creator_julian_cross`, `creator_naia_singh`, `creator_elias_vance`; `cb_aria_deep_work`, `cb_marcus_morning`, `cb_sora_creative`, `cb_julian_calm`, `cb_naia_devotion`, `cb_elias_studio`) and the `purgeOrphanedUserData.ts` `creator_` skip-list update.
- Interim note: until SP-H deletes the docs, `verifiedCreatorsStreamProvider` still emits the 6 fake profiles, so the new All Tribes CREATORS section may render them — accepted (see spec §5).

- [ ] **Step 7: Commit any fix-ups (optional)**

If the sweep surfaced a fix, commit it with a `fix(social): …` message naming only the touched files; otherwise no commit in this task.
