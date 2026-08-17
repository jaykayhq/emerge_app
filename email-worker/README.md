# Emerge Email Worker

> **Active** (2026-08): ALL transactional emails — welcome, **verification**,
> **password reset**, re-engagement drip, verification grace lock — are sent
> HERE via GitHub Actions + SMTP with fully branded templates. Firebase
> Auth's built-in emails are never used (the app writes request markers the
> worker polls instead). No Cloud Functions, no webhook.

Cron email jobs for Emerge, run by **GitHub Actions** (free) instead of Cloud
Functions, sending via **SMTP** (nodemailer) instead of the Resend API.

Tasks:

| Task | What it does | Trigger / Idempotency marker |
|------|--------------|------------------------------|
| `welcome` | One branded welcome email per account, created in the last 7 days (lookback prevents a retroactive blast to pre-existing accounts) | `users/{uid}.welcomeEmailSentAt` |
| `verify` | Branded verification email with a link back to the app's `/verify-email` route (oobCode applied in-app — no Firebase hosted page). **Command-driven: at most ONE email per request.** Sends only when `verificationRequestedAt` is newer than the last send (`verificationEmailSentAt`) — a fresh request from signup or a "Resend" click. An already-answered request is never re-emailed, so the 5-minute cron can't spam. | App writes `users/{uid}.verificationRequestedAt`; worker marks `verificationEmailSentAt` (+ `emailVerificationSentAt` grace anchor on first send only) |
| `reset` | Branded password-reset email with a link back to the app's `/reset-password` route. Command-driven: one email per request doc (idempotent `sentAt` marker), with a 60s per-email cooldown to absorb duplicate submissions. | App writes `email_requests/{id}` `{type: 'password_reset', email, requestedAt}`; worker marks `sentAt` |
| `drip` | Re-engagement nudge: signed up ≥ 3 days ago, still active (lastActivity within 7 days), not dripped | `users/{uid}.reengagementEmailSentAt` |
| `grace` | Verification grace lock: unverified accounts 7 days after `emailVerificationSentAt` get `users/{uid}.emailLockedAt` (the app router then blocks non-auth surfaces); verified accounts get stale locks cleared. The check uses Firebase Auth's authoritative `emailVerified` flag | state on `users/{uid}.emailLockedAt` |

## Local run

```bash
cd email-worker
npm ci
FIREBASE_SERVICE_ACCOUNT=/path/to/service-account-key.json \
SMTP_HOST=... SMTP_PORT=587 SMTP_USER=... SMTP_PASS=... \
node src/index.js --task all          # or: --task welcome|verify|reset|drip|grace
```

(`FIREBASE_SERVICE_ACCOUNT_JSON` with the JSON inline also works — that's how
GitHub Actions passes it, avoiding shell mangling of the multi-line file.)

### Dry run (no emails sent, no documents written)

```bash
FIREBASE_SERVICE_ACCOUNT=... node src/index.js --task all --dry-run
```

### Send everything to one inbox (test mode)

```bash
EMAIL_OVERRIDE_TO=you@example.com node src/index.js --task all
```

## GitHub Actions

`.github/workflows/emails.yml` runs ALL tasks (welcome/verify/reset/drip/
grace) daily at 04:00 UTC as a safety net (`workflow_dispatch` available for
manual runs). `.github/workflows/emails-welcome.yml` runs welcome/verify/
reset every 5 minutes for near-real-time delivery (all tasks are idempotent
via their markers, so the overlapping runs never double-send).

Required repo secrets:

- `FIREBASE_SERVICE_ACCOUNT_TRADEFLASH_L2966` — service-account JSON (same
  one the hosting workflow uses)
- `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASS` — SMTP credentials
- Optional: `EMAIL_FROM`, `EMAIL_OVERRIDE_TO`

## Tests

```bash
npm test   # node --test — no extra test deps
```

### E2E: prove the verification + reset links actually work

`scripts/test_email_links.mjs` drives the exact Admin SDK calls the worker
uses (link generation with `handleCodeInApp: true` + the app URLs) against the
**Auth emulator**, then redeems the oobCodes the way the Flutter app does:

- verification oobCode → `emailVerified` flips to `true`
- reset oobCode → old password rejected, sign-in with the new password succeeds

```bash
firebase emulators:start --only auth &
FIREBASE_AUTH_EMULATOR_HOST=localhost:9099 \
  FIREBASE_SERVICE_ACCOUNT=../scripts/service-account-key.json \
  node scripts/test_email_links.mjs
```

The script refuses to run without `FIREBASE_AUTH_EMULATOR_HOST` — it must
never touch production.
