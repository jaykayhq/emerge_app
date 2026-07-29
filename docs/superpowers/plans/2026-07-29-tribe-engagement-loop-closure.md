# Tribe Engagement Loop Closure — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close 4 remaining gaps in the tribe engagement loop — streak milestone feed posts, level-up feed posts, partner miss-detection nudges, and Firestore→Drift merge-back for cross-user data.

**Architecture:** Single `TribeLoopService` subscribing to `EventBus().on<HabitCompleted>()`, with a `StreakWatchdog` for partner gap checks and a `FirestoreDriftSyncer` for reverse-sync. All service methods already exist — this wires callers to them.

**Tech Stack:** Flutter 3.x, Riverpod (with codegen), Drift (SQLite), Firebase Firestore, EnhancedSyncEngine, EventBus

## Global Constraints

- All repository methods return `Either<Failure, T>` from fpdart — never throw across the boundary
- All `@riverpod` annotations use auto-dispose unless `keepAlive: true`
- Every `AsyncValue` must handle all three branches (`loading`/`error`/`data`) + empty-array case
- Run `dart analyze` before any commit — zero errors, zero warnings
- Run `dart run build_runner build --delete-conflicting-outputs` after any `.g.dart` generation change

---

## File Structure

### New Files
1. `lib/features/social/domain/services/tribe_loop_service.dart` — Event bus subscriber + coordinator
2. `lib/features/social/domain/services/tribe_loop_service.g.dart` — Generated Riverpod code
3. `lib/features/social/domain/services/streak_watchdog.dart` — Partner miss-detection
4. `lib/features/social/domain/services/firestore_drift_syncer.dart` — Firestore→Drift merge-back
5. `test/features/social/domain/services/tribe_loop_service_test.dart`
6. `test/features/social/domain/services/streak_watchdog_test.dart`
7. `test/features/social/domain/services/firestore_drift_syncer_test.dart`

### Modified Files
1. `lib/core/services/event_bus.dart` — Extend `HabitCompleted` with `gameLoopResult`, `previousLevel`, `tribeId`, `archetype`
2. `lib/core/drift_repositories/drift_habit_repository.dart` — Emit `HabitCompleted` event after Drift transaction
3. `lib/core/drift/daos/habit_completions_dao.dart` — Add `getLastCompletion(String userId)`
4. `lib/core/drift/daos/habit_completions_dao.g.dart` — Regenerated
5. `lib/features/social/presentation/providers/tribes_provider.dart` — Add `tribeLoopServiceProvider` (keepAlive)
6. `lib/features/social/presentation/providers/friend_provider.dart` — Add `habitCompletionsDaoProvider` (keepAlive)

---

### Task 1: Extend HabitCompleted + Fire from completeHabit()

**Files:**
- Modify: `lib/core/services/event_bus.dart`
- Modify: `lib/core/drift_repositories/drift_habit_repository.dart`
- Test: `test/core/drift_repositories/drift_habit_repository_test.dart` (or verify existing)

**Interfaces:**
- Consumes: `EventBus.fire(dynamic)`, `GameLoopResult` (existing)
- Produces: Extended `HabitCompleted` with `gameLoopResult`, `previousLevel`, `tribeId`, `archetype`

- [ ] **Step 1: Extend HabitCompleted event**

In `lib/core/services/event_bus.dart`, add fields to the existing event:

```dart
class HabitCompleted {
  final String habitId;
  final String userId;
  final DateTime date;
  final GameLoopResult gameLoopResult;
  final int previousLevel;
  final String? tribeId;
  final String? archetype;
  final String userName;

  HabitCompleted({
    required this.habitId,
    required this.userId,
    required this.date,
    required this.gameLoopResult,
    required this.previousLevel,
    required this.userName,
    this.tribeId,
    this.archetype,
  });
}
```

Also add import `import '../game_loop/game_loop_result.dart';` at the top.

- [ ] **Step 2: Wire the fire call in completeHabit()**

In `lib/core/drift_repositories/drift_habit_repository.dart`, in `completeHabit()`:

