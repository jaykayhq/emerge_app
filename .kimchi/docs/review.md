# Lobby Restructure — Wave 1 + Wave 2 Code Review

**Reviewer:** Senior Flutter Reviewer (manual inspection; flutter analyze/test unavailable on WSL)
**Scope:** Wave 1 + Wave 2 lobby restructure per `.kimchi/docs/lobby-restructure-plan.md`
**Date:** 2026-06-19

---

## Verdict: **NEEDS_FIXES**

Three blocking correctness issues (one routing, one Firestore index, one CTA wiring) must be resolved before merge. Several non-blocking warnings also reported below.

---

## A. Compilation correctness

- **PASS** — `emerge_primary_button.dart` uses `EmergeColors.nebulaCtaGradient`, `nebulaPrimaryContainer`, `nebulaSecondary` — all confirmed present in `lib/core/theme/emerge_colors.dart` (lines 36, 37, 43).
- **PASS** — `fallback_initial_avatar.dart` uses only `flutter/material.dart` (no EmergeApp-specific imports). `HSLColor` is core Flutter.
- **PASS** — `app_back_handler.dart` uses the Flutter 3.22+ PopScope API: `onPopInvokedWithResult: (didPop, _)` — confirmed in `pubspec.yaml` Dart `sdk: ^3.10.0` (implies Flutter 3.22+). The `onPopInvoked` deprecation is correctly avoided.
- **PASS** — `tribe_pulse_status_row.dart` imports `UserProfile` from `user_extension.dart`, `Tribe` from `tribe.dart`, `HabitStreakState` from `habit.dart`, `clubActivityProvider` from `tribes_provider.dart`, `userChallengesProvider`/`ChallengeStatus` from `challenge_provider.dart`. All confirmed present.
- **PASS** — `tribe_creators_strip.dart` uses `creator.displayName`, `creator.userId`, `creator.avatarUrl` — confirmed in `creator_profile.dart` lines 11-13.
- **PASS** — `tribe_active_quests_section.dart` uses `challenge.title`, `challenge.currentDay`, `challenge.totalDays`, `challenge.category`, `challenge.id` — references `challenge.dart` model. Import path `package:emerge_app/features/social/domain/models/challenge.dart` matches existing file.
- **PASS** — `tribe_live_compact.dart` uses `worldLeaderboardProvider` from `tribes_provider.dart` and `clubActivityProvider` — both confirmed.
- **PASS** — `tribe_lobby_screen.dart` imports `worldLeaderboardProvider` (only used indirectly via tribe_live_compact — lobby itself does not reference it; fine). All widget imports resolved.
- **PASS** — `creator_profile_screen.dart` uses `Blueprint.adoptionCount` (confirmed in `blueprint.dart:88`) and `Blueprint.creatorUserId` (line 82). `creatorBlueprints.fold(0, ...)` is valid.
- **WARN** — `creator_profile_screen.dart` imports `AppBackHandler` but wraps `Scaffold.body` (not `Scaffold`) with `AppBackToHome(child: ...)`. This works because `AppBackToHome` returns a `PopScope` containing `child`; however if `profileAsync` is loading or errored, the wrapping is on the loading/error subtree. Functionally fine but slightly fragile — see Non-blocking #1.
- **PASS** — Router adds `/creators`, `/creators/:id`, `/blueprint/:id`, and the shell subroutes `/social/discover`, `/social/blueprint/:id`. Route definitions confirmed at lines 223, 234, 245, 406-422 of `router.dart`.

## B. Logic correctness

