# Resend Marketing Email (Welcome + Drip) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Send a branded welcome email when a user account is created and a single re-engagement drip to active-but-old users, via Resend's free tier.

**Architecture:** A shared `sendEmail` Resend helper + an `onDocumentCreated('users/{uid}')` trigger for the welcome email + a daily scheduled function for the drip. Both declare `secrets: ["RESEND_API_KEY"]`. Failures are logged, never thrown, so email can never break signup.

**Tech Stack:** Firebase Gen 2 Cloud Functions (TypeScript, jest + firebase-functions-test), axios, Resend REST API.

---

## File Structure

**New (functions):**
- `functions/src/email.ts` — `sendEmail()` Resend helper (restored; `EmailPayload` + optional `timeoutMs`).
- `functions/src/email_templates.ts` — `buildWelcomeHtml(name)`, `buildReengagementHtml(name)`.
- `functions/src/marketing_email.ts` — `sendWelcomeEmail` trigger + `enforceReengagementDrip` scheduled (+ testable `enforceReengagementDripInternal`).
- `functions/test/email.test.ts` — helper tests.
- `functions/test/marketing_email.test.ts` — trigger + drip tests.

**Modified (functions):** `functions/src/index.ts` (exports).

---

## Task 1: `email.ts` — Resend helper (restore)

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

  it("applies a custom timeout when provided", async () => {
    process.env.RESEND_API_KEY = "re_test_123";
    await sendEmail({ to: "a@b.com", subject: "Hi", html: "<p>Hi</p>", timeoutMs: 5000 });
    const [, , config] = axiosPost.mock.calls[0];
    expect(config.timeout).toBe(5000);
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
 * Shared transactional/marketing email helper (Resend). Used by the welcome
 * trigger and the re-engagement drip (marketing_email.ts). RESEND_API_KEY is a
 * function secret — never client-visible.
 */
import axios from "axios";

export interface EmailPayload {
  to: string;
  subject: string;
  html: string;
  timeoutMs?: number;
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
    {
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      timeout: payload.timeoutMs ?? 10_000,
    }
  );
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd functions && npm run build && npx jest test/email.test.ts`
Expected: PASS — 4 passing

- [ ] **Step 5: Commit**

```bash
cd functions && npm run build && npx eslint src/email.ts && npx jest test/email.test.ts
cd .. && git add functions/src/email.ts functions/test/email.test.ts
git commit -m "feat(functions): restore Resend email helper for marketing flows"
```

---

## Task 2: `email_templates.ts` — HTML builders

**Files:**
- Create: `functions/src/email_templates.ts`
- Test: `functions/test/email_templates.test.ts` (light: builders return strings containing the name)

- [ ] **Step 1: Write the failing test**

`functions/test/email_templates.test.ts`:

```ts
import { buildWelcomeHtml, buildReengagementHtml } from "../src/email_templates";

describe("email templates", () => {
  it("welcome html includes the display name and CTA", () => {
    const html = buildWelcomeHtml("Aria");
    expect(html).toContain("Aria");
    expect(html).toContain("Start exploring");
    expect(html).toContain("Your journey begins now");
  });

  it("reengagement html includes the name and a nudge", () => {
    const html = buildReengagementHtml("Aria");
    expect(html).toContain("Aria");
    expect(html).toContain("coming back");
  });

  it("handles a missing name gracefully", () => {
    expect(buildWelcomeHtml(undefined)).toContain("Welcome");
    expect(buildWelcomeHtml("")).not.toContain("undefined");
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd functions && npx jest test/email_templates.test.ts`
Expected: FAIL — module not found

- [ ] **Step 3: Write minimal implementation**

`functions/src/email_templates.ts`:

```ts
/**
 * Inline-styled, mobile-friendly HTML for the marketing emails. No template
 * engine — the strings are small and versioned in code.
 */

const baseStyles =
  "font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;" +
  "background:#0A0A1A;color:#F5F0E8;padding:32px 16px;text-align:center";

const buttonStyles =
  "display:inline-block;margin-top:20px;padding:14px 28px;border-radius:12px;" +
  "background:#2DD4BF;color:#0A0A1A;font-weight:bold;text-decoration:none";

function safeName(name: string | undefined): string {
  const trimmed = (name ?? "").trim();
  return trimmed.length > 0 ? trimmed : "friend";
}

export function buildWelcomeHtml(name?: string): string {
  const displayName = safeName(name);
  return `
    <div style="${baseStyles}">
      <h1 style="color:#2DD4BF;">Welcome to Emerge, ${displayName}.</h1>
      <p style="font-size:16px;line-height:1.6;">
        Your journey begins now. Build one small habit, earn XP, and watch
        your avatar evolve into the person you're becoming.
      </p>
      <a href="https://emerge.app/timeline" style="${buttonStyles}">
        Start exploring
      </a>
      <p style="font-size:12px;color:#8B8B8B;margin-top:28px;">
        Your journey begins now — one habit at a time.
      </p>
    </div>`;
}

export function buildReengagementHtml(name?: string): string {
  const displayName = safeName(name);
  return `
    <div style="${baseStyles}">
      <h1 style="color:#2DD4BF;">We miss you, ${displayName}.</h1>
      <p style="font-size:16px;line-height:1.6;">
        Your identity is built in small moments. Even one habit today keeps
        the streak alive — and your avatar keeps evolving.
      </p>
      <a href="https://emerge.app/timeline" style="${buttonStyles}">
        Coming back
      </a>
      <p style="font-size:12px;color:#8B8B8B;margin-top:28px;">
        A small step is still a step forward.
      </p>
    </div>`;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd functions && npx jest test/email_templates.test.ts`
Expected: PASS — 3 passing

- [ ] **Step 5: Commit**

```bash
cd functions && npx eslint src/email_templates.ts && npx jest test/email_templates.test.ts
cd .. && git add functions/src/email_templates.ts functions/test/email_templates.test.ts
git commit -m "feat(functions): marketing email HTML templates"
```

---

## Task 3: `marketing_email.ts` — welcome trigger

**Files:**
- Create: `functions/src/marketing_email.ts`
- Modify: `functions/src/index.ts` (export)
- Test: `functions/test/marketing_email.test.ts`

- [ ] **Step 1: Write the failing test**

`functions/test/marketing_email.test.ts` (offline admin mock; `onDocumentCreated` uses `event.data`):

```ts
const axiosPost = jest.fn().mockResolvedValue({ status: 200 });
jest.mock("axios", () => ({ post: (...args: unknown[]) => axiosPost(...args) }));

const dbCollection = jest.fn(() => ({
  where: jest.fn(() => ({
    limit: jest.fn(() => ({ get: jest.fn() })),
    get: jest.fn(),
  })),
}));
const firestoreMock = jest.fn(() => ({ collection: dbCollection, batch: jest.fn() }));

jest.mock("firebase-admin", () => ({
  apps: [],
  initializeApp: jest.fn(),
  firestore: firestoreMock,
}));

// eslint-disable-next-line @typescript-eslint/no-require-imports
const ft = require("firebase-functions-test")();

// eslint-disable-next-line @typescript-eslint/no-require-imports
const { sendWelcomeEmail } = require("../src/marketing_email");

beforeEach(() => {
  jest.clearAllMocks();
  process.env.RESEND_API_KEY = "re_test_123";
});

describe("sendWelcomeEmail", () => {
  it("sends a welcome email for a valid new user", async () => {
    const wrapped = ft.wrap(sendWelcomeEmail);
    await wrapped(
      {
        params: { uid: "u1" },
        data: ft.firestore.makeDocumentSnapshot(
          { email: "a@b.com", displayName: "Aria" },
          "users/u1"
        ),
      }
    );
    expect(axiosPost).toHaveBeenCalledTimes(1);
    const [, body] = axiosPost.mock.calls[0];
    expect(body.to).toBe("a@b.com");
    expect(body.subject).toContain("Welcome to Emerge");
  });

  it("skips users without a valid email", async () => {
    const wrapped = ft.wrap(sendWelcomeEmail);
    await wrapped(
      {
        params: { uid: "u2" },
        data: ft.firestore.makeDocumentSnapshot(
          { email: "", displayName: "NoEmail" },
          "users/u2"
        ),
      }
    );
    expect(axiosPost).not.toHaveBeenCalled();
  });

  it("skips system/seed creator docs", async () => {
    const wrapped = ft.wrap(sendWelcomeEmail);
    await wrapped(
      {
        params: { uid: "system" },
        data: ft.firestore.makeDocumentSnapshot(
          { email: "system@emerge.app", creatorUserId: "system" },
          "users/system"
        ),
      }
    );
    expect(axiosPost).not.toHaveBeenCalled();
  });

  it("swallows send failures without throwing", async () => {
    axiosPost.mockRejectedValueOnce(new Error("500 down"));
    const wrapped = ft.wrap(sendWelcomeEmail);
    await expect(
      wrapped({
        params: { uid: "u3" },
        data: ft.firestore.makeDocumentSnapshot(
          { email: "c@d.com", displayName: "C" },
          "users/u3"
        ),
      })
    ).resolves.toBeUndefined();
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd functions && npx jest test/marketing_email.test.ts`
Expected: FAIL — module not found

- [ ] **Step 3: Write minimal implementation**

`functions/src/marketing_email.ts`:

```ts
/**
 * Marketing email flow (SP sub-project 3).
 *
 * sendWelcomeEmail: onDocumentCreated trigger on users/{uid} — one branded
 * welcome email per account. Fire-and-forget: failures are logged, never
 * thrown, so email can never break account creation.
 *
 * enforceReengagementDrip: daily scheduled job that nudges users who signed
 * up >= 3 days ago, are still active (lastActivity within 7d), and haven't
 * been dripped yet. Idempotent via users/{uid}.reengagementEmailSentAt.
 */
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { onSchedule } from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";
import { sendEmail } from "./email";
import { buildWelcomeHtml, buildReengagementHtml } from "./email_templates";

if (admin.apps.length === 0) {
  admin.initializeApp();
}

const db = admin.firestore();

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export const sendWelcomeEmail = onDocumentCreated(
  { secrets: ["RESEND_API_KEY"] },
  async (event) => {
    const data = event.data?.data() ?? {};
    const uid = event.params.uid;
    const email = typeof data.email === "string" ? data.email : "";

    // Skip seed/system docs and anything that isn't a real consumer account.
    if (data.creatorUserId === "system" || data.isAdmin === true) {
      return;
    }
    if (!email || !EMAIL_RE.test(email)) {
      console.warn(`[welcome] skipping ${uid}: no valid email`);
      return;
    }

    try {
      await sendEmail({
        to: email,
        subject: "Welcome to Emerge — your journey starts now",
        html: buildWelcomeHtml(
          typeof data.displayName === "string" ? data.displayName : undefined
        ),
      });
    } catch (err) {
      console.error(`[welcome] failed for ${uid}:`, err);
    }
  }
);

// Drip parameters.
const DRIP_SINCE_MS = 3 * 24 * 60 * 60 * 1000; // signed up >= 3 days ago
const DRIP_ACTIVE_WINDOW_MS = 7 * 24 * 60 * 60 * 1000; // active within last 7d
const DRIP_PAGE_SIZE = 400;
const DRIP_MAX_PAGES = 100;

function toMillis(value: unknown): number {
  if (value instanceof Date) return value.getTime();
  const ts = value as { toMillis?: () => number } | undefined;
  return ts?.toMillis?.() ?? 0;
}

/** Testable body; wrapped by onSchedule. */
export async function enforceReengagementDripInternal(
  database: typeof db,
  nowMs: number
): Promise<void> {
  const since = new Date(nowMs - DRIP_SINCE_MS);
  let lastDoc: admin.firestore.QueryDocumentSnapshot | undefined;
  for (let page = 0; page < DRIP_MAX_PAGES; page++) {
    let query = database
      .collection("users")
      .where("createdAt", "<=", since)
      .limit(DRIP_PAGE_SIZE);
    if (lastDoc) {
      query = query.startAfter(lastDoc);
    }
    const snap = await query.get();
    if (snap.empty) {
      break;
    }
    const batch = database.batch();
    let changed = 0;
    for (const doc of snap.docs) {
      const data = doc.data();
      if (data.reengagementEmailSentAt != null) {
        continue; // already dripped
      }
      const email = typeof data.email === "string" ? data.email : "";
      if (!email || !EMAIL_RE.test(email)) {
        continue;
      }
      const lastActive = toMillis(data.lastActivity);
      if (lastActive === 0 || nowMs - lastActive > DRIP_ACTIVE_WINDOW_MS) {
        continue; // never active, or churned out of the window
      }
      try {
        await sendEmail({
          to: email,
          subject: "We miss you — your identity is still building",
          html: buildReengagementHtml(
            typeof data.displayName === "string" ? data.displayName : undefined
          ),
        });
        batch.set(
          database.collection("users").doc(doc.id),
          { reengagementEmailSentAt: admin.firestore.FieldValue.serverTimestamp() },
          { merge: true }
        );
        changed++;
      } catch (err) {
        console.error(`[drip] failed for ${doc.id}:`, err);
      }
    }
    if (changed > 0) {
      await batch.commit();
    }
    console.log(`[drip] page ${page + 1}: ${changed} emails sent`);
    lastDoc = snap.docs[snap.docs.length - 1];
    if (snap.docs.length < DRIP_PAGE_SIZE) {
      break;
    }
  }
}

export const enforceReengagementDrip = onSchedule(
  { schedule: "0 6 * * *", secrets: ["RESEND_API_KEY"] },
  async () => {
    console.log("Running re-engagement drip");
    await enforceReengagementDripInternal(db, Date.now());
  }
);
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd functions && npm run build && npx jest test/marketing_email.test.ts`
Expected: PASS (4 trigger tests). The drip tests are added in Task 4.

- [ ] **Step 5: Export from index.ts**

Add to `functions/src/index.ts`:

```ts
export { sendWelcomeEmail, enforceReengagementDrip } from "./marketing_email";
```

- [ ] **Step 6: Build, lint, commit**

```bash
cd functions && npm run build && npx eslint src/marketing_email.ts src/email.ts src/email_templates.ts && npx jest test/marketing_email.test.ts
cd .. && git add functions/src/marketing_email.ts functions/test/marketing_email.test.ts functions/src/index.ts
git commit -m "feat(functions): welcome email trigger via Resend"
```

---

## Task 4: Drip tests + full marketing suite pass

**Files:**
- Modify: `functions/test/marketing_email.test.ts`

- [ ] **Step 1: Write the failing drip tests**

Append to `functions/test/marketing_email.test.ts` a drip section. The mock needs a richer `dbCollection`/query chain and batch. Add:

```ts
const queryGet = jest.fn();
const startAfter = jest.fn();
const batchSet = jest.fn();
const batchCommit = jest.fn().mockResolvedValue(undefined);
const batch = jest.fn(() => ({ set: batchSet, commit: batchCommit }));

// eslint-disable-next-line @typescript-eslint/no-require-imports
const { enforceReengagementDripInternal } = require("../src/marketing_email");

const makeQuery = () => ({ get: queryGet, limit: jest.fn(() => makeQuery()), startAfter: jest.fn(() => makeQuery()) });
dbCollection.mockImplementation(() => ({ where: jest.fn(() => makeQuery()) }));
firestoreMock.mockImplementation(() => ({ collection: dbCollection, batch }));
(firestoreMock as unknown as { FieldValue: { serverTimestamp: () => string } }).FieldValue = {
  serverTimestamp: () => "SERVER_TIMESTAMP",
};

const makeDoc = (id: string, data: Record<string, unknown>) => ({ id, data: () => data });

beforeEach(() => {
  queryGet.mockReset();
  batchSet.mockClear();
  batchCommit.mockClear();
});

describe("enforceReengagementDripInternal", () => {
  const database = firestoreMock() as never;
  const nowMs = Date.now();

  it("sends and marks users past the drip age who are active and not yet dripped", async () => {
    queryGet.mockResolvedValue({
      size: 1, empty: false,
      docs: [makeDoc("u1", {
        email: "a@b.com", displayName: "Aria",
        createdAt: new Date(nowMs - 4 * 86400_000),
        lastActivity: new Date(nowMs - 2 * 86400_000),
      })],
    });
    await enforceReengagementDripInternal(database, nowMs);
    expect(axiosPost).toHaveBeenCalledTimes(1);
    expect(batchSet).toHaveBeenCalledWith(
      expect.objectContaining({ id: "u1" }),
      { reengagementEmailSentAt: "SERVER_TIMESTAMP" },
      { merge: true }
    );
    expect(batchCommit).toHaveBeenCalled();
  });

  it("skips users already dripped", async () => {
    queryGet.mockResolvedValue({
      size: 1, empty: false,
      docs: [makeDoc("u1", {
        email: "a@b.com",
        reengagementEmailSentAt: "SERVER_TIMESTAMP",
        lastActivity: new Date(nowMs - 2 * 86400_000),
      })],
    });
    await enforceReengagementDripInternal(database, nowMs);
    expect(axiosPost).not.toHaveBeenCalled();
  });

  it("skips users who churned (last activity older than 7 days)", async () => {
    queryGet.mockResolvedValue({
      size: 1, empty: false,
      docs: [makeDoc("u1", {
        email: "a@b.com",
        createdAt: new Date(nowMs - 10 * 86400_000),
        lastActivity: new Date(nowMs - 8 * 86400_000),
      })],
    });
    await enforceReengagementDripInternal(database, nowMs);
    expect(axiosPost).not.toHaveBeenCalled();
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd functions && npx jest test/marketing_email.test.ts`
Expected: initially fails if the mock chain mismatches — adjust the mock (`makeQuery` chaining) to match the implementation, then it should pass. The three drip cases must pass (send+mark, skip-dripped, skip-churned).

- [ ] **Step 3: Verify full suite + lint + build**

```bash
cd functions && npm run build && npx eslint src/marketing_email.ts && npx jest test/marketing_email.test.ts test/email.test.ts test/email_templates.test.ts
```
Expected: all pass.

- [ ] **Step 4: Commit**

```bash
cd .. && git add functions/test/marketing_email.test.ts
git commit -m "test(functions): re-engagement drip coverage"
```

---

## Self-Review (marketing plan)

**Spec coverage:** §4 helper → Task 1; §5.3 templates → Task 2; §5.1 welcome trigger → Task 3; §5.2 drip → Task 3+4; §6 secrets → `secrets: ["RESEND_API_KEY"]` on both functions; §8 tests → Tasks 1–4; §9 rollout → Task 5.

**Placeholders:** none.

**Type consistency:** `sendEmail(payload: EmailPayload)` with optional `timeoutMs`; `buildWelcomeHtml(name?)` / `buildReengagementHtml(name?)`; `enforceReengagementDripInternal(database, nowMs)`; field `reengagementEmailSentAt` used in both write and read.

---

## Task 5: Verification + deployment notes

- [ ] **Step 1: Build + lint + focused tests**

```bash
cd functions && npm run build && npx eslint src/ && npx jest test/email.test.ts test/email_templates.test.ts test/marketing_email.test.ts
```
Expected: build clean, lint clean (src/), all tests pass.

- [ ] **Step 2: Ops (not code)**

1. `firebase functions:secrets:set RESEND_API_KEY` — enter the free-tier Resend key.
2. Verify the sending domain for `no-reply@emerge.app` in the Resend dashboard (DNS records).
3. Deploy: `firebase deploy --only functions:sendWelcomeEmail,functions:enforceReengagementDrip`.
4. Verify: fresh signup → welcome email; seeded 3-day-old active test user → drip email.

- [ ] **Step 3: Final commit**

```bash
git add -A && git commit -m "chore: marketing email verification pass" || echo "nothing to commit"
```
