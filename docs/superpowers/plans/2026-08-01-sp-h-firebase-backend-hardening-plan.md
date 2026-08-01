# SP-H: Firebase Backend Hardening — Rules, Indexes, Functions — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the hardened `firestore.rules` package (creator writes, tribe counter validation, dead-guard removal), remove the dead Cloud Functions triggers, fix the broken premium gates (`generateAiRecap`, Paystack→claims sync), make `recalcTribes` respect actual membership, add the `creator_invites` callables that SP-E's client depends on, deploy, and verify against the emulator matrix + smoke checklist.

**Architecture:** Backend-only (no Dart client changes). The rules package is the main deliverable: it relaxes creator surfaces only for server-verified creators (`isVerifiedCreator()` helper backed by the `role='creator'` claim + a verified `creator_profiles` doc), hardens tribe aggregate updates with a memberCount ±1 diff constraint, and removes the dead `rateLimited()` guard. Functions: delete 3 dead triggers, fix 2 premium gates, fix recalc membership resolution, add `functions/src/creator_invites.ts` (SP-E D1/D5). Indexes: **zero additions** (verified — see design §4); the deploy step is a no-op there. All function changes carry jest unit tests (jest + ts-jest + firebase-functions-test offline); rules are verified via `firebase deploy --only firestore:rules --dry-run` plus an emulator matrix script.

**Tech Stack:** Firebase CLI 15.22.3 (global), Firestore rules v2, Cloud Functions Gen 2 (nodejs22, `us-central1`), TypeScript 5.9, jest 29 + firebase-functions-test 3.5, Node 22 `fetch` for the emulator check script. Project `tradeflash-l2966`, Firestore region `africa-south1`.

**Spec:** `docs/superpowers/specs/2026-08-01-sp-h-firebase-backend-hardening-design.md`

---

## ⚠️ Pre-flight (read first)

1. **The working tree is dirty** (pre-existing uncommitted changes across ~20+ files, including a `firestore.rules` working-tree edit: the `habit_completions` owner-delete allowance at `:322-326`, plus CRLF line-ending churn). **Commit only the files each task names** — never `git add -A` or `git add lib` wholesale. The rules edits in Tasks 2–4 build on the working-tree version of `firestore.rules` (594 lines), not HEAD.
2. **Firebase CLI:** global install at `C:\Users\HP\AppData\Roaming\npm\firebase`, v15.22.3 — supports `deploy --dry-run` (rules/indexes validation without deploying). `firebase login` must have access to `tradeflash-l2966`; run `firebase projects:list` to confirm.
3. **Sibling plans:** SP-B, SP-C, SP-D, SP-F plans are on disk; **SP-E has only a design spec** (`docs/superpowers/specs/2026-08-01-sp-e-creator-invites-design.md`) — its client changes may not exist yet. Task 10 (creator_invites) checks whether SP-E's plan/implementation has landed and adapts (ownership note in design §D3.1). SP-G's plan is not on disk; Task 9 (recalc) is SP-H's unless SP-G's plan ships it first.
4. **Functions test quirk:** `functions/test/*.test.ts` do `require("../lib/index")` — **`npm run build` must run before `npm test`** (SP-E spec confirms).
5. **Emulator config exists:** `firebase.json` already declares firestore 8080 / auth 9099 / functions 5001 / ui 4000, `singleProjectMode: true`.
6. **Deploy order note:** the rules package is safe to deploy before SP-E's client ships (it only denies more for non-verified-creator paths; every current client write is preserved — verified in the design §8 matrix). Deploy rules + functions together in Task 11.

## File structure

### New files

| Path | Responsibility |
|---|---|
| `functions/src/creator_invites.ts` | `generateCreatorInviteCode`, `redeemCreatorInvite`, `ensureCreatorTribe` (SP-E D1/D5) |
| `functions/test/creator_invites.test.ts` | Unit tests for the three callables (offline firebase-functions-test) |
| `functions/test/ai_recap.test.ts` | Premium-gate unit tests for `generateAiRecap` |
| `functions/test/paystack_claims.test.ts` | Claim-sync unit test for `paystackWebhook` |
| `functions/test/recalc_tribes.test.ts` | Resolved-membership aggregation tests for `recalcTribesInternal` |
| `scripts/rules_emulator_check.mjs` | Node script: Auth-emulator token + Firestore-emulator REST assertions for the rules matrix (no new npm deps) |

### Modified files

| Path | Change |
|---|---|
| `firestore.rules` | Remove `rateLimited()` (:35-40) + its `posts` uses (:440-441); `isValidStats` blocks `isPremium`/`premium_since`; `isValidTribe` relaxed (creator type, optional archetypeId); add `isVerifiedCreator()` helper; add `creator_invite_codes` deny block; replace `creator_profiles` (:512-517), `blueprints` (:501-504), `challenges` (:408-410), `tribes` (:361-372) blocks |
| `functions/src/index.ts` | Add `export * from "./creator_invites";`; remove `export * from "./rateLimiter";` (:261) |
| `functions/src/rateLimiter.ts` | **Deleted** |
| `functions/src/habit_notifications.ts` | Remove `onHabitChanged` (:260-374) + `notifyAchievement` (:426-452); keep `sendDailyInsights` + helpers |
| `functions/src/ai_recap.ts` | Premium gate reads `users/{uid}` (`isPremium` / `subscriptionStatus`) instead of `user_stats.isPremium` (:26-34) |
| `functions/src/payments/paystack.ts` | `charge.success`: merge custom claim `activeEntitlements: ['premium']` after the `users/{uid}` write (:130-140) |
| `functions/src/recalcTribes.ts` | Use resolved membership (explicit wins) for both `members` and XP aggregation (:69-105) |
| `functions/src/purgeOrphanedUserData.ts` | Remove `SYSTEM_PREFIXES = ["creator_"]` + skip logic (Task 11, after admin deletion) |
| `functions/test/index.test.ts` | Add assertions that `enforceRateLimit`/`onHabitChanged`/`notifyAchievement` are no longer exported |

### Admin work (Firebase Console, Task 11 — no code)

- Delete 12 seeded docs (SP-D D5): `creator_profiles/{creator_aria_chen, creator_marcus_okafor, creator_sora_tanaka, creator_julian_cross, creator_naia_singh, creator_elias_vance}`; `blueprints/{cb_aria_deep_work, cb_marcus_morning, cb_sora_creative, cb_julian_calm, cb_naia_devotion, cb_elias_studio}`
- Blueprints v1 purge (SP-F): docs with legacy archetype categories or `lh3.googleusercontent.com/aida-public/` imageUrls; fix `morning_3.imageUrl` → `https://images.unsplash.com/photo-1528715471579-d1bcf0ba5e83?w=800`

---

## Task 1: Pre-flight & baseline

**Files:** none (verification only)

- [ ] **Step 1: Confirm Firebase access**
```bash
firebase projects:list | grep tradeflash-l2966
firebase --version   # expect 15.22.3
```
Expected: project listed; CLI ≥ 15.x.

- [ ] **Step 2: Baseline the dirty tree**
```bash
cd "C:\Users\HP\Downloads\emerge_app" && git status --short | head -30
git diff -w firestore.rules | head -40
```
Expected: working-tree `firestore.rules` differs from HEAD only by the `habit_completions` delete allowance (+CRLF churn). Record `git rev-parse HEAD` as the rollback baseline.

