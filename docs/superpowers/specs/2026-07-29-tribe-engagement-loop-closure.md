# Tribe Engagement Loop Closure

**Goal:** Close the 4 remaining gaps in the tribe engagement loop — streak milestone feed posts, level-up feed posts, partner miss-detection nudges, and Firestore→Drift merge-back for cross-user data.

**Architecture:** Single `TribeLoopService` subscribing to `EventBus().on<HabitCompleted>()`, with a `StreakWatchdog` for partner gap checks and a `FirestoreDriftSyncer` for reverse-sync. All service methods already exist — this wires callers to them.

## Background

The closed loop from `completeHabit()` already fans out:
- Drift local writes (habit log, user stats, tribe stats, leaderboard)
- Sync queue (Firestore writes for all 4+ paths)
- Tribe activity feed (habit completions)

But 4 gaps remain:

1. **Streak milestones** (7/14/21/30 days) — `SocialActivityService.logStreakMilestone()` exists but nobody calls it
2. **Level-ups** — `SocialActivityService.logLevelUp()` exists but nobody calls it
3. **Partner miss-detection** — No automatic nudge when a partner misses 2+ consecutive days
4. **Firestore→Drift merge-back** — Cross-user data (other tribe members' stats, leaderboard changes) doesn't sync back to local Drift

## Design

### 1. TribeLoopService

A keep-alive Riverpod provider that starts at app boot and subscribes to `EventBus().on<HabitCompleted>()`. It coordinates all post-completion side effects in one place.

**File:** `lib/features/social/domain/services/tribe_loop_service.dart`

```dart
@Riverpod(keepAlive: true)
TribeLoopService tribeLoopService(Ref ref) {
  final service = TribeLoopService(
    ref: ref,
    socialActivity: ref.watch(clubActivityServiceProvider),
    friendRepo: ref.watch(friendRepositoryProvider),
    habitCompletionsDao: ref.watch(habitCompletionsDaoProvider),
    notificationService: ref.watch(socialNotificationServiceProvider),
    leaderboardDao: ref.watch(leaderboardEntriesDaoProvider),
    tribeStatsDao: ref.watch(tribeStatsDaoProvider),
    firestore: ref.watch(firebaseFirestoreProvider),
  );
  ref.onDispose(() => service.dispose());
  return service;
}
```

**Initialization:**
- Subscribes to `EventBus().on<HabitCompleted>()` on construction
- Calls `startDriftSync()` to start Firestore→Drift listeners
- `dispose()` cancels all subscriptions

### 2. HabitCompleted Event Extension

**File:** `lib/core/events/habit_completed_event.dart`

Add to existing event:
```dart
class HabitCompleted {
  final String userId;
  final String habitId;
  final GameLoopResult gameLoopResult;
  final int previousLevel;
  final String? tribeId;
  final String? archetype;

  const HabitCompleted({...});
}
```

The event is emitted in `DriftHabitRepository.completeHabit()` after the Drift transaction succeeds.

### 3. Streak Milestone Feed Posts

In `_onHabitCompleted()`:

```dart
const streakMilestones = [7, 14, 21, 30, 60, 90];
if (streakMilestones.contains(result.newStreak)) {
  await socialActivity.logStreakMilestone(
    userId: userId,
    userName: userName,
    tribeId: event.tribeId!,
    streakDay: result.newStreak,
    archetype: event.archetype,
  );
}
```

**Fan-out (already in `logStreakMilestone`):**
- Drift: `TribeActivityTable` insert
- Firestore: `tribes/{tribeId}/activity/{id}`
- Firestore: `global_activities/{id}`
- Firestore: `users/{partnerId}/partner_activity/{id}` (per partner)

### 4. Level-Up Feed Posts

In `_onHabitCompleted()`:

```dart
if (result.newLevel > previousLevel) {
  await socialActivity.logLevelUp(
    userId: userId,
    userName: userName,
    tribeId: event.tribeId!,
    newLevel: result.newLevel,
    archetype: event.archetype,
  );
}
```

**Fan-out (same as streak milestones above, via existing `logLevelUp`).**

### 5. StreakWatchdog (Partner Miss-Detection)

**File:** `lib/features/social/domain/services/streak_watchdog.dart`

```dart
class StreakWatchdog {
  Future<void> checkPartners({
    required String userId,
    required String tribeId,
  }) async {
    final partners = await friendRepo.getFriends(userId);
    for (final partner in partners) {
      final lastCompletion = await habitCompletionsDao
          .getLastCompletion(partner.id);
      if (lastCompletion == null) continue;
      final daysSince = DateTime.now()
          .difference(lastCompletion.completedAt)
          .inDays;
      if (daysSince >= 2) {
        await notificationService.sendNotification(
          userId: userId,
          title: '${partner.name} missed 2 days',
          body: 'Send them some encouragement!',
          type: AppNotificationType.tribeActivity,
        );
      }
    }
  }
}
```

**Triggers:**
- On app start (via `TribeLoopService` init) — runs for all tribe members
- On own habit completion — checks the completing user's partners

**Rate-limiting:** The watchdog tracks last-check timestamps per partner to avoid duplicate notifications within a 24-hour window. State is in memory (a `Map<String, DateTime>`).

### 6. FirestoreDriftSyncer (Merge-Back)

**File:** `lib/features/social/domain/services/firestore_drift_syncer.dart`

```dart
class FirestoreDriftSyncer {
  StreamSubscription? _leaderboardSub;
  StreamSubscription? _tribeStatsSub;

  void start(String tribeId) {
    // Leaderboard: Firestore → Drift leaderboard_entries
    _leaderboardSub = firestore
        .collection('club_leaderboards')
        .where('tribeId', isEqualTo: tribeId)
        .snapshots()
        .listen((snapshot) {
      for (final doc in snapshot.docs) {
        leaderboardDao.upsertEntry(LeaderboardEntry.fromMap(doc.data()).toCompanion());
      }
    });

    // Tribe stats: Firestore → Drift tribe_stats
    _tribeStatsSub = firestore
        .collection('tribes')
        .doc(tribeId)
        .snapshots()
        .listen((doc) {
      if (doc.exists) {
        tribeStatsDao.upsertStats(TribeStatsTableCompanion(
          tribeId: Value(doc.id),
          totalXp: Value(doc.data()?['totalXp'] ?? 0),
          memberCount: Value(doc.data()?['memberCount'] ?? 0),
          totalHabitsCompleted: Value(doc.data()?['totalHabitsCompleted'] ?? 0),
        ));
      }
    });
  }

  void stop() {
    _leaderboardSub?.cancel();
    _tribeStatsSub?.cancel();
  }
}
```

**Merge logic:** Uses `upsertStats` / `upsertEntry` which are pure upserts (insert or update). For monotonic counters (XP, habits), the higher value wins. For scalars (memberCount), Firestore is source of truth.

**Subscription lifecycle:** Started when `TribeLoopService` initializes (requires user to have a tribe). Cancelled on dispose.

## File Changes

### New Files
| File | Purpose |
|------|---------|
| `lib/features/social/domain/services/tribe_loop_service.dart` | Event bus subscriber + coordinator |
| `lib/features/social/domain/services/tribe_loop_service.g.dart` | Generated Riverpod code |
| `lib/features/social/domain/services/streak_watchdog.dart` | Partner miss-detection |
| `lib/features/social/domain/services/firestore_drift_syncer.dart` | Firestore→Drift merge-back |
| `test/features/social/domain/services/tribe_loop_service_test.dart` | TribeLoopService tests |
| `test/features/social/domain/services/streak_watchdog_test.dart` | StreakWatchdog tests |
| `test/features/social/domain/services/firestore_drift_syncer_test.dart` | Syncer tests |

### Modified Files
| File | Change |
|------|--------|
| `lib/core/events/habit_completed_event.dart` | Add `gameLoopResult`, `previousLevel`, `tribeId`, `archetype` fields |
| `lib/core/drift_repositories/drift_habit_repository.dart` | Emit `HabitCompleted` with full result after Drift transaction |
| `lib/features/habits/presentation/providers/habit_providers.dart` | Pass previous level into `completeHabit()` |
| `lib/features/social/presentation/providers/activity_service_provider.dart` | Add `clubActivityServiceProvider` (if missing) |
| `lib/features/social/presentation/providers/friend_provider.dart` | Add `habitCompletionsDaoProvider` |
| `lib/core/drift/database.dart` | Export `habitCompletionsDaoProvider` |

## Test Plan

| Test | What It Verifies |
|------|-----------------|
| `TribeLoopService` | Streak 7/14/21 calls `logStreakMilestone`; non-milestone does not |
| `TribeLoopService` | Level increment calls `logLevelUp`; no change does not |
| `StreakWatchdog` | Partner with 2+ day gap triggers notification |
| `StreakWatchdog` | Partner with recent completion triggers nothing |
| `StreakWatchdog` | Rate-limiter suppresses duplicate within 24h |
| `FirestoreDriftSyncer` | Firestore leaderboard change upserts Drift entry |
| `FirestoreDriftSyncer` | Firestore tribe stats change upserts Drift stats |

## Success Criteria

- [ ] Completing a habit at streak 7/14/21/30 posts milestone to tribe feed
- [ ] Leveling up posts level-up announcement to tribe feed
- [ ] User receives in-app notification when a partner misses 2+ days
- [ ] Leaderboard entries from other users appear in local Drift without app restart
- [ ] Tribe stats (memberCount, totalXp) reflect other users' changes without app restart
- [ ] `dart analyze` passes with 0 errors
- [ ] All new unit tests pass
