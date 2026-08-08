# Email Verification (Grace-Period) & Username Uniqueness — Design

**Date:** 2026-08-08
**App:** Emerge — Identity-First Habit Formation

---

## 1. Problem Statement

Three related gaps across the auth surface:

1. **Usernames are not unique.** The username is stored as `displayName` on `users/{uid}` and mirrored on Firebase Auth (`firebase_auth_repository.dart:154`), but nothing prevents two users from choosing the same name. The validator (`lib/core/utils/validators.dart:83`) checks format only (length, charset, blocked words) — not uniqueness. Duplicate names pollute leaderboards, tribe activity feeds, and friend resolution (`contact_resolver.dart:43`).
2. **Email uniqueness is enforced, but email ownership is never confirmed.** Firebase Auth rejects duplicate emails (`email-already-in-use` surfaced at `signup_screen.dart:105`), so the *uniqueness* half of the ask is already satisfied. There is no verification step: any email — including disposable/temp-mail — can create a working account. This matters because Emerge has real-money surfaces: affiliate/referral payouts (`lib/features/social/domain/services/club_activity_service.dart` etc.), sponsor rewards, and RevenueCat premium. Unverified accounts can farm referral credits and pollute the social graph.
3. **No email infrastructure exists.** `functions/package.json` has `axios`, `firebase-admin`, `firebase-functions` — no SMTP/transactional provider. No verification email, no welcome email.

### Scope decomposition (agreed)

This sub-project ships **#1 (verification)**, the first of four planned subsystems. Follow-ups (separate specs/plans):
- **Sub-project 2:** Web payments (Stripe/RevenueCat web) + order-complete confirmation.
- **Sub-project 3:** Email marketing flows (welcome drip, re-engagement), reusing the email helper built here.
- **Sub-project 4:** Feedback / rating popup (`in_app_review` + store deep link).

---

## 2. Goals & Non-Goals

**Goals**
- Every new email/password account must verify its email within a 7-day grace period, or login locks (account and data preserved).
- Google sign-in is exempt (Google already verifies emails) — code step skipped.
- Usernames become globally unique, case-insensitively, enforced server-side.
- Existing accounts backfilled deterministically.
- A "Welcome — you're verified" email fires on successful verification.
- All code paths testable per the project's TDD iron law.

**Non-Goals**
- No web payments, no marketing drip, no rating popup (separate sub-projects).
- No blocking of account *creation* on unverified email (grace-period model, not hard gate).
- No permanent account deletion on grace expiry — login locks, data kept.
- No change to the existing creator invite-code system (`creator_invites.ts` stays untouched).
- No change to the signup UX field set (username, email, password, confirm) — a verify screen is *added* after signup.

---

## 3. Data Model

Two new Firestore collections, both **functions-only** (rules deny client read/write, mirroring `creator_invite_codes`):

```
email_verifications/{uid}
  codeHash:    string          // SHA-256(salt + code), never the raw code
  codeSalt:    string
  expiresAt:   timestamp       // 10-minute TTL
  attempts:    number          // max 5 per code, then requires re-send
  lastSentAt:  timestamp
  resendCount: number          // 5/hour, 20/day
  createdAt:   timestamp
  verified:    bool

usernames/{usernameLowercase}
  uid:         string          // claims the name; doc id is the key
  claimedAt:   timestamp
```

Mirrored fields on the existing `users/{uid}` doc (server-written via Admin SDK):
- `emailVerified: bool`
- `emailLockedAt: timestamp` (set when the 7-day grace period expires)

Firebase Auth `emailVerified` flag is the **source of truth** (native flag, set by Admin SDK on code success — never via the client).

---

## 4. Cloud Functions — `functions/src/email_verification.ts`

Server-authoritative, modeled on `creator_invites.ts` (hash-at-rest, doc-as-lock, rules deny client access).

### 4.1 `sendEmailVerificationCode` (onCall)