- [ ] **Step 3: Baseline functions build + tests**
```bash
cd functions && npm run build && npm test
```
Expected: BUILD SUCCESSFUL; jest runs `index.test.ts`, `create_starter_pack.test.ts`, `paystack.test.ts`, `seed_starter_habits.test.ts` — all pass (note any pre-existing failures and record them; do not fix them in this task).

- [ ] **Step 4: Baseline the rules dry-run command**
```bash
firebase deploy --only firestore:rules --dry-run
```
Expected: validates the CURRENT rules file without deploying ("dry run of your deployment" — CLI 15.22.3 supports `--dry-run`). This confirms the lint loop used in Tasks 2–5 works.

- [ ] **Step 5: Commit**
```bash
git add functions/test/index.test.ts  # only if you edited it; otherwise skip
```
No commit for this task (baseline only) — unless Step 3 surfaced a broken baseline that must be fixed first; then commit that fix separately with a `test(functions):` message.

---

## Task 2: Rules — helpers & dead-code removal

**Files:**
- Modify: `firestore.rules`

- [ ] **Step 1: Remove the dead `rateLimited()` helper**

Delete the `rateLimited()` function block (currently `:35-40`) including its comment:
```text
-    // Helper function to rate limit writes
-    function rateLimited() {
-      // Rate limiting: Allow 10 writes per minute per user
-      // Backed by Cloud Functions which set the rateLimitUntil custom claim
-      return !('rateLimitUntil' in request.auth.token) ||
-             request.time.toMillis() > request.auth.token.rateLimitUntil;
-    }
```
(Verified dead: nothing ever sets a `rateLimitUntil` claim — only a comment in `functions/src/setUserRole.ts:90`; `rateLimiter.ts` sets `rateLimited`/`flaggedAt`, and its trigger path matches nothing.)

- [ ] **Step 2: Drop `rateLimited()` from `posts`**

Replace the `posts` block (`:438-443`):
```text
    match /posts/{postId} {
      allow read: if isAuthenticated() && resource.data.status != 'deleted';
      allow create: if isAuthenticated() && isValidPost(request.resource.data);
      allow update: if isOwner(resource.data.userId) && isValidPost(request.resource.data);
      allow delete: if isOwner(resource.data.userId);
    }
```
(Behavior is unchanged — the guard was a no-op.)

- [ ] **Step 3: Block premium spoofing in `isValidStats`**

Inside `isValidStats` (after the `lastUpdated` line, `:173`), add:
```text
             // Privilege fields are server-owned (Paystack webhook /
             // RevenueCat extension) — never writable by the client.
             !data.keys().hasAny(['isPremium', 'premium_since']) &&
```
(Verified safe: no client or function writes `isPremium`/`premium_since` into `user_stats` today.)

- [ ] **Step 4: Relax `isValidTribe` for creator tribes (SP-E D4)**

In `isValidTribe` (`:68-86`):
```text
-    function isValidTribe(tribe) {
-      return tribe.keys().hasAll(['name', 'archetypeId', 'type']) &&
+    function isValidTribe(tribe) {
+      return tribe.keys().hasAll(['name', 'type']) &&
              tribe.keys().size() <= 40 &&
              sanitizeString(tribe.name) &&
              tribe.name.size() <= 100 &&
-             tribe.archetypeId in ['athlete', 'scholar', 'stoic', 'creator', 'zealot', 'mystic'] &&
-             tribe.type in ['official', 'brand', 'userPrivate', 'userPublic'] &&
+             // archetypeId is optional — creator tribes may omit it (SP-E D5)
+             (!tribe.keys().hasAny(['archetypeId']) ||
+                tribe.archetypeId in ['athlete', 'scholar', 'stoic', 'creator', 'zealot', 'mystic']) &&
+             tribe.type in ['official', 'brand', 'userPrivate', 'userPublic', 'creator'] &&
```

- [ ] **Step 5: Add the `isVerifiedCreator()` helper + `creator_invite_codes` deny block**

After `isAdmin()` (`:19`):
```text
    // Verified creator: role claim 'creator' AND a verified creator_profiles doc.
    // NOTE: get() on a missing doc makes the rule evaluate to an error → deny.
    function isVerifiedCreator() {
      return isAuthenticated() &&
             request.auth.token.role == 'creator' &&
             get(/databases/$(database)/documents/creator_profiles/$(request.auth.uid)).data.isVerifiedCreator == true;
    }
```
Add a new block immediately before `blueprints` (`:501`):
```text
    // Creator invite codes — functions-only writes (SP-E D1).
    match /creator_invite_codes/{code} {
      allow read, write: if false;
    }
```

- [ ] **Step 6: Lint**
```bash
firebase deploy --only firestore:rules --dry-run
```
Expected: "dry run" passes — rules compile. Fix any syntax error before continuing.

- [ ] **Step 7: Commit**
```bash
git add firestore.rules
git commit -m "feat(rules): remove dead rateLimited guard, block premium spoof in isValidStats, relax isValidTribe for creator tribes, add isVerifiedCreator helper + creator_invite_codes deny"
```

---

## Task 3: Rules — creator_profiles / blueprints / challenges

**Files:**
- Modify: `firestore.rules`

- [ ] **Step 1: Replace the `creator_profiles` block (`:512-517`)**

```text
    // Creator Profiles (verified creators).
    // Server owns creation (redeemCreatorInvite). System-seeded profiles
    // (ids like creator_aria_chen) keep an authenticated-dev carve-out.
    match /creator_profiles/{profileId} {
      allow read: if true;
      allow create: if isAdmin() || (profileId.startsWith('creator_') && isAuthenticated());
      // Owner may maintain their profile (onboarding steps) but NEVER flip
      // verification/role/identity fields.
      allow update: if isAdmin() ||
        (isAuthenticated() && resource.data.ownerId == request.auth.uid &&
         isValidCreatorProfile(request.resource.data) &&
         !request.resource.data.diff(resource.data).affectedKeys()
           .hasAny(['ownerId', 'userId', 'role', 'isVerifiedCreator'])) ||
        (profileId.startsWith('creator_') && isAuthenticated());
      allow delete: if isAdmin();
    }
```

- [ ] **Step 2: Replace the `blueprints` block (`:501-504`)**

```text
    // Blueprints (habit stacks) — public read; written by admins, verified
    // creators (their own docs), and the curated 'system' catalog seed
    // (SP-F v3 backfill writes creatorUserId: 'system' in-app).
    match /blueprints/{blueprintId} {
      allow read: if true;
      allow create: if isAdmin() ||
        (isVerifiedCreator() && request.resource.data.creatorUserId == request.auth.uid) ||
        (isAuthenticated() && request.resource.data.creatorUserId == 'system');
      allow update: if isAdmin() ||
        (isVerifiedCreator() && resource.data.creatorUserId == request.auth.uid &&
         request.resource.data.creatorUserId == request.auth.uid) ||
        (isAuthenticated() && resource.data.creatorUserId == 'system' &&
         request.resource.data.creatorUserId == 'system');
      allow delete: if isAdmin() ||
        (isVerifiedCreator() && resource.data.creatorUserId == request.auth.uid);
    }
```
> The `'system'` carve-out is a **flagged deviation** from SP-E's literal rule shape (design §D1.2a): without it, `_createSeed` (`blueprint_repository.dart:380-398`) and SP-F's v3 in-app seed are denied for normal users.

- [ ] **Step 3: Replace the `challenges` block (`:408-410`)**

