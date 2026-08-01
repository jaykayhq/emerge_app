# SP-G: Tribe Membership & XP Accounting Fixes — Design Spec

**Date:** 2026-08-01
**Status:** Design — ready for implementation
**Plan:** `docs/superpowers/plans/2026-08-01-sp-g-tribe-membership-xp-plan.md`
**Audit source:** SP-G audit (bugs B1–B15), re-verified line-by-line against the current working tree on 2026-08-01. Where the audit's path/line citations had drifted from the working tree (SP-A + other WIP touched several files), this spec cites the **verified** locations.

---

## 1. Goals

Fix the tribe membership and XP **accounting** defects found in the SP-G audit. Concretely:

1. **A user joins a tribe exactly once** (memberCount +1, one membership doc, one contributor doc) — no double joins from the two onboarding paths (B1), no duplicate joins after reinstall (B2).
2. **Leaving a tribe** decrements `memberCount`/`members` exactly once, preserves all earned XP/history (D2, user-confirmed), and no longer attempts rule-denied client writes (B3).
3. **Rejoining a tribe** never wipes previously contributed totals (B11).
4. **XP accounting is symmetric per channel**: whatever a completion credits to `user_stats` / `tribes` / `contributors` / `club_leaderboards`, the undo debits the exact same amount (B5, B6, B12).
5. **Challenge XP flows everywhere it should**: into Firestore `user_stats.avatarStats.totalXp`, into the leaderboard, and (via the server recalc) into tribe totals (B5, B9).
6. **One leaderboard entry per user per tribe** — the tribe the user is actually a member of, not their archetype's default club (B7, B8, B14).
7. **Stale roster entries are filtered from UI** after a user leaves (B10), without deleting history (D2).
8. **Server-authoritative tribe totals**: the client stops writing `tribes.totalXp` / `totalHabitsCompleted` / `totalChallengesCompleted` (they are recalc-only), and the daily recalc is extended to **all** tribes with explicit membership docs, aggregating XP per member directly from `user_stats` (B3, B4).
9. **Rules harden `memberCount`/`members` updates** with diff/value validation (B13). XP spoofing via `user_stats` is **flagged**, not fixed, in this sub-project (D11 → SP-H).

## 2. Verified audit recap (what the code actually does today)

### 2.1 Join paths (two)

**Path A — `joinTribe` (transactional)**: `lib/features/social/domain/services/tribe_membership_service.dart:29-99`
- Drift-only membership guard `watchActiveMembership` (`:36-39`).
- Firestore `runTransaction`: `tribes/{id}` `memberCount = current + 1` + `members arrayUnion` + `lastStatsSync` (`:48-53`); `users/{uid}/tribes/{tribeId}` membership doc set with `membershipType`/`isActive` (`:56-64`); `tribes/{tribeId}/contributors/{uid}` **SET (no merge) with zeroed totals** (`:67-76`).
- Drift `deactivateAll` + membership upsert (`:80-87`).

**Path B — `joinClub` (Drift + enqueued sync)**: `lib/core/drift_repositories/drift_tribe_repository.dart:392-445`
- Local `incrementMemberCount(+1)` (`:395`) + membership upsert (`:396-402`).
- Sync engine enqueues: `users/{uid}/tribes` set (`:407-414`), `tribes/{tribeId}/contributors/{uid}` **set with zeros** (`:417-427`), `tribes/{id}` merge-set `memberCount` increment +1 + `arrayUnion` (`:432-444`).
- **No membership check at all.**

**Legacy/other join call sites:** `club_screen.dart:53` (`joinTribe`), `onboarding_state_notifier.dart:427` (`joinClub`), legacy `onboarding_provider.dart:184` (`joinClub`, guarded by `joinedClubId`), `tribe_discovery_screen.dart:226` (`joinTribe`), and a second `FirestoreTribeRepository` implementation (`lib/features/social/data/repositories/tribe_repository.dart:169-216` joinClub via batch) used by legacy paths.

### 2.2 Leave path

`tribe_membership_service.dart:101-140` — transaction: `memberCount = (current-1).clamp(0,999999)` (`:116-120`), `members arrayRemove` (`:119`), delete `users/{uid}/tribes/{tribeId}` (`:123-125`); Drift `deactivateAll` (`:129`). Legacy `leaveClub` at `drift_tribe_repository.dart:447-475`.

**Leave does NOT touch:** `contributors/{uid}` (rules forbid delete), `club_leaderboards/{uid}_{clubId}` (rules `allow delete: if false`), tribe `totalXp`/`totalHabitsCompleted` (no decrement), `user_stats` XP (correct — preserved), no Cloud Function.

After leave, `tribe_card.dart:217` calls `statsService.syncTribeStats(tribe.id)` — **always denied** by rules (B3); same on join (`:229`).

### 2.3 XP fields (verified against rules + writers)

- `user_stats.avatarStats.{totalXp, strengthXp..spiritXp, challengeXp, level}` — GLOBAL XP = `avatarStats.totalXp` (there are no `globalXp`/`tribeXp` fields anywhere).
- `tribes.{totalXp, totalHabitsCompleted, totalChallengesCompleted, memberCount, members}`.
- `club_leaderboards.{xp, level, clubId, userId}`.
- `contributors.{totalXpContributed, totalHabitsCompleted, contributionCount}`.

### 2.4 Client-side writers (sync engine — all merge-sets, see `lib/core/sync/sync_engine.dart:188-218`)

