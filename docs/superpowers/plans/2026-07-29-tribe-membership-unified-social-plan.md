# Tribe Membership & Unified Social Architecture — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix the club-not-showing-in-tribes bug and refactor the entire social architecture into a tribe-first, single-membership, offline-first system.

**Architecture:** Add a Drift `UserTribeTable` for local membership tracking. Create `TribeMembershipDao` and refactor `TribeMembershipService` as the single join/leave path. Convert `hasClubProvider` from `FutureProvider` to `StreamProvider`. Split `tribe_tab_content.dart` into focused screens. Wire all social features (friends, challenges, blueprints, creators, accountability) through tribe membership.

**Tech Stack:** Flutter 3.x, Riverpod (with codegen), Drift (SQLite), Firebase Firestore, EnhancedSyncEngine

## Global Constraints

- All repository methods return `Either<Failure, T>` from fpdart — never throw across the boundary
- All `@riverpod` annotations use auto-dispose unless `keepAlive: true`
- All Drift tables include a `userId` filter clause to prevent cross-user data leakage
- Every `AsyncValue` must handle all three branches (`loading`/`error`/`data`) + empty-array case
- Follow existing pattern: feature-first layout, Riverpod codegen, `part 'file.g.dart'` for generated files
- Run `dart run build_runner build --delete-conflicting-outputs` after any `.g.dart` generation change
- Run `dart analyze` before any commit — zero errors, zero warnings
- Always prefix migration steps with `schemaVersion` increment in `AppDatabase`

---

## File Structure

### New Files
1. `lib/core/drift/tables/user_tribe_table.dart` — Drift table for user-tribe membership
2. `lib/core/drift/daos/tribe_membership_dao.dart` — DAO for UserTribeTable CRUD + watch
3. `lib/core/drift/daos/tribe_membership_dao.g.dart` — Generated
4. `lib/features/social/presentation/screens/tribe_discovery_screen.dart` — Club grid for users without a tribe
5. `lib/features/social/presentation/screens/tribe_sanctum_tab.dart` — Emblem, stats, activity feed
6. `lib/features/social/presentation/screens/tribe_quests_tab.dart` — Active quests + featured quests
7. `lib/features/social/presentation/screens/tribe_members_tab.dart` — Leaderboard + member roster
8. `lib/features/social/presentation/screens/tribe_bonds_tab.dart` — Tribe-scoped accountability partners
9. `test/core/drift/daos/tribe_membership_dao_test.dart` — DAO unit tests
10. `test/features/social/domain/services/tribe_membership_service_test.dart` — Service tests

### Modified Files
1. `lib/core/drift/app_database.dart` — Add UserTribeTable, TribeMembershipDao, schema v11
2. `lib/core/drift/drift_native.dart` — Export tribe_membership_dao
3. `lib/core/drift/database.dart` — Add `tribeMembershipDaoProvider`
4. `lib/core/drift_repositories/drift_tribe_repository.dart` — `getUserTribes()` reads Drift first; `joinClub()` writes Drift membership
5. `lib/features/social/domain/services/tribe_membership_service.dart` — Refactor to use Drift DAO + full invalidation
6. `lib/features/social/presentation/providers/tribes_provider.dart` — `hasClubProvider` → StreamProvider
7. `lib/features/social/presentation/screens/tribe_tab_content.dart` — Extract screens, reduce to dispatcher
8. `lib/features/onboarding/presentation/screens/club_screen.dart` — Use `TribeMembershipService.joinTribe()`
9. `lib/features/social/presentation/screens/social_hub_screen.dart` — Use `watchActiveMembership()`
10. `functions/src/recalcTribes.ts` — Respect actual membership records, don't derive from archetype

---

### Task 1: Drift UserTribeTable + TribeMembershipDao

**Files:**
- Create: `lib/core/drift/tables/user_tribe_table.dart`
- Create: `lib/core/drift/daos/tribe_membership_dao.dart`
- Modify: `lib/core/drift/app_database.dart` (register table + DAO, schema v11)
- Modify: `lib/core/drift/drift_native.dart` (export dao)
- Test: `test/core/drift/daos/tribe_membership_dao_test.dart`

**Interfaces:**
- Consumes: `UserTribeTable` Drift table definition
- Produces: `TribeMembershipDao` with `watchActiveMembership(userId)`, `upsertMembership(companion)`, `deactivateAll(userId)`, `getMembership(userId, tribeId)`

- [ ] **Step 1: Create the UserTribeTable definition**