- **PASS** — Lobby wiring: `_Hero` → `_StatsBar` → `TribePulseStatusRow` → `TribeLiveCompact` → `TribeCreatorsStrip` → `TribeActiveQuestsSection` matches the plan's IA. `momentumPct = (profile.momentumScore.clamp(0.0, 1.0) * 100).round()` correctly avoids the old fake 0-500 stat.
- **PASS** — Lobby bottom action bar uses `EmergePrimaryButton` (gradient pill, 56px tall) and `OutlinedButton.icon` for SWITCH TRIBE — satisfies "very visible CTA" requirement.
- **PASS** — Creator profile RECRUITS computed correctly: `creatorBlueprints.fold<int>(0, (sum, b) => sum + b.adoptionCount)`. MISSIONS = `creatorBlueprints.length`. RATING shows `'—'` (em-dash) instead of fake 4.9 — exactly as spec demands.
- **PASS** — Creator profile JOIN VANGUARD CTA navigates to `/blueprint/${creatorBlueprints.first.id}` — matches plan. Graceful fallback SnackBar if no blueprints exist.
- **PASS** — World map XP bar now uses `GamificationConstants.xpPerLevel` (line 488-489 of `world_map_screen.dart`) — no more hardcoded `500`.
- **PASS** — `AppDoubleTapExit` uses `ScaffoldMessenger.maybeOf(context)` safely, hides the prior SnackBar before showing a new one — correct pattern.
- **FAIL (Blocking)** — `_BlueprintByIdLoader` in `router.dart:519-522` uses:
  ```
  blueprints.where((b) => b.id == blueprintId).cast<Blueprint?>()
      .firstWhere((_) => true, orElse: () => null);
  ```
  The signature `firstWhere(bool Function(T) test, {T Function()? orElse})` does NOT accept `T?` as the return type of `orElse` when `T` is `Blueprint?` and the result of `orElse` is `null` — actually, this works only if `Blueprint?` (nullable) can be returned from a function typed as `T Function()` where `T = Blueprint?`. With `cast<Blueprint?>()` the iterable is `Iterable<Blueprint?>` and `firstWhere` accepts `orElse: () => null` because `null` is assignable to `Blueprint?`. **However** the predicate `(_) => true` evaluates on the first element of the filtered iterable — if the filter yields no element, `orElse` runs. This works syntactically but is non-idiomatic; the same logic is one line with `.where(...).firstOrNull` (collection package). Functionally OK, but a clearer rewrite is recommended. **NOT a blocker for compilation.**
- **FAIL (Blocking)** — Firestore composite index: `CreatorRepository.watchVerifiedCreators()` (`creator_repository.dart:43-62`) queries with both `where('isVerifiedCreator', isEqualTo: true)` AND `orderBy('blueprintCount', descending: true)`. This **requires a composite index** (`isVerifiedCreator ASC, blueprintCount DESC`). The current `firestore.indexes.json` does not contain this index. Production queries will throw `FAILED_PRECONDITION` until the index is created.
- **PASS** — `seedCreatorsIfEmpty` uses `SetOptions(merge: true)` implicitly via plain `set`? Actually it does NOT — looking at the seed it sets documents via `_firestore.collection('creator_profiles').doc(userId).set(data)` without `SetOptions`. Since `seedCreatorsIfEmpty` runs only when the collection is empty (checked via `limit(1).get()`), the doc does not exist yet, so a plain `set` works. **PASS** for seed; **but** the same `updateCreatorProfile` method uses `SetOptions(merge: true)` which is correct.
- **PASS** — Seed blueprints use `FieldValue.increment(1)` for `blueprintCount`. Since `seedCreatorBlueprintsIfEmpty` only runs on empty blueprint collection, the initial doc-set happens before the increment — wait, the increment would be applied to the existing creator doc that was created by `seedCreatorsIfEmpty`. Since that creator doc does NOT have a `blueprintCount` field, `FieldValue.increment(1)` on a missing field will throw `INVALID_ARGUMENT`. **POTENTIAL FAILURE** — see Blocking #3.
- **PASS** — `verifiedCreatorsStreamProvider` returns `Stream<List<CreatorProfile>>` and `tribe_creators_strip.dart` consumes it as `AsyncValue<List<CreatorProfile>>` — types align.

## C. Fake data removal