```text
    // Challenges — catalog entries; admins and verified creators (own docs)
    match /challenges/{challengeId} {
      allow read: if true;
      allow create: if isAdmin() ||
        (isVerifiedCreator() && request.resource.data.createdBy == request.auth.uid);
      allow update: if isAdmin() ||
        (isVerifiedCreator() && resource.data.createdBy == request.auth.uid);
      allow delete: if isAdmin() ||
        (isVerifiedCreator() && resource.data.createdBy == request.auth.uid);

      match /participants/{participantId} {
        allow read: if isAuthenticated();
        allow write: if isOwner(participantId);
      }
    }
```

- [ ] **Step 4: Lint**
```bash
firebase deploy --only firestore:rules --dry-run
```
Expected: passes.

- [ ] **Step 5: Commit**
```bash
git add firestore.rules
git commit -m "feat(rules): function-owned creator_profiles, verified-creator blueprint/challenge writes (+system catalog carve-out)"
```

---

## Task 4: Rules — tribes create gate + memberCount ±1 constraint (SP-G D9)

**Files:**
- Modify: `firestore.rules`

- [ ] **Step 1: Gate creator-tribe creation**

In the `tribes` block (`:361-372`), change the create rule:
```text
      allow create: if isAuthenticated() && isValidTribe(request.resource.data) &&
        (request.resource.data.type != 'creator' || isVerifiedCreator());
```

- [ ] **Step 2: Constrain aggregate updates to ±1**

Replace the update rule (`:364-371`) with:
```text
      allow update: if isAuthenticated() && isValidTribe(request.resource.data) && (
        resource.data.createdBy == request.auth.uid ||
        isAdmin() ||
        // Aggregate member fields (joinTribe / leaveTribe / recalcTribes):
        // only memberCount ±1 alongside members/lastStatsSync (SP-G D9).
        (request.resource.data.diff(resource.data).affectedKeys()
           .hasOnly(['memberCount', 'members', 'lastStatsSync']) &&
         (request.resource.data.memberCount == resource.data.memberCount + 1 ||
          request.resource.data.memberCount == resource.data.memberCount - 1))
      );
```
(Verified against current client paths: `tribe_repository.dart:204-208,240-244` and `tribe_membership_service.dart:49-53,117-120` all move memberCount by exactly ±1. Known edge: `tribe_membership_service.leaveTribe` clamps at 0 (`:118`) — a leave from a corrupt `memberCount == 0` doc is denied; accepted, documented in design §8. `syncTribeStats` (`tribe_stats_service.dart:236-254`) was already denied (writes `totalXp`/`totalHabitsCompleted`/`totalChallengesCompleted` — not in the whitelist) and stays denied; `recalcTribes` remains the authority via admin SDK.)

- [ ] **Step 3: Lint**
```bash
firebase deploy --only firestore:rules --dry-run
```
Expected: passes.

- [ ] **Step 4: Commit**
```bash
git add firestore.rules
git commit -m "feat(rules): gate creator-tribe creation on verified creators, constrain tribe aggregate updates to memberCount ±1"
```

---

## Task 5: Rules verification — emulator matrix

**Files:**
- Create: `scripts/rules_emulator_check.mjs`

- [ ] **Step 1: Start the emulators**

```bash
firebase emulators:start --only firestore,auth
```
Expected: Firestore on `127.0.0.1:8080`, Auth on `127.0.0.1:9099`, Emulator UI on `127.0.0.1:4000`. Rules hot-reload from `firestore.rules` — restart or rely on reload after each edit.

- [ ] **Step 2: Write the check script**

Create `scripts/rules_emulator_check.mjs` (Node ≥ 18, no new deps — uses `fetch` + the admin SDK from `functions/node_modules` for claims/seed):

```js
// Emulator rules matrix for SP-H (design spec §6.2).
// Usage: node scripts/rules_emulator_check.mjs  (emulators must be running)
// Pass: script exits 0; FAIL lines show which matrix row broke.
import { execSync } from "node:child_process";

const AUTH = "http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts";
const FS = "http://127.0.0.1:8080/v1/projects/tradeflash-l2966/databases/(default)/documents";
const KEY = "?key=fake";

async function signUp(email) {
  const r = await fetch(`${AUTH}:signUp${KEY}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email, password: "pass1234", returnSecureToken: true }),
  });
  const j = await r.json();
  return { idToken: j.idToken, uid: j.localId };
}

async function call(method, token, path, body) {
  const r = await fetch(`${FS}/${path}`, {
    method,
    headers: token ? { Authorization: `Bearer ${token}`, "Content-Type": "application/json" } : { "Content-Type": "application/json" },
    body: body ? JSON.stringify(body) : undefined,
  });
  return r.status;
}

const results = [];
function check(name, got, want) {
  const ok = got === want;
  results.push(`${ok ? "PASS" : "FAIL"}  ${name} (got ${got}, want ${want})`);
}

// --- seed + claims (admin SDK against emulators) ---
process.env.FIRESTORE_EMULATOR_HOST = "127.0.0.1:8080";
process.env.FIREBASE_AUTH_EMULATOR_HOST = "127.0.0.1:9099";
const admin = (await import("file://" + process.cwd().replace(/\\/g, "/") + "/functions/node_modules/firebase-admin/lib/index.js")).default;
if (admin.apps.length === 0) admin.initializeApp({ projectId: "tradeflash-l2966" });

const { idToken: aliceToken, uid: aliceUid } = await signUp("alice@test.dev");
const { idToken: bobToken, uid: bobUid } = await signUp("bob@test.dev");
await admin.auth().setCustomUserClaims(aliceUid, { role: "creator" });
await admin.firestore().collection("creator_profiles").doc(aliceUid).set({
  userId: aliceUid, ownerId: aliceUid, role: "creator", isVerifiedCreator: true,
});
await admin.firestore().collection("tribes").doc("morning_warriors").set({
  name: "Morning Warriors", archetypeId: "athlete", type: "official",
  memberCount: 10, members: [], totalXp: 0, lastStatsSync: admin.firestore.FieldValue.serverTimestamp(),
});
await admin.firestore().collection("challenges").doc("c1").set({ title: "t", status: "active" });

const doc = (path, fields) => ({ fields: Object.fromEntries(Object.entries(fields).map(([k, v]) => [k, { [typeof v === "number" ? "integerValue" : typeof v === "boolean" ? "booleanValue" : "stringValue"]: String(v) }])) });