Write `lib/core/drift/tables/user_tribe_table.dart`:
```dart
import 'package:drift/drift.dart';

class UserTribeTable extends Table {
  TextColumn get userId => text()();
  TextColumn get tribeId => text()();
  TextColumn get membershipType => text()();
  TextColumn get joinedAt => text()();
  BoolColumn get isActive => boolean().withDefault(const Constant(false))();
  TextColumn get syncedAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {userId, tribeId};
}
```

- [ ] **Step 2: Create the TribeMembershipDao**

Write `lib/core/drift/daos/tribe_membership_dao.dart`:
```dart
import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/user_tribe_table.dart';

part 'tribe_membership_dao.g.dart';

@DriftAccessor(tables: [UserTribeTable])
class TribeMembershipDao extends DatabaseAccessor<AppDatabase>
    with _$TribeMembershipDaoMixin {
  TribeMembershipDao(super.db);

  Future<UserTribeTableData?> getMembership(String userId, String tribeId) {
    return (select(userTribeTable)
      ..where((t) => t.userId.equals(userId) & t.tribeId.equals(tribeId)))
        .getSingleOrNull();
  }

  Stream<UserTribeTableData?> watchActiveMembership(String userId) {
    return (select(userTribeTable)
      ..where((t) => t.userId.equals(userId) & t.isActive.equals(true)))
        .watchSingleOrNull();
  }

  Future<void> upsertMembership(Insertable<UserTribeTableData> entry) {
    return into(userTribeTable).insertOnConflictUpdate(entry);
  }

  Future<void> deactivateAll(String userId) async {
    await (update(userTribeTable)
      ..where((t) => t.userId.equals(userId)))
        .write(const UserTribeTableCompanion(isActive: Value(false)));
  }

  Future<void> removeMembership(String userId, String tribeId) async {
    await (delete(userTribeTable)
      ..where((t) => t.userId.equals(userId) & t.tribeId.equals(tribeId)))
        .go();
  }
}
```

- [ ] **Step 3: Write the failing DAO test**

Write `test/core/drift/daos/tribe_membership_dao_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:emerge_app/core/drift/app_database.dart';
import 'package:emerge_app/core/drift/tables/user_tribe_table.dart';
import 'package:emerge_app/core/drift/daos/tribe_membership_dao.dart';

void main() {
  late AppDatabase db;
  late TribeMembershipDao dao;

  setUp(() async {
    db = AppDatabase.withExecutor(NativeDatabase.memory());
    dao = TribeMembershipDao(db);
    await dao.upsertMembership(UserTribeTableCompanion(
      userId: const Value('user1'),
      tribeId: const Value('morning_warriors'),
      membershipType: const Value('archetype'),
      joinedAt: Value(DateTime.now().toIso8601String()),
      isActive: const Value(true),
    ));
  });

  tearDown(() => db.close());

  test('watchActiveMembership returns active tribe', () async {
    final membership = await dao.watchActiveMembership('user1').first;
    expect(membership, isNotNull);
    expect(membership!.tribeId, 'morning_warriors');
    expect(membership.isActive, true);
  });

  test('deactivateAll sets all to inactive', () async {
    await dao.deactivateAll('user1');
    final membership = await dao.watchActiveMembership('user1').first;
    expect(membership, isNull);
  });

  test('upsertMembership updates existing row', () async {
    await dao.upsertMembership(UserTribeTableCompanion(
      userId: const Value('user1'),
      tribeId: const Value('morning_warriors'),
      membershipType: const Value('creator'),
      joinedAt: Value(DateTime.now().toIso8601String()),
      isActive: const Value(true),
    ));
    final membership = await dao.watchActiveMembership('user1').first;
    expect(membership!.membershipType, 'creator');
  });

  test('removeMembership deletes the row', () async {
    await dao.removeMembership('user1', 'morning_warriors');
    final membership = await dao.watchActiveMembership('user1').first;
    expect(membership, isNull);
  });
}
```

Run: `flutter test test/core/drift/daos/tribe_membership_dao_test.dart`
Expected: FAIL — `TribeMembershipDao` not found (no `.g.dart` yet)

- [ ] **Step 4: Register table + DAO in AppDatabase**

Modify `lib/core/drift/app_database.dart`:
```dart
import 'tables/user_tribe_table.dart';
// ... after other table imports

import 'daos/tribe_membership_dao.dart';
// ... after other dao imports
```

Add to `@DriftDatabase`:
```dart
@DriftDatabase(
  tables: [
    // ... existing tables
    UserTribeTable,
  ],
  daos: [
    // ... existing daos
    TribeMembershipDao,
  ],
)
```

Increment `schemaVersion` to 11. Add migration:
```dart
if (from < 11) {
  await m.createTable(userTribeTable);
}
```

