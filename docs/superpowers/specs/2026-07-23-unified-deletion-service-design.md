# Unified Deletion Service + Hardened Sync Engine

- **Date:** 2026-07-23
- **Status:** Approved (design)
- **Feature:** Deletion architecture hardening for `deleteHabit` and `deleteAccount`
- **Approach:** A — Unified `DeletionService` + hardened `EnhancedSyncEngine`

## 0. Context & premise

The brief ("Optimize delete habit and delete user operations… align with the
existing purge function's patterns — batch processing, async job queues, audit
logging") assumes a backend-with-endpoints architecture: server transactions,
foreign-key constraints, circuit breakers, an auditable `purge` function.

**Reality of this repo:** `emerge_app` is a Flutter + Firebase (Firestore)
**client**. Deletion is client-side:

- `deleteHabit` lives in `lib/core/drift_repositories/drift_habit_repository.dart:121`
  as a soft delete (`isArchived=1`).
- `deleteAccount` lives in `lib/features/settings/presentation/screens/settings_screen.dart:1242`
  and `lib/features/auth/data/repositories/firebase_auth_repository.dart:347`. It
  wipes the **local** SQLite DB (`db.clearAll()`) *before* calling the server-side
  `deleteMyAccount` Cloud Function.
- The "job queue" is `EnhancedSyncEngine` (`lib/core/sync/sync_engine.dart`): a
  Drift-backed mutation queue with a naive 3-retry-then-drop loop.

The server-side `deleteMyAccount` ("purge") is **not in this repo** — only client
comments reference `functions/src/...`. Per the agreed scope, backend changes are
captured as a **documented contract** (Appendix A), not implemented here.

**Agreed scope:** Client-side hardening in this repo + a documented server-purge
contract. No Cloud Functions repo will be created here.

## 1. Goals

1. Fix the `deleteHabit` local-row **corruption bug** (see §2.1).
2. Add a single, testable `DeletionService` that both delete paths consume.
3. Add cascade deletion (habit → habit_completions) for local integrity.
4. Make the sync engine resilient: idempotency, exponential backoff, dead-letter
   (no silent drop), and a circuit breaker.
5. Add observability: structured audit log, metrics, and a `SyncStatus` stream.
6. Close the `deleteAccount` data-loss gap (do not nuke local before remote success).
7. Write TDD integration tests: concurrent deletes, partial failures, rollbacks.

## 2. Current problems (root cause)

### 2.1 `deleteHabit` corrupts the local row
`drift_habit_repository.dart:122-146` calls
`habitsDao.insertFromData(id, userId, title, isArchived:1, createdAt, updatedAt)`
with **only those fields**. `HabitsDao.insertFromData` (`habits_dao.dart:33`) uses
`insertOnConflictUpdate`, so on conflict it overwrites the existing row with the
DEFAULTS for every field it was *not* given: `cue=''`, `routine=''`,
`frequency='daily'`, `difficulty='medium'`, `currentStreak=0`, `longestStreak=0`,
`momentumScore=0`, etc. The Firestore sync only sends `{'isArchived': true}`, so
the **cloud copy survives but the local row is silently destroyed**.

No local transaction wraps the archive. No cascade to `habit_completions`.

### 2.2 `deleteAccount` wipes local before remote confirmation
`settings_screen.dart:1238-1251`: `await db.clearAll()` runs **first**, then the
`deleteMyAccount` callable is invoked with a 15s timeout. If the callable throws
or times out, the code navigates to `/auth` and shows "Local data cleared.
Error…" — the user's **local data is gone but the remote account persists**. This
is a data-loss / inconsistency gap.

### 2.3 `EnhancedSyncEngine` drops mutations silently
`sync_engine.dart:34-40`: on failure it `incrementRetry`, and after `retryCount >= 3`
it `deleteProcessed` (drops) the mutation — no backoff, no structured log, no
dead-letter, no circuit breaker. Root cause of the "intermittent failures" report.

## 3. Architecture

```
UI (habit_options_sheet / settings_screen)
        │
        ▼
   DeletionService            ← single owner of deletion logic
        ├── local:  AppDatabase (Drift transaction: archive + cascade)
        ├── remote: EnhancedSyncEngine.enqueue(...)
        └── audit:  DeletionAudit (structured log + metric)
                        │
                        ▼
              EnhancedSyncEngine (mutation queue v10)
                • idempotency key (dedupe)
                • exponential backoff (nextRetryAt)
                • dead-letter (no silent drop)
                • circuit breaker (degraded state)
                • SyncStatus stream (observability)
                        │
                        ▼
                  Firestore (delete doc/subcollection)
```

New module: `lib/core/deletion/`. Upgraded module: `lib/core/sync/`.

## 4. Components

### 4.1 `DeletionService` — `lib/core/deletion/deletion_service.dart`
Plain class (no Flutter/UI deps), constructed with:
- `AppDatabase db`
- `EnhancedSyncEngine syncEngine`
- `FirebaseAuth auth`
- `FirebaseFunctions functions`
- `DeletionAudit audit`

Methods:
- `Future<Either<Failure, Unit>> deleteHabit({required String userId, required String habitId})`
- `Future<Either<Failure, Unit>> deleteAccount({required String userId})`

Pure decision logic is extractable for unit tests (mirrors the project's
"testable design" signature pattern — see AGENTS.md).

### 4.2 `DeletionAudit` — `lib/core/deletion/deletion_audit.dart`
Wraps `AppLogger` + a `SyncMetrics` sink. Emits one structured event per deletion
with keys: `{op, target, habitId|uid, outcome, durationMs, attempt}`. Uses
`AppLogger.security` (Crashlytics in prod) for account-level events. PII redaction
is inherited from `AppLogger`.

### 4.3 `EnhancedSyncEngine` (upgrade) — `lib/core/sync/sync_engine.dart`
Retains the Drift mutation queue, adds:
- `idempotencyKey` dedupe at enqueue time.
- Exponential backoff computed from `nextRetryAt`.
- Dead-letter on exhaustion (keep row, `status='dead'`).
- In-memory circuit breaker → `SyncStatus.degraded`.
- `Stream<SyncStatus> get status` and queue-depth metric.

### 4.4 DAO additions
- `HabitsDao.archiveHabit(String id)` — targeted
  `update(habitsTable)..where(id.equals(id))).write(HabitsTableCompanion(isArchived: const Value(1), updatedAt: ...))`.
  Replaces the corrupting `insertFromData` call.
- `HabitCompletionsDao.deleteByHabitId(String habitId)` — cascade delete local
  completions for a habit.

### 4.5 Schema migration v10 — `lib/core/drift/app_database.dart`
Add columns to `MutationQueueTable` (`lib/core/drift/tables/mutation_queue_table.dart`):
- `idempotencyKey` → `text().nullable()()` with a unique index (null allowed for legacy rows).
- `lastError` → `text().nullable()()`.
- `nextRetryAt` → `text().nullable()()` (ISO-8601).
- `status` → `text().withDefault(const Constant('pending'))()`.

Migration `onUpgrade`: `if (from < 10) { await m.addColumn(...idempotencyKey...); ... }`.
Bump `schemaVersion => 10`.

## 5. Data flow — `deleteHabit` (soft delete, single habit)

1. Service opens a Drift `transaction`:
   - `archiveHabit(habitId)` (only `isArchived`/`updatedAt` touched).
   - `HabitCompletionsDao.deleteByHabitId(habitId)` (local cascade).
   - Rolls back on any throw (local integrity preserved).
2. Enqueue Firestore `update('habits/$habitId', {isArchived: true})` with
   `idempotencyKey = 'del:habit:$habitId'`.
3. **Idempotent**: deleting an already-archived habit is a no-op success; enqueue
   dedupes on the key.
4. `DeletionAudit` logs `{op:'deleteHabit', habitId, outcome, durationMs, attempt}`.

Resolution of §2.1: `archiveHabit` uses a targeted `write()` so streak/cue/
frequency are **not** overwritten.

## 6. Data flow — `deleteAccount` (hard delete, full account)

1. Generate + persist a `deletionRequestId` (local secure prefs) **before** calling server.
2. Call server `deleteMyAccount({deletionRequestId})`.
3. Only on confirmed success (`{success:true}`), the service performs its
   local cleanup and returns `Right(unit)`:
   - `await db.clearAll()`
   - `await auth.signOut()`
   - clear local prefs + mutation queue
   The service is **UI-free**: navigation to `/auth` is the **caller's**
   (`settings_screen`) responsibility, triggered on `Right`.
4. On failure / timeout: the service returns `Left(Failure)`, **does NOT** wipe
   local, and preserves `deletionRequestId` (caller offers a retry that is
   idempotent on the server side).

This closes the §2.2 data-loss gap.

## 7. Error handling & resilience (sync engine)

- **Exponential backoff**: `nextRetryAt = now + min(cap, base * 2^retryCount)`
  (base 1s, cap 5min). The processing loop skips entries whose `nextRetryAt` is in
  the future.
- **Dead-letter**: after `maxRetries` (default 5) with backoff, set
  `status='dead'` and **keep** the row (visible via observability). Manual
  `retryDeadLetter()` re-enqueues eligible rows.
- **Circuit breaker**: in-memory consecutive-failure counter; above threshold
  (default 5) stop the auto-loop and emit `SyncStatus.degraded`; resets on first
  success.
- **Idempotency**: dedupe on `idempotencyKey` at enqueue; safe to retry.

## 8. Observability

- `SyncStatus` enum: `idle | processing | degraded | offline`.
- `Stream<SyncStatus> get status` for a UI "sync" indicator.
- `SyncMetrics` sink with counters:
  `enqueued, succeeded, failed, deadLettered, queueDepth, lastProcessingMs`.
  Test-observable.
- Structured logs via `DeletionAudit` (operation, target, outcome, durationMs, attempt).

## 9. Server-purge contract (Appendix A — code NOT in this repo)

Documented requirements for the external `deleteMyAccount` Cloud Function so
backend work can align with the client:

1. **Idempotent** on the client-supplied `deletionRequestId`.
2. **Cascade delete** all user-owned collections in a batched write:
   `users`, `user_stats`, `habits`, `habit_completions`, `challenges`,
   tribe memberships, leaderboard entries, activity feeds.
3. **Emit** an `audit_logs` document (actor uid, timestamp, scope, outcome).
4. **Authorization**: enforce `caller.uid === target.uid` via `verifyIdToken`.
5. **Large datasets**: write a soft-delete marker, then a deferred batch purge
   job; return `{success:true, purged:[...]}`.
6. **Client contract**: returns `{success:true}` only after Firestore purge
   completes; Auth account deletion last.

## 10. Testing (TDD, per AGENTS.md)

- **Pure logic** (no Firebase/Riverpod): already-archived habit → no-op success;
  missing habit → `Left(ServerFailure)`; cascade count assertions.
- **Drift-backed** (`AppDatabase.withExecutor` in-memory): transaction + cascade +
  rollback-on-throw (partial failure).
- **Sync engine** (mock Firestore): assert backoff timing, dead-letter after N,
  dedupe by key, circuit-breaker transition.
- **Concurrent**: N parallel `deleteHabit` → exactly 1 archive + 1 enqueued mutation.
- **Integration (account)**: fake `deleteMyAccount` callable → assert local
  `clearAll` runs only on success; on failure local survives.
- **Rollback**: throw mid-transaction → local row intact.

Tests mirror lib under `test/core/deletion/` and `test/core/sync/`.

## 11. Out of scope (YAGNI)

- No new Cloud Function code (separate repo).
- No server-side transaction changes in this repo.
- No soft-delete→restore UI for accounts (single-habit un-archive is a future option).
- No new screens.

## 12. Files touched (planned)

- NEW: `lib/core/deletion/deletion_service.dart`
- NEW: `lib/core/deletion/deletion_audit.dart`
- NEW: `lib/core/deletion/sync_status.dart` (enum + metrics)
- MODIFY: `lib/core/sync/sync_engine.dart`
- MODIFY: `lib/core/drift/tables/mutation_queue_table.dart`
- MODIFY: `lib/core/drift/app_database.dart` (migration v10)
- MODIFY: `lib/core/drift/daos/habits_dao.dart` (`archiveHabit`)
- MODIFY: `lib/core/drift/daos/habit_completions_dao.dart` (`deleteByHabitId`)
- MODIFY: `lib/core/drift_repositories/drift_habit_repository.dart` (`deleteHabit`)
- MODIFY: `lib/features/auth/data/repositories/firebase_auth_repository.dart`
  (`deleteAccount` accepts `deletionRequestId`)
- MODIFY: `lib/features/settings/presentation/screens/settings_screen.dart`
  (server-first account deletion, retry UI)
- NEW tests: `test/core/deletion/`, `test/core/sync/`