1. Requires auth. Throws `unauthenticated` otherwise.
2. Rate-limit: `resendCount >= 5/hour` or `>= 20/day` → `resource-exhausted`.
3. Generate a 6-digit code from `CODE_CHARS` (`0-9`, no ambiguous chars needed — digits only, `Math.floor(Math.random()*10)` or `randomInt` from `node:crypto`, matching the repo's `randomInt` usage).
4. Store `{ codeHash: sha256(salt+code), codeSalt, expiresAt: now+10min, attempts: 0, ... }` in `email_verifications/{uid}` (merge).
5. Send email via Resend REST API (`POST https://api.resend.com/emails` using the existing `axios` dependency; `RESEND_API_KEY` from functions env, never client-visible).
6. Return `{ ok: true, expiresInSeconds: 600 }`.

### 4.2 `verifyEmailCode` (onCall)

1. Requires auth. Validates 6-digit numeric format (`invalid-argument`).
2. Read `email_verifications/{uid}`; missing or expired (`expiresAt < now`) → `not-found` / `failed-precondition` with re-send guidance.
3. `attempts >= 5` → `resource-exhausted`, require re-send.
4. Constant-time compare (`crypto.timingSafeEqual`) of `sha256(salt+submitted)` vs `codeHash`. On mismatch: increment `attempts`, throw `invalid-argument` ("wrong code").
5. On match (single-use): delete the code doc (or mark `verified: true` + clear hash) **and** in a transaction:
   - Admin SDK `updateUser(uid, { emailVerified: true })` — sets the Auth flag (the gate for the router).
   - `users/{uid}` merge: `{ emailVerified: true, emailLockedAt: FieldValue.delete() }` (clears any prior lock).
6. Fire-and-forget the "Welcome — you're verified" email (Section 7).
7. Return `{ ok: true }`.

### 4.3 `enforceEmailGracePeriod` (onSchedule, daily)

1. Query users created > 7 days ago with `emailVerified != true` (requires a composite index on `users` for `createdAt` + `emailVerified`; note index creation in the plan).
2. For each: merge `users/{uid}` `{ emailLockedAt: FieldValue.serverTimestamp() }`.
3. Re-verified users get the lock cleared by 4.2 step 5.

### 4.4 `claimUsername` (onCall)

1. Requires auth. Validate via the same rules as the Dart validator (3–30 chars, `[a-zA-Z0-9_-]`, no blocked words, no leading/trailing `_`/`-`) — server-side, mirrored from `lib/core/utils/validators.dart`.
2. Normalize: `username.trim().toLowerCase()`.
3. Transaction with doc-as-lock: `usernames/{normalized}` must not exist → create `{ uid, claimedAt }`. If it exists → `already-exists` ("Username taken").
4. On success: Admin SDK `updateUser(uid, { displayName: username })` + `users/{uid}` merge `{ displayName: username }` (server-authoritative claim).
5. Return `{ ok: true, username }`.

### 4.5 Shared email helper — `functions/src/email.ts`

```ts
export async function sendEmail(opts: {
  to: string;
  subject: string;
  html: string;
}): Promise<void>  // axios POST to Resend; throws on failure, logged
```

Reused by 4.1, 4.2 (welcome), and later sub-project 3.

---

## 5. Client Changes

### 5.1 Repository (`AuthRepository` / `FirebaseAuthRepository`)

New interface methods:
- `Future<Either<Failure, void>> sendEmailVerificationCode()`
- `Future<Either<Failure, void>> verifyEmailCode(String code)`
- `Future<Either<Failure, void>> claimUsername(String username)`
- `Future<Either<Failure, bool>> checkEmailVerified()`

`AuthUser` entity gains `emailVerified: bool` (default `false`), populated from `firebaseUser.emailVerified` in the `user` stream (`firebase_auth_repository.dart:59`). Map `FirebaseFunctionsException.code` → existing `Failure` types (e.g. `resource-exhausted` → rate-limit message).

### 5.2 Signup flow (unchanged shape, new step)

1. Existing `_signUp()` creates the account, profile, onboarding state (unchanged).
2. After profile creation, if `!user.emailVerified`: `context.go('/verify-email')` (replacing the direct onboarding navigation only for unverified accounts; Google sign-in and verified users skip straight to onboarding as today).
3. `claimUsername` is called as part of signup (after `signUpWithEmailAndPassword`). On `already-exists`, the form shows the validator message; the user edits the username and retries (re-claim + `updateDisplayName`), or abandons via existing `deleteMyAccount`.

### 5.3 Router — pure enforcement

Extend `RedirectContext` (`lib/core/router/router.dart:77`) with:
- `emailVerified: bool?`
- `emailLockedAt: DateTime?`

New `decideRedirect` branch (pure, follows the existing TDD pattern, **no `ref.watch` inside redirect**): authenticated + role `user` + `emailVerified == false` → hold current path, redirect to `/verify-email`. When `emailLockedAt != null`, the same screen renders in "locked" mode (with re-send + code entry). Verified users pass through to the shell as today.

Watch `emailVerified` outside the redirect closure (e.g. the auth stream / user provider), `ref.read` inside with `try/catch` returning `null` on failure (web DDC race guard, per AGENTS.md).

### 5.4 `VerifyEmailScreen` (new, top-level route `/verify-email`)

- Shows the account email, a 6-digit OTP field, "Send code" (auto-fires on entry, cooldown timer for re-send), "wrong code / expired / locked" states with actionable copy, and a "verified" success state that resumes the held path (`context.go` to the held location or onboarding).
- Styling follows `signup_screen.dart` (glass surface, `EmergeColors`, `ResponsiveLayout` for tablet).
- Reads held path from the router state so the user returns where they were headed.

### 5.5 Settings (optional surface, low-risk)

A small "Verify your email" tile in Settings when `emailVerified == false`, navigating to `/verify-email`.

---

## 6. Firestore Rules

Add to `firestore.rules` (both collections deny client access, matching `creator_invite_codes`):

```firestore
match /email_verifications/{uid} {
  allow read, write: if false;
}

match /usernames/{username} {
  allow read, write: if false;
}
```

---

## 7. Post-Verification Email

On `verifyEmailCode` success, fire `sendEmail` with a "Welcome to Emerge — you're verified" HTML template (branded, minimal). This is the seam where sub-project 3 hooks the marketing drip later; the helper is shared so no rework.

---

## 8. Backfill (existing users)

New script `functions/src/backfill_usernames.ts` (one-off, run via `npm run` script or a guarded callable):
- For each `users/{uid}` with a non-empty `displayName`, create `usernames/{displayName.trim().toLowerCase()}` → `{ uid }`.
- On collision: deterministic suffix `_2`, `_3`, … (retry until free). First-come-first-served by `createdAt` ordering.
- Idempotent: skips names already claimed by the same uid.

---

## 9. Error Handling & Security

- **Codes:** hashed + salted at rest (never stored plaintext), constant-time compare, single-use, 10-min TTL, 5-attempt cap, rate-limited resend (5/hr, 20/day). Attacker cannot brute-force a 6-digit code within the TTL (10^6 space, 5 attempts, constant-time).
- **Secrets:** `RESEND_API_KEY` in functions env/config only — never in client code or Firestore rules.
- **Username squatting:** doc-id-as-lock transaction; claim and displayName write are the same atomic operation; no client-write path exists (rules deny).
- **Grace lock:** server-written `emailLockedAt`; client only reads it. Re-verification clears it atomically.
- **fpdart:** all repository returns are `Either<Failure, T>`; Cloud Function errors map to user-facing messages via `.fold`.

---

## 10. Testing (TDD Iron Law)

Order: failing test → watch fail → minimal implementation → refactor. No production code without a failing test first.

### Cloud Functions (jest + `firebase-functions-test`, mirroring existing CF tests)
- `sendEmailVerificationCode`: rate limits (5/hr, 20/day), TTL fields set, hash≠raw code, unauth denied.
- `verifyEmailCode`: success sets Auth `emailVerified` + Firestore mirror + clears lock; wrong code (attempts increment, fail at 5); expired code; already-used code; unauth denied.
- `claimUsername`: success claims + displayName; duplicate → `already-exists`; normalization (`  Foo_ ` → `foo_`); validation rejections (short, bad chars, blocked word).
- `enforceEmailGracePeriod`: locks users past 7 days, skips verified.

### Pure Dart (no Firebase — the project's signature pattern)
- `usernameNormalize` / validation mirroring `AppValidators` (extract shared rules into a pure, testable module if needed).
- `decideRedirect` new branches in `test/core/router/router_redirect_test.dart`: unverified → `/verify-email` (path held); locked → same screen locked mode; verified → shell; Google/creator unaffected.

### Widget / screen
- `VerifyEmailScreen` states: idle, sending, wrong code, expired, locked, verified→navigate.
- Signup: verified skip vs. unverified redirect.

### Verification commands (run focused, never the full suite — AGENTS.md)
- `flutter test test/core/router/router_redirect_test.dart`
- `flutter test test/features/auth/...`
- `cd functions && npm test -- email_verification`
- `flutter pub run build_runner build` if Riverpod providers change
- `dart analyze` / `cd functions && npm run lint`

---

## 11. Rollout & Operations

1. Deploy functions (`firebase deploy --only functions`), including `RESEND_API_KEY` config and the new composite index on `users`.
2. Run `backfill_usernames` once.
3. Release app update (web + stores).
4. Verify: signup a fresh email/password account → code arrives → verify → welcome email → after (optionally shortened, dev) grace period, login locks.
5. Sub-project 3 (marketing drip) later reuses `email.ts`.

---

## 12. Open Items / Assumptions

- **Resend** free tier (3,000/mo, 100/day) is the chosen provider — confirmed by the developer. API key provisioning is ops, not code.
- Composite index `users (createdAt asc, emailVerified asc)` required by `enforceEmailGracePeriod` — create during function deploy.
- Grace period is a hard-coded 7 days in the scheduled function; consider a `RemoteConfig`/env value only if a later change asks for it (YAGNI now).
- Google sign-in path (web redirect + native) remains unchanged; its accounts are considered verified at creation (Firebase sets `emailVerified` for Google federated accounts).