- `drift_habit_repository.dart:494-512` — `user_stats` `avatarStats.totalXp` increment = `result.xpGained` **only** (B5: challenge XP computed at `:348-353` and added to Drift at `:382-389` is never pushed).
- `drift_habit_repository.dart:516-541` — `tribes.totalXp` increment = `result.xpGained` only (challenge XP missing); `contributors.totalXpContributed` increment (same).
- Undo path `drift_habit_repository.dart:222-344` — `xpToUndo = last.xpGained + last.challengeXp` (`:245`); tribe debit `-xpToUndo` (`:308`) while the credit was `+result.xpGained` — asymmetric (B6); **no `user_stats` decrement enqueued at all** (B12).
- `club_activity_service.dart` — activity feed + `updateUserScore` keyed by **archetype club** `_getClubIdForArchetype` (`:79-95`), not the active tribe (B8). `logHabitCompletion` writes a leaderboard **increment** (`:183-197`); `logLevelUp` writes an **absolute** `totalXp` with `isIncrement: false` (`:271-283`) — double-count (B7). `logChallengeComplete` (`:289-382`) has **zero callers** (B9). `logLevelUp` callers: `tribe_loop_service.dart:58`, `user_stats_providers.dart:387`.
- `drift_leaderboard_repository.dart:129-201` — writes `clubId` field; `watchClubLeaderboard` (`:23-119`) queries remote by `clubId` (correct); **`firestore_drift_syncer.dart:26-29` queries `club_leaderboards` by `tribeId`** — remote rows never reach Drift (B14). Syncer path: `lib/features/social/domain/services/firestore_drift_syncer.dart`.
- `tribe_stats_service.dart:236-254` — `syncTribeStats` writes `memberCount/totalXp/habits/challenges` — denied by rules (B3). Actual path: `lib/features/social/data/services/tribe_stats_service.dart`. Its read helpers (`getTribeStats` etc., `:130-230`) have **no other callers**.

### 2.5 Server-side

- `functions/src/recalcTribes.ts:16-164` (scheduled 3AM, `functions/src/index.ts:249-252`) — the only writer of tribe totals. 6 hardcoded official clubs (`clubMap` `:3-10`); member lists built from archetype map (`:30-46`) with explicit-membership override applied **only to archetype-mapped users** (`:69-74`); XP aggregated **by archetype bucket** (`:84-105`); habits/challenges from `global_activities.clubId` (`:107-132`); single non-transactional batch (`:134-163`).
- `functions/src/cleanupUserData.ts:64` — `deleteMyAccount` deletes `club_leaderboards` by `userId`, but **not** `tribes/{id}/contributors/{uid}` (recursive deletes cover `users/{uid}`, `user_stats/{uid}`, `pulse_feed_cards/{uid}` only).
- `functions/src/challenges.ts:9-36` — `onChallengeMembershipChanged` adjusts `challenges/{id}.participants` ±1.

### 2.6 Rules (`firestore.rules`, verified)

- `user_stats` owner create/update with `isValidStats` only (`:267-273`) — type checks, **no value bounds** → XP spoofing (D11 flag).
- `users/{uid}/tribes` full owner read/write (`:298-300`).
- `tribes` update: `isValidTribe` + (`createdBy == uid` | `isAdmin()` | diff keys `hasOnly(['memberCount','members','lastStatsSync'])`) (`:361-372`) — **any authenticated user may change memberCount/members with no value validation** (B13). `tribes` create: `isValidTribe` — permits `type: 'official'/'brand'` (`:363`, `:74`).
- `contributors`: create if `memberId == uid`; update owner with restricted keys (includes `leftAt` — `:384`); **no delete** (`:376-386`).
- `club_leaderboards`: create/update if entry id starts with uid or `userId == uid`; **delete false** (`:419-427`).

### 2.7 Pre-existing failure owned by SP-G

`test/features/social/domain/services/tribe_membership_service_test.dart` — "joinTribe enqueues Firestore sync operations" fails at HEAD (confirmed by SP-A handoff): the test asserts sync-queue ops that the current transactional `joinTribe` never enqueues. Fixed in T3.

---

## 3. Recorded decisions (D1–D11)

### D1 — B1/B2: single join, guarded at the source

**Decision:** Fix at the join methods themselves (both paths), not by rewiring onboarding UI:

- `joinClub` (`drift_tribe_repository.dart:392`) gains an **early-return guard**: if the user already has an active Drift membership **or** a Firestore `users/{uid}/tribes/{tribeId}` doc exists → return without any mutation or enqueue. The Firestore check matters for the reinstall case (empty Drift, existing Firestore membership) — the Drift-only check in `joinTribe` is exactly B2.
- `joinTribe` (`tribe_membership_service.dart:36`) gains a **Firestore-side membership check** before the transaction: `users/{uid}/tribes` non-empty → `Left(AlreadyInTribe)` (same semantic as the existing Drift guard; leave deletes the doc so rejoin works).
- **Increments stay increments.** The enqueued `memberCount: increment +1` does NOT become a SET from a local snapshot — multi-device correctness requires server-side increments; the guard is the fix, not the write shape.
- Onboarding dedupe: `completeOnboarding` (`onboarding_state_notifier.dart:427`) does not need changes once `joinClub` guards — the `club_screen` `joinTribe` (which writes the Firestore membership doc) is caught by the `joinClub` Firestore check.

### D2 — B10-adjacent: leave semantics — **CONFIRM-WITH-USER → RESOLVED 2026-08-01: "Keep everything"**

> This was a genuine product fork; the user was asked and chose the RECOMMENDED option.

