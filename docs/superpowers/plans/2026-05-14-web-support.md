# Web Support Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enable `flutter build web` by replacing native-only Drift/SQLite with direct Firestore access on web.

**Architecture:** Mobile keeps Drift + SQLite + sync engine. Web reads/writes Firestore directly with no local cache. Provider layer routes to the correct repository based on `kIsWeb`.

**Tech Stack:** Flutter, Firestore, Drift (mobile only), Riverpod, Mocktail (tests)

**Spec reference:** `docs/superpowers/specs/2026-05-14-web-support-design.md`

---

### Task 1: Guard Drift database and sync engine for web

**Files:**
- Modify: `lib/core/drift/database.dart`
- Modify: `lib/core/sync/sync_engine.dart`
- Modify: `lib/core/sync/sync_providers.dart`
- Modify: `lib/core/sync/sync_trigger_service.dart`

- [ ] **Step 1: Guard AppDatabase in database.dart**

Add `import 'package:flutter/foundation.dart' show kIsWeb;` and a `!kIsWeb` guard:

```dart
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
// ... rest of imports

@Riverpod(keepAlive: true)
AppDatabase? appDatabase(Ref ref) {
  if (kIsWeb) return null;
  return AppDatabase.instance;
}

@Riverpod(keepAlive: true)
UserStatsDao? userStatsDao(Ref ref) {
  return ref.watch(appDatabaseProvider)?.userStatsDao;
}
// Same pattern for all DAO providers
```

- [ ] **Step 2: Guard all DAO providers in database.dart**

Every `@Riverpod(keepAlive: true)` DAO provider returns `null` on web:
- `userStatsDao`
- `habitsDao`
- `habitCompletionsDao`
- `challengeProgressDao`
- `tribeStatsDao`
- `leaderboardEntriesDao`
- `blueprintsDao`
- `mutationQueueDao`
- `tribeActivityDao`

Change provider return types to nullable (`UserStatsDao?`, `HabitsDao?`, etc.).

- [ ] **Step 3: Guard sync engine**

```dart
// lib/core/sync/sync_engine.dart
import 'package:flutter/foundation.dart' show kIsWeb;

class EnhancedSyncEngine {
  // ...existing code, no constructor changes
}
```

- [ ] **Step 4: Guard sync providers**

```dart
// lib/core/sync/sync_providers.dart
import 'package:flutter/foundation.dart' show kIsWeb;

@Riverpod(keepAlive: true)
EnhancedSyncEngine? enhancedSyncEngine(Ref ref) {
  if (kIsWeb) return null;
  // ...existing creation code
  return engine;
}

@Riverpod(keepAlive: true)
SyncTriggerService? syncTriggerService(Ref ref) {
  if (kIsWeb) return null;
  // ...existing creation code
}
```

- [ ] **Step 5: Commit**

```bash
git add lib/core/drift/database.dart lib/core/sync/sync_engine.dart lib/core/sync/sync_providers.dart lib/core/sync/sync_trigger_service.dart
git commit -m "feat(web): guard Drift DB and sync engine with kIsWeb"
```

---

### Task 2: Create Firestore habit repository

**Files:**
- Create: `lib/core/firestore_repositories/firestore_habit_repository.dart`

- [ ] **Step 1: Create the file**

```dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/domain/models/habit_activity.dart';
import 'package:emerge_app/features/habits/domain/repositories/habit_repository.dart';
import 'package:emerge_app/features/blueprints/domain/models/blueprint.dart';
import 'package:fpdart/fpdart.dart';

class FirestoreHabitRepository implements HabitRepository {
  final FirebaseFirestore _firestore;

  FirestoreHabitRepository(this._firestore);

  @override
  Stream<List<Habit>> watchHabits(String userId) {
    return _firestore
        .collection('habits')
        .where('userId', isEqualTo: userId)
        .where('isArchived', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Habit.fromMap(doc.data()))
            .toList());
  }

  @override
  Future<Either<Failure, Unit>> createHabit(Habit habit) async {
    try {
      await _firestore.collection('habits').doc(habit.id).set(habit.toMap());
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateHabit(Habit habit) async {
    try {
      await _firestore.collection('habits').doc(habit.id).update(habit.toMap());
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteHabit(String habitId) async {
    try {
      await _firestore.collection('habits').doc(habitId).update({'isArchived': true});
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> completeHabit(String habitId, DateTime date) async {
    // Web uses Firestore — game loop runs on server via Cloud Functions
    // Client just logs the completion; server processes XP
    try {
      await _firestore.collection('habit_completions').add({
        'habitId': habitId,
        'completedAt': date.toIso8601String(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      return const Right(true);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Habit?> getHabit(String habitId) async {
    final doc = await _firestore.collection('habits').doc(habitId).get();
    if (!doc.exists) return null;
    return Habit.fromMap(doc.data()!);
  }

  @override
  Future<List<Habit>> getHabitsByAnchor(String anchorHabitId) async {
    final snapshot = await _firestore
        .collection('habits')
        .where('anchorHabitId', isEqualTo: anchorHabitId)
        .where('isArchived', isEqualTo: false)
        .get();
    return snapshot.docs.map((doc) => Habit.fromMap(doc.data())).toList();
  }

  @override
  Future<List<HabitActivity>> getActivity(String userId, DateTime start, DateTime end) async {
    final snapshot = await _firestore
        .collection('habit_completions')
        .where('userId', isEqualTo: userId)
        .where('completedAt', isGreaterThanOrEqualTo: start.toIso8601String())
        .where('completedAt', isLessThanOrEqualTo: end.toIso8601String())
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return HabitActivity(
        id: doc.id,
        habitId: data['habitId'] as String,
        userId: userId,
        date: DateTime.parse(data['completedAt'] as String),
        type: 'habit_completion',
      );
    }).toList();
  }

  @override
  Future<Either<Failure, Unit>> createHabitsFromBlueprint({
    required String userId,
    required Blueprint blueprint,
    String? reminderTime,
  }) async {
    try {
      final batch = _firestore.batch();
      for (int i = 0; i < blueprint.habits.length; i++) {
        final h = blueprint.habits[i];
        final habitId = '${blueprint.id}_${i}_${DateTime.now().millisecondsSinceEpoch}';
        final ref = _firestore.collection('habits').doc(habitId);
        batch.set(ref, {
          'id': habitId,
          'userId': userId,
          'title': h.title,
          'attribute': h.attribute.name,
          'createdAt': DateTime.now().toIso8601String(),
          'isArchived': false,
        });
      }
      await batch.commit();
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/core/firestore_repositories/firestore_habit_repository.dart
git commit -m "feat(web): add Firestore habit repository for web"
```

---

### Task 3: Create Firestore user stats repository

**Files:**
- Create: `lib/core/firestore_repositories/firestore_user_stats_repository.dart`
- Reference: `lib/core/drift_repositories/drift_user_stats_repository.dart`

- [ ] **Step 1: Create the file**

Mirrors the `DriftUserStatsRepository` interface but writes to Firestore directly:

```dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';

class FirestoreUserStatsRepository {
  final FirebaseFirestore _firestore;

  FirestoreUserStatsRepository(this._firestore);

  Future<void> saveUserStats(UserProfile profile) async {
    final profileMap = profile.toMap();
    profileMap['updatedAt'] = DateTime.now().toIso8601String();

    await _firestore.collection('user_stats').doc(profile.uid).set(
      profileMap,
      SetOptions(merge: true),
    );

    await _firestore.collection('users').doc(profile.uid).update({
      'archetype': profile.archetype.name,
      'level': profile.avatarStats.level,
      'streak': profile.avatarStats.streak,
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> syncUserIdentity(UserProfile profile) async {
    await saveUserStats(profile);
  }

  Stream<UserProfile> watchUserStats(String uid) {
    return _firestore
        .collection('user_stats')
        .doc(uid)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return UserProfile(uid: uid);
      return UserProfile.fromMap(snapshot.data()!);
    });
  }

  Future<UserProfile> getUserStats(String uid) async {
    final doc = await _firestore.collection('user_stats').doc(uid).get();
    if (!doc.exists) return UserProfile(uid: uid);
    return UserProfile.fromMap(doc.data()!);
  }

  // Include updateWorldHealth, updateStreak, unlockBuilding, startMission,
  // completeMission, emerge — all via Firestore write with SetOptions(merge: true)
  Future<void> updateWorldHealth(String uid, int score) async {
    await _firestore.collection('user_stats').doc(uid).update({
      'worldState.entropy': 1.0 - (score / 100.0),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> updateStreak(String uid, int streak) async {
    await _firestore.collection('user_stats').doc(uid).update({
      'avatarStats.streak': streak,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<Map<String, dynamic>?> getLatestRecap(String userId) async {
    final snapshot = await _firestore
        .collection('user_stats')
        .doc(userId)
        .collection('recaps')
        .orderBy('endDate', descending: true)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return snapshot.docs.first.data();
  }

  Future<Map<String, dynamic>?> getRecap(String userId, String recapId) async {
    final doc = await _firestore
        .collection('user_stats')
        .doc(userId)
        .collection('recaps')
        .doc(recapId)
        .get();
    return doc.data();
  }

  Future<List<Map<String, dynamic>>> getRecaps(String userId, {int limit = 10}) async {
    final snapshot = await _firestore
        .collection('user_stats')
        .doc(userId)
        .collection('recaps')
        .orderBy('endDate', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<void> saveRecap(String userId, Map<String, dynamic> recapData) async {
    await _firestore
        .collection('user_stats')
        .doc(userId)
        .collection('recaps')
        .add(recapData);
  }

  Future<UserStatsController>? Function() get updateWorldHealthWrapper => null;

  Future<void> saveContract(HabitContract contract) async {
    await _firestore.collection('contracts').doc(contract.id).set(contract.toMap());
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/core/firestore_repositories/firestore_user_stats_repository.dart
git commit -m "feat(web): add Firestore user stats repository for web"
```

---

### Task 4: Create remaining Firestore repositories

**Files:**
- Create: `lib/core/firestore_repositories/firestore_challenge_repository.dart`
- Create: `lib/core/firestore_repositories/firestore_tribe_repository.dart`
- Create: `lib/core/firestore_repositories/firestore_leaderboard_repository.dart`
- Create: `lib/core/firestore_repositories/firestore_friend_repository.dart`

- [ ] **Step 1: Firestore challenge repository**

Create a class that mirrors `DriftChallengeRepository` — all Firestore reads/writes, no local DB.

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/features/social/domain/repositories/challenge_repository.dart';
// ... implement ChallengeRepository interface with Firestore calls
```

- [ ] **Step 2: Firestore tribe repository**

```dart
// Mirrors DriftTribeRepository — Firestore reads/writes for tribes, contributors, activity
```

- [ ] **Step 3: Firestore leaderboard repository**

```dart
// Mirrors DriftLeaderboardRepository — Firestore reads/writes for leaderboard entries
```

- [ ] **Step 4: Firestore friend repository**

```dart
// Mirrors DriftFriendRepository — Firestore reads/writes for friends
```

- [ ] **Step 5: Commit**

```bash
git add lib/core/firestore_repositories/
git commit -m "feat(web): add Firestore challenge, tribe, leaderboard, friend repositories"
```

---

### Task 5: Route providers based on kIsWeb

**Files:**
- Modify: `lib/features/habits/presentation/providers/habit_providers.dart`
- Modify: `lib/features/gamification/presentation/providers/gamification_providers.dart`
- Modify: `lib/features/gamification/presentation/providers/user_stats_providers.dart`
- Modify: `lib/features/social/presentation/providers/tribes_provider.dart`
- Modify: `lib/features/social/presentation/providers/challenge_provider.dart`
- Modify: `lib/features/social/presentation/providers/friends_leaderboard_provider.dart`
- Modify: `lib/features/social/presentation/providers/challenge_bundle_provider.dart`

- [ ] **Step 1: Route habitRepositoryProvider**

```dart
// lib/features/habits/presentation/providers/habit_providers.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:emerge_app/core/firestore_repositories/firestore_habit_repository.dart';

