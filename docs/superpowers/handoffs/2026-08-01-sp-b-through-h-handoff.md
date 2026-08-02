# SP-B…SP-H Handoff — Program Index (2026-08-01)

> Single entry point for the remaining Emerge App sub-projects. Each sub-project has a **design spec** (decisions, architecture, file inventory, testing strategy) + an **implementation plan** (TDD tasks, exact commands, commit messages) in the SP-A format. SP-A is **complete** (see `docs/superpowers/plans/2026-08-01-sp-a-narrator-coach-tutorials-premium-limits.md` handoff note).

## Status table

| Sub-project | What it ships | Spec | Plan | Status |
|---|---|---|---|---|
| **SP-A** | Narrator-as-coach, tutorials, quota, settings | `specs/2026-08-01-narrator-coach-tutorials-premium-limits-design.md` | `plans/2026-08-01-sp-a-...-plan.md` | ✅ **DONE** (19 commits, final review READY) |
| **SP-B** | Paywall web fix, web premium activation, LimitsCatalog + offers copy | `specs/2026-08-01-sp-b-paywall-premium-limits-design.md` | `plans/2026-08-01-sp-b-paywall-premium-limits-plan.md` | 📄 Ready (7 tasks) |
| **SP-C** | Theme lock ("coming soon" on 5 of 6 themes) | `specs/2026-08-01-sp-c-theme-lock-design.md` | `plans/2026-08-01-sp-c-theme-lock-plan.md` | 📄 Ready (4 tasks) |
| **SP-D** | All Tribes split (creators + tribes), lobby CTA → "Switch Tribes", blueprint-creator removal | `specs/2026-08-01-sp-d-tribes-creators-split-design.md` | `plans/2026-08-01-sp-d-tribes-creators-split-plan.md` | 📄 Ready (6 tasks) |
| **SP-E** | Creator invite codes (generate/redeem callables), creator creation rights, creator tribes, default account | `specs/2026-08-01-sp-e-creator-invites-design.md` | `plans/2026-08-01-sp-e-creator-invites-plan.md` | 📄 Ready (12 tasks) |
| **SP-F** | Blueprint image fixes, standalone page removal, per-tribe curated blueprints (seed v3) | `specs/2026-08-01-sp-f-blueprints-overhaul-design.md` | `plans/2026-08-01-sp-f-blueprints-overhaul-plan.md` | 📄 Ready (10 tasks) |
| **SP-G** | Tribe membership/XP accounting fixes (B1–B15 matrix) | `specs/2026-08-01-sp-g-tribe-membership-xp-design.md` | `plans/2026-08-01-sp-g-tribe-membership-xp-plan.md` | 📄 Ready (14 tasks) |
| **SP-H** | Firebase rules/indexes/functions hardening + admin data cleanup | `specs/2026-08-01-sp-h-firebase-backend-hardening-design.md` | `plans/2026-08-01-sp-h-firebase-backend-hardening-plan.md` | 📄 Ready (12 tasks) |

## Recommended execution order (dependency-driven)

```
SP-C (tiny, independent)
  ↓
SP-B (paywall/limits — client)
  ↓
SP-E (creator backend+client — unlocks creator rights) ──┐
  ↓                                                       │
SP-F (blueprints UI + curation; also removes the         │
      BROWSE BLUEPRINTS CTA so no dangling route)        │
  ↓                                                       │
SP-D (tribes split + Switch Tribes CTA — needs SP-F's    │
      CTA removal or coordinate the interim single-      │
      CHALLENGES button)                                 │
  ↓                                                       │
SP-G (membership/XP accounting — client + recalc)        │
  ↓                                                       │
SP-H (rules/indexes/functions + admin doc cleanup —      │
      depends on E/F/G's backend needs; recalcTribes     │
      ownership shared with SP-G — see coordination) ────┘
```