- [ ] **Step 5: Export in drift_native.dart**

Add to `lib/core/drift/drift_native.dart`:
```dart
export 'daos/tribe_membership_dao.dart';
```

- [ ] **Step 6: Add DAO provider in database.dart**

Add to `lib/core/drift/database.dart`:
```dart
@Riverpod(keepAlive: true)
TribeMembershipDao tribeMembershipDao(Ref ref) {
  return ref.watch(appDatabaseProvider).tribeMembershipDao;
}
```

- [ ] **Step 7: Run build_runner + tests**

Run:
```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/core/drift/daos/tribe_membership_dao_test.dart
```

Expected: All tests PASS

- [ ] **Step 8: Commit**

```bash
git add lib/core/drift/tables/user_tribe_table.dart \
       lib/core/drift/daos/tribe_membership_dao.dart \
       lib/core/drift/daos/tribe_membership_dao.g.dart \
       lib/core/drift/app_database.dart \
       lib/core/drift/drift_native.dart \
       lib/core/drift/database.dart \
       test/core/drift/daos/tribe_membership_dao_test.dart
git commit -m "feat: add UserTribeTable + TribeMembershipDao for local membership tracking"
```

---

### Task 2: Refactor TribeMembershipService

**Files:**
- Modify: `lib/features/social/domain/services/tribe_membership_service.dart`
- Test: `test/features/social/domain/services/tribe_membership_service_test.dart`

**Interfaces:**
- Consumes: `TribeMembershipDao`, `DriftTribeRepository`, `EnhancedSyncEngine`
- Produces: `TribeMembershipService.joinTribe(userId, tribeId, type)` and `leaveTribe(userId)` with full invalidation

- [ ] **Step 1: Write the failing service test**

Write `test/features/social/domain/services/tribe_membership_service_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:emerge_app/core/drift/app_database.dart';
import 'package:emerge_app/core/sync/sync_engine.dart';
import 'package:emerge_app/features/social/domain/services/tribe_membership_service.dart';
import 'package:emerge_app/features/social/data/repositories/tribe_repository.dart';
import 'package:emerge_app/core/drift_repositories/drift_tribe_repository.dart';

void main() {
  late AppDatabase db;
  late FakeFirebaseFirestore firestore;
  late EnhancedSyncEngine syncEngine;
  late TribeRepository repository;
  late TribeMembershipService service;

  setUp(() async {
    db = AppDatabase.withExecutor(NativeDatabase.memory());
    firestore = FakeFirebaseFirestore();
    syncEngine = EnhancedSyncEngine(
      db.mutationQueueDao,
      firestore,
    );
    repository = DriftTribeRepository(db, syncEngine, firestore);
    service = TribeMembershipService(repository, db.tribeMembershipDao, syncEngine);
  });

  tearDown(() => db.close());

  test('joinTribe writes Drift membership + enqueues sync', () async {
    await service.joinTribe(
      userId: 'user1',
      tribeId: 'morning_warriors',
      type: 'archetype',
    );
    final membership = await db.tribeMembershipDao.watchActiveMembership('user1').first;
    expect(membership, isNotNull);
    expect(membership!.tribeId, 'morning_warriors');
    expect(membership.isActive, true);
  });

  test('joinTribe enqueues Firestore sync operations', () async {
    await service.joinTribe(
      userId: 'user1',
      tribeId: 'morning_warriors',
      type: 'archetype',
    );
    final queue = await db.mutationQueueDao.getAll();
    expect(queue.length, greaterThanOrEqualTo(3)); // user tribes + contributor + tribe doc
  });

  test('leaveTribe deactivates membership', () async {
    await service.joinTribe(
      userId: 'user1',
      tribeId: 'morning_warriors',
      type: 'archetype',
    );
    await service.leaveTribe('user1');
    final membership = await db.tribeMembershipDao.watchActiveMembership('user1').first;
    expect(membership, isNull);
  });
}
```

Run: `flutter test test/features/social/domain/services/tribe_membership_service_test.dart`
Expected: FAIL — service methods don't match new signature

- [ ] **Step 2: Rewrite TribeMembershipService**