@Riverpod(keepAlive: true)
HabitRepository habitRepository(Ref ref) {
  if (kIsWeb) {
    return FirestoreHabitRepository(FirebaseFirestore.instance);
  }
  final db = ref.watch(appDatabaseProvider);
  final engine = LocalGameLoopEngine();
  final syncEngine = ref.watch(enhancedSyncEngineProvider);
  final socialService = ref.watch(socialActivityServiceProvider);
  return DriftHabitRepository(
    db: db!,
    gameLoopEngine: engine,
    syncEngine: syncEngine!,
    socialService: socialService,
  );
}
```

- [ ] **Step 2: Route userStatsRepositoryProvider**

```dart
// lib/features/gamification/presentation/providers/user_stats_providers.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:emerge_app/core/firestore_repositories/firestore_user_stats_repository.dart';

final userStatsRepositoryProvider = Provider<DriftUserStatsRepository>((ref) {
  if (kIsWeb) {
    return FirestoreUserStatsRepository(FirebaseFirestore.instance);
  }
  final db = ref.watch(appDatabaseProvider)!;
  final syncEngine = ref.watch(enhancedSyncEngineProvider)!;
  return DriftUserStatsRepository(db, syncEngine);
});
```

- [ ] **Step 3: Route tribe, challenge, leaderboard, friend providers**

Same pattern — return `Firestore*Repository` on web, `Drift*Repository` on mobile.

- [ ] **Step 4: Commit**

```bash
git add lib/features/habits/presentation/providers/habit_providers.dart lib/features/gamification/presentation/providers/gamification_providers.dart lib/features/gamification/presentation/providers/user_stats_providers.dart lib/features/social/presentation/providers/tribes_provider.dart lib/features/social/presentation/providers/challenge_provider.dart lib/features/social/presentation/providers/friends_leaderboard_provider.dart
git commit -m "feat(web): route repositories based on kIsWeb at provider level"
```

---

### Task 6: Fix remaining native-only compilation errors

**Files:**
- Modify: `lib/features/onboarding/data/repositories/local_settings_repository.dart`
- Modify: `lib/main.dart`
- Modify: `lib/core/security/app_security.dart`
- Modify: `lib/core/network/secure_http_client.dart`
- Modify: `lib/features/monetization/domain/services/ad_manager_service.dart`
- Modify: `lib/features/monetization/presentation/widgets/ad_banner_widget.dart`
- Modify: `lib/features/world_map/presentation/screens/level_immersive_screen.dart`
- Modify: `lib/features/timeline/presentation/widgets/timeline_share_preview.dart`

- [ ] **Step 1: Fix dart:io imports**

For each file with `import 'dart:io'`, add a `kIsWeb` guard or wrap the usage:
- `dart:io` types like `File`, `Platform`, `InternetAddress` won't compile on web
- Wrap the specific method/class that uses them, or guard the entire import with conditional exports

- [ ] **Step 2: Fix local_settings_repository.dart**

Hive + path_provider are native-only. Guard with `kIsWeb`:

```dart
if (kIsWeb) {
  // Use SharedPreferences or in-memory storage on web
} else {
  // Use Hive on mobile
}
```

- [ ] **Step 3: Guard main.dart**

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initApp();

  if (!kIsWeb) {
    // Mobile-specific initializations: Drift, Hive, notifications
  }

  runApp(const ProviderScope(child: EmergeApp()));
}
```

- [ ] **Step 4: Commit**

```bash
git add lib/main.dart lib/features/onboarding/data/repositories/local_settings_repository.dart lib/core/security/app_security.dart lib/core/network/secure_http_client.dart lib/features/monetization/ lib/features/world_map/ lib/features/timeline/
git commit -m "fix(web): guard native-only dart:io imports and Hive storage"
```

---

### Task 7: Build and verify web compilation

- [ ] **Step 1: Run flutter build web**

```bash
flutter build web
```
Expected: Compilation succeeds.

- [ ] **Step 2: Fix any remaining compilation errors**

Iterate on any remaining `dart:ffi`, `dart:io`, or native package errors until web build passes.

- [ ] **Step 3: Run existing tests**

```bash
flutter test
```
Expected: All 198 tests still pass (they mock repositories, so provider routing doesn't affect them).

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "fix(web): resolve remaining compilation errors for web build"
```