**RECOMMENDED (chosen):** leaving preserves everything earned:
- `user_stats` XP untouched (already true).
- Tribe totals unchanged — contributions are history.
- Contributor doc **kept** (history; rules already forbid delete; optional future `leftAt` soft-delete needs no rules change — `leftAt` is already an allowed update key, `firestore.rules:384`).
- Leaderboard entry **kept** — historical ranking is honest.
- **Fix the leave-dialog copy** at `tribe_card.dart:195-198` ("You will lose your streak progress, accountability partners, and tribe contributions." → "your contributions stay on the tribe's record").
- Stale-visibility problem solved in the UI by filtering against the `members` array (D8).

**ALTERNATIVE (documented, not chosen):** clean break — delete contributor + leaderboard entries on leave via a server-side callable plus a rules change (delete allowed). Larger, loses history, needs a backfill purge for past leavers. Rejected by the user.

### D3 — B11: rejoin never wipes contributions

- `joinTribe` transaction (`tribe_membership_service.dart:67-76`): read the contributor doc inside the transaction; **if it exists → merge-set only `userId`/`joinedAt` (no zero-totals keys, so existing totals survive); if absent → create with zeros**.
- `joinClub` (`drift_tribe_repository.dart:417-427`): remove the zero-total keys from the enqueued contributor payload (the sync engine applies merge-sets, `sync_engine.dart:200` — explicit `totalXpContributed: 0` in a merge-set **does** overwrite, so omitting them preserves existing totals; a fresh doc is created without totals, which UI reads as 0). **Explicit-zeros are the bug; omission is the fix.**

### D4 — B3: client stops writing tribe totals

- Remove/disable the `tribes` `totalXp`/`totalHabitsCompleted`/`totalChallengesCompleted` sync enqueues:
  - completion path `drift_habit_repository.dart:516-524`;
  - undo path tribe debit `drift_habit_repository.dart:303-315` (this also removes the asymmetric tribe debit that B6 flagged — tribe totals become recalc-only).
- Remove `TribeStatsService.syncTribeStats` (`tribe_stats_service.dart:236-254`) and its two calls in `tribe_card.dart:217,229`.
- **Display side:** `cachedTribeStatsProvider` (`lib/features/social/presentation/providers/cached_tribe_stats_provider.dart:39-73`) and `_mergeTribeData` (`drift_tribe_repository.dart:679-692`) merge local Drift vs remote with `max()` for XP/habits/challenges. With client writes gone, local values can be stale/inflated forever; switch these merges to **remote-preferred** (`remote ?? local`), matching `watchArchetypeClubs.emitMerged` (`:57-66`) which already prefers remote. Local Drift totals keep updating for instant UI; the recalc'd Firestore values become authoritative as soon as they arrive.
- The daily recalc remains the **single server-authoritative writer** of tribe totals (D10). This kills the dead-lettering caused by denied `tribes.totalXp` updates (`sync_engine.dart:102-153`).
- Tribe totals displayed on the client now naturally include challenge XP: after D5, `user_stats.avatarStats.totalXp` includes challenge XP, and D10 derives tribe totals from `user_stats.totalXp`.

### D5 — B5/B9: challenge XP reaches user_stats and leaderboards

- `completeHabit` (`drift_habit_repository.dart:494-512`): the `user_stats` enqueue increments `avatarStats.totalXp` **and** `avatarStats.{attr}Xp` by `result.xpGained + challengeXpEarned` (matching the local Drift credit at `:382-389`). Single write shape shared with the undo (D6) via one payload builder.
- Challenge-completion path `drift_challenge_repository.dart:68-122` (`updateProgress`, reward block `:92-105`): on `result.isCompleted && result.xpReward != null`:
  - enqueue the same `user_stats` `avatarStats.totalXp` + `avatarStats.vitalityXp` increment for `result.xpReward` (currently only Drift is credited — Firestore never learns about it);
  - call `SocialActivityService.logChallengeComplete` (currently zero callers) with the user's active tribe as `clubId` (resolved locally via `_db.tribeMembershipDao.watchActiveMembership` — offline-safe), so challenge XP reaches the activity feed and the leaderboard increment.
- Requires injecting `SocialActivityService` into `DriftChallengeRepository` (constructor: `db, engine, syncEngine, socialService`) and updating `challengeRepositoryProvider` (`lib/features/social/presentation/providers/challenge_provider.dart:16-22`) — `socialActivityServiceProvider` lives in `tribes_provider.dart:20-42`, already imported by `challenge_provider.dart`; no cycle.
- **No double-credit risk**: `updateProgress` and `completeHabit`'s challenge handling are disjoint flows (habit-driven challenge completion credits via `challengeXpEarned`; manual progress via `updateProgress`).

### D6 — B6/B12: undo symmetry, per channel

The governing rule: **debit exactly what was credited, per channel.** Verified credit/debit table:

| Channel | Credit (completion) | Debit (undo) — today | Debit — after SP-G |
|---|---|---|---|
| Drift `user_stats` totalXp/attr | `+ (xpGained + challengeXp)` (`:382-389`) | `- (last.xpGained + last.challengeXp)` (`:253`) | unchanged (already symmetric) |
| Firestore `user_stats` totalXp/attr | `+ xpGained` today → **`+ (xpGained + challengeXp)` after D5** (`:494-512`) | **none enqueued** (B12) | **enqueue `- (last.xpGained + last.challengeXp)`** with the same payload builder |
| `tribes.totalXp` | `+ result.xpGained` (`:520`) | `- xpToUndo` includes challengeXp (B6) (`:308`) | **removed entirely** (D4 — recalc-only) |
| `contributors.totalXpContributed` | `+ result.xpGained` (`:534`) | `- xpToUndo` over-debits (B6) (`:322`) | **`- last.xpGained`** (exact credit match) |