After the stats row read (line 152), capture the old level:
```dart
final oldLevel = _engine.computeLevel(statsRow.totalXp);
```

After the Drift transaction succeeds (line 494, just before `return const Right(true)`):
```dart
EventBus().fire(HabitCompleted(
  habitId: habitRow.id,
  userId: habitRow.userId,
  date: date,
  gameLoopResult: result,
  previousLevel: oldLevel,
  tribeId: activeTribeId,
  archetype: statsRow.archetype,
  userName: statsRow.displayName ?? habitRow.userId,
));
```

Add import at top: `import 'package:emerge_app/core/services/event_bus.dart';`

- [ ] **Step 3: Run analysis**

```bash
dart analyze lib/core/services/event_bus.dart lib/core/drift_repositories/drift_habit_repository.dart
```

Expected: 0 errors, 0 warnings

- [ ] **Step 4: Commit**

```bash
git add lib/core/services/event_bus.dart lib/core/drift_repositories/drift_habit_repository.dart
git commit -m "feat: extend HabitCompleted event, fire from completeHabit()"
```

---

### Task 2: StreakWatchdog + HabitCompletionsDao.getLastCompletion

**Files:**
- Modify: `lib/core/drift/daos/habit_completions_dao.dart`
- Create: `lib/features/social/domain/services/streak_watchdog.dart`
- Create: `test/features/social/domain/services/streak_watchdog_test.dart`

**Interfaces:**
- Consumes: `HabitCompletionsDao.getLastCompletion(String userId) → Future<HabitCompletionsTableData?>`
- Produces: `StreakWatchdog.checkPartners(userId, tribeId) → Future<void>`

- [ ] **Step 1: Add getLastCompletion to DAO**

In `lib/core/drift/daos/habit_completions_dao.dart`, add:

```dart
Future<HabitCompletionsTableData?> getLastCompletion(String userId) async {
  return (select(habitCompletionsTable)
    ..where((t) => t.userId.equals(userId))
    ..orderBy([(t) => OrderingTerm(expression: t.completedAt, mode: OrderingMode.desc)])
    ..limit(1))
      .getSingleOrNull();
}
```

- [ ] **Step 2: Write failing test for StreakWatchdog**

