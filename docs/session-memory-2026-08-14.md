# Session Memory — 2026-08-14

**Product:** Emerge (identity-first habit engine). Released, <50 users, Nigeria beachhead, Firebase (Auth/Firestore africa-south1/Functions nodejs22), Riverpod 3 + Drift + go_router 17, fpdart Either.

## 1.0.8 release (committed `33b52596`, `f3eaa696` — deployed web + Play production 2026-08-14)

1. **Tribe XP / partners / leaderboard fixes verified** (commits `2362f66c`, `906d1e53`, `d6b48e64`): focused suites green — tribe XP (55), social/leaderboard (19), blueprints (32+). Fixed a pre-existing test gap in `blueprint_detail_controller_test.dart` (remote-config override for the free-tier gate, `33b52596`).
2. **Live username availability check** (`33b52596`): new public callable `checkUsernameAvailability` (`functions/src/usernames.ts`) probes the `usernames/{normalized}` doc-as-lock BEFORE account creation; signup + creator signup debounce (400 ms) a field-level "This username is already taken" error while typing. AuthRepository gained `checkUsernameAvailability`. **Deployed to prod** (functions).
3. **Starter-habit recommended durations** (`33b52596`): `StarterHabitBlueprint` gained required `timerDurationMinutes` (all 30 catalog entries set); `createStarterPack` propagates it (Drift row + Firestore payload); FirstHabitsScreen cards show an "N MIN" chip.
4. **Blueprint seeds v6** (`33b52596`): all 76 habit specs now carry a recommended duration (0-duration habits eliminated); seed check requires durations so existing Firestore docs backfill.
5. **Version 1.0.8+13** in all 4 places (pubspec, `kAppVersion`, settings label, `web/version.json`) — bumped BEFORE builds per runbook.
6. **Deploy record**: functions deployed (`checkUsernameAvailability` created); `flutter clean && flutter build web --release` → hosting live (verified 200 + version.json 1.0.8+13); AAB 76.4 MB → stripped 56.8 MB → bundletool validate OK → **production track live, versionCode 13** (notes ≤500 chars).
7. **IDX build gotchas hit this release**: gradle wrapper dist gone after cache wipe (re-download via `./gradlew --version`); `android/gradle.properties` had regressed to `-Xmx2048m` → R8 OOM "Java heap space" → restored `-Xmx8192m` (commit `f3eaa696`); `key.properties` recreated from documented creds (`emerge123`/alias `emerge`).

## Completed this session (committed + pushed `b107bd26..a8163ad3`)

1. **Email Cloud Functions removed** (commit `5d7dc528`, −881 lines). `email.ts`, `email_templates.ts`, `email_verification.ts`, `marketing_email.ts` + their tests deleted — the GH Actions worker (`email-worker/` + `.github/workflows/emails.yml`) is the only email path now. Verified: `tsc --noEmit` clean, no dangling imports, client email verification uses only the Firebase Auth SDK (`sendVerificationEmail` in `firebase_auth_repository.dart:436`). **Deployed to prod** — no email functions remain in the deployment; full `firebase deploy --only functions` works without `RESEND_API_KEY`.

2. **Tribe XP recalc now contributor-derived** (commit `35ae1420`). `recalcTribes.ts` sums `tribes/{id}/contributors/*.totalXpContributed` as the PRIMARY source (historical attribution — XP stays with the previous tribe after switching), falling back to `user_stats` sums only for tribes with no contributor docs. Reconciles to exactly the same value the `maintainTribeXp` trigger writes. `seed.ts` official clubs now seed `members: []` (server-owned field). **Deployed to prod** (`applyDailyTribeRecalculation` updated). 121/121 functions tests green.

3. **1.0.7 release prep** (commit `a8163ad3`):
   - `scripts/play_deploy.mjs` — throws if `--countries` is passed with `--status completed` (API rejects countryTargeting on completed releases); completed releases now pass `null` targeting
   - `android/app/build.gradle.kts` — debug builds fall back to the debug keystore when `key.properties` is absent (IDX workspace); local PC with real secrets unchanged
   - `web/service-worker.js` — now actively `unregister()`s itself after purging caches (stale SW caused the AssetManifest 404 symptom even after redeploys)
   - `web/version.json` → 1.0.7+12; `docs/android-release.md` gained IDX-specific build notes, 1.0.7 size numbers (75.8 → 56.3 MB after strip), release-notes writing guide (500-char cap), and the completed-release error table rows

## Late session (committed `2c30d75c` + live GCP change): web auth + email links/routing

1. **Web Google sign-in root cause = API key referrer restriction.** The dedicated web key (`b3783a74-92c4-4b4b-b600-b4363bce7260` / `AIzaSyBXiqmFfdGUmMnYSVQ1kTBDczk-4jbCvOQ`, restricted this morning in `b107bd26`) allowed ONLY `tradeflash-l2966.web.app` + `emerge-404.web.app`. Verified live: identitytoolkit returns `403 "Requests from referer ... are blocked"` for `localhost` and `emerge.app` referers, while the web.app referer passed. **Fixed via gcloud (owner account `joeukpai55@gmail.com` active):** added `http://localhost/*`, `http://localhost:*/*`, `https://localhost:*/*`, `https://tradeflash-l2966-*.web.app/*` (preview channels). Re-verified live: localhost passes (400 endpoint-reached), parked `emerge.app` still blocked. `scripts/restrict_api_keys.sh` WEB_REFERRERS updated to match. If the user tests web on a custom domain, it must be added too.
2. **`emerge.app` is a PARKED GoDaddy domain** (redirect script → `/lander`, `LANDER_SYSTEM="PW"` parking) — every email link to it was a dead end. `emerge-404.web.app` also serves nothing (404). Real web app = `tradeflash-l2966.web.app`.
3. **Email links fixed** (`2c30d75c`): `email-worker/src/templates.js` CTAs → `https://tradeflash-l2966.web.app/timeline`; welcome email adds "Get the app on Google Play" → `https://play.google.com/store/apps/details?id=com.emerge.emerge_app` (verified listing exists, 200). `verify.js` `DEFAULT_VERIFICATION_URL_WEB` → `https://tradeflash-l2966.web.app/verify-email` (mobile keeps `emergeapp://verify-email`). 27/27 worker tests green.
4. **Owner was receiving every user's email**: `EMAIL_OVERRIDE_TO` secret was wired into BOTH workflows (emails.yml, emails-welcome.yml) → all sends routed to the owner's inbox. Removed the env line from both workflows — real recipients now. Welcome is still one-time per user via the `welcomeEmailSentAt` marker (the perceived recurrence was the override echo). `EMAIL_OVERRIDE_TO` secret still exists but unused — delete in GitHub Settings.
5. **Recommendation for user:** set `EMAIL_FROM` to a real sending address — the default `no-reply@emerge.app` uses the parked domain and will hurt SMTP deliverability/spam scoring.

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