Write new `lib/features/social/domain/services/tribe_membership_service.dart`:
```dart
import 'package:emerge_app/core/drift/daos/tribe_membership_dao.dart';
import 'package:emerge_app/core/drift/tables/user_tribe_table.dart';
import 'package:emerge_app/core/sync/sync_engine.dart';
import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:emerge_app/features/social/data/repositories/tribe_repository.dart';
import 'package:emerge_app/features/social/domain/models/tribe.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';

class TribeMembershipService {
  final TribeRepository _repository;
  final TribeMembershipDao _dao;
  final EnhancedSyncEngine _syncEngine;
  final Ref? _ref;

  TribeMembershipService(
    this._repository,
    this._dao,
    this._syncEngine, [
    this._ref,
  ]);

  Future<Either<Failure, void>> joinTribe({
    required String userId,
    required String tribeId,
    required String type,
  }) async {
    try {
      // 1. Check not already in a tribe
      final existing = await _dao.watchActiveMembership(userId).first;
      if (existing != null) {
        return Left(Failure('Already in tribe ${existing.tribeId}'));
      }

      // 2. Drift: deactivate all (safety) + upsert active
      await _dao.deactivateAll(userId);
      await _dao.upsertMembership(UserTribeTableCompanion(
        userId: Value(userId),
        tribeId: Value(tribeId),
        membershipType: Value(type),
        joinedAt: Value(DateTime.now().toIso8601String()),
        isActive: const Value(true),
      ));

      // 3. Sync: enqueue Firestore writes
      await _syncEngine.enqueueSet(
        collectionPath: 'users/$userId/tribes',
        documentId: tribeId,
        data: {
          'tribeId': tribeId,
          'joinedAt': {'__type__': 'serverTimestamp'},
          'membershipType': type,
        },
      );
      await _syncEngine.enqueueSet(
        collectionPath: 'tribes/$tribeId/contributors',
        documentId: userId,
        data: {
          'userId': userId,
          'joinedAt': {'__type__': 'serverTimestamp'},
          'contributionCount': 0,
          'totalHabitsCompleted': 0,
          'totalXpContributed': 0,
        },
      );
      await _syncEngine.enqueueSet(
        collectionPath: 'tribes',
        documentId: tribeId,
        data: {
          'members': {
            '__type__': 'arrayUnion',
            'values': [userId],
          },
          'memberCount': {'__type__': 'increment', 'value': 1},
          'lastStatsSync': {'__type__': 'serverTimestamp'},
        },
      );

      // 4. Invalidate providers (if Ref available)
      _ref?.invalidate(hasClubProvider);
      _ref?.invalidate(discoveryClubsProvider);

      return const Right(null);
    } catch (e, s) {
      AppLogger.e('joinTribe failed', e, s);
      return Left(Failure('Failed to join tribe: $e'));
    }
  }

  Future<Either<Failure, void>> leaveTribe(String userId) async {
    try {
      final active = await _dao.watchActiveMembership(userId).first;
      if (active == null) {
        return const Left(Failure('Not in a tribe'));
      }

      final tribeId = active.tribeId;
      await _dao.deactivateAll(userId);

      await _syncEngine.enqueueMutation(
        collectionPath: 'users/$userId/tribes',
        documentId: tribeId,
        operation: 'delete',
      );
      await _syncEngine.enqueueSet(
        collectionPath: 'tribes',
        documentId: tribeId,
        data: {
          'members': {
            '__type__': 'arrayRemove',
            'values': [userId],
          },
          'memberCount': {'__type__': 'increment', 'value': -1},
        },
      );

      _ref?.invalidate(hasClubProvider);
      _ref?.invalidate(discoveryClubsProvider);

      return const Right(null);
    } catch (e, s) {
      AppLogger.e('leaveTribe failed', e, s);
      return Left(Failure('Failed to leave tribe: $e'));
    }
  }

  Future<bool> isInTribe(String userId) async {
    final membership = await _dao.watchActiveMembership(userId).first;
    return membership != null;
  }

  Stream<UserTribeTableData?> watchActiveMembership(String userId) {
    return _dao.watchActiveMembership(userId);
  }
}

final tribeMembershipServiceProvider = Provider<TribeMembershipService>((ref) {
  final repository = ref.watch(tribeRepositoryProvider);
  final dao = ref.watch(tribeMembershipDaoProvider);
  final syncEngine = ref.watch(enhancedSyncEngineProvider);
  return TribeMembershipService(repository, dao, syncEngine, ref);
});
```

- [ ] **Step 3: Run tests**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/features/social/domain/services/tribe_membership_service_test.dart
```

Expected: All tests PASS

- [ ] **Step 4: Commit**

```bash
git add lib/features/social/domain/services/tribe_membership_service.dart \
       test/features/social/domain/services/tribe_membership_service_test.dart
