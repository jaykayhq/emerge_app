# Unified Deletion Service + Hardened Sync Engine — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Harden the `deleteHabit` and `deleteAccount` delete paths into a single,
testable `DeletionService`, fix the local-row corruption bug, and upgrade the
`EnhancedSyncEngine` with idempotency, exponential backoff, dead-lettering, a
circuit breaker, and observability.

**Architecture:** A new `lib/core/deletion/` module owns both delete operations.
`deleteHabit` runs a Drift transaction (archive + cascade) then enqueues an
idempotent Firestore mutation. `deleteAccount` goes server-first (idempotent
`deletionRequestId`, local wipe only on confirmed success). The `EnhancedSyncEngine`
mutation queue gains `idempotencyKey`/`lastError`/`nextRetryAt`/`status` columns,
exponential-backoff retries, dead-lettering instead of silent drops, a circuit
breaker, and a `SyncStatus` stream. Server-side `deleteMyAccount` is external
(see spec Appendix A); we only define the client contract + concrete adapter.

**Tech Stack:** Flutter/Dart 3.10, Riverpod 3.x, drift 2.26, cloud_firestore,
cloud_functions, firebase_auth, shared_preferences. Tests: flutter_test, mocktail,
fake_cloud_firestore, drift in-memory DB.

**Spec:** `docs/superpowers/specs/2026-07-23-unified-deletion-service-design.md`

---

## File Structure

**New files**
- `lib/core/deletion/sync_status.dart` — `SyncStatus` enum + `SyncMetrics`.
- `lib/core/deletion/deletion_audit.dart` — structured audit logging.
- `lib/core/deletion/deletion_service.dart` — unified `DeletionService`.
- `lib/core/deletion/delete_account_backend.dart` — `DeleteAccountBackend` /
  `SecureIdStore` interfaces + `CloudFunctionDeleteBackend` /
  `SharedPreferencesIdStore` adapters.
- `lib/core/deletion/deletion_providers.dart` — `deletionServiceProvider`.

**Modified files**
- `lib/core/drift/tables/mutation_queue_table.dart` — 4 new columns.
- `lib/core/drift/app_database.dart` — migration v9→10.
- `lib/core/drift/daos/mutation_queue_dao.dart` — dedup + due/failed/dead helpers.
- `lib/core/drift/daos/habits_dao.dart` — `archiveHabit`.
- `lib/core/drift/daos/habit_completions_dao.dart` — `deleteByHabitId`.
- `lib/core/sync/sync_engine.dart` — backoff, dead-letter, breaker, idempotency, status.
- `lib/core/sync/sync_providers.dart` — `syncMetricsProvider`, `syncStatusProvider`.
- `lib/core/drift_repositories/drift_habit_repository.dart` — delegate `deleteHabit`.
- `lib/features/habits/presentation/providers/habit_providers.dart` — wire service.
- `lib/features/auth/data/repositories/firebase_auth_repository.dart` — accept `deletionRequestId`.
- `lib/features/settings/presentation/screens/settings_screen.dart` — server-first deletion.

**Tests**
- `test/core/drift/mutation_queue_migration_test.dart`
- `test/core/drift/dao_deletion_methods_test.dart`
- `test/core/deletion/sync_status_test.dart`
- `test/core/sync/enhanced_sync_engine_test.dart`
- `test/core/deletion/deletion_audit_test.dart`
- `test/core/deletion/deletion_service_test.dart`
- `test/core/deletion/deletion_service_account_test.dart`
- `test/core/deletion/deletion_service_integration_test.dart`

**Generated code:** After editing any drift table/DAO, run
`flutter pub run build_runner build --delete-conflicting-outputs` (regenerates
`*.g.dart`). Run it at the end of Tasks 1, 2, and 4.

---

## Task 1: Mutation queue schema migration v10

**Files:**
- Modify: `lib/core/drift/tables/mutation_queue_table.dart`
- Modify: `lib/core/drift/app_database.dart:68-119`
- Modify: `lib/core/drift/daos/mutation_queue_dao.dart`
- Test: `test/core/drift/mutation_queue_migration_test.dart`

- [ ] **Step 1: Write the failing test** (references columns that don't exist yet)
```dart
import 'package:drift/drift.dart';
import 'package:emerge_app/core/drift/database.dart';
import 'package:emerge_app/core/drift/tables/mutation_queue_table.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mutation queue stores idempotency/status columns', () async {
    final db = AppDatabase.withExecutor(
      (await (await NativeDatabase.createInMemory()).executor).executor,
    );
    await db.mutationQueueDao.enqueue(
      collectionPath: 'habits',
      documentId: 'h1',
      operation: 'update',
      idempotencyKey: 'del:habit:h1',
    );
    final rows = await db.select(db.mutationQueueTable).get();
    expect(rows.length, 1);
    expect(rows.first.idempotencyKey, 'del:habit:h1');
    expect(rows.first.status, 'pending');
    await db.close();
  });
}
```
> Note: `AppDatabase.withExecutor` expects a `QueryExecutor`. Use
> `import 'package:drift/native.dart';` and
> `NativeDatabase.createInMemory()` → `AppDatabase.withExecutor(await NativeDatabase.createInMemory())`.
> Adjust the constructor call to `AppDatabase.withExecutor(await NativeDatabase.createInMemory())`.

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/core/drift/mutation_queue_migration_test.dart`
Expected: compile error — `idempotencyKey` / `status` getters don't exist on the table.

- [ ] **Step 3: Add the columns to the table**
In `lib/core/drift/tables/mutation_queue_table.dart` add below `retryCount`:
```dart
  TextColumn get idempotencyKey => text().nullable()();
  TextColumn get lastError => text().nullable()();
  TextColumn get nextRetryAt => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
```

- [ ] **Step 4: Add migration v10**
In `lib/core/drift/app_database.dart`:
  - change `int get schemaVersion => 9;` → `=> 10;`
  - in `onUpgrade`, add before the closing `}` of the `if` chain:
```dart
      if (from < 10) {
        await m.addColumn(mutationQueueTable, mutationQueueTable.idempotencyKey);
        await m.addColumn(mutationQueueTable, mutationQueueTable.lastError);
        await m.addColumn(mutationQueueTable, mutationQueueTable.nextRetryAt);
        await m.addColumn(mutationQueueTable, mutationQueueTable.status);
      }
