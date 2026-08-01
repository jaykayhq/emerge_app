# SP-E: Creator Invite Codes + Creator Creation Rights — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A default creator account with an invite-code generator; new creators redeem codes; invite-redeemed (verified) creators can create challenges, blueprints, and creator tribes. Fixes the end-to-end-broken creator system: denied `creator_profiles` writes (`ownerId` mismatch), admin-only `setUserRole` (signup's role promotion always rejected), admin-only `blueprints`/`challenges` rules, tribe validation that forbids creator tribes, and the dashboard bounce on fresh signups.

**Architecture:** Server-authoritative invite system: new `creator_invite_codes/{code}` collection (functions-only), three new callables in `functions/src/creator_invites.ts` (`generateCreatorInviteCode`, `redeemCreatorInvite`, `ensureCreatorTribe`), `firestore.rules` granting verified creators write rights on `blueprints`/`challenges`/`tribes` while keeping `creator_profiles` server-owned, an `ADMIN_SECRET`-guarded `seedCreatorAccount.ts` default-account script, invite-gated creator signup, and a dashboard-bounce loading guard.

**Tech Stack:** Flutter 3.x, Dart 3.10+, Riverpod 3.x, Firebase Auth/Firestore/Cloud Functions (Gen 2, Node 22), TypeScript 5.9, jest + ts-jest + firebase-functions-test (offline), fake_cloud_firestore, firebase_auth_mocks.

**Spec:** `docs/superpowers/specs/2026-08-01-sp-e-creator-invites-design.md`

---

## ⚠️ Pre-flight (read first)

1. **The working tree is dirty** (pre-existing uncommitted changes across ~20 files — notably `firestore.rules`, `lib/core/drift/*`, `lib/core/router/router.g.dart`, several `lib/features/*` and `test/*` files, plus untracked `.zcode/`, `lib/features/habits/presentation/providers/habit_recommendations_provider.dart`, `lib/features/timeline/domain/`). **Commit only the files each task names** — never `git add -A` or `git add lib` wholesale.
2. **`firestore.rules` is ALREADY modified** in the worktree. Inspect the diff before editing (`git diff firestore.rules`) and preserve unrelated hunks; the rule edits in Tasks 6–7 apply on top.
3. **Functions tests need a build first:** `functions/test/*.test.ts` `require("../lib/index")` (compiled output) and jest coverage collects from `lib/**/*.js`. Every functions test step is `npm run build` then `npm test`/`npx jest`.
4. Deploy ordering matters: **functions → rules → client**. Old clients writing `creator_profiles` would be denied by the new rules — acceptable; the new redeem flow never writes client-side.
5. `ADMIN_SECRET`, `CREATOR_EMAIL`, `CREATOR_PASSWORD` must exist as function secrets/env before Task 4's script can be exercised (emulator reads `.env`/secrets; in the emulator set `FIREBASE_CONFIG`/env vars locally).
6. Baseline before starting: `cd functions && npm run build && npm test` should pass, and `flutter test test/features/auth/presentation/screens/creator_signup_screen_test.dart test/features/social/presentation/screens/creator/creator_dashboard_scaffold_test.dart` should pass.

## File structure

### New files

| Path | Responsibility |
|---|---|
| `functions/src/creator_invites.ts` | `generateCreatorInviteCode`, `redeemCreatorInvite`, `ensureCreatorTribe` + shared helpers |
| `functions/src/seedCreatorAccount.ts` | D2 default creator account seed (ADMIN_SECRET + `CREATOR_EMAIL`/`CREATOR_PASSWORD` secrets) |
| `functions/test/creator_invites.test.ts` | Jest offline tests for the three callables |
| `functions/test/seedCreatorAccount.test.ts` | Seed script guard tests (auth header, env requirements) |
| `test/features/social/presentation/screens/creator/creator_create_challenge_dialog_test.dart` | Widget tests for the new dialog |

### Modified files