// --- matrix ---
check("1a unauthenticated read blueprints", await call("GET", null, "blueprints/x", null), 404); // no doc -> 404, but NOT 401/403
check("1b unauthenticated write blueprints", await call("PATCH", null, "blueprints/x", doc("x", { creatorUserId: "alice" })), 403);
check("2a users owner read", await call("GET", aliceToken, `users/${aliceUid}`, null), 404); // allowed (missing doc)
check("2b users other read", await call("GET", bobToken, `users/${aliceUid}`, null), 403);
check("2c users isPremium write", await call("PATCH", aliceToken, `users/${aliceUid}`, doc("x", { isPremium: "true" })), 403);
check("3 user_stats isPremium write", await call("PATCH", aliceToken, `user_stats/${aliceUid}`, doc("x", { isPremium: "true" })), 403);
check("4a creator_profiles create by normal user", await call("PATCH", bobToken, "creator_profiles/bob_uid", doc("x", { userId: "bob_uid", ownerId: "bob_uid" })), 403);
check("4b creator_profiles create creator_ prefix", await call("PATCH", bobToken, "creator_profiles/creator_demo", doc("x", { userId: "creator_demo" })), 200);
check("4c creator_profiles flip isVerifiedCreator", await call("PATCH", aliceToken, `creator_profiles/${aliceUid}`, doc("x", { isVerifiedCreator: "false" })), 403);
check("5a blueprints non-verified creator write", await call("PATCH", bobToken, "blueprints/bob_bp", doc("x", { creatorUserId: bobUid })), 403);
check("5b blueprints verified creator write", await call("PATCH", aliceToken, "blueprints/alice_bp", doc("x", { creatorUserId: aliceUid })), 200);
check("5c blueprints system catalog seed", await call("PATCH", bobToken, "blueprints/morning_9", doc("x", { creatorUserId: "system" })), 200);
check("6 challenges verified creator write", await call("PATCH", aliceToken, "challenges/c_alice", doc("x", { createdBy: aliceUid })), 200);
check("6b challenges non-verified write", await call("PATCH", bobToken, "challenges/c_bob", doc("x", { createdBy: bobUid })), 403);
check("7a tribe creator type by non-verified", await call("PATCH", bobToken, "tribes/bob_creator_tribe", doc("x", { name: "B", type: "creator" })), 403);
check("7b tribe creator type by verified", await call("PATCH", aliceToken, "tribes/alice_creator_tribe", doc("x", { name: "A", type: "creator", members: [], memberCount: "1" })), 200);
check("8a tribe memberCount +1", await call("PATCH", bobToken, "tribes/morning_warriors", doc("x", { name: "Morning Warriors", archetypeId: "athlete", type: "official", memberCount: "11", members: [bobUid], lastStatsSync: "1" })), 200);
check("8b tribe memberCount +5", await call("PATCH", bobToken, "tribes/morning_warriors", doc("x", { name: "Morning Warriors", archetypeId: "athlete", type: "official", memberCount: "16", members: [bobUid], lastStatsSync: "1" })), 403);
check("8c tribe totalXp-only update", await call("PATCH", bobToken, "tribes/morning_warriors", doc("x", { name: "Morning Warriors", archetypeId: "athlete", type: "official", memberCount: "10", members: [], lastStatsSync: "1", totalXp: "999999" })), 403);
check("9a creator_invite_codes deny", await call("PATCH", aliceToken, "creator_invite_codes/ABCD2345", doc("x", { creatorUid: aliceUid })), 403);
check("9b invite_codes deny (unchanged)", await call("PATCH", aliceToken, "invite_codes/ABC123", doc("x", { userId: aliceUid })), 403);
check("10a habit_completions create", await call("PATCH", aliceToken, `users/${aliceUid}/habit_completions/c1`, doc("x", { userId: aliceUid })), 200);
check("10b posts create", await call("PATCH", aliceToken, "posts/p1", doc("x", { content: "hi", userId: aliceUid, createdAt: "1" })), 403); // requires createdAt timestamp -> adjust body with timestampValue if needed
check("11 club_leaderboards self write", await call("PATCH", aliceToken, `club_leaderboards/${aliceUid}_morning_warriors`, doc("x", { userId: aliceUid, clubId: "morning_warriors", xp: "10" })), 200);

console.log(results.join("\n"));
const failed = results.filter((r) => r.startsWith("FAIL"));
if (failed.length) { console.error(`\n${failed.length} FAILURES`); process.exit(1); }
console.log("\nALL RULES MATRIX CHECKS PASSED");
```

- [ ] **Step 3: Run the matrix**

```bash
node scripts/rules_emulator_check.mjs
```
Expected: every row PASS. Rows marked with a comment (e.g. 1a/2a expecting 404 vs 403) may need a tweak for the emulator's exact status codes (missing-doc reads return 404 even when authorized) — adjust the expectations to the emulator's observed behavior and re-run; **the goal is: no authorized read/write denied, no unauthorized write allowed.**

- [ ] **Step 4: Manual app-flow pass (Emulator UI on :4000)**

With the Flutter app pointed at the emulators, exercise: tribe join/leave from onboarding (`club_screen.dart` path), habit completion + undo delete (`habit_completions`), creator signup (only after SP-E client lands; until then confirm denial is graceful), blueprint seed (`seedBlueprints`), posts creation. Confirm no `PERMISSION_DENIED` errors appear for flows that worked before this rules package.

- [ ] **Step 5: Commit**
```bash
git add scripts/rules_emulator_check.mjs
git commit -m "test(rules): emulator matrix script for SP-H rules package"
```

---

## Task 6: Functions — delete dead triggers + rateLimiter

**Files:**
- Delete: `functions/src/rateLimiter.ts`
- Modify: `functions/src/index.ts`, `functions/src/habit_notifications.ts`, `functions/test/index.test.ts`

- [ ] **Step 1: Write the failing export assertions**

Append to `functions/test/index.test.ts`:
```ts
describe("dead triggers removed (SP-H)", () => {
  const index = require("../lib/index");
  it("no longer exports enforceRateLimit", () => {
    expect(index.enforceRateLimit).toBeUndefined();
  });
  it("no longer exports onHabitChanged", () => {
    expect(index.onHabitChanged).toBeUndefined();
  });
  it("no longer exports notifyAchievement", () => {
    expect(index.notifyAchievement).toBeUndefined();
  });
});
```

- [ ] **Step 2: Run to verify it fails**
```bash
cd functions && npm run build && npx jest test/index.test.ts --coverage=false
```
Expected: FAIL (the three exports still exist).

- [ ] **Step 3: Remove the dead code**

- Delete `functions/src/rateLimiter.ts`.
- `functions/src/index.ts:261` — remove `export * from "./rateLimiter";`.
- `functions/src/habit_notifications.ts` — delete the `onHabitChanged` function (`:260-374`) and `notifyAchievement` (`:426-452`), plus the now-orphaned "HABIT LIFECYCLE" / "ACHIEVEMENT NOTIFICATIONS" section comments. Keep `sendDailyInsights` (`:389-417`) and all helper functions (`getDb`, `sendNotification`, `getTemplateMessage`, `generateAIInsight`).

- [ ] **Step 4: Run to verify it passes**
```bash
cd functions && npm run build && npm test
```
Expected: PASS — full suite (old + new assertions).

- [ ] **Step 5: Commit**
```bash
git add functions/src/rateLimiter.ts functions/src/index.ts functions/src/habit_notifications.ts functions/test/index.test.ts functions/lib 2>/dev/null || git add functions/src functions/test
git commit -m "chore(functions): remove dead triggers (enforceRateLimit, onHabitChanged, notifyAchievement) + rateLimiter.ts"
```
(If `functions/lib` is gitignored, the build output isn't committed — adjust the `git add` to whatever the repo tracks; check `git status` first.)

---

## Task 7: Functions — `generateAiRecap` premium gate fix

**Files:**
- Create: `functions/test/ai_recap.test.ts`
- Modify: `functions/src/ai_recap.ts`

- [ ] **Step 1: Write the failing test**

```ts
// functions/test/ai_recap.test.ts
// eslint-disable-next-line @typescript-eslint/no-require-imports
const ft = require("firebase-functions-test")();
import * as admin from "firebase-admin";