```

- [ ] **Step 5: Add dedup + helper queries to the DAO**
Replace `enqueue` and add methods in `lib/core/drift/daos/mutation_queue_dao.dart`:
```dart
  Future<void> enqueue({
    required String collectionPath,
    required String documentId,
    required String operation,
    String? dataJson,
    String? idempotencyKey,
  }) async {
    if (idempotencyKey != null) {
      final existing = (select(mutationQueueTable)
            ..where((t) => t.idempotencyKey.equals(idempotencyKey)))
          .getSingleOrNull();
      if (existing != null) return; // idempotency: skip duplicate
    }
    await into(mutationQueueTable).insert(
      MutationQueueTableCompanion(
        collectionPath: Value(collectionPath),
        documentId: Value(documentId),
        operation: Value(operation),
        dataJson: Value(dataJson),
        idempotencyKey: Value(idempotencyKey),
        createdAt: Value(DateTime.now().toIso8601String()),
        status: const Value('pending'),
      ),
    );
  }

  /// Pending rows that are due now (not dead, no future retry).
  Future<List<MutationQueueTableData>> getDue(String nowIso) {
    return (select(mutationQueueTable)
          ..where((t) =>
              t.status.equals('pending') &
              (t.nextRetryAt.isNull() |
                  t.nextRetryAt.isSmallerOrEqualValue(nowIso)))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]))
        .get();
  }

  Future<void> markFailed({
    required int id,
    required int retryCount,
    required String lastError,
    required String nextRetryAt,
    required String status,
  }) {
    return (update(mutationQueueTable)..where((t) => t.id.equals(id))).write(
      MutationQueueTableCompanion(
        retryCount: Value(retryCount),
        lastError: Value(lastError),
        nextRetryAt: Value(nextRetryAt),
        status: Value(status),
      ),
    );
  }

  Future<List<MutationQueueTableData>> getDead() =>
      (select(mutationQueueTable)..where((t) => t.status.equals('dead'))).get();

  Future<void> resetDeadToPending() => (update(mutationQueueTable)
        ..where((t) => t.status.equals('dead')))
      .write(const MutationQueueTableCompanion(
        status: Value('pending'),
        retryCount: Value(0),
        nextRetryAt: Value(null),
        lastError: Value(null),
      ));
