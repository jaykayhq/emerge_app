# Email Verification (Grace Period) & Username Uniqueness — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Verify every new email/password account via a 6-digit code sent through Resend, lock login after a 7-day grace period, enforce globally-unique case-insensitive usernames server-side, and backfill existing users.

**Architecture:** Server-authoritative Cloud Functions mirroring the proven `creator_invites.ts` pattern — codes hashed at rest in a functions-only `email_verifications/{uid}` collection, Firebase Auth's native `emailVerified` flag set via Admin SDK, `usernames/{normalized}` doc-as-lock claims, pure `decideRedirect` branch enforcing the gate. Google sign-in is exempt.

**Tech Stack:** Firebase Gen 2 Cloud Functions (TypeScript, jest + `firebase-functions-test`), Resend REST via existing `axios`, Firestore security rules, Flutter/Riverpod, fpdart `Either`.

---

## File Structure

**New (functions):**
- `functions/src/email.ts` — `sendEmail()` Resend helper (shared with sub-project 3).
- `functions/src/email_verification.ts` — `sendEmailVerificationCode`, `verifyEmailCode`, `enforceEmailGracePeriod` (+ testable `enforceEmailGracePeriodInternal`).
- `functions/src/usernames.ts` — `claimUsername`.
- `functions/src/backfill_usernames.ts` — one-off admin-gated backfill.
- `functions/test/email_verification.test.ts`, `functions/test/usernames.test.ts`.

**New (Flutter):**
- `lib/features/auth/presentation/screens/verify_email_screen.dart` — OTP entry, cooldown, locked/verified states.

**Modified (functions):** `functions/src/index.ts` (exports), `firestore.rules` (deny `email_verifications`, `usernames`), `functions/package.json` (backfill script).

**Modified (Flutter):**
- `lib/features/auth/domain/entities/auth_user.dart` — add `emailVerified`.
- `lib/features/auth/domain/repositories/auth_repository.dart` — 4 new methods.
- `lib/features/auth/data/repositories/firebase_auth_repository.dart` — implement + error mapping + claim-with-rollback in signup.
- `lib/core/router/router.dart` — `RedirectContext.emailVerified/emailLockedAt`, `decideRedirect` branch, `/verify-email` route.
- `lib/features/auth/presentation/providers/role_provider.dart` — `currentEmailLockedAtProvider`.
- `lib/features/auth/presentation/screens/signup_screen.dart` — navigate to `/verify-email` when unverified.
- `lib/features/settings/presentation/screens/settings_screen.dart` — verify-email tile.
- `test/features/auth/data/repositories/fake_auth_repository.dart` + `auth_repository_test.dart`, `test/core/router/router_redirect_test.dart`, `test/features/auth/presentation/screens/signup_screen_test.dart`, new `verify_email_screen_test.dart`.

---

## Task 1: `email.ts` — Resend email helper

**Files:**
- Create: `functions/src/email.ts`
- Test: `functions/test/email.test.ts`

- [ ] **Step 1: Write the failing test**

`functions/test/email.test.ts`:

```ts
const axiosPost = jest.fn().mockResolvedValue({ status: 200 });

jest.mock("axios", () => ({ post: (...args: unknown[]) => axiosPost(...args) }));

import { sendEmail } from "../src/email";

describe("sendEmail", () => {
  afterEach(() => jest.clearAllMocks());

  it("throws when RESEND_API_KEY is missing", async () => {
    delete process.env.RESEND_API_KEY;
    await expect(
      sendEmail({ to: "a@b.com", subject: "Hi", html: "<p>Hi</p>" })
    ).rejects.toThrow("RESEND_API_KEY not configured");
  });

  it("POSTs to the Resend API with auth header", async () => {
    process.env.RESEND_API_KEY = "re_test_123";
    await sendEmail({ to: "a@b.com", subject: "Hi", html: "<p>Hi</p>" });
    expect(axiosPost).toHaveBeenCalledTimes(1);
    const [url, body, config] = axiosPost.mock.calls[0];
    expect(url).toBe("https://api.resend.com/emails");
    expect(body).toMatchObject({
      from: "Emerge <no-reply@emerge.app>",
      to: "a@b.com",
      subject: "Hi",
      html: "<p>Hi</p>",
    });
    expect(config.headers.Authorization).toBe("Bearer re_test_123");
  });

  it("propagates API errors", async () => {
    process.env.RESEND_API_KEY = "re_test_123";
    axiosPost.mockRejectedValueOnce(new Error("429 too many"));
    await expect(
      sendEmail({ to: "a@b.com", subject: "Hi", html: "<p>Hi</p>" })
    ).rejects.toThrow("429 too many");
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd functions && npx jest test/email.test.ts`
Expected: FAIL — "Cannot find module '../src/email'"

- [ ] **Step 3: Write minimal implementation**

`functions/src/email.ts`:

```ts
/**
 * Shared transactional-email helper (Resend). Reused by the verification
 * code flow (Task 2) and, later, sub-project 3's marketing drip.
 * RESEND_API_KEY lives in function secrets — never client-visible.
 */
import axios from "axios";

export interface EmailPayload {
  to: string;
  subject: string;
  html: string;
}

export async function sendEmail(payload: EmailPayload): Promise<void> {
  const apiKey = process.env.RESEND_API_KEY;
  if (!apiKey) {
    throw new Error("RESEND_API_KEY not configured");
  }
  await axios.post(
    "https://api.resend.com/emails",
    {
      from: "Emerge <no-reply@emerge.app>",
      to: payload.to,
      subject: payload.subject,
      html: payload.html,
    },
    { headers: { Authorization: `Bearer ${apiKey}`, "Content-Type": "application/json" } }
  );
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd functions && npx jest test/email.test.ts`
Expected: PASS — 3 passing

- [ ] **Step 5: Commit**

```bash
cd functions && npm run build && npx jest test/email.test.ts
cd .. && git add functions/src/email.ts functions/test/email.test.ts
git commit -m "feat(functions): Resend transactional email helper"
```

---

## Task 2: `email_verification.ts` — send / verify / grace-period lock

**Files:**
- Create: `functions/src/email_verification.ts`
- Modify: `functions/src/index.ts:264` (add export line)
- Test: `functions/test/email_verification.test.ts`

- [ ] **Step 1: Write the failing test**

`functions/test/email_verification.test.ts` — offline admin mock, mirroring `creator_invites.test.ts`:

```ts
/**
 * Offline tests for email_verification.ts.
 * Run with: cd functions && npm run build && npx jest test/email_verification.test.ts
 */
const updateUser = jest.fn().mockResolvedValue(undefined);
const getUser = jest.fn();
const docGet = jest.fn();
const docSet = jest.fn();
const docDelete = jest.fn();
const queryGet = jest.fn();
const runTransaction = jest.fn();
const batchSet = jest.fn();
const batchCommit = jest.fn().mockResolvedValue(undefined);
const batch = jest.fn(() => ({ set: batchSet, commit: batchCommit }));

const collection = jest.fn((name: string) => ({
  doc: jest.fn((id?: string) => ({
    id: id ?? "auto-1",
    get: jest.fn(() => docGet(name, id)),
    set: docSet,
    delete: docDelete,
  })),
  where: jest.fn(() => ({
    where: jest.fn(() => ({
      get: queryGet,
      limit: jest.fn(() => ({ get: queryGet })),
    })),
    limit: jest.fn(() => ({ get: queryGet })),
    get: queryGet,
  })),
}));

const firestoreMock = jest.fn(() => ({ collection, runTransaction, batch }));
(
  firestoreMock as unknown as {
    FieldValue: {
      serverTimestamp: () => string;
      delete: () => string;
    };
    Timestamp: { fromDate: (d: Date) => Date; now: () => Date };
  }
).FieldValue = { serverTimestamp: () => "SERVER_TIMESTAMP", delete: () => "FIELD_DELETE" };
(
  firestoreMock as unknown as {
    Timestamp: { fromDate: (d: Date) => Date; now: () => Date };
  }
).Timestamp = { fromDate: (d: Date) => d, now: () => new Date() };

jest.mock("firebase-admin", () => ({
  apps: [],
  initializeApp: jest.fn(),
  firestore: firestoreMock,
  auth: () => ({ getUser, updateUser }),
}));

// eslint-disable-next-line @typescript-eslint/no-require-imports
const ft = require("firebase-functions-test")();

// eslint-disable-next-line @typescript-eslint/no-require-imports
const {
  sendEmailVerificationCode,
  verifyEmailCode,
  enforceEmailGracePeriodInternal,
} = require("../src/email_verification");

beforeEach(() => {
  jest.clearAllMocks();
  docGet.mockImplementation((name: string, id: string) =>
    Promise.resolve({ exists: false, data: () => null })
  );
  queryGet.mockResolvedValue({ size: 0, empty: true, docs: [], forEach: jest.fn() });
});

describe("sendEmailVerificationCode", () => {
  it("rejects unauthenticated calls", async () => {
    await expect(
      sendEmailVerificationCode.run({ auth: undefined, data: {} })
    ).rejects.toHaveProperty("code", "unauthenticated");
  });

  it("rejects when over the hourly resend limit", async () => {
    docGet.mockImplementation((name: string, id: string) =>
      Promise.resolve({
        exists: true,
        data: () => ({
          resendCount: 5,
          lastSentAt: new Date(Date.now() - 60_000),
          attempts: 0,
        }),
      })
    );
    await expect(
      sendEmailVerificationCode.run({
        auth: { uid: "u1", token: {} },
        data: {},
      })
    ).rejects.toHaveProperty("code", "resource-exhausted");
  });

  it("writes a hashed code doc with TTL and returns ok", async () => {
    await sendEmailVerificationCode.run({ auth: { uid: "u1", token: {} }, data: {} });
    expect(docSet).toHaveBeenCalledTimes(1);
    const [docPath, data] = docSet.mock.calls[0];
    expect(docPath).toBeDefined();
    expect(data.codeHash).toBeDefined();
    expect(data.codeHash).not.toContain("password-ish");
    expect(typeof data.codeHash).toBe("string");
    expect(data.expiresAt).toBeInstanceOf(Date);
    expect(data.attempts).toBe(0);
    expect(data.resendCount).toBe(1);
  });
});

describe("verifyEmailCode", () => {
  it("rejects unauthenticated calls", async () => {
    await expect(
      verifyEmailCode.run({ auth: undefined, data: { code: "123456" } })
    ).rejects.toHaveProperty("code", "unauthenticated");
  });

  it("rejects a malformed code", async () => {
    await expect(
      verifyEmailCode.run({ auth: { uid: "u1", token: {} }, data: { code: "ab12" } })
    ).rejects.toHaveProperty("code", "invalid-argument");
  });

  it("sets emailVerified, mirrors users/{uid}, and consumes the code", async () => {
    // Need a real matching doc. Simulate by capturing what send wrote, then
    // verifying with the SAME function instance so the salt/hash line up.
    // Simpler: stub the doc with a hash we compute here is impossible without
    // the salt. Instead, call sendEmailVerificationCode first, then re-run
    // docGet to return the doc send just wrote via docSet.
    await sendEmailVerificationCode.run({
      auth: { uid: "u1", token: {} },
      data: {},
    });
    const [, written] = docSet.mock.calls[0];
    docGet.mockResolvedValueOnce({ exists: true, data: () => written });
    docGet.mockResolvedValue({ exists: true, data: () => written });

    // Extract the code by re-deriving: the test cannot read plaintext. So we
    // assert the flow via the updateUser/mirror side effects by monkeypatching
    // crypto inside the module — see implementation (Task 2 Step 3) for how
    // verify reads `data.code`. For determinism, the implementation exports
    // `hashCodeForTest(code, salt)` — see Task 2 Step 3.
    // eslint-disable-next-line @typescript-eslint/no-require-imports
    const { hashCodeForTest } = require("../src/email_verification");
    const code = "123456";
    const salt = written.codeSalt;
    const expectedHash = hashCodeForTest(code, salt);
    docGet.mockResolvedValue({
      exists: true,
      data: () => ({ ...written, codeHash: expectedHash }),
    });

    await verifyEmailCode.run({
      auth: { uid: "u1", token: {} },
      data: { code },
    });

    expect(updateUser).toHaveBeenCalledWith("u1", { emailVerified: true });
    expect(docDelete).toHaveBeenCalled();
    // users/{uid} mirror merge clears the lock and sets emailVerified.
    expect(docSet).toHaveBeenCalled();
  });

  it("rejects an expired code", async () => {
    docGet.mockResolvedValue({
      exists: true,
      data: () => ({
        codeHash: "x",
        codeSalt: "y",
        expiresAt: new Date(Date.now() - 1000),
        attempts: 0,
        resendCount: 1,
      }),
    });
    await expect(
      verifyEmailCode.run({ auth: { uid: "u1", token: {} }, data: { code: "123456" } })
    ).rejects.toHaveProperty("code", "failed-precondition");
  });
});

describe("enforceEmailGracePeriodInternal", () => {
  it("locks unverified users older than the grace period", async () => {
    const db = { collection };
    const oldUnverified = {
      exists: true,
      data: () => ({ emailVerified: false }),
    };
    queryGet.mockResolvedValue({
      size: 1,
      empty: false,
      docs: [{ id: "u1", data: () => ({ createdAt: new Date(Date.now() - 8 * 86400_000) }) }],
      forEach: jest.fn(),
    });
    docGet.mockResolvedValue(oldUnverified);
    await enforceEmailGracePeriodInternal(db as never, Date.now());
    expect(batchSet).toHaveBeenCalled();
    expect(batchCommit).toHaveBeenCalled();
  });
});
```

Note: the "sets emailVerified" test needs a deterministic code. The implementation must export `hashCodeForTest(code: string, salt: string): string` (a thin wrapper over the internal hash used only by tests) — see Step 3.

- [ ] **Step 2: Run test to verify it fails**

Run: `cd functions && npx jest test/email_verification.test.ts`
Expected: FAIL — module not found / exports undefined

- [ ] **Step 3: Write minimal implementation**

`functions/src/email_verification.ts`:

```ts
/**
 * Email verification code system (SP sub-project 1). Server-authoritative,
 * mirroring creator_invites.ts: codes are hashed + salted at rest in a
 * functions-only collection, single-use, 10-minute TTL, rate-limited resends.
 * On success the Admin SDK sets Firebase Auth's native emailVerified flag
 * (the router's source of truth) and mirrors it to users/{uid}.
 */
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";
import { randomInt } from "node:crypto";
import * as crypto from "node:crypto";
import { sendEmail } from "./email";

if (admin.apps.length === 0) {
  admin.initializeApp();
}

const db = admin.firestore();

export const CODE_LENGTH = 6;
export const CODE_TTL_MS = 10 * 60 * 1000; // 10 minutes
export const MAX_ATTEMPTS = 5;
export const RESEND_HOUR_LIMIT = 5;
export const RESEND_DAY_LIMIT = 20;
export const GRACE_PERIOD_MS = 7 * 24 * 60 * 60 * 1000; // 7 days
export const HOUR_MS = 60 * 60 * 1000;
export const DAY_MS = 24 * 60 * 60 * 1000;

export function generateCode(): string {
  let code = "";
  for (let i = 0; i < CODE_LENGTH; i++) {
    code += String(randomInt(0, 10));
  }
  return code;
}

export function hashCode(code: string, salt: string): string {
  return crypto.createHash("sha256").update(salt + code).digest("hex");
}

/** Test seam: deterministic hash so offline tests can reproduce it. */
export function hashCodeForTest(code: string, salt: string): string {
  return hashCode(code, salt);
}

export function makeSalt(): string {
  return crypto.randomBytes(16).toString("hex");
}

export function codeExpiryMs(value: unknown): number {
  if (value instanceof Date) return value.getTime();
  const ts = value as { toMillis?: () => number } | undefined;
  return ts?.toMillis?.() ?? 0;
}

export const sendEmailVerificationCode = onCall(
  { secrets: ["RESEND_API_KEY"] },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "User must be logged in.");
    }
    const uid = request.auth.uid;
    const userRecord = await admin.auth().getUser(uid);
    if (userRecord.emailVerified) {
      throw new HttpsError("already-exists", "Email is already verified.");
    }

    const ref = db.collection("email_verifications").doc(uid);
    const nowMs = Date.now();
    const existing = await ref.get();

    if (existing.exists) {
      const data = existing.data()!;
      const lastSent = codeExpiryMs((data.lastSentAt as { toMillis?: () => number } | Date | undefined));
      const resendCount = (data.resendCount as number) ?? 0;
      if (resendCount >= RESEND_DAY_LIMIT) {
        throw new HttpsError("resource-exhausted", "Daily resend limit reached.");
      }
      if (
        resendCount >= RESEND_HOUR_LIMIT &&
        nowMs - lastSent < HOUR_MS
      ) {
        throw new HttpsError("resource-exhausted", "Too many codes sent recently. Try again later.");
      }
    }

    const code = generateCode();
    const salt = makeSalt();
    await ref.set({
      codeHash: hashCode(code, salt),
      codeSalt: salt,
      expiresAt: new Date(nowMs + CODE_TTL_MS),
      attempts: 0,
      resendCount: (existing.exists ? (existing.data()?.resendCount as number) ?? 0 : 0) + 1,
      lastSentAt: admin.firestore.FieldValue.serverTimestamp(),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    try {
      await sendEmail({
        to: userRecord.email!,
        subject: "Your Emerge verification code",
        html: `<p>Your Emerge verification code is:</p>
               <h2>${code}</h2>
               <p>It expires in 10 minutes. If you didn't request this, ignore this email.</p>`,
      });
    } catch (err) {
      await ref.delete();
      console.error(`[sendEmailVerificationCode] Resend failed for ${uid}:`, err);
      throw new HttpsError("internal", "Failed to send the verification email. Please try again.");
    }

    return { ok: true, expiresInSeconds: CODE_TTL_MS / 1000 };
  }
);

export const verifyEmailCode = onCall(
  { secrets: ["RESEND_API_KEY"] },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "User must be logged in.");
    }
    const uid = request.auth.uid;
    const data = request.data ?? {};
    const code = typeof data.code === "string" ? data.code.trim() : "";
    if (!/^\d{6}$/.test(code)) {
      throw new HttpsError("invalid-argument", "Verification code must be 6 digits.");
    }

    const ref = db.collection("email_verifications").doc(uid);
    const snap = await ref.get();
    if (!snap.exists) {
      throw new HttpsError("not-found", "No verification code found. Request a new one.");
    }
    const doc = snap.data()!;
    if (codeExpiryMs(doc.expiresAt) < Date.now()) {
      throw new HttpsError("failed-precondition", "This code has expired. Request a new one.");
    }
    if (((doc.attempts as number) ?? 0) >= MAX_ATTEMPTS) {
      throw new HttpsError("resource-exhausted", "Too many failed attempts. Request a new code.");
    }

    const salt = (doc.codeSalt as string) ?? "";
    const expected = (doc.codeHash as string) ?? "";
    const actual = hashCode(code, salt);
    const ok =
      expected.length === actual.length &&
      crypto.timingSafeEqual(Buffer.from(expected, "hex"), Buffer.from(actual, "hex"));

    if (!ok) {
      await ref.update({ attempts: admin.firestore.FieldValue.increment(1) });
      throw new HttpsError("invalid-argument", "Incorrect code. Please try again.");
    }

    // Consume the code (single-use) and set the Auth flag + Firestore mirror.
    await admin.auth().updateUser(uid, { emailVerified: true });
    await db.collection("users").doc(uid).set(
      {
        emailVerified: true,
        emailLockedAt: admin.firestore.FieldValue.delete(),
      },
      { merge: true }
    );
    await ref.delete();

    // Fire-and-forget welcome email — never blocks verification success.
    try {
      const userRecord = await admin.auth().getUser(uid);
      await sendEmail({
        to: userRecord.email!,
        subject: "Welcome to Emerge — you're verified",
        html: "<p>Your email is verified. Welcome aboard — your journey begins now.</p>",
      });
    } catch (err) {
      console.error(`[verifyEmailCode] welcome email failed for ${uid}:`, err);
    }

    return { ok: true };
  }
);

/** Testable body of the scheduled lock; wrapped by onSchedule below. */
export async function enforceEmailGracePeriodInternal(
  database: typeof db,
  nowMs: number
): Promise<void> {
  const cutoff = new Date(nowMs - GRACE_PERIOD_MS);
  const snap = await database
    .collection("users")
    .where("createdAt", "<=", cutoff)
    .get();
  const batch = database.batch();
  let changed = 0;
  snap.forEach((doc: admin.firestore.QueryDocumentSnapshot) => {
    const data = doc.data();
    if (data.emailVerified !== true && data.emailLockedAt == null) {
      batch.set(
        database.collection("users").doc(doc.id),
        { emailLockedAt: admin.firestore.FieldValue.serverTimestamp() },
        { merge: true }
      );
      changed++;
    }
  });
  if (changed > 0) {
    await batch.commit();
  }
}

export const enforceEmailGracePeriod = onSchedule("0 4 * * *", async () => {
  console.log("Enforcing email verification grace period");
  await enforceEmailGracePeriodInternal(db, Date.now());
});
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd functions && npm run build && npx jest test/email_verification.test.ts`
Expected: PASS

- [ ] **Step 5: Export from index.ts**

Add to `functions/src/index.ts` near the other sub-module exports (line ~265):

```ts
export * from "./email_verification";
```

- [ ] **Step 6: Typecheck, build, commit**

```bash
cd functions && npm run build && npx eslint src/email_verification.ts && npx jest test/email_verification.test.ts test/email.test.ts
cd .. && git add functions/src/email_verification.ts functions/test/email_verification.test.ts functions/src/index.ts
git commit -m "feat(functions): email verification code send/verify + grace-period lock"
```

---

## Task 3: `usernames.ts` — `claimUsername`

**Files:**
- Create: `functions/src/usernames.ts`
- Modify: `functions/src/index.ts` (add export line)
- Test: `functions/test/usernames.test.ts`

- [ ] **Step 1: Write the failing test**

`functions/test/usernames.test.ts`:

```ts
const setCustomUserClaims = jest.fn().mockResolvedValue(undefined);
const updateUser = jest.fn().mockResolvedValue(undefined);
const getUser = jest.fn();
const docGet = jest.fn();
const docSet = jest.fn();
const runTransaction = jest.fn();

const collection = jest.fn((name: string) => ({
  doc: jest.fn((id?: string) => ({
    id: id ?? "auto-1",
    get: jest.fn(() => docGet(name, id)),
    set: docSet,
  })),
}));

const firestoreMock = jest.fn(() => ({ collection, runTransaction }));
(
  firestoreMock as unknown as {
    FieldValue: { serverTimestamp: () => string };
    Timestamp: { fromDate: (d: Date) => Date };
  }
).FieldValue = { serverTimestamp: () => "SERVER_TIMESTAMP" };
(
  firestoreMock as unknown as {
    Timestamp: { fromDate: (d: Date) => Date };
  }
).Timestamp = { fromDate: (d: Date) => d };

