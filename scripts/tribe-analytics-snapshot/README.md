# Emerge Tribe Analytics Snapshot

> **Active** (2026-08): the creator dashboard's 30-day trend charts are
> guaranteed to have data even when no creator opens the app, because this
> job writes each tribe's daily doc to `tribe_analytics/{tribeId}/daily/{date}`
> on a GitHub Actions schedule — a server-side backstop to the client-side
> `TribeAnalyticsSnapshotService` (Flutter).

Daily snapshot job for Emerge, run by **GitHub Actions** (free) instead of
Cloud Functions, using the **Firebase Admin SDK** directly.

## What it does

- Scans `tribes/*` for creator-owned tribes (has a `createdBy` — official
  clubs are skipped).
- Aggregates each tribe's `tribes/{tribeId}/contributors/*` subcollection
  into today's snapshot: member count, total XP, habits completed,
  challenges completed, active members (last activity within 7 days),
  new members this week (joined within 7 days) — mirroring the Dart
  aggregation in `lib/features/social/data/services/creator_analytics_service.dart`.
- Writes `tribe_analytics/{tribeId}/daily/{date}`.

## Idempotency

Same doc id per tribe + date, and the job skips tribes whose latest snapshot
is under 24h old (same staleness gate as the client service). Re-runs and the
client-side writer never conflict or duplicate.

## Local run

```bash
cd scripts/tribe-analytics-snapshot
npm ci
FIREBASE_SERVICE_ACCOUNT=/path/to/service-account-key.json node index.js
```

(`FIREBASE_SERVICE_ACCOUNT_JSON` with the JSON inline also works — that's how
GitHub Actions passes it, avoiding shell mangling of the multi-line file.)

### Dry run (no documents written)

```bash
FIREBASE_SERVICE_ACCOUNT=... node index.js --dry-run
```

## Schedule

`.github/workflows/tribe-analytics-snapshot.yml` — daily 03:00 UTC, plus a
manual `workflow_dispatch` trigger. Runs the unit tests before writing.

## Tests

Pure logic lives in `snapshot.js` (no Firebase imports); the Firestore driver
is in `index.js`. Run tests with:

```bash
npm test
```