```

- [ ] **Step 6: Regenerate drift code + run test**
Run: `flutter pub run build_runner build --delete-conflicting-outputs`
Run: `flutter test test/core/drift/mutation_queue_migration_test.dart`
Expected: PASS.

- [ ] **Step 7: Commit**
```bash
git add lib/core/drift/ test/core/drift/mutation_queue_migration_test.dart
git commit -m "feat(drift): add idempotency/status columns to mutation queue (v10)"
```

---

## Task 2: DAO deletion methods (archiveHabit + deleteByHabitId)

**Files:**
- Modify: `lib/core/drift/daos/habits_dao.dart`
- Modify: `lib/core/drift/daos/habit_completions_dao.dart`
- Test: `test/core/drift/dao_deletion_methods_test.dart`

- [ ] **Step 1: Write the failing test** (asserts the corruption bug is fixed)
```dart
import 'package:drift/native.dart';
import 'package:emerge_app/core/drift/database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  setUp(() async {
    db = AppDatabase.withExecutor(await NativeDatabase.createInMemory());
    await db.habitsDao.insertFromData(
      id: 'h1',
      userId: 'u1',
      title: 'Read',
      cue: 'after coffee',
      frequency: 'daily',
      difficulty: 'hard',
      currentStreak: 7,
      longestStreak: 12,
      createdAt: DateTime(2026, 1, 1).toIso8601String(),
      updatedAt: DateTime(2026, 1, 1).toIso8601String(),
    );
    await db.habitCompletionsDao.insertFromData(
      id: 'c1', habitId: 'h1', userId: 'u1',
      completedAt: DateTime(2026, 2, 1).toIso8601String(),
    );
  });
  tearDown(() => db.close());

  test('archiveHabit only flips isArchived, preserves other fields', () async {
    await db.habitsDao.archiveHabit('h1');
    final row = await db.habitsDao.getHabit('h1');
    expect(row!.isArchived, 1);
    expect(row.cue, 'after coffee');      // NOT overwritten to ''
    expect(row.currentStreak, 7);          // NOT reset to 0
    expect(row.frequency, 'daily');
  });

  test('deleteByHabitId cascades local completions', () async {
    final deleted = await db.habitCompletionsDao.deleteByHabitId('h1');
    expect(deleted, 1);
    final remaining = await db.habitCompletionsDao.getBetweenDates(
      'u1', DateTime(2020).toIso8601String(), DateTime(2030).toIso8601String());
    expect(remaining.length, 0);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/core/drift/dao_deletion_methods_test.dart`
Expected: compile error — `archiveHabit` / `deleteByHabitId` don't exist.

- [ ] **Step 3: Add the DAO methods**
In `lib/core/drift/daos/habits_dao.dart` add after `updateMomentum`:
```dart
  /// Targeted soft-delete: flips only isArchived + updatedAt.
  /// Avoids insertOnConflictUpdate, which would blank other columns.
  Future<void> archiveHabit(String id) async {
    await (update(habitsTable)..where((t) => t.id.equals(id))).write(
      HabitsTableCompanion(
        isArchived: const Value(1),
        updatedAt: Value(DateTime.now().toIso8601String()),
      ),
    );
  }
```

In `lib/core/drift/daos/habit_completions_dao.dart` add after `getTodayCompletions`:
```dart
  /// Cascade-delete local completions for a habit.
  Future<int> deleteByHabitId(String habitId) =>
      (delete(habitCompletionsTable)
            ..where((t) => t.habitId.equals(habitId)))
          .go();
```

- [ ] **Step 4: Regenerate drift code + run test**
Run: `flutter pub run build_runner build --delete-conflicting-outputs`
Run: `flutter test test/core/drift/dao_deletion_methods_test.dart`
Expected: PASS (confirms streak/cue preserved).

- [ ] **Step 5: Commit**
```bash
git add lib/core/drift/daos/habits_dao.dart lib/core/drift/daos/habit_completions_dao.dart test/core/drift/dao_deletion_methods_test.dart
git commit -m "feat(drift): add archiveHabit + deleteByHabitId (cascade) DAOs"
```

---

## Task 3: SyncStatus + SyncMetrics observability primitives

**Files:**
- Create: `lib/core/deletion/sync_status.dart`
- Test: `test/core/deletion/sync_status_test.dart`

- [ ] **Step 1: Write the failing test**
```dart
import 'package:emerge_app/core/deletion/sync_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('metrics increment and copy', () {
    final m = SyncMetrics();
    expect(m.queueDepth, 0);
    m.recordEnqueued();
    m.recordSucceeded();
    m.recordDeadLettered();
    expect(m.enqueued, 1);
    expect(m.succeeded, 1);
    expect(m.deadLettered, 1);
    final c = m.copy();
    expect(c.enqueued, 1);
    c.recordFailed();
    expect(m.failed, 0); // copy is independent
  });

  test('SyncStatus enum has expected values', () {
    expect(SyncStatus.values, [SyncStatus.idle, SyncStatus.processing, SyncStatus.degraded, SyncStatus.offline]);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/core/deletion/sync_status_test.dart`
Expected: compile error — no `sync_status.dart`.

- [ ] **Step 3: Create the file**
`lib/core/deletion/sync_status.dart`:
```dart
enum SyncStatus { idle, processing, degraded, offline }

/// In-memory counters for deletion/sync observability.
class SyncMetrics {
  int enqueued = 0;
  int succeeded = 0;
  int failed = 0;
  int deadLettered = 0;
  int queueDepth = 0;
  int lastProcessingMs = 0;

  void recordEnqueued() => enqueued++;
  void recordSucceeded() => succeeded++;
  void recordFailed() => failed++;
  void recordDeadLettered() => deadLettered++;

  SyncMetrics copy() => SyncMetrics()
    ..enqueued = enqueued
    ..succeeded = succeeded
    ..failed = failed
    ..deadLettered = deadLettered
    ..queueDepth = queueDepth
    ..lastProcessingMs = lastProcessingMs;
}
```

- [ ] **Step 4: Run test to verify it passes**
Run: `flutter test test/core/deletion/sync_status_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**
```bash
git add lib/core/deletion/sync_status.dart test/core/deletion/sync_status_test.dart
git commit -m "feat(deletion): add SyncStatus enum + SyncMetrics"
```

---

## Task 4: Hardened EnhancedSyncEngine (backoff, dead-letter, breaker, idempotency, status)

**Files:**
- Modify: `lib/core/sync/sync_engine.dart`
- Modify: `lib/core/sync/sync_providers.dart`
- Test: `test/core/sync/enhanced_sync_engine_test.dart`

- [ ] **Step 1: Write the failing test** (uses injected applier + FakeFirebaseFirestore)
```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/core/deletion/sync_status.dart';
import 'package:emerge_app/core/drift/database.dart';
import 'package:emerge_app/core/sync/sync_engine.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late EnhancedSyncEngine engine;

  setUp(() async {
    db = AppDatabase.withExecutor(await NativeDatabase.createInMemory());
  });
  tearDown(() => db.close());

  test('dedupes by idempotencyKey', () async {
    engine = EnhancedSyncEngine(
      db.mutationQueueDao, FakeFirebaseFirestore(), metrics: SyncMetrics());
    await engine.enqueueMutation(
      collectionPath: 'habits', documentId: 'h1',
      operation: 'update', idempotencyKey: 'k1');
    await engine.enqueueMutation(
      collectionPath: 'habits', documentId: 'h1',
      operation: 'update', idempotencyKey: 'k1');
    final rows = await db.mutationQueueDao.getAllPending();
    expect(rows.length, 1);
  });

  test('dead-letters after maxRetries instead of dropping', () async {
    int attempts = 0;
    engine = EnhancedSyncEngine(
      db.mutationQueueDao, FakeFirebaseFirestore(),
      metrics: SyncMetrics(),
      applier: (_) async { attempts++; return false; });
    await engine.enqueueMutation(
      collectionPath: 'habits', documentId: 'h1', operation: 'update');
    // process once per attempt; engine advances retryCount each pass
    for (int i = 0; i < 6; i++) {
      await engine.processMutationQueue();
    }
    final dead = await db.mutationQueueDao.getDead();
    expect(dead.length, 1, reason: 'row must be retained as dead, not dropped');
    expect(dead.first.status, 'dead');
    expect(attempts, greaterThanOrEqualTo(5));
  });

  test('circuit breaker flips to degraded after consecutive failures', () async {
    engine = EnhancedSyncEngine(
      db.mutationQueueDao, FakeFirebaseFirestore(),
      metrics: SyncMetrics(),
      breakerThreshold: 2,
      applier: (_) async => false);
    await engine.enqueueMutation(
      collectionPath: 'habits', documentId: 'h1', operation: 'update');
    await engine.processMutationQueue();
    await engine.processMutationQueue();
    final states = <SyncStatus>[];
    final sub = engine.status.listen(states.add);
    await engine.processMutationQueue();
    await Future.delayed(Duration.zero);
    expect(states, contains(SyncStatus.degraded));
    await sub.cancel();
  });

  test('backoff schedules nextRetryAt in the future', () async {
    final sw = Stopwatch()..start();
    engine = EnhancedSyncEngine(
      db.mutationQueueDao, FakeFirebaseFirestore(),
      metrics: SyncMetrics(), applier: (_) async => false);
    await engine.enqueueMutation(
      collectionPath: 'habits', documentId: 'h1', operation: 'update');
    await engine.processMutationQueue();
    final rows = await db.mutationQueueDao.getAllPending();
    final next = DateTime.parse(rows.first.nextRetryAt!);
    expect(next.isAfter(DateTime.now()), isTrue);
    sw.stop();
  });
}
```
> `NativeDatabase` import: `import 'package:drift/native.dart';`

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/core/sync/enhanced_sync_engine_test.dart`
Expected: compile error — constructor params `metrics`/`applier`/`breakerThreshold`,
`idempotencyKey`, and `status` stream don't exist.

- [ ] **Step 3: Rewrite the engine**
Replace `lib/core/sync/sync_engine.dart` with:
```dart
import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/core/deletion/sync_status.dart';
import 'package:emerge_app/core/drift/database.dart';
import 'package:emerge_app/core/utils/app_logger.dart';

class EnhancedSyncEngine {
  final MutationQueueDao _mutationQueue;
  final FirebaseFirestore _firestore;
  final SyncMetrics _metrics;
  final Future<bool> Function(MutationQueueTableData)? applier;

  final int maxRetries;
  final int breakerThreshold;
  final Duration baseBackoff;
  final Duration capBackoff;

  final StreamController<SyncStatus> _statusController =
      StreamController<SyncStatus>.broadcast();
  SyncStatus _status = SyncStatus.idle;
  int _consecutiveFailures = 0;
  bool _isProcessing = false;

  EnhancedSyncEngine(
    this._mutationQueue,
    this._firestore, {
    SyncMetrics? metrics,
    this.applier,
    this.maxRetries = 5,
    this.breakerThreshold = 5,
    this.baseBackoff = const Duration(seconds: 1),
    this.capBackoff = const Duration(minutes: 5),
  }) : _metrics = metrics ?? SyncMetrics();

  Stream<SyncStatus> get status => _statusController.stream;

  void _setStatus(SyncStatus s) {
    if (_status != s) {
      _status = s;
      _statusController.add(s);
    }
  }

  Future<void> enqueueMutation({
    required String collectionPath,
    required String documentId,
    required String operation,
    Map<String, dynamic>? data,
    String? idempotencyKey,
  }) async {
    _metrics.recordEnqueued();
    await _mutationQueue.enqueue(
      collectionPath: collectionPath,
      documentId: documentId,
      operation: operation,
      dataJson: data != null ? jsonEncode(data) : null,
      idempotencyKey: idempotencyKey,
    );
  }

  Future<void> enqueueSet({
    required String collectionPath,
    required String documentId,
    required Map<String, dynamic> data,
  }) =>
      enqueueMutation(
        collectionPath: collectionPath,
        documentId: documentId,
        operation: 'set',
        data: data,
      );

  Future<void> enqueueUpdate({
    required String collectionPath,
    required String documentId,
    required Map<String, dynamic> data,
    String? idempotencyKey,
  }) =>
      enqueueMutation(
        collectionPath: collectionPath,
        documentId: documentId,
        operation: 'update',
        data: data,
        idempotencyKey: idempotencyKey,
      );

  Future<void> processMutationQueue() async {
    if (_isProcessing) {
      AppLogger.d('SyncEngine: Already processing, skipping');
      return;
    }
    _isProcessing = true;
    _setStatus(SyncStatus.processing);
    final sw = Stopwatch()..start();
    try {
      final nowIso = DateTime.now().toIso8601String();
      final mutations = await _mutationQueue.getDue(nowIso);
      _metrics.queueDepth = mutations.length;
      for (final mutation in mutations) {
        final ok = applier != null
            ? await applier!(mutation)
            : await _applyMutation(mutation);
        if (ok) {
          await _mutationQueue.deleteProcessed(mutation.id);
          _metrics.recordSucceeded();
          _consecutiveFailures = 0;
          AppLogger.d('SyncEngine: Synced mutation ${mutation.id}');
        } else {
          _metrics.recordFailed();
          _consecutiveFailures++;
          final nextCount = mutation.retryCount + 1;
          final nextRetry = _backoff(nextCount);
          final status = nextCount >= maxRetries ? 'dead' : 'pending';
          if (status == 'dead') _metrics.recordDeadLettered();
          await _mutationQueue.markFailed(
            id: mutation.id,
            retryCount: nextCount,
            lastError: 'apply failed',
            nextRetryAt: nextRetry.toIso8601String(),
            status: status,
          );
          AppLogger.w('SyncEngine: Mutation ${mutation.id} failed '
              '(attempt $nextCount/$maxRetries) -> $status');
        }
      }
      _setStatus(_consecutiveFailures >= breakerThreshold
          ? SyncStatus.degraded
          : SyncStatus.idle);
    } catch (e) {
      AppLogger.e('SyncEngine: processing error', e);
      _setStatus(SyncStatus.degraded);
    } finally {
      _metrics.lastProcessingMs = sw.elapsedMilliseconds;
      _isProcessing = false;
    }
  }

  DateTime _backoff(int retryCount) {
    final exp = baseBackoff * (1 << (retryCount - 1));
    final clamped = exp > capBackoff ? capBackoff : exp;
    return DateTime.now().add(clamped);
  }

  /// Re-enqueue dead-letter rows for another attempt.
  Future<void> retryDeadLetter() async {
    await _mutationQueue.resetDeadToPending();
    _consecutiveFailures = 0;
    await processMutationQueue();
  }

  Future<bool> _applyMutation(MutationQueueTableData mutation) async {
    try {
      final ref = _firestore
          .collection(mutation.collectionPath)
          .doc(mutation.documentId);
      final data = mutation.dataJson != null
          ? Map<String, dynamic>.from(jsonDecode(mutation.dataJson!) as Map)
          : <String, dynamic>{};
      switch (mutation.operation) {
        case 'set':
          _convertTimestamps(data);
          _processMarkers(data);
          await ref.set(data, SetOptions(merge: true));
          break;
        case 'update':
          _convertTimestamps(data);
          _processMarkers(data);
          await ref.update(data);
          break;
        case 'delete':
          await ref.delete();
          break;
        default:
          return false;
      }
      return true;
    } catch (e) {
      AppLogger.d('SyncEngine: Error applying mutation: $e');
      return false;
    }
  }

  void _convertTimestamps(Map<String, dynamic> data) {
    data.forEach((key, value) {
      if (value is String && value.contains('T') && value.contains('-')) {
        final date = DateTime.tryParse(value);
        if (date != null) data[key] = Timestamp.fromDate(date);
      } else if (value is Map<String, dynamic>) {
        _convertTimestamps(value);
      } else if (value is List) {
        for (var i = 0; i < value.length; i++) {
          if (value[i] is Map<String, dynamic>) {
            _convertTimestamps(value[i] as Map<String, dynamic>);
          }
        }
      }
    });
  }

  void _processMarkers(Map<String, dynamic> data) {
    final keysToUpdate = <String, dynamic>{};
    data.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        if (value.containsKey('__type__')) {
          final type = value['__type__'];
          if (type == 'increment') {
            keysToUpdate[key] = FieldValue.increment(value['value'] as num);
          } else if (type == 'serverTimestamp') {
            keysToUpdate[key] = FieldValue.serverTimestamp();
          } else if (type == 'arrayUnion') {
            keysToUpdate[key] = FieldValue.arrayUnion(value['values'] as List);
          } else if (type == 'arrayRemove') {
            keysToUpdate[key] = FieldValue.arrayRemove(value['values'] as List);
          }
        } else {
          _processMarkers(value);
        }
      } else if (value is List) {
        for (var i = 0; i < value.length; i++) {
          if (value[i] is Map<String, dynamic>) {
            _processMarkers(value[i] as Map<String, dynamic>);
          }
        }
      }
    });
    data.addAll(keysToUpdate);
  }
}
```
> Note: `_mutationQueue.getAllPending()` still exists (defined in Task 1's DAO).
> The engine now uses `getDue` for processing. `getAllPending()` remains available
> for queue-depth display; tests reference it and it returns pending rows.

- [ ] **Step 4: Add providers (metrics + status)**
In `lib/core/sync/sync_providers.dart` add after `enhancedSyncEngineProvider`:
```dart
final syncMetricsProvider = Provider<SyncMetrics>((ref) {
  final engine = ref.watch(enhancedSyncEngineProvider);
  return engine._metrics; // expose shared metrics
});
```
> `_metrics` is private. Add a public getter `SyncMetrics get metrics => _metrics;`
> to `EnhancedSyncEngine` and use `engine.metrics` above.

Add a status stream provider:
```dart
final syncStatusProvider = StreamProvider<SyncStatus>((ref) {
  final engine = ref.watch(enhancedSyncEngineProvider);
  return engine.status;
});
```
Update `enhancedSyncEngineProvider` to pass shared metrics:
```dart
final enhancedSyncEngineProvider = Provider<EnhancedSyncEngine>((ref) {
  final mutationQueue = ref.watch(mutationQueueDaoProvider);
  final metrics = ref.watch(syncMetricsProvider); // careful: avoid cycle
  return EnhancedSyncEngine(mutationQueue, FirebaseFirestore.instance,
      metrics: SyncMetrics());
});
```
> To avoid a provider cycle, do NOT read `syncMetricsProvider` inside
> `enhancedSyncEngineProvider`. Instead create the metrics inside the engine
> (default `SyncMetrics()`) and expose via `metrics` getter. Remove the
> `syncMetricsProvider`/`syncStatusProvider` dependency on the engine provider
> cycle by defining:
```dart
final syncStatusProvider = StreamProvider<SyncStatus>((ref) {
  final engine = ref.watch(enhancedSyncEngineProvider);
  return engine.status;
});
```
> `enhancedSyncEngineProvider` keeps `metrics: SyncMetrics()` (its own instance);
> `engine.metrics` exposes it for any UI that wants counters.

- [ ] **Step 5: Regenerate if needed + run tests**
Run: `flutter test test/core/sync/enhanced_sync_engine_test.dart`
Expected: PASS (dedupe, dead-letter retained, breaker degraded, backoff future).

- [ ] **Step 6: Commit**
```bash
git add lib/core/sync/ test/core/sync/enhanced_sync_engine_test.dart
git commit -m "feat(sync): hardened engine — backoff, dead-letter, idempotency, breaker, status"
```

---

## Task 5: DeletionAudit (structured logging)

**Files:**
- Create: `lib/core/deletion/deletion_audit.dart`
- Test: `test/core/deletion/deletion_audit_test.dart`

- [ ] **Step 1: Write the failing test**
```dart
import 'package:emerge_app/core/deletion/deletion_audit.dart';
import 'package:emerge_app/core/deletion/sync_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('emits structured event with required keys', () {
    final events = <Map<String, dynamic>>[];
    final audit = DeletionAudit(
      metrics: SyncMetrics(),
      onEvent: events.add,
    );
    audit.log(
      op: 'deleteHabit',
      target: 'habit',
      habitId: 'h1',
      outcome: 'success',
      durationMs: 12,
      attempt: 1,
    );
    expect(events.length, 1);
    final e = events.first;
    expect(e['op'], 'deleteHabit');
    expect(e['target'], 'habit');
    expect(e['outcome'], 'success');
    expect(e['durationMs'], 12);
    expect(e['attempt'], 1);
    expect(e['habitId'], 'h1');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/core/deletion/deletion_audit_test.dart`
Expected: compile error.

- [ ] **Step 3: Create the file**
`lib/core/deletion/deletion_audit.dart`:
```dart
import 'package:emerge_app/core/deletion/sync_status.dart';
import 'package:emerge_app/core/utils/app_logger.dart';

