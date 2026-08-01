# SP-H: Firebase Backend Hardening — Rules, Indexes, Functions — Design Spec

> **Sub-project H** of the 8-sub-project program (A→H) for **Emerge** (Firebase project `tradeflash-l2966`, Firestore region `africa-south1`, functions runtime nodejs22 / Gen 2, `us-central1`).
>
> **Scope:** Ship the `firestore.rules`, `firestore.indexes.json`, and `functions/` changes that SP-B…SP-G need, plus the backend audit's own fixes (dead triggers, broken premium gate, spoofable counters). **Documentation only — no code changes in this document.**

**Related specs (siblings, all dated 2026-08-01 unless noted):**
- SP-B: `docs/superpowers/specs/2026-08-01-sp-b-paywall-premium-limits-design.md` (web premium reads `users/{uid}.isPremium`; explicitly defers the Paystack→custom-claims sync and the `generateAiRecap` gate fix to SP-H)
- SP-D: `docs/superpowers/specs/2026-08-01-sp-d-tribes-creators-split-design.md` (deletes the 12 seeded creator docs **admin-side in SP-H**; client code removal only)
- SP-E: `docs/superpowers/specs/2026-08-01-sp-e-creator-invites-design.md` (creator invite codes, function-owned `creator_profiles`, verified-creator writes, `ensureCreatorTribe`; its D4 rule shapes are the base this spec builds on)
- SP-F: `docs/superpowers/specs/2026-08-01-sp-f-blueprints-overhaul-design.md` (blueprints v1 purge + `morning_3` imageUrl fix are **SP-H admin work**; in-app v3 seed writes client-side via the "normal seed path" — constrains the blueprints rule)
- SP-G: `docs/superpowers/specs/2026-07-29-tribe-membership-unified-social-design.md` (recalc respects actual membership; SP-G D9 rules validation / D10 recalc are referenced by the brief — SP-G's plan is not on disk yet; coordination notes below)

---

## 1. Goals

1. **Make the creator economy actually work in production**: client creator signup (`creator_profiles`), blueprint/challenge creation by verified creators, and creator tribes are all **denied by today's rules**. SP-E's client work cannot function without this rules package.
2. **Close the spoofable/duplicate-counter holes** the audit found: tribe `memberCount` (any authenticated user could write any value), `user_stats.isPremium` (never blocked by `isValidStats`), dead `rateLimited()` guard, dead rate-limit trigger.
3. **Kill dead backend code**: `enforceRateLimit` (wrong path + wrong claim — never fires), `onHabitChanged` + `notifyAchievement` (trigger paths nothing writes), plus the dead `rateLimited()` rule helper.
4. **Fix the broken premium gates server-side**: `generateAiRecap` reads `user_stats.isPremium` (nothing writes it) — point it at the real source of truth; sync Paystack purchases into custom claims so the client's claims fallback works on web too (SP-B deferred this here explicitly).
5. **Make `recalcTribes` respect actual membership** (SP-G behavior): explicit `users/{uid}/tribes` membership must win over archetype assignment for **both** the `members` array and the XP aggregation (today XP uses the archetype map even for users who switched tribes).
6. **No new composite indexes** — verified against every SP-B…SP-G client query (see §4). Document the conditional index if a creator-tribe browse query ever lands.

---

## 2. Verified current state (audit findings, re-verified 2026-08-01)

### 2.1 `firestore.rules` (594 lines, helpers at the cited lines)

| Area | Current behavior (file:line) | Verified evidence |
|---|---|---|
| `invite_codes` | **No rules block** → default deny | Friendship invite (`friend_repository.dart:288-348`) writes/reads/deletes `invite_codes` → **broken in prod** |
| `blueprints` | read public; create/update/delete **admin-only** | `firestore.rules:501-504`; creator builder (`blueprint_builder_screen.dart:245-309`) → denied in prod |
| `challenges` | read public; create/update/delete **admin-only** | `firestore.rules:408-410`; `Challenge` model has **no `createdBy`** (SP-E E2) |
| `challengeTemplates` | read-only | `firestore.rules:520-523`; **zero code references** (grep-verified) — keep as-is |
| `tribes` | create: any auth user if `isValidTribe` (`:363`); update: `createdBy==uid` OR admin OR diff `hasOnly(['memberCount','members','lastStatsSync'])` (`:364-371`); delete admin | **memberCount is fully spoofable** — any user can set any tribe's `memberCount`/`members` |
| `creator_profiles` | create: `ownerId == auth.uid` (`:514`) but `CreatorProfile.toMap()` writes `userId` **never** `ownerId` (`creator_profile.dart:93-118`) → on-device signup **denied**; update: `resource.data.ownerId == uid` (same problem); comment `:506-511` claims `creator_*` writable by any auth user — not implemented | signup (`auth_providers.dart:111-119`), Google redirect (`init_app.dart:85`), seeds (`creator_repository.dart:73-193`, `blueprint_repository.dart:641`) all denied in prod |
| `user_stats` | owner create/update with `isValidStats` only (`:267-274`) → **XP spoofable** (accepted, documented); `isValidStats` does **not** block `isPremium`/`premium_since` (no client writes them today — verified) | keep XP as known-accepted; **block `isPremium`** (new) |
| `users/{uid}` | owner read/write; `isValidUser` blocks `isPremium`/`premium_since` (`:55`) | Paystack webhook writes them via admin SDK (bypasses rules) ✓ |
| `contributors` | owner create/update whitelisted keys; **no delete** | `:376-385`; `club_leaderboards` self create/update, delete false (`:419-427`) |
| `rateLimited()` | checks claim `rateLimitUntil` (`:38`), used on `posts` create/update (`:440-441`) | **Nothing ever sets `rateLimitUntil`** (grep: only a comment in `setUserRole.ts:90`); `rateLimiter.ts:44-48` sets `rateLimited`/`flaggedAt` — the guard is dead |
| `habit_completions` | `users/{uid}/habit_completions/{cid}` create/read/delete by owner, update false (`:319-327`; working tree already allows owner delete for undo) | client writes here (`drift_habit_repository.dart:297,411`) ✓ |
| `customers`/`revenuecat_events` | write false (RevenueCat extension) | `:571-582` ✓ |

### 2.2 `firestore.indexes.json` — all 40 collection-scope indexes, `fieldOverrides: []`

Existing coverage that matters to SP-B…SP-G (all verified present): `tribes` type+isVerified+totalXp DESC (`:320-342`), type+archetypeId (`:343-361`); `club_leaderboards` clubId+xp DESC (`:385-403`), +lastUpdated (`:530-552`); `challenge_leaderboards` challengeId+xp (`:404-422`), +lastUpdated (`:553-575`); `creator_profiles` isVerifiedCreator+blueprintCount DESC (`:599-617`); `activity` clubId+timestamp (`:423-441`) + userId+timestamp (`:442-460`); `habits` userId+createdAt DESC (`:23-40`) + userId+isArchived+order+createdAt (`:42-67`); `user_activity` 4 composites (`:87-170`); `user_stats` userId+level DESC (`:171-189`); `posts` userId+timestamp (`:68-86`); `friends`, `notifications`, `partner_requests`, `referrals`, `affiliatePartners`(3), `activities`, `challenges`(4).

### 2.3 `functions/src` inventory (verified)

**Callables:** `setUserRole` (`setUserRole.ts:34`; `role != 'user'` requires admin `:52-56` — meaning **no normal user can ever become `creator` today**); `deleteMyAccount` (`cleanupUserData.ts:38`; tribe member removal `:75-95`, `club_leaderboards` purge `:64`); `purgeOrphanedUserData` (`purgeOrphanedUserData.ts:50`; admin-only `:58`, `SYSTEM_PREFIXES = ["creator_"]` `:48`,`:105-109`); `getAuraInsight`, `getGroqCoachAdvice` (index.ts); `generateAiRecap` (`ai_recap.ts:10`; premium gate reads `user_stats.isPremium` `:30-34` — **nothing writes it, gate always denies**); `createStarterPack` (`create_starter_pack.ts:59`); `fillNarratorSlots` (`narrator.ts:224`); `initializePaystackTransaction` (`paystack.ts:18`).

**Schedulers:** `applyDailyDecayScheduled` (index.ts:90, `0 0 * * *`); `applyDailyMomentumDecay` (index.ts:170, `0 2 * * *`; XP penalty writes `user_stats`); `applyDailyTribeRecalculation` (index.ts:249, `0 3 * * *` → `recalcTribesInternal` `recalcTribes.ts:16`, **6 hardcoded clubs** `:3-10`); `sendDailyInsights` (`habit_notifications.ts:389`, `0 8 * * *`); `refreshQuarterlyChallenges` (`refreshQuarterlyChallenges.ts:68`).

**Firestore triggers:** `onChallengeMembershipChanged` (`challenges.ts:9`, path `users/{userId}/challenges/{challengeId}` — rules allow owner write ✓ alive); `onChallengeRequestCreated` (`challenges.ts:41`, no-op); `onHabitChanged` (`habit_notifications.ts:260`, path `users/{userId}/habits/{habitId}` — **nothing writes that path**: habits live in the top-level `habits` collection, rules don't define the subcollection → **dead**); `notifyAchievement` (`habit_notifications.ts:426`, path `users/{userId}/achievements/{achievementId}` — **nothing writes achievements anywhere** (grep-verified) → **dead**); `enforceRateLimit` (`rateLimiter.ts:13`, path `users/{userId}/habits/{habitId}/completions/{completionId}` — completions are written to `users/{uid}/habit_completions`, and the claim it sets (`rateLimited`) is not what `rateLimited()` checks → **dead**).

**Eventarc:** `revenuecat_events.ts` — `onBillingIssue`, `onSubscriptionRenewed`, `onSubscriptionCancelled`, `onSubscriptionExpired`, `onInitialPurchase`, `onProductChange` (writes `users/{uid}.subscriptionStatus` + FCM; extension owns `customers`).

**HTTP:** `accountDeletion` (`accountDeletion.ts:11`, static page); `paystackWebhook` (`paystack.ts:86`; **only handles `charge.success`** `:122`; writes `users/{uid}.isPremium=true` + `identity_type` + `premium_since` `:130-134`; idempotent via `processed_webhooks` `:114`); `seedOnboardingCatalog` (`seed_starter_habits.ts:407`).

**Not exported:** `seed_templates.ts`, `seedReviewerAccount.ts` (commented at `index.ts:255,258`). `fixTribes.ts` has no exports. **No `onDatabaseCreated`-class triggers. No joinTribe/leaveTribe callables. No server-side XP-awarding function** (the `user_activity` rules comment `:553` references `onUserActivityCreated` — **does not exist**).

**Premium split-brain (verified):** RevenueCat drives the client (`revenue_cat_repository.dart:119-123,218-220` — `entitlements.all[_entitlementId].isActive`); Paystack writes `users/{uid}.isPremium` (`paystack.ts:130-134`); nothing sets custom claims `activeEntitlements`; `generateAiRecap` gates on `user_stats.isPremium` (never written). SP-B makes the web client stream `users/{uid}.isPremium` (owner-read already allowed by rules — no rules change needed there).

---

## 3. Recorded decisions (D1–D4) with fork resolutions

### D1 — Rules package (main deliverable)

| # | Decision | Status |
|---|---|---|
| D1.1 | **`creator_invite_codes`**: full deny for clients (functions-only writes) | Locked (SP-E D1/D4) |
| D1.2 | **`blueprints`**: allow create/update/delete when `creatorUserId == auth.uid` AND caller is a verified creator; admin stays | Locked (SP-E D4) **+ SP-H carve-out D1.2a** |
| D1.2a | **`blueprints` system-catalog carve-out (SP-H fork):** SP-E's exact rule shape breaks the in-app seed — `_createSeed` writes `creatorUserId: 'system'` (`blueprint_repository.dart:380-398`) and SP-F's v3 seed backfill "updates the 30 seeded docs in-app via the normal seed path" (SP-F spec D3). Add: any authenticated user may create/update docs with `creatorUserId == 'system'` (delete stays admin/creator-only). **Flagged CONFIRM-WITH-USER** (deviates from SP-E's literal rule shape) | **RECOMMENDED: include the carve-out** |
| D1.3 | **`challenges`**: allow create/update/delete when `createdBy == auth.uid` AND verified creator; admin stays (SP-E adds `createdBy` to the model + `createCatalogChallenge`) | Locked (SP-E D4/E1/E2) |
| D1.4 | **`tribes`**: `isValidTribe` relaxed for type `'creator'` (archetypeId optional; `createdBy == auth.uid`; creator must be verified); memberCount/members updates get **diff validation + memberCount ±1 constraint** per SP-G D9 | Locked (SP-E D4 + SP-G D9) |
| D1.5 | **`creator_profiles`**: **function-owned** (SP-E chose this branch): create admin-only + `creator_`-prefix auth carve-out; update owner-allowed on a non-privileged whitelist; delete admin-only; read public | Locked — mirror SP-E D4 exactly |
| D1.6 | **`invite_codes` (friendship)**: **leave broken, out of scope.** No rules block is added; the friendship invite stays default-deny and SP-E's `creator_invite_codes` becomes the invite mechanism | **FORK RESOLVED: leave as-is, documented** |
| D1.7 | **`rateLimited()` + `enforceRateLimit`**: **remove both** (dead: path mismatch, claim mismatch). `posts` rules drop the `rateLimited()` calls (behavior unchanged — guard was a no-op) | **FORK RESOLVED: removal** |
| D1.8 | **`user_stats` XP spoofing**: **document as known-accepted** (server-authoritative XP is a larger project). No change | Locked |
| D1.9 | **`user_stats.isPremium`/`premium_since`**: **add to the `isValidStats` deny-list** (closes the spoof; nothing legitimately writes them — verified). `users/{uid}` stays as-is (already blocked); SP-B reads it on web (owner-read allowed) | Locked (+1 small rule change beyond the brief) |
| D1.10 | **`notifyAchievement`**: dead (no writer of `users/{uid}/achievements`). **Remove** alongside `onHabitChanged`. **Flagged CONFIRM-WITH-USER** (brief listed only `onHabitChanged`) | **RECOMMENDED: remove both in one task** |

### D2 — Indexes

**Decision: add NO new indexes.** Verified against every SP-B…SP-G client query:

- `creator_invite_codes` — `generateCreatorInviteCode` counts outstanding via `where("creatorUid","==",uid)` (single-field → auto-indexed); redeem lookup is by code = **doc id** → no composite needed.
- Creator tribes listing — **no client query filters `type == 'creator'` today** (grep-verified: only `type == official` in `tribe_repository.dart:80,92,103` and `tribes_provider.dart:305`; `discoveryClubsProvider` orders by `memberCount` alone). SP-E's creator tribe surfaces via `getUserTribes`/`watchUserTribes` (`members` array-contains, single-field) and `creator_profiles.tribeId` reads. **Conditional add (exact JSON in §4) if a browse query for creator tribes appears in SP-D/SP-E follow-up.**
- `blueprints` — SP-F: "No new Firestore indexes — the whole collection keeps being streamed and filtered client-side" ✓.
- Functions' own queries — `recalcTribes` uses collection streams (no indexes); `deleteMyAccount` `members` array-contains (single-field); `generateAiRecap` `user_activity` userId+type+date (index exists); `habits` userId (index exists). No additions.

### D3 — Functions

| # | Decision |
|---|---|
| D3.1 | **`creator_invites.ts`** (SP-E D1/D5): `generateCreatorInviteCode`, `redeemCreatorInvite`, `ensureCreatorTribe` — full implementation spec in §5. **Ownership split:** SP-E's design claims these functions, but SP-E's plan is not on disk; SP-H's plan implements them per this spec **unless SP-E's plan has already shipped them at execution time** (then SP-H only deploys + verifies). |
| D3.2 | **`paystack.ts` claim sync**: on `charge.success`, after the `users/{uid}` write, merge custom claims `activeEntitlements: ['premium']` (idempotent; preserves other claims). The webhook handles **only** `charge.success` — no refund event exists to clear claims; clearing is future work when refund events are wired. (SP-B D2 explicitly deferred this here.) |
| D3.3 | **`generateAiRecap` gate fix**: read `users/{uid}`; gate on `isPremium === true || subscriptionStatus === 'active'` (the second covers RevenueCat subscribers via the eventarc handlers `revenuecat_events.ts`). `user_stats.isPremium` is dropped entirely. |
| D3.4 | **`recalcTribes` generalization (SP-G D10)**: use the **resolved** membership map (explicit `users/{uid}/tribes` wins over archetype) for BOTH `members`/`memberCount` and the **XP aggregation** (today XP uses the archetype map at `recalcTribes.ts:83-105` even for users whose explicit membership differs — inconsistent with the members array `:69-74`). Never touch non-official (creator) tribes. **FORK RESOLVED: SP-H owns implementation (it is a functions change); if SP-G's plan ships it first, SP-H skips implementation and only deploys/verifies.** |
| D3.5 | **`purgeOrphanedUserData`**: after SP-H's admin deletion of the 12 seeded docs (SP-D D5), remove the now-obsolete `SYSTEM_PREFIXES = ["creator_"]` skip (`purgeOrphanedUserData.ts:48`). |
| D3.6 | **Delete dead code**: `rateLimiter.ts` (file + `index.ts:261` export), `onHabitChanged` + `notifyAchievement` (`habit_notifications.ts:260-374,426-452`; keep `sendDailyInsights` + notification helpers). |
| D3.7 | **joinTribe/leaveTribe callables (SP-G D9 "strong option")**: **DECISION — next-phase, optional task in the plan** (transactional membership doc + memberCount ±1 + contributor merge/keep per SP-G D2). The core SP-H rules package carries the ±1 diff validation; the callables are listed as an optional hardening task, not core, because SP-G D9 chose rules validation and the client still writes directly. |

### D4 — Deployment & verification

- Pre-deploy rules lint: `firebase deploy --only firestore:rules --dry-run` — **flag verified**: firebase CLI 15.22.3 (global install at `C:\Users\HP\AppData\Roaming\npm\firebase`) supports `--dry-run` ("validates your changes and builds your code without deploying").
- Deploy: `firebase deploy --only firestore:rules,firestore:indexes` then `firebase deploy --only functions` (functions built first via `npm run build`; predeploy hook `npm --prefix "$RESOURCE_DIR" run build` already configured in `firebase.json`).
- Emulators: `firebase.json` already configures firestore 8080 / auth 9099 / functions 5001 / ui 4000 (singleProjectMode). Rules are hot-reloaded by the emulator; the plan includes an emulator verification matrix (§6.2) — **no rules unit-test harness exists** (no `@firebase/rules-unit-testing` in either package.json; root `firestore-tests/` contains only logs) → emulator-based matrix + functions jest unit tests (jest + ts-jest + firebase-functions-test offline, already configured; **`npm run build` must precede `npm test`** — tests `require("../lib/index")`).
- Post-deploy smoke checklist: §6.3 (the client queries that must keep working).

---

## 4. Indexes spec

### 4.1 Additions — NONE (see D2)

### 4.2 Conditional (add only when a client query for creator-tribe browsing lands)

Exact JSON to append to `firestore.indexes.json` when SP-D/SP-E follow-up introduces `tribes.where('type','==','creator').orderBy(...)`:

```json
{
  "collectionGroup": "tribes",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "type", "order": "ASCENDING" },
    { "fieldPath": "createdAt", "order": "DESCENDING" },
    { "fieldPath": "__name__", "order": "DESCENDING" }
  ],
  "density": "SPARSE_ALL"
}
```

(and/or `type ASC + memberCount DESC + __name__ DESC` if the browse sorts by popularity). Do not pre-add: unused composite indexes consume quota and the brief mandates "add only what SP-B…SP-G actually query".

---

## 5. Functions spec

### 5.1 New — `functions/src/creator_invites.ts` (SP-E D1/D5, ownership note D3.1)

```ts
export const generateCreatorInviteCode = onCall(async (request) => Promise<{ code: string }>);
```
- Auth required; `permission-denied` unless caller is a **verified creator** (custom claim `role == 'creator'` AND `creator_profiles/{uid}.isVerifiedCreator == true` — checked server-side, never trust the client).
- Rate limit: count `creator_invite_codes.where("creatorUid","==",uid)` (single-field query), filter `redeemedBy == null` in memory (Firestore can't query `== null`; redeemed codes are deleted so in practice all are outstanding); ≥ `MAX_OUTSTANDING_CODES = 10` → `resource-exhausted`.
- 8-char code from an ambiguity-free alphabet (e.g. `ABCDEFGHJKMNPQRSTUVWXYZ23456789`), collision retry loop ≤5 (then `internal`).
- Writes `creator_invite_codes/{code}` `{ creatorUid, createdAt: serverTimestamp, expiresAt (7 days), redeemedBy: null }`.

```ts
export const redeemCreatorInvite = onCall(async (request) => Promise<{ ok: true; role: 'creator' }>);
```
- Auth required; params `{ code: string, displayName?: string }`. Reject if caller already a creator (`creator_profiles/{uid}` exists or claim `role == 'creator'`).
- Firestore **transaction** (atomic): read code doc → must exist, not expired, `redeemedBy == null` → write `creator_profiles/{uid}` `{ userId: uid, ownerId: uid, role: 'creator', displayName, isVerifiedCreator: true, createdAt }`, delete the code doc (single-use).
- After commit: `admin.auth().setCustomUserClaims(uid, { ...existing, role: 'creator' })` (merge — preserve any other claims).

```ts
export const ensureCreatorTribe = onCall(async (request) => Promise<{ tribeId: string; created: boolean }>);
```
- Auth required; verified-creator gate; params `{ blueprintId?: string }`.
- Find existing: `tribes.where("createdBy","==",uid).where("type","==","creator").limit(1)` (composite `createdBy`+`type` — **single-field? no: two equality fields → composite needed? No** — two equality constraints on distinct fields DO require a composite index. **Index note:** add `tribes` `createdBy ASC + type ASC` composite, or query by `type == 'creator'` then filter in memory (collection is small). **Decision: in-memory filter on `where("type","==","creator")` (single-field, auto-indexed) to avoid an index addition** — the creator-tribe count per user is ≤1 and the collection is small; alternatively add the tiny `createdBy+type` composite. Flagged as a no-new-index preference; the plan picks the in-memory filter.)
- Create if missing: `{ type: 'creator', name: <profile displayName>, createdBy: uid, members: [uid], memberCount: 1, archetypeId: <profile archetype or absent>, createdAt }`.
- Writes `creator_profiles/{uid}.tribeId = tribeId` and, if `blueprintId` given, `blueprints/{blueprintId}.creatorTribeId = tribeId`.
- Export from `index.ts`: `export * from "./creator_invites";`.

### 5.2 Modified — `functions/src/payments/paystack.ts` (D3.2)

In `paystackWebhook`, inside the existing `charge.success` branch **after** the `users/{uid}` merge write (`:130-134`), before the idempotency marker (`:143`):

```ts
try {
  const auth = admin.auth();
  const userRecord = await auth.getUser(uid);
  await auth.setCustomUserClaims(uid, {
    ...(userRecord.customClaims ?? {}),
    activeEntitlements: ["premium"],
  });
} catch (err) { logger.error("Claim sync failed:", err); } // never fail the webhook ack
```

Idempotent (merges existing claims; repeated webhooks are already deduped by `processed_webhooks`). Refund/expiry claim-clearing is future work — the webhook only handles `charge.success` today.

### 5.3 Modified — `functions/src/ai_recap.ts` (D3.3)

Replace `:26-34`:

```ts
const userDoc = await db.collection("users").doc(userId).get();
const userData = userDoc.data();
const isPremium = userData?.isPremium === true || userData?.subscriptionStatus === "active";
if (!isPremium) { ...throw new HttpsError("permission-denied", "AI Insights are a premium feature."); }
```

### 5.4 Modified — `functions/src/recalcTribes.ts` (D3.4, SP-G D10)

- Keep the explicit-membership scan (`:48-66`) and the "explicit wins" resolution (`:69-74`).
- **Fix**: build the resolved membership map ONCE (`userId → resolved tribeId`), then drive **both** the `members`/`memberCount` arrays **and** the XP aggregation (`:83-105` must use the resolved map, not `userToTribeMap`).
- Only ever write the 6 official club docs (`tribeRef` targets unchanged) — creator/user tribes are never touched by the scheduler.
- Note: `applyDailyTribeRecalculation` (`index.ts:249`) is the deployment surface; no signature change.

### 5.5 Modified — `functions/src/purgeOrphanedUserData.ts` (D3.5)

Remove `SYSTEM_PREFIXES = ["creator_"]` (`:48`) and the skip logic (`:104-109`) **after** the SP-H admin deletion of the 12 seeded docs (SP-D D5). Do this in the same deploy task as the deletion.

### 5.6 Modified — `functions/src/index.ts`

- Add `export * from "./creator_invites";`
- Remove `export * from "./rateLimiter";` (`:261`)
- `habit_notifications` export stays (still exports `sendDailyInsights`); `onHabitChanged` + `notifyAchievement` are removed inside the file.

### 5.7 Deleted

| File/export | Reason |
|---|---|
| `functions/src/rateLimiter.ts` | Dead trigger: path `users/{uid}/habits/{hid}/completions/{cid}` matches nothing the client writes (completions → `users/{uid}/habit_completions`); claim it sets (`rateLimited`) ≠ claim `rateLimited()` checks (`rateLimitUntil`); no other writer of `security_logs` exists |
| `onHabitChanged` (in `habit_notifications.ts:260-374`) | Trigger path `users/{userId}/habits/{habitId}` — habits live in the top-level `habits` collection; no client/function writes the subcollection |
| `notifyAchievement` (in `habit_notifications.ts:426-452`) | Trigger path `users/{userId}/achievements/{achievementId}` — nothing writes achievements anywhere (grep-verified) |

---

## 6. Deployment plan & verification

### 6.1 Deployment

1. **Pre-flight**: `firebase login` / `firebase projects:list` (confirm `tradeflash-l2966`); `firebase use tradeflash-l2966`. CLI 15.22.3 global. Working tree is dirty (pre-existing changes) — commit only named files, never `git add -A`.
2. **Rules lint (pre-deploy)**: `firebase deploy --only firestore:rules --dry-run` — validates syntax without deploying (verified flag exists in CLI 15.22.3).
3. **Functions build + tests**: `cd functions && npm run build && npm test` (jest + firebase-functions-test offline; tests require `../lib/index`, so build first — SP-E spec §tools confirms).
4. **Deploy**: `firebase deploy --only firestore:rules,firestore:indexes` → `firebase deploy --only functions`. (Indexes: no changes — deploy is a no-op there.)
5. **Rollback**: `git show HEAD:firestore.rules > firestore.rules && firebase deploy --only firestore:rules` (+ `firebase deploy --only functions` from the previous release commit).

### 6.2 Verification strategy

- **Functions**: jest unit tests (offline `firebase-functions-test`, `.run({auth, data})`, assert `rejects.toHaveProperty("code", ...)` — mirrors `functions/test/index.test.ts`). New tests: ai_recap gate (users.isPremium true/false/subscriptionStatus), paystack claim sync, recalcTribes resolved-membership aggregation, creator_invites (verified-creator gate, outstanding cap, atomic redeem, claim set), and an index.test.ts assertion that `enforceRateLimit`/`onHabitChanged`/`notifyAchievement` are no longer exported.
- **Rules**: no harness exists → **emulator matrix** with `firebase emulators:start --only firestore,auth,functions` (or `--import`/`--export-on-exit` for repeatable state). Matrix (each row = manual/scripted check; authenticated rows use an Auth-emulator token):
  1. unauthenticated reads of `blueprints`, `challenges`, `creator_profiles`, `tribes` → allow; writes → deny
  2. `users/{uid}` owner read ✓; other-user read ✗; owner write of `isPremium` ✗ (unchanged)
  3. `user_stats/{uid}` owner write of `isPremium` → **deny (new)**
  4. `creator_profiles` create by normal user ✗; by admin ✓; `creator_`-prefixed by auth user ✓; update flipping `isVerifiedCreator` ✗; onboarding-field update ✓; delete by non-admin ✗
  5. `blueprints` create `creatorUserId == uid` by non-verified creator ✗; by verified creator (claim `role=creator` + verified profile) ✓; `creatorUserId == 'system'` by any auth user ✓ (carve-out); admin ✓
  6. `challenges` create `createdBy == uid` by verified creator ✓; by non-verified ✗; admin ✓
  7. `tribes` create `type=='creator'` by non-verified ✗ / verified ✓; `type=='official'` by any auth user ✓
  8. `tribes` update memberCount +1 / −1 → ✓; ±5 → ✗; `totalXp`-only update by non-owner ✗; owner (`createdBy`) full update ✓; admin ✓
  9. `creator_invite_codes` read/write → ✗ (deny); `invite_codes` → ✗ (unchanged, documented)
  10. `habit_completions` owner create/delete ✓; update ✗; `posts` create ✓ (rateLimited removed)
  11. `club_leaderboards` self create/update ✓; delete ✗; `contributors` owner create/update ✓; delete ✗
- **Post-deploy smoke checklist (client queries that must keep working)**:
  - `watchArchetypeClubs` (`tribe_repository.dart:100-109`, `type == official`) + `getArchetypeClubs` (`:89-97`, type+orderBy archetypeId)
  - `discoveryClubsProvider` (`tribes_provider.dart:354-359`, orderBy memberCount desc)
  - `watchUserTribes`/`getUserTribes` (members array-contains)
  - `verifiedCreatorsStreamProvider` → `watchVerifiedCreators` (`creator_repository.dart:43-61`, isVerifiedCreator+blueprintCount desc)
  - `joinClub`/`leaveClub` + `TribeMembershipService.joinTribe/leaveTribe` (members + memberCount ±1 paths)
  - tribe blueprints (`tribe_blueprints_provider`, SP-F — stream + client filter)
  - `habit_completions` undo-delete (already in working-tree rules)
  - `club_leaderboards` drift sync writes
  - SP-B web premium stream (`users/{uid}` owner read)
  - SP-E creator signup + blueprint/challenge creation (requires SP-E client landed; until then the rules simply keep denying)

### 6.3 Admin cleanup (part of SP-H, per SP-D D5 / SP-F)

- Delete the 12 seeded docs: `creator_profiles/{creator_aria_chen, creator_marcus_okafor, creator_sora_tanaka, creator_julian_cross, creator_naia_singh, creator_elias_vance}` and `blueprints/{cb_aria_deep_work, cb_marcus_morning, cb_sora_creative, cb_julian_calm, cb_naia_devotion, cb_elias_studio}` (Firebase Console or admin script — client deletion is denied by rules, by design).
- Blueprints v1 purge (SP-F): delete docs with legacy archetype categories (`Athlete`, `Creator`, `Scholar`, `Stoic`, `Zealot`) or `imageUrl` starting `https://lh3.googleusercontent.com/aida-public/`; fix `morning_3.imageUrl` → `https://images.unsplash.com/photo-1528715471579-d1bcf0ba5e83?w=800`.
- After deletion: remove the `creator_` skip list from `purgeOrphanedUserData.ts` (D3.5).

---

## 7. Out of scope

- **Server-authoritative XP** (`user_stats` spoofing) — documented accepted (D1.8); no `onUserActivityCreated` function is built.
- **Friendship `invite_codes`** — left broken (D1.6); SP-E's creator invites replace the pattern.
- **RevenueCat→claims entitlement sync** (beyond the Paystack claim sync) and refund/expiry claim clearing — future work (D3.2 note).
- **`challengeTemplates`**, `starter_habit_blueprints`, `interest_catalog`, `customers`, `revenuecat_events` — unchanged (read-only / extension-owned).
- **joinTribe/leaveTribe callables** — next-phase optional task (D3.7), not core.
- Client code changes of SP-B…SP-G (this spec only makes the backend that enables them).
- `setUserRole`'s admin-gated role promotion — SP-E changes the signup flow to bypass it (`redeemCreatorInvite` sets the claim); no change here.

## 8. Risks & client-change mapping (every rule change ↔ SP-B…SP-G)

| Rule change | Breaks if… | Enabling client change |
|---|---|---|
| `tribes` aggregate update + memberCount ±1 | A client writes non-±1 memberCount (current paths verified ±1: `tribe_repository.dart:204-208,240-244`, `tribe_membership_service.dart:49-53,117-120`). Edge: `leaveTribe` clamp-at-0 (`:118`) writes 0 when count is 0 → denied (corrupt-state edge, accepted). `syncTribeStats` (`tribe_stats_service.dart:236-254`) already denied today (writes `totalXp` etc. — not in the whitelist) → stays broken, **silently no-ops**; `recalcTribes` is the authority | SP-G D9 (rules validation) + optional SP-H callables |
| `tribes` create gate (`type=='creator'` ⇒ verified) | A non-verified user creates a creator tribe (denied — intended) | SP-E D5 `ensureCreatorTribe` (function) |
| `creator_profiles` function-owned | Client writes at signup/onboarding (denied — intended); seeds (`creator_repository.dart:73-193`, `blueprint_repository.dart:641`) already broken today, replaced by function creation | SP-E D3 (§4.3.4: `signUpCreator` rewrite, onboarding provider drops the `role` rewrite), E3 (`ownerId` in `toMap`) |
| `blueprints` verified-creator + `'system'` carve-out | In-app v2/v3 seeds write `creatorUserId:'system'` (carve-out covers); creator builder without verification (denied — intended) | SP-E D4/D7 (builder writes `creatorUserId == uid`); SP-F D3 (v3 seed — needs the carve-out, **flagged**) |
| `challenges` `createdBy` | Seeds (`seed_runner.dart:29-112`) have no `createdBy` → stay denied (already broken today; prod data exists) | SP-E E1/E2 (`createCatalogChallenge` + model field) |
| `isVerifiedCreator()` claim dependency | Before SP-E ships `redeemCreatorInvite`, no user has `role='creator'` claim → all creator-write rules deny (safe default; same as today) | SP-E D1 (claim set server-side) |
| `isValidStats` blocks `isPremium`/`premium_since` | Nothing legitimately writes them (grep-verified) | none |
| `rateLimited()` removal | None (guard was dead — claim never set) | none |
| Dead trigger removals | None (paths unwritten) | none |
| `generateAiRecap` gate → `users.isPremium`/`subscriptionStatus` | RevenueCat-only subscribers without eventarc writes still denied (gate covers `subscriptionStatus=='active'` when events fire) | SP-B (web reads `users.isPremium`); note client does not call `generateAiRecap` today |
| `recalcTribes` XP by resolved membership | Leaderboard XP shifts for users who switched tribes (intended; SP-G scope) | SP-G D10 |

**Deploy ordering:** the rules package is safe to deploy before SP-E's client (it only *denies more* for non-verified-creator paths and preserves every verified current client write: tribes ±1 paths, seeds with `type=='official'`, `creator_` seeds, `'system'` blueprints). Functions deploy together with rules. The `creator_invites` functions and the SP-E client must land as a pair (signup UX depends on them).

## 9. Decisions flagged CONFIRM-WITH-USER

1. **D1.2a blueprints `'system'` catalog carve-out** (deviates from SP-E's literal rule shape; required for SP-F's in-app seed) — recommended: include.
2. **D1.10 remove `notifyAchievement`** (dead trigger, beyond the brief's `onHabitChanged`) — recommended: remove in the same task.
3. **D3.7 joinTribe/leaveTribe callables** — included only as an optional next-phase task; core hardening is the rules ±1 validation.
4. **`ensureCreatorTribe` lookup**: in-memory filter on `type=='creator'` (no new index) vs. adding a `createdBy+type` composite — preferred: no new index.
5. **`recalcTribes` ownership** (D3.4): SP-H implements unless SP-G's plan ships it first.
