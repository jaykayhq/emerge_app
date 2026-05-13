# Local-First Game Loop Architecture

**Date**: 2026-05-13
**Status**: Draft
**Author**: Senior Flutter Architect, Identity-First UX Strategy

---

## 1. Problem Statement

The current Emerge app architecture is Firestore-first. Every habit completion triggers ~30-40 Firestore operations across 4 separate transactions:

1. `FirestoreHabitRepository.completeHabit()` — reads/writes habit doc + world health via transaction
2. `SocialActivityService.logHabitCompletion()` — 6 writes across global/club activity, tribe counters, contributor stats, club leaderboard, user_stats via transaction
3. `FirestoreChallengeRepository.updateProgress()` or `completeChallengeWithReward()` — reads challenge + user_stats, writes XP + status via transaction
4. `FirestoreGamificationRepository.addXp()` — reads/writes avatarStats + level via separate transaction

**Consequences**:
- **No offline support** for the core action loop — user completes habit, sees nothing if offline
- **Latency compounding** — 300ms+ per transaction × 4 = 1.2s+ before UI reflects progress
- **Redundant compute** — XP calculation logic exists in 3+ places (`GamificationService.addXp`, `FirestoreGamificationRepository.addXp`, `ChallengeRepository.updateProgress`)
- **Firestore costs** — every completion reads and re-reads the same `user_stats` document

## 2. Target Architecture

```
[UI / Riverpod Providers] ←reads from← [Drift*Repositories] ←syncs to→ [Firestore (backup)]
                                          ↓                        ↓
                                     [Drift SQLite DB]       [SyncEngine → Firestore Batch]
                                          ↑
                                     [LocalGameLoopEngine]
                                          ↑
                                     [User Action: habit complete, challenge progress, etc.]
```

### Data Flow

**Write path** (local-first):
1. User action → repository method
2. Repository calls `LocalGameLoopEngine` to compute all derived state (pure Dart, no I/O)
3. Repository writes ALL changes to Drift in a single SQLite transaction
4. Drift reactive streams emit → Riverpod providers emit → UI updates in <1ms
5. Repository enqueues a single mutation to `mutation_queue` table

**Read path** (always reactive):
1. Widget watches Riverpod `StreamProvider`
2. Provider delegates to `Drift*Repository.watch*()` which wraps `drift.watchXxx()`
3. Drift emits whenever the underlying SQLite table changes
4. First emission is instant (from local DB), no network wait

**Sync path** (asynchronous):
1. `EnhancedSyncEngine` reads `mutation_queue` ordered by `created_at`
2. Groups mutations by collection for Firestore batch writes
3. After successful Firestore write, marks record as `synced_at`
4. On conflict: compare `updated_at` timestamps, newest wins

## 3. Drift Schema (8 tables)

### `user_stats`
Single row per user. Flat columns for reactive attribute-level watching.

| Column | Type | Description |
|--------|------|-------------|
| user_id | TEXT PK | Firebase Auth UID |
| total_xp | INTEGER | Sum of all attribute XP |
| level | INTEGER | Derived from total XP |
| streak | INTEGER | Current global streak |
| strength_xp | INTEGER | |
| intellect_xp | INTEGER | |
| vitality_xp | INTEGER | |
| creativity_xp | INTEGER | |
| focus_xp | INTEGER | |
| spirit_xp | INTEGER | |
| challenge_xp | INTEGER | XP from completed challenges |
| world_health_score | REAL | 0.0–1.0 |
| archetype | TEXT | User archetype (athlete, scholar, etc.) |
| avatar_json | TEXT | JSON blob for avatar state |
| world_state_json | TEXT | JSON blob for world state |
| updated_at | TEXT | ISO8601 |
| synced_at | TEXT | ISO8601, null if unsynced |

### `habits`
Full local mirror of Firestore habits collection.

| Column | Type |
|--------|------|
| id | TEXT PK |
| user_id | TEXT NOT NULL |
| title | TEXT NOT NULL |
| cue | TEXT |
| routine | TEXT |
| reward | TEXT |
| frequency | TEXT |
| difficulty | TEXT |
| attribute | TEXT |
| current_streak | INTEGER |
| longest_streak | INTEGER |
| momentum_score | INTEGER |
| consecutive_misses | INTEGER |
| last_completed_date | TEXT |
| is_archived | INTEGER |
| created_at | TEXT |
| updated_at | TEXT |
| synced_at | TEXT |

