# SP-E Design — Creator Invite-Code System + Creator Creation Rights

> **Date:** 2026-08-01
> **Status:** Draft (design review pending)
> **Scope:** SP-E of an 8-sub-project program (A→H). Server + rules + client: two new Cloud Functions (`generateCreatorInviteCode`, `redeemCreatorInvite`, `ensureCreatorTribe`), `firestore.rules` changes, creator signup gated by invite codes, verified-creator write rights on `blueprints` / `challenges` / `tribes`, a default creator account seed script, and a dashboard-bounce fix.
> **Predecessor work:** `2026-06-18-creator-auth-separation-design.md`, `2026-06-19-creator-login-hardening-design.md`, `2026-06-23-creator-routes-design.md`, `2026-06-13-creator-tribes-data-layer.md`.

---

## 1. Goals

1. **Default creator account** exists with access to an **invite-code generator** — new creators can only become creators by redeeming a code.
2. **Verified creators** (redeemed an invite) can **create challenges, blueprints, and creator tribes** — end-to-end, with production Firestore rules that actually permit it.
3. **Fix the broken creator system** discovered while designing: client signup writes are denied by rules (`ownerId` mismatch), `setUserRole` rejects non-admin role promotion, and the dashboard bounces fresh signups back to login.

## 2. Current state (verified 2026-08-01) — the creator system is broken end-to-end

| # | Defect | Evidence |
|---|---|---|
| C1 | Creator login gates on `creator_profiles/{uid}` existing (`isCreatorProvider`, `auth_providers.dart:76-82`); non-creator → sign-out + snackbar | `creator_login_screen.dart:54-63` |
| C2 | Signup calls `setUserRole {role: 'creator'}`; function requires `callerToken.admin === true` for any role ≠ 'user' — client swallows the error and falls back to the Firestore mirror | `setUserRole.ts:52-56`; `auth_providers.dart:121-133` |
| C3 | Rules deny the client's `creator_profiles` create: rule requires `request.resource.data.ownerId == request.auth.uid` (`firestore.rules:514`) but `CreatorProfile.toMap()` never writes `ownerId` (it writes `userId`) — signup writes are **denied in prod**. Comment at `firestore.rules:506-511` claims `creator_*` docs are writable by any auth user — not implemented for the owner path | `creator_profile.dart:93-118`, `firestore.rules:512-517` |
| C4 | Dashboard scaffold hard-redirects to `/creator/login` when `isVerifiedCreatorProvider` resolves false — a fresh signup (`isVerifiedCreator: false`) loops back to login | `creator_dashboard_scaffold.dart:17-23`, `creator_auth_provider.dart:5-12` |
| C5 | `blueprints` create/update/delete are admin-only (`firestore.rules:501-504`); the creator blueprint builder writes client-side → denied in prod | `blueprint_builder_screen.dart:245-309` |
| C6 | `challenges` create/update/delete are admin-only (`firestore.rules:408-410`); the Tribe tab's "Create Challenge" card is a "launching soon" snackbar stub | `creator_tribe_management_tab.dart:166-177` |
| C7 | `isValidTribe` requires `archetypeId ∈ {athlete, scholar, stoic, creator, zealot, mystic}` + `type ∈ {official, brand, userPrivate, userPublic}` (`firestore.rules:68-86, 363`) — a creator tribe with null `archetypeId` **cannot be created** by any client | `firestore.rules:363` |
| C8 | The blueprint builder promises "Publish a blueprint to automatically create your creator tribe" (`creator_tribe_management_tab.dart:397-399`) — **not implemented**; no tribe is created on publish, `creatorTribeId` never set | `blueprint_builder_screen.dart:245-309` |
| C9 | Friendship invite pattern (`friend_repository.dart:288-348`): 6-char code in `invite_codes/{code}`, single-use by delete, non-atomic (race). **`invite_codes` has no Firestore rules block → all client access is denied — the friendship invite is broken in prod too.** Do NOT copy this pattern as-is | `firestore.rules` (no `invite_codes` match block) |
| C10 | On-device seeds write `creator_profiles` client-side (`seedCreatorsIfEmpty`, `creator_repository.dart:73-193`, ids like `creator_aria_chen`; `blueprintCount` increment at `blueprint_repository.dart:635-654`) — rules changes must keep the `creator_`-prefix carve-out or these break | `creator_repository.dart:73-193` |