git commit -m "refactor: TribeMembershipService with Drift-first join/leave + invalidation"
```

---

### Task 3: Update DriftTribeRepository — getUserTribes local-first

**Files:**
- Modify: `lib/core/drift_repositories/drift_tribe_repository.dart`

**Interfaces:**
- Consumes: `TribeMembershipDao`, `TribeStatsDao`
- Produces: `getUserTribes()` returns from Drift membership immediately, falls back to Firestore sync

- [ ] **Step 1: Modify getUserTribes to read Drift first**

In `lib/core/drift_repositories/drift_tribe_repository.dart`, update `getUserTribes`:
```dart
@override
Future<List<Tribe>> getUserTribes(String userId) async {
  // 1. Read active membership from Drift (instant, offline-first)
  final membership = await _db.tribeMembershipDao.watchActiveMembership(userId).first;
  if (membership != null) {
    final row = await _db.tribeStatsDao.getStats(membership.tribeId);
    if (row != null) return [_rowToTribe(row)];
  }

  // 2. Fallback: sync from Firestore and cache locally
  try {
    final tribeDocs = await _firestore
        .collection('tribes')
        .where('members', arrayContains: userId)
        .get();
    if (tribeDocs.docs.isEmpty) return [];
    final tribes = tribeDocs.docs.map((doc) => Tribe.fromMap(doc.data())).toList();
    // Cache each found tribe into local membership
    for (final tribe in tribes) {
      await _db.tribeMembershipDao.upsertMembership(UserTribeTableCompanion(
        userId: Value(userId),
        tribeId: Value(tribe.id),
        membershipType: Value(tribe.archetypeId != null ? 'archetype' : 'creator'),
        joinedAt: Value(DateTime.now().toIso8601String()),
        isActive: const Value(true),
      ));
    }
    return tribes;
  } catch (e) {
    debugPrint('getUserTribes Firestore fallback failed: $e');
    return [];
  }
}
```

- [ ] **Step 3: Simplify joinClub in DriftTribeRepository**

The `DriftTribeRepository.joinClub` should still work as fallback, but the primary path is now `TribeMembershipService.joinTribe`. Keep the existing implementation (lines 390-435) as-is for backward compatibility but add the Drift membership write:

Add after `incrementMemberCount` call (line 392):
```dart
await _db.tribeMembershipDao.upsertMembership(UserTribeTableCompanion(
  userId: Value(userId),
  tribeId: Value(tribeId),
  membershipType: const Value('archetype'),
  joinedAt: Value(DateTime.now().toIso8601String()),
  isActive: const Value(true),
));
```

- [ ] **Step 4: Verify static analysis**

```bash
dart analyze lib/core/drift_repositories/drift_tribe_repository.dart
```

Expected: 0 errors, 0 warnings

- [ ] **Step 5: Commit**

```bash
git add lib/core/drift_repositories/drift_tribe_repository.dart
git commit -m "fix: getUserTribes reads Drift first for offline-first membership"
```

---

### Task 4: Convert hasClubProvider to StreamProvider + Rewire ClubScreen

**Files:**
- Modify: `lib/features/social/presentation/providers/tribes_provider.dart`
- Modify: `lib/features/social/presentation/screens/tribe_tab_content.dart` (remove old hasClubProvider, use new one)
- Modify: `lib/features/onboarding/presentation/screens/club_screen.dart`

**Interfaces:**
- Consumes: `TribeMembershipDao`, `TribeMembershipService`
- Produces: Reactive `hasClubProvider`, `ClubScreen` using `TribeMembershipService.joinTribe()`

- [ ] **Step 1: Replace hasClubProvider in tribes_provider.dart**

Remove the existing `FutureProvider` (lines 50-62) and add a `StreamProvider` at the bottom of `tribes_provider.dart`:
```dart
/// Whether the signed-in user belongs to any club.
///
/// Reactive stream from Drift [TribeMembershipDao.watchActiveMembership].
/// Returns false while signed out or loading. Never throws.
final hasClubProvider = StreamProvider<bool>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final userId = authState.value?.id;
  if (userId == null || userId.isEmpty) return Stream.value(false);
  final dao = ref.watch(tribeMembershipDaoProvider);
  return dao.watchActiveMembership(userId).map((m) => m != null);
});
```

- [ ] **Step 2: Update tribe_tab_content.dart to use StreamProvider**

Change line 147 from:
```dart
final hasClubAsync = ref.watch(hasClubProvider);
```
to use the new `StreamProvider` — `hasClubAsync` is already destructured correctly as it was already using `.when()`.

Update the `_joinClub` method (line 351) to use `TribeMembershipService`:
```dart
Future<void> _joinClub(Tribe club) async {
  final authUser = ref.read(authStateChangesProvider).value;
  final userId = authUser?.id;
  if (userId == null || userId.isEmpty) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sign in to join a club')),
    );
    return;
  }
  if (!mounted) return;
  if (await clubJoinBlockedByFreeTier(ref, context, userId)) return;
  if (!mounted) return;
  try {
    final service = ref.read(tribeMembershipServiceProvider);
    final result = await service.joinTribe(
      userId: userId,
      tribeId: club.id,
      type: club.archetypeId != null ? 'archetype' : 'creator',
    );
    result.fold(
      (failure) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to join: ${failure.message}')),
        );
      },
      (_) {
        ref.invalidate(discoveryClubsProvider);
      },
    );
  } catch (e, s) {
    AppLogger.e('TribeTabContent: joinClub failed', e, s);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to join: $e')),
    );
  }
}
```

- [ ] **Step 3: Rewire ClubScreen to use TribeMembershipService**

Modify `lib/features/onboarding/presentation/screens/club_screen.dart` `_joinClub` method:
```dart
Future<void> _joinClub(Tribe club) async {
  if (_isSaving) return;
  setState(() => _isSaving = true);
  try {
    // State-side record
    await ref.read(enhancedOnboardingProvider.notifier).setClub(club.id);

    // Membership via unified service
    final user = ref.read(authStateChangesProvider).value;
    if (user != null && user.isNotEmpty) {
      try {
        final service = ref.read(tribeMembershipServiceProvider);
        final result = await service.joinTribe(
          userId: user.id,
          tribeId: club.id,
          type: club.archetypeId != null ? 'archetype' : 'creator',
        );
        result.fold(
          (failure) {
            AppLogger.e('ClubScreen: joinTribe failed', failure.message);
          },
          (_) {},
        );
      } catch (e, s) {
        AppLogger.e('ClubScreen: joinClub failed', e, s);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not join ${club.name}. Retrying…'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }

    await ref
        .read(enhancedOnboardingProvider.notifier)
        .completeMilestone(2);

    if (!mounted) return;
    context.push('/onboarding/first-habits');
  } catch (e, s) {
    AppLogger.e('ClubScreen: failed to save', e, s);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to save: $e')),
    );
    setState(() => _isSaving = false);
  }
}
```

- [ ] **Step 4: Update SocialHubScreen**

Modify `social_hub_screen.dart` to use `watchActiveMembership()` instead of archetype resolution:

Replace the `ref.listen(currentArchetypeProvider, ...)` block with:
```dart
ref.listen(hasClubProvider, (prev, next) {
  next.whenData((hasClub) {
    if (hasClub && !_navigatedToTribe) {
      _navigatedToTribe = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateToUserTribe();
      });
    } else if (!hasClub) {
      _navigatedToTribe = false;
    }
  });
});
```

Update `_navigateToUserTribe` to resolve from Drift:
```dart
Future<void> _navigateToUserTribe() async {
  final userId = ref.read(authStateChangesProvider).value?.id;
  if (userId == null) return;
  final dao = ref.read(tribeMembershipDaoProvider);
  final membership = await dao.watchActiveMembership(userId).first;
  if (membership != null && context.mounted) {
    context.go('/social/tribe/${membership.tribeId}');
  }
}
```

- [ ] **Step 5: Verify**

```bash
dart analyze
```

Expected: 0 errors, 0 warnings

- [ ] **Step 6: Commit**

```bash
git add lib/features/social/presentation/providers/tribes_provider.dart \
       lib/features/social/presentation/screens/tribe_tab_content.dart \
       lib/features/onboarding/presentation/screens/club_screen.dart \
       lib/features/social/presentation/screens/social_hub_screen.dart
