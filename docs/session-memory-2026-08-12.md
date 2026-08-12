# Session Memory — 2026-08-12

**Product:** Emerge (identity-first habit engine). Released, <50 users, Nigeria beachhead (Paystack NGN), RevenueCat + AdMob monetization, Firebase (Auth/Firestore/Functions), Riverpod + Drift + go_router 17, fpdart Either.

## Key decisions made this session

1. **Affiliate-link monetization SCRUBBED** (revert commit `3b27baa7`). Removed: sponsor reward card, affiliate reward service/helper, server-published challenge feed (stream + merger + bundle wiring), rotation automation (scripts/rotation, ai-rotation.yml GH workflow, runbooks), 3 server challenge templates + polli images. Reason: generic affiliate links break identity immersion; rotation introduced challenges without honoring existing challenge expiry. **Pivot: sponsor-first monetization** — flat-fee/CPA sponsored quests, real rewards via voucher API (Giftbit/Tremendous). Validated direction: **creator-paid-challenges** (validation-gates Gate 2: 5 vetted micro-creators, 14-day ₦2,500 paid challenges, WhatsApp mirror; pass ≥0.5-1% follower→purchaser, kill <0.3%). Timeline: `docs/growth/notion-tasks.csv` (dated from 2026-08-12); strategy: `docs/growth/strategy-page.md`. Spec/plans marked SUPERSEDED.

2. **Creator invite codes are now ADMIN-ONLY** (commits `43ff9574` + `e0bf27cf`). Server: `generateCreatorInviteCode` requires `admin: true` claim (`isAdminUser` helper in functions/src/creator_invites.ts); `seedCreatorAccount` now sets `{role: "creator", admin: true}`. Client: `isAdminUserProvider` (role_provider.dart, reads token claim directly — do NOT watch authStateChangesProvider there, it breaks tests via GoogleSignIn chain); Overview + Tribe tabs gate the Invite Creators UI on it. Error mapper maps resource-exhausted/permission-denied specifically.

3. **Strategy artifacts:** GTM = content-led organic + community-first distribution (Reddit/FB/WhatsApp/Quora, 10:1 rule) + Product Hunt; The Emerge Method guide as willingness-to-pay test; sponsor-first MVP sequence in notion-tasks.csv.

## Architecture facts & gotchas learned

- `FirebaseAnalytics.logEvent` takes `Map<String, Object>` (NOT `Map<String, Object?>`) — SDK 12.4.3.
- `FirebaseFunctionsException` constructor is NOT const.
- Drift `getUserChallenges` rebuilt challenges drop sponsor fields unless propagated (injectable `catalogLookup` seam pattern was used then removed with the feature).
- GitHub Actions → Kilo: `kilo run --auto` REQUIRED for headless (interactive mode auto-rejects permissions in CI); kilo reads gateway keys via `OPENCODE_API_KEY`/`KILO_API_KEY` env; polli package is `@pollinations/cli` + `polli auth login --with-token`; deleting a workflow file from main auto-deactivates it.
- `gh`: device-flow login; `gh auth refresh` needs `--hostname github.com` non-interactively; pushing workflow files requires the `workflow` scope (refresh with `-s workflow`); `gh auth setup-git` wires git to the gh token.
- Test-harness patterns: autoDispose FutureProviders race in tests → keep alive with `container.listen(...)`; repository chain providers need `overrideWithValue` mocks; `FirebaseAuth.instance` without init throws — wrap provider bodies in try/catch.

## Repo operational state (important)

- **Working tree has UNCOMMITTED WIP on main** (release 1.0.7 version bumps in pubspec/web/version.json/web_update_service/settings_screen, reflections/onboarding work, build.gradle signing). NEVER `git add -A`; stage only task files.
- Origin/main was merged (1.0.6 release) via stash → merge → conflict resolution (kept 1.0.7 WIP).
- GitHub secrets set: KILO_GATEWAY_KEY, POLLINATIONS_API_KEY (now unused after automation scrub — user may delete), FIREBASE_SERVICE_ACCOUNT_TRADEFLASH_L2966.
- Keys were pasted in chat — recommend rotation.
- `scripts/service-account-key.json` was NEVER tracked (gitignored already) — false alarm resolved.

## Pending manual actions (user)

1. **Deploy functions** for admin-only invites: `firebase deploy --only functions`, then **re-run seedCreatorAccount** (ADMIN_SECRET bearer) so the existing default creator account gets `admin: true`.
2. Grant the CI/hosting service account `roles/datastore.user` + `roles/storage.objectAdmin` (was needed for rotation; still useful).
3. Sign sponsor #1 (pitch due 2026-08-13 per calendar) — sponsor-first MVP sequence.
4. Full test suite was NOT run — only focused files (AGENTS.md discipline).