### `habit_completions`
Immutable event log. Each completion = one row. Enables offline leaderboard/challenge computation.

| Column | Type |
|--------|------|
| id | TEXT PK |
| habit_id | TEXT NOT NULL |
| user_id | TEXT NOT NULL |
| completed_at | TEXT NOT NULL |
| xp_gained | INTEGER |
| attribute | TEXT |
| momentum_at_completion | INTEGER |
| streak_day | INTEGER |
| was_recovery | INTEGER |
| synced_at | TEXT |

### `challenge_progress`
Tracks each challenge the user has joined and their progress.

| Column | Type |
|--------|------|
| challenge_id | TEXT PK |
| user_id | TEXT NOT NULL |
| title | TEXT |
| attribute | TEXT |
| current_day | INTEGER |
| total_days | INTEGER |
| status | TEXT |
| xp_reward | INTEGER |
| joined_at | TEXT |
| updated_at | TEXT |
| synced_at | TEXT |

### `tribe_stats`
Local snapshot of user's archetype tribe.

| Column | Type |
|--------|------|
| tribe_id | TEXT PK |
| tribe_name | TEXT |
| archetype_id | TEXT |
| member_count | INTEGER |
| total_xp | INTEGER |
| total_habits_completed | INTEGER |
| total_challenges_completed | INTEGER |
| user_contribution_xp | INTEGER |
| user_habits_completed | INTEGER |
| user_challenges_completed | INTEGER |
| updated_at | TEXT |
| synced_at | TEXT |

### `leaderboard_entries`
Local snapshot of tribe/club leaderboard.

| Column | Type |
|--------|------|
| id | TEXT PK (userId_tribeId) |
| tribe_id | TEXT NOT NULL |
| user_id | TEXT NOT NULL |
| user_name | TEXT |
| xp | INTEGER |
| level | INTEGER |
| rank | INTEGER |
| archetype | TEXT |
| updated_at | TEXT |
| synced_at | TEXT |

### `blueprints`
Local cache of available blueprints (fallback + synced).

| Column | Type |
|--------|------|
| id | TEXT PK |
| title | TEXT |
| description | TEXT |
| category | TEXT |
| difficulty | TEXT |
| image_url | TEXT |
| habit_count | INTEGER |
| is_fallback | INTEGER |
| data_json | TEXT |
| updated_at | TEXT |

### `mutation_queue`
Sync queue replacing Hive's key-value box.

| Column | Type |
|--------|------|
| id | INTEGER PK AUTOINCREMENT |
| collection_path | TEXT NOT NULL |
| document_id | TEXT NOT NULL |
| operation | TEXT NOT NULL |
| data_json | TEXT |
| created_at | TEXT NOT NULL |
| retry_count | INTEGER |

## 4. Components

### 4.1 LocalGameLoopEngine (Pure Dart, Zero Dependencies)

```dart
class LocalGameLoopEngine {
  /// Pure function: takes current state, returns full delta
  GameLoopResult processHabitCompletion({
    required HabitData currentHabit,
    required UserStatsData currentStats,
    List<ChallengeProgress> activeChallenges,
  });

  ChallengeProgressResult processChallengeProgress({
    required ChallengeProgress challenge,
    required int newDay,
  });

  TribeContribution computeTribeContribution(
    GameLoopResult gameResult,
  );

  int computeXpGain(int difficultyMultiplier, int streak);
  int computeLevel(int totalXp);
  int computeWorldHealth(List<HabitMomentum> habits);
}
```

Methods are synchronous, pure, and take plain data objects (not drift DAOs). This makes them testable without any infrastructure.

### 4.2 Drift Repositories

Each implements the existing abstract interface from the feature's domain layer:

| Interface | Drift Implementation | Replaces |
|-----------|---------------------|----------|
| `HabitRepository` | `DriftHabitRepository` | `FirestoreHabitRepository` + `CacheAwareHabitRepository` |
| `UserStatsRepository` | `DriftUserStatsRepository` | `UserStatsRepository` + `CacheAwareUserStatsRepository` |
| `ChallengeRepository` | `DriftChallengeRepository` | `FirestoreChallengeRepository` |
| `TribeRepository` | `DriftTribeRepository` | `FirestoreTribeRepository` + `CacheAwareTribeRepository` |
| `LeaderboardRepository` | `DriftLeaderboardRepository` | `FirestoreLeaderboardRepository` |
| `BlueprintsRepository` | `DriftBlueprintsRepository` | `BlueprintsRepository` |