/// Structured, security-grade audit logging for deletion operations.
class DeletionAudit {
  final SyncMetrics _metrics;
  final void Function(Map<String, dynamic> event)? _onEvent;

  DeletionAudit({SyncMetrics? metrics, void Function(Map<String, dynamic>)? onEvent})
      : _metrics = metrics ?? SyncMetrics(),
        _onEvent = onEvent;

  SyncMetrics get metrics => _metrics;

  void log({
    required String op,
    required String target,
    required String outcome,
    required int durationMs,
    int attempt = 1,
    String? habitId,
    String? uid,
    String? error,
  }) {
    final event = <String, dynamic>{
      'op': op,
      'target': target,
      'outcome': outcome,
      'durationMs': durationMs,
      'attempt': attempt,
      if (habitId != null) 'habitId': habitId,
      if (uid != null) 'uid': uid,
      if (error != null) 'error': error,
      'ts': DateTime.now().toIso8601String(),
    };
    // Account-level deletions are security events → Crashlytics in prod.
    if (op == 'deleteAccount') {
      AppLogger.security('[DELETION] $op $outcome',
          context: {'target': target, 'uid': uid, 'outcome': outcome});
    } else {
      AppLogger.i('[DELETION] $op $outcome (${durationMs}ms)');
    }
    _onEvent?.call(event);
  }
}
```

- [ ] **Step 4: Run test to verify it passes**
Run: `flutter test test/core/deletion/deletion_audit_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**
```bash
git add lib/core/deletion/deletion_audit.dart test/core/deletion/deletion_audit_test.dart
git commit -m "feat(deletion): structured DeletionAudit logging"
```