describe("generateAiRecap premium gate (SP-H)", () => {
  afterAll(() => ft.cleanup());

  const generateAiRecap = require("../lib/index").generateAiRecap;

  it("denies when users/{uid}.isPremium is not set", async () => {
    ft.firestore.collection("users").doc("u1").set({ displayName: "A" });
    await expect(
      generateAiRecap.run({ auth: { uid: "u1" }, data: {} })
    ).rejects.toHaveProperty("code", "permission-denied");
  });

  it("allows when users/{uid}.isPremium is true", async () => {
    ft.firestore.collection("users").doc("u2").set({ isPremium: true });
    ft.firestore.collection("habits").doc("h1").set({ userId: "u2", title: "t" });
    const res = await generateAiRecap.run({ auth: { uid: "u2" }, data: {} });
    expect(res.success).toBe(false); // no habits completed -> no_habits path is fine; key: no permission-denied
  });

  it("allows when users/{uid}.subscriptionStatus is active (RevenueCat)", async () => {
    ft.firestore.collection("users").doc("u3").set({ subscriptionStatus: "active" });
    const res = await generateAiRecap.run({ auth: { uid: "u3" }, data: {} });
    expect(res).toBeDefined(); // gate passed
  });
});
```
(Note: `generateAiRecap` reads `user_stats` too — seed `user_stats/uX` if the test path requires it; adjust per the actual data dependencies.)

- [ ] **Step 2: Run to verify it fails**
```bash
cd functions && npm run build && npx jest test/ai_recap.test.ts --coverage=false
```
Expected: FAIL — the gate still reads `user_stats.isPremium` (never set) and denies all three.

- [ ] **Step 3: Implement the gate fix**

In `functions/src/ai_recap.ts`, replace lines `:26-34`:
```ts
    // 1. Fetch User Data & Habits
    const userDoc = await db.collection("users").doc(userId).get();
    const userData = userDoc.data();

    // PREMIUM GUARD: source of truth is users/{uid} — Paystack webhook
    // writes isPremium (paystack.ts); the RevenueCat extension writes
    // subscriptionStatus (revenuecat_events.ts). user_stats.isPremium is
    // never written and is blocked by rules (SP-H).
    const isPremium =
      userData?.isPremium === true || userData?.subscriptionStatus === "active";
    if (!isPremium) {
      console.warn(`[generateAiRecap] Non-premium user ${userId} attempted to generate AI recap.`);
      throw new HttpsError("permission-denied", "AI Insights are a premium feature.");
    }
```
(Keep the later `user_stats` reads for stats data — only the gate changes.)

- [ ] **Step 4: Run to verify it passes**
```bash
cd functions && npm run build && npm test
```
Expected: PASS.

- [ ] **Step 5: Commit**
```bash
git add functions/src/ai_recap.ts functions/test/ai_recap.test.ts
git commit -m "fix(functions): generateAiRecap premium gate reads users.isPremium/subscriptionStatus (was dead user_stats.isPremium)"
```

---

## Task 8: Functions — Paystack webhook custom-claims sync

**Files:**
- Create: `functions/test/paystack_claims.test.ts`
- Modify: `functions/src/payments/paystack.ts`

- [ ] **Step 1: Write the failing test**

```ts
// functions/test/paystack_claims.test.ts
// eslint-disable-next-line @typescript-eslint/no-require-imports
const ft = require("firebase-functions-test")();
import * as admin from "firebase-admin";

describe("paystackWebhook claim sync (SP-H)", () => {
  afterAll(() => ft.cleanup());

  const paystackWebhook = require("../lib/index").paystackWebhook;
  const crypto = require("crypto");
  const secret = process.env.PAYSTACK_SECRET_KEY ?? "test-secret";

  function signedBody(overrides = {}) {
    const body = {
      event: "charge.success",
      id: "evt_1",
      data: {
        reference: "ref_1",
        metadata: { custom_fields: [{ variable_name: "user_id", value: "u1" }] },
      },
      ...overrides,
    };
    const signature = crypto.createHmac("sha512", secret).update(JSON.stringify(body)).digest("hex");
    return { body, headers: { "x-paystack-signature": signature } };
  }

  it("sets activeEntitlements claim on charge.success", async () => {
    const { body, headers } = signedBody();
    const claimsSet: any[] = [];
    // stub admin.auth().setCustomUserClaims + getUser
    const originalAuth = (admin as any).auth;
    (admin as any).auth = () => ({
      getUser: async () => ({ customClaims: { role: "user" } }),
      setCustomUserClaims: async (uid: string, claims: any) => claimsSet.push({ uid, claims }),
    });
    try {
      await paystackWebhook.run({ body, headers, method: "POST" }, { status: () => ({ send: () => {} }), sendStatus: () => {} });
      expect(claimsSet).toHaveLength(1);
      expect(claimsSet[0].claims.activeEntitlements).toEqual(["premium"]);
      expect(claimsSet[0].claims.role).toBe("user"); // merged, not clobbered
    } finally {
      (admin as any).auth = originalAuth;
    }
  });

  it("is idempotent for duplicate webhooks (no second claim write)", async () => {
    const { body, headers } = signedBody();
    await paystackWebhook.run({ body, headers, method: "POST" }, { status: () => ({ send: () => {} }), sendStatus: () => {} });
    // processed_webhooks/ref_1 exists now
    let called = 0;
    const originalAuth = (admin as any).auth;
    (admin as any).auth = () => ({
      getUser: async () => ({ customClaims: {} }),
      setCustomUserClaims: async () => { called++; },
    });
    try {
      await paystackWebhook.run({ body, headers, method: "POST" }, { status: () => ({ send: () => {} }), sendStatus: () => {} });
      expect(called).toBe(0);
    } finally {
      (admin as any).auth = originalAuth;
    }
  });
});
```
(Adjust to the existing `paystack.test.ts` mocking conventions — read that file first and mirror its helpers.)

- [ ] **Step 2: Run to verify it fails**
```bash
cd functions && npm run build && npx jest test/paystack_claims.test.ts --coverage=false
```
Expected: FAIL — no claim write happens today.

- [ ] **Step 3: Implement the claim sync**

In `functions/src/payments/paystack.ts`, inside the `charge.success` branch after the `users/{uid}` merge (`:130-140`), before the `processedRef.set(...)` idempotency marker:
```ts
        if (uid) {
            try {
                // Identity-First UX: Evolve the user's avatar / unlock premium
                await db.collection("users").doc(uid).set({
                    isPremium: true,
                    identity_type: identityType,
                    premium_since: admin.firestore.FieldValue.serverTimestamp(),
                }, { merge: true });

                // SP-H: mirror the entitlement into custom claims so the
                // client's claims fallback (subscription_provider.dart:66-80)
                // works on web too (SP-B D2 deferred this here). Merges —
                // never clobbers existing claims. Refund/expiry clearing is
                // future work (the webhook only receives charge.success).
                try {
                    const auth = admin.auth();
                    const userRecord = await auth.getUser(uid);
                    await auth.setCustomUserClaims(uid, {
                        ...(userRecord.customClaims ?? {}),
                        activeEntitlements: ["premium"],
                    });
                } catch (claimErr) {
                    logger.error("Paystack claim sync failed:", claimErr);
                }

                logger.info(`Successfully upgraded user ${uid} to premium via Paystack.`);
            } catch (err) {
                logger.error("Firestore Update Error:", err);
            }
        }
