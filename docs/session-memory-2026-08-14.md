# Session Memory — 2026-08-14

**Product:** Emerge (identity-first habit engine). Released, <50 users, Nigeria beachhead, Firebase (Auth/Firestore africa-south1/Functions nodejs22), Riverpod 3 + Drift + go_router 17, fpdart Either.

## Completed this session (committed + pushed `b107bd26..a8163ad3`)

1. **Email Cloud Functions removed** (commit `5d7dc528`, −881 lines). `email.ts`, `email_templates.ts`, `email_verification.ts`, `marketing_email.ts` + their tests deleted — the GH Actions worker (`email-worker/` + `.github/workflows/emails.yml`) is the only email path now. Verified: `tsc --noEmit` clean, no dangling imports, client email verification uses only the Firebase Auth SDK (`sendVerificationEmail` in `firebase_auth_repository.dart:436`). **Deployed to prod** — no email functions remain in the deployment; full `firebase deploy --only functions` works without `RESEND_API_KEY`.

2. **Tribe XP recalc now contributor-derived** (commit `35ae1420`). `recalcTribes.ts` sums `tribes/{id}/contributors/*.totalXpContributed` as the PRIMARY source (historical attribution — XP stays with the previous tribe after switching), falling back to `user_stats` sums only for tribes with no contributor docs. Reconciles to exactly the same value the `maintainTribeXp` trigger writes. `seed.ts` official clubs now seed `members: []` (server-owned field). **Deployed to prod** (`applyDailyTribeRecalculation` updated). 121/121 functions tests green.

3. **1.0.7 release prep** (commit `a8163ad3`):
   - `scripts/play_deploy.mjs` — throws if `--countries` is passed with `--status completed` (API rejects countryTargeting on completed releases); completed releases now pass `null` targeting
   - `android/app/build.gradle.kts` — debug builds fall back to the debug keystore when `key.properties` is absent (IDX workspace); local PC with real secrets unchanged
   - `web/service-worker.js` — now actively `unregister()`s itself after purging caches (stale SW caused the AssetManifest 404 symptom even after redeploys)
   - `web/version.json` → 1.0.7+12; `docs/android-release.md` gained IDX-specific build notes, 1.0.7 size numbers (75.8 → 56.3 MB after strip), release-notes writing guide (500-char cap), and the completed-release error table rows

## Security state

- GitHub secrets live: SMTP_HOST/PORT/USER/PASS, EMAIL_FROM, EMAIL_OVERRIDE_TO (added 07:23 today), FIREBASE_SERVICE_ACCOUNT_TRADEFLASH_L2966.
- **STILL PRESENT, now confirmed unused:** `KILO_GATEWAY_KEY` + `POLLINATIONS_API_KEY` (the AI rotation workflow was scrubbed 8/12). Delete both in GitHub Settings → Secrets.
- API key restriction (console-only, owner action): Android `AIzaSyAWlSsjpgQN4E_Bt3esMa1hIFJ9nESAEmA`, iOS `AIzaSyAhbcUe2s1B-K_qd4w3fmyKef0AQhJtNAg`, web key now dedicated per commit `b107bd26` — apply Application + API restrictions, then resolve the 3 secret-scanning alerts.
- Container-image cleanup policy: already exists (1 day retention) — the deploy-time warning was a false negative; `functions:artifacts:setpolicy` confirms no changes needed.

## Deploy record

- `firebase deploy --only functions` (2026-08-14, service account `scripts/service-account-key.json`): all functions updated, incl. `applyDailyTribeRecalculation` (contributor-XP), `generateCreatorInviteCode` (admin-only, from 8/12), `seedCreatorAccount`. No email functions remain deployed.

## Pending manual actions

1. Delete `KILO_GATEWAY_KEY` + `POLLINATIONS_API_KEY` GitHub secrets (unused since the rotation workflow was scrubbed).
2. Rotate the kilo/polli keys from 8/8 if they were shared elsewhere (pasted in chat).
3. GCP console: restrict the 3 Firebase API keys; mark secret-scanning alerts resolved.
4. Next release: `flutter clean && flutter build web --release` + redeploy hosting (stale build was the fonts/manifest 404 cause); Android 1.0.7 AAB flow is documented in `docs/android-release.md`.
5. Optional: seed official clubs `members: []` (`npm --prefix functions run seed`) — first join/recalc converges without it.