| Path | Change |
|---|---|
| `firestore.rules` | `isVerifiedCreator()` helper; `creator_invite_codes` deny block; `creator_profiles` create/update; `blueprints`, `challenges` creator rights; `isValidTribe` + `tribes` create |
| `functions/src/index.ts` | `export * from "./creator_invites";` (+ commented `seedCreatorAccount` export) |
| `lib/features/auth/presentation/providers/auth_providers.dart` | `signUpCreator`/`signUpCreatorWithGoogle` rewritten to redeem callable |
| `lib/features/auth/presentation/screens/creator_signup_screen.dart` | Invite-code field + wiring |
| `lib/features/social/presentation/screens/creator/creator_dashboard_scaffold.dart` | Loading-guard on the verified listener |
| `lib/features/social/presentation/screens/creator/blueprint_builder_screen.dart` | `ensureCreatorTribe` call after publish |
| `lib/features/social/presentation/screens/creator/creator_tribe_management_tab.dart` | Create-Challenge dialog (replaces "launching soon" stub) |
| `lib/features/social/domain/models/challenge.dart` | `createdBy` + `createdAt` fields |
| `lib/features/social/data/repositories/challenge_repository.dart` (+ `lib/features/social/data/repositories/firebase_challenge_repository.dart` if that is the impl file) | `createCatalogChallenge` |
| `lib/features/social/domain/entities/creator_profile.dart` | `toMap()` writes `ownerId` |
| `lib/features/onboarding/presentation/providers/creator_onboarding_provider.dart` | Drop `role` from the merge; remove the `setUserRole` mirror call |
| `test/features/auth/presentation/screens/creator_signup_screen_test.dart` | Invite-code field tests |
| `test/features/auth/presentation/screens/creator_login_screen_test.dart` | (only if login behavior changes — it doesn't; skip unless a test breaks) |
| `test/features/social/presentation/screens/creator/creator_dashboard_scaffold_test.dart` | Loading-guard tests |
| `test/features/social/presentation/screens/creator/blueprint_builder_screen_test.dart` (if exists; else create) | Publish → `ensureCreatorTribe` wiring |
| `test/features/social/data/repositories/creator_repository_test.dart` | `toMap` includes `ownerId` |

---

# Phase 1 — Cloud Functions (TDD, jest offline)

## Task 1: `generateCreatorInviteCode` + shared helpers + tests

**Files:**
- Create: `functions/src/creator_invites.ts`
- Create: `functions/test/creator_invites.test.ts`

- [ ] **Step 1: Write the failing test**

```ts
/**
 * Tests for creator_invites.ts — offline mode (no emulator).
 * Run with: cd functions && npm run build && npx jest test/creator_invites.test.ts
 */
// eslint-disable-next-line @typescript-eslint/no-require-imports
const ft = require("firebase-functions-test")();

// Stub admin so no real Firebase is contacted.
const setCustomUserClaims = jest.fn().mockResolvedValue(undefined);
const getUser = jest.fn();
const docGet = jest.fn();
const docSet = jest.fn();
const docDelete = jest.fn();
const queryGet = jest.fn();
const runTransaction = jest.fn();
const collection = jest.fn(() => ({
  doc: jest.fn(() => ({
    get: docGet,
    set: docSet,
    delete: docDelete,
  })),
  where: jest.fn(() => ({ get: queryGet })),
}));

jest.mock("firebase-admin", () => ({
  apps: [],
  initializeApp: jest.fn(),
  firestore: () => ({
    collection,
    runTransaction,
  }),
  auth: () => ({ getUser, setCustomUserClaims }),
}));

// eslint-disable-next-line @typescript-eslint/no-require-imports
const { generateCreatorInviteCode } = require("../src/creator_invites");

const CODE_PATTERN = /^[A-Z2-9]{8}$/;

beforeEach(() => {
  jest.clearAllMocks();
  // Default: caller is a verified creator.
  getUser.mockResolvedValue({ customClaims: { role: "creator" } });
  docGet.mockResolvedValue({ exists: true, data: () => ({ isVerifiedCreator: true }) });
  queryGet.mockResolvedValue({ size: 0, docs: [], forEach: jest.fn() });
});

describe("generateCreatorInviteCode", () => {
  it("rejects unauthenticated calls", async () => {
    await expect(
      generateCreatorInviteCode.run({ auth: undefined, data: {} })
    ).rejects.toHaveProperty("code", "unauthenticated");
  });

  it("rejects non-creator claims", async () => {
    getUser.mockResolvedValue({ customClaims: { role: "user" } });
    await expect(
      generateCreatorInviteCode.run({ auth: { uid: "u1" }, data: {} })
    ).rejects.toHaveProperty("code", "permission-denied");
  });

  it("rejects a creator claim with no verified profile doc", async () => {
    docGet.mockResolvedValue({ exists: false, data: () => null });
    await expect(
      generateCreatorInviteCode.run({ auth: { uid: "u1" }, data: {} })
    ).rejects.toHaveProperty("code", "permission-denied");
  });

  it("rejects when 10 codes are already outstanding", async () => {
    queryGet.mockResolvedValue({
      size: 10,
      docs: Array.from({ length: 10 }, (_, i) => ({ data: () => ({ redeemedBy: null }) })),
      forEach: jest.fn((cb) => {
        for (let i = 0; i < 10; i++) cb({ data: () => ({ redeemedBy: null }) });
      }),
    });
    await expect(
      generateCreatorInviteCode.run({ auth: { uid: "u1" }, data: {} })
    ).rejects.toHaveProperty("code", "resource-exhausted");
  });

  it("creates a doc and returns an 8-char ambiguity-free code", async () => {
    docGet.mockResolvedValue({ exists: false, data: () => null }); // no collision
    const result = await generateCreatorInviteCode.run({ auth: { uid: "u1" }, data: {} });
    expect(CODE_PATTERN.test(result.code)).toBe(true);
    expect(docSet).toHaveBeenCalled();
    const written = docSet.mock.calls[0][0];
    expect(written.creatorUid).toBe("u1");
    expect(written.redeemedBy).toBeNull();
    expect(written.expiresAt).toBeInstanceOf(Date);
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd functions && npm run build && npx jest test/creator_invites.test.ts`
Expected: FAIL — `../src/creator_invites` has no export `generateCreatorInviteCode`.

- [ ] **Step 3: Implement `functions/src/creator_invites.ts` (helpers + generator)**

```ts
/**
 * Creator invite-code system (SP-E). Server-authoritative: clients have NO
 * access to creator_invite_codes; every code is generated here and redeemed
 * here. Verification (claim + profile) is always checked server-side.
 */
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { randomInt } from "node:crypto";
import * as admin from "firebase-admin";

if (admin.apps.length === 0) {
  admin.initializeApp();
}

const db = admin.firestore();

export const CODE_CHARS = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"; // no 0/O/1/I/L
export const CODE_LENGTH = 8;
export const CODE_TTL_MS = 7 * 24 * 60 * 60 * 1000; // 7 days
export const MAX_OUTSTANDING_CODES = 10;
export const CODE_PATTERN = /^[A-Z2-9]{8}$/;

export async function isVerifiedCreator(uid: string): Promise<boolean> {
  const [userRecord, profile] = await Promise.all([
    admin.auth().getUser(uid),
    db.collection("creator_profiles").doc(uid).get(),
  ]);
  const claims = userRecord.customClaims ?? {};
  return (
    claims.role === "creator" &&
    profile.exists &&
    profile.data()?.isVerifiedCreator === true
  );
}

export function generateCode(): string {
  let code = "";
  for (let i = 0; i < CODE_LENGTH; i++) {
    code += CODE_CHARS[randomInt(CODE_CHARS.length)];
  }
  return code;
}

export function generateCode(): string {
  let code = "";
  for (let i = 0; i < CODE_LENGTH; i++) {
    code += CODE_CHARS[randomInt(CODE_CHARS.length)];
  }
  return code;
}

export const generateCreatorInviteCode = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be logged in.");
  }
  const uid = request.auth.uid;
  if (!(await isVerifiedCreator(uid))) {
    throw new HttpsError(
      "permission-denied",
      "Only verified creators can generate invite codes."
    );
  }

  // Outstanding count: query by creatorUid (Firestore cannot filter
  // `== null`), filter redeemedBy in memory. Redeemed codes are deleted,
  // so in practice every doc under creatorUid is outstanding.
  const snapshot = await db
    .collection("creator_invite_codes")
    .where("creatorUid", "==", uid)
    .get();
  let outstanding = 0;
  snapshot.forEach((doc) => {
    if (doc.data().redeemedBy == null) outstanding++;
  });
  if (outstanding >= MAX_OUTSTANDING_CODES) {
    throw new HttpsError(
      "resource-exhausted",
      `You have ${MAX_OUTSTANDING_CODES} outstanding invite codes — redeem them or wait for expiry.`
    );
  }

  // Collision-retry (≤5 attempts; 32^8 space makes this vanishingly rare).
  let code = generateCode();
  for (let attempt = 0; attempt < 5; attempt++) {
    const existing = await db.collection("creator_invite_codes").doc(code).get();
    if (!existing.exists) break;
    code = generateCode();
    if (attempt === 4) {
      throw new HttpsError("internal", "Could not generate a unique code.");
    }
  }

  await db.collection("creator_invite_codes").doc(code).set({
    creatorUid: uid,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    expiresAt: new Date(Date.now() + CODE_TTL_MS),
    redeemedBy: null,
  });

  return { code };
});
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd functions && npm run build && npx jest test/creator_invites.test.ts`
Expected: PASS — 6 tests. (`expiresAt` assertion: write `new Date(...)` in the implementation so `toBeInstanceOf(Date)` holds; if you prefer a Timestamp, adjust the assertion to `expect(written.expiresAt.toMillis()).toBeGreaterThan(Date.now())`.)

- [ ] **Step 5: Commit**

```bash
git add functions/src/creator_invites.ts functions/test/creator_invites.test.ts
git commit -m "feat(functions): generateCreatorInviteCode (verified-creator-only, 10-code rate limit)"
```

---

## Task 2: `redeemCreatorInvite` + tests

**Files:**
- Modify: `functions/src/creator_invites.ts`
- Modify: `functions/test/creator_invites.test.ts`

- [ ] **Step 1: Add failing tests**

Append to `functions/test/creator_invites.test.ts`:

```ts
// eslint-disable-next-line @typescript-eslint/no-require-imports
const { redeemCreatorInvite } = require("../src/creator_invites");

describe("redeemCreatorInvite", () => {
  it("rejects unauthenticated calls", async () => {
    await expect(
      redeemCreatorInvite.run({ auth: undefined, data: { code: "ABCDEFGH" } })
    ).rejects.toHaveProperty("code", "unauthenticated");
  });

  it("rejects a malformed code", async () => {
    await expect(
      redeemCreatorInvite.run({ auth: { uid: "u2" }, data: { code: "abc!" } })
    ).rejects.toHaveProperty("code", "invalid-argument");
  });

  it("rejects when the caller is already a creator", async () => {
    docGet.mockResolvedValue({ exists: true, data: () => ({ isVerifiedCreator: true }) });
    await expect(
      redeemCreatorInvite.run({ auth: { uid: "u2" }, data: { code: "ABCDEFGH" } })
    ).rejects.toHaveProperty("code", "already-exists");
  });

  it("rejects an unknown code", async () => {
    docGet.mockResolvedValue({ exists: false, data: () => null });
    runTransaction.mockImplementation(async (fn) => {
      const tx = {
        get: jest.fn().mockResolvedValue({ exists: false, data: () => null }),
        set: jest.fn(),
        delete: jest.fn(),
      };
      await fn(tx);
    });
    await expect(
      redeemCreatorInvite.run({ auth: { uid: "u2" }, data: { code: "ABCDEFGH" } })
    ).rejects.toHaveProperty("code", "not-found");
  });

  it("rejects an already-redeemed code", async () => {
    docGet.mockResolvedValue({ exists: false, data: () => null });
    runTransaction.mockImplementation(async (fn) => {
      const tx = {
        get: jest.fn().mockResolvedValue({
          exists: true,
          data: () => ({ creatorUid: "u1", redeemedBy: "other", expiresAt: new Date(Date.now() + 100000) }),
        }),
        set: jest.fn(),
        delete: jest.fn(),
      };
      await fn(tx);
    });
    await expect(
      redeemCreatorInvite.run({ auth: { uid: "u2" }, data: { code: "ABCDEFGH" } })
    ).rejects.toHaveProperty("code", "failed-precondition");
  });

  it("rejects an expired code", async () => {
    docGet.mockResolvedValue({ exists: false, data: () => null });
    runTransaction.mockImplementation(async (fn) => {
      const tx = {
        get: jest.fn().mockResolvedValue({
          exists: true,
          data: () => ({ creatorUid: "u1", redeemedBy: null, expiresAt: new Date(Date.now() - 1000) }),
        }),
        set: jest.fn(),
        delete: jest.fn(),
      };
      await fn(tx);
    });
    await expect(
      redeemCreatorInvite.run({ auth: { uid: "u2" }, data: { code: "ABCDEFGH" } })
    ).rejects.toHaveProperty("code", "failed-precondition");
  });

  it("redeems: creates profile, deletes code, sets the role claim", async () => {
    docGet.mockResolvedValue({ exists: false, data: () => null });
    const txSet = jest.fn();
    const txDelete = jest.fn();
    runTransaction.mockImplementation(async (fn) => {
      const tx = {
        get: jest.fn().mockResolvedValue({
          exists: true,
          data: () => ({ creatorUid: "u1", redeemedBy: null, expiresAt: new Date(Date.now() + 100000) }),
        }),
        set: txSet,
        delete: txDelete,
      };
      await fn(tx);
    });
    const result = await redeemCreatorInvite.run({
      auth: { uid: "u2" },
      data: { code: "abcdeFGH", displayName: "New Creator" },
    });
    expect(result.ok).toBe(true);
    expect(txDelete).toHaveBeenCalled();
    const profileWrite = txSet.mock.calls.find(
      ([ref]) => ref === "profile" // impl passes a sentinel ref; assert by data instead
    );
    expect(profileWrite).toBeDefined();
    expect(setCustomUserClaims).toHaveBeenCalledWith(
      "u2",
      expect.objectContaining({ role: "creator" })
    );
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd functions && npm run build && npx jest test/creator_invites.test.ts`
Expected: FAIL — `redeemCreatorInvite` is not exported.

- [ ] **Step 3: Implement `redeemCreatorInvite`**

Append to `functions/src/creator_invites.ts`:

```ts
export const redeemCreatorInvite = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be logged in.");
  }
  const uid = request.auth.uid;
  const data = request.data ?? {};
  const code = typeof data.code === "string" ? data.code.trim().toUpperCase() : "";
  if (!CODE_PATTERN.test(code)) {
    throw new HttpsError("invalid-argument", "Invalid invite code format.");
  }
  const displayName =
    typeof data.displayName === "string" && data.displayName.trim() !== ""
      ? data.displayName.trim().slice(0, 50)
      : "Creator";

  // Already a creator? (best-effort; the transaction's single-use code is
  // the real guard against double consumption).
  const [existingProfile, userRecord] = await Promise.all([
    db.collection("creator_profiles").doc(uid).get(),
    admin.auth().getUser(uid),
  ]);
  if (
    existingProfile.exists ||
    (userRecord.customClaims ?? {}).role === "creator"
  ) {
    throw new HttpsError("already-exists", "This account is already a creator.");
  }

  const codeRef = db.collection("creator_invite_codes").doc(code);
  const profileRef = db.collection("creator_profiles").doc(uid);

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(codeRef);
    if (!snap.exists) {
      throw new HttpsError("not-found", "Invalid or expired invite code.");
    }
    const doc = snap.data()!;
    if (doc.redeemedBy != null) {
      throw new HttpsError(
        "failed-precondition",
        "This invite code has already been used."
      );
    }
    const expiresAt = doc.expiresAt as admin.firestore.Timestamp | Date | undefined;
    const expiryMs =
      expiresAt instanceof Date
        ? expiresAt.getTime()
        : expiresAt?.toMillis?.() ?? 0;
    if (expiryMs < Date.now()) {
      throw new HttpsError(
        "failed-precondition",
        "This invite code has expired."
      );
    }

    // Mark + delete in the same transaction (doc-as-lock: a replayed or
    // failed delete still leaves the redeemedBy marker blocking reuse).
    tx.set(
      codeRef,
      { redeemedBy: uid, redeemedAt: admin.firestore.FieldValue.serverTimestamp() },
      { merge: true }
    );
    tx.delete(codeRef);

    tx.set(profileRef, {
      userId: uid,
      ownerId: uid,
      role: "creator",
      displayName,
      isVerifiedCreator: true,
      bio: "",
      specialityTags: [],
      blueprintCount: 0,
      creatorOnboardingProgress: 0,
      archetype: "none",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

  await admin.auth().setCustomUserClaims(uid, {
    ...(userRecord.customClaims ?? {}),
    role: "creator",
  });

  return { ok: true, uid };
});
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd functions && npm run build && npx jest test/creator_invites.test.ts`
Expected: PASS — all tests. (In the happy-path test, assert on the profile payload instead of a ref sentinel: find the `txSet` call whose data contains `userId: "u2"` and `isVerifiedCreator: true`.)

- [ ] **Step 5: Commit**

```bash
git add functions/src/creator_invites.ts functions/test/creator_invites.test.ts
git commit -m "feat(functions): redeemCreatorInvite (atomic single-use code, server-owned creator profile, role claim)"
```

---

## Task 3: `ensureCreatorTribe` + tests

**Files:**
- Modify: `functions/src/creator_invites.ts`
- Modify: `functions/test/creator_invites.test.ts`

- [ ] **Step 1: Add failing tests**

```ts
// eslint-disable-next-line @typescript-eslint/no-require-imports
const { ensureCreatorTribe } = require("../src/creator_invites");

describe("ensureCreatorTribe", () => {
  it("rejects unauthenticated calls", async () => {
    await expect(
      ensureCreatorTribe.run({ auth: undefined, data: {} })
    ).rejects.toHaveProperty("code", "unauthenticated");
  });

  it("rejects unverified creators", async () => {
    docGet.mockResolvedValue({ exists: false, data: () => null });
    await expect(
      ensureCreatorTribe.run({ auth: { uid: "u1" }, data: {} })
    ).rejects.toHaveProperty("code", "permission-denied");
  });

  it("creates a tribe on first publish and links the blueprint", async () => {
    // u1 verified (isVerifiedCreator true), no existing tribe, profile has displayName.
    docGet.mockResolvedValue({ exists: true, data: () => ({ isVerifiedCreator: true, displayName: "Aria" }) });
    queryGet.mockResolvedValue({ empty: true, docs: [], size: 0, forEach: jest.fn() });
    docSet.mockResolvedValue(undefined);
    const blueprintDocGet = jest.fn().mockResolvedValue({
      exists: true,
      data: () => ({ creatorUserId: "u1" }),
    });
    // The implementation reads blueprints/{id} — wire it through docGet by
    // switching on the path or by mocking collection().doc(id).get().

    const result = await ensureCreatorTribe.run({
      auth: { uid: "u1" },
      data: { blueprintId: "bp1" },
    });
    expect(result.tribeId).toBeTruthy();
    expect(result.created).toBe(true);
    // tribe doc contains type 'creator', members ['u1'], createdBy 'u1'
    const tribeWrite = docSet.mock.calls.find(([, ref]) => ref === "tribe"); // adjust to payload shape
    expect(tribeWrite).toBeDefined();
    // blueprint got creatorTribeId
    // creator_profiles got tribeId (merge)
  });

  it("reuses an existing tribe on second publish", async () => {
    docGet.mockResolvedValue({ exists: true, data: () => ({ isVerifiedCreator: true, displayName: "Aria" }) });
    queryGet.mockResolvedValue({
      empty: false,
      docs: [{ id: "tribe-1", data: () => ({}) }],
      size: 1,
      forEach: jest.fn((cb) => cb({ id: "tribe-1", data: () => ({}) })),
    });
    const result = await ensureCreatorTribe.run({ auth: { uid: "u1" }, data: {} });
    expect(result.tribeId).toBe("tribe-1");
    expect(result.created).toBe(false);
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd functions && npm run build && npx jest test/creator_invites.test.ts`
Expected: FAIL — `ensureCreatorTribe` is not exported.

- [ ] **Step 3: Implement `ensureCreatorTribe`**

Append to `functions/src/creator_invites.ts`:

```ts
export const ensureCreatorTribe = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be logged in.");
  }
  const uid = request.auth.uid;
  if (!(await isVerifiedCreator(uid))) {
    throw new HttpsError(
      "permission-denied",
      "Only verified creators can create tribes."
    );
  }
  const data = request.data ?? {};
  const blueprintId =
    typeof data.blueprintId === "string" && data.blueprintId.trim() !== ""
      ? data.blueprintId.trim()
      : null;

  const existing = await db
    .collection("tribes")
    .where("createdBy", "==", uid)
    .where("type", "==", "creator")
    .limit(1)
    .get();

  let tribeId: string;
  let created = false;
  if (existing.empty) {
    const profile = await db.collection("creator_profiles").doc(uid).get();
    const displayName = (profile.data()?.displayName as string) ?? "Creator";
    const archetype = (profile.data()?.archetype as string) ?? "none";
    const tribeRef = db.collection("tribes").doc();
    const tribeDoc: Record<string, unknown> = {
      name: `${displayName}'s Tribe`,
      type: "creator",
      createdBy: uid,
      members: [uid],
      memberCount: 1,
      description: "",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    if (archetype && archetype !== "none") {
      tribeDoc.archetypeId = archetype;
    }
    await tribeRef.set(tribeDoc);
    tribeId = tribeRef.id;
    created = true;
    await db
      .collection("creator_profiles")
      .doc(uid)
      .set({ tribeId, ownerId: uid }, { merge: true });
  } else {
    tribeId = existing.docs[0].id;
  }

  if (blueprintId) {
    const bp = await db.collection("blueprints").doc(blueprintId).get();
    if (bp.exists && bp.data()?.creatorUserId === uid) {
      await db
        .collection("blueprints")
        .doc(blueprintId)
        .set({ creatorTribeId: tribeId }, { merge: true });
    }
  }

  return { tribeId, created };
});
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd functions && npm run build && npx jest test/creator_invites.test.ts`
Expected: PASS. (Mock `collection().doc()` reads by path; simplest: make `docGet` switch on the doc id — `"bp1"` returns the blueprint, everything else returns the profile. The tribe doc id is unknown until creation, so capture the `set` payload and assert on it.)

- [ ] **Step 5: Commit**

```bash
git add functions/src/creator_invites.ts functions/test/creator_invites.test.ts
git commit -m "feat(functions): ensureCreatorTribe (auto-create or reuse creator tribe, link blueprint)"
```

---

## Task 4: Default creator account seed script (D2 — **CONFIRM-WITH-USER**)

> **CONFIRM-WITH-USER — D2.** Two recorded options: (a) seed a known default account via `seedCreatorAccount.ts` (ADMIN_SECRET + `CREATOR_EMAIL`/`CREATOR_PASSWORD` secrets), credentials delivered out-of-band — **recommended**; (b) promote the first creator manually (admin `setUserRole` + console-created verified profile). Proceed with (a) unless the user picks (b); if (b), this task reduces to a documented runbook and Task 4's script work is dropped.

**Files:**
- Create: `functions/src/seedCreatorAccount.ts`
- Create: `functions/test/seedCreatorAccount.test.ts`

- [ ] **Step 1: Write the failing test**

```ts
/**
 * Tests for seedCreatorAccount.ts guard logic (offline).
 * The handler is an onRequest — test the exported inner function directly.
 */
