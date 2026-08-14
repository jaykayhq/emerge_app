# Backend Engineering Research & Debug Log — 2026-08-13

**Project:** Emerge (identity-first habit engine) — Flutter 3.44 / Dart 3.12, Firebase (Auth, Firestore `africa-south1`, Functions nodejs22), Riverpod 3 + Drift + go_router 17, fpdart `Either`.

This document records the root-cause investigation for the reported issues (tribe member counts, XP attribution, premium gating, email-verification UX, web asset/font failures), the general backend engineering knowledge applied, and the project-specific decisions that resulted. All fixes are test-first (red → green), per the repo's TDD Iron Law.

---

## 1. Web: `AssetManifest.bin.json` 404 + google_fonts failures

### Root cause (verified)
- `flutter build web --debug` **does** produce `assets/AssetManifest.bin.json`, `assets/shaders/candle_flame.frag` and the full asset set — verified locally (build/web/assets/ contains `AssetManifest.bin`, `AssetManifest.bin.json`, `shaders/`, `fonts/`, `NOTICES`).
- The reported 404s occur in `kDebugMode` (App Check log proves a debug build) against a **stale/incomplete served `build/web`** — a build made by an older Flutter SDK emits `AssetManifest.json` (pre-3.19 name); a newer engine requests `AssetManifest.bin.json` → 404. Same class of mismatch for the shader (added to pubspec after the served build was produced).
- `google_fonts` then falls back from the asset manifest to runtime HTTP fetching of `fonts.gstatic.com`; when that is slow/blocked, text falls back to the engine default and the "Could not find a set of Noto fonts" warnings appear. The splash/theme rendered fine because the engine ships a minimal default font — but custom families (SplineSans, Outfit) silently fail.

### General knowledge
- **Flutter web asset manifest:** release/debug web builds list assets in `assets/AssetManifest.bin.json` (binary, since Flutter 3.19; pre-3.19 used `AssetManifest.json`). Mismatched engine/build pairs 404. Never partially-deploy `build/web`; always `flutter clean && flutter pub get && flutter build web --release` then deploy the whole directory (hosting `public: build/web`, Firebase Hosting, CI workflow `firebase-hosting-merge.yml`).
- **google_fonts resolution order** (v8 source, `google_fonts_base.dart:127-163`): (1) bundled asset whose name ends with `<Family>-<Weight>.<ext>` found via the asset manifest (web accepts `.woff2/.woff/.ttf/.otf`); (2) device file system cache; (3) HTTP fetch from fonts.gstatic.com unless `GoogleFonts.config.allowRuntimeFetching` is false. Any failure logs the "unable to load font" error.
- **Service workers:** a stale registered SW can keep serving an old `index.html` (old asset hashes) after redeploys. The no-op SW that only purges caches still *stays registered*; calling `self.registration.unregister()` on activate fully removes the SW footprint.

### Fixes applied
1. **Bundled fonts locally** (`assets/fonts/`, declared in pubspec `fonts:`): SplineSans (400/500/600/700), Outfit (400/500/700), Poppins (400/500/700) — static TTFs obtained from the Google Fonts CSS API (legacy-UA request returns authoritative `.ttf` URLs; SplineSans/Outfit only ship variable fonts in the google/fonts repo, so static weights were fetched from fonts.gstatic.com).
2. **Theme no longer depends on google_fonts at all**: `AppTheme.lightTheme/darkTheme` now use `textTheme.apply(fontFamily: 'SplineSans', ...)`. The handful of `GoogleFonts.splineSans/outfit/poppins(...)` style calls resolve to the bundled assets when the manifest exists, and the family is registered by the engine regardless — text can never fall back to the default font even on a stale-manifest environment.
3. **No-op SW now unregisters itself** on activate after purging caches (`web/service-worker.js`), eliminating legacy-PWA stale shells.
4. Operational note for the user: rebuild + redeploy (`flutter clean && flutter build web --release`), hard-refresh browsers. Fresh builds verified: manifest + shaders present.

---

## 2. Tribe member count never updates (join / switch / leave)

### Root cause (verified, evidence per component boundary)
- `memberCount`/`members` on `tribes/{id}` were written **client-side in two divergent paths**:
  - `TribeMembershipService.joinTribe/leaveTribe` — a Firestore `runTransaction` updating the tribe doc (`lib/features/social/domain/services/tribe_membership_service.dart`).
  - `DriftTribeRepository.joinClub/leaveClub` — three queued sync mutations, the third ("Path C") a merge-set on the tribe doc (`lib/core/drift_repositories/drift_tribe_repository.dart`).
