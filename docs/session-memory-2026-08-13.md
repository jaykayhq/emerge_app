# Session Memory — 2026-08-13

**Product:** Emerge (identity-first habit engine). Released, <50 users, Nigeria beachhead (Paystack NGN), Firebase (Auth/Firestore africa-south1/Functions nodejs22), Riverpod 3 + Drift + go_router 17, fpdart Either.

## Key decisions made this session (2026-08-13)

1. **Tribe memberCount is now server-owned.** Root cause of dead letters 102/103/129/145: client-side tribe-doc writes (service transaction + Drift repo "Path C" mutation) were denied by rules (seeded official clubs had memberCount but no `members` array; create-vs-update on locally-seeded clubs; replay double-apply). Fix: `maintainTribeMembership` trigger (`functions/src/tribe_membership.ts`) on `users/{uid}/tribes/{tribeId}` maintains `members` + `memberCount = members.length` transactionally (idempotent, replay-safe, matches recalc semantics). Client: service no longer writes the tribe doc but DOES update local Drift count; Drift repo drops Path C; rules deny client tribe-doc updates (creator/admin only); SyncEngine purges top-level `tribes` rows at startup (`purgeTribeDocMutations`); seed adds `members: []`. Switching = leave+join; contributor docs (XP history) survive by design.

2. **Tribe XP is contributor-derived.** Recalc previously summed `user_stats.totalXp` of current members — which re-homes XP on tribe switch, violating "XP stays with previous tribe". Recalc now sums `tribes/{id}/contributors/*.totalXpContributed` (user_stats fallback only when no contributor docs). New trigger `maintainTribeXp` (`functions/src/tribe_contributions.ts`) applies before/after deltas to `tribes/{id}.totalXp` in near-real-time; recalc reconciles from the same source. Client: habit flow credits base + challengeXpEarned to local tribe stats/contributors/leaderboard; challenge flow now writes local tribe stats + contributor record; `UserAvatarStats.toMap` includes derived `totalXp` (nested-map clobber fix).

3. **Premium gate closed for blueprint adoption.** `BlueprintDetailController.adoptBlueprint` bypassed the 5-habit cap. New pure `FreeTierHabitGate.canAddHabits(...)` (tested) enforced in the controller → `showPremiumLimitDialog(PremiumLimitType.habit)`. Coach quota verified flat 3/day (NOT habit-linked — narrator Day Card chips are display-only). Seeded blueprint catalog has zero premium items (content decision). Server-side habit-limit enforcement still client-trust model (would need callables).

4. **Email verification is non-blocking during the 7-day grace.** `decideRedirect` branch 6: unverified+within-grace → all surfaces allowed (banner nudges); locked (`emailLockedAt`) → /verify-email only. Signup always → onboarding + best-effort `sendVerificationEmail()` (Google skips). New `EmailVerificationBanner` (main.dart builder; NOT tooltips — builder runs above the Navigator/Overlay; guarded router read). `VerifyEmailScreen` auto-sends only when `emailVerificationSentAt` is null (new `emailVerificationSentAtProvider`).

5. **Fonts bundled locally.** SplineSans/Outfit/Poppins static TTFs in `assets/fonts/` (declared in pubspec fonts:); `AppTheme` no longer calls google_fonts (textTheme.apply(fontFamily: 'SplineSans')); no-op SW now unregisters itself. Web AssetManifest.bin.json 404s were a STALE served build (verified fresh `flutter build web --debug` emits manifest+shaders+fonts) — user must clean rebuild + redeploy.

## Architecture facts & gotchas learned

- Riverpod 3: `StateProvider` lives in `flutter_riverpod/legacy.dart` (not main export) — use `NotifierProvider` + small Notifier class instead.
- Widgets in `MaterialApp.builder` have NO Overlay ancestor — Tooltips crash there; use plain icons.
- `MaterialApp.router`'s GoRouter only resolves state when attached to a Navigator — `router.state.uri.path` throws `Bad state: No element` otherwise (banner guards with try/catch).
- google_fonts v8 asset lookup: any manifest asset whose basename ends with `<Family>-<Weight>.<ext>` is picked; falls back to device cache then HTTP (`allowRuntimeFetching`).
- `flutter build web` bundles pubspec `fonts:` at `assets/assets/fonts/` + registers in `FontManifest.json` (not AssetManifest) — the engine loads them without any manifest fetch.
- Firestore triggers: `event.data.before/after.data()` are post-increment values; delta pattern + scheduled recalc = at-least-once-safe.
- `incrementMemberCount` no-ops without a local Drift row — tests must seed tribe_stats rows.
- `collectionGroup(name)` fake in jest harness must be name-parametrized (recalc now streams TWO collectionGroups).

## Repo operational state (important)

- Working tree has UNCOMMITTED changes: 6 feature areas above + fonts + SW + docs. NEVER `git add -A`; stage only task files.
- `pubspec.yaml` fonts section added (10 TTFs, ~800 KB total in assets/fonts/).
- firestore.rules tribes update clause simplified (creator/admin only).
- functions: 3 new/updated modules (`tribe_membership.ts`, `tribe_contributions.ts`, `recalcTribes.ts`), exported in index.ts. Build + 140 tests green.
- Flutter: 645 focused tests green, `dart analyze` 0 issues, `flutter build web --debug` verified.

## Pending manual actions (user)

1. **EMAIL WORKER (2026-08-13):** Cloud email functions replaced by GitHub Actions (`email-worker/` + `.github/workflows/emails.yml`) — SMTP via nodemailer, no Resend. Old functions deleted from prod; full `firebase deploy --only functions` now works WITHOUT the RESEND_API_KEY secret. **User must add repo secrets:** `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASS` (+ optional `EMAIL_FROM`, `EMAIL_OVERRIDE_TO` to route all emails to one inbox). `FIREBASE_SERVICE_ACCOUNT_TRADEFLASH_L2966` already exists (hosting workflow). Welcome emails are now a daily batch (7-day lookback marker `welcomeEmailSentAt`) instead of a real-time trigger; grace lock + drip logic ported verbatim. Worker tests: 19 node:test cases.
2. Seed official clubs `members: []` — `npm --prefix functions run seed` (needs ADMIN_SECRET); optional — first join/recalc converges.
3. `flutter clean && flutter build web --release` + redeploy hosting; hard-refresh browsers (stale build was the AssetManifest/shaders/fonts 404 cause).
4. Consider seed with 1-2 premium-flagged blueprints to exercise the premium blueprint surface.
5. Full test suite not run (AGENTS.md discipline) — only focused files + functions suite.