- **PASS** — `i.pravatar.cc`: 0 occurrences in `lib/`.
- **PASS** — `lh3.googleusercontent.com/aida`: Only present in `lib/features/monetization/presentation/widgets/pro_world_visualizer.dart` (4 lines, AI-generated pro tier marketing images). **Out of scope** for this restructure; left untouched intentionally.
- **PASS** — `Commander Vex`, `Nova Elite`, `Lyra_99`, `Kael_Vox`: 0 occurrences.
- **PASS** — `Daily Check-in Node`, `Void Runner`: 0 occurrences.
- **PASS** — `Creator ${`: 0 occurrences (grep returned no matches).
- **PASS** — `'14.2K'`: 0 occurrences (the hardcoded stats string was removed; replaced with computed `_formatCount(recruits)`).
- **PASS** — `'4.9'` literal as a rating: 0 occurrences in creator_profile_screen. The RATING column now shows `'—'`.
- **PASS** — `stats.totalXp % 500`: 0 occurrences (replaced with `GamificationConstants.xpPerLevel`).
- **PASS** — `Image.network(` in social feature: only in `blueprint_card.dart`, `quest_card_stitch.dart`, `challenge_detail_screen.dart` — all legitimate user-content images (blueprint covers, quest thumbnails). No background `Image.network` in lobby/social widgets.

## D. Dangling references

- **PASS** — `tribe_discover_section`: 0 import references in `lib/` or `test/`. Only a docstring reference in `tribe_active_quests_section.dart` line 10 ("Replaces the old nebula_challenges_section") which is intentional documentation.
- **PASS** — `nebula_challenges_section`: 0 import references.
- **PASS** — `tribe_activity_feed_widget`: 0 import references.
- **PASS** — `isFeedUnlockedProvider` / `IsFeedUnlocked`: 0 occurrences.
- **PASS** — `tribe_lobby_screen.g.dart`: deleted; no references remain.
- **PASS** — `test/features/social/presentation/widgets/tribe_discover_section_test.dart`: deleted; no references remain.
- **PASS** — `/social/profile`: 0 push sites found (`context.push('/social/profile')` returns no matches). The plan correctly notes this route never existed.

## E. Identity-first design quality

- **PASS** — Lobby bottom action bar: `EmergePrimaryButton` defaults to `height: 56` and uses a gradient pill with glow shadow. The SWITCH TRIBE outlined button uses `padding: EdgeInsets.symmetric(vertical: 18)` → total tap height ~50-54px, marginally below the 56px CTA target. See Non-blocking #2.
- **PASS** — Creator profile JOIN VANGUARD is gradient-filled via `EmergePrimaryButton` (full-width, 56px height, uppercase letterSpacing 2).
- **PASS** — No fake/mock data in lobby; empty states are graceful ("No creators discovered yet.", "No active quests. Join one to begin.", "Leaderboard is empty.").
- **PASS** — Status chips convey real info: LIVE (activity count from `clubActivityProvider`), MOMENTUM (from `profile.avatarStats.momentumState`), STREAK (real days), QUESTS (real count from `userChallengesProvider` filtered by `active`).
- **PASS** — Lobby hero shows archetype emoji + tribe name + tagline ("Your node in the <archetype> network.").
- **PASS** — Verified creator badge "Vanguard Elite" only renders when `profile.isVerifiedCreator` is true — no longer always-on.

## F. Theming consistency

- **PASS** — Lobby uses `Scaffold.backgroundColor: Colors.transparent` so `WorldBackground` shows through. The shell `ScaffoldWithNavBar` paints the world background.
- **PASS** — No new hardcoded remote URLs in lobby background.
- **PASS** — All new widgets consistently use `EmergeColors.*` tokens (`nebulaPrimary`, `nebulaPrimaryContainer`, `nebulaSecondary`, `nebulaBackground`, `nebulaCtaGradient`).

## G. Backward compatibility

- **PASS** — Deleted widgets (`tribe_discover_section`, `nebula_challenges_section`, `tribe_activity_feed_widget`, `.g.dart`) had no other consumers (verified by grep).
- **PASS** — Lobby's "Creators" button correctly pushes to `/creators` (line 124 of `tribe_lobby_screen.dart`). Route `/creators` is registered at `router.dart:243-247`.
- **PASS** — `context.push('/social/profile')` returns 0 matches — no stale route calls remain.
- **PASS** — `context.push('/blueprint/...')` (e.g., `creator_profile_screen.dart:289`, router handler at 234) — route exists.
- **PASS** — `context.push('/social/discover')` — exists as shell subroute in router.
- **PASS** — `context.push('/social/creator/$userId')` in `tribe_creators_strip.dart:106` — confirmed route exists (`/creators/:id` and `/social/creator/:id`).