- **Firestore rules denied every legitimate client tribe-doc write** (`firestore.rules` tribes match): `update` requires `'members' in resource.data`, an exact ±1 delta, and only the caller's own uid in the array delta. Seeded official clubs were written with `memberCount: 1250..3200` but **no `members` array** (`functions/src/seed.ts`), so even the atomic transaction path was denied. Locally-seeded clubs not yet on Firestore hit create-vs-update denial; dead-letter replays hit double-apply denial.
- Observable symptom: dead-lettered mutations **102/103/129/145** (`SyncEngine` revives → 5 retries → `dead`), while membership + contributor writes succeeded. The daily 3AM `recalcTribes` was the only healer.
- XP history was already designed to survive leave/rejoin (contributor docs never deleted) — so switching tribes only needed the *count* path fixed; XP staying with the previous tribe is the contributor model.

### General knowledge
- **Firestore counters are a server-side concern.** Google's guidance: a single-document counter contends under frequent writes; for correctness at scale use distributed counters (shards) or derive the value from an event log. For *membership counts* specifically, the derived-count pattern is superior: **`memberCount = members.length`** — idempotent (arrayUnion/Remove are idempotent), replay-safe, and exactly what the daily recalc already computed.
- **Cloud Functions Firestore triggers (2nd gen):** `onDocumentWritten("users/{uid}/tribes/{tribeId}")` gives `before`/`after` snapshots and runs in the trusted server environment, bypassing security rules. Use a transaction to read the tribe doc and write both fields atomically; skip when the doc is missing (locally-seeded clubs) — the scheduled recalc backfills official clubs.
- **Security rules:** fields owned by server code should be *denied* to clients — rules are the enforcement boundary, not the app. Removing the aggregate-member clause shrinks the attack surface and prevents stale clients from dead-lettering forever.
- **Dead-letter hygiene:** a mutation that can never succeed must be purged, not revived. `MutationQueueDao.purgeTribeDocMutations()` deletes all top-level `tribes` rows at startup (before revival), killing the revive→5-retries→dead loop.

### Fixes applied
1. **New trigger `maintainTribeMembership`** (`functions/src/tribe_membership.ts`, exported in `index.ts`): on membership doc create → `arrayUnion` + `memberCount = members.length`; on delete → `arrayRemove` + length; no-op when the array wouldn't change (replay-safe) or when the tribe doc is missing. Tested in `functions/test/tribe_membership.test.ts` (7 cases, incl. seeded-club-without-array and replays).
2. **Client stops writing the tribe doc:** service transaction now writes only the membership + contributor docs and updates the local Drift count (`tribeStatsDao.incrementMemberCount ±1`); `DriftTribeRepository` drops Path C.
3. **Rules tightened** (`firestore.rules`): tribe doc `update` only for the tribe creator or admin; `create` unchanged; reads unchanged. Contributor subcollection rules unchanged.
4. **Seed corrected:** official clubs now seed `members: []`; the fake `memberCount` collapses to the real count on first join/recalc (consistent with `recalcTribes` semantics).
5. **Switch = leave(old) + join(new)** — both sides now fire the trigger on the correct tribe; contributor docs (XP history) intentionally survive, satisfying "XP stays in the previous tribe".

---

## 3. Habit / challenge XP attribution to tribes and global XP

### Root cause (verified)
- **Global XP was already correct** for both flows: Drift-first `user_stats` writes + queued `user_stats` sync; habit flow includes challenge XP (`drift_habit_repository.dart`).
- Tribe-side defects:
  1. Habit flow credited the tribe with **base XP only** — `challengeXpEarned` was excluded from local tribe stats, the `tribes/{id}/contributors/{uid}` record, and the leaderboard increment (`logHabitCompletion`).
  2. **Challenge flow wrote nothing to the tribe**: no local `tribeStatsDao.incrementContribution`, no contributor record (leaderboard only).
  3. Tribe doc `totalXp` was **recalc-only (24 h stale)** and recalc summed `user_stats.totalXp` per current member — which *moves XP with the member* when they switch tribes, contradicting the requirement that XP stays with the previous tribe.
  4. `UserAvatarStats.toMap()` omitted the derived `totalXp`, so full-profile merge-sets could clobber nested `avatarStats.totalXp` increments (dotted-path writes replace whole nested maps).