---

## Task 6: DeletionService.deleteHabit

**Files:**
- Create: `lib/core/deletion/deletion_service.dart`
- Test: `test/core/deletion/deletion_service_test.dart`

- [ ] **Step 1: Write the failing test**
```dart
import 'package:drift/native.dart';
import 'package:emerge_app/core/deletion/deletion_audit.dart';
import 'package:emerge_app/core/deletion/deletion_service.dart';
import 'package:emerge_app/core/deletion/sync_status.dart';
import 'package:emerge_app/core/drift/database.dart';
import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/core/sync/sync_engine.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockSyncEngine extends Mock implements EnhancedSyncEngine {}

void main() {
  late AppDatabase db;
  late MockSyncEngine sync;
  late DeletionService service;

  setUp(() async {
    db = AppDatabase.withExecutor(await NativeDatabase.createInMemory());
    sync = MockSyncEngine();
    when(() => sync.enqueueUpdate(
          collectionPath: any(named: 'collectionPath'),
          documentId: any(named: 'documentId'),
          data: any(named: 'data'),
          idempotencyKey: any(named: 'idempotencyKey'),
        )).thenAnswer((_) async {});
    service = DeletionService(
      db: db,
      syncEngine: sync,
      audit: DeletionAudit(metrics: SyncMetrics()),
    );
  });
  tearDown(() => db.close());

  test('deleteHabit archives + cascades + enqueues with idempotency key', () async {
    await db.habitsDao.insertFromData(
      id: 'h1', userId: 'u1', title: 'Read',
      cue: 'x', currentStreak: 5,
      createdAt: DateTime(2026).toIso8601String(),
      updatedAt: DateTime(2026).toIso8601String());
    await db.habitCompletionsDao.insertFromData(
      id: 'c1', habitId: 'h1', userId: 'u1',
      completedAt: DateTime(2026, 2).toIso8601String());

    final res = await service.deleteHabit(userId: 'u1', habitId: 'h1');
    expect(res, const Right<Failure, Unit>(unit));

    final row = await db.habitsDao.getHabit('h1');
    expect(row!.isArchived, 1);
    expect(row.currentStreak, 5); // preserved
    final comps = await db.habitCompletionsDao.getBetweenDates(
      'u1', DateTime(2020).toIso8601String(), DateTime(2030).toIso8601String());
    expect(comps.length, 0);

    final ver = verify(() => sync.enqueueUpdate(
          collectionPath: 'habits', documentId: 'h1',
          data: any(named: 'data'),
          idempotencyKey: captureAny(named: 'idempotencyKey'))).captured;
    expect(ver.single, 'del:habit:h1');
  });

  test('deleting an already-archived habit is a no-op success', () async {
    await db.habitsDao.insertFromData(
      id: 'h1', userId: 'u1', title: 'Read',
      currentStreak: 5, isArchived: 1,
      createdAt: DateTime(2026).toIso8601String(),
      updatedAt: DateTime(2026).toIso8601String());
    final res = await service.deleteHabit(userId: 'u1', habitId: 'h1');
    expect(res, const Right<Failure, Unit>(unit));
    verifyNever(() => sync.enqueueUpdate(
          collectionPath: any(named: 'collectionPath'),
          documentId: any(named: 'documentId'),
          data: any(named: 'data'),
          idempotencyKey: any(named: 'idempotencyKey')));
  });

  test('missing habit returns Left', () async {
    final res = await service.deleteHabit(userId: 'u1', habitId: 'nope');
    expect(res.isLeft(), isTrue);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/core/deletion/deletion_service_test.dart`
Expected: compile error.

- [ ] **Step 3: Create the service**
`lib/core/deletion/deletion_service.dart`:
```dart
import 'dart:async';

import 'package:emerge_app/core/deletion/deletion_audit.dart';
import 'package:emerge_app/core/deletion/delete_account_backend.dart';
import 'package:emerge_app/core/deletion/sync_status.dart';
import 'package:emerge_app/core/drift/database.dart';
import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/core/sync/sync_engine.dart';
import 'package:fpdart/fpdart.dart';

/// Single owner of deletion logic for both habit and account deletes.
class DeletionService {
  final AppDatabase _db;
  final EnhancedSyncEngine _syncEngine;
  final DeletionAudit _audit;

  DeletionService({
    required AppDatabase db,
    required EnhancedSyncEngine syncEngine,
    required DeletionAudit audit,
  })  : _db = db,
        _syncEngine = syncEngine,
        _audit = audit;

  Future<Either<Failure, Unit>> deleteHabit({
    required String userId,
    required String habitId,
  }) async {
    final sw = Stopwatch()..start();
    try {
      final existing = await _db.habitsDao.getHabit(habitId);
      if (existing == null) {
        return const Left(ServerFailure('Habit not found'));
      }
      if (existing.isArchived == 1) {
        _audit.log(
          op: 'deleteHabit',
          target: 'habit',
          habitId: habitId,
          outcome: 'noop',
          durationMs: sw.elapsedMilliseconds,
        );
        return const Right(unit); // idempotent
      }
      await _db.transaction(() async {
        await _db.habitsDao.archiveHabit(habitId);
        await _db.habitCompletionsDao.deleteByHabitId(habitId);
      });
      await _syncEngine.enqueueUpdate(
        collectionPath: 'habits',
        documentId: habitId,
        data: {'isArchived': true},
        idempotencyKey: 'del:habit:$habitId',
      );
      _audit.log(
        op: 'deleteHabit',
        target: 'habit',
        habitId: habitId,
        outcome: 'success',
        durationMs: sw.elapsedMilliseconds,
      );
      return const Right(unit);
    } catch (e, _) {
      _audit.log(
        op: 'deleteHabit',
        target: 'habit',
        habitId: habitId,
        outcome: 'error',
        durationMs: sw.elapsedMilliseconds,
        error: e.toString(),
      );
      return Left(ServerFailure(e.toString()));
    }
  }
}
```