**Verified environment facts (differ from the task brief — see report):**
- Creator feature code lives under `lib/features/social/` (not `lib/features/creator/`): `lib/features/social/presentation/screens/creator/*`.
- `CreatorProfile` model: `lib/features/social/domain/entities/creator_profile.dart`; `CreatorRepository`: `lib/features/social/data/repositories/creator_repository.dart`.
- `isVerifiedCreatorProvider` exists **twice**: `lib/features/auth/presentation/providers/creator_auth_provider.dart:5` (used by the scaffold) and `lib/features/social/presentation/providers/creator_provider.dart:17`.
- `Blueprint` model **already has** `creatorTribeId` (`blueprint.dart:99`) — no model change needed for D5.
- `Challenge` model has **no `createdBy`** (`challenge.dart`) — must be added for D4.
- Creator onboarding persists `creator_profiles` **client-side** (`creator_onboarding_provider.dart:123`) — this constrains D4 (see §4.2).
- Functions test tooling: **jest + ts-jest + firebase-functions-test (offline)**; tests live in `functions/test/*.test.ts`; `npm test` = `jest --coverage` with `collectCoverageFrom: lib/**/*.js` and tests `require("../lib/index")` → **`npm run build` must run before `npm test`**.
- `firestore.rules` is 594 lines; helpers `isAuthenticated` (:7), `isOwner` (:12), `isAdmin` (:17), `isValidTribe` (:68), `isValidCreatorProfile` (:94).
- `functions/src/index.ts` exports `setUserRole`, `seedOnboardingCatalog` (from `seed_starter_habits.ts`), etc.; `seed_templates.ts` and `seedReviewerAccount.ts` exist but are **not exported** (commented at `index.ts:255-258`). `seed_starter_habits.ts:405-418` shows the `ADMIN_SECRET` Bearer-token guard pattern; `seedReviewerAccount.ts` shows the secrets-based account seed (`REVIEWER_EMAIL`/`REVIEWER_PASSWORD`).
- Emulators configured in `firebase.json`: auth 9099, functions 5001, firestore 8080, hosting 5000, UI 4000.

## 3. Recorded design decisions

