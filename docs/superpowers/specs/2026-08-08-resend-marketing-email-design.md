# Resend Marketing Email (Welcome + Drip) — Design

**Date:** 2026-08-08
**App:** Emerge — Identity-First Habit Formation
**Sub-project:** #3 (of the post-verification sequence: #1 verification ✓ → this #3 → #4 rating popup → #2 web payments)

---

## 1. Problem Statement

All custom email infrastructure was removed in the verification rework (Resend dropped in favor of
Firebase's native verification link). The app now sends **no** proactive marketing email. For a
habit-formation product, a welcome email and a light re-engagement drip are high-leverage (activation
+ early retention). The developer approved **Resend free tier** (3,000 emails/month, 100/day) via the
existing `axios` dependency — the same provider originally used for verification.

---

## 2. Goals & Non-Goals

**Goals**
- **Welcome email** on account creation: branded "Welcome to Emerge", first-habit guidance, call-to-action.
- **One re-engagement drip:** users who signed up ≥3 days ago and are active-but-low-engagement get a
  single nudge email.
- Server-authoritative, fire-and-forget (email failures never break signup or app flows).
- Reuses a single shared `sendEmail` helper (Resend REST) so the provider seam is one file.
- `RESEND_API_KEY` in function secrets; never in client code.

**Non-Goals**
- No full marketing automation platform (no segments/audiences/campaign editor).
- No unsubscribe preference center (out of scope; Resend has an opt-out link per-email if we add one,
  but list management is deferred).
- No multiple drip steps (one drip only — more is scope creep).
- No client-side email composition or sending (functions only).
- No changes to Firebase's native verification email.

---

## 3. Architecture

```
onDocumentCreated('users/{uid}')  [trigger]
  └─> sendWelcomeEmail: builds HTML from user.displayName → sendEmail via Resend (axios)
        └─> failures logged; never throws (trigger survives)

enforceReengagementDrip  [onSchedule, daily]
  └─> query users where createdAt <= now-3d AND lastActiveAt >= now-7d  (active-but-old)
        └─> exclude users already sent the drip (users/{uid}.reengagementEmailSentAt exists)
              └─> send nudge email → mark reengagementEmailSentAt (idempotent)
```

The trigger runs on `users/{uid}` creation (fires exactly once per account). The drip marks its own
`reengagementEmailSentAt` field for idempotency, so a rerun never double-sends.

---

## 4. Shared helper — `functions/src/email.ts`

Re-add the Resend helper (restored from the verification-era design; the Cloud Function code was deleted,
the pattern is proven):

```ts
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
    {
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      timeout: 10_000,
    }
  );
}
```

Note: `no-reply@emerge.app` must be a verified sender in the Resend dashboard before production sends
(ops step, listed in §9).

---

## 5. Cloud Functions — `functions/src/marketing_email.ts`

### 5.1 `onDocumentCreated('users/{uid}')` — welcome email

```ts
export const sendWelcomeEmail = onDocumentCreated("users/{uid}", async (event) => {
  const data = event.data?.data() ?? {};
  const email = data.email as string | undefined;
  const name = (data.displayName as string)?.trim();
  if (!email || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    console.warn(`[welcome] skipping uid ${event.params.uid}: no valid email`);
    return;
  }
  try {
    await sendEmail({
      to: email,
      subject: "Welcome to Emerge — your journey starts now",
      html: buildWelcomeHtml(name),
    });
  } catch (err) {
    // Fire-and-forget: a marketing email must never break account creation.
    console.error(`[welcome] failed for ${event.params.uid}:`, err);
  }
});
```

- **Guard:** the trigger sends only for docs that look like real users. Email regex-gated. Google
  sign-ins also create `users/{uid}` docs with an email → they get the welcome too (desired).
- **Do NOT send** if `data.emailVerificationSentAt` is absent AND role is a creator bootstrap (seed
  docs) — the seed creator (`seedCreatorAccount`) and any `system`-owned docs must be excluded. Add a
  cheap filter: skip when `data.creatorUserId == 'system'` or `data.role == 'creator' && data.isAdmin`.
  (The seed creator uses ADMIN_SECRET; its doc should not trigger consumer email.)

### 5.2 `enforceReengagementDrip` — daily scheduled

```ts
export const enforceReengagementDrip = onSchedule("0 6 * * *", async () => {
  await enforceReengagementDripInternal(db, Date.now());
});
```

Testable body `enforceReengagementDripInternal(database, nowMs)`:
1. `cutoff = now - 3d`; query `users` where `createdAt <= cutoff` (paginated, like the grace-lock job —
   400/page, bounded loop).
2. For each doc: skip if `reengagementEmailSentAt` exists (already dripped), skip if no valid email,
   skip if `lastActiveAt == null` (never active — welcome covers them), skip if `lastActiveAt < now - 7d`
   (churned; separate future flow). Remaining = active-but-low-engagement.
3. Send the nudge email; on success, merge `users/{uid}` `{ reengagementEmailSentAt: serverTimestamp }`.
4. Idempotent by field; batch the marker writes.

`lastActiveAt` is an existing field on `users/{uid}` (written by the app's activity sync). Verify its
name/type during implementation and adapt if it's stored elsewhere.

### 5.3 Templates — `functions/src/email_templates.ts`

Two small HTML builders (`buildWelcomeHtml(name)`, `buildReengagementHtml(name)`), inline-styled,
mobile-friendly, plain-text fallback included. No external template engine.

---

## 6. Secrets & Security

- `RESEND_API_KEY` set via `firebase functions:secrets:set RESEND_API_KEY` (ops step; never committed).
- Both functions declare `secrets: ["RESEND_API_KEY"]` (v2 secret binding) so `process.env.RESEND_API_KEY`
  is available at runtime.
- Email addresses come from the user's own doc (server-side). Never logged in full; the trigger logs only
  `uid` on failure.
- Resend free-tier limits (100/day) are an ops concern — the drip is a single daily batch, well under it.

---

## 7. Firestore Rules

No new collections. The drip's `reengagementEmailSentAt` marker is a client-readable/server-written
field on `users/{uid}` — add it to the server-owned carve-out? **No**: the client does not need to write
it (functions write it via Admin SDK, which bypasses rules). No rules change required. Confirm the
`users` update rule still forbids `emailVerified`/`emailLockedAt` (already done) and doesn't need
`reengagementEmailSentAt` (it does not — clients never write it).

---

## 8. Testing (TDD Iron Law)

### Cloud Functions (jest, `functions/test/marketing_email.test.ts`)
- `sendWelcomeEmail` trigger: sends when email valid + name present; skips when email missing/invalid;
  skips system/seed docs; swallows send failures (no throw); passes correct `to`/`subject`.
- `enforceReengagementDripInternal`: sends only to users past 3d, active within 7d, not yet dripped;
  marks `reengagementEmailSentAt` on success; skips already-dripped; pages correctly; batch commits.
- `email.ts` helper: missing key throws; POST shape + Bearer auth; error propagation (reuse the old
  `email.test.ts` shape — it was deleted, restore it).

### Verification commands (focused only)
- `cd functions && npm run build && npx eslint src/email.ts src/marketing_email.ts src/email_templates.ts`
- `cd functions && npx jest test/email.test.ts test/marketing_email.test.ts`

---

## 9. Rollout & Operations

1. `firebase functions:secrets:set RESEND_API_KEY` — enter the Resend API key (free tier key).
2. Verify the Resend **sender domain**: add `no-reply@emerge.app` and verify the sending domain in the
   Resend dashboard (DNS records).
3. Deploy functions (`firebase deploy --only functions:sendWelcomeEmail,functions:enforceReengagementDrip`).
4. Verify: sign up a fresh account → welcome email arrives; a seeded 3-day-old test user → drip email.
5. Confirm the free-tier dashboard shows the sends and no bounce complaints.

---

## 10. Open Items / Assumptions

- **Sender domain** must be verified in Resend before production (DNS). Assumed the domain owner can do it.
- `lastActiveAt` field name/type verified during implementation (fallback: `users/{uid}.lastActivity`
  or `user_stats`). If absent for most users, the drip silently sends nothing (safe default).
- Free-tier cap is 100 emails/day; the daily drip is one batch and the welcome trigger is volume-bounded
  by new signups. If signups ever exceed ~100/day, throttling/queueing is a separate follow-up.
- A future unsubscribe flow is deferred; Resend's built-in opt-out link can be added to the templates
  without architecture change.