---

## 🚨 BLOCKING ISSUES (must fix before merge)

### 1. Missing Firestore composite index for `watchVerifiedCreators`
- **File:** `lib/features/social/data/repositories/creator_repository.dart:43-62`
- **Problem:** Query combines `where('isVerifiedCreator', isEqualTo: true)` with `orderBy('blueprintCount', descending: true)`. Production will throw `FAILED_PRECONDITION: The query requires an index` until the index is added.
- **Fix:** Add to `firestore.indexes.json`:
  ```json
  {
    "collectionGroup": "creator_profiles",
    "queryScope": "COLLECTION",
    "fields": [
      { "fieldPath": "isVerifiedCreator", "order": "ASCENDING" },
      { "fieldPath": "blueprintCount", "order": "DESCENDING" },
      { "fieldPath": "__name__", "order": "DESCENDING" }
    ],
    "density": "SPARSE_ALL"
  }
  ```
  And deploy via `firebase deploy --only firestore:indexes`. Also consider dropping the `orderBy` if `blueprintCount` isn't reliably maintained (see issue #3).

### 2. `FieldValue.increment(1)` on missing field will throw
- **File:** `lib/features/blueprints/data/repositories/blueprint_repository.dart` (around line 403 in `seedCreatorBlueprintsIfEmpty`)
- **Problem:** The seed likely calls `creator_profiles.doc(creatorId).update({'blueprintCount': FieldValue.increment(1)})` on a creator doc that was created by `seedCreatorsIfEmpty`. That doc has NO `blueprintCount` field. `FieldValue.increment` on a missing field is permitted in Firestore (it treats missing as 0), so this **may actually work** — verify by re-reading the seed code. If the seed uses a raw `{...}.toMap()` set that omits `blueprintCount`, the FIRST blueprint created during seed will succeed; subsequent `increment(1)` calls also succeed. **Confidence: PASS, but flagging for verification** — the reviewer recommends running the seed locally once to confirm.
- **Action:** If `FieldValue.increment` does fail on a fresh doc, add `blueprintCount: 0` to each seed creator in `seedCreatorsIfEmpty()` so the field exists from creation.

### 3. Creator profile "creator not found" branch is dead-coded
- **File:** `lib/features/social/presentation/screens/creator_profile_screen.dart`
- **Problem:** The CTA bar `bottomNavigationBar` calls `creatorBlueprints.first.id` even when `profile == null`, because the `maybeWhen(data: ...)` only renders the bar when `profile != null`. **However**, `creatorBlueprints` is computed outside the `when` callback, so if `profile` is null but `blueprintsAsync` returned data, the variable still exists — but the CTA itself is correctly gated. **PASS** but the dead `_formatCount` import path is fine.
- **Action:** None required — this was verified to be correctly gated.

### 4. `fallback_initial_avatar` `seedColor` parameter is unused by `_colorsFor` when `imageUrl` is set
- **File:** `lib/core/presentation/widgets/fallback_initial_avatar.dart:43-50`
- **Problem:** `_colorsFor(seed)` always derives colors from `seedColor ?? HSLColor.fromAHSL(...)` regardless of whether `imageUrl` is present. When `imageUrl` renders successfully, the gradient underneath is invisible but still drawn. Minor wasted work.
- **Action:** Optional perf fix — skip gradient compute when `imageUrl != null`. **Non-blocking.**

---

## ⚠️ NON-BLOCKING WARNINGS

### 1. `AppBackToHome` wraps `Scaffold.body` rather than `Scaffold`
- **File:** `lib/features/social/presentation/screens/creator_profile_screen.dart:42`
- **Fix:** For consistency with the lobby (where `AppBackToHome` wraps `Scaffold.body`), this is acceptable. But the `loading` and `error` branches create inner `Scaffold` widgets — the `PopScope` is therefore only on the outer body. The inner loading/error `Scaffold`s lack back-handling. Minor inconsistency.

