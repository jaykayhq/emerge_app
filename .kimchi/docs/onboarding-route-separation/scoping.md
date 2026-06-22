# Scope: Separate Onboarding Routes for Creators vs Normal Users

## Goal
Close the routing hole that causes a creator who signs up to be redirected into
the normal-user onboarding flow. Make routing deterministic by introducing a
canonical `role` ("creator" | "user") backed by Firebase Auth custom claims,
and rewire the GoRouter to read the claim rather than inferring role from
collection-existence races.

## Root Cause (confirmed)
- `signUpCreatorProvider` creates the Firebase Auth user, then writes the
  `creator_profiles` doc. Between these two steps, `idTokenChanges` fires and
  the router reruns. At that instant `isCreatorProvider(uid) == false`,
  `isNormalUserProvider(uid) == false`, and `userStatsStreamProvider == null`,
  so the router falls through to "Normal User Onboarding" and redirects to
  `/onboarding/identity-studio`.
- Creator signup writes ONLY `creator_profiles`. Normal signup writes both
  `users` and `user_stats`. This asymmetry means a creator has no `users` doc
  even after signup, so the redirect logic is structurally fragile.

## Success Criteria (each must be verifiable)
1. A fresh creator signup (`/creator/signup` → `/creator/verify-email` →
   `/creator/dashboard`) never visits any `/onboarding/*` route at any point
   during the flow, including during the Firestore-write race window.
2. A fresh normal-user signup still reaches `/onboarding/identity-studio`
   exactly as today.
3. The router decision is driven by a `role` custom claim on the Firebase
   Auth user; collection-existence checks are not used for routing.
4. Firestore rules accept a `role` field on `users/{uid}` and
   `creator_profiles/{uid}` without privilege escalation.
5. A Cloud Function `setUserRole` callable writes the role custom claim
   AND mirrors it to the user doc.
6. Unit tests cover the router redirect decisions for: unauthenticated,
   normal user mid-onboarding, normal user post-onboarding, creator
   unverified email, creator verified email, creator signup in flight,
   stale claim during creator signup.

## Constraints
- No new third-party dependencies.
- Must compile on Flutter stable (current pubspec baseline).
- Existing creator and normal-user flows must keep their visual designs.
- Role field can be written by client during signup but the custom claim
  must be set by Cloud Function (Admin SDK only).
- Firestore rules must continue to block privilege escalation for any
  other privileged fields (isAdmin, isPremium, etc.).
- Existing `isVerifiedCreator` flag and `creator_profiles` collection stay
  untouched — role is orthogonal to verification.

## Assumptions
- Firebase Functions are deployed to the same project as Firestore
  (verified: `.firebaserc` exists, `functions/src/index.ts` is active).
- The user accepts adding `role` as a non-privileged, self-writable field
  on `users/{uid}` (rules explicitly forbid `role` today — we relax only
  this single restriction, keep all others).
- Custom claims will propagate within ~1s after Cloud Function returns;
  client must call `user.getIdToken(true)` to force refresh.
- We will NOT migrate existing users in this ferment — they retain their
  current routing (backed by collection checks) until they next sign in,
  at which point the new flow takes over and writes their role claim.
- No production data is touched outside of `users/{uid}.role`,
  `creator_profiles/{uid}.role`, and Firebase Auth custom claims.

## Phases (single phase — tightly coupled change)

### Phase 1 — Fix routing for creator vs normal user

**Goal:** close the routing hole end-to-end so creators can never be sent
to normal-user onboarding.

**Steps:**

1. Add `setUserRole` callable Cloud Function
   (`functions/src/setUserRole.ts`) that sets the `role` custom claim via
   Admin SDK and mirrors it to `users/{uid}` and `creator_profiles/{uid}`
   fields. Export from `functions/src/index.ts`.
   Verify: `cd functions && npm run build` succeeds (or `tsc --noEmit`).

2. Add `role` field to `UserProfile` (`lib/features/auth/domain/entities/
   user_extension.dart`) and `CreatorProfile`
   (`lib/features/social/domain/entities/creator_profile.dart`); update
   `toMap` / `fromMap` / `copyWith`.
   Verify: `dart run build_runner build --delete-conflicting-outputs`
   succeeds for the affected .g.dart files.

3. Update `FirestoreAuthRepository.signUpWithEmailAndPassword` and
   `signInWithGoogle` to call `setUserRole('user')` after creating the
   auth user, then `getIdToken(true)` to refresh claims.
   Verify: existing auth unit tests still pass.

4. Update `signUpCreatorProvider` and `signUpCreatorWithGoogleProvider`
   in `lib/features/auth/presentation/providers/auth_providers.dart` to
   call `setUserRole('creator')` after writing the creator profile, then
   `getIdToken(true)`.
   Verify: unit-test stub confirms claim is set before `context.go`
   fires in the signup screen.