Implementation: a pure `CompletionXpSplit`-style helper (see §5.1 / T1) computing credit and debit deltas from a completion result **or** a stored completion row, plus the shared `user_stats` payload builder. Both credit and undo paths call it — symmetry is guaranteed by construction and unit-tested (pure math, no Firebase).

### D7 — B7/B8/B14: one leaderboard entry per user per ACTIVE tribe

- **Attribution target = the user's active tribe.** `SocialActivityService` log methods (`logHabitCompletion`, `logLevelUp`, `logChallengeComplete`, `logStreakMilestone`, `logNodeClaim`, `logBadgeEarned`, `logPartnerJoined`, `logContractCommitted`) get an optional `String? clubId` parameter; when provided it replaces `_getClubIdForArchetype`. `drift_habit_repository` passes the `activeTribeId`/resolved `tribeId` it already computes (`:360`, `:434-459`). Other callers keep the archetype fallback or pass their known tribe.
- **`logLevelUp` stops writing the leaderboard** (remove the `updateUserScore(..., isIncrement: false)` absolute write at `:271-283`): the increment path from `logHabitCompletion` is the single write shape, and level is derivable from XP. Activity-feed entries stay.
- **Field alignment (B14):** leaderboard docs use `clubId` (= tribe id). Fix the syncer query `firestore_drift_syncer.dart:26-29` to `where('clubId', isEqualTo: tribeId)` and upsert `clubId` (not `tribeId`) into Drift (`:37`). `DriftLeaderboardRepository.watchClubLeaderboard` already queries by `clubId` (`:97-99`) — unchanged.
- `leaderboard_screen.dart` `_TribeLeaderboardTab` (`:142-233`) derives `clubId` from `_archetypeToClubId(profile.archetype.name)` (`:123-138`, `:157`) — switch to the active membership's tribe (watch `activeMembershipProvider`), falling back to archetype when no membership.

### D8 — B10: roster/leaderboard UI filters leavers

No deletion (D2). Filter **display** by the tribe's `members` array (which is already merged into `Tribe` objects from remote docs — `drift_tribe_repository.dart:82`, `watchUserTribes` remote docs):

- `ContributorsSection` (`lib/features/social/presentation/widgets/tribe_header_widgets.dart:255-323`) and `TribeLeaderboardSection` (`tribe_members_tab.dart:226-319`): accept the tribe's `members` list and drop entries whose `userId` is not in it. Note: `clubContributorsProvider` (`tribes_provider.dart:89-107`) reads **Drift leaderboard entries** keyed by tribeId (not the Firestore contributors subcollection) — filtering at the provider or widget level both work; widget-level with the merged `members` is simplest.
- `leaderboard_screen.dart` tribe tab: filter by the active tribe's remote `members` (via `watchUserTribes`).
- Only filter when `members` is non-empty (creator tribes without a merged `members` array must not blank the list).

### D9 — B13: rules — diff/value validation (minimal hardening)

Extend the `tribes` update branch (`firestore.rules:364-371`) for the non-creator/non-admin path: keep the key-diff restriction **and** add value consistency:

```javascript
request.resource.data.diff(resource.data).affectedKeys()
  .hasOnly(['memberCount', 'members', 'lastStatsSync']) &&
('members' in resource.data) &&
// memberCount must move by exactly ±1...
(request.resource.data.memberCount == resource.data.memberCount + 1 ||
 request.resource.data.memberCount == resource.data.memberCount - 1) &&
// ...and track the members array size delta exactly...
request.resource.data.memberCount == resource.data.memberCount +
  (request.resource.data.members.size() - resource.data.members.size()) &&
// ...and the caller's uid is the one added or removed
((request.resource.data.members.size() == resource.data.members.size() + 1 &&
  request.resource.data.members.hasAll(resource.data.members) &&
  request.resource.data.members.hasAny([request.auth.uid])) ||
 (request.resource.data.members.size() + 1 == resource.data.members.size() &&
  resource.data.members.hasAll(request.resource.data.members) &&
  resource.data.members.hasAny([request.auth.uid])))
```