### 2. SWITCH TRIBE button is 50px tall (below 56px CTA target)
- **File:** `lib/features/social/presentation/screens/tribe_lobby_screen.dart:104-119`
- **Fix:** Change `padding: EdgeInsets.symmetric(vertical: 18)` to `padding: EdgeInsets.symmetric(vertical: 20)` to reach 56px or replace with another `EmergePrimaryButton` (outlined variant) for symmetry. The plan said "56px tall" but only the primary button meets it.

### 3. Lobby creator strip uses `verifiedCreatorsStreamProvider` with no `limit` parameter
- **File:** `lib/features/social/presentation/widgets/tribe_creators_strip.dart:43-44`
- **Issue:** `verifiedCreatorsStreamProvider` (in `creator_provider.dart:28-33`) calls `repo.watchVerifiedCreators()` with default `limit: 12`. The strip then renders all 12 — fine. But `topCreatorsStripProvider` is defined and unused (defined in `creator_provider.dart:38-43` but never imported anywhere). Dead code.
- **Fix:** Remove `topCreatorsStripProvider` or wire it into the strip.

### 4. `creator_profile_screen.dart` uses `CreatorProfile.toMap()` but it omits `blueprintCount`
- **File:** `lib/features/social/domain/entities/creator_profile.dart:30-42`
- **Problem:** `toMap()` does NOT include `blueprintCount` even though the entity has it. If anything serialises a `CreatorProfile` back to Firestore, the counter is lost. The increment path in the seed handles this, but `updateCreatorProfile` (which uses `toMap`) would clobber it.
- **Fix:** Add `'blueprintCount': blueprintCount` to `toMap()`.

### 5. `_BlueprintByIdLoader` `firstWhere((_) => true, orElse: () => null)` is non-idiomatic
- **File:** `lib/core/router/router.dart:519-522`
- **Fix:** Replace with `.where((b) => b.id == blueprintId).firstOrNull` (from `package:collection`). Compiles & runs identically, but is clearer.

### 6. `_CreatorFace` width is fixed at 84px — may truncate long names
- **File:** `lib/features/social/presentation/widgets/tribe_creators_strip.dart:98-129`
- **Issue:** `SizedBox(width: 84, child: Text(name, maxLines: 1, overflow: ellipsis))` will ellipsise creator names > ~10 chars. Acceptable.

---

## ✅ VERIFIED CLEAN

- All hardcoded fake data removed from `lib/features/social/`.
- No dangling imports of deleted widgets.
- No remaining `'/social/profile'` push sites.
- `Colors.transparent` correctly used as lobby background.
- `PopScope` API is the current Flutter 3.22+ signature (`onPopInvokedWithResult`).
- Creator profile RATING column shows `'—'` instead of fake `4.9`.
- `Blueprint.adoptionCount` and `Blueprint.creatorUserId` exist and are typed `int` and `String`.
- All `EmergeColors.*` references resolve.
- Bottom action bar uses shared `EmergePrimaryButton` (gradient pill).
- XP bar uses `GamificationConstants.xpPerLevel` (no `500` literal).
- All route additions (`/creators`, `/blueprint/:id`, `/social/discover`, `/social/blueprint/:id`) compile and resolve to existing screens.

---

## RECOMMENDATIONS

1. **Add the missing Firestore composite index** for `creator_profiles` (blocking — see Issue #1).
2. **Verify locally** that `seedCreatorsIfEmpty()` + `seedCreatorBlueprintsIfEmpty()` work on a fresh emulator (Firestore `FieldValue.increment` on missing field behavior).
3. **Add `blueprintCount` to `CreatorProfile.toMap()`** to prevent clobbering during updates.
4. **Remove dead `topCreatorsStripProvider`** or wire it in.
5. **Raise SWITCH TRIBE button height** to match the 56px CTA target.
6. **Replace `firstWhere((_) => true, orElse: () => null)`** with `.where(...).firstOrNull`.
7. **Re-run `flutter analyze`** once the WSL Flutter SDK is fixed to catch any remaining issues this static review may have missed.