```

- [ ] **Step 4: Run to verify it passes**
```bash
cd functions && npm run build && npm test
```
Expected: PASS.

- [ ] **Step 5: Commit**
```bash
git add functions/src/payments/paystack.ts functions/test/paystack_claims.test.ts
git commit -m "feat(functions): paystack charge.success syncs activeEntitlements custom claim (SP-B deferred)"
```

---

## Task 9: Functions — recalcTribes respects actual membership (SP-G D10)

**Files:**
- Create: `functions/test/recalc_tribes.test.ts`
- Modify: `functions/src/recalcTribes.ts`

> Coordination note (design §D3.4): SP-G's plan is not on disk. If it ships a `recalcTribes` change first, this task reduces to running its tests + deploy. Otherwise SP-H owns it.

- [ ] **Step 1: Write the failing test**

```ts
// functions/test/recalc_tribes.test.ts
// eslint-disable-next-line @typescript-eslint/no-require-imports
const ft = require("firebase-functions-test")();
import * as admin from "firebase-admin";
import { recalcTribesInternal } from "../src/recalcTribes";

describe("recalcTribesInternal resolved membership (SP-H/SP-G D10)", () => {
  afterAll(() => ft.cleanup());

  it("uses explicit users/{uid}/tribes membership for BOTH members and XP", async () => {
    const db = admin.firestore();
    // alice: archetype athlete (default club morning_warriors) but explicit membership in deep_work_society
    await db.collection("users").doc("alice").set({ archetype: "athlete" });
    await db.collection("users").doc("alice").collection("tribes").doc("deep_work_society").set({ tribeId: "deep_work_society", joinedAt: new Date() });
    await db.collection("user_stats").doc("alice").set({ avatarStats: { totalXp: 500 } });
    // bob: no explicit membership -> archetype club
    await db.collection("users").doc("bob").set({ archetype: "stoic" });
    await db.collection("user_stats").doc("bob").set({ avatarStats: { totalXp: 100 } });

    await recalcTribesInternal(db as any);

    const dws = await db.collection("tribes").doc("deep_work_society").get();
    const mw = await db.collection("tribes").doc("morning_warriors").get();
    const mm = await db.collection("tribes").doc("mindful_masters").get();

    expect(dws.data()?.members).toContain("alice");
    expect(dws.data()?.totalXp).toBe(500);   // alice's XP follows her, not her archetype
    expect(mw.data()?.members).not.toContain("alice");
    expect(mm.data()?.members).toContain("bob");
    expect(mm.data()?.totalXp).toBe(100);
  });
});
```
(Skip seeding official tribe docs if `recalcTribesInternal` uses `batch.update` — verify behavior first and adjust the test to match the function's contract; the assertion that matters: XP follows the **resolved** membership.)

- [ ] **Step 2: Run to verify it fails**
```bash
cd functions && npm run build && npx jest test/recalc_tribes.test.ts --coverage=false
```
Expected: FAIL — today `deep_work_society.totalXp` is 0 because XP aggregation uses the archetype map (`recalcTribes.ts:87` `userToTribeMap.get(doc.id)`), not the resolved membership.

- [ ] **Step 3: Implement**

In `functions/src/recalcTribes.ts`:
1. Keep the explicit-membership scan (`:48-66`) and the resolution step (`:69-74`).
2. Extract the resolution into a single map before aggregation:
```ts
  // Resolve each user's effective tribe ONCE: explicit membership wins,
  // else archetype default (SP-H / SP-G D10).
  const resolvedTribe = new Map<string, string>();
  for (const [uid, archetype] of userToTribeMap.entries()) {
    const membership = userMembershipMap.get(uid);
    const clubId = membership ? membership.tribeId : archetype;
    resolvedTribe.set(uid, clubId);
    const members = tribeMembers.get(clubId);
    if (members) members.push(uid);
  }
```
3. Replace the XP aggregation (`:83-105`) to use `resolvedTribe` instead of `userToTribeMap`:
```ts
  await new Promise((resolve, reject) => {
    db.collection("user_stats")
      .stream()
      .on("data", (doc: admin.firestore.QueryDocumentSnapshot) => {
        const tribeId = resolvedTribe.get(doc.id);
        if (tribeId) {
          const stats = doc.data();
          let xp = 0;
          const avatarStats = stats.avatarStats || {};
          if (typeof avatarStats.totalXp === "number") {
            xp = avatarStats.totalXp;
          } else if (typeof stats.totalXp === "number") {
            xp = stats.totalXp;
          }
          const currentXp = tribeXp.get(tribeId) || 0;
          tribeXp.set(tribeId, currentXp + xp);
        }
      })
      .on("end", resolve)
      .on("error", reject);
  });
```
4. Do not touch: the 6 hardcoded official club targets (`:139-159`), the activity aggregation, or anything that would write creator/user tribes (they are not in `Object.values(clubMap)` — unchanged).

- [ ] **Step 4: Run to verify it passes**
```bash
cd functions && npm run build && npm test
```
Expected: PASS.

- [ ] **Step 5: Commit**
```bash
git add functions/src/recalcTribes.ts functions/test/recalc_tribes.test.ts
git commit -m "fix(functions): recalcTribes aggregates XP by resolved membership (explicit tribe wins over archetype)"
```

---

## Task 10: Functions — `creator_invites.ts` (SP-E D1/D5)

**Files:**
- Create: `functions/src/creator_invites.ts`
- Create: `functions/test/creator_invites.test.ts`
- Modify: `functions/src/index.ts`

> Ownership note (design §D3.1): SP-E's design claims these functions. **Before starting, check whether `docs/superpowers/plans/2026-08-01-sp-e-creator-invites-plan.md` exists and whether `functions/src/creator_invites.ts` is already implemented.** If SP-E shipped it: skip Steps 1–4, review the implementation against this spec, run `npm run build && npm test`, and move on. Otherwise implement here.

- [ ] **Step 1: Write the failing tests**

```ts
// functions/test/creator_invites.test.ts
// eslint-disable-next-line @typescript-eslint/no-require-imports
const ft = require("firebase-functions-test")();
import * as admin from "firebase-admin";