git commit -m "fix: hasClubProvider → StreamProvider, ClubScreen/SocialHubScreen use TribeMembershipService"
```

---

### Task 5: Update recalcTribes Cloud Function

**Files:**
- Modify: `functions/src/recalcTribes.ts`

- [ ] **Step 1: Update recalcTribes to respect actual membership**

Modify `functions/src/recalcTribes.ts`:

Key change: query `users/{uid}/tribes` subcollection for actual membership. Only assign by archetype for users with NO explicit membership.

```typescript
// After building userToTribeMap from archetype, query membership records:
const userMembershipMap = new Map<string, { tribeId: string }>();

await new Promise((resolve, reject) => {
  // Scan all users' tribe subcollections
  db.collectionGroup("tribes")
    .stream()
    .on("data", (doc: admin.firestore.QueryDocumentSnapshot) => {
      const data = doc.data();
      const ref = doc.ref.path; // "users/{uid}/tribes/{tribeId}"
      const parts = ref.split("/");
      if (parts.length === 4 && parts[0] === "users" && parts[2] === "tribes") {
        const uid = parts[1];
        const tribeId = parts[3];
        userMembershipMap.set(uid, { tribeId });
      }
    })
    .on("end", resolve)
    .on("error", reject);
});

// Then, when populating tribeMembers, respect actual membership:
// For users with explicit membership, use that.
// For users without, fall back to archetype mapping.
for (const [uid, archetype] of userToTribeMap.entries()) {
  const membership = userMembershipMap.get(uid);
  const clubId = membership ? membership.tribeId : archetype;
  const members = tribeMembers.get(clubId);
  if (members) members.push(uid);
}
```

Replace the entire `recalcTribesInternal` function with this updated version.

- [ ] **Step 2: Verify TypeScript compilation**

```bash
cd functions && npx tsc --noEmit
```

Expected: 0 errors

- [ ] **Step 3: Commit**

```bash
git add functions/src/recalcTribes.ts
git commit -m "fix: recalcTribes respects actual tribe membership records"
```

---

### Task 6: Split tribe_tab_content.dart (Phase 3)

**Files:**
- Create: `lib/features/social/presentation/screens/tribe_discovery_screen.dart`
- Create: `lib/features/social/presentation/screens/tribe_sanctum_tab.dart`
- Create: `lib/features/social/presentation/screens/tribe_quests_tab.dart`
- Create: `lib/features/social/presentation/screens/tribe_members_tab.dart`
- Create: `lib/features/social/presentation/screens/tribe_bonds_tab.dart`
- Modify: `lib/features/social/presentation/screens/tribe_tab_content.dart` (reduce to dispatcher)

- [ ] **Step 1: Extract `tribe_discovery_screen.dart`**

Move the discovery view logic (`_buildDiscoveryView`, `_filterClubs`, `_buildSearchBar`, `_buildFilterChips`, `_showPreviewSheet`, `_joinClub`) into a standalone `ConsumerStatefulWidget` called `TribeDiscoveryScreen`.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/features/social/domain/models/tribe.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';
// ... other imports

class TribeDiscoveryScreen extends ConsumerStatefulWidget {
  const TribeDiscoveryScreen({super.key});
  @override
  ConsumerState<TribeDiscoveryScreen> createState() => _TribeDiscoveryScreenState();
}

class _TribeDiscoveryScreenState extends ConsumerState<TribeDiscoveryScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final clubsAsync = ref.watch(discoveryClubsProvider);
    return clubsAsync.when(
      data: (clubs) { /* grid with _filterClubs, search, filter chips */ },
      loading: () => const EmergeLoadingSkeleton(itemCount: 6),
      error: (err, _) => /* error state */,
    );
  }
  // ... _filterClubs, _showPreviewSheet, _joinClub methods
}
```

