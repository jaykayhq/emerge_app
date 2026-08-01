# SP-A Design — "The Narrator Is The Coach": Tutorials, Coach Unification, Premium Limits, Settings Refresh

> **Date:** 2026-08-01
> **Status:** Approved (design review 2026-08-01)
> **Scope:** SP-A of an 8-sub-project program (A→H). This spec covers client-only work; no `firestore.rules`, `firestore.indexes.json`, or `functions/` changes.
> **Predecessor plans:** `2026-07-05-narrator-onboarding-timeline-redesign.md` (Tasks 6–20 were never implemented; this spec completes the narrator vision and layers tutorials + coach + quota on top), `2026-06-10-reusable-coachmarks-and-habit-rune-indicator-plan.md` (9 coach marks; only 2 ever wired).

---

## 1. Goals

1. **Re-establish tutorials (node guides)** across all live, front-facing screens, honoring the existing `tutorialsEnabled` setting.
2. **Fold the AI coach into the narrator** — one voice, one resolver, one premium gate. The narrator avatar is the coach entry point.
3. **Add premium limits for coach asks** — free tier gets 3 coach asks/day; premium gets unlimited personal (LLM-grounded) lines. Quota surfaces as part of the premium offer (paywall copy) and in Settings.
4. **Refresh tutorial settings** — one unified "Tutorials" section replacing the legacy Node Guides / Companion Tips tiles; migrate legacy visited flags; remove the superseded companion coach-mark system.

## 2. Recorded design decisions

| Decision | Choice |
|---|---|
| Coach × narrator relationship | **Narrator IS the coach** — Oracle screen deleted; coach lives in the narrator avatar/dialog |
| Tutorial surface scope | All live front-facing screens with complexity; dead/orphaned routes excluded |
| Premium limit shape | **3 coach asks/day** free; unlimited + personal lines premium; tutorials stay free |
| Settings layout | Unified **Tutorials** section: toggle + replay guides + replay onboarding + quota row |

## 3. Architecture

```
                    ┌─────────────────────────────────────────────┐
                    │           NARRATOR (single stack)           │
                    │                                             │
  Events ─────────► │ NarratorTriggerEngine ──► NarratorLine      │
  (habit done,      │      (9 triggers)           Resolver        │
  streak break,     │                              │              │
  level up,         │              ┌───────────────┴────────┐     │
  evening)          │              │                        │     │
                    │   free: GenericLine           premium: │     │
  Avatar tap ─────► │   + CoachAskQuota (3/day)   PersonalLine (LLM)│
  ("ask coach")     │              │                        │     │
                    │              ▼                        ▼     │
  UI:  NarratorAvatar (timeline top-right)  │  NarratorCoachSheet  │
       NarratorMilestoneCard (slide-up)     │  (ask dialog)        │
       Node-guide coach marks (tutorials)   │                      │
                    └─────────────────────────────────────────────┘
        Settings: unified "Tutorials" section (toggle / replay / quota)
```

Layers:

- **Narrator core (exists, incomplete):** `NarratorTriggerEngine` (9 triggers), `NarratorLineResolver` (`GenericLine` free / `PersonalLine` pro), `lineResolverProvider` (wired to `isPremiumProvider` + `GroqAiService.fillNarratorSlots`), `PendingMilestone` notifier, `NarratorAvatar`, `NarratorMilestoneCard`, `NarratorSheet`, `NarratorSummaryCard`.
- **Gaps this spec fills:** avatar never mounted; `pendingMilestoneProvider.set()` never called (no producers); `resolveAskNarratorTrigger` never called; no coach ask surface; no quota; tutorials layer missing; Oracle stack orphaned; settings legacy.
- **Tutorials layer (new, free, first-visit):** node-guide registry (pure data) + provider honoring `tutorialsEnabled` + `hasSeenNodeGuide_<nodeId>`; renders `FeatureCoachMark`.
- **Quota layer (new):** pure daily counter; consumed by coach sheet; surfaced in Settings and premium limit dialog.

## 4. Component specs

### 4.1 Coach unification (narrator = coach)