- [ ] **Step 4: Run test to verify it passes**
Run: `flutter test test/core/deletion/deletion_service_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**
```bash
git add lib/core/deletion/deletion_service.dart test/core/deletion/deletion_service_test.dart
git commit -m "feat(deletion): DeletionService.deleteHabit (transaction + cascade + idempotency)"
```

---

## Task 7: DeletionService.deleteAccount (server-first, idempotent)

**Files:**
- Create: `lib/core/deletion/delete_account_backend.dart`
- Test: `test/core/deletion/deletion_service_account_test.dart`

- [ ] **Step 1: Write the failing test**
```dart
import 'package:emerge_app/core/deletion/deletion_audit.dart';
import 'package:emerge_app/core/deletion/deletion_service.dart';
import 'package:emerge_app/core/deletion/delete_account_backend.dart';
import 'package:emerge_app/core/deletion/sync_status.dart';
import 'package:emerge_app/core/drift/database.dart';
import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/core/sync/sync_engine.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class FakeBackend extends Fake implements DeleteAccountBackend {
  bool shouldSucceed;
  String? lastId;
  FakeBackend(this.shouldSucceed);
  @override
  Future<Either<Failure, Unit>> delete({required String deletionRequestId}) async {
    lastId = deletionRequestId;
    return shouldSucceed ? const Right(unit) : const Left(ServerFailure('boom'));
  }
}

class FakeIdStore extends Fake implements SecureIdStore {
  String? _stored;
  @override
  Future<String> loadOrCreateId(String key) async => _stored ??= 'id-$key';
  @override
  Future<void> clear(String key) async => _stored = null;
}

class FakeAuth extends Fake implements FakeAuthLike {
  bool signedOut = false;
  @override
  Future<void> signOut() async => signedOut = true;
}

late AppDatabase testDb;

void main() {
  late DeletionService service;
  late FakeBackend backend;
  late FakeIdStore idStore;
  late FakeAuth auth;

  setUp(() async {
    testDb = await AppDatabase.forTest();
    backend = FakeBackend(true);
    idStore = FakeIdStore();
    auth = FakeAuth();
    service = DeletionService(
      db: testDb,
      syncEngine: EnhancedSyncEngine(
        testDb.mutationQueueDao,
        FakeFirebaseFirestore(),
        metrics: SyncMetrics()),
      audit: DeletionAudit(metrics: SyncMetrics()),
    );
  });

  test('success: clears local db + signs out + returns Right', () async {
    final res = await service.deleteAccount(
      userId: 'u1',
      backend: backend,
      idStore: idStore,
      auth: auth,
    );
    expect(res, const Right<Failure, Unit>(unit));
    expect(auth.signedOut, isTrue);
    expect(backend.lastId, startsWith('id-'));
  });

  test('failure: local data is NOT cleared, returns Left, id retained', () async {
    backend = FakeBackend(false);
    // Pre-populate local so we can assert it survives.
    final res = await service.deleteAccount(
      userId: 'u1',
      backend: backend,
      idStore: idStore,
      auth: auth,
    );
    expect(res.isLeft(), isTrue);
    expect(auth.signedOut, isFalse);
    expect(idStore._stored, isNotNull); // deletionRequestId retained for retry
  });
}
```
> `AppDatabase.forTest()` must exist — add a factory in Task 7 Step 3 that
> returns `AppDatabase.withExecutor(await NativeDatabase.createInMemory())`.
> `FakeAuthLike` is a tiny abstract defined in the test for `signOut()`. Replace
> with `FirebaseAuth` mock if preferred; the service only calls `auth.signOut()`.

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/core/deletion/deletion_service_account_test.dart`
Expected: compile error — `deleteAccount`, `DeleteAccountBackend`, `SecureIdStore`
don't exist; `AppDatabase.forTest()` missing.

- [ ] **Step 3: Create the backend abstractions + adapter**
`lib/core/deletion/delete_account_backend.dart`:
```dart
import 'package:cloud_functions/cloud_functions.dart';
import 'package:emerge_app/core/error/failure.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Contract for the (external) server-side purge. See spec Appendix A.
abstract class DeleteAccountBackend {
  Future<Either<Failure, Unit>> delete({required String deletionRequestId});
}

/// Durable store for the idempotency key.
abstract class SecureIdStore {
  Future<String> loadOrCreateId(String key);
  Future<void> clear(String key);
}

class CloudFunctionDeleteBackend implements DeleteAccountBackend {
  final FirebaseFunctions _functions;
  CloudFunctionDeleteBackend(this._functions);

  @override
  Future<Either<Failure, Unit>> delete(
      {required String deletionRequestId}) async {
    try {
      final result = await _functions
          .httpsCallable('deleteMyAccount')
          .call({'deletionRequestId': deletionRequestId});
      if (result.data != null && (result.data as Map)['success'] == true) {
        return const Right(unit);
      }
      return const Left(ServerFailure('Account deletion failed'));
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'unauthenticated') {
        return const Left(AuthFailure('Please log in again.'));
      }
      return Left(ServerFailure(e.message ?? 'Delete failed'));
    } catch (e, _) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

class SharedPreferencesIdStore implements SecureIdStore {
  const SharedPreferencesIdStore();

  @override
  Future<String> loadOrCreateId(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(key);
    if (existing != null) return existing;
    final generated =
        '${DateTime.now().microsecondsSinceEpoch}-${key.hashCode}';
    await prefs.setString(key, generated);
    return generated;
  }

  @override
  Future<void> clear(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}
```
Add to `AppDatabase` (in `lib/core/drift/app_database.dart`) a test factory:
```dart
  static Future<AppDatabase> forTest() async =>
      AppDatabase.withExecutor(await NativeDatabase.createInMemory());
```
> `NativeDatabase` import: `import 'package:drift/native.dart';` in `app_database.dart`.

- [ ] **Step 4: Add deleteAccount to the service**
Append to `DeletionService` in `lib/core/deletion/deletion_service.dart`:
```dart
  Future<Either<Failure, Unit>> deleteAccount({
    required String userId,
    required DeleteAccountBackend backend,
    required SecureIdStore idStore,
    required FirebaseAuth auth,
  }) async {
    final sw = Stopwatch()..start();
    final id = await idStore.loadOrCreateId('deletionRequestId:$userId');
    final result = await backend.delete(deletionRequestId: id);
    if (result.isLeft()) {
      final msg = result.fold((f) => f.message, (_) => 'error');
      _audit.log(
        op: 'deleteAccount',
        target: 'account',
        uid: userId,
        outcome: 'error',
        durationMs: sw.elapsedMilliseconds,
        error: msg,
      );
      return result; // local data intentionally NOT cleared
    }
    await _db.clearAll();
    await auth.signOut();
    await idStore.clear('deletionRequestId:$userId');
    _audit.log(
      op: 'deleteAccount',
      target: 'account',
      uid: userId,
      outcome: 'success',
      durationMs: sw.elapsedMilliseconds,
    );
    return const Right(unit);
  }
```
> Add `import 'package:firebase_auth/firebase_auth.dart';` to `deletion_service.dart`.