// eslint-disable-next-line @typescript-eslint/no-require-imports
const { seedCreatorAccountHandler } = require("../src/seedCreatorAccount");

const OLD_SECRET = process.env.ADMIN_SECRET;
const OLD_EMAIL = process.env.CREATOR_EMAIL;
const OLD_PASSWORD = process.env.CREATOR_PASSWORD;

afterAll(() => {
  if (OLD_SECRET !== undefined) process.env.ADMIN_SECRET = OLD_SECRET;
  if (OLD_EMAIL !== undefined) process.env.CREATOR_EMAIL = OLD_EMAIL;
  if (OLD_PASSWORD !== undefined) process.env.CREATOR_PASSWORD = OLD_PASSWORD;
});

describe("seedCreatorAccountHandler", () => {
  it("rejects a missing bearer token", async () => {
    process.env.ADMIN_SECRET = "s3cret";
    const res = { status: jest.fn().mockReturnThis(), json: jest.fn() };
    await seedCreatorAccountHandler({ headers: {} }, res);
    expect(res.status).toHaveBeenCalledWith(403);
  });

  it("rejects a wrong admin secret", async () => {
    process.env.ADMIN_SECRET = "s3cret";
    const res = { status: jest.fn().mockReturnThis(), json: jest.fn() };
    await seedCreatorAccountHandler(
      { headers: { authorization: "Bearer wrong" } },
      res
    );
    expect(res.status).toHaveBeenCalledWith(403);
  });

  it("creates the user, profile, claim, and one invite code", async () => {
    process.env.ADMIN_SECRET = "s3cret";
    process.env.CREATOR_EMAIL = "founder@emerge.app";
    process.env.CREATOR_PASSWORD = "hunter2outofband";
    // mock admin.auth().getUserByEmail → throws user-not-found; createUser returns uid;
    // setCustomUserClaims resolves; firestore set resolves.
    const res = { status: jest.fn().mockReturnThis(), json: jest.fn() };
    await seedCreatorAccountHandler(
      { headers: { authorization: "Bearer s3cret" } },
      res
    );
    expect(res.json).toHaveBeenCalledWith(
      expect.objectContaining({ ok: true })
    );
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd functions && npm run build && npx jest test/seedCreatorAccount.test.ts`
Expected: FAIL — module not found.

- [ ] **Step 3: Implement `functions/src/seedCreatorAccount.ts`**

Modeled on `functions/src/seedReviewerAccount.ts` (secrets pattern) + `seed_starter_habits.ts:405-418` (ADMIN_SECRET guard):

```ts
import { onRequest } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

if (admin.apps.length === 0) {
  admin.initializeApp();
}

function getRequiredEnvVar(name: string): string {
  const value = process.env[name];
  if (!value) throw new Error(`Required environment variable ${name} is not set.`);
  return value;
}

export async function seedCreatorAccountHandler(
  req: { headers: Record<string, string | undefined> },
  res: { status(code: number): { json(body: unknown): void } }
): Promise<void> {
  const adminSecret = req.headers.authorization?.replace("Bearer ", "");
  if (adminSecret !== process.env.ADMIN_SECRET) {
    res.status(403).json({ error: "Unauthorized" });
    return;
  }
  try {
    const email = getRequiredEnvVar("CREATOR_EMAIL");
    const password = getRequiredEnvVar("CREATOR_PASSWORD");
    const displayName = process.env.CREATOR_DISPLAY_NAME || "Emerge Founder";

    const auth = admin.auth();
    const db = admin.firestore();

    let uid: string;
    try {
      const existing = await auth.getUserByEmail(email);
      uid = existing.uid;
      await auth.updateUser(uid, { password, displayName, emailVerified: true });
    } catch (err: unknown) {
      if ((err as { code?: string }).code === "auth/user-not-found") {
        const newUser = await auth.createUser({
          email, password, displayName, emailVerified: true,
        });
        uid = newUser.uid;
      } else {
        throw err;
      }
    }

    await auth.setCustomUserClaims(uid, { role: "creator" });

    await db.collection("creator_profiles").doc(uid).set({
      userId: uid,
      ownerId: uid,
      role: "creator",
      displayName,
      isVerifiedCreator: true,
      bio: "",
      specialityTags: [],
      blueprintCount: 0,
      creatorOnboardingProgress: 3,          // onboarding complete → dashboard reachable
      creatorOnboardingCompletedAt: admin.firestore.Timestamp.now(),
      archetype: "creator",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // One ready invite code so the default creator can immediately onboard others.
    const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
    let code = "";
    for (let i = 0; i < 8; i++) code += chars[Math.floor(Math.random() * chars.length)];
    await db.collection("creator_invite_codes").doc(code).set({
      creatorUid: uid,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
      redeemedBy: null,
    });

    res.status(200).json({ ok: true, uid, inviteCode: code });
  } catch (error) {
    console.error("seedCreatorAccount failed:", error);
    res.status(500).json({ error: "Seeding failed" });
  }
}

/** HTTP trigger. Export is commented out in index.ts by default (seedReviewerAccount precedent). */
export const seedCreatorAccount = onRequest(
  { secrets: ["CREATOR_EMAIL", "CREATOR_PASSWORD"] },
  seedCreatorAccountHandler
);
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd functions && npm run build && npx jest test/seedCreatorAccount.test.ts`
Expected: PASS — 3 tests. (Mock `firebase-admin` like Task 1: `getUserByEmail` throws `{code:"auth/user-not-found"}`, `createUser` returns `{uid:"seed-uid"}`.)

- [ ] **Step 5: Commit**

```bash
git add functions/src/seedCreatorAccount.ts functions/test/seedCreatorAccount.test.ts
git commit -m "feat(functions): seedCreatorAccount — ADMIN_SECRET-guarded default creator + first invite code"
```

---

## Task 5: Export callables from `index.ts` + full functions suite

**Files:**
- Modify: `functions/src/index.ts`

- [ ] **Step 1: Add the export**

In `functions/src/index.ts`, in the SUB-MODULE EXPORTS section (after line 265 `export { setUserRole } ...`):

```ts
export * from "./creator_invites";
// export * from "./seedCreatorAccount";   // enable explicitly when bootstrapping the default creator (SP-E Task 4)
```

- [ ] **Step 2: Build + run the whole functions suite**

Run: `cd functions && npm run build && npm test`
Expected: ALL PASS — existing tests (`index.test.ts`, `create_starter_pack.test.ts`, `paystack.test.ts`, `seed_starter_habits.test.ts`) plus the new `creator_invites.test.ts` and `seedCreatorAccount.test.ts`.

- [ ] **Step 3: Commit**

```bash
git add functions/src/index.ts
git commit -m "feat(functions): export creator invite callables from index"
```

---

# Phase 2 — Firestore rules (emulator-verified)

## Task 6: Rules — `isVerifiedCreator` helper, `creator_invite_codes`, `creator_profiles`

**Files:**
- Modify: `firestore.rules` (already dirty in the worktree — preserve unrelated hunks; inspect `git diff firestore.rules` first)

- [ ] **Step 1: Add the `isVerifiedCreator` helper**

Insert after `isAdmin()` (`firestore.rules:17-19`):

```
    // Verified creator: role claim 'creator' AND a verified creator_profiles
    // doc. get() on a missing doc errors → the rule denies (fail-closed).
    function isVerifiedCreator() {
      return isAuthenticated() &&
             request.auth.token.role == 'creator' &&
             get(/databases/$(database)/documents/creator_profiles/$(request.auth.uid)).data.isVerifiedCreator == true;
    }
```

- [ ] **Step 2: Add the `creator_invite_codes` deny block**

Insert before the `blueprints` block (`firestore.rules:501`):

```
    // Creator invite codes — functions only (admin SDK bypasses rules).
    // Clients must never read, create, or consume codes directly.
    match /creator_invite_codes/{code} {
      allow read, write: if false;
    }
```

- [ ] **Step 3: Replace the `creator_profiles` block (`firestore.rules:512-517`)**

```
    // Creator Profiles.
    // The redeemCreatorInvite function creates docs (isVerifiedCreator: true).
    // Owners may update non-privileged fields (onboarding) but can never flip
    // ownerId / userId / role / isVerifiedCreator — those are server-only.
    // The profileId.startsWith('creator_') carve-out preserves the on-device
    // system-creator seeder (seedCreatorsIfEmpty, creator_aria_chen, ...).
    match /creator_profiles/{profileId} {
      allow read: if true;
      allow create: if isAdmin() ||
        (profileId.startsWith('creator_') && isAuthenticated());
      allow update: if isAdmin() ||
        (isAuthenticated() && resource.data.ownerId == request.auth.uid &&
         isValidCreatorProfile(request.resource.data) &&
         !request.resource.data.diff(resource.data).affectedKeys()
           .hasAny(['ownerId', 'userId', 'role', 'isVerifiedCreator'])) ||
        (profileId.startsWith('creator_') && isAuthenticated());
      allow delete: if isAdmin();
    }
```

- [ ] **Step 4: Verify with the emulator (manual rules smoke)**

Run:
```bash
firebase emulators:start --only firestore,auth,functions
# 1. deploy rules: firebase deploy --only firestore:rules --project tradeflash-l2966 (prod) OR
#    use the emulator console (http://localhost:4000) with firestore.rules
# 2. With the emulators running, run the default-account seed (Task 4) via curl:
curl -X POST http://localhost:5001/<project>/us-central1/seedCreatorAccount \
  -H "Authorization: Bearer $ADMIN_SECRET"
# 3. Confirm a creator_profiles doc + creator_invite_codes doc exist in the emulator UI.
# 4. Attempt a client-side create of creator_profiles/{someUid} with isVerifiedCreator: true
#    from an unauthenticated session → must be DENIED (emulator UI "Add document" test or a
#    scratch Dart test using fake emulator config).
```

Expected: seed writes succeed (admin SDK), direct client writes to `creator_invite_codes` are denied, owner update of `bio`/`archetype` on an owned profile succeeds, owner update attempting `isVerifiedCreator: true` is denied.

- [ ] **Step 5: Commit**

```bash
git add firestore.rules
git commit -m "feat(rules): verified-creator helper + deny client access to creator_invite_codes + server-owned creator_profiles"
```

---

## Task 7: Rules — `blueprints`, `challenges`, `tribes` creator rights

**Files:**
- Modify: `firestore.rules`

- [ ] **Step 1: Extend `isValidTribe` (`firestore.rules:68-86`)**

Change the `archetypeId` and `type` lines:

```
    function isValidTribe(tribe) {
      return tribe.keys().hasAll(['name', 'type']) &&
             tribe.keys().size() <= 40 &&
             sanitizeString(tribe.name) &&
             tribe.name.size() <= 100 &&
             // archetypeId optional ONLY for creator tribes (null archetype)
             (!tribe.keys().hasAny(['archetypeId']) ||
                tribe.archetypeId in ['athlete', 'scholar', 'stoic', 'creator', 'zealot', 'mystic']) &&
             tribe.type in ['official', 'brand', 'userPrivate', 'userPublic', 'creator'] &&
             ...
```

- [ ] **Step 2: Update the `tribes` create rule (`firestore.rules:361-372`)**

```
    match /tribes/{tribeId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated() && isValidTribe(request.resource.data) &&
        (request.resource.data.type != 'creator' || isVerifiedCreator());
      allow update: if isAuthenticated() && isValidTribe(request.resource.data) && (
        resource.data.createdBy == request.auth.uid ||
        isAdmin() ||
        request.resource.data.diff(resource.data).affectedKeys()
          .hasOnly(['memberCount', 'members', 'lastStatsSync'])
      );
      allow delete: if isAdmin();
```

- [ ] **Step 3: Update the `challenges` block (`firestore.rules:408-410`)**

```
    // Challenges — catalog entries. Verified creators may add their own
    // (createdBy == auth.uid); admins manage the curated catalog.
    match /challenges/{challengeId} {
      allow read: if true;
      allow create: if isAdmin() ||
        (isVerifiedCreator() && request.resource.data.createdBy == request.auth.uid);
      allow update: if isAdmin() ||
        (isVerifiedCreator() && resource.data.createdBy == request.auth.uid);
      allow delete: if isAdmin() ||
        (isVerifiedCreator() && resource.data.createdBy == request.auth.uid);
```

- [ ] **Step 4: Update the `blueprints` block (`firestore.rules:501-504`)**

```
    // Blueprints — verified creators publish their own (creatorUserId).
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

- [ ] **Step 5: Emulator smoke**

Repeat Task 6 Step 4's emulator session: with a redeemed (verified) creator account signed in on the client, (a) `blueprints/{autoId}` create with `creatorUserId: uid` → ALLOWED; with `creatorUserId: otherUid` → DENIED; (b) `challenges/{autoId}` create with `createdBy: uid` → ALLOWED; (c) `tribes/{autoId}` create `{name, type:'creator', createdBy: uid, members:[uid]}` (no archetypeId) → ALLOWED for verified creators, DENIED for normal users; (d) same tribe with `type:'official'` and no archetypeId → DENIED.

- [ ] **Step 6: Commit**

```bash
git add firestore.rules
git commit -m "feat(rules): verified creators may create/update own blueprints, challenges, creator tribes"
```

---

# Phase 3 — Client (Flutter, TDD)

## Task 8: Model + repository foundations — `ownerId`, `createdBy`, `createCatalogChallenge`

**Files:**
- Modify: `lib/features/social/domain/entities/creator_profile.dart`
- Modify: `lib/features/social/domain/models/challenge.dart`
- Modify: `lib/features/social/domain/repositories/challenge_repository.dart`
- Modify: (impl file) `lib/features/social/data/repositories/firebase_challenge_repository.dart` — verify the actual impl class name first (`grep -rn "implements ChallengeRepository" lib/features/social/data`)
- Modify: `test/features/social/data/repositories/creator_repository_test.dart`
- Create: `test/features/social/domain/models/challenge_test.dart` (if none exists)

- [ ] **Step 1: Write the failing tests**

```dart
// test/features/social/data/repositories/creator_repository_test.dart — append
test('toMap writes ownerId matching userId', () {
  const profile = CreatorProfile(userId: 'abc', role: 'creator', displayName: 'A');
  final map = profile.toMap();
  expect(map['ownerId'], 'abc');
});
```

```dart
// test/features/social/domain/models/challenge_test.dart (new)
test('challenge round-trips createdBy and createdAt', () {
  final c = Challenge(
    id: 'c1', title: 't', description: 'd', imageUrl: 'u', reward: 'r',
    participants: 0, daysLeft: 0, totalDays: 7, currentDay: 0, status: ChallengeStatus.active,
    xpReward: 100, steps: const [], createdBy: 'uid-1', createdAt: DateTime(2026, 8, 1),
  );
  final round = Challenge.fromMap(c.toMap(), id: 'c1');
  expect(round.createdBy, 'uid-1');
  expect(round.createdAt, DateTime(2026, 8, 1));
  expect(c.copyWith(title: 't2').createdBy, 'uid-1');
});
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/features/social/data/repositories/creator_repository_test.dart test/features/social/domain/models/challenge_test.dart`
Expected: FAIL — `ownerId` missing from `toMap`; `createdBy`/`createdAt` not on `Challenge`.

- [ ] **Step 3: Implement**

`creator_profile.dart` `toMap()` (line ~93): add `'ownerId': userId,` as the first entry.

`challenge.dart`: add `final String? createdBy;` and `final DateTime? createdAt;` (constructor defaults null after `rewardNameplateId`; `copyWith`; `toMap` writes both — `createdAt` as `toIso8601String()`; `fromMap` parses both; add both to `props`).

`challenge_repository.dart` + impl: add

```dart
  /// Publishes a catalog challenge owned by [createdBy] (verified creators).
  Future<String> createCatalogChallenge(Challenge challenge);
```

Firestore impl: `final ref = _firestore.collection('challenges').doc(); await ref.set(challenge.copyWith(id: ref.id).toMap()); return ref.id;` (mirror `BlueprintRepository.createBlueprint`). Do **not** touch `createSoloChallenge` (writes `users/{uid}/challenges` progress).

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/features/social/data/repositories/creator_repository_test.dart test/features/social/domain/models/challenge_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/social/domain/entities/creator_profile.dart lib/features/social/domain/models/challenge.dart lib/features/social/domain/repositories/challenge_repository.dart lib/features/social/data/repositories/firebase_challenge_repository.dart test/features/social
git commit -m "feat(social): CreatorProfile.ownerId + Challenge.createdBy/createdAt + createCatalogChallenge"
```

---

## Task 9: Invite-gated creator signup (provider + screen)

**Files:**
- Modify: `lib/features/auth/presentation/providers/auth_providers.dart`
- Modify: `lib/features/auth/presentation/screens/creator_signup_screen.dart`
- Modify: `test/features/auth/presentation/screens/creator_signup_screen_test.dart`

- [ ] **Step 1: Write the failing widget test**

```dart
// Append to test/features/auth/presentation/screens/creator_signup_screen_test.dart
testWidgets('invite code field validates format', (tester) async {
  // existing harness (fake auth via firebase_auth_mocks + fake_cloud_firestore)
  await tester.pumpWidget(harness());
  await tester.enterText(find.widgetWithText(TextFormField, 'Invite Code'), 'bad');
  await tester.tap(find.text('Register as Creator'));
  await tester.pumpAndSettle();
  expect(find.textContaining('8 characters'), findsOneWidget); // or the chosen message
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/auth/presentation/screens/creator_signup_screen_test.dart`
Expected: FAIL — no invite-code field exists.

- [ ] **Step 3: Implement the provider rewrite**

In `auth_providers.dart`, replace `signUpCreator` (lines 98-134):

```dart
@Riverpod(keepAlive: true)
Future<void> signUpCreator(Ref ref, String email, String password,
    String username, String inviteCode) async {
  final auth = ref.read(firebaseAuthProvider);
  final credential = await auth.createUserWithEmailAndPassword(
    email: email.trim(),
    password: password,
  );

  final user = credential.user;
  if (user == null) throw Exception('User creation failed');

  await user.updateDisplayName(username.trim());

  // Server-side redemption: creates creator_profiles (isVerifiedCreator: true)
  // and sets the role custom claim. The old client-side profile write and the
  // admin-gated setUserRole call are removed (SP-E).
  final functions = FirebaseFunctions.instance;
  await functions.httpsCallable('redeemCreatorInvite').call(<String, dynamic>{
    'code': inviteCode.trim().toUpperCase(),
    'displayName': username.trim(),
  });
  await user.getIdToken(true);
}
```

`signUpCreatorWithGoogle` (lines 136-197): add `String inviteCode` parameter; web path stores `prefs.setString('pending_creator_invite_code', inviteCode)` next to the existing `pending_creator_signup` flag (~line 146) and redeems after redirect; native path calls the redeem callable after `signInWithCredential` and before returning. Remove the client `creatorRepo.updateCreatorProfile` write and both `setUserRole` try/catch blocks. **Check the splash/redirect flow** that consumes `pending_creator_signup` (`grep -rn pending_creator_signup lib`) and extend it to pass the stored code into the post-redirect redemption.

- [ ] **Step 4: Implement the screen field**

In `creator_signup_screen.dart`, add between Confirm Password and the submit button:

```dart
              // Invite Code
              TextFormField(
                controller: _inviteCodeController,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Invite Code',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: EmergeColors.background.withValues(alpha: 0.5),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: EmergeColors.hexLine),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.amber),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.confirmation_number_outlined, color: Colors.amber),
                ),
                validator: (value) {
                  final v = value?.trim().toUpperCase() ?? '';
                  if (v.isEmpty) return 'An invite code is required to become a creator';
                  if (v.length != 8 || !RegExp(r'^[A-Z2-9]{8}$').hasMatch(v)) {
                    return 'Invite codes are 8 characters (A-Z, 2-9)';
                  }
                  return null;
                },
              ).animate(delay: 275.ms).fadeIn().slideX(begin: 0.02),
              const Gap(16),
```

Wire `_signUp` (line 49): `signUpCreatorProvider(_emailController.text.trim(), _passwordController.text, _usernameController.text.trim(), _inviteCodeController.text.trim())`. Add the `_inviteCodeController` to the state class + dispose.

- [ ] **Step 5: Run codegen + tests**

Run: `dart run build_runner build --delete-conflicting-outputs` (if provider signatures changed codegen) then `flutter test test/features/auth/presentation/screens/creator_signup_screen_test.dart test/features/auth/...`
Expected: PASS. (The redeem callable is a real `FirebaseFunctions.instance` call — in widget tests without an emulator it throws; existing tests tolerate this because errors surface as snackbars. Add a `FirebaseFunctions`-platform override if the existing harness doesn't stub it; see `test/features/auth` conventions.)

- [ ] **Step 6: Commit**

```bash
git add lib/features/auth/presentation/providers/auth_providers.dart lib/features/auth/presentation/screens/creator_signup_screen.dart lib/features/auth/presentation/providers/auth_providers.g.dart test/features/auth/presentation/screens/creator_signup_screen_test.dart
git commit -m "feat(auth): invite-gated creator signup (redeemCreatorInvite; drop client profile write + setUserRole)"
```

---

## Task 10: Dashboard loading guard + onboarding provider cleanup

**Files:**
- Modify: `lib/features/social/presentation/screens/creator/creator_dashboard_scaffold.dart`
- Modify: `lib/features/onboarding/presentation/providers/creator_onboarding_provider.dart`
- Modify: `test/features/social/presentation/screens/creator/creator_dashboard_scaffold_test.dart`

- [ ] **Step 1: Write the failing widget test**

```dart
// Append to creator_dashboard_scaffold_test.dart — the harness must drive
// isVerifiedCreatorProvider through loading → data states.
testWidgets('does not redirect while verification is loading', (tester) async {
  // Provider override whose future never completes initially; pump; expect
  // no navigation to /creator/login.
  // Complete the future with false; pump; expect navigation.
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/social/presentation/screens/creator/creator_dashboard_scaffold_test.dart`
Expected: FAIL — current listener redirects even while loading (or the loading state can't be expressed because the provider resolves immediately; if the harness can't produce a loading state with the existing provider, override `isVerifiedCreatorProvider` with a manually-completed `Completer`-backed future).

- [ ] **Step 3: Implement**

`creator_dashboard_scaffold.dart:17-23`:

```dart
    ref.listen(isVerifiedCreatorProvider, (_, next) {
      // Hold while loading: a fresh redeem is followed by the profile doc
      // resolving; bouncing during that window logs the creator out (SP-E D6).
      if (next.isLoading || !next.hasValue) return;
      if (!next.value! && context.mounted) {
        context.go('/creator/login');
      }
    });
```

`creator_onboarding_provider.dart` `saveCreatorOnboardingProgress` (lines 103-123): remove `role: 'creator'` from the `copyWith` call (both the `existing ??` seed and the merge — lines 110 and 113) so the rules `diff` whitelist is never tripped by a same-value rewrite; remove the `setUserRole` mirror try/catch block (lines 125-142) — the profile is the source of truth; keep the `ref.invalidate(currentCreatorOnboardingProvider)` in a `finally`. Note: `currentCreatorOnboardingProvider` (`role_provider.dart:113-131`) reads the profile directly — no behavior change.

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/features/social/presentation/screens/creator/creator_dashboard_scaffold_test.dart test/features/onboarding/...creator_onboarding*_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/social/presentation/screens/creator/creator_dashboard_scaffold.dart lib/features/onboarding/presentation/providers/creator_onboarding_provider.dart test/features/social/presentation/screens/creator/creator_dashboard_scaffold_test.dart
git commit -m "fix(creator): no dashboard bounce while verification loads; onboarding writes stay rule-whitelist safe"
```

---

## Task 11: Blueprint publish → tribe + Create Challenge dialog

**Files:**
- Modify: `lib/features/social/presentation/screens/creator/blueprint_builder_screen.dart`
- Modify: `lib/features/social/presentation/screens/creator/creator_tribe_management_tab.dart`
- Create: `test/features/social/presentation/screens/creator/creator_create_challenge_dialog_test.dart`
- Modify: (if exists) `test/features/social/presentation/screens/creator/blueprint_builder_screen_test.dart`

- [ ] **Step 1: Write the failing widget test**

```dart
// creator_create_challenge_dialog_test.dart (new)
testWidgets('create challenge dialog submits a catalog challenge', (tester) async {
  // pump CreatorTribeManagementTab with a fake ChallengeRepository override
  // (createCatalogChallenge records the call); tap 'Create Challenge';
  // fill title/description/days; tap submit.
  // expect(created.createdBy, currentUid); success snackbar visible.
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/social/presentation/screens/creator/creator_create_challenge_dialog_test.dart`
Expected: FAIL — no dialog exists; the "Create Challenge" card still shows the stub snackbar.

- [ ] **Step 3: Implement the create-challenge dialog**

In `creator_tribe_management_tab.dart`, replace the "Create Challenge" `_ActionCard` onTap stub (lines 166-177) with `onTap: () => _showCreateChallengeDialog(context)`. Add `_showCreateChallengeDialog`: a `showDialog` with title/description `TextField`s, a `ChallengeCategory` dropdown, and a day count (7/14/21/30); on submit build a `Challenge(...)` (auto id '', `createdBy: FirebaseAuth.instance.currentUser!.uid`, `createdAt: DateTime.now()`, `status: ChallengeStatus.active`, `steps: const []`, `participants: 0`, `daysLeft: days`, `totalDays: days`, `currentDay: 0`, `xpReward: 100`) and call `challengeRepository.createCatalogChallenge(...)`; success snackbar + `ref.invalidate` of the challenges provider.

- [ ] **Step 4: Implement the publish wiring**

In `blueprint_builder_screen.dart` `_submit` (after `final id = await repo.createBlueprint(blueprint);` at line 281):

```dart
      // SP-E D5/D7: auto-create (or reuse) the creator tribe and link it.
      try {
        final functions = FirebaseFunctions.instance;
        final result = await functions.httpsCallable('ensureCreatorTribe').call(
          <String, dynamic>{'blueprintId': id},
        );
        final tribeId = (result.data as Map<String, dynamic>?)?['tribeId'] as String?;
        if (tribeId != null) {
          // Keep the local list/tab in sync; failures are non-fatal.
        }
      } catch (e) {
        AppLogger.w('ensureCreatorTribe failed (publish still succeeded): $e');
      }
```

(Import `cloud_functions` and `AppLogger` if not already imported.)

- [ ] **Step 5: Run tests to verify they pass**

Run: `flutter test test/features/social/presentation/screens/creator/`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/features/social/presentation/screens/creator/blueprint_builder_screen.dart lib/features/social/presentation/screens/creator/creator_tribe_management_tab.dart test/features/social/presentation/screens/creator/
git commit -m "feat(creator): publish auto-creates creator tribe; Create Challenge dialog replaces stub"
```

---

## Task 12: Full verification + emulator end-to-end smoke + docs

**Files:** none (verification only; commit any test fixes produced)

- [ ] **Step 1: Full functions suite**

Run: `cd functions && npm run build && npm test`
Expected: ALL PASS.

- [ ] **Step 2: Full Flutter analyze + focused tests**

Run:
```bash
dart analyze lib test
flutter test test/features/auth/presentation/screens/creator_signup_screen_test.dart test/features/auth/presentation/screens/creator_login_screen_test.dart test/features/social/presentation/screens/creator/ test/features/social/data/repositories/creator_repository_test.dart
```
Expected: 0 SP-E-introduced analyzer issues; all listed suites pass. (Pre-existing failures outside these suites are not this plan's responsibility.)

- [ ] **Step 3: End-to-end emulator smoke**

Run:
```bash
firebase emulators:start --only firestore,auth,functions
# 1. curl the seedCreatorAccount endpoint (ADMIN_SECRET) → get {inviteCode}
# 2. In the app (emulator build): sign up on /creator/signup with a new email +
#    the invite code → lands on /creator/dashboard (no bounce)
# 3. Open Blueprints → forge a blueprint → EMIT TO WORLD → success snackbar
# 4. Open Tribe tab → tribe now shows "<name>'s Tribe" with 1 member
# 5. Tribe tab → Create Challenge → submit → challenge appears in the challenges feed
# 6. Sign out; log in as a normal user → creator login correctly rejects them
# 7. From a normal account, attempt a direct Firestore write to creator_invite_codes → denied
```

- [ ] **Step 4: Deployment runbook (documented in the spec; execute when shipping)**

```bash
cd functions
firebase functions:secrets:set ADMIN_SECRET
firebase functions:secrets:set CREATOR_EMAIL
firebase functions:secrets:set CREATOR_PASSWORD
# enable the seedCreatorAccount export in index.ts, then:
firebase deploy --only functions
# bootstrap the default creator + first code:
curl -X POST <fnUrl>/seedCreatorAccount -H "Authorization: Bearer $ADMIN_SECRET"
firebase deploy --only firestore:rules
```
Order matters: **functions → seed → rules → client release** (old clients writing `creator_profiles` are denied by the new rules; the redeem-based flow never writes client-side).

- [ ] **Step 5: Commit any test fixes produced by Steps 1–2**

```bash
git add <only the fixed test files>
git commit -m "test(creator): SP-E verification fixes"
```
(If nothing changed, skip this step.)

---

## Done definition

- [ ] All 12 tasks committed with the messages above (or approved deviations).
- [ ] `functions/test` fully green after `npm run build` (offline firebase-functions-test).
- [ ] Emulator smoke (Task 12 Step 3) passes end-to-end: seed → redeem → dashboard → publish → tribe → challenge.
- [ ] `firestore.rules` deployable and denies `creator_invite_codes` client access; verified creators can write own blueprints/challenges/creator tribes; unverified clients cannot.
- [ ] Spec updated with any implementation deviations; D2 confirmed with the user (option (a) recommended).