1. **Mount `NarratorAvatar`** (44dp, exists at `lib/features/narrator/presentation/widgets/narrator_avatar.dart`, currently unused) top-right of the timeline header (`lib/features/timeline/presentation/screens/timeline_screen.dart`), per `docs/design.md` §11.5 (line 788). Tap → coach sheet.
2. **`NarratorCoachSheet`** — evolve `NarratorSheet` (`lib/features/narrator/presentation/widgets/narrator_sheet.dart`): keep instant-text rendering and the two action buttons; re-add a text-input row as the **ask surface** (the old `hasTextField` mode, previously removed in the narrator redesign). Submit → `resolveAskNarratorTrigger` → `lineResolverProvider`:
   - premium → `PersonalLine` via LLM (existing `fillNarratorSlots` / `getGroqCoachAdvice` path);
   - free → curated `GenericLine` from a small ask-response pool, **deducting 1 coach ask from the quota**.
3. **Wire milestone producers** — `pendingMilestoneProvider.set(line)`:
   - `streakBreakFirstMiss` / `onFireState` — already computed in `HabitCompletionResult.narratorTrigger` (`lib/features/habits/data/services/habit_completion_service.dart:85-157`); consume it in the timeline completion flow.
   - `levelUp`, `longAbsence`, `morningBriefEarlyDays` — via `NarratorTriggerEngine.shouldTrigger` evaluation at timeline open (engine currently has no app callers).
   - `onboardingPostArchetype` — fire once after archetype selection in `identity_studio_screen.dart` as a slide-up milestone card (design.md: "The Narrator never interrupts onboarding" — non-blocking, auto-dismiss 6s, swipeable).
   - Never fire milestone cards mid-onboarding except `onboardingPostArchetype`.
4. **Delete the Oracle stack:**
   - Remove routes `reflections` and `goldilocks` from `lib/core/router/router.dart` (lines ~601, ~609). Verified: no `push`/`go` callers exist — orphaned routes.
   - Delete `lib/features/ai/presentation/screens/ai_reflections_screen.dart` and `goldilocks_screen.dart`.
   - Replace the AI Reflections *tutorial* with a `coach` node guide on the coach sheet.
   - `GetCoachAdvice` usecase + `AiRepository.getCoachAdvice` remain (used by the LLM path); the *screens* are gone.
5. **Consolidate duplicate `GroqAiService`** (`lib/features/ai/data/datasources/groq_ai_service.dart` vs `lib/features/ai/data/services/groq_ai_service.dart`): keep the richer `data/services` implementation (identity affirmation, pattern recognition, Goldilocks, challenges, companion messages, archetype fallback bank), delete `data/datasources`, update imports. `fillNarratorSlots` must survive on the kept class.
6. **Weekly recap** stays premium-gated via `WeeklyRecapGated` — unchanged; it is the premium coach artifact.

### 4.2 Coach ask quota (premium limits seed)

- New pure domain unit `CoachAskQuota` (`lib/features/monetization/domain/services/coach_ask_quota.dart`):
  - `freeDailyLimit = 3`; premium users bypass (no deduction).
  - Daily counter persisted in shared_prefs under key `coach_asks_<yyyy-MM-dd>`; rollover by date comparison (pure function `quotaFor(date, usedToday)`).
  - API: `remaining`, `canAsk`, `consume()` — pure + testable without Firebase (mirrors `decideRedirect` signature pattern).
- Provider `coachAskQuotaProvider` in `lib/features/monetization/presentation/providers/` — reads `isPremiumProvider`; skip check when premium.
- Exhausted ask → `showPremiumLimitDialog(PremiumLimitType.coachAsk)` (`lib/features/monetization/presentation/widgets/premium_limit_dialog.dart` — extend the enum + copy: "You've used your 3 free coach asks today." CTA → `/paywall`).
- This tracker is the seed of the generic limits framework extended in SP-B.

### 4.3 Tutorials (node guides)

- New feature `lib/features/tutorials/`:
  - `domain/node_guide_registry.dart` — **pure data**: `nodeId → (route, title, items: List<CoachItemData>, accent)`.
  - `presentation/providers/node_guide_provider.dart` — Riverpod provider: exposes `shouldShow(nodeId)` (requires `tutorialsEnabled` + unseen) and `markSeen(nodeId)` (persists `hasSeenNodeGuide_<nodeId>` via `LocalSettingsRepository`).