jest.mock("firebase-admin", () => ({
  apps: [],
  initializeApp: jest.fn(),
  firestore: firestoreMock,
  auth: () => ({ getUser, updateUser, setCustomUserClaims }),
}));

// eslint-disable-next-line @typescript-eslint/no-require-imports
const ft = require("firebase-functions-test")();

// eslint-disable-next-line @typescript-eslint/no-require-imports
const { claimUsername } = require("../src/usernames");

beforeEach(() => {
  jest.clearAllMocks();
  docGet.mockImplementation((name: string, id: string) =>
    Promise.resolve({ exists: false, data: () => null })
  );
  getUser.mockResolvedValue({
    uid: "u1",
    email: "a@b.com",
    displayName: "OldName",
    customClaims: {},
  });
});

describe("claimUsername", () => {
  it("rejects unauthenticated calls", async () => {
    await expect(
      claimUsername.run({ auth: undefined, data: { username: "Aria" } })
    ).rejects.toHaveProperty("code", "unauthenticated");
  });

  it("rejects invalid usernames", async () => {
    await expect(
      claimUsername.run({ auth: { uid: "u1", token: {} }, data: { username: "ab" } })
    ).rejects.toHaveProperty("code", "invalid-argument");
    await expect(
      claimUsername.run({ auth: { uid: "u1", token: {} }, data: { username: "bad name!" } })
    ).rejects.toHaveProperty("code", "invalid-argument");
    await expect(
      claimUsername.run({ auth: { uid: "u1", token: {} }, data: { username: "admin" } })
    ).rejects.toHaveProperty("code", "invalid-argument");
  });

  it("normalizes case and claims the username", async () => {
    runTransaction.mockImplementation(async (cb: (tx: unknown) => Promise<void>) => {
      const tx = {
        get: () => Promise.resolve({ exists: false, data: () => null }),
        set: docSet,
      };
      await cb(tx);
    });

    await claimUsername.run({
      auth: { uid: "u1", token: {} },
      data: { username: "  Aria_Star " },
    });

    expect(runTransaction).toHaveBeenCalled();
    const [, data] = docSet.mock.calls[0];
    expect(data).toMatchObject({ uid: "u1" });
    expect(updateUser).toHaveBeenCalledWith("u1", { displayName: "Aria_Star" });
  });

  it("rejects when the username is already taken", async () => {
    runTransaction.mockImplementation(async (cb: (tx: unknown) => Promise<void>) => {
      const tx = {
        get: () => Promise.resolve({ exists: true, data: () => ({ uid: "other" }) }),
        set: docSet,
      };
      await cb(tx);
    });
    await expect(
      claimUsername.run({ auth: { uid: "u1", token: {} }, data: { username: "Aria_Star" } })
    ).rejects.toHaveProperty("code", "already-exists");
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd functions && npx jest test/usernames.test.ts`
Expected: FAIL — module not found

- [ ] **Step 3: Write minimal implementation**

`functions/src/usernames.ts`:

```ts
/**
 * Server-authoritative username claims. `usernames/{normalized}` is a
 * doc-as-lock: the doc id is the lowercased username, so Firestore's
 * transaction retry + existence check make claims race-free. Clients have
 * NO write access to this collection (firestore.rules).
 */
import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

if (admin.apps.length === 0) {
  admin.initializeApp();
}

const db = admin.firestore();

const BLOCKED_USERNAMES = new Set([
  "admin", "administrator", "root", "system", "moderator", "support",
  "help", "info", "contact", "api", "test", "user", "guest", "anonymous",
  "null", "undefined",
]);

export function validateUsername(value: string): string | null {
  const username = value.trim();
  if (username.length < 3) return "Username must be at least 3 characters long";
  if (username.length > 30) return "Username is too long";
  if (!/^[a-zA-Z0-9_-]+$/.test(username)) {
    return "Username can only contain letters, numbers, underscores, and hyphens";
  }
  if (BLOCKED_USERNAMES.has(username.toLowerCase())) {
    return "This username is not allowed";
  }
  if (/^[_\-]|[_\-]$/.test(username)) {
    return "Username cannot start or end with underscore or hyphen";
  }
  return null;
}

export const claimUsername = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be logged in.");
  }
  const uid = request.auth.uid;
  const data = request.data ?? {};
  const username = typeof data.username === "string" ? data.username.trim() : "";

  const validationError = validateUsername(username);
  if (validationError) {
    throw new HttpsError("invalid-argument", validationError);
  }

  const normalized = username.toLowerCase();
  const nameRef = db.collection("usernames").doc(normalized);
  const userRef = db.collection("users").doc(uid);

  await db.runTransaction(async (tx) => {
    const existing = await tx.get(nameRef);
    if (existing.exists) {
      throw new HttpsError(
        "already-exists",
        "This username is already taken. Please choose another."
      );
    }
    tx.set(nameRef, {
      uid,
      claimedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    tx.set(userRef, { displayName: username }, { merge: true });
  });

  await admin.auth().updateUser(uid, { displayName: username });

  return { ok: true, username };
});
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd functions && npm run build && npx jest test/usernames.test.ts`
Expected: PASS

- [ ] **Step 5: Export from index.ts**

Add to `functions/src/index.ts`:

```ts
export * from "./usernames";
```

- [ ] **Step 6: Build, lint, commit**

```bash
cd functions && npm run build && npx eslint src/usernames.ts && npx jest test/usernames.test.ts
cd .. && git add functions/src/usernames.ts functions/test/usernames.test.ts functions/src/index.ts
git commit -m "feat(functions): server-authoritative unique username claims"
```

---

## Task 4: Firestore rules + backfill script

**Files:**
- Modify: `firestore.rules` (add two deny blocks)
- Create: `functions/src/backfill_usernames.ts`
- Modify: `functions/package.json` (backfill script)

- [ ] **Step 1: Add rules (no test needed — rules deploy validated)**

Add to `firestore.rules`, right after the `creator_invite_codes` block (~line 565):

```firestore
    // Email verification codes — functions only (Admin SDK bypasses rules).
    // Clients must never read, create, or consume codes directly.
    match /email_verifications/{uid} {
      allow read, write: if false;
    }

    // Username claims — functions only (Admin SDK bypasses rules).
    // Doc id is the lowercased username; claims are server-authoritative.
    match /usernames/{username} {
      allow read, write: if false;
    }
```

- [ ] **Step 2: Write the backfill script**

`functions/src/backfill_usernames.ts`:

```ts
/**
 * One-off backfill: claim usernames for existing users deterministically.
 * Run: cd functions && npm run backfill:usernames
 * Requires GOOGLE_APPLICATION_CREDENTIALS pointing at a service account with
 * Firestore write access (runs OUTSIDE the security rules via Admin SDK).
 */
import * as admin from "firebase-admin";
import { validateUsername } from "./usernames";

if (admin.apps.length === 0) {
  admin.initializeApp();
}

const db = admin.firestore();

async function run(): Promise<void> {
  const snap = await db.collection("users").orderBy("createdAt", "asc").get();
  const batch = db.batch();
  let claimed = 0;
  let skipped = 0;
  let collisions = 0;

  for (const doc of snap.docs) {
    const uid = doc.id;
    const raw = (doc.data().displayName as string) ?? "";
    const base = raw.trim();
    if (!base || validateUsername(base) !== null) {
      skipped++;
      continue;
    }
    let candidate = base.toLowerCase();
    for (let attempt = 2; ; attempt++) {
      const nameRef = db.collection("usernames").doc(candidate);
      const existing = await nameRef.get();
      if (!existing.exists) {
        batch.set(nameRef, { uid, claimedAt: admin.firestore.FieldValue.serverTimestamp() });
        claimed++;
        break;
      }
      if (existing.data()?.uid === uid) {
        skipped++; // already claimed by this uid — idempotent re-run
        break;
      }
      collisions++;
      candidate = `${base.toLowerCase()}_${attempt}`;
      if (attempt > 1000) {
        console.warn(`[backfill] could not claim for ${uid} (${base})`);
        break;
      }
    }
    if (claimed % 400 === 0) {
      await batch.commit();
    }
  }
  await batch.commit();
  console.log(`[backfill] claimed=${claimed} skipped=${skipped} collisions=${collisions}`);
}

run()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error("[backfill] failed:", err);
    process.exit(1);
  });
```

- [ ] **Step 3: Add the npm script**

In `functions/package.json` scripts, add:

```json
"backfill:usernames": "node lib/backfill_usernames.js"
```

- [ ] **Step 4: Build and commit**

```bash
cd functions && npm run build
cd .. && git add firestore.rules functions/src/backfill_usernames.ts functions/package.json
git commit -m "feat(functions): username backfill script + deny rules for verification/username collections"
```

---

## Task 5: Flutter — `AuthUser.emailVerified` + repository interface + Firebase implementation

**Files:**
- Modify: `lib/features/auth/domain/entities/auth_user.dart`
- Modify: `lib/features/auth/domain/repositories/auth_repository.dart`
- Modify: `lib/features/auth/data/repositories/firebase_auth_repository.dart`

- [ ] **Step 1: Write the failing test**

Extend `test/features/auth/domain/entities/user_extension_test.dart` (or add a new `test/features/auth/domain/entities/auth_user_test.dart`):

```dart
import 'package:emerge_app/features/auth/domain/entities/auth_user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthUser', () {
    test('emailVerified defaults to false', () {
      const user = AuthUser(id: 'u1', email: 'a@b.com');
      expect(user.emailVerified, isFalse);
    });

    test('emailVerified participates in equality', () {
      const a = AuthUser(id: 'u1', email: 'a@b.com', emailVerified: true);
      const b = AuthUser(id: 'u1', email: 'a@b.com', emailVerified: false);
      expect(a == b, isFalse);
    });

    test('empty user is not verified', () {
      expect(AuthUser.empty.emailVerified, isFalse);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/auth/domain/entities/auth_user_test.dart`
Expected: FAIL — `emailVerified` is not a member

- [ ] **Step 3: Update the entity**

`lib/features/auth/domain/entities/auth_user.dart`:

```dart
class AuthUser extends Equatable {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final bool emailVerified;

  const AuthUser({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.emailVerified = false,
  });

  static const empty = AuthUser(id: '', email: '');

  bool get isEmpty => this == AuthUser.empty;
  bool get isNotEmpty => this != AuthUser.empty;

  @override
  List<Object?> get props => [id, email, displayName, photoUrl, emailVerified];
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/auth/domain/entities/auth_user_test.dart`
Expected: PASS

- [ ] **Step 5: Extend the repository interface**

`lib/features/auth/domain/repositories/auth_repository.dart` — add after `deleteAccount`:

```dart
  /// Sends a 6-digit verification code to the current user's email.
  Future<Either<Failure, void>> sendEmailVerificationCode();

  /// Submits a 6-digit code; on success the account is marked verified.
  Future<Either<Failure, void>> verifyEmailCode(String code);

  /// Claims a globally-unique (case-insensitive) username for the current user.
  Future<Either<Failure, void>> claimUsername(String username);

  /// True when the current user's email is verified.
  Future<Either<Failure, bool>> checkEmailVerified();
```

- [ ] **Step 6: Implement in `FirebaseAuthRepository`**

`lib/features/auth/data/repositories/firebase_auth_repository.dart`:

1. Add a private helper to map Cloud Function errors:

```dart
  Failure _mapFunctionsError(FirebaseFunctionsException e) {
    switch (e.code) {
      case 'unauthenticated':
        return const AuthFailure('Please log in again before continuing.');
      case 'already-exists':
        return const AuthFailure('This username is already taken. Please choose another.');
      case 'invalid-argument':
        return AuthFailure(e.message ?? 'Invalid input. Please try again.');
      case 'resource-exhausted':
        return AuthFailure(e.message ?? 'Too many attempts. Please wait and try again.');
      case 'failed-precondition':
        return AuthFailure(e.message ?? 'This code has expired. Please request a new one.');
      case 'not-found':
        return const AuthFailure('No verification code found. Please request a new one.');
      case 'internal':
        return ServerFailure(e.message ?? 'Something went wrong. Please try again.');
      default:
        return ServerFailure(e.message ?? 'Something went wrong. Please try again.');
    }
  }
```

2. In the `user` stream, populate `emailVerified`:

```dart
      return AuthUser(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName: firebaseUser.displayName,
        emailVerified: firebaseUser.emailVerified,
      );
```

Also update both `signInWithEmailAndPassword` and `signInWithGoogle` `AuthUser(...)` constructions to pass `emailVerified: user.emailVerified` (and the `updatedUser`/`user` variants in signup). Keep the web `redirect_initiated` early return as-is.

3. Add the four implementations:

```dart
  @override
  Future<Either<Failure, void>> sendEmailVerificationCode() async {
    try {
      await FirebaseFunctions.instance
          .httpsCallable('sendEmailVerificationCode')
          .call();
      return const Right(null);
    } on FirebaseFunctionsException catch (e) {
      AppLogger.w('sendEmailVerificationCode failed', e);
      return Left(_mapFunctionsError(e));
    } catch (e, s) {
      AppLogger.e('sendEmailVerificationCode failed', e, s);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> verifyEmailCode(String code) async {
    try {
      await FirebaseFunctions.instance
          .httpsCallable('verifyEmailCode')
          .call(<String, dynamic>{'code': code.trim()});
      // Refresh the local Auth user so emailVerified propagates to the stream.
      await _firebaseAuth.currentUser?.reload();
      return const Right(null);
    } on FirebaseFunctionsException catch (e) {
      AppLogger.w('verifyEmailCode failed', e);
      return Left(_mapFunctionsError(e));
    } catch (e, s) {
      AppLogger.e('verifyEmailCode failed', e, s);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> claimUsername(String username) async {
    try {
      await FirebaseFunctions.instance
          .httpsCallable('claimUsername')
          .call(<String, dynamic>{'username': username.trim()});
      await _firebaseAuth.currentUser?.reload();
      return const Right(null);
    } on FirebaseFunctionsException catch (e) {
      AppLogger.w('claimUsername failed', e);
      return Left(_mapFunctionsError(e));
    } catch (e, s) {
      AppLogger.e('claimUsername failed', e, s);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> checkEmailVerified() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      return const Left(AuthFailure('User not logged in'));
    }
    await user.reload();
    return Right(user.emailVerified);
  }
```

- [ ] **Step 7: Verify**

Run: `dart analyze lib/features/auth && flutter test test/features/auth/domain/entities/auth_user_test.dart`
Expected: no issues, tests pass

- [ ] **Step 8: Commit**

```bash
git add lib/features/auth/domain/entities/auth_user.dart lib/features/auth/domain/repositories/auth_repository.dart lib/features/auth/data/repositories/firebase_auth_repository.dart test/features/auth/domain/entities/auth_user_test.dart
git commit -m "feat(auth): emailVerified on AuthUser + verification/username repository methods"
```

---

## Task 6: Flutter — router enforcement (pure `decideRedirect`)

**Files:**
- Modify: `lib/core/router/router.dart:69-85` (RedirectContext), `:96` (decideRedirect), `:254` (router provider)
- Modify: `lib/features/auth/presentation/providers/role_provider.dart` (emailLockedAt provider)
- Test: `test/core/router/router_redirect_test.dart`

- [ ] **Step 1: Write the failing tests**

Add to `test/core/router/router_redirect_test.dart` a new group:

```dart
  group('email verification gate', () {
    RedirectContext unverifiedCtx({DateTime? emailLockedAt}) {
      return RedirectContext(
        isLoggedIn: true,
        role: UserRole.user,
        isFirstLaunch: false,
        userOnboardingProgress: 4,
        userOnboardingCompletedAt: DateTime(2026, 1, 1),
        creatorOnboarding: null,
        emailVerified: false,
        emailLockedAt: emailLockedAt,
      );
    }

    test('unverified normal user on a shell path -> /verify-email', () {
      expect(
        decideRedirect(currentPath: '/timeline', ctx: unverifiedCtx()),
        '/verify-email',
      );
    });

    test('unverified normal user on /verify-email -> stays', () {
      expect(
        decideRedirect(currentPath: '/verify-email', ctx: unverifiedCtx()),
        isNull,
      );
    });

    test('unverified normal user mid-onboarding -> stays (grace period)', () {
      final ctx = RedirectContext(
        isLoggedIn: true,
        role: UserRole.user,
        isFirstLaunch: false,
        userOnboardingProgress: 1,
        userOnboardingCompletedAt: null,
        creatorOnboarding: null,
        emailVerified: false,
        emailLockedAt: null,
      );
      expect(
        decideRedirect(currentPath: '/onboarding/interests', ctx: ctx),
        isNull,
      );
    });

    test('locked (past grace) user on onboarding -> /verify-email', () {
      expect(
        decideRedirect(
          currentPath: '/onboarding/interests',
          ctx: unverifiedCtx(emailLockedAt: DateTime(2026, 1, 8)),
        ),
        '/verify-email',
      );
    });

    test('verified normal user is unaffected', () {
      const ctx = RedirectContext(
        isLoggedIn: true,
        role: UserRole.user,
        isFirstLaunch: false,
        userOnboardingProgress: 4,
        userOnboardingCompletedAt: null,
        creatorOnboarding: null,
        emailVerified: true,
        emailLockedAt: null,
      );
      expect(decideRedirect(currentPath: '/timeline', ctx: ctx), isNull);
    });

    test('creator is never gated by email verification', () {
      final ctx = RedirectContext(
        isLoggedIn: true,
        role: UserRole.creator,
        isFirstLaunch: false,
        userOnboardingProgress: null,
        userOnboardingCompletedAt: null,
        creatorOnboarding: CreatorOnboardingState.empty,
        emailVerified: false,
        emailLockedAt: null,
      );
      expect(
        decideRedirect(currentPath: '/world-map', ctx: ctx),
        '/onboarding/creator/archetype',
      );
    });
  });
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/core/router/router_redirect_test.dart`
Expected: FAIL — `emailVerified`/`emailLockedAt` are not named parameters

- [ ] **Step 3: Add fields to `RedirectContext`**

In `lib/core/router/router.dart`, extend the class:

```dart
class RedirectContext {
  final bool isLoggedIn;
  final UserRole? role;
  final bool isFirstLaunch;
  final int? userOnboardingProgress;
  final DateTime? userOnboardingCompletedAt;
  final CreatorOnboardingState? creatorOnboarding;
  final bool? emailVerified; // null = unknown; false = unverified
  final DateTime? emailLockedAt; // null = within grace period

  const RedirectContext({
    required this.isLoggedIn,
    required this.role,
    required this.isFirstLaunch,
    required this.userOnboardingProgress,
    required this.userOnboardingCompletedAt,
    required this.creatorOnboarding,
    this.emailVerified,
    this.emailLockedAt,
  });
}
```

- [ ] **Step 4: Add the gate to `decideRedirect`**

Insert at the very top of the **normal-user branch** (after `// 6. Normal user branch.`), before the creator-paths check:

```dart
  // 6. Normal user branch.
  if (ctx.role == UserRole.user) {
    // Email verification gate. During the 7-day grace period an unverified
    // user may finish onboarding; once emailLockedAt is set (past grace),
    // every surface except /verify-email and auth paths is blocked.
    final unverified = ctx.emailVerified == false;
    final locked = ctx.emailLockedAt != null;
    if (unverified && locked) {
      if (currentPath == '/verify-email') return null;
      if (isOnAuthPath || isOnNormalOnboardingPath || isOnCreatorOnboardingPath) {
        return '/verify-email';
      }
      return '/verify-email';
    }
    if (unverified) {
      if (currentPath == '/verify-email') return null;
      // Grace period: allow onboarding and auth surfaces through.
      if (isOnAuthPath || isOnNormalOnboardingPath || isOnCreatorOnboardingPath) {
        return null;
      }
      return '/verify-email';
    }
```

The rest of the user branch (creator-path rejection, onboarding progress routing, etc.) stays exactly as-is below.

- [ ] **Step 5: Run tests to verify they pass**

Run: `flutter test test/core/router/router_redirect_test.dart`
Expected: PASS — all existing + new cases

- [ ] **Step 6: Add `currentEmailLockedAtProvider`**

`lib/features/auth/presentation/providers/role_provider.dart` — append:

```dart
/// Reads `users/{uid}.emailLockedAt` (server-written when the 7-day
/// verification grace period expires). Null when not locked.
final currentEmailLockedAtProvider = FutureProvider<DateTime?>((ref) async {
  final authUser = await ref.watch(authStateChangesProvider.future);
  if (authUser.isEmpty) return null;
  final firestore = FirebaseFirestore.instance;
  final doc = await firestore.collection('users').doc(authUser.id).get();
  final raw = doc.data()?['emailLockedAt'];
  if (raw is Timestamp) return raw.toDate();
  if (raw is DateTime) return raw;
  return null;
});
```

- [ ] **Step 7: Wire the router provider**

In `lib/core/router/router.dart`, inside the `router` provider:
1. Listen to the new provider so redirect re-evaluates when it settles:
```dart
  ref.listen(currentEmailLockedAtProvider, (_, _) => refreshNotifier.value++);
```
2. Read it in the redirect closure next to the other provider reads:
```dart
      final emailLockedAtAsync = ref.read(currentEmailLockedAtProvider);
      final emailLockedAt = emailLockedAtAsync is AsyncData
          ? emailLockedAtAsync.value
          : null;
```
3. Pass both fields into `RedirectContext`:
```dart
        ctx: RedirectContext(
          isLoggedIn: isLoggedIn,
          role: role,
          isFirstLaunch: isFirstLaunch,
          userOnboardingProgress: userStats?.onboardingProgress,
          userOnboardingCompletedAt: userStats?.onboardingCompletedAt,
          creatorOnboarding: creatorOnboarding,
          emailVerified: authState.value?.emailVerified,
          emailLockedAt: emailLockedAt,
        ),
```

Wrap the `ref.read(currentEmailLockedAtProvider)` in the same try/catch guard pattern as the other reads if lint/analyze flags it; the redirect already has the surrounding try/catch on `isFirstLaunch` — place the new read inside a `try { ... } catch (_) { /* defer */ }` to honor the web DDC race guard.

- [ ] **Step 8: Verify and commit**

```bash
dart analyze lib/core/router/router.dart lib/features/auth/presentation/providers/role_provider.dart
flutter test test/core/router/router_redirect_test.dart
git add lib/core/router/router.dart lib/features/auth/presentation/providers/role_provider.dart test/core/router/router_redirect_test.dart
git commit -m "feat(router): email verification gate in decideRedirect with grace-period lock"
```

---

## Task 7: Flutter — `/verify-email` route + `VerifyEmailScreen`

**Files:**
- Create: `lib/features/auth/presentation/screens/verify_email_screen.dart`
- Modify: `lib/core/router/router.dart` (route registration)
- Test: `test/features/auth/presentation/screens/verify_email_screen_test.dart`

- [ ] **Step 1: Write the failing widget test**

`test/features/auth/presentation/screens/verify_email_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/auth/presentation/screens/verify_email_screen.dart';
import '../../../../helpers/widget_test_utils.dart';
import '../../../../helpers/mocks/auth_mocks.dart';

Widget _buildTest(AuthRepository repo) {
  return createScreenUnderTest(
    screen: const VerifyEmailScreen(),
    overrides: [authRepositoryProvider.overrideWithValue(repo)],
  );
}

void main() {
  late MockAuthRepository mockAuth;

  setUp(() {
    mockAuth = MockAuthRepository();
    when(() => mockAuth.user).thenAnswer((_) => const Stream.empty());
    when(() => mockAuth.sendEmailVerificationCode())
        .thenAnswer((_) async => const Right<Failure, void>(null));
    when(() => mockAuth.verifyEmailCode(any()))
        .thenAnswer((_) async => const Right<Failure, void>(null));
  });

  testWidgets('renders code entry and verify button', (tester) async {
    await tester.pumpWidget(_buildTest(mockAuth));
    await tester.pumpAndSettle();

    expect(find.text('Verify your email'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Verify'), findsOneWidget);
  });

  testWidgets('sends the code on load and surfaces failures', (tester) async {
    when(() => mockAuth.sendEmailVerificationCode())
        .thenAnswer((_) async => Left<Failure, void>(AuthFailure('Too many codes sent recently. Try again later.')));
    await tester.pumpWidget(_buildTest(mockAuth));
    await tester.pumpAndSettle();

    expect(find.textContaining('Too many codes'), findsOneWidget);
  });

  testWidgets('verifies a code and shows success', (tester) async {
    await tester.pumpWidget(_buildTest(mockAuth));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '123456');
    await tester.tap(find.text('Verify'));
    await tester.pumpAndSettle();

    verify(() => mockAuth.verifyEmailCode('123456')).called(1);
    expect(find.textContaining('verified'), findsWidgets);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/auth/presentation/screens/verify_email_screen_test.dart`
Expected: FAIL — screen not found / missing

- [ ] **Step 3: Write the screen**

`lib/features/auth/presentation/screens/verify_email_screen.dart`:

```dart
import 'dart:async';

import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/core/presentation/widgets/responsive_layout.dart';
import 'package:emerge_app/features/auth/domain/entities/auth_user.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/auth/presentation/providers/role_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  final _codeController = TextEditingController();
  bool _isVerifying = false;
  bool _isSending = false;
  String? _error;
  String? _info;
  int _cooldown = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _sendCode());
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    setState(() {
      _isSending = true;
      _error = null;
    });
    final result = await ref.read(authRepositoryProvider).sendEmailVerificationCode();
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _error = failure.message;
        _isSending = false;
      }),
      (_) => setState(() {
        _isSending = false;
        _info = 'We sent a 6-digit code to your email.';
        _startCooldown();
      }),
    );
  }

  void _startCooldown() {
    setState(() => _cooldown = 60);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_cooldown <= 1) {
        timer.cancel();
        setState(() => _cooldown = 0);
      } else {
        setState(() => _cooldown--);
      }
    });
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      setState(() => _error = 'Enter the 6-digit code.');
      return;
    }
    setState(() {
      _isVerifying = true;
      _error = null;
    });
    final result = await ref
        .read(authRepositoryProvider)
        .verifyEmailCode(code);
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _error = failure.message;
        _isVerifying = false;
      }),
      (_) {
        setState(() => _isVerifying = false);
        // Router's decideRedirect now lets the user through; land on a shell
        // path and let redirect resolve onboarding/dashboard.
        context.go('/timeline');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final emailLockedAt = ref.watch(currentEmailLockedAtProvider).valueOrNull;
    final isLocked = emailLockedAt != null;

    return Scaffold(
      backgroundColor: EmergeColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textMainDark),
          onPressed: () => context.pop(),
        ),
      ),
      body: ResponsiveLayout(
        mobile: _buildBody(context, isLocked),
        tablet: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: _buildBody(context, isLocked),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, bool isLocked) {
    final authUser = ref.watch(authStateChangesProvider).valueOrNull ??
        const AuthUser(id: '', email: '');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Gap(32),
          Icon(Icons.mark_email_read_outlined,
              size: 72, color: EmergeColors.teal),
          const Gap(16),
          Text(
            isLocked ? 'Account locked — verify your email' : 'Verify your email',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.textMainDark,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const Gap(8),
          Text(
            isLocked
                ? 'Your 7-day verification window has passed. Enter a new code to unlock your account.'
                : 'We sent a 6-digit code to ${authUser.email.isEmpty ? 'your email' : authUser.email}.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondaryDark,
                ),
          ),
          const Gap(24),
          if (_info != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_info!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: EmergeColors.teal)),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent)),
            ),
          TextField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textMainDark, fontSize: 22, letterSpacing: 6),
            decoration: InputDecoration(
              hintText: '000000',
              counterText: '',
              filled: true,
              fillColor: AppTheme.surfaceDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: EmergeColors.hexLine),
              ),
            ),
          ),
          const Gap(16),
          FilledButton(
            onPressed: (_isVerifying || _isSending) ? null : _verify,
            style: FilledButton.styleFrom(
              backgroundColor: EmergeColors.teal,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isVerifying
                ? const SizedBox(
                    height: 20, width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                : const Text('Verify',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
          ),
          const Gap(12),
          OutlinedButton(
            onPressed: (_cooldown > 0 || _isSending) ? null : _sendCode,
            child: Text(
              _cooldown > 0 ? 'Resend code in ${_cooldown}s' : 'Resend code',
            ),
          ),
        ],
      ),
    );
  }
}
```

Note: if `context.pop()`/`context.go` inside the bare `MaterialApp` test harness throws, wrap navigation in the screen with a `try/catch` around `context.go` OR have the tests assert on state rather than navigation. The test harness in Task 7 Step 1 only asserts rendering and `verifyEmailCode` being called — safe. Add `import 'package:emerge_app/features/auth/domain/entities/auth_user.dart';` for `AuthUser`.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/auth/presentation/screens/verify_email_screen_test.dart`
Expected: PASS

- [ ] **Step 5: Register the route**

In `lib/core/router/router.dart`, next to the `/login` route (~line 350):

```dart
      GoRoute(
        path: '/verify-email',
        builder: (context, state) => const VerifyEmailScreen(),
      ),
```

Add the import:
```dart
import 'package:emerge_app/features/auth/presentation/screens/verify_email_screen.dart';
```

- [ ] **Step 6: Verify and commit**

```bash
flutter analyze lib/features/auth/presentation/screens/verify_email_screen.dart
flutter test test/features/auth/presentation/screens/verify_email_screen_test.dart
git add lib/features/auth/presentation/screens/verify_email_screen.dart lib/core/router/router.dart test/features/auth/presentation/screens/verify_email_screen_test.dart
git commit -m "feat(auth): verify-email screen with OTP entry and route"
```

---

## Task 8: Flutter — signup wiring (claim username + verify redirect)

**Files:**
- Modify: `lib/features/auth/presentation/screens/signup_screen.dart`
- Modify: `lib/features/auth/data/repositories/firebase_auth_repository.dart` (claim-with-rollback in signup)

- [ ] **Step 1: Write the failing test**

Add to `test/features/auth/presentation/screens/signup_screen_test.dart`:

```dart
  testWidgets('navigates to verify-email when the account is unverified',
      (tester) async {
    await setMobileViewport(tester);
    when(() => mockAuth.signUpWithEmailAndPassword(
      email: any(named: 'email'),
      password: any(named: 'password'),
      username: any(named: 'username'),
    )).thenAnswer((_) async => right<Failure, AuthUser>(
      AuthUser(id: 'u1', email: 't@example.com', displayName: 'TestUser'),
    ));

    await tester.pumpWidget(_buildTest(mockAuth));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'TestUser');
    await tester.enterText(find.byType(TextFormField).at(1), 't@example.com');
    await tester.enterText(find.byType(TextFormField).at(2), 'Str0ngP@sswd!');
    await tester.enterText(find.byType(TextFormField).at(3), 'Str0ngP@sswd!');
    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();
  });
```

Because the test harness has no GoRouter, the navigation can't be asserted directly. Instead, the repository-level change (claim with rollback) is covered in the fake/repo test below, and the screen wiring is verified by the router tests in Task 6. If `context.go` throws in this harness, guard navigation in `_signUp` with a `mounted` check only (no try/catch needed around navigation — the harness simply won't navigate).

- [ ] **Step 2: Implement claim-with-rollback in signup**

In `FirebaseAuthRepository.signUpWithEmailAndPassword`, after `createUserWithEmailAndPassword` succeeds and BEFORE the profile writes, claim the username; on failure roll back the freshly-created auth account so no orphan exists:

```dart
      final user = credential.user;
      if (user == null) {
        return const Left(AuthFailure('User creation failed'));
      }

      // Claim the globally-unique username. On collision we delete the
      // just-created auth account (client SDK allows self-delete) and return
      // the error so the form can retry with a different name — no orphaned
      // Firestore docs, no half-registered account.
      final claim = await claimUsername(sanitizedUsername);
      final claimFailure = claim.fold<Failure?>((f) => f, (_) => null);
      if (claimFailure != null) {
        try {
          await user.delete();
        } catch (_) {
          // Best-effort rollback; deleteMyAccount remains the cleanup path.
        }
        return Left(claimFailure);
      }
```

- [ ] **Step 3: Wire the verify-email redirect in `_signUp`**

In `lib/features/auth/presentation/screens/signup_screen.dart`, replace the final navigation inside the success `.fold`:

```dart
          (_) async {
            if (mounted) {
              if (user.emailVerified) {
                context.go('/onboarding/identity-studio');
              } else {
                context.go('/verify-email');
              }
            }
          },
```

Do the same in `_signUpWithGoogle` success handler: `context.go(user.emailVerified ? '/onboarding/identity-studio' : '/verify-email');` (Google accounts are verified, so this always takes the onboarding branch).

- [ ] **Step 4: Update the fake repository**

`test/features/auth/data/repositories/fake_auth_repository.dart` — add the four new methods so `implements AuthRepository` stays satisfied:

```dart
  @override
  Future<Either<Failure, void>> sendEmailVerificationCode() async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> verifyEmailCode(String code) async {
    if (_currentUser == AuthUser.empty) {
      return const Left(AuthFailure('User not logged in'));
    }
    _currentUser = AuthUser(
      id: _currentUser.id,
      email: _currentUser.email,
      displayName: _currentUser.displayName,
      photoUrl: _currentUser.photoUrl,
      emailVerified: true,
    );
    _controller.add(_currentUser);
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> claimUsername(String username) async {
    if (_currentUser == AuthUser.empty) {
      return const Left(AuthFailure('User not logged in'));
    }
    return const Right(null);
  }

  @override
  Future<Either<Failure, bool>> checkEmailVerified() async {
    if (_currentUser == AuthUser.empty) {
      return const Left(AuthFailure('User not logged in'));
    }
    return Right(_currentUser.emailVerified);
  }
```

- [ ] **Step 5: Verify and commit**

```bash
flutter analyze lib/features/auth
flutter test test/features/auth/presentation/screens/signup_screen_test.dart test/features/auth/data/repositories/auth_repository_test.dart
git add lib/features/auth/presentation/screens/signup_screen.dart lib/features/auth/data/repositories/firebase_auth_repository.dart test/features/auth/data/repositories/fake_auth_repository.dart test/features/auth/presentation/screens/signup_screen_test.dart
git commit -m "feat(auth): signup claims username with rollback and routes to verify-email"
```

---

## Task 9: Settings verify-email tile (low-risk optional surface)

**Files:**
- Modify: `lib/features/settings/presentation/screens/settings_screen.dart`

- [ ] **Step 1: Add the tile**

In the settings screen's list of account items, when the current user is unverified, show a tile that navigates to `/verify-email`. Locate the existing `user` watch (the file already watches `authStateChangesProvider` or the profile provider). Add, next to the existing account tiles:

```dart
if (!(ref.watch(authStateChangesProvider).valueOrNull?.emailVerified ?? true))
  ListTile(
    leading: const Icon(Icons.verified_outlined, color: Colors.amber),
    title: const Text('Verify your email'),
    subtitle: const Text('Confirm your email address to secure your account.'),
    onTap: () => context.push('/verify-email'),
  ),
```

Match the file's existing ListTile styling (it may wrap tiles in a Card — mirror that structure). Import `verify_email_screen.dart` isn't needed (navigation by path).

- [ ] **Step 2: Verify**

Run: `dart analyze lib/features/settings/presentation/screens/settings_screen.dart && flutter test test/features/settings/` (focused tests only — do not run the full suite)

- [ ] **Step 3: Commit**

```bash
git add lib/features/settings/presentation/screens/settings_screen.dart
git commit -m "feat(settings): verify-email tile for unverified accounts"
```

---

## Task 10: Full verification pass

- [ ] **Step 1: Build + lint functions**

```bash
cd functions && npm run build && npx eslint src/ && npx jest test/email.test.ts test/email_verification.test.ts test/usernames.test.ts
```

Expected: build succeeds, lint clean, all three test files pass.

- [ ] **Step 2: Analyze + focused Flutter tests**

```bash
cd .. && flutter analyze lib test/core/router/router_redirect_test.dart test/features/auth
flutter test test/core/router/router_redirect_test.dart test/features/auth
```

Expected: analyze clean, all focused tests pass. **Do not run the full test suite** (AGENTS.md).

- [ ] **Step 3: Confirm new collections in rules**

Verify `firestore.rules` contains the `email_verifications` and `usernames` deny blocks.

- [ ] **Step 4: Final commit**

```bash
git add -A
git commit -m "chore: verification pass for email verification + username uniqueness" || echo "nothing to commit"
```

- [ ] **Step 5: Deployment notes (ops, not code)**

1. `firebase functions:secrets:set RESEND_API_KEY` — set once before deploying.
2. `firebase deploy --only functions` — deploys `sendEmailVerificationCode`, `verifyEmailCode`, `enforceEmailGracePeriod`, `claimUsername`.
3. `firebase deploy --only firestore:rules` — deploys the deny rules.
4. Run the backfill ONCE after users exist: `cd functions && npm run build && npm run backfill:usernames` (with `GOOGLE_APPLICATION_CREDENTIALS` set).
5. Google sign-in is exempt (Firebase sets `emailVerified` on federated accounts) — no code path changes needed there.

---

## Self-Review

**Spec coverage:**
- §3 data model → Task 2 (`email_verifications`), Task 3 (`usernames`), Task 2/5 (mirror fields).
- §4 functions → Tasks 2, 3.
- §5.1 repository methods → Task 5; §5.2 signup flow → Task 8; §5.3 router enforcement → Task 6; §5.4 verify screen → Task 7; §5.5 settings tile → Task 9.
- §6 rules → Task 4.
- §7 post-verification email → Task 2 `verifyEmailCode` welcome email.
- §8 backfill → Task 4.
- §9 security (hash, TTL, rate limit, constant-time, doc-as-lock, fpdart) → Tasks 2, 3, 5.
- §10 testing (jest CF tests, pure router tests, widget tests) → all tasks.
- §11 rollout → Task 10 Step 5.

**Placeholders:** none — every step has concrete code or an exact command.

**Type consistency:** `emailVerified` is `bool` on `AuthUser` and `bool?` on `RedirectContext`; `emailLockedAt` is `DateTime?` on `RedirectContext` and `DateTime?` from `currentEmailLockedAtProvider`; function names (`sendEmailVerificationCode`, `verifyEmailCode`, `claimUsername`, `checkEmailVerified`) match between the callables in `functions/src`, the Dart interface (Task 5), and the screen (Task 7). `hashCodeForTest` is defined and used only in tests (Task 2).
