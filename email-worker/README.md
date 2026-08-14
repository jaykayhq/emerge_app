# Emerge Email Worker

Cron email jobs for Emerge, run by **GitHub Actions** (free) instead of Cloud
Functions, sending via **SMTP** (nodemailer) instead of the Resend API.

Tasks (ported faithfully from the old Cloud Functions):

| Task | What it does | Idempotency marker |
|------|--------------|--------------------|
| `welcome` | One branded welcome email per account, created in the last 7 days (lookback prevents a retroactive blast to pre-existing accounts; the old Firestore trigger never backfilled) | `users/{uid}.welcomeEmailSentAt` |
| `drip` | Re-engagement nudge: signed up ≥ 3 days ago, still active (lastActivity within 7 days), not dripped | `users/{uid}.reengagementEmailSentAt` |
| `grace` | Verification grace lock: unverified accounts 7 days after `emailVerificationSentAt` get `users/{uid}.emailLockedAt` (the app router then blocks non-auth surfaces); verified accounts get stale locks cleared. The check uses Firebase Auth's authoritative `emailVerified` flag | state on `users/{uid}.emailLockedAt` |

## Local run

```bash
cd email-worker
npm ci
FIREBASE_SERVICE_ACCOUNT=/path/to/service-account-key.json \
SMTP_HOST=... SMTP_PORT=587 SMTP_USER=... SMTP_PASS=... \
node src/index.js --task all          # or: --task welcome|drip|grace
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

`.github/workflows/emails.yml` runs all tasks daily at 04:00 UTC
(`workflow_dispatch` available for manual runs).
`.github/workflows/emails-welcome.yml` runs the welcome task every 5 minutes
for near-real-time delivery (the repo is public → unlimited free Actions
minutes). Welcome delivery is therefore ≤5 minutes after signup; drip and
grace remain daily.

Required repo secrets:

- `FIREBASE_SERVICE_ACCOUNT_TRADEFLASH_L2966` — service-account JSON (same
  one the hosting workflow uses)
- `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASS` — SMTP credentials
- Optional: `EMAIL_FROM`, `EMAIL_OVERRIDE_TO`

## Tests

```bash
npm test   # node --test — no extra test deps
```