| # | Decision | Choice |
|---|---|---|
| D1 | Invite-code model | New collection **`creator_invite_codes/{code}`**: `{creatorUid, createdAt, expiresAt, redeemedBy: null\|uid}`. Server-authoritative: two callables in `functions/src/creator_invites.ts`. `generateCreatorInviteCode` — caller must be a **verified creator** (claim `role=='creator'` AND `creator_profiles/{uid}.isVerifiedCreator==true`, checked server-side; never trust the client); 8-char code from an ambiguity-free alphabet; rate-limit: max **10 outstanding** per creator (const). `redeemCreatorInvite` — validates code exists / not expired / not redeemed; **atomically** (Firestore transaction) marks `redeemedBy` + deletes the code; creates `creator_profiles/{uid}` with `isVerifiedCreator: true`, `role: 'creator'`; sets custom claim `role=creator` via `admin.auth().setCustomUserClaims`; returns success. Redemption requires the invitee to be the **caller** (`auth.uid`) and **not already a creator**. |
| D2 | Default creator account | **CONFIRM-WITH-USER** (two options): (a) seed a known default account (email/password) via a one-off admin script (`seedCreatorAccount.ts`, modeled on the unexported `seedReviewerAccount.ts` precedent, guarded by `ADMIN_SECRET`, secrets `CREATOR_EMAIL`/`CREATOR_PASSWORD`) — credentials delivered out-of-band; the script also creates the profile doc + claim + optionally one ready invite code; (b) the first creator is promoted manually by an admin (run `setUserRole` with an admin token + set `isVerifiedCreator: true` via console). **Recommendation: (a)** — deterministic, matches the `ADMIN_SECRET` seed family. |
| D3 | Signup flow change | Creator signup becomes **invite-gated**: email/password + invite-code field. Flow: **create auth user → call `redeemCreatorInvite` with the code (auth user must exist first — the callable needs `auth.uid`) → server creates `creator_profiles` → `getIdToken(true)` → done**. The old client-side `creator_profiles` write (`auth_providers.dart:111-119`) is **removed** (rules will block client create anyway — the server owns the doc). `isVerifiedCreator` defaults **true** for invite-redeemed creators → no dashboard bounce. Google creator signup gets the same gate (persist the code in SharedPreferences alongside `pending_creator_signup` before the web redirect; redeem on return). |
| D4 | Rules changes | See §4.2 for the exact rule shapes. `creator_invite_codes`: client denied entirely (functions only). `creator_profiles`: create = admin-only (function owns creation) + keep the `creator_`-prefix dev-seed carve-out; **update = owner-allowed restricted to a non-privileged key whitelist** (this keeps the creator onboarding flow working — `creator_onboarding_provider.dart:123` — which the "update admin-only" reading of the brief would break); read public; delete admin-only. `blueprints`: creator write when `creatorUserId == auth.uid` **and** the caller is a verified creator; admin stays. `challenges`: creator write when `createdBy == auth.uid` (+ add `createdBy` to the `Challenge` model — verified absent); admin stays. `tribes`: `isValidTribe` relaxed so `type == 'creator'` permits a missing `archetypeId`; verified-creator requirement for creator-type tribes. |
| D5 | Creator tribe auto-creation | Publishing a blueprint (creator flow) **auto-creates (or reuses)** the creator's tribe via callable **`ensureCreatorTribe`**: `tribes` doc `{type: 'creator', name: <profile displayName>, createdBy: uid, members: [uid], memberCount: 1, archetypeId: <profile archetype or absent>}`; sets `creator_profiles/{uid}.tribeId` and `blueprints/{id}.creatorTribeId`. Callable (not client-side) — atomic, returns `tribeId`, avoids client races. The tribe tab already renders from `creatorProfileProvider(uid)` → `tribeId` → `realTimeTribeStatsProvider` (`creator_tribe_management_tab.dart:17,112`), and `getUserTribes` matches `members` arrayContains (`tribe_repository.dart:219-224`), so the new tribe appears immediately. |
| D6 | Dashboard bounce fix | Invite-redeemed creators have `isVerifiedCreator: true` → no bounce. Additionally fix `creator_dashboard_scaffold.dart:17-23` to **not hard-redirect while `isVerifiedCreatorProvider` is loading** (guard on `next.isLoading` / skip redirect while the profile doc hasn't resolved). |
| D7 | Blueprint builder `_submit` | After the D4 rules land, the client write succeeds for verified creators. `_submit` additionally calls `ensureCreatorTribe({blueprintId})` after `createBlueprint` and updates local UI state. |
| D8 | Out of scope | Per-tribe blueprint content curation (SP-F), XP/leaderboards (SP-G), rate-limiter cleanup (SP-H may fold the invite rate limit in). |

### Decisions beyond D1–D8 (made in this spec; flag if you disagree)

| # | Decision |
|---|---|
| E1 | **Minimal "Create Challenge" UI** replaces the "launching soon" stub (`creator_tribe_management_tab.dart:166-177`): a small dialog (title, description, category, total days) writing `challenges/{autoId}` via a new `ChallengeRepository.createCatalogChallenge` method (existing `createSoloChallenge` writes to `users/{uid}/challenges` progress — **different collection**, verified in `drift_challenge_repository.dart:221-245`). Required so "verified creators can make challenges" is true end-to-end, not just in rules. |
| E2 | **`Challenge.createdBy` (String?) + `createdAt`** added to the model (backward-compatible; catalog challenges keep `createdBy` null). |
| E3 | **`CreatorProfile.toMap()` gains `ownerId: userId`** — fixes the C3 mismatch and makes the owner-update rule match for docs created by the redeem function. Backfill: existing prod `creator_profiles` docs (seeded system creators have no `ownerId`) are covered by the `creator_`-prefix carve-out; the seed script / a small migration backfills `ownerId` for any other docs. |
| E4 | **Outstanding-code counting** queries `creator_invite_codes` by `creatorUid` and filters `redeemedBy == null` **in memory** — Firestore queries cannot filter `== null`. Redeemed codes are deleted, so in practice all docs under a `creatorUid` are outstanding. |
| E5 | Redeeming is allowed even if the invitee already has a `users/{uid}` doc (normal user converts; their `users` doc stays, the `role` claim 'creator' wins in `currentUserRoleProvider` resolution order — claim → users mirror → inference, `role_provider.dart:58-109`). |
| E6 | Normal users may **not** call `generateCreatorInviteCode`, may not create `blueprints`/`challenges` as creators, and may not self-verify: `isVerifiedCreator` can only be set by the redeem function or an admin. |

## 4. Architecture

### 4.1 Layering

```
Flutter client                          Cloud Functions (admin SDK)          Firestore
─────────────────                       ─────────────────────────────        ─────────
CreatorSignUpScreen ── signUpCreator ──► auth.createUserWithEmailAndPassword (client SDK)
  (email/pw + code)        │
                           └─ redeemCreatorInvite({code, displayName}) ──► transaction:
                                auth.uid must not be a creator                1. get code doc
                                code must exist/not expired/not redeemed       2. set redeemedBy + delete
                                ──► creator_profiles/{uid} created            3. create creator_profiles
                                ──► setCustomUserClaims({role:'creator'})       (isVerifiedCreator: true)
                           └─ getIdToken(true)

CreatorDashboard (verified)
  BlueprintBuilder ── createBlueprint (client, now allowed by rules)
                        └─ ensureCreatorTribe({blueprintId}) ──► find-or-create tribes/{id}
                             (type:'creator', members:[uid])      set creator_profiles.tribeId
                                                                  set blueprints.creatorTribeId

Default creator (seedCreatorAccount, ADMIN_SECRET) ──► auth user + profile (verified)
                                                        + claim + 1 ready invite code
```

### 4.2 Flow diagrams (text)

**Generate flow** (default creator, then any verified creator):

```
creator taps "Generate invite code"
  → httpsCallable('generateCreatorInviteCode').call({})
  → [auth.uid present? else unauthenticated]
  → server: admin.auth().getUser(uid) → customClaims.role === 'creator'?   (never trust client)
  → server: creator_profiles/{uid} exists && isVerifiedCreator === true?    (else permission-denied)
  → server: count outstanding codes where creatorUid == uid (in-memory filter)
  → count >= 10 → resource-exhausted ("You have 10 outstanding invite codes")
  → code = 8 chars from "ABCDEFGHJKLMNPQRSTUVWXYZ23456789" (no 0/O/1/I/L), collision-retry (≤5)
  → set creator_invite_codes/{code} {creatorUid, createdAt: serverTimestamp,
      expiresAt: now + 7 days, redeemedBy: null}
  → return {code}
```

**Redeem flow** (new creator signup):

```
user submits signup form (email, password, username, invite code)
  → client SDK createUserWithEmailAndPassword + updateDisplayName
  → httpsCallable('redeemCreatorInvite').call({code, displayName})
  → [auth.uid present? else unauthenticated]
  → [code format ^[A-Z2-9]{8}$? else invalid-argument]
  → [creator_profiles/{uid} exists OR claim role === 'creator'? else already-exists]
  → transaction:
      read creator_invite_codes/{code}          (missing → not-found)
      redeemedBy != null                        (→ failed-precondition "already used")
      expiresAt < now                           (→ failed-precondition "expired")
      set {redeemedBy: uid, redeemedAt} + delete the code doc
      set creator_profiles/{uid} {userId, ownerId, role:'creator', displayName,
          isVerifiedCreator: true, bio:'', specialityTags:[], blueprintCount:0,
          creatorOnboardingProgress:0, archetype:'none', createdAt}
  → setCustomUserClaims(uid, {...existing, role:'creator'})
  → return {ok:true}
  → client: getIdToken(true) → navigate to /creator/dashboard (profile verified → no bounce)
```

**Publish flow** (verified creator):

```
creator taps "EMIT TO WORLD" (blueprint builder _submit)
  → client write blueprints/{autoId} {creatorUserId: uid, isCreatorBlueprint: true, ...}
      [rules: verified creator && creatorUserId == auth.uid → allowed]
  → httpsCallable('ensureCreatorTribe').call({blueprintId})
  → [verified creator? else permission-denied]
  → query tribes where createdBy == uid && type == 'creator' (limit 1)
  → none: create tribes/{autoId} {name: "<displayName>'s Tribe", type:'creator',
      createdBy: uid, members:[uid], memberCount:1, archetypeId: <profile archetype>}
      + set creator_profiles/{uid}.tribeId (merge)
  → exists: reuse tribeId
  → blueprintId provided && blueprint.creatorUserId == uid → set blueprints/{id}.creatorTribeId
  → return {tribeId}
  → client: refreshes tribe tab / blueprints tab
```

### 4.3 Component specs

#### 4.3.1 `functions/src/creator_invites.ts` (new)

Shared helpers:

```ts
const CODE_CHARS = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"; // no 0/O/1/I/L
const CODE_LENGTH = 8;
const CODE_TTL_MS = 7 * 24 * 60 * 60 * 1000;            // 7 days
const MAX_OUTSTANDING_CODES = 10;
const CODE_PATTERN = /^[A-Z2-9]{8}$/;

async function isVerifiedCreator(uid: string): Promise<boolean> {
  const [userRecord, profile] = await Promise.all([
    admin.auth().getUser(uid),
    admin.firestore().collection("creator_profiles").doc(uid).get(),
  ]);
  const claims = userRecord.customClaims ?? {};
  return (
    claims.role === "creator" &&
    profile.exists &&
    profile.data()?.isVerifiedCreator === true
  );
}
```

**`generateCreatorInviteCode`** (onCall): auth required; `isVerifiedCreator(auth.uid)` or `permission-denied`; outstanding count via `collection("creator_invite_codes").where("creatorUid", "==", uid).get()` + in-memory `redeemedBy == null` filter (see E4); ≥ `MAX_OUTSTANDING_CODES` → `resource-exhausted`; generate code with collision retry loop (≤5, then `internal`); write doc; return `{code}`.

**`redeemCreatorInvite`** (onCall): auth required; normalize `data.code` (trim, uppercase); pattern check → `invalid-argument`; already-a-creator checks (profile doc exists OR existing claim `role === 'creator'`) → `already-exists`; then `db.runTransaction` (reads-before-writes): missing code → `not-found`; `redeemedBy != null` → `failed-precondition` ("already used"); `expiresAt.toMillis() < Date.now()` → `failed-precondition` ("expired"); `tx.set(codeRef, {redeemedBy: uid, redeemedAt: serverTimestamp}, {merge: true})` **and** `tx.delete(codeRef)`; `tx.set(profileRef, {...})` (full profile, `isVerifiedCreator: true`). After the transaction: `setCustomUserClaims(uid, {...existing, role: "creator"})`; return `{ok: true, uid}`. (Set + delete in the same transaction is the doc-as-lock: if the delete is retried/undone the `redeemedBy` marker still blocks reuse.)

**`ensureCreatorTribe`** (onCall): auth required; `isVerifiedCreator(auth.uid)` or `permission-denied`; optional `data.blueprintId` (string, non-empty); find-or-create tribe (see flow above); set `creator_profiles/{uid}.tribeId` (merge) when created; if `blueprintId` given and `blueprints/{id}.creatorUserId === uid` → merge `{creatorTribeId: tribeId}`; return `{tribeId, created}`.

Export all three from `functions/src/index.ts` (`export * from "./creator_invites";`).

#### 4.3.2 `functions/src/seedCreatorAccount.ts` (new — D2, CONFIRM-WITH-USER for option (a))

Modeled on `seedReviewerAccount.ts` + `seed_starter_habits.ts` guard:

```ts
export const seedCreatorAccount = onRequest({
  secrets: ["CREATOR_EMAIL", "CREATOR_PASSWORD"],
}, async (req, res) => {
  // 1. Authorization: Bearer token === process.env.ADMIN_SECRET (403 otherwise)
  // 2. getRequiredEnvVar CREATOR_EMAIL / CREATOR_PASSWORD
  // 3. auth.getUserByEmail → update password/displayName; or createUser (emailVerified: true)
  // 4. setCustomUserClaims(uid, {role: 'creator'})
  // 5. creator_profiles/{uid}.set({userId, ownerId: uid, role:'creator',
  //      displayName, isVerifiedCreator: true, blueprintCount: 0,
  //      creatorOnboardingProgress: 3, creatorOnboardingCompletedAt: now,
  //      archetype: 'creator', createdAt})   // onboarding marked complete → dashboard reachable
  // 6. create one ready invite code in creator_invite_codes (7-day TTL)
  // 7. respond {ok: true, uid, inviteCode}
});
```

Export is **commented out by default** in `index.ts` (mirror the `seedReviewerAccount` precedent at `index.ts:258`) — deploy it explicitly when bootstrapping, or keep it exported behind `ADMIN_SECRET` (the guard makes public exposure safe; `seedOnboardingCatalog` is exported unguarded-by-default too — follow that precedent). `ADMIN_SECRET` must be set as a function secret/env before deploy. Credentials are delivered out-of-band (never committed).

#### 4.3.3 `firestore.rules` (D4)

Add helpers next to `isAdmin` (`firestore.rules:17`):

```
// Verified creator: role claim 'creator' AND a verified creator_profiles doc.
// NOTE: get() on a missing doc makes the rule evaluate to an error → deny.
function isVerifiedCreator() {
  return isAuthenticated() &&
         request.auth.token.role == 'creator' &&
         get(/databases/$(database)/documents/creator_profiles/$(request.auth.uid)).data.isVerifiedCreator == true;
}
```

**`creator_invite_codes`** (new block, before `blueprints` at :501):

```
match /creator_invite_codes/{code} {
  allow read, write: if false;   // functions only (admin SDK bypasses rules)
}
```

**`creator_profiles`** (replace :512-517):

```
match /creator_profiles/{profileId} {
  allow read: if true;
  // Server owns creation (redeemCreatorInvite). Keep the on-device dev-seed
  // carve-out for system profiles (ids like creator_aria_chen).
  allow create: if isAdmin() || (profileId.startsWith('creator_') && isAuthenticated());
  // Owner may maintain their profile (onboarding steps) but NEVER flip
  // verification/role/identity fields. isValidCreatorProfile (:94) keeps
  // rejecting privileged fields.
  allow update: if isAdmin() ||
    (isAuthenticated() && resource.data.ownerId == request.auth.uid &&
     isValidCreatorProfile(request.resource.data) &&
     !request.resource.data.diff(resource.data).affectedKeys()
       .hasAny(['ownerId', 'userId', 'role', 'isVerifiedCreator'])) ||
    (profileId.startsWith('creator_') && isAuthenticated());
  allow delete: if isAdmin();
}
```

Onboarding writes (`creator_onboarding_provider.dart:123`) touch only `role`(unchanged value — `diff` counts it as affected only when it **changes**; it is set to the same 'creator' value, but to be safe the whitelist blocks it and onboarding must stop re-writing `role` — see §4.3.4), `archetype`, `bio`, `specialityTags`, `creatorOnboardingProgress`, `creatorOnboardingCompletedAt` — all non-privileged → allowed. The `setUserRole` mirror writes `role`/`roleUpdatedAt` server-side (admin SDK, unaffected).

**`blueprints`** (replace :501-504):

```
match /blueprints/{blueprintId} {
  allow read: if true;
  allow create: if isAdmin() ||
    (isVerifiedCreator() && request.resource.data.creatorUserId == request.auth.uid);
  allow update: if isAdmin() ||
    (isVerifiedCreator() && resource.data.creatorUserId == request.auth.uid &&
     request.resource.data.creatorUserId == request.auth.uid);
  allow delete: if isAdmin() ||
    (isVerifiedCreator() && resource.data.creatorUserId == request.auth.uid);
}
```

**`challenges`** (replace :408-410):

```
match /challenges/{challengeId} {
  allow read: if true;
  allow create: if isAdmin() ||
    (isVerifiedCreator() && request.resource.data.createdBy == request.auth.uid);
  allow update: if isAdmin() ||
    (isVerifiedCreator() && resource.data.createdBy == request.auth.uid);
  allow delete: if isAdmin() ||
    (isVerifiedCreator() && resource.data.createdBy == request.auth.uid);
  // participants subcollection unchanged
}
```

**`tribes`** (extend :68-86 and :361-372):

```
function isValidTribe(tribe) {
  return tribe.keys().hasAll(['name', 'type']) &&
         tribe.keys().size() <= 40 &&
         sanitizeString(tribe.name) &&
         tribe.name.size() <= 100 &&
         // archetypeId optional ONLY for creator tribes
         (!tribe.keys().hasAny(['archetypeId']) ||
            tribe.archetypeId in ['athlete', 'scholar', 'stoic', 'creator', 'zealot', 'mystic']) &&
         tribe.type in ['official', 'brand', 'userPrivate', 'userPublic', 'creator'] &&
         ... (rest unchanged) ...
}
```

```
match /tribes/{tribeId} {
  allow read: if isAuthenticated();
  allow create: if isAuthenticated() && isValidTribe(request.resource.data) &&
    (request.resource.data.type != 'creator' || isVerifiedCreator());
  allow update: ... unchanged (createdBy owner / admin / aggregate-only) ...
  allow delete: if isAdmin();
}
```

#### 4.3.4 Client changes

**`lib/features/auth/presentation/providers/auth_providers.dart`** — rewrite `signUpCreator` (currently :98-134):

```dart
@Riverpod(keepAlive: true)
Future<void> signUpCreator(Ref ref, String email, String password,
    String username, String inviteCode) async {
  final auth = ref.read(firebaseAuthProvider);
  final credential = await auth.createUserWithEmailAndPassword(
    email: email.trim(), password: password);
  final user = credential.user;
  if (user == null) throw Exception('User creation failed');
  await user.updateDisplayName(username.trim());

  // Server-side redemption creates creator_profiles + sets the role claim.
  // Removed: client write of creator_profiles (rules deny it) and the
  // setUserRole call (admin-gated, always rejected for non-admins).
  final functions = FirebaseFunctions.instance;
  await functions.httpsCallable('redeemCreatorInvite').call(<String, dynamic>{
    'code': inviteCode.trim().toUpperCase(),
    'displayName': username.trim(),
  });
  await user.getIdToken(true);
}
```

`signUpCreatorWithGoogle` (:136-197): add an invite-code parameter; on web persist `pending_creator_invite_code` in SharedPreferences next to `pending_creator_signup` (line ~146) and redeem after the redirect completes; native path redeems directly after `signInWithCredential`. Same removal of client profile write + `setUserRole`.

**`lib/features/auth/presentation/screens/creator_signup_screen.dart`** — add an invite-code `TextFormField` (uppercase, validator: 8 chars, pattern `^[A-Z2-9]{8}$` via `AppValidators` addition or inline) between Confirm Password and the submit button; pass it to `signUpCreatorProvider(...)` (:49-53).

**`lib/features/onboarding/presentation/providers/creator_onboarding_provider.dart`** — `saveCreatorOnboardingProgress` (:91-146) keeps writing client-side (allowed by the D4 whitelist); drop the `role: 'creator'` line from the merged update (:110, :113) so the `diff`-based whitelist is never tripped by a same-value rewrite. The `setUserRole` mirror call (:128-135) stays (it is admin-gated for `role:'creator'` — hmm, it passes `role: 'creator'` and will be rejected for non-admins, same as today; that path only exists to mirror progress onto the claim. Since SP-E removes reliance on it for signup, leave it best-effort OR remove it and let `creatorOnboardingProgress` live only in Firestore — **decision: remove the setUserRole mirror call** and rely on the Firestore profile; `currentCreatorOnboardingProvider` already reads the profile (`role_provider.dart:113-131`). Flag if you disagree.)

**`lib/features/social/presentation/screens/creator/creator_dashboard_scaffold.dart`** (D6) — guard the listener:

```dart
ref.listen(isVerifiedCreatorProvider, (_, next) {
  if (next.isLoading || !next.hasValue) return;   // hold during profile resolution
  if (!next.value! && context.mounted) {
    context.go('/creator/login');
  }
});
```

**`lib/features/social/presentation/screens/creator/blueprint_builder_screen.dart`** (D7) — in `_submit` (:280-293), after `repo.createBlueprint(blueprint)` returns the id, call `ensureCreatorTribe({blueprintId: id})` via `FirebaseFunctions.instance.httpsCallable('ensureCreatorTribe')`; store the returned `tribeId` on the local `Blueprint` (and optionally `ref.invalidate` the blueprints/tribe providers). Errors from the callable are non-fatal to the publish (snackbar already shows success); log a warning.

**`lib/features/social/domain/models/challenge.dart`** (E2) — add `final String? createdBy;` + `final DateTime? createdAt;` (copyWith, toMap, fromMap, props). No change to existing catalog rows (nullable).

**`lib/features/social/data/repositories/challenge_repository.dart`** (E1) — add `Future<String> createCatalogChallenge(Challenge challenge)` (Firestore impl): `challenges/{autoId}.set({...toMap(), createdBy: uid, createdAt})`. (Existing `createSoloChallenge` targets `users/{uid}/challenges` — do not reuse.)

**`lib/features/social/presentation/screens/creator/creator_tribe_management_tab.dart`** (E1) — replace the "Create Challenge" snackbar stub (:166-177) with a dialog (title, description, category dropdown from `ChallengeCategory`, total days) → `createCatalogChallenge` → success snackbar + invalidate challenges provider.

**`lib/features/social/domain/entities/creator_profile.dart`** (E3) — `toMap()` adds `'ownerId': userId`.

## 5. Data model

### 5.1 `creator_invite_codes/{code}` (new collection)

| Field | Type | Notes |
|---|---|---|
| `code` (doc id) | string | 8 chars, `[A-Z2-9]{8}` (no 0/O/1/I/L), uppercase |
| `creatorUid` | string | The verified creator who generated it |
| `createdAt` | timestamp | serverTimestamp |
| `expiresAt` | timestamp | `createdAt + 7 days` (const `CODE_TTL_MS`) |
| `redeemedBy` | string \| null | null until redeemed; set in the redeem transaction, then the doc is deleted |

Access: **no client access** (rule `if false`). Functions only.

### 5.2 `creator_profiles/{uid}` (modified)

- `ownerId: uid` — added by `CreatorProfile.toMap()` and by the redeem function (fixes C3; matches the existing update rule's `resource.data.ownerId` check).
- Created by `redeemCreatorInvite` with `isVerifiedCreator: true`, `role: 'creator'`, `creatorOnboardingProgress: 0`, `archetype: 'none'`. Onboarding then updates it client-side (whitelist-allowed). `tribeId` set by `ensureCreatorTribe`.

### 5.3 `blueprints/{id}` (modified)

- `creatorTribeId: tribeId` — already a model field (`blueprint.dart:99`), now actually set by `ensureCreatorTribe`.

### 5.4 `tribes/{id}` (new shape for creator tribes)

- `type: 'creator'` (new enum value), `createdBy: uid`, `members: [uid]`, `memberCount: 1`, `name: "<displayName>'s Tribe"`, `archetypeId` absent (or profile archetype). `isValidTribe` relaxed accordingly.

### 5.5 `challenges/{id}` (modified)

- `createdBy: uid` (new optional field), `createdAt` (new optional field). Catalog challenges unchanged.

## 6. File inventory

### New files

| Path | Responsibility |
|---|---|
| `functions/src/creator_invites.ts` | `generateCreatorInviteCode`, `redeemCreatorInvite`, `ensureCreatorTribe`, shared `isVerifiedCreator`/code helpers |
| `functions/src/seedCreatorAccount.ts` | D2 default creator account (ADMIN_SECRET + secrets), one ready invite code |
| `functions/test/creator_invites.test.ts` | Jest unit tests for the three callables (offline firebase-functions-test) |
| `functions/test/seedCreatorAccount.test.ts` | Guard/secret tests (if applicable) |
| `test/features/auth/presentation/screens/creator_signup_screen_test.dart` (extend) | Invite-code field + gated signup widget tests |

### Modified files

| Path | Change |
|---|---|
| `firestore.rules` | `isVerifiedCreator()` helper; `creator_invite_codes` deny block; `creator_profiles` create/update; `blueprints`, `challenges` creator rights; `isValidTribe` + `tribes` create |
| `functions/src/index.ts` | `export * from "./creator_invites";` (+ optionally export `seedCreatorAccount`) |
| `lib/features/auth/presentation/providers/auth_providers.dart` | `signUpCreator` / `signUpCreatorWithGoogle` rewritten (redeem callable, no client profile write, no `setUserRole`) |
| `lib/features/auth/presentation/screens/creator_signup_screen.dart` | Invite-code field + wiring |
| `lib/features/auth/presentation/providers/creator_auth_provider.dart` (or `social/presentation/providers/creator_provider.dart`) | (unchanged — verified flag already read from profile) |
| `lib/features/social/presentation/screens/creator/creator_dashboard_scaffold.dart` | Loading-guard on the verified listener |
| `lib/features/social/presentation/screens/creator/blueprint_builder_screen.dart` | `ensureCreatorTribe` call after publish |
| `lib/features/social/presentation/screens/creator/creator_tribe_management_tab.dart` | Create-Challenge dialog (replaces stub) |
| `lib/features/social/domain/models/challenge.dart` | `createdBy` + `createdAt` fields |
| `lib/features/social/data/repositories/challenge_repository.dart` (+ impl) | `createCatalogChallenge` |
| `lib/features/social/domain/entities/creator_profile.dart` | `toMap()` writes `ownerId` |
| `lib/features/onboarding/presentation/providers/creator_onboarding_provider.dart` | Drop `role` from the merge; remove the `setUserRole` mirror call (E-decision) |
| `lib/core/utils/validators.dart` | `validateInviteCode` (optional — inline validator is fine) |

## 7. Error handling & edge cases

| Case | Handling |
|---|---|
| Code not found / malformed | `not-found` / `invalid-argument` (format `^[A-Z2-9]{8}$`); client shows the message in the signup snackbar |
| Expired code | `failed-precondition` "This invite code has expired." (`expiresAt < now`, checked inside the transaction) |
| Double redeem (same code, two users) | Transaction serializes; second reader sees `redeemedBy != null` → `failed-precondition`. Non-atomic read-then-delete race (C9 pattern) is eliminated by the transaction + marker |
| Wrong-user redeem (caller ≠ intended recipient) | Not applicable — redemption binds to the caller (`auth.uid`); codes are single-use, so whoever redeems first gets it. (Documented limitation; the code is shared by the creator out-of-band, same as the friendship invite.) |
| Already a creator | Profile doc exists OR existing claim `role === 'creator'` → `already-exists` before the transaction (best-effort; the transaction's single-use code still prevents double-consumption) |
| Unverified user calls `generateCreatorInviteCode` | `permission-denied` (claim or profile check fails) |
| Rate limit | `resource-exhausted` at 10 outstanding codes per creator; UI shows "You have 10 outstanding invite codes — redeem or wait for expiry" |
| Code-generation collision | Retry loop (≤5) against doc existence; `internal` if exhausted (astronomically unlikely at 32^8 space) |
| Normal user converts | Allowed (E5); `users/{uid}` doc remains; claim `role:'creator'` wins in router resolution |
| Blueprint publish without tribe | `ensureCreatorTribe` non-fatal on failure (publish still succeeds; tribe created on next publish) |
| Firestore rules `get()` on missing profile | Rule errors → deny (verified-check is fail-closed). Signup always creates the profile before the client can act, so no false denies in the happy path |
| Dashboard profile briefly missing (cold start after redeem) | D6 loading-guard prevents the bounce while the profile resolves; if truly absent (deleted), the redirect still applies |
| Existing prod docs without `ownerId` | `creator_`-prefix carve-out covers system creators; redeem-created docs always carry `ownerId`; a one-off backfill is optional (only affects owner-updates of pre-existing docs) |

## 8. Testing strategy

### 8.1 Cloud Functions (jest + firebase-functions-test offline)

Follow the existing pattern in `functions/test/index.test.ts` (offline `firebase-functions-test`, call `.run({auth, data})`, assert `rejects.toHaveProperty("code", ...)`). **Build first**: `cd functions && npm run build && npm test` (tests `require("../lib/index")`; jest coverage collects from `lib/**/*.js`).

`functions/test/creator_invites.test.ts`:
- `generateCreatorInviteCode`: unauthenticated → `unauthenticated`; non-creator claim → `permission-denied`; verified claim but missing profile doc → `permission-denied`; happy path returns an 8-char `[A-Z2-9]` code and writes the doc; 10 outstanding → `resource-exhausted`; collision retry (pre-seeded doc id).
- `redeemCreatorInvite`: unauthenticated; bad format; unknown code → `not-found`; already redeemed (seeded `redeemedBy`) → `failed-precondition`; expired (seeded `expiresAt` in the past) → `failed-precondition`; already-a-creator (seeded profile) → `already-exists`; happy path — profile created with `isVerifiedCreator: true`, code doc deleted, claim set (assert via mocked `admin.auth().setCustomUserClaims`).
- `ensureCreatorTribe`: unauthenticated; unverified → `permission-denied`; happy path creates tribe with `members:[uid]`, `type:'creator'`, sets `creator_profiles.tribeId` and `blueprints.creatorTribeId`; second call reuses the same `tribeId`.

Mocks: seed Firestore docs via `firebase-functions-test`'s `firestore` wrapper or mock `admin.firestore()`/`admin.auth()` directly (the suite uses offline mode, so no emulator). `setCustomUserClaims` must be stubbed.

### 8.2 Firestore rules

**No rules test harness exists in the repo** (`firestore-tests/` only holds logs; no `@firebase/rules-unit-testing` dependency). Strategy:
- Manual/emulator verification steps in the plan (`firebase emulators:start` — auth 9099, functions 5001, firestore 8080; run the seed script, sign up with a code, publish a blueprint, create a challenge).
- Optional (not in scope): add `@firebase/rules-unit-testing` in a later sub-project (SP-H) — note it in Risks.

### 8.3 Flutter

- Widget tests (extend `test/features/auth/presentation/screens/creator_signup_screen_test.dart`): invite-code field validation (empty, wrong length, bad chars); submit flow calls the redeem callable (mock `FirebaseFunctions` via a fake `FirebaseFunctionsPlatform` or wrap the call in an injectable service — existing tests use `firebase_auth_mocks` + `fake_cloud_firestore`; the current `signUpCreator` swallows function errors, so tests already tolerate a no-emulator environment).
- `creator_dashboard_scaffold_test.dart`: loading state does not redirect; false → redirects to `/creator/login`.
- `creator_repository_test.dart`: `toMap()` now includes `ownerId`.
- Blueprint builder test: publish flow invokes `ensureCreatorTribe`.
- Challenge dialog test (new): creates a catalog challenge with `createdBy`.

## 9. Out of scope

- Per-tribe blueprint content curation (SP-F).
- XP/leaderboards for creator challenges/tribes (SP-G).
- Rate-limiter cleanup (SP-H may fold the invite rate limit into its work).
- `@firebase/rules-unit-testing` harness (recommended for SP-H).
- Fixing the **friendship** `invite_codes` flow (C9) — it is broken in prod, but SP-E ships a new, separate collection; the legacy collection stays untouched (flagging: a follow-up should either delete `invite_codes` or give it rules).
- Creator monetization, analytics, announcement/feed features in the tribe tab (existing stubs stay).
- Challenge **content** (steps editor etc.) beyond the minimal create dialog (E1).

## 10. Risks

| Risk | Mitigation |
|---|---|
| Rules change for `creator_profiles` update could break creator onboarding | Whitelist keeps every field onboarding writes; onboarding stops re-writing `role` (same-value rewrite would trip `diff`) — covered by §8.3 tests |
| `isVerifiedCreator` rules helper uses `get()` — missing doc → deny (fail-closed) | Redeem always creates the doc before the client can publish; login gate + D6 guard surface the broken state clearly |
| `ensureCreatorTribe` duplicates if two publishes race | Callable queries `createdBy == uid && type == 'creator'` then creates; a duplicate is still benign (the tab shows the first match); optionally make it a transaction in the implementation |
| Seed script leaks credentials | `ADMIN_SECRET` + secrets; credentials never committed; script export commented out by default (seedReviewerAccount precedent) |
| Existing dirty worktree (`firestore.rules` already modified) | Plan pre-flight: commit only files each task names; never `git add -A` |
| Query `where("redeemedBy", "==", null)` unsupported | Count by `creatorUid` only, filter in memory (E4) |
| `setUserRole` still rejects creator self-promotion — good (by design) | SP-E removes the client's reliance on it for signup; the mirror fallback in `role_provider.dart` remains for legacy accounts |
| Deploy ordering | Functions first, then rules, then client: old clients writing `creator_profiles` (removed in this SP) would be denied by new rules — acceptable, and the redeem flow never writes client-side |