Key pattern for every repository:
```dart
class DriftHabitRepository implements HabitRepository {
  final AppDatabase _db;
  final LocalGameLoopEngine _engine;
  final EnhancedSyncEngine _syncEngine;

  @override
  Future<Either<Failure, bool>> completeHabit(String habitId, DateTime date) async {
    // 1. Read current state from drift
    final habit = await _db.habitsDao.getHabit(habitId);
    final stats = await _db.userStatsDao.getStats(habit.userId);
    final challenges = await _db.challengeProgressDao.getActive(habit.userId);

    // 2. Compute all derived state (pure, <1ms)
    final result = _engine.processHabitCompletion(
      currentHabit: habit,
      currentStats: stats,
      activeChallenges: challenges,
    );

    // 3. Write everything in a single drift transaction
    await _db.transaction(() async {
      await _db.habitsDao.updateStreak(habitId, result.newStreak);
      await _db.habitCompletionsDao.insert(result.completionLog);
      await _db.userStatsDao.updateXp(stats.userId, result.xpDelta, result.newLevel);
      if (result.challengeUpdates.isNotEmpty) {
        await _db.challengeProgressDao.bulkUpdate(result.challengeUpdates);
      }
    });

    // 4. Enqueue sync (single mutation, not 4 transactions)
    await _syncEngine.enqueueMutation(
      collectionPath: 'user_stats',
      documentId: stats.userId,
      operation: 'set',
      data: result.toSyncPayload(),
    );

    return Right(result.isNewlyCompleted);
  }
}
```

### 4.3 EnhancedSyncEngine

Consumes drift `mutation_queue` table instead of Hive boxes:

```dart
class EnhancedSyncEngine {
  final AppDatabase _db;
  final FirebaseFirestore _firestore;

  Future<void> processMutationQueue() async {
    final mutations = await _db.mutationQueueDao.getAllPending();
    // Group by collection for batch writes
    final grouped = groupBy(mutations, (m) => m.collectionPath);
    for (final entry in grouped.entries) {
      final batch = _firestore.batch();
      for (final mutation in entry.value) {
        final ref = _firestore.collection(entry.key).doc(mutation.documentId);
        switch (mutation.operation) {
          case 'set': batch.set(ref, mutation.data); break;
          case 'update': batch.update(ref, mutation.data); break;
          case 'delete': batch.delete(ref); break;
        }
      }
      await batch.commit();
      await _db.mutationQueueDao.markSynced(entry.value.map((m) => m.id));
    }
  }
}
```

## 5. File Structure Changes

### New Files
```
lib/core/drift/
├── database.dart              # Drift database class
├── database.g.dart            # Generated
├── tables/
│   ├── user_stats_table.dart
│   ├── habits_table.dart
│   ├── habit_completions_table.dart
│   ├── challenge_progress_table.dart
│   ├── tribe_stats_table.dart
│   ├── leaderboard_entries_table.dart
│   ├── blueprints_table.dart
│   └── mutation_queue_table.dart
├── daos/
│   ├── user_stats_dao.dart
│   ├── habits_dao.dart
│   ├── habit_completions_dao.dart
│   ├── challenge_progress_dao.dart
│   ├── tribe_stats_dao.dart
│   ├── leaderboard_entries_dao.dart
│   ├── blueprints_dao.dart
│   └── mutation_queue_dao.dart

lib/core/game_loop/
├── game_loop_engine.dart
└── game_loop_result.dart

lib/core/drift_repositories/
├── drift_habit_repository.dart
├── drift_user_stats_repository.dart
├── drift_challenge_repository.dart
├── drift_tribe_repository.dart
├── drift_leaderboard_repository.dart
└── drift_blueprint_repository.dart

lib/core/sync/
├── sync_engine.dart            # Rewritten for drift
└── sync_providers.dart
```