`test/features/social/domain/services/streak_watchdog_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:emerge_app/core/drift/daos/habit_completions_dao.dart';
import 'package:emerge_app/core/drift/tables/habit_completions_table.dart';
import 'package:emerge_app/features/social/domain/services/streak_watchdog.dart';
import 'package:emerge_app/features/social/domain/repositories/friend_repository.dart';
import 'package:emerge_app/features/social/domain/entities/social_entities.dart';
import 'package:emerge_app/core/services/social_notification_service.dart';

class MockFriendRepo extends Mock implements FriendRepository {}
class MockHabitCompletionsDao extends Mock implements HabitCompletionsDao {}
class MockNotificationService extends Mock implements SocialNotificationService {}

void main() {
  late StreakWatchdog watchdog;
  late MockFriendRepo mockFriendRepo;
  late MockHabitCompletionsDao mockDao;
  late MockNotificationService mockNotification;

  setUp(() {
    mockFriendRepo = MockFriendRepo();
    mockDao = MockHabitCompletionsDao();
    mockNotification = MockNotificationService();
    watchdog = StreakWatchdog(
      friendRepo: mockFriendRepo,
      habitCompletionsDao: mockDao,
      notificationService: mockNotification,
    );
  });

  group('checkPartners', () {
    test('notifies when partner missed 2+ days', () async {
      when(mockFriendRepo.getFriends('user1'))
          .thenAnswer((_) async => [Friend(id: 'partner1', name: 'Partner1', archetype: FriendArchetype.athlete)]);
      when(mockDao.getLastCompletion('partner1'))
          .thenAnswer((_) async => HabitCompletionsTableData(
                id: 'c1', habitId: 'h1', userId: 'partner1',
                completedAt: DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
              ));

      await watchdog.checkPartners(userId: 'user1', tribeId: 't1');

      verify(mockNotification.sendNotification(any, any)).called(1);
    });

    test('does not notify when partner completed today', () async {
      when(mockFriendRepo.getFriends('user1'))
          .thenAnswer((_) async => [Friend(id: 'partner1', name: 'Partner1', archetype: FriendArchetype.athlete)]);
      when(mockDao.getLastCompletion('partner1'))
          .thenAnswer((_) async => HabitCompletionsTableData(
                id: 'c1', habitId: 'h1', userId: 'partner1',
                completedAt: DateTime.now().toIso8601String(),
              ));

      await watchdog.checkPartners(userId: 'user1', tribeId: 't1');

      verifyNever(mockNotification.sendNotification(any, any));
    });

    test('rate-limiter suppresses duplicate within 24h', () async {
      when(mockFriendRepo.getFriends('user1'))
          .thenAnswer((_) async => [Friend(id: 'partner1', name: 'Partner1', archetype: FriendArchetype.athlete)]);
      when(mockDao.getLastCompletion('partner1'))
          .thenAnswer((_) async => HabitCompletionsTableData(
                id: 'c1', habitId: 'h1', userId: 'partner1',
                completedAt: DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
              ));

      await watchdog.checkPartners(userId: 'user1', tribeId: 't1');
      await watchdog.checkPartners(userId: 'user1', tribeId: 't1');

      verify(mockNotification.sendNotification(any, any)).called(1);
    });

    test('skips partner with no completions', () async {
      when(mockFriendRepo.getFriends('user1'))
          .thenAnswer((_) async => [Friend(id: 'partner1', name: 'Partner1', archetype: FriendArchetype.athlete)]);
      when(mockDao.getLastCompletion('partner1')).thenAnswer((_) async => null);

      await watchdog.checkPartners(userId: 'user1', tribeId: 't1');

      verifyNever(mockNotification.sendNotification(any, any));
    });
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

```bash
flutter test test/features/social/domain/services/streak_watchdog_test.dart --timeout 30s
```

Expected: FAIL — StreakWatchdog class not found

- [ ] **Step 4: Create StreakWatchdog**

`lib/features/social/domain/services/streak_watchdog.dart`:

```dart
import 'dart:collection';
import 'package:emerge_app/core/drift/daos/habit_completions_dao.dart';
import 'package:emerge_app/core/domain/entities/app_notification.dart';
import 'package:emerge_app/core/services/social_notification_service.dart';
import 'package:emerge_app/features/social/domain/repositories/friend_repository.dart';

class StreakWatchdog {
  final FriendRepository friendRepo;
  final HabitCompletionsDao habitCompletionsDao;
  final SocialNotificationService notificationService;
  final HashMap<String, DateTime> _lastCheck = HashMap();

  StreakWatchdog({
    required this.friendRepo,
    required this.habitCompletionsDao,
    required this.notificationService,
  });

  Future<void> checkPartners({
    required String userId,
    required String tribeId,
  }) async {
    final partners = await friendRepo.getFriends(userId);
    for (final partner in partners) {
      // Rate-limit: skip if checked within last 24h
      final lastChecked = _lastCheck[partner.id];
      if (lastChecked != null &&
          DateTime.now().difference(lastChecked).inHours < 24) {
        continue;
      }
      _lastCheck[partner.id] = DateTime.now();

      final lastCompletion = await habitCompletionsDao.getLastCompletion(partner.id);
      if (lastCompletion == null) continue;

      final completedAt = DateTime.parse(lastCompletion.completedAt);
      final daysSince = DateTime.now().difference(completedAt).inDays;
      if (daysSince >= 2) {
        await notificationService.sendNotification(
          userId,
          AppNotification(
            id: '',
            type: AppNotificationType.tribeActivity,
            title: '${partner.name} missed 2 days',
            body: 'Send them some encouragement!',
            createdAt: DateTime.now().toIso8601String(),
          ),
        );
      }
    }
  }
}
```

- [ ] **Step 5: Run tests to verify they pass**

```bash
flutter test test/features/social/domain/services/streak_watchdog_test.dart --timeout 30s
```

Expected: All 4 tests PASS

- [ ] **Step 6: Build runner + Commit**

```bash
dart run build_runner build --delete-conflicting-outputs
git add lib/core/drift/daos/habit_completions_dao.dart \
       lib/features/social/domain/services/streak_watchdog.dart \
       test/features/social/domain/services/streak_watchdog_test.dart \
       lib/core/drift/daos/habit_completions_dao.g.dart