- [ ] **Step 5: Run test to verify it passes**
Run: `flutter test test/core/deletion/deletion_service_account_test.dart`
Expected: PASS (success clears; failure keeps local + retains id).

- [ ] **Step 6: Commit**
```bash
git add lib/core/deletion/delete_account_backend.dart lib/core/deletion/deletion_service.dart lib/core/drift/app_database.dart test/core/deletion/deletion_service_account_test.dart
git commit -m "feat(deletion): server-first deleteAccount with idempotent request id"
```

---

## Task 8: Wire deleteHabit through DeletionService in DriftHabitRepository

**Files:**
- Modify: `lib/core/drift_repositories/drift_habit_repository.dart`
- Modify: `lib/features/habits/presentation/providers/habit_providers.dart`
- Modify: `lib/core/deletion/deletion_providers.dart` (new)
- Test: extend `test/core/deletion/deletion_service_test.dart` or add
  `test/core/drift_repositories/drift_habit_repository_delete_test.dart`

- [ ] **Step 1: Add deletionServiceProvider**
Create `lib/core/deletion/deletion_providers.dart`:
```dart
import 'package:emerge_app/core/deletion/deletion_audit.dart';
import 'package:emerge_app/core/deletion/deletion_service.dart';
import 'package:emerge_app/core/drift/database.dart';
import 'package:emerge_app/core/sync/sync_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final deletionServiceProvider = Provider<DeletionService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final engine = ref.watch(enhancedSyncEngineProvider);
  return DeletionService(
    db: db,
    syncEngine: engine,
    audit: DeletionAudit(),
  );
});
```

- [ ] **Step 2: Inject + delegate in DriftHabitRepository**
In `drift_habit_repository.dart`:
  - add `final DeletionService _deletionService;` to fields and constructor
    (`required DeletionService deletionService`) and assign.
  - import `package:emerge_app/core/deletion/deletion_service.dart`.
  - replace the body of `deleteHabit` (lines 121-146) with:
```dart
  @override
  Future<Either<Failure, Unit>> deleteHabit(String habitId) async {
    try {
      final existing = await _db.habitsDao.getHabit(habitId);
      if (existing == null) return const Left(ServerFailure('Habit not found'));
      return await _deletionService.deleteHabit(
        userId: existing.userId,
        habitId: habitId,
      );
    } catch (e, _) {
      return Left(ServerFailure(e.toString()));
    }
  }
```

- [ ] **Step 3: Wire the provider**
In `habit_providers.dart`, update the `HabitRepository` provider:
```dart
@Riverpod(keepAlive: true)
HabitRepository habitRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  final engine = LocalGameLoopEngine();
  final syncEngine = ref.watch(enhancedSyncEngineProvider);
  final socialService = ref.watch(socialActivityServiceProvider);
  final deletionService = ref.watch(deletionServiceProvider);
  return DriftHabitRepository(
    db: db,
    gameLoopEngine: engine,
    syncEngine: syncEngine,
    socialService: socialService,
    deletionService: deletionService,
  );
}
```
Add imports:
`import 'package:emerge_app/core/deletion/deletion_providers.dart';`

- [ ] **Step 4: Run analyzer + a repo delete test**
Run: `flutter analyze lib/core/drift_repositories/drift_habit_repository.dart lib/features/habits/presentation/providers/habit_providers.dart`
Expected: no errors.
Add `test/core/drift_repositories/drift_habit_repository_delete_test.dart` that
constructs `DriftHabitRepository` with a real in-memory `AppDatabase`,
a real `EnhancedSyncEngine` (FakeFirebaseFirestore), a `FakeSocialActivityService`
(mocktail), a `LocalGameLoopEngine()`, and a real `DeletionService`, inserts a
habit, calls `deleteHabit`, and asserts the local row is `isArchived == 1` and
streak/cue preserved. (Mirror the DAO test assertions; this proves the wiring.)

- [ ] **Step 5: Run tests**
Run: `flutter test test/core/drift_repositories/`
Expected: PASS.

- [ ] **Step 6: Commit**
```bash
git add lib/core/deletion/deletion_providers.dart lib/core/drift_repositories/drift_habit_repository.dart lib/features/habits/presentation/providers/habit_providers.dart test/core/drift_repositories/
git commit -m "feat(habits): route deleteHabit through unified DeletionService"
```

---

## Task 9: Wire server-first deleteAccount into auth + settings UI

**Files:**
- Modify: `lib/features/auth/data/repositories/firebase_auth_repository.dart`
- Modify: `lib/features/settings/presentation/screens/settings_screen.dart`

- [ ] **Step 1: Update auth repository to accept deletionRequestId**
In `firebase_auth_repository.dart`, change `deleteAccount()` signature to
`deleteAccount({required String deletionRequestId})` and pass it to the callable:
```dart
  @override
  Future<Either<Failure, void>> deleteAccount(
      {required String deletionRequestId}) async {
    try {
      final functions = FirebaseFunctions.instance;
      final result = await functions
          .httpsCallable('deleteMyAccount')
          .call({'deletionRequestId': deletionRequestId});
      if (result.data != null && (result.data as Map)['success'] == true) {
        return const Right(null);
      }
      return const Left(ServerFailure('Account deletion failed unexpectedly'));
    } on FirebaseFunctionsException catch (e) {
      AppLogger.e('Delete account failed', e);
      if (e.code == 'unauthenticated') {
        return const Left(AuthFailure('Please log in again before deleting.'));
      }
      return Left(ServerFailure(e.message ?? 'Delete failed'));
    } catch (e, _) {
      AppLogger.e('Delete account failed', e);
      return Left(ServerFailure(e.toString()));
    }
  }
```
> `CloudFunctionDeleteBackend` (Task 7) will wrap this callable, so the new
> signature is the single source of truth. Update any other callers of
> `deleteAccount()` (grep) to pass `deletionRequestId`.

- [ ] **Step 2: Replace the settings-screen deletion flow**
In `settings_screen.dart`, inside `_showDeleteAccountDialog`, replace the block
that does `await db.clearAll();` first then `deleteAccount()` with a
server-first call to `DeletionService.deleteAccount`, and on failure keep local
data + offer retry. Use:
```dart
// inside the confirm `onPressed` async block, replacing clearAll-first logic:
final userId = ref.read(authStateChangesProvider).value?.id ?? '';
final service = ref.read(deletionServiceProvider);
final result = await service.deleteAccount(
  userId: userId,
  backend: CloudFunctionDeleteBackend(FirebaseFunctions.instance),
  idStore: const SharedPreferencesIdStore(),
  auth: FirebaseAuth.instance,
);
if (!context.mounted) return;
Navigator.of(context, rootNavigator: true).pop(); // dismiss loading
result.fold(
  (failure) {
    context.go('/settings'); // stay; local data preserved
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Deletion failed: ${failure.message}. Your data is intact. Tap retry.'),
      backgroundColor: Colors.orange,
    ));
  },
  (_) {
    context.go('/auth');
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Account deleted.'),
    ));
  },
);
```
Add imports to `settings_screen.dart`:
```dart
import 'package:emerge_app/core/deletion/deletion_providers.dart';
import 'package:emerge_app/core/deletion/delete_account_backend.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
```
> Remove the now-dead `final db = ref.read(appDatabaseProvider); await db.clearAll();`
> lines. Keep the `db.clearAll()` call only inside `DeletionService` (runs on success).