- Wire `FeatureCoachMark` (`lib/core/presentation/widgets/feature_coach_mark.dart`, exists) on these **live** surfaces:

  | Node | Screen | Route/file |
  |---|---|---|
  | `timeline` | Timeline | `timeline_screen.dart` |
  | `habit_create` | Create habit dialog | `habit_create_screen.dart` |
  | `habit_advanced` | Advanced habit dialog | `advanced_create_habit_dialog.dart` |
  | `streak_recovery` | Streak Recovery | `streak_recovery_screen.dart` |
  | `world_map` | World Map | `world_map_screen.dart` |
  | `leveling` | Leveling | `leveling_screen.dart` |
  | `future_self` | Future Self Studio | `future_self_studio_screen.dart` |
  | `coach` | Narrator coach sheet | `narrator_sheet.dart` |
  | `challenges` | Challenges | `challenges_screen.dart` (fixes dead `_checkFirstVisit` stub at lines 55–67 that renders nothing) |
  | `all_tribes` | All Tribes | `all_tribes_screen.dart` |
  | `tribe_lobby` | Tribe Lobby | `tribe_lobby_screen.dart` |

- **Replace the 2 companion coach marks** (`social_discover_tab.dart:104-120`, `tribe_tab_content.dart:153-169`): `tribe_tab_content` is orphaned (legacy shell) — remove its mark; the discover mark dies with the blueprints page in SP-F (do not port).
- **Gate everything by `tutorialsEnabled`** — the 2 live companion marks currently ignore it (bug fixed by replacement).
- **Migration:** `migrateVisitedFlags()` in `lib/core/data/repositories/local_settings_repository.dart` — pure function mapping legacy `companion_visited_*` keys → `hasSeenNodeGuide_*` (`timeline, worldMap, profile, tribes, aiCoach→coach, challenges`); `discover` flag dropped (page dies in SP-F). Lives there because that repository owns the `hasSeenNodeGuide_*` target keys and `tutorialsEnabled`. Keep `migrateFromTutorials()` behavior for old `tutorial_*` keys; the companion repository's visited-flag helpers become unused and are removed with the companion coach-mark system.

### 4.4 Settings refresh

Replace the three legacy tiles in `lib/features/settings/presentation/screens/settings_screen.dart` (`Show Node Guides` 365–397, `Reset Node Guides` 412–420, `Reset Companion Tips` 404–411) with one **Tutorials** section:

1. **"Show first-visit guides"** toggle — reuses `tutorialsEnabled` (via existing `TutorialSetting`/`tutorialSettingProvider`); now honored by every node guide.
2. **"Replay first-visit guides"** — existing `resetTutorials()` (clears all `hasSeenNodeGuide_*`).
3. **"Replay onboarding"** — `resetOnboarding()` (existing, `onboarding_provider.dart:76`) + `ref.invalidate(onboardingControllerProvider)`; re-runs the 5-milestone flow. Router already maps progress → `/onboarding/*`.
4. **Coach quota row** — "Coach asks today: 2/3"; taps → paywall when exhausted; shows "Unlimited" for premium.

Remove companion legacy from Settings; clean up the superseded-companion comment in `lib/core/presentation/widgets/scaffold_with_nav_bar.dart:18-20`.

## 5. Data & storage changes

| Storage | Change |
|---|---|
| shared_prefs `tutorialsEnabled` | Reused (no change) |
| shared_prefs `hasSeenNodeGuide_<nodeId>` | Reused; 11 new nodeIds registered |
| shared_prefs `companion_visited_*` | Read once by migration, then obsolete |
| shared_prefs `coach_asks_<date>` | New (quota counter) |
| Drift | No changes |
| Firestore | No changes |

## 6. File inventory

**New:**
- `lib/features/tutorials/domain/node_guide_registry.dart` (+ test)
- `lib/features/tutorials/presentation/providers/node_guide_provider.dart` (+ `.g.dart`, generated)
- `lib/features/monetization/domain/services/coach_ask_quota.dart` (+ test)
- `lib/features/monetization/presentation/providers/coach_ask_quota_provider.dart` (+ `.g.dart`)

**Modified (primary):**
- `lib/features/timeline/presentation/screens/timeline_screen.dart` — avatar mount, milestone producers, node guide
- `lib/features/narrator/presentation/widgets/narrator_sheet.dart` — coach ask input, coach node guide
- `lib/features/narrator/presentation/providers/narrator_providers.dart` — `resolveAskNarratorTrigger` wiring, quota-aware coach ask
- `lib/features/habits/data/services/habit_completion_service.dart` / timeline completion flow — consume `narratorTrigger` → `pendingMilestoneProvider`
- `lib/features/onboarding/presentation/screens/identity_studio_screen.dart` — `onboardingPostArchetype` milestone card
- `lib/features/monetization/presentation/widgets/premium_limit_dialog.dart` — `PremiumLimitType.coachAsk`
- `lib/features/settings/presentation/screens/settings_screen.dart` — Tutorials section
- `lib/core/router/router.dart` — remove `reflections` + `goldilocks` routes
- `lib/features/ai/data/services/groq_ai_service.dart` — consolidated (keep), update imports
- `lib/features/social/data/repositories/companion_repository.dart` (or `local_settings_repository.dart`) — flag migration
- `lib/features/social/presentation/screens/challenges_screen.dart`, `all_tribes_screen.dart`, `tribe_lobby_screen.dart` — node guides
- `lib/features/habits/presentation/screens/*`, `lib/features/profile/presentation/screens/future_self_studio_screen.dart`, `lib/features/world_map/*`, `lib/features/gamification/presentation/screens/leveling_screen.dart` — node guides
- `lib/core/presentation/widgets/scaffold_with_nav_bar.dart` — comment cleanup