git commit -m "feat: add StreakWatchdog for partner miss-detection"
```

---

### Task 3: TribeLoopService — Event Subscription, Feed Posts, Partner Checks

**Files:**
- Create: `lib/features/social/domain/services/tribe_loop_service.dart`
- Create: `test/features/social/domain/services/tribe_loop_service_test.dart`
- Modify: `lib/features/social/presentation/providers/tribes_provider.dart`

**Interfaces:**
- Consumes: `EventBus().on<HabitCompleted>()`, `SocialActivityService.logStreakMilestone()`, `SocialActivityService.logLevelUp()`, `StreakWatchdog`, `FriendRepository`
- Produces: `tribeLoopServiceProvider` (keepAlive)

- [ ] **Step 1: Write failing test**

`test/features/social/domain/services/tribe_loop_service_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:emerge_app/core/events/habit_completed_event.dart';
import 'package:emerge_app/core/game_loop/game_loop_result.dart';
import 'package:emerge_app/features/social/domain/services/tribe_loop_service.dart';
import 'package:emerge_app/features/social/domain/services/club_activity_service.dart';
import 'package:emerge_app/features/social/domain/services/streak_watchdog.dart';

class MockSocialActivity extends Mock implements SocialActivityService {}
class MockStreakWatchdog extends Mock implements StreakWatchdog {}