- [ ] **Step 2: Extract `tribe_sanctum_tab.dart`**

Move the SANCTUM tab content (emblem, stats bar, activity feed toggle). This is roughly lines 400-600 of tribe_tab_content.dart.

- [ ] **Step 3: Extract `tribe_quests_tab.dart`**

Move the QUESTS tab content (quests sections). Uses `TribeYourQuestsSection` and `TribeQuestsForYouSection` widgets that already exist.

- [ ] **Step 4: Extract `tribe_members_tab.dart`**

Move the MEMBERS tab content (contributor rankings, leaderboard, "SEE ALL TRIBES" button).

- [ ] **Step 5: Extract `tribe_bonds_tab.dart`**

Move the BONDS tab content (accountability partners section). Uses `TribeAccountabilitySection`.

- [ ] **Step 6: Reduce `tribe_tab_content.dart` to dispatcher**

After extracting all 5 screens, `tribe_tab_content.dart` becomes a simple `DefaultTabController` that renders them:

```dart
return hasClubAsync.when(
  data: (hasClub) {
    if (!hasClub) return const TribeDiscoveryScreen();
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: TabBar(
          tabs: const [
            Tab(text: 'SANCTUM'),
            Tab(text: 'QUESTS'),
            Tab(text: 'MEMBERS'),
            Tab(text: 'BONDS'),
          ],
        ),
        body: const TabBarView(
          children: [
            TribeSanctumTab(),
            TribeQuestsTab(),
            TribeMembersTab(),
            TribeBondsTab(),
          ],
        ),
      ),
    );
  },
  loading: () => const EmergeLoadingSkeleton(itemCount: 5),
  error: (_, _) => const TribeSanctumTab(),
);
```

- [ ] **Step 7: Verify**

```bash
dart analyze lib/features/social/presentation/screens/
```

Expected: 0 errors, 0 warnings

- [ ] **Step 8: Commit**