Alternative: SP-G before SP-E if data-integrity is the priority (SP-G's plan absorbs the pre-existing failing `tribe_membership_service_test`).

## ✅ Confirmations (2026-08-02 — all four resolved by the user)

1. **SP-E D2:** option (a) — ADMIN_SECRET-guarded seed script for the default creator account. **CONFIRMED**
2. **SP-F D1a:** interim single CHALLENGES lobby button (until SP-D's Switch Tribes CTA) is acceptable. **CONFIRMED**
3. **SP-G D2:** leave semantics = "Keep everything" (contributions/contributor doc/leaderboard entry preserved; leave-dialog copy fixed). **CONFIRMED by the user directly**
4. **SP-H:** include the blueprints `'system'` carve-out, dead-function removal (`notifyAchievement` + `onHabitChanged`), and the `isValidStats` deny-list additions. **CONFIRMED**

Execution started 2026-08-02 in the recommended order (SP-C → SP-B → SP-E → SP-F → SP-D → SP-G → SP-H); this index is the coordination source.

## ⚠️ CONFIRM-WITH-USER items (decide before executing the affected sub-project)

1. **SP-E D2 — Default creator account (must confirm):** the spec recommends option (a): an ADMIN_SECRET-guarded seed script creating a known default creator account (credentials delivered out-of-band), mirroring the unexported `seedReviewerAccount.ts` precedent. Alternative (b): manually promote the first creator via admin `setUserRole` + console.
2. **SP-F D1a — Blueprints CTA interim (must confirm):** removing `/social/discover` before SP-D lands leaves the lobby's "BROWSE BLUEPRINTS" CTA pushing an unregistered route. SP-F's plan removes the CTA now (bottom bar = single CHALLENGES button until SP-D reintroduces "Switch Tribes"). Alternative: run SP-D first. Confirm the interim single-button state is acceptable.
3. **SP-G D2 — Leave semantics (recorded as user-confirmed "Keep everything"):** contributions/contributor doc/leaderboard entry are preserved on leave; only the leave-dialog copy is fixed to match. ⚠️ *Note: this confirmation was recorded by the authoring agent via an in-session question — if you did not actually answer "Keep everything", re-confirm before executing SP-G. The alternative (clean break via server-side deletion) is documented in the spec.*
4. **SP-H flags:** (a) blueprints `'system'` catalog carve-out so in-app seeds keep working under the new creator-write rules (recommended: include); (b) removing the dead `notifyAchievement` + `onHabitChanged` functions (recommended: remove); (c) adding `isPremium`/`premium_since` to the `isValidStats` deny-list (recommended: include); (d) `recalcTribes` generalization ownership — SP-H implements unless SP-G ships first (coordinate).

## Cross-sub-project coordination notes

- **Dirty working tree:** several files carry other workstreams' uncommitted WIP (tribe_lobby_screen.dart back-button refactor ~270 lines, habit_create/future_self_studio screens, router.g.dart hash). Every plan's pre-flight covers the commit protocol: stage only named files, never revert/stash WIP, coordinate with the WIP owner on shared files. SP-D's plan has the most explicit protocol for tribe_lobby.
- **SP-D interim fakes:** until SP-H deletes the 6 seeded `creator_*` docs admin-side, the new CREATORS section renders the fakes. Accepted; SP-H can be pulled forward for a zero-fake interim.
- **Admin doc surgery (SP-H):** delete the 6 `creator_*` profiles + 6 `cb_*` blueprints; purge v1 blueprint docs with expired `aida-public` URLs; fix `morning_3`'s dead image URL (verified replacement: `photo-1528715471579-d1bcf0ba5e83`); update `purgeOrphanedUserData`'s `creator_*` skip list.
- **SP-B ↔ SP-H:** SP-B's web premium path reads `users.isPremium` client-side; SP-H optionally adds Paystack-webhook → custom-claims sync and fixes the broken `generateAiRecap` gate (`user_stats.isPremium` → `users.isPremium || subscriptionStatus == 'active'`).
- **SP-E ↔ SP-H:** SP-E's rules changes (creator_invite_codes deny-all, blueprints/challenges creator writes, `type:'creator'` tribes, function-owned `creator_profiles`) ship in SP-H's rules task but SP-E's client depends on them — run SP-E's client work against the emulator or deploy SP-H rules first (SP-E's plan includes an emulator smoke runbook).
- **SP-G ↔ SP-H:** SP-G implements the client-side accounting fixes + recalc generalization decision (D10); SP-H implements the rules ±1 memberCount validation + optional joinTribe/leaveTribe callables (next-phase). `recalcTribes.ts:83-105` has a real bug (XP aggregated by archetype map even when explicit membership differs) — owned by whichever lands first.

## Known pre-existing failures (not caused by SP-A; relevant to SP-G/SP-H)

- `test/features/social/domain/services/tribe_membership_service_test.dart` — "joinTribe enqueues Firestore sync operations" fails at HEAD; SP-G T3 replaces the assertion (the transactional joinTribe no longer enqueues queue ops).
- Client `seedChallenges` is broken in prod (admin-only rule) — SP-E's `createCatalogChallenge` replaces it.
- Friendship invite (`invite_codes`) is broken in prod (no rules) — left documented-broken; SP-E's creator invite is the replacement.

## Deferred cleanup (from SP-A final review)

- Dead AI surface: `ai_service.dart` (GroqAiServiceImpl/aiServiceProvider), `ai_personalization_service.dart`, `get_coach_advice.dart` + `AiRepository`/`AiRepositoryImpl` (only their own tests consume).
- Companion presentation layer: CompanionPanel/Overlay/InlineCard/AskMentorButton — no app consumers.
- `_narratorTriggerFor` (habit_providers) duplicates `_evaluateNarratorTrigger` (habit_completion_service) — extract a shared pure function.
- Inert `companion_visited_/gamification` prefs seed in leveling_screen_test.dart:62.
- Inert remote-config `goldilocks_threshold_*` keys.
- Manual smoke checklist for SP-A (Task 16 Step 3) still needs a device run.