### General knowledge
- **Event-driven aggregates:** a subcollection of *attribution records* (contributors) is the source of truth; the aggregate (tribe `totalXp`) is derived. Client writes records with `FieldValue.increment` markers through the sync engine; a trigger applies the before/after delta in a transaction. The scheduled recalc reconciles from the same records so both mechanisms agree.
- **Historical attribution:** XP is attributed to the tribe the user belonged to **at the time of the event** — never re-homed on membership change. This is why `user_stats`-summing is the wrong source for tribe totals.
- **Trigger at-least-once caveat:** duplicate delivery of a delta can double-apply; the daily recalc overwrite is the corrective backstop (acceptable at <50 users; a per-event idempotency key is the scale-up path — see `docs/session-memory-2026-08-12.md` for the 500-op batch/chunk precedent).
- **Model integrity:** derived fields in `toMap()` prevent nested-map clobbering across writers (client increments + full-profile sets).

### Fixes applied
1. Habit flow now credits `base + challengeXpEarned` everywhere (local tribe stats, contributor record, leaderboard).
2. Challenge flow now mirrors the habit flow: local `incrementContribution(xp, habits: 0, challenges: 1)` (active tribe, archetype fallback via `_resolveArchetypeTribe`) + contributor record (`totalXpContributed`, `totalChallengesCompleted`, `contributionCount`).
3. New trigger `maintainTribeXp` (`functions/src/tribe_contributions.ts`): delta of `totalXpContributed` applied to `tribes/{id}.totalXp` in a transaction (clamped ≥ 0; zero-delta and missing-tribe no-ops). Tested in `functions/test/tribe_contributions.test.ts` (5 cases).
4. `recalcTribes` now sources XP from **contributor records** (collectionGroup stream), falling back to `user_stats` sums only for tribes with no contributor docs — matching the trigger's source so the daily pass reconciles instead of bouncing. `aggregateTribeStats` is pure and unit-tested (`functions/test/recalcTribes.test.ts`, 10 cases).
5. `UserAvatarStats.toMap()` includes the derived `totalXp`.

---

## 4. Premium gating: blueprints, habits, coach

### Root cause (verified)
- The 5-active-habit free cap **is enforced** in both normal creation paths (`createHabit` provider + dashboard quick-create) via Remote Config `free_habit_limit` (default 5) and `isPremiumProvider`.
- **Real bypass:** blueprint adoption (`BlueprintDetailController.adoptBlueprint` → `repository.createHabitsFromBlueprint`) created every blueprint habit with **no cap/premium check** — a free user could push well past 5 active habits by adopting multiple 3-habit blueprints.
- **Coach quota is flat 3/day** (`CoachAskQuota.freeDailyLimit = 3`, shared_prefs per-day key) — verified **not** habit-count-linked. The perceived linkage comes from the coach Day Card's habit-progress chips (active/completed counts) next to the "X of 3 coach asks left today" hint. Premium gets data-grounded Groq answers (`getGroqCoachAdvice` callable); free users get canned replies; the quota is consumed for both.
- **Blueprints:** the premium mechanism works for creator-uploaded `isPremium: true` blueprints (paywall push), but zero seeded blueprints are premium — the entire seeded catalog is free. That is a catalog-content decision, not a gate bug.
- **Server-side enforcement:** habits are created via direct Firestore writes from the sync engine; Firestore triggers cannot reject writes, and moving habit creation to callables is a redesign. The client-trust model is the documented design (`docs/FREEMIUM_MODEL.md`); only the coach callable exists server-side (and it currently checks auth only).

### General knowledge
- **Freemium enforcement layering:** client gates for UX (dialogs, dead-ends) + Remote Config for limits (no app update to change) + entitlement truth in one place (`users/{uid}.isPremium` on web via Paystack webhook; RevenueCat + custom-claims fallback on native). Server-side callable enforcement is the next layer when writes move to callables.
- **Pure decision functions** (`FreeTierHabitGate.canAddHabits`, `CoachAskQuota`, `decideRedirect`) are the repo's signature testable pattern: plain data in, decision out, no Firebase/Riverpod.

### Fixes applied
1. New pure gate `FreeTierHabitGate.canAddHabits(activeHabitCount, habitsToAdd, freeLimit, isPremium)` (`lib/features/habits/domain/services/free_tier_habit_gate.dart`) + 5 unit tests.
2. `BlueprintDetailController.adoptBlueprint` enforces it (active non-archived count + blueprint habit count vs Remote Config limit, premium bypass); throws `SubscriptionLimitReachedException`, surfaced by the blueprint detail screen via `showPremiumLimitDialog(PremiumLimitType.habit)` — same UX as habit creation.
3. Dashboard quick-add `activateBlueprint` was already gated per-habit — verified, no change needed.
4. Reported honestly: coach quota is not habit-linked (Day Card chips are display-only); seeded blueprint catalog has no premium items (content decision); server-side habit-limit enforcement requires callables (documented as the known trust-model limitation).