```bash
git add lib/features/social/presentation/screens/tribe_discovery_screen.dart \
       lib/features/social/presentation/screens/tribe_sanctum_tab.dart \
       lib/features/social/presentation/screens/tribe_quests_tab.dart \
       lib/features/social/presentation/screens/tribe_members_tab.dart \
       lib/features/social/presentation/screens/tribe_bonds_tab.dart \
       lib/features/social/presentation/screens/tribe_tab_content.dart
git commit -m "refactor: split tribe_tab_content.dart into 5 focused screens"
```

---

### Task 7: Feature Integration — Tribe-Scoped Providers (Phase 4)

**Files:**
- Modify: `lib/features/social/presentation/providers/tribes_provider.dart`
- Modify: `lib/features/social/presentation/providers/friend_provider.dart` (add tribeCircleProvider)
- Modify: `lib/features/social/presentation/providers/challenge_provider.dart` (add tribeChallengesProvider)
- Modify: `lib/features/social/presentation/providers/tribe_blueprints_provider.dart` (enhance)
- Modify: `lib/features/social/presentation/providers/creator_provider.dart` (add tribeCreatorsProvider)

- [ ] **Step 1: Add `activeMembershipProvider` to tribes_provider.dart**

```dart
final activeMembershipProvider = StreamProvider<UserTribeTableData?>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(null);
  final dao = ref.watch(tribeMembershipDaoProvider);
  return dao.watchActiveMembership(userId);
});
```

- [ ] **Step 2: Add `tribeCircleProvider` to friend_provider.dart**

```dart
final tribeCircleProvider = StreamProvider<List<Friend>>((ref) {
  final membership = ref.watch(activeMembershipProvider);
  return membership.switchMap((m) {
    if (m == null) return Stream.value([]);
    return ref.watch(partnersListProvider).map((partners) {
      return partners.where((p) => true).toList(); // Filter by tribe when Friend has tribeId
    });
  });
});
```

- [ ] **Step 3: Add `tribeChallengesProvider` to challenge_provider.dart**

```dart
final tribeChallengesProvider = StreamProvider<List<Challenge>>((ref) {
  final membership = ref.watch(activeMembershipProvider);
  return membership.switchMap((m) {
    if (m == null) return Stream.value([]);
    final repo = ref.watch(challengeRepositoryProvider);
    return repo.watchByTribe(m.tribeId);
  });
});
```

- [ ] **Step 4: Enhance `tribeBlueprintsProvider`**

In `tribe_blueprints_provider.dart`, add tribe-specific curation by subscribing to `activeMembershipProvider` instead of just archetype.

- [ ] **Step 5: Add `tribeCreatorsProvider` to creator_provider.dart**

```dart
final tribeCreatorsProvider = StreamProvider<List<CreatorProfile>>((ref) {
  final membership = ref.watch(activeMembershipProvider);
  return membership.switchMap((m) {
    if (m == null) return Stream.value([]);
    final repo = ref.watch(creatorRepositoryProvider);
    return repo.watchByTribe(m.tribeId);
  });
});
```

- [ ] **Step 6: Wire into TribeLobbyScreen**

Update `TribeLobbyScreen` sections to use the new tribe-scoped providers:
- Circle section → `tribeCircleProvider`
- Quests section → `tribeChallengesProvider`
- Creators strip → `tribeCreatorsProvider`

- [ ] **Step 7: Verify**

```bash
dart analyze
```

Expected: 0 errors, 0 warnings

- [ ] **Step 8: Commit**

```bash
git add lib/features/social/presentation/providers/tribes_provider.dart \
       lib/features/social/presentation/providers/friend_provider.dart \
       lib/features/social/presentation/providers/challenge_provider.dart \
       lib/features/social/presentation/providers/tribe_blueprints_provider.dart \
       lib/features/social/presentation/providers/creator_provider.dart
git commit -m "feat: tribe-scoped providers for friends, challenges, blueprints, creators"
```

---

### Task 8: Regression Tests & Verification

- [ ] **Step 1: Run full analysis**

```bash
dart analyze
```

Expected: 0 errors, 0 warnings across project

- [ ] **Step 2: Run focused tests**

```bash
flutter test test/core/drift/daos/tribe_membership_dao_test.dart
flutter test test/features/social/domain/services/tribe_membership_service_test.dart
flutter test test/features/social/presentation/providers/
flutter test test/features/social/presentation/screens/
```

Expected: All passing

- [ ] **Step 3: Run onboarding tests**

```bash
flutter test test/features/onboarding/presentation/screens/club_screen_test.dart
```

Expected: All passing (update test expectations if needed)

- [ ] **Step 4: Verify build**

```bash
flutter build apk --debug
# or
flutter build web
```

Expected: Build completes successfully