describe("creator_invites (SP-E D1/D5)", () => {
  afterAll(() => ft.cleanup());

  const { generateCreatorInviteCode, redeemCreatorInvite, ensureCreatorTribe } = require("../lib/index");

  describe("generateCreatorInviteCode", () => {
    it("rejects unauthenticated", async () => {
      await expect(generateCreatorInviteCode.run({ auth: undefined, data: {} }))
        .rejects.toHaveProperty("code", "unauthenticated");
    });
    it("rejects non-verified creators", async () => {
      ft.firestore.collection("creator_profiles").doc("u1").set({ userId: "u1", isVerifiedCreator: false });
      await expect(generateCreatorInviteCode.run({ auth: { uid: "u1" }, data: {} }))
        .rejects.toHaveProperty("code", "permission-denied");
    });
    it("returns an 8-char code for a verified creator", async () => {
      ft.firestore.collection("creator_profiles").doc("u2").set({ userId: "u2", isVerifiedCreator: true });
      admin.auth().getUser = async () => ({ customClaims: { role: "creator" } }) as any;
      const res = await generateCreatorInviteCode.run({ auth: { uid: "u2" }, data: {} });
      expect(res.code).toMatch(/^[A-Z2-9]{8}$/);
    });
  });

  describe("redeemCreatorInvite", () => {
    it("creates the profile + claim atomically and deletes the code", async () => {
      ft.firestore.collection("creator_invite_codes").doc("ABCD2345").set({
        creatorUid: "creator1", createdAt: new Date(),
        expiresAt: new Date(Date.now() + 86400000), redeemedBy: null,
      });
      const claim: any = {};
      admin.auth().setCustomUserClaims = async (uid: string, c: any) => { claim.uid = uid; claim.claims = c; };
      const res = await redeemCreatorInvite.run({ auth: { uid: "invitee1" }, data: { code: "ABCD2345" } });
      expect(res.role).toBe("creator");
      const profile = await ft.firestore.collection("creator_profiles").doc("invitee1").get();
      expect(profile.data()?.isVerifiedCreator).toBe(true);
      expect(profile.data()?.ownerId).toBe("invitee1");
      expect(claim.claims.role).toBe("creator");
      const code = await ft.firestore.collection("creator_invite_codes").doc("ABCD2345").get();
      expect(code.exists).toBe(false);
    });
    it("rejects expired codes", async () => {
      ft.firestore.collection("creator_invite_codes").doc("EXPIRED1").set({
        creatorUid: "creator1", createdAt: new Date(),
        expiresAt: new Date(Date.now() - 1000), redeemedBy: null,
      });
      await expect(redeemCreatorInvite.run({ auth: { uid: "invitee2" }, data: { code: "EXPIRED1" } }))
        .rejects.toHaveProperty("code", "not-found");
    });
  });

  describe("ensureCreatorTribe", () => {
    it("creates a creator tribe and links the profile", async () => {
      ft.firestore.collection("creator_profiles").doc("u3").set({ userId: "u3", isVerifiedCreator: true, displayName: "Aria" });
      admin.auth().getUser = async () => ({ customClaims: { role: "creator" } }) as any;
      const res = await ensureCreatorTribe.run({ auth: { uid: "u3" }, data: {} });
      const tribe = await ft.firestore.collection("tribes").doc(res.tribeId).get();
      expect(tribe.data()?.type).toBe("creator");
      expect(tribe.data()?.createdBy).toBe("u3");
      expect(tribe.data()?.memberCount).toBe(1);
      const profile = await ft.firestore.collection("creator_profiles").doc("u3").get();
      expect(profile.data()?.tribeId).toBe(res.tribeId);
    });
  });
});
```
(Mirror the mocking style of the existing `paystack.test.ts`/`create_starter_pack.test.ts` for `admin.auth()` stubs — read them first.)

- [ ] **Step 2: Run to verify it fails**
```bash
cd functions && npm run build && npx jest test/creator_invites.test.ts --coverage=false
```
Expected: FAIL — `creator_invites` module doesn't exist.

- [ ] **Step 3: Implement `functions/src/creator_invites.ts`**

```ts
import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

if (admin.apps.length === 0) {
  admin.initializeApp();
}
const db = admin.firestore();

const CODE_ALPHABET = "ABCDEFGHJKMNPQRSTUVWXYZ23456789"; // no 0/O/1/I/L
const CODE_LENGTH = 8;
const MAX_OUTSTANDING_CODES = 10;
const CODE_TTL_MS = 7 * 24 * 60 * 60 * 1000; // 7 days

/** Server-side verified-creator check (mirrors the rules helper). */
async function isVerifiedCreator(uid: string): Promise<boolean> {
  const profile = await db.collection("creator_profiles").doc(uid).get();
  return profile.exists && profile.data()?.isVerifiedCreator === true;
}

function generateCode(): string {
  let code = "";
  for (let i = 0; i < CODE_LENGTH; i++) {
    code += CODE_ALPHABET[Math.floor(Math.random() * CODE_ALPHABET.length)];
  }
  return code;
}

/**
 * Generates an 8-char creator invite code (SP-E D1).
 * Caller must be a verified creator; max 10 outstanding codes.
 */
export const generateCreatorInviteCode = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be logged in.");
  }
  const uid = request.auth.uid;
  if (request.auth.token?.role !== "creator" || !(await isVerifiedCreator(uid))) {
    throw new HttpsError("permission-denied", "Only verified creators can generate invite codes.");
  }

  const snap = await db
    .collection("creator_invite_codes")
    .where("creatorUid", "==", uid)
    .get();
  const outstanding = snap.docs.filter((d) => d.data().redeemedBy == null).length;
  if (outstanding >= MAX_OUTSTANDING_CODES) {
    throw new HttpsError("resource-exhausted", "You have too many outstanding invite codes.");
  }

  let code = "";
  for (let attempt = 0; attempt < 5; attempt++) {
    code = generateCode();
    const existing = await db.collection("creator_invite_codes").doc(code).get();
    if (!existing.exists) break;
    if (attempt === 4) throw new HttpsError("internal", "Failed to generate a unique code.");
  }

  const now = admin.firestore.Timestamp.now();
  await db.collection("creator_invite_codes").doc(code).set({
    creatorUid: uid,
    createdAt: now,
    expiresAt: new admin.firestore.Timestamp(now.seconds + CODE_TTL_MS / 1000, now.nanoseconds),
    redeemedBy: null,
  });
  return { code };
});

/**
 * Atomically redeems a creator invite (SP-E D1): validates the code,
 * creates creator_profiles/{uid}, deletes the code, sets the role claim.
 */
export const redeemCreatorInvite = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be logged in.");
  }
  const uid = request.auth.uid;
  const code = String(request.data?.code ?? "").trim().toUpperCase();
  if (!/^[A-Z2-9]{8}$/.test(code)) {
    throw new HttpsError("invalid-argument", "Invalid invite code.");
  }
  const displayName = request.data?.displayName ? String(request.data.displayName).slice(0, 50) : undefined;

  const existingProfile = await db.collection("creator_profiles").doc(uid).get();
  if (existingProfile.exists || request.auth.token?.role === "creator") {
    throw new HttpsError("already-exists", "This account is already a creator.");
  }

  const codeRef = db.collection("creator_invite_codes").doc(code);
  let created = false;
  await db.runTransaction(async (tx) => {
    const codeSnap = await tx.get(codeRef);
    if (!codeSnap.exists) {
      throw new HttpsError("not-found", "Invalid or expired invite code.");
    }
    const data = codeSnap.data()!;
    if (data.redeemedBy != null) {
      throw new HttpsError("not-found", "This invite code has already been used.");
    }
    const expiresAt = data.expiresAt as admin.firestore.Timestamp;
    if (expiresAt && expiresAt.toMillis() < Date.now()) {
      throw new HttpsError("not-found", "This invite code has expired.");
    }

    tx.set(db.collection("creator_profiles").doc(uid), {
      userId: uid,
      ownerId: uid,
      role: "creator",
      displayName: displayName ?? "",
      isVerifiedCreator: true,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    tx.delete(codeRef);
    created = true;
  });

  if (!created) throw new HttpsError("internal", "Redemption failed.");

  const userRecord = await admin.auth().getUser(uid);
  await admin.auth().setCustomUserClaims(uid, {
    ...(userRecord.customClaims ?? {}),
    role: "creator",
  });

  return { ok: true, role: "creator" };
});

/**
 * Ensures the caller's creator tribe exists (SP-E D5); links profile.tribeId
 * and optionally blueprints/{blueprintId}.creatorTribeId. Finds the existing
 * tribe via where("type","==","creator") + in-memory createdBy filter (small
 * collection — avoids a new composite index; design §D3.4-flag).
 */