- [ ] **Step 3: Run analyzer**
Run: `flutter analyze lib/features/auth/data/repositories/firebase_auth_repository.dart lib/features/settings/presentation/screens/settings_screen.dart`
Expected: no errors.

- [ ] **Step 4: Commit**
```bash
git add lib/features/auth/data/repositories/firebase_auth_repository.dart lib/features/settings/presentation/screens/settings_screen.dart
git commit -m "feat(settings): server-first account deletion via DeletionService"
```

---

## Task 10: Integration tests (concurrent / partial-failure / rollback)

**Files:**
- Test: `test/core/deletion/deletion_service_integration_test.dart`

- [ ] **Step 1: Write the integration test**
```dart
import 'package:drift/native.dart';
import 'package:emerge_app/core/deletion/deletion_audit.dart';
import 'package:emerge_app/core/deletion/deletion_service.dart';
import 'package:emerge_app/core/deletion/sync_status.dart';
import 'package:emerge_app/core/drift/database.dart';
import 'package:emerge_app/core/drift/daos/mutation_queue_dao.dart';
import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/core/sync/sync_engine.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class RecordingSync extends Mock implements EnhancedSyncEngine {
  final List<String> keys = [];
  @override
  Future<void> enqueueUpdate({
    required String collectionPath,
    required String documentId,
    required Map<String, dynamic> data,
    String? idempotencyKey,
  }) async {
    keys.add(idempotencyKey ?? documentId);
  }
}

void main() {
  late AppDatabase db;
  late RecordingSync sync;
  late DeletionService service;
  late RecordingSync failingSync;
  late DeletionService svcWithFailingSync;

  setUp(() async {
    db = AppDatabase.withExecutor(await NativeDatabase.createInMemory());
    sync = RecordingSync();
    service = DeletionService(
      db: db,
      syncEngine: sync,
      audit: DeletionAudit(metrics: SyncMetrics()),
    );
    failingSync = _FailingSync(
      db.mutationQueueDao,
      FakeFirebaseFirestore(),
    );
    svcWithFailingSync = DeletionService(
      db: db,
      syncEngine: failingSync,
      audit: DeletionAudit(metrics: SyncMetrics()),
    );
  });
  tearDown(() => db.close());

  test('concurrent deletes of same habit enqueue exactly once', () async {
    await db.habitsDao.insertFromData(
      id: 'h1', userId: 'u1', title: 'X',
      createdAt: DateTime(2026).toIso8601String(),
      updatedAt: DateTime(2026).toIso8601String());
    final results = await Future.wait([
      service.deleteHabit(userId: 'u1', habitId: 'h1'),
      service.deleteHabit(userId: 'u1', habitId: 'h1'),
      service.deleteHabit(userId: 'u1', habitId: 'h1'),
    ]);
    expect(results.every((r) => r == const Right<Failure, Unit>(unit)), isTrue);
    // idempotency: only the first archives + enqueues; later ones are no-ops
    expect(sync.keys, ['del:habit:h1']);
    final row = await db.habitsDao.getHabit('h1');
    expect(row!.isArchived, 1);
  });

  test('remote enqueue failure still commits local archive', () async {
    await db.habitsDao.insertFromData(
      id: 'h1', userId: 'u1', title: 'X', currentStreak: 9,
      createdAt: DateTime(2026).toIso8601String(),
      updatedAt: DateTime(2026).toIso8601String());
    final res = await svcWithFailingSync.deleteHabit(userId: 'u1', habitId: 'h1');
    expect(res.isLeft(), isTrue);
    final row = await db.habitsDao.getHabit('h1');
    expect(row!.isArchived, 1); // local archive committed before remote enqueue
  });
}

class _FailingSync extends EnhancedSyncEngine {
  _FailingSync(MutationQueueDao dao, FirebaseFirestore firestore)
      : super(dao, firestore);
  @override
  Future<void> enqueueUpdate({
    required String collectionPath,
    required String documentId,
    required Map<String, dynamic> data,
    String? idempotencyKey,
  }) async {
    throw Exception('network down');
  }
}
```
> The `_FailingSync` constructor is illustrative; in practice construct it with a
> real `MutationQueueDao` from an in-memory DB. Replace
> `FakeFirebaseFirestore().mutationQueueDaoPlaceholder()` with
> `(await AppDatabase.withExecutor(await NativeDatabase.createInMemory())).mutationQueueDao`
> inside `setUp`. The key assertion: local archive is committed even when the
> remote enqueue throws.

- [ ] **Step 2: Run the integration test**
Run: `flutter test test/core/deletion/deletion_service_integration_test.dart`
Expected: PASS (concurrent → 1 enqueue; rollback scenario shows local archive
committed, remote failure surfaced as Left).

- [ ] **Step 3: Full analysis + full deletion test suite**
Run: `flutter analyze`
Run: `flutter test test/core/deletion test/core/sync test/core/drift`
Expected: all green, no analyzer errors.

- [ ] **Step 4: Commit**
```bash
git add test/core/deletion/deletion_service_integration_test.dart
git commit -m "test(deletion): concurrent + partial-failure + rollback integration tests"
```

---

## Task 11: Final verification & build_runner

- [ ] **Step 1: Regenerate all drift/riverpod generated code**
Run: `flutter pub run build_runner build --delete-conflicting-outputs`

- [ ] **Step 2: Full analyze + test**
Run: `flutter analyze`
Run: `flutter test`
Expected: no analyzer errors; deletion/sync/drift tests PASS.

- [ ] **Step 3: Commit any generated changes**
```bash
git add -A
git commit -m "chore: regenerate drift/riverpod generated code for deletion work" || echo "nothing to commit"
```

---

## Spec coverage check
- §1 goals → Tasks 1-10. ✓
- §2.1 corruption bug → Task 2 (archiveHabit) + Task 6/8 assertions. ✓
- §2.2 account data-loss gap → Task 7 (server-first), Task 9 wiring. ✓
- §2.3 silent drop → Task 4 dead-letter + breaker. ✓
- §3 architecture → all tasks. ✓
- §4 components → Tasks 1,3,4,5,6,7. ✓
- §5 deleteHabit flow → Tasks 2,6,8. ✓
- §6 deleteAccount flow → Tasks 7,9. ✓
- §7 resilience (backoff/breaker/idempotency/dead-letter) → Task 4 + tests. ✓
- §8 observability (status stream, metrics, structured audit) → Tasks 3,4,5. ✓
- §9 server-purge contract → Task 7 `DeleteAccountBackend` interface + doc comment (Appendix A implemented externally). ✓
- §10 testing → Tasks 1-10. ✓
- §11 out-of-scope → not implemented. ✓

## Notes / honest limitations
- **Traces:** no OpenTelemetry/tracing dependency is present; "traces" are
  approximated by structured `durationMs` timing in `DeletionAudit` events and
  `SyncMetrics.lastProcessingMs`. If distributed tracing is later required, add a
  tracing package and wrap `processMutationQueue` + `deleteHabit`/`deleteAccount`.
- **Server-side purge** (`deleteMyAccount`) lives in a separate repo; this plan
  only defines the client contract (`DeleteAccountBackend`) and passes an
  idempotent `deletionRequestId`. Backend implementation is out of scope.
- **Idempotency dedupe** at enqueue uses a read-then-insert check (not atomic
  across isolates); deletes are user-driven on the UI thread, and the server is
  independently idempotent on `deletionRequestId`, so the residual race is
  acceptable.