**Deleted:**
- `lib/features/ai/presentation/screens/ai_reflections_screen.dart`
- `lib/features/ai/presentation/screens/goldilocks_screen.dart`
- `lib/features/ai/data/datasources/groq_ai_service.dart` (duplicate)

## 7. Error handling & edge cases

- **Quota storage failure:** prefs read failure → default to 0 used (never hard-block a user); write failure → log, still allow the ask (permit by default).
- **Premium on web:** `isPremiumProvider` is false on web until SP-B fixes activation → web users see the free quota until then. Accepted ordering.
- **Onboarding:** narrator never interrupts onboarding; `onboardingPostArchetype` is the single onboarding surface (non-blocking card, auto-dismiss 6s).
- **Milestone card during flow:** auto-dismiss + swipe-up; `pendingMilestoneProvider.clear()` on dismiss (already wired at `timeline_screen.dart:290`).
- **LLM failure:** personal-line generation failure falls back to `GenericLine` (resolver already returns free lines for non-pro; wrap LLM call in try/catch returning generic).
- **Migration idempotency:** `migrateVisitedFlags()` must be idempotent (only migrate keys that exist; never overwrite already-seen node flags).
- **Deleted routes:** verified zero in-app callers; deep links to removed paths 404 → acceptable (they were developer-facing).

## 8. Testing strategy (TDD Iron Law)

Tests written first; focused runs only (never the full suite during dev):

1. `node_guide_registry_test.dart` — pure: every registered node maps to a live route; entries unique.
2. `coach_ask_quota_test.dart` — pure: 3/day cap, rollover by date, premium bypass, exhausted state.
3. `visited_flags_migration_test.dart` — pure: `companion_visited_*` → `hasSeenNodeGuide_*` mapping + idempotency.
4. `narrator_coach_sheet_test.dart` — widget: ask submit path, quota decrement, exhausted → dialog.
5. `node_guide_provider_test.dart` — widget/provider: `tutorialsEnabled=false` suppresses marks; seen-flag persists.
6. `settings_tutorials_section_test.dart` — widget: toggle + replay tiles + quota row render.
7. Update tests referencing deleted screens/routes (`ai_reflections`, `goldilocks`) and removed companion coach marks.

## 9. Out of scope (queued sub-projects)

- **SP-B:** paywall web "RevenueCat not configured" removal, web premium activation (Paystack `users.isPremium` → entitlements), generic limits framework extension, offer copy.
- **SP-C:** theme lock ("coming soon" on 5 of 6 world themes).
- **SP-D:** All Tribes split (creators vs tribes), lobby CTA → "Switch Tribes", blueprint-creator deletion.
- **SP-E:** creator invite-code system + default creator account.
- **SP-F:** blueprints page removal, image fixes, per-tribe curated blueprints.
- **SP-G:** tribe join/leave member-count + XP accounting fixes (B1–B15).
- **SP-H:** `firestore.rules` / `firestore.indexes.json` / `functions/` changes (threads through E/F/G).

## 10. Risks & mitigations

| Risk | Mitigation |
|---|---|
| GroqAiService consolidation breaks `fillNarratorSlots`/`getCoachAdvice` callers | Keep richer service; grep all imports before deletion; `dart analyze` gates |
| Milestone producers spam users | All triggers pass `NarratorTriggerEngine` cooldown (4h) + priority; onboarding exempt except `onboardingPostArchetype` |
| Quota drift across devices | Accepted: quota is per-device (shared_prefs); server-authoritative quota deferred (SP-B/H) |
| Orphaned deep links to removed routes | Routes had zero in-app callers; removal verified by grep |
| Half-finished working tree (uncommitted narrator files) | SP-A plan will commit in coherent task units; verify `dart analyze` before each commit |