export const ensureCreatorTribe = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be logged in.");
  }
  const uid = request.auth.uid;
  if (request.auth.token?.role !== "creator" || !(await isVerifiedCreator(uid))) {
    throw new HttpsError("permission-denied", "Only verified creators can create creator tribes.");
  }
  const blueprintId = request.data?.blueprintId ? String(request.data.blueprintId) : undefined;

  const profileSnap = await db.collection("creator_profiles").doc(uid).get();
  if (!profileSnap.exists) {
    throw new HttpsError("failed-precondition", "Creator profile missing.");
  }
  const profile = profileSnap.data()!;

  // Reuse an existing creator tribe (one per creator).
  const existingSnap = await db.collection("tribes").where("type", "==", "creator").get();
  const mine = existingSnap.docs.find((d) => d.data().createdBy === uid);
  if (mine) {
    await db.collection("creator_profiles").doc(uid).update({ tribeId: mine.id });
    if (blueprintId) {
      await db.collection("blueprints").doc(blueprintId).update({ creatorTribeId: mine.id }).catch(() => {});
    }
    return { tribeId: mine.id, created: false };
  }

  const tribeRef = db.collection("tribes").doc(`creator_${uid}`);
  const tribeData: Record<string, unknown> = {
    type: "creator",
    name: profile.displayName ?? "Creator Tribe",
    createdBy: uid,
    members: [uid],
    memberCount: 1,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  };
  if (profile.archetype) tribeData.archetypeId = profile.archetype;
  await tribeRef.set(tribeData);

  await db.collection("creator_profiles").doc(uid).update({ tribeId: tribeRef.id });
  if (blueprintId) {
    await db.collection("blueprints").doc(blueprintId).update({ creatorTribeId: tribeRef.id }).catch(() => {});
  }
  return { tribeId: tribeRef.id, created: true };
});
```

Add to `functions/src/index.ts` (next to the other sub-module exports):
```ts
export * from "./creator_invites";
```

- [ ] **Step 4: Run to verify it passes**
```bash
cd functions && npm run build && npm test
```
Expected: PASS — full suite.

- [ ] **Step 5: Commit**
```bash
git add functions/src/creator_invites.ts functions/test/creator_invites.test.ts functions/src/index.ts
git commit -m "feat(functions): creator invite code generation/redemption + ensureCreatorTribe (SP-E D1/D5)"
```

---

## Task 11: Deploy — rules, indexes, functions + admin cleanup

**Files:** none (ops)

> **Gate:** Tasks 2–10 merged; `cd functions && npm run build && npm test` green; emulator matrix green (Task 5).

- [ ] **Step 1: Rules + indexes dry-run (final lint)**
```bash
firebase deploy --only firestore:rules,firestore:indexes --dry-run
```
Expected: dry run validates both (indexes are unchanged — the deploy itself is a no-op).

- [ ] **Step 2: Deploy rules**
```bash
firebase deploy --only firestore:rules
```
Expected: `firestore.rules` live for `tradeflash-l2966`. (Deploying before SP-E's client is safe — design §8 ordering note.)

- [ ] **Step 3: Deploy functions**
```bash
cd functions && npm run build && cd .. && firebase deploy --only functions
```
Expected: new export set live — `creator_invites` added; `enforceRateLimit`, `onHabitChanged`, `notifyAchievement`, `rateLimiter` gone (CLI may prompt with `--force` only if functions were deleted wholesale; the four removed exports are ordinary deletions — confirm the summary lists them).

- [ ] **Step 4: Admin cleanup (Firebase Console — see §6.3 of the design spec)**

1. Delete the 12 seeded docs (SP-D D5): the six `creator_profiles/creator_*` and six `blueprints/cb_*` docs listed in the design spec §6.3.
2. Blueprints v1 purge (SP-F): delete docs with legacy archetype `category` values or `lh3.googleusercontent.com/aida-public/` imageUrls; set `morning_3.imageUrl` to the verified URL from design §6.3.
3. After the deletion: edit `functions/src/purgeOrphanedUserData.ts` — remove `SYSTEM_PREFIXES = ["creator_"]` (`:48`) and the skip block (`:104-109`), then `cd functions && npm run build && firebase deploy --only functions` (one function) and commit:
```bash
git add functions/src/purgeOrphanedUserData.ts
git commit -m "chore(functions): drop creator_ skip list from purgeOrphanedUserData (seeded docs deleted)"
```

- [ ] **Step 5: Post-deploy verification**
```bash
firebase functions:log --only generateAiRecap,paystackWebhook,applyDailyTribeRecalculation --limit 20
```
Expected: no new `permission-denied`/`ERROR` storms; `applyDailyTribeRecalculation` runs at `0 3 * * *` — verify the next run in logs (or trigger once via `firebase functions:shell`-style invocation if needed).

---

## Task 12: Smoke checklist + rollback drill

**Files:** none (manual QA)

- [ ] **Step 1: Smoke the client queries that must keep working** (design §6.2 checklist) — run the app against production (or point a staging build at prod Firestore):

| Flow | File | Expect |
|---|---|---|
| Archetype clubs stream | `tribe_repository.dart:100-109` | loads, no PERMISSION_DENIED |
| Tribe discovery | `tribes_provider.dart:354-359` | sorts by memberCount desc |
| User tribes | `tribe_repository.dart:248-256` | members array-contains works |
| Verified creators strip | `creator_repository.dart:43-61` | streams (docs still exist until Task 11 cleanup is verified) |
| Join/leave tribe | `tribe_repository.dart:169-245`, `tribe_membership_service.dart:43-126` | memberCount ±1 updates succeed |
| Habit completion + undo | `drift_habit_repository.dart:297,411` | create + delete allowed, update denied |
| Blueprint seed + adopt | `blueprint_repository.dart:59+,641` | `'system'` catalog writes succeed (create + merge update) |
| Posts | `posts` writes | create/update succeed (rateLimited removed) |
| Web premium (SP-B) | `users/{uid}` stream | owner read works |
| Creator signup (SP-E, if client landed) | redeem flow | profile created + claim set |

- [ ] **Step 2: Rollback drill (documented, not executed unless needed)**
```bash
# rules rollback to the previous release:
git show <baseline-SHA>:firestore.rules > firestore.rules && firebase deploy --only firestore:rules
# functions rollback: revert the functions commits, rebuild, redeploy
```
The baseline SHA recorded in Task 1 Step 2 is the rollback point for rules; the pre-Task-6 `functions` tree is the functions rollback point.

- [ ] **Step 3: Optional next-phase hardening (NOT part of this release)**

If SP-G D9's "strong option" is approved later: add `functions/src/joinTribe.ts` (`joinTribe(userId, tribeId, type)`) and `functions/src/leaveTribe.ts` — transactional (membership doc `users/{uid}/tribes/{tribeId}` + `tribes/{id}` memberCount ±1 + contributors merge/keep per SP-G D2), then switch `TribeMembershipService` to call them and tighten the rules aggregate branch to `allow update: if false` for those keys (functions-only). Document as a follow-on sub-task; do not build now.

- [ ] **Step 4: Final report**

Summarize: deploy SHAs, emulator matrix results, smoke results, any `CONFIRM-WITH-USER` items that were resolved differently than the design spec's recommendation (D1.2a `'system'` carve-out, D1.10 `notifyAchievement` removal, D3.4 recalc ownership, D3.7 callables deferral).