void main() {
  late TribeLoopService service;
  late MockSocialActivity mockSocial;
  late MockStreakWatchdog mockWatchdog;

  setUp(() {
    mockSocial = MockSocialActivity();
    mockWatchdog = MockStreakWatchdog();
    service = TribeLoopService(
      socialActivity: mockSocial,
      streakWatchdog: mockWatchdog,
    );
  });

  tearDown(() {
    service.dispose();
  });

  HabitCompleted _event({
    int newStreak = 1,
    int newLevel = 5,
    int previousLevel = 5,
    String? tribeId = 't1',
  }) {
    return HabitCompleted(
      habitId: 'h1',
      userId: 'u1',
      date: DateTime.now(),
      gameLoopResult: GameLoopResult(
        newStreak: newStreak,
        longestStreak: newStreak,
        xpGained: 10,
        attribute: 'strength',
        newLevel: newLevel,
        newTotalXp: 500,
        newMomentumScore: 10,
        newConsecutiveMisses: 0,
        isRecovery: false,
        worldHealthDelta: 0.1,
        challengeUpdates: {},
      ),
      previousLevel: previousLevel,
      tribeId: tribeId,
      archetype: 'athlete',
      userName: 'User1',
    );
  }

  test('streak milestone 7 calls logStreakMilestone', () async {
    await service._onHabitCompleted(_event(newStreak: 7));
    verify(mockSocial.logStreakMilestone(
      userId: anyNamed('userId'),
      userName: anyNamed('userName'),
      archetype: anyNamed('archetype'),
      streakDays: 7,
    )).called(1);
  });

  test('streak 14 calls logStreakMilestone', () async {
    await service._onHabitCompleted(_event(newStreak: 14));
    verify(mockSocial.logStreakMilestone(
      streakDays: 14,
    )).called(1);
  });

  test('non-milestone streak does not log', () async {
    await service._onHabitCompleted(_event(newStreak: 3));
    verifyNever(mockSocial.logStreakMilestone(any));
  });

  test('level up calls logLevelUp', () async {
    await service._onHabitCompleted(_event(newLevel: 6, previousLevel: 5));
    verify(mockSocial.logLevelUp(
      userId: anyNamed('userId'),
      userName: anyNamed('userName'),
      archetype: anyNamed('archetype'),
      newLevel: 6,
    )).called(1);
  });

  test('no level change does not call logLevelUp', () async {
    await service._onHabitCompleted(_event(newLevel: 5, previousLevel: 5));
    verifyNever(mockSocial.logLevelUp(any));
  });

  test('calls StreakWatchdog on habit completion', () async {
    await service._onHabitCompleted(_event());
    verify(mockWatchdog.checkPartners(userId: 'u1', tribeId: 't1')).called(1);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/features/social/domain/services/tribe_loop_service_test.dart --timeout 30s
```

Expected: FAIL — TribeLoopService not found

- [ ] **Step 3: Create TribeLoopService**

`lib/features/social/domain/services/tribe_loop_service.dart`:

```dart
import 'dart:async';
import 'package:emerge_app/core/services/event_bus.dart';
import 'package:emerge_app/features/social/domain/services/club_activity_service.dart';
import 'package:emerge_app/features/social/domain/services/streak_watchdog.dart';

class TribeLoopService {
  final SocialActivityService _socialActivity;
  final StreakWatchdog _streakWatchdog;
  StreamSubscription? _subscription;

  static const _streakMilestones = [7, 14, 21, 30, 60, 90];

  TribeLoopService({
    required SocialActivityService socialActivity,
    required StreakWatchdog streakWatchdog,
  })  : _socialActivity = socialActivity,
        _streakWatchdog = streakWatchdog {
    _subscription = EventBus().on<HabitCompleted>().listen(_onHabitCompleted);
  }

  void dispose() {
    _subscription?.cancel();
  }

  @visibleForTesting
  Future<void> _onHabitCompleted(HabitCompleted event) async {
    final result = event.gameLoopResult;
    final userId = event.userId;

    // 1. Streak milestone → tribe feed
    if (_streakMilestones.contains(result.newStreak)) {
      await _socialActivity.logStreakMilestone(
        userId: userId,
        userName: event.userName,
        archetype: event.archetype ?? '',
        streakDays: result.newStreak,
      );
    }

    // 2. Level up → tribe feed
    if (result.newLevel > event.previousLevel) {
      await _socialActivity.logLevelUp(
        userId: userId,
        userName: event.userName,
        archetype: event.archetype ?? '',
        newLevel: result.newLevel,
        totalXp: result.newTotalXp,
      );
    }

    // 3. Partner miss-detection
    if (event.tribeId != null) {
      await _streakWatchdog.checkPartners(
        userId: userId,
        tribeId: event.tribeId!,
      );
    }
  }
}
```

Note: The `userName` is empty string here because `HabitCompleted` doesn't carry it. The `SocialActivityService` methods can handle this by using `userId` for lookups, and the existing tests show they work without it. A future enhancement could add `userName` to `HabitCompleted`.

- [ ] **Step 4: Add tribeLoopServiceProvider to tribes_provider.dart**

In `lib/features/social/presentation/providers/tribes_provider.dart`, add at the bottom:

```dart
@Riverpod(keepAlive: true)
TribeLoopService tribeLoopService(Ref ref) {
  final socialActivity = ref.read(socialActivityServiceProvider);
  final friendRepo = ref.read(friendRepositoryProvider);
  final dao = ref.read(habitCompletionsDaoProvider);
  final notificationService = ref.read(socialNotificationServiceProvider);
  final watchdog = StreakWatchdog(
    friendRepo: friendRepo,
    habitCompletionsDao: dao,
    notificationService: notificationService,
  );
  final service = TribeLoopService(
    socialActivity: socialActivity,
    streakWatchdog: watchdog,
  );
  ref.onDispose(() => service.dispose());
  return service;
}
```

- [ ] **Step 5: Run tests + analysis**

```bash
flutter test test/features/social/domain/services/tribe_loop_service_test.dart --timeout 30s
dart analyze lib/features/social/domain/services/tribe_loop_service.dart lib/features/social/presentation/providers/tribes_provider.dart
```

Expected: All tests PASS, 0 errors

- [ ] **Step 6: Build runner + Commit**

```bash
dart run build_runner build --delete-conflicting-outputs
git add lib/features/social/domain/services/tribe_loop_service.dart \
       test/features/social/domain/services/tribe_loop_service_test.dart \
       lib/features/social/presentation/providers/tribes_provider.dart \
       lib/features/social/domain/services/tribe_loop_service.g.dart
git commit -m "feat: TribeLoopService wires streak milestones, level-ups, and partner checks"
```

---

### Task 4: FirestoreDriftSyncer — Cross-User Merge-Back

**Files:**
- Create: `lib/features/social/domain/services/firestore_drift_syncer.dart`
- Create: `test/features/social/domain/services/firestore_drift_syncer_test.dart`

**Interfaces:**
- Consumes: `FirebaseFirestore`, `LeaderboardEntriesDao`, `TribeStatsDao`
- Produces: `FirestoreDriftSyncer.start(tribeId)`, `stop()`

- [ ] **Step 1: Write failing test**

`test/features/social/domain/services/firestore_drift_syncer_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:emerge_app/core/drift/app_database.dart';
import 'package:emerge_app/features/social/domain/services/firestore_drift_syncer.dart';

void main() {
  late AppDatabase db;
  late FakeFirebaseFirestore firestore;
  late FirestoreDriftSyncer syncer;

  setUp(() async {
    db = AppDatabase.withExecutor(NativeDatabase.memory());
    firestore = FakeFirebaseFirestore();
    syncer = FirestoreDriftSyncer(
      firestore: firestore,
      leaderboardDao: db.leaderboardEntriesDao,
      tribeStatsDao: db.tribeStatsDao,
    );
  });

  tearDown(() async {
    syncer.stop();
    await db.close();
  });

  test('tribe stats upserted from Firestore document', () async {
    await firestore.collection('tribes').doc('t1').set({
      'totalXp': 1000,
      'memberCount': 5,
      'totalHabitsCompleted': 200,
    });

    syncer.start('t1');
    await Future.delayed(const Duration(milliseconds: 100));

    final stats = await db.tribeStatsDao.getStats('t1');
    expect(stats, isNotNull);
    expect(stats!.totalXp, 1000);
    expect(stats.memberCount, 5);
  });

  test('leaderboard entry upserted from Firestore', () async {
    await firestore.collection('club_leaderboards').add({
      'tribeId': 't1',
      'userId': 'u1',
      'userName': 'User1',
      'xp': 500,
      'level': 5,
      'rank': 1,
    });

    syncer.start('t1');
    await Future.delayed(const Duration(milliseconds: 100));

    final entries = await db.leaderboardEntriesDao.watchLeaderboard('t1').first;
    expect(entries, isNotEmpty);
  });

  test('multiple tribe docs update independently', () async {
    await firestore.collection('tribes').doc('t1').set({
      'totalXp': 1000,
      'memberCount': 5,
    });
    await firestore.collection('tribes').doc('t2').set({
      'totalXp': 2000,
      'memberCount': 10,
    });

    syncer.start('t1');
    await Future.delayed(const Duration(milliseconds: 100));

    final statsT1 = await db.tribeStatsDao.getStats('t1');
    final statsT2 = await db.tribeStatsDao.getStats('t2');
    expect(statsT1, isNotNull);
    expect(statsT1!.totalXp, 1000);
    // t2 should NOT be synced since we started with tribeId 't1'
    expect(statsT2?.totalXp, isNot(2000));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/features/social/domain/services/firestore_drift_syncer_test.dart --timeout 30s
```

Expected: FAIL — FirestoreDriftSyncer not found

- [ ] **Step 3: Create FirestoreDriftSyncer**

`lib/features/social/domain/services/firestore_drift_syncer.dart`:

```dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/core/drift/daos/leaderboard_entries_dao.dart';
import 'package:emerge_app/core/drift/daos/tribe_stats_dao.dart';
import 'package:emerge_app/core/drift/tables/tribe_stats_table.dart';
import 'package:emerge_app/features/social/domain/entities/leaderboard_entry.dart';

class FirestoreDriftSyncer {
  final FirebaseFirestore firestore;
  final LeaderboardEntriesDao leaderboardDao;
  final TribeStatsDao tribeStatsDao;
  StreamSubscription? _leaderboardSub;
  StreamSubscription? _tribeStatsSub;

  FirestoreDriftSyncer({
    required this.firestore,
    required this.leaderboardDao,
    required this.tribeStatsDao,
  });

  void start(String tribeId) {
    // Leaderboard: Firestore → Drift leaderboard_entries
    _leaderboardSub = firestore
        .collection('club_leaderboards')
        .where('tribeId', isEqualTo: tribeId)
        .snapshots()
        .listen((snapshot) {
      for (final doc in snapshot.docs) {
        final data = doc.data();
        leaderboardDao.upsertEntry(LeaderboardEntriesTableCompanion(
          id: Value(doc.id),
          tribeId: Value(data['tribeId'] as String? ?? tribeId),
          userId: Value(data['userId'] as String? ?? ''),
          userName: Value(data['userName'] as String? ?? ''),
          xp: Value(data['xp'] as int? ?? 0),
          level: Value(data['level'] as int? ?? 1),
          rank: Value(data['rank'] as int? ?? 0),
          archetype: Value(data['archetype'] as String? ?? ''),
          updatedAt: Value(DateTime.now().toIso8601String()),
        ));
      }
    });

    // Tribe stats: Firestore → Drift tribe_stats
    _tribeStatsSub = firestore
        .collection('tribes')
        .doc(tribeId)
        .snapshots()
        .listen((doc) {
      if (!doc.exists) return;
      final data = doc.data()!;
      tribeStatsDao.upsertStats(TribeStatsTableCompanion(
        tribeId: Value(doc.id),
        totalXp: Value(data['totalXp'] as int? ?? 0),
        memberCount: Value(data['memberCount'] as int? ?? 0),
        totalHabitsCompleted: Value(data['totalHabitsCompleted'] as int? ?? 0),
      ));
    });
  }

  void stop() {
    _leaderboardSub?.cancel();
    _tribeStatsSub?.cancel();
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
flutter test test/features/social/domain/services/firestore_drift_syncer_test.dart --timeout 30s
```

Expected: All 3 tests PASS

- [ ] **Step 5: Analysis**

```bash
dart analyze lib/features/social/domain/services/firestore_drift_syncer.dart
```

Expected: 0 errors

- [ ] **Step 6: Commit**

```bash
git add lib/features/social/domain/services/firestore_drift_syncer.dart \
       test/features/social/domain/services/firestore_drift_syncer_test.dart
git commit -m "feat: FirestoreDriftSyncer merges cross-user data back into Drift"
```

---

### Task 5: Wire TribeLoopService Start at Boot + Regression Tests

**Files:**
- Modify: `lib/features/social/presentation/providers/tribes_provider.dart`

**Interfaces:**
- Consumes: `tribeLoopServiceProvider` (auto-starts on first read)
- Produces: `FirestoreDriftSyncer` wired into boot flow

- [ ] **Step 1: Ensure tribeLoopServiceProvider starts at boot**

In `lib/features/social/presentation/providers/tribes_provider.dart`, ensure the provider is eagerly initialized by reading it from the app bootstrap. The keepAlive provider starts on first `ref.watch` or `ref.read`. The existing `tribeLoopServiceProvider` from Task 3 is already keepAlive.

If there's an app boot provider or main.dart initialization, add a read:
```dart
// At app boot
ref.read(tribeLoopServiceProvider);
```

Check if there's an existing boot sequence in `lib/app.dart` or `lib/main.dart`. If not, the keepAlive provider will start lazily on first read, which is fine — the first `HabitCompleted` event will trigger initialization.

- [ ] **Step 2: Wire FirestoreDriftSyncer into TribeLoopService**

Modify `lib/features/social/domain/services/tribe_loop_service.dart` to accept and start `FirestoreDriftSyncer`:

```dart
class TribeLoopService {
  final SocialActivityService _socialActivity;
  final StreakWatchdog _streakWatchdog;
  final FirestoreDriftSyncer? _driftSyncer;
  StreamSubscription? _subscription;

  TribeLoopService({
    required SocialActivityService socialActivity,
    required StreakWatchdog streakWatchdog,
    FirestoreDriftSyncer? driftSyncer,
  })  : _socialActivity = socialActivity,
        _streakWatchdog = streakWatchdog,
        _driftSyncer = driftSyncer;

  void startDriftSync(String tribeId) {
    _driftSyncer?.start(tribeId);
  }

  void stopDriftSync() {
    _driftSyncer?.stop();
  }
  // ...
}
```

Also add `stopDriftSync()` call in `dispose()`:
```dart
void dispose() {
  _subscription?.cancel();
  _driftSyncer?.stop();
}
```

- [ ] **Step 3: Wire drift syncer init in tribeLoopServiceProvider**

In `tribes_provider.dart`, update `tribeLoopServiceProvider` to start the drift syncer when the user has an active tribe:

```dart
@Riverpod(keepAlive: true)
TribeLoopService tribeLoopService(Ref ref) {
  final firestore = FirebaseFirestore.instance;
  final leaderboardDao = ref.read(leaderboardEntriesDaoProvider);
  final tribeStatsDao = ref.read(tribeStatsDaoProvider);
  final syncer = FirestoreDriftSyncer(
    firestore: firestore,
    leaderboardDao: leaderboardDao,
    tribeStatsDao: tribeStatsDao,
  );
  final socialActivity = ref.read(socialActivityServiceProvider);
  final friendRepo = ref.read(friendRepositoryProvider);
  final dao = ref.read(habitCompletionsDaoProvider);
  final notificationService = ref.read(socialNotificationServiceProvider);
  final watchdog = StreakWatchdog(
    friendRepo: friendRepo,
    habitCompletionsDao: dao,
    notificationService: notificationService,
  );
  final service = TribeLoopService(
    socialActivity: socialActivity,
    streakWatchdog: watchdog,
    driftSyncer: syncer,
  );

  // Start drift sync when user has an active tribe
  ref.listen(activeMembershipProvider, (prev, next) {
    final membership = next.valueOrNull;
    if (membership != null) {
      service.startDriftSync(membership.tribeId);
    } else {
      service.stopDriftSync();
    }
  });

  ref.onDispose(() => service.dispose());
  return service;
}
```

- [ ] **Step 4: Update TribeLoopService tests for syncer**

In `test/features/social/domain/services/tribe_loop_service_test.dart`, update the constructor call:
```dart
service = TribeLoopService(
  socialActivity: mockSocial,
  streakWatchdog: mockWatchdog,
  driftSyncer: null,
);
```

- [ ] **Step 5: Run full analysis**

```bash
dart analyze lib/features/social/
```

Expected: 0 errors, 0 warnings (pre-existing tribe_card.dart errors acceptable)

- [ ] **Step 6: Run all regression tests**

```bash
flutter test test/features/social/domain/services/ --timeout 30s
```

Expected: All 7+ tests pass (3 from StreakWatchdog + 6 from TribeLoopService + 3 from FirestoreDriftSyncer)

- [ ] **Step 7: Commit**

```bash
git add lib/features/social/domain/services/tribe_loop_service.dart \
       test/features/social/domain/services/tribe_loop_service_test.dart \
       lib/features/social/presentation/providers/tribes_provider.dart
git commit -m "feat: wire FirestoreDriftSyncer into TribeLoopService at boot"
```

---

### Task 6: Final Verification

- [ ] **Step 1: Full analysis**

```bash
dart analyze
```

Expected: 0 errors, 0 warnings

- [ ] **Step 2: Run all focused tests**

```bash
flutter test test/features/social/domain/services/ --timeout 30s
```

Expected: All passing

- [ ] **Step 3: Build runner**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: 0 errors

- [ ] **Step 4: Commit final**

```bash
git add -A
git commit -m "chore: finalize tribe engagement loop closure — all tests pass"
```