- **Documented limitation:** rules see the post-transform array (arrayUnion/arrayRemove are applied server-side before evaluation), so the size-delta + uid-membership checks fully express "the caller added/removed exactly themselves" — but a user can still legitimately join/leave only their own membership, which is exactly the intended semantic. True join/leave callables are the STRONG option (SP-H); this diff validation is the minimal SP-G hardening.
- `'members' in resource.data` requires tribes to have a members array — the D10 recalc backfills `members` to every tribe it touches (including `[]`), healing legacy docs.
- **Create restriction (same bug):** `tribes` create currently allows `type: 'official'/'brand'` (`:363`, `:74`). Restrict client create to non-official types: `request.resource.data.type != 'official' && request.resource.data.type != 'brand'` (official clubs are seeded/recalc'd server-side). Creator tribes (`userPrivate`/`userPublic`) remain client-creatable.
- No rules-test harness exists (`firestore-tests/` contains only logs; no `@firebase/rules-unit-testing` anywhere) → T12 is a rules edit verified manually via the emulator (steps in the plan), not an automated test.

### D10 — B4: recalc extended to ALL tribes, XP per member

Rewrite `functions/src/recalcTribes.ts` aggregation:

1. Explicit membership from `collectionGroup('users/{uid}/tribes')` → `uid → tribeId` (exists today, `:48-66`).
2. **Members per tribe = explicit membership docs**, **plus** archetype fallback (existing `clubMap` `:3-10`) for users **without** explicit membership docs, restricted to official club ids (legacy users auto-joined by archetype whose membership doc was never written — decided: keep the fallback so legacy users don't vanish from the daily recalc; document that the fallback is only for official clubs).
3. **XP per member** read directly from that member's `user_stats.avatarStats.totalXp` (stream `user_stats` once into a `uid → xp` map; aggregate per tribe from the member lists). **No archetype bucketing** — this fixes the misattribution where an explicit member of tribe X had their XP counted toward their archetype club (today `:84-105`).
4. Tribe totals: `memberCount = members.length`, `totalXp = sum(member XP)`.
5. `totalHabitsCompleted`/`totalChallengesCompleted`: keep the `global_activities` per-`clubId` aggregation (documented limitation: activities written before D7 are archetype-attributed; counts heal forward after the D7 fix lands).
6. **Drop the 6-hardcoded-club special case:** write every tribe id found in the membership map + official club ids, with chunked batches (500/batch) and merge-sets (`batch.set(..., {merge: true})` — the doc may not exist for creator tribes; admin SDK bypasses rules).
7. **Extract a pure aggregation function** (`aggregateTribeStats(membershipMap, archetypeMap, clubMap, userStatsXp) → Map<tribeId, {members, totalXp}>`) so the math is unit-testable with jest (functions tooling: `functions/package.json` → `npm test`, jest + ts-jest + firebase-functions-test, tests in `functions/test/*.test.ts`).
8. Keep the single (non-transactional) batch per run — a 500-doc transaction is not feasible; a failed run simply reruns the next 3AM. Document the tradeoff.

### D11 — XP spoofing: FLAG, not fixed (SP-H)

`user_stats` is owner-writable with `isValidStats` (`firestore.rules:267-273`) — type checks only, so a client can set `avatarStats.totalXp` to anything, and the D10 recalc would happily aggregate spoofed XP into tribe totals. **SP-G does not fix this** (server-authoritative XP awarding is a large change: functions recomputing XP from immutable `habit_completions` + rules dropping client `user_stats` writes). D5/D6 reduce the client/server delta so a future SP-H migration is tractable. Documented here so the residual risk is explicit: until SP-H, tribe totals are only as trustworthy as client-written user XP.

---

## 4. Bug-to-fix matrix (B1–B15)

> The audit enumerated B1–B15; B6 and B12 were reported as one entry ("asymmetric undo"); B15 is the XP-spoofing flag from the audit's Rules section, given its own row here for completeness.

| # | Defect (verified) | Fix | Where |
|---|---|---|---|
| B1 | Onboarding joins twice: `club_screen.dart:53` `joinTribe` (transaction +1) then `onboarding_state_notifier.dart:427` `joinClub` (enqueued +1) → memberCount +2 | D1 guard in `joinClub` (Drift active OR Firestore membership doc exists → early return) | `drift_tribe_repository.dart` |
| B2 | `joinTribe` guard is Drift-only (`tribe_membership_service.dart:36-39`) — reinstall user with Firestore membership joins again → duplicate doc + extra +1 | D1: Firestore `users/{uid}/tribes` existence check before transaction | `tribe_membership_service.dart` |
| B3 | Client `tribes.totalXp/...` writes denied by rules → `syncTribeStats` (`tribe_card.dart:217,229`) always fails + dead-lettering | D4: remove tribe-total enqueues + remove `syncTribeStats` + remote-preferred display merge | `drift_habit_repository.dart`, `tribe_stats_service.dart`, `tribe_card.dart`, `cached_tribe_stats_provider.dart`, `drift_tribe_repository.dart` |
| B4 | `recalcTribes` drops/misattributes non-archetype explicit members; archetype-'none' members dropped; XP bucketed by archetype | D10: members = explicit docs (+ official fallback); XP per member | `functions/src/recalcTribes.ts` |
| B5 | Challenge XP added to Drift `user_stats` (`drift_habit_repository.dart:382-389`) never pushed to Firestore `user_stats` (`:494-512` uses `result.xpGained` only) | D5: increment includes `challengeXpEarned`; shared payload builder | `drift_habit_repository.dart` |
| B6 | Undo tribe/contributor debit uses `-xpToUndo` (includes challengeXp) vs credit `+result.xpGained` (`:245,308,322`) | D6 + D4: tribe debit removed (recalc-only); contributor debit `-last.xpGained` | `drift_habit_repository.dart` |
| B7 | Leaderboard double-count: `logHabitCompletion` increment + `logLevelUp` absolute write (`club_activity_service.dart:183-197,271-283`) | D7: `logLevelUp` leaderboard write removed | `club_activity_service.dart` |
| B8 | XP splits across two clubs when joined tribe ≠ archetype club (`_getClubIdForArchetype` `:79-95`) | D7: clubId = active tribe (explicit param from callers; `leaderboard_screen.dart` uses membership) | `club_activity_service.dart`, `drift_habit_repository.dart`, `leaderboard_screen.dart` |
| B9 | `logChallengeComplete` has zero callers — challenge XP never reaches activity/leaderboard | D5: wire from `updateProgress` completion branch | `drift_challenge_repository.dart` + provider |
| B10 | Stale contributor/leaderboard rows shown after leave (nothing deleted) | D8: UI filters by `members` array (D2 keeps data) | `tribe_header_widgets.dart`, `tribe_members_tab.dart`, `leaderboard_screen.dart` |
| B11 | Rejoin resets contributor totals (joinTribe SET `:67-76`; joinClub zeros in merge-set `:417-427`) | D3: merge-preserving contributor writes (no zero keys when doc exists / in payload) | `tribe_membership_service.dart`, `drift_tribe_repository.dart` |
| B12 | Undo enqueues NO `user_stats` decrement → Firestore XP over-counts after undo | D6: enqueue symmetric debit via shared payload builder | `drift_habit_repository.dart` |
| B13 | Any user can set `memberCount`/`members` to arbitrary values (rules key-diff only, `firestore.rules:364-371`); anyone can create official/brand tribes (`:363`) | D9: diff/value validation + create restriction | `firestore.rules` |
| B14 | `firestore_drift_syncer.dart:26-29` queries `club_leaderboards` by `tribeId`; writers use `clubId` → remote rows never synced | D7: syncer queries/upserts `clubId` | `firestore_drift_syncer.dart` |
| B15 | XP spoofing: `user_stats` owner-writable, `isValidStats` value-blind (`firestore.rules:267-273`) | **Non-fix in SP-G** (flag → SP-H server-authoritative XP). D5/D6 shrink client/server delta | — |

---

## 5. Component specs (data flow before → after)

### 5.1 Pure XP-accounting helper (new)

**`lib/features/gamification/domain/services/completion_xp_split.dart`** (new)

- `CompletionXpSplit.fromResult(GameLoopResult result)` → `{ userStatsDelta: xpGained + challengeXp, tribeDelta: xpGained }` (challenge XP goes to the user, never to tribe/contributor increments).
- `CompletionXpSplit.fromStoredRow({xpGained, challengeXp})` → same shape from a persisted completion row (undo side).
- `buildUserStatsXpPayload({required int totalDelta, required String attr, required int level, required String updatedAt})` → the exact `user_stats` enqueue map (`avatarStats.totalXp`/`avatarStats.{attr}Xp` increments + level + updatedAt). **One builder for credit AND undo** — symmetry by construction.
- Tests: pure Dart, no Firebase (`test/features/gamification/domain/completion_xp_split_test.dart`).

Before: credit math inline at `drift_habit_repository.dart:355,382-389,494-512` and debit math inline at `:245-253` — two hand-maintained halves that drifted apart (B5/B6/B12).
After: both halves call the same helper; the undo `user_stats` enqueue appears for the first time (B12).

### 5.2 `joinTribe` / `joinClub` (D1 + D3)

**Before (join):**
```
club_screen.joinTribe ──► transaction { tribes.memberCount +1; members ∪uid;
  users/{uid}/tribes SET; contributors/{uid} SET(zeros) }   ──► Drift active
onboarding_state_notifier.joinClub ──► Drift +1 ──► enqueue { users/{uid}/tribes set;
  contributors SET(zeros); tribes {increment+1, arrayUnion} }        (no guard → +1 again)
```

**After:**
```
joinTribe: guard Drift AND Firestore users/{uid}/tribes (non-empty → Left) ──►
  transaction { tribes +1/∪uid; users/{uid}/tribes SET;
    contributors: read → exists ? merge {userId, joinedAt} : SET(zeros) } ──► Drift
joinClub: guard Drift active OR Firestore users/{uid}/tribes/{tribeId} exists → return;
  else Drift +1 ──► enqueue { users/{uid}/tribes set; contributors merge (no zero keys);
    tribes {increment+1, arrayUnion} }
```

### 5.3 `completeHabit` credit (D4 + D5)

**Before:** local Drift totalXp `+ (xpGained + challengeXp)`; enqueues: `user_stats` `+xpGained` (totalXp & attr), `tribes.totalXp` `+xpGained` (DENIED by rules), `contributors` `+xpGained`.
**After:** local Drift unchanged; enqueues: `user_stats` `+(xpGained + challengeXp)` (both fields, via builder); `tribes` enqueue **removed**; `contributors` `+xpGained` (unchanged). Tribe totals now only move via the 3AM recalc.

### 5.4 Undo (D6)

**Before:** Drift `-xpToUndo`; deletes completion rows; enqueues: completion delete, `tribes.totalXp -xpToUndo` (DENIED), `contributors -xpToUndo` (over-debit). No `user_stats` enqueue.
**After:** Drift unchanged; enqueues: completion delete, `user_stats` `-xpToUndo` (both fields, same builder as credit → exact mirror), `contributors -last.xpGained`. No `tribes` enqueue.

### 5.5 Challenge completion (`updateProgress`) (D5)

**Before:** Drift `+xpReward` to totalXp/vitality (`drift_challenge_repository.dart:92-105`); enqueues only `users/{uid}/challenges` progress; leaderboard/activity silent (B9).
**After:** same local credit + `user_stats` enqueue (`+xpReward`, builder, vitality) + `logChallengeComplete(..., clubId: activeTribeId)` → activity feed + leaderboard increment on the user's actual tribe.

### 5.6 Leaderboard writes (D7)

**Before:** `logHabitCompletion` → `updateUserScore(clubId: archetypeClub, isIncrement: true)`; `logLevelUp` → `updateUserScore(clubId: archetypeClub, isIncrement: false, xp: absolute)`; doc `{clubId, xp, level}`; syncer reads by `tribeId` (never matches).
**After:** `logHabitCompletion`/`logChallengeComplete` → `updateUserScore(clubId: activeTribe, isIncrement: true)`; `logLevelUp` writes activity only; doc unchanged (`clubId` = tribe id); syncer reads by `clubId`. One increment write shape; no absolute overwrites; local+remote leaderboards finally merge.

### 5.7 Recalc (D10)

**Before:** `user_stats` stream → archetype bucket → 6 official club docs (batch). Members from archetype map with partial explicit override.
**After:** explicit-membership map (collectionGroup) + archetype fallback (official clubs only) → per-tribe member lists; `user_stats` stream → uid→XP map; per tribe: `members`, `memberCount`, `totalXp = Σ member XP`; `global_activities` per clubId for habits/challenges; chunked merge-sets to every tribe id in (membership map ∪ official ids).

### 5.8 UI filters (D8)

**Before:** `ContributorsSection`/`TribeLeaderboardSection`/`leaderboard_screen` render every Drift/remote leaderboard row for the tribe, including users who left.
**After:** the tribe's merged `members` list (non-empty) filters rows by `userId ∈ members`.

### 5.9 Rules (D9)

See §3 D9 for the exact expression. Also `tribes` create restricted to non-official/non-brand types.

---

## 6. Data & storage changes

- **No new Firestore collections, no schema/type changes, no Drift migrations.** The drift mutation queue schema is untouched.
- `club_leaderboards` doc field usage converges on `clubId` (= tribe id); the `tribeId` field is no longer read (writer never wrote it; existing docs may have it — ignored).
- `tribes/{id}/contributors/{uid}` docs may exist without `totalXpContributed`/`contributionCount` (fresh joins after D3 create with only `userId`/`joinedAt`) — all readers treat missing as 0 (`tribe_header_widgets.dart:302` already uses `as int? ?? 0`).
- Recalc now writes **all** tribes with membership docs (creator tribes included) with merge-sets — no existing field is removed.
- Dead-lettered mutation rows from past denied `tribes.totalXp` writes remain in the queue; they are inert (retried → denied → re-dead-lettered). Optional cleanup: `resetDeadLetters()` or targeted queue pruning — out of scope, noted in risks.

## 7. File inventory

### New files (lib)
| Path | Responsibility |
|---|---|
| `lib/features/gamification/domain/services/completion_xp_split.dart` | Pure credit/debit deltas + shared `user_stats` payload builder |
| `test/features/gamification/domain/completion_xp_split_test.dart` | Pure math tests (B5/B6/B12 regression) |

### Modified files (lib)
| Path | Change |
|---|---|
| `lib/features/social/domain/services/tribe_membership_service.dart` | D1 Firestore guard in `joinTribe`; D3 merge-preserving contributor write |
| `lib/core/drift_repositories/drift_tribe_repository.dart` | D1 `joinClub` guard; D3 contributor payload without zero keys; D4 `_mergeTribeData` remote-preferred |
| `lib/core/drift_repositories/drift_habit_repository.dart` | D4 remove tribe-total enqueues; D5 credit shape; D6 undo symmetry (user_stats enqueue + contributor debit fix) |
| `lib/core/drift_repositories/drift_challenge_repository.dart` | D5 `SocialActivityService` injection; reward enqueue + `logChallengeComplete` wiring |
| `lib/features/social/presentation/providers/challenge_provider.dart` | D5 construct repo with `socialActivityServiceProvider` |
| `lib/features/social/domain/services/club_activity_service.dart` | D7 `clubId` param on log methods; remove `logLevelUp` leaderboard write |
| `lib/features/social/domain/services/firestore_drift_syncer.dart` | B14 query/upsert by `clubId` |
| `lib/features/social/data/services/tribe_stats_service.dart` | D4 remove `syncTribeStats` |
| `lib/features/social/presentation/widgets/tribe_card.dart` | D2 dialog copy; D4 drop `syncTribeStats` calls |
| `lib/features/social/presentation/providers/cached_tribe_stats_provider.dart` | D4 remote-preferred merge |
| `lib/features/social/presentation/widgets/tribe_header_widgets.dart` | D8 `ContributorsSection` members filter |
| `lib/features/social/presentation/screens/tribe_members_tab.dart` | D8 pass members to sections |
| `lib/features/social/presentation/screens/leaderboard_screen.dart` | D7 membership-based clubId; D8 filter |

### Modified files (functions)
| Path | Change |
|---|---|
| `functions/src/recalcTribes.ts` | D10 pure `aggregateTribeStats` + all-tribe recalc |
| `functions/test/recalcTribes.test.ts` | (new) jest tests for the pure aggregation |
| `firestore.rules` | D9 `tribes` update/create validation |

### Test files (lib)
`test/core/drift_repositories/drift_tribe_repository_test.dart`, `drift_habit_repository_test.dart`, `drift_challenge_repository_test.dart`, `test/features/social/domain/services/tribe_membership_service_test.dart` (fix pre-existing failure), `club_activity_service_test.dart` (+extended/partner fanout), `firestore_drift_syncer_test.dart`, `test/features/social/data/services/tribe_stats_service_test.dart` (drop syncTribeStats tests), `tribe_card_test.dart`, `all_tribes_screen_test.dart` (TribeStatsService references), `leaderboard_screen`/`tribe_members_tab` widget tests as affected.

## 8. Error handling & edge cases

- **Offline join via `joinClub`:** the Firestore membership-doc check may throw offline → degrade to Drift-only check and proceed (the enqueued operations replay when online; the D1 guard is best-effort, not a hard lock; multi-device races are further constrained by D9 rules).
- **`joinTribe` double-tap / race:** the Firestore guard read + transaction are separate steps; the transaction itself is atomic but two rapid calls could both pass the read. D9's ±1 rules validation bounds the damage to ±1 per write; the client guard covers the real-world duplicate flows (onboarding, reinstall).
- **Rejoin while membership doc exists in another tribe:** `joinTribe`'s guard fails with `Left(AlreadyInTribe)` (same as today's Drift semantics). Switching tribes is a leave+join (existing behavior).
- **Tribe doc missing `members`:** D9 rules deny the update until the recalc backfills `members` (heals within 24h); `joinTribe` transaction tolerates missing `memberCount` (`?? 0`) and writes `members` via `arrayUnion` (creates it).
- **Undo with no stored completion row / already-undone:** existing no-op path stays (`drift_habit_repository.dart:237-240`); the new enqueues only run when a row is actually deleted.
- **Contributor doc missing on completion:** enqueued merge-set increment on `contributors` creates it via merge (increments apply); rules allow create when `memberId == uid` and update for owner keys — the completion enqueue only touches owner keys (`totalXpContributed`, `totalHabitsCompleted`, `contributionCount`, `lastContributionAt`, `lastActivity`).
- **Challenge completion while offline:** Drift credit is local; `logChallengeComplete` enqueues replay when online; the active-tribe lookup is a local Drift read (no network dependency).
- **Reinstall user with stale Firestore membership but no local state:** `joinClub` guard sees the Firestore doc → no duplicate; `joinTribe` guard likewise; the user can leave (leaveTribe only needs Drift `deactivateAll` + transaction that tolerates missing tribe doc `:115`).
- **Recalc partial failure:** batches commit in 500-doc chunks; a mid-run failure leaves some tribes updated — next 3AM run converges. No transactions (documented tradeoff).
- **Rules denial after D9:** a client in the field with an old app version writing raw `memberCount` (e.g. a future callable-less client) gets denied → dead-letter → visible as stale count until recalc. Mitigated by shipping client changes with the rules in the same release train.

## 9. Testing strategy

- **Pure logic (no Firebase):** `CompletionXpSplit` credit/debit math + payload builder — the exact B5/B6/B12 symmetry is proven in `completion_xp_split_test.dart`. Recalc aggregation as a pure function — `functions/test/recalcTribes.test.ts` (jest + ts-jest; run `cd functions && npm test`).
- **Service/repository tests with `fake_cloud_firestore` (^4.1.1) + Drift in-memory (`NativeDatabase.memory()`)** — pattern already used in `tribe_membership_service_test.dart`:
  - `joinTribe` guard (Firestore membership exists → Left), contributor merge-preserve on rejoin, leave behavior; **fix the pre-existing failing test** (assert Firestore state, not mutation queue).
  - `joinClub` guard (Drift active / Firestore doc exists → no-op, no enqueued ops, no `incrementMemberCount`).
  - `completeHabit` credit payload (`+ xpGained + challengeXp` on `user_stats`; **no** `tribes` enqueue) and undo debit payload (`- xpToUndo` on `user_stats`; `- last.xpGained` on contributors; no `tribes` enqueue).
  - `updateProgress` completion → user_stats increment + `logChallengeComplete` invocation (mock `SocialActivityService` via constructor injection).
  - `club_activity_service` leaderboard writes: `logLevelUp` no longer writes leaderboard; clubId override param honored.
  - `firestore_drift_syncer` pulls remote rows by `clubId`.
- **Rules:** no harness exists (verified) → manual emulator verification steps in the plan (T12): start `firebase emulators:start`, replay the join/leave write shapes from a throwaway script, assert accept/reject for: ±1 memberCount+uid member change (accept), +2 change (reject), totalXp write (reject), official/brand create (reject), creator create (accept).
- **Widgets:** filter behavior (D8) covered in `tribe_members_tab`/`leaderboard_screen` widget tests; `tribe_card_test.dart` updated for new dialog copy and dropped `syncTribeStats`.
- **Regression sweep:** full `flutter test` + `dart analyze lib test` + `cd functions && npm test`.

## 10. Out of scope (SP-G)

- XP spoofing fix / server-authoritative XP awarding (D11 → SP-H; also the STRONG join/leave callables option).
- Deleting contributor/leaderboard history on leave (D2 alternative — user chose Keep everything).
- Creator-tribe ownership features, `challenges.participants` handling, activity-feed content.
- Backfill purge of already-stale data (dead-letter rows, old misattributed leaderboard entries) — healed by recalc/forward writes.
- New rules-test harness infrastructure.

## 11. Risks

- **D9 residual:** rules can still be bypassed by a crafted sequence of ±1 writes (each legal), and multi-device increments can transiently diverge; authoritative callables in SP-H close this. Official/brand create restriction may break an existing client path that seeds official clubs on-device — verified: seeding is server-side (`seed.ts`/recalc) and `DriftTribeRepository._seedLocalClubs` is local-only (no Firestore writes).
- **D10 scope creep:** recalc now writes every tribe with members (creator tribes included) — must use merge-sets and never clobber `ownerId`/`name`/`type`; the pure function + jest tests guard the math, and the merge-set guard the data.
- **Display regressions from D4's remote-preferred merge:** if the recalc hasn't run yet for a tribe, remote values are absent → falls back to local (no regression). If remote is stale-low (pre-fix inflation), tribe totals may appear to shrink after the first recalc — expected correction, worth a release note.
- **Undo enqueue ordering:** the `user_stats` debit and completion-row delete are both enqueued (same transaction locally, separate queue rows) — a crash between them leaves a visible completion with over-counted XP until the debit replays (idempotent-ish; a second undo has no row to delete and no-ops).
- **`logChallengeComplete` wiring adds a dependency edge** (challenge repo → social service): verified acyclic (`challenge_provider.dart` already imports `tribes_provider.dart`; `socialActivityServiceProvider` needs `leaderboardRepositoryProvider` only).