---

## 5. Email verification must not block signup

### Root cause (verified)
- A 7-day grace period **already exists server-side**: `functions/src/email_verification.ts` (scheduled daily) writes `users/{uid}.emailLockedAt` for unverified users whose `emailVerificationSentAt` is older than 7 days; `currentEmailLockedAtProvider` exposes it.
- The **hard blocker was one branch** in `decideRedirect` (router.dart): any unverified user on a non-auth/non-onboarding path (including the finished dashboard) was bounced to `/verify-email` *even inside the grace period*. Signup also routed straight to `/verify-email`, and the email was only sent when that screen mounted.

### General knowledge
- **Grace-period pattern:** verification is a *progressive* gate — frictionless at signup (banner/toast), escalating to a full-screen lock at a deadline. The lock must be server-computed (trusted clock, authoritative `emailVerified` from Firebase Auth), with the client only *reading* `emailLockedAt`. Anchor the 7-day clock on `emailVerificationSentAt` (first send), not account creation.
- **Pure router decisions:** `decideRedirect` is a pure function over `RedirectContext` — the UX change is a one-branch edit, pinned by tests (no GoRouter/Firebase needed).
- **Banner composition:** top overlay banners composed in `MaterialApp.builder` (`EmailVerificationBanner` around `WebUpdateBanner`/`OfflineBanner`) — but note `builder` runs **above the Navigator**: widgets needing an `Overlay` (Tooltips) will crash there; use plain icons/buttons.

### Fixes applied
1. Router: within the grace period an unverified user is allowed **every** surface (banner nudges); only `emailLockedAt != null` locks non-auth paths to `/verify-email`. Tests updated (`router_redirect_test.dart`: grace-on-shell-path stays; locked-on-shell-path → verify).
2. Signup always routes to `/onboarding/identity-studio` and sends the verification email best-effort (non-blocking, logged on failure); Google sign-ins skip (already verified).
3. New `EmailVerificationBanner` (top overlay, dismissible per session, action → `/verify-email`, hidden when verified/locked/on the verify screen; guarded router read). Composed in `main.dart`; 5 widget tests.
4. `VerifyEmailScreen` only auto-sends when `emailVerificationSentAt` is null (no silent re-sends on repeat visits); locked variant unchanged.
5. New `emailVerificationSentAtProvider` reads the anchor from `users/{uid}`.

---

## 6. General backend fundamentals (references)

- **Firestore single-document update rate** and distributed counters: https://firebase.google.com/docs/firestore/solutions/counters
- **Security rules conditions** (auth, data validation, cross-doc `get()`/`exists()`): https://firebase.google.com/docs/firestore/security/rules-conditions
- **2nd-gen Firestore triggers** (`onDocumentWritten` before/after): https://firebase.google.com/docs/functions/firestore-events
- **Flutter fonts** (supported formats, pubspec declaration): https://docs.flutter.dev/cookbook/design/fonts
- **Flutter assets/manifest on web**: https://docs.flutter.dev/ui/assets-and-images
- **google_fonts runtime behavior** (asset → device → HTTP fallback): package source `google_fonts-8.1.0/lib/src/google_fonts_base.dart` (`loadFontIfNecessary`, `findFamilyWithVariantAssetPath`).
- **Server-owned fields vs rules**: fields written exclusively by Cloud Functions must be denied to clients in `firestore.rules`; rules are the enforcement boundary.
- **Idempotent triggers:** derive counts from sets (`members.length`) rather than ±1 increments; arrayUnion/Remove are naturally replay-safe; scheduled reconciliation (recalc) is the corrective backstop for at-least-once delivery.
- **Offline-first sync:** local Drift is always the first render source; Firestore mutations queue through the sync engine with markers (`increment`, `serverTimestamp`, `arrayUnion`, `arrayRemove`); dead letters that can never succeed are purged at startup rather than revived.

## 7. Verification status

- Flutter focused suites: **645 tests pass** (router, auth, banner, tribes, drift repositories, habits, monetization, sync).
- Functions: `tsc` build clean; **140 tests pass across 18 suites** (incl. new `tribe_membership`, `tribe_contributions`, updated `recalcTribes`).
- `dart analyze`: **0 issues**.
- `flutter build web --debug`: manifest, shaders, and bundled fonts verified in output.
- Remaining user actions: `firebase deploy --only functions` (both triggers), re-run `seed` for official clubs (`members: []`), rebuild+redeploy web, hard-refresh browsers.