5. Add `currentUserRoleProvider` in `auth_providers.dart` that reads
   `FirebaseAuth.instance.currentUser?.getIdTokenResult()?.claims?['role']`
   and exposes `null | 'user' | 'creator'`. Auto-refresh on
   `idTokenChanges`.
   Verify: provider unit test with mocked `getIdTokenResult`.

6. Rewrite the redirect logic in `lib/core/router/router.dart`:
   - Determine `role` from `currentUserRoleProvider` (with Firestore
     fallback read of `users/{uid}.role` if claim is stale/null).
   - Add `/creator/verify-email` to the auth-screen allowlist for the
     creator branch so the race window can't redirect mid-signup.
   - Branch on role:
     - `creator` → if not verified → `/creator/verify-email`,
       else `/creator/dashboard` (block `/onboarding/*` and `/`).
     - `user` → block `/creator/*`; check onboarding progress and route
       to either the right onboarding step or `/`.
     - `null` (claim not yet propagated) → if on a creator signup path,
       hold and don't redirect; else fall through to current behavior.
   - Remove the `isNormalUserProvider` / `isCreatorProvider` collection-
     existence checks from the redirect hot path.
   Verify: redirect unit tests cover each branch (see success criterion 6).

7. Update Firestore rules (`firestore.rules`):
   - Allow `role` field on `users/{uid}` (set by Cloud Function or by
     self during signup; value restricted to 'user' or 'creator').
   - Allow `role` field on `creator_profiles/{uid}` (same restriction).
   - Keep all other privilege-escalation blocks intact
     (`isAdmin`, `isPremium`, etc.).
   Verify: `firebase emulators:exec --only firestore "true"` with the
   rules file loaded, or run the existing rules-test suite if present.

8. Add unit tests under `test/features/auth/` and
   `test/core/router/`:
   - Router redirect decisions (table-driven, one case per row of
     success criterion 6).
   - `setUserRole` callable (mock Admin SDK).
   - `currentUserRoleProvider` reads claims and listens to changes.
   Verify: `flutter test` for the new files passes.

## Risks / Edge Cases
- **Stale custom claim:** mitigate by `getIdToken(true)` after every
  `setUserRole` call; router also accepts `role` mirrored on Firestore
  as fallback when claim is still null.
- **Existing users without role:** their first login will not have a
  claim; the new `signIn` flow calls `setUserRole('user')` lazily on
  next sign-in. We add the call to `signInWithEmailAndPassword` and
  `signInWithGoogle` so it heals automatically.
- **Race during signup:** covered by step 6 — the router no longer
  redirects to `/onboarding/*` while `role` is unresolved AND the path
  is a creator signup screen.
- **Multiple tabs / back navigation:** the `refreshNotifier` already
  rebuilds on auth changes; we extend it to also listen on
  `currentUserRoleProvider`.

## Out of Scope
- Migrating existing creators' onboarding completion timestamps.
- Changing creator verification (`isVerifiedCreator`) workflow.
- Adding creator-specific onboarding screens beyond the verify-email
  step (the user has not asked for this; current creator flow goes
  straight from verify-email to dashboard, which matches the existing
  design).
- Web/iOS/Android build verification beyond `dart analyze` and unit
  tests — assume CI handles platform builds.

## Gates (P1/P2/P3)

**P1 — Verifiable success signals**
- Step 1: `cd functions && npx tsc --noEmit` exits 0.
- Step 2: `dart run build_runner build --delete-conflicting-outputs`
  exits 0.
- Steps 3-5: targeted `flutter test test/features/auth/` exits 0.
- Step 6: new `test/core/router/router_redirect_test.dart` exits 0
  with rows for each redirect branch.
- Step 7: rules-test command exits 0.
- Step 8: full `flutter test` exits 0.

**P2 — Phase ordering**
- Single phase; step ordering is: backend (1, 2, 7) → frontend wiring
  (3, 4, 5) → router rewrite (6) → tests (8). Step 6 depends on 1-5;
  step 8 depends on all prior steps. No independent parallel buckets.

**P3 — Evidence for complete_ferment**
- `functions/src/setUserRole.ts` exists and is exported from `index.ts`.
- `UserProfile.role` and `CreatorProfile.role` fields present, with
  updated `toMap` / `fromMap`.
- `flutter analyze` exits 0.
- `flutter test` exits 0, including the new router redirect test file.
- `firestore.rules` shows the `role` allowlist on the two collections.
- A run-through screenshot or trace of: creator signup → verify-email
  → dashboard with no `/onboarding/*` navigation in between (recorded
  via the existing test harness or a manual log capture).