### Deleted Files
```
lib/core/cache/                                  # Entire directory
  cache_aware_habit_repository.dart

lib/core/services/
  local_cache_service.dart                       # Replaced by drift
  local_cache_service.g.dart
  background_sync_service.dart                   # Replaced by EnhancedSyncEngine

lib/features/gamification/data/repositories/
  cache_aware_user_stats_repository.dart
  blueprints_repository.dart                    # Inline fallback data moved to DriftBlueprintsRepository

lib/features/social/data/repositories/
  cache_aware_tribe_repository.dart

lib/features/social/presentation/providers/
  cached_tribe_stats_provider.dart              # Caching is now in drift
  cached_stats.dart                             # Model class for old cache

lib/features/gamification/data/repositories/
  user_stats_repository.dart                     # Direct Firestore, replaced by drift
  firestore_gamification_repository.dart         # Direct Firestore transactions, replaced

lib/features/habits/data/repositories/
  firestore_habit_repository.dart                # Direct Firestore, replaced by drift

lib/features/social/data/repositories/
  firestore_leaderboard_repository.dart          # Direct Firestore, replaced by drift
  challenge_repository.dart                      # Direct Firestore, replaced by drift
  tribe_repository.dart                          # Direct Firestore, replaced by drift

pubspec.yaml
  # Remove: hive, hive_flutter, flutter_secure_storage (if no longer needed)
  # Add: drift, sqlite3_flutter_libs, path_provider, sql_parser
```

### Modified Files
```
lib/features/gamification/presentation/providers/
  gamification_providers.dart                    # Swap to Drift repositories
  user_stats_providers.dart                       # Swap to drift UserStatsRepository

lib/features/social/presentation/providers/
  tribes_provider.dart                            # Swap to DriftTribeRepository
  leaderboard_provider.dart                       # Swap to DriftLeaderboardRepository
  challenge_provider.dart                         # Swap to DriftChallengeRepository

lib/features/blueprints/data/repositories/
  blueprint_repository.dart                       # Replaced by DriftBlueprintsRepository

lib/core/services/
  connectivity_service.dart                       # Still needed for sync trigger
```

## 6. Migration Path

### Phase 1: Foundation
1. Add drift + sqlite3 packages to pubspec.yaml
2. Create drift database, all 8 table definitions, all DAOs
3. Run `build_runner` to verify generation works
4. Implement `LocalGameLoopEngine` with unit tests
5. Store knowledge: drift setup, engine interface

### Phase 2: Drift Repositories
6. Implement `DriftHabitRepository` implementing `HabitRepository`
7. Implement `DriftUserStatsRepository` implementing `UserStatsRepository`
8. Wire up providers to use drift repos
9. Test: complete habit offline → verify UI updates from drift
10. Store knowledge: drift repository pattern

### Phase 3: Sync
11. Rewrite `SyncEngine` to consume drift mutation_queue
12. Wire connectivity service to trigger sync
13. Test: go online → verify Firestore receives queued mutations
14. Store knowledge: sync engine pattern

### Phase 4: Challenge + Tribe + Leaderboard
15. Implement `DriftChallengeRepository`, `DriftTribeRepository`, `DriftLeaderboardRepository`
16. Swap remaining providers
17. Test full flow: complete habit → updates XP, streak, challenge progress, tribe stats, leaderboard — all locally

### Phase 5: Cleanup
18. Remove all files listed in Deleted Files section
19. Remove Hive from pubspec.yaml if no longer used
20. Remove all stale `.g.dart` files
21. Run full test suite

## 7. Testing Strategy

### Unit Tests (LocalGameLoopEngine)
- `computeXpGain`: easy/medium/hard difficulty × 0/7/30/90 streak days
- `computeLevel`: 0 XP → level 1, 499 XP → level 1, 500 XP → level 2
- `processHabitCompletion`: new streak, existing streak continuation, streak reset
- `processChallengeProgress`: day increment, completion detection, XP reward
- Edge cases: negative XP, overflow, streak wrap at max int

### Widget Tests (Drift Repositories)
- Mock drift database with in-memory SQLite
- Test that `watchHabits()` emits when a habit is inserted/updated
- Test that `completeHabit()` writes to both `habits` + `habit_completions` + `user_stats` in one transaction

### Integration Tests
- Real drift database + fake Firebase
- Complete habit → verify drift has updated stats → trigger sync → verify Firestore received correct payload
- Offline completion → verify queued mutation → online → verify mutation consumed

## 8. Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Drift migration breaks existing providers | Drift repos implement same interfaces; providers swap transparently |
| SyncEngine drops mutations | Each mutation has retry_count; on network error, survives across app restarts |
| Conflict between local and Firestore data | Timestamp comparison (`updated_at`); newest wins |
| Large mutation queue on first sync after offline period | Process in batches of 50; rate-limited by WorkManager |
| Testing drift with existing test suite | Use `NativeDatabase.memory()` for in-memory SQLite in tests |
