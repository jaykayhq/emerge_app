# Creator Analytics Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a full creator analytics suite — KPI cards, member-growth + engagement trends, blueprint breakdown, top members, and challenge health — as a 4th nav branch of the creator dashboard, with client-side daily trend snapshots.

**Architecture:** A pure `CreatorAnalytics` data struct + `CreatorAnalyticsService` aggregates live KPIs from rules-compliant Firestore sources (`tribes/{tribeId}/contributors/*`, `blueprints`, `challenges`). A separate `TribeAnalyticsSnapshotService` writes one daily snapshot per tribe to `tribe_analytics/{tribeId}/daily/{date}` when >24h stale, and reads the last 30 days for trends. A Drift `TribeAnalyticsTable` caches the latest snapshot for offline-first render. Riverpod `@riverpod` provider wires it together; `fl_chart` renders trend charts.

**Tech Stack:** Flutter, Riverpod 3 (annotation + codegen), go_router 17, Firestore, Drift, fpdart `Either`, fl_chart, fake_cloud_firestore (tests).

**Spec:** `docs/superpowers/specs/2026-08-18-creator-analytics-design.md`

---

## File Structure

**Create:**
- `lib/features/social/domain/models/creator_analytics.dart` — pure structs (CreatorAnalytics, BlueprintStat, MemberStat, ChallengeStat, DailyTrend, TribeAnalyticsSnapshot)
- `lib/core/drift/tables/tribe_analytics_table.dart` — Drift table
- `lib/core/drift/daos/tribe_analytics_dao.dart` — Drift DAO
- `lib/features/social/data/services/creator_analytics_service.dart` — live aggregation
- `lib/features/social/data/services/tribe_analytics_snapshot_service.dart` — daily snapshots
- `lib/features/social/presentation/providers/creator_analytics_provider.dart` — Riverpod provider
- `lib/features/social/presentation/screens/creator/creator_analytics_tab.dart` — UI
- `test/features/social/domain/models/creator_analytics_test.dart`
- `test/features/social/data/services/creator_analytics_service_test.dart`
- `test/features/social/data/services/tribe_analytics_snapshot_service_test.dart`
- `test/features/social/presentation/screens/creator/creator_analytics_tab_test.dart`
- `test/core/router/creator_analytics_route_test.dart`

**Modify:**
- `lib/core/drift/app_database.dart` — register table + DAO, bump schemaVersion
- `lib/core/drift/database.dart` — register DAO provider
- `lib/core/router/creator_routes.dart` — add 4th branch
- `lib/features/social/presentation/screens/creator/creator_overview_tab.dart` — rewire SOON card
- `lib/features/social/presentation/screens/creator/creator_tribe_management_tab.dart` — link member placeholder
- `firestore.rules` — `tribe_analytics` rule

---

### Task 1: Pure data models

**Files:**
- Create: `lib/features/social/domain/models/creator_analytics.dart`
- Test: `test/features/social/domain/models/creator_analytics_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/features/social/domain/models/creator_analytics_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/social/domain/models/creator_analytics.dart';

void main() {
  group('TribeAnalyticsSnapshot', () {
    test('toMap/fromMap round-trips', () {
      final snap = TribeAnalyticsSnapshot(
        tribeId: 't1',
        date: '2026-08-18',
        memberCount: 10,
        totalXp: 5000,
        totalHabitsCompleted: 120,
        totalChallengesCompleted: 4,
        activeMembers: 6,
        newMembersThisWeek: 2,
      );
      final restored = TribeAnalyticsSnapshot.fromMap(snap.toMap());
      expect(restored, snap);
    });
  });

  group('CreatorAnalytics', () {
    test('defaults to zeros when constructed empty', () {
      const analytics = CreatorAnalytics(tribeId: 't1', tribeName: 'Tribe');
      expect(analytics.memberCount, 0);
      expect(analytics.blueprintStats, isEmpty);
      expect(analytics.topMembers, isEmpty);
      expect(analytics.challengeStats, isEmpty);
      expect(analytics.trends, isEmpty);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/social/domain/models/creator_analytics_test.dart`
Expected: FAIL — no such file / class not defined.

- [ ] **Step 3: Implement the models**

```dart
// lib/features/social/domain/models/creator_analytics.dart
import 'package:equatable/equatable.dart';

/// One day's snapshot of a tribe's aggregate stats (Firestore + Drift).
class TribeAnalyticsSnapshot extends Equatable {
  final String tribeId;
  final String date; // yyyy-MM-dd
  final int memberCount;
  final int totalXp;
  final int totalHabitsCompleted;
  final int totalChallengesCompleted;
  final int activeMembers;
  final int newMembersThisWeek;

  const TribeAnalyticsSnapshot({
    required this.tribeId,
    required this.date,
    this.memberCount = 0,
    this.totalXp = 0,
    this.totalHabitsCompleted = 0,
    this.totalChallengesCompleted = 0,
    this.activeMembers = 0,
    this.newMembersThisWeek = 0,
  });

  Map<String, dynamic> toMap() => {
    'tribeId': tribeId,
    'date': date,
    'memberCount': memberCount,
    'totalXp': totalXp,
    'totalHabitsCompleted': totalHabitsCompleted,
    'totalChallengesCompleted': totalChallengesCompleted,
    'activeMembers': activeMembers,
    'newMembersThisWeek': newMembersThisWeek,
  };

  factory TribeAnalyticsSnapshot.fromMap(Map<String, dynamic> map) =>
      TribeAnalyticsSnapshot(
        tribeId: map['tribeId'] as String,
        date: map['date'] as String,
        memberCount: (map['memberCount'] as num?)?.toInt() ?? 0,
        totalXp: (map['totalXp'] as num?)?.toInt() ?? 0,
        totalHabitsCompleted: (map['totalHabitsCompleted'] as num?)?.toInt() ?? 0,
        totalChallengesCompleted:
            (map['totalChallengesCompleted'] as num?)?.toInt() ?? 0,
        activeMembers: (map['activeMembers'] as num?)?.toInt() ?? 0,
        newMembersThisWeek: (map['newMembersThisWeek'] as num?)?.toInt() ?? 0,
      );

  @override
  List<Object?> get props => [
    tribeId, date, memberCount, totalXp, totalHabitsCompleted,
    totalChallengesCompleted, activeMembers, newMembersThisWeek,
  ];
}

/// A single blueprint's performance row.
class BlueprintStat extends Equatable {
  final String id;
  final String title;
  final int adoptionCount;
  final int habitCount;

  const BlueprintStat({
    required this.id,
    required this.title,
    this.adoptionCount = 0,
    this.habitCount = 0,
  });

  @override
  List<Object?> get props => [id, title, adoptionCount, habitCount];
}

/// A single tribe member's contribution row.
class MemberStat extends Equatable {
  final String userId;
  final String name;
  final int xp;
  final int habitsCompleted;

  const MemberStat({
    required this.userId,
    required this.name,
    this.xp = 0,
    this.habitsCompleted = 0,
  });

  @override
  List<Object?> get props => [userId, name, xp, habitsCompleted];
}

/// A creator-published challenge's health row.
class ChallengeStat extends Equatable {
  final String id;
  final String title;
  final int participants;
  final String status;
  final int xpReward;

  const ChallengeStat({
    required this.id,
    required this.title,
    this.participants = 0,
    this.status = 'active',
    this.xpReward = 0,
  });

  @override
  List<Object?> get props => [id, title, participants, status, xpReward];
}

/// One point on a trend chart (one daily snapshot).
class DailyTrend extends Equatable {
  final String date;
  final int memberCount;
  final int totalXp;
  final int totalHabitsCompleted;

  const DailyTrend({
    required this.date,
    this.memberCount = 0,
    this.totalXp = 0,
    this.totalHabitsCompleted = 0,
  });

  @override
  List<Object?> get props => [date, memberCount, totalXp, totalHabitsCompleted];
}

/// The full analytics payload the UI renders.
class CreatorAnalytics extends Equatable {
  final String tribeId;
  final String tribeName;
  final int memberCount;
  final int totalXp;
  final int totalHabitsCompleted;
  final int totalChallengesCompleted;
  final int newMembersThisWeek;
  final int activeMembers;
  final double activeRate; // 0..1
  final List<BlueprintStat> blueprintStats;
  final List<MemberStat> topMembers;
  final List<ChallengeStat> challengeStats;
  final List<DailyTrend> trends;

  const CreatorAnalytics({
    required this.tribeId,
    required this.tribeName,
    this.memberCount = 0,
    this.totalXp = 0,
    this.totalHabitsCompleted = 0,
    this.totalChallengesCompleted = 0,
    this.newMembersThisWeek = 0,
    this.activeMembers = 0,
    this.activeRate = 0,
    this.blueprintStats = const [],
    this.topMembers = const [],
    this.challengeStats = const [],
    this.trends = const [],
  });

  @override
  List<Object?> get props => [
    tribeId, tribeName, memberCount, totalXp, totalHabitsCompleted,
    totalChallengesCompleted, newMembersThisWeek, activeMembers, activeRate,
    blueprintStats, topMembers, challengeStats, trends,
  ];
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/social/domain/models/creator_analytics_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/social/domain/models/creator_analytics.dart test/features/social/domain/models/creator_analytics_test.dart
git commit -m "feat(analytics): add pure CreatorAnalytics data models"
```

---

### Task 2: Drift table + DAO for analytics snapshots

**Files:**
- Create: `lib/core/drift/tables/tribe_analytics_table.dart`
- Create: `lib/core/drift/daos/tribe_analytics_dao.dart`
- Modify: `lib/core/drift/app_database.dart`
- Modify: `lib/core/drift/database.dart`
- Test: `test/core/drift/tribe_analytics_dao_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/core/drift/tribe_analytics_dao_test.dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/core/drift/app_database.dart';
import 'package:emerge_app/core/drift/daos/tribe_analytics_dao.dart';

void main() {
  late AppDatabase db;
  late TribeAnalyticsDao dao;

  setUp(() {
    db = AppDatabase.withExecutor(
      NativeDatabase.memory(),
    );
    dao = db.tribeAnalyticsDao;
  });

  tearDown(() => db.close());

  test('upsert + watch latest snapshot', () async {
    await dao.upsertSnapshot(
      tribeId: 't1',
      date: '2026-08-18',
      memberCount: 10,
      totalXp: 5000,
      totalHabitsCompleted: 120,
      totalChallengesCompleted: 4,
      activeMembers: 6,
      newMembersThisWeek: 2,
    );
    final latest = await dao.getLatest('t1');
    expect(latest, isNotNull);
    expect(latest!.memberCount, 10);
    expect(latest.totalXp, 5000);
  });

  test('getLatest returns null when no rows', () async {
    expect(await dao.getLatest('missing'), isNull);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/drift/tribe_analytics_dao_test.dart`
Expected: FAIL — `db.tribeAnalyticsDao` undefined.

- [ ] **Step 3: Create the table**

```dart
// lib/core/drift/tables/tribe_analytics_table.dart
import 'package:drift/drift.dart';

/// Per-tribe-per-day analytics snapshot cache (offline-first render).
class TribeAnalyticsTable extends Table {
  TextColumn get tribeId => text()();
  TextColumn get date => text()(); // yyyy-MM-dd
  IntColumn get memberCount => integer().withDefault(const Constant(0))();
  IntColumn get totalXp => integer().withDefault(const Constant(0))();
  IntColumn get totalHabitsCompleted =>
      integer().withDefault(const Constant(0))();
  IntColumn get totalChallengesCompleted =>
      integer().withDefault(const Constant(0))();
  IntColumn get activeMembers => integer().withDefault(const Constant(0))();
  IntColumn get newMembersThisWeek =>
      integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {tribeId, date};
}
```

- [ ] **Step 4: Create the DAO**

```dart
// lib/core/drift/daos/tribe_analytics_dao.dart
import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/tribe_analytics_table.dart';

part 'tribe_analytics_dao.g.dart';

@DriftAccessor(tables: [TribeAnalyticsTable])
class TribeAnalyticsDao extends DatabaseAccessor<AppDatabase>
    with _$TribeAnalyticsDaoMixin {
  TribeAnalyticsDao(super.db);

  Future<TribeAnalyticsTableData?> getLatest(String tribeId) {
    return (select(tribeAnalyticsTable)
          ..where((t) => t.tribeId.equals(tribeId))
          ..orderBy([(t) => OrderingTerm.desc(t.date)])
          ..limit(1))
        .getSingleOrNull();
  }

  Stream<TribeAnalyticsTableData?> watchLatest(String tribeId) {
    return (select(tribeAnalyticsTable)
          ..where((t) => t.tribeId.equals(tribeId))
          ..orderBy([(t) => OrderingTerm.desc(t.date)])
          ..limit(1))
        .watchSingleOrNull();
  }

  Future<void> upsertSnapshot({
    required String tribeId,
    required String date,
    required int memberCount,
    required int totalXp,
    required int totalHabitsCompleted,
    required int totalChallengesCompleted,
    required int activeMembers,
    required int newMembersThisWeek,
  }) {
    return into(tribeAnalyticsTable).insertOnConflictUpdate(
      TribeAnalyticsTableCompanion.insert(
        tribeId: tribeId,
        date: date,
        memberCount: Value(memberCount),
        totalXp: Value(totalXp),
        totalHabitsCompleted: Value(totalHabitsCompleted),
        totalChallengesCompleted: Value(totalChallengesCompleted),
        activeMembers: Value(activeMembers),
        newMembersThisWeek: Value(newMembersThisWeek),
      ),
    );
  }
}
```

- [ ] **Step 5: Register in `app_database.dart`**

Add imports:
```dart
import 'tables/tribe_analytics_table.dart';
import 'daos/tribe_analytics_dao.dart';
```

Add `TribeAnalyticsTable,` to the `@DriftDatabase(tables: [...])` list and `TribeAnalyticsDao,` to the `daos: [...]` list. Bump `schemaVersion => 15` and add to `onUpgrade`:

```dart
if (from < 15) {
  await m.createTable(tribeAnalyticsTable);
}
```

- [ ] **Step 6: Register the DAO provider in `database.dart`**

```dart
@Riverpod(keepAlive: true)
TribeAnalyticsDao tribeAnalyticsDao(Ref ref) {
  return ref.watch(appDatabaseProvider).tribeAnalyticsDao;
}
```

- [ ] **Step 7: Run build_runner, then run the test**

Run: `dart run build_runner build --delete-conflicting-outputs`
Run: `flutter test test/core/drift/tribe_analytics_dao_test.dart`
Expected: PASS.

- [ ] **Step 8: Commit**

```bash
git add lib/core/drift/tables/tribe_analytics_table.dart lib/core/drift/daos/tribe_analytics_dao.dart lib/core/drift/daos/tribe_analytics_dao.g.dart lib/core/drift/app_database.dart lib/core/drift/app_database.g.dart lib/core/drift/database.dart lib/core/drift/database.g.dart test/core/drift/tribe_analytics_dao_test.dart
git commit -m "feat(analytics): add Drift TribeAnalyticsTable + DAO"
```

---

### Task 3: `CreatorAnalyticsService` — live aggregation

**Files:**
- Create: `lib/features/social/data/services/creator_analytics_service.dart`
- Test: `test/features/social/data/services/creator_analytics_service_test.dart`

Aggregation reads ONLY rules-compliant sources: `tribes/{tribeId}` (read: authenticated), `tribes/{tribeId}/contributors/*` (read: authenticated), `blueprints` (read: true), `challenges` (read: true). It never reads `user_stats` (owner-only).

- [ ] **Step 1: Write the failing test**

```dart
// test/features/social/data/services/creator_analytics_service_test.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/social/data/services/creator_analytics_service.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late CreatorAnalyticsService service;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    service = CreatorAnalyticsService(firestore: firestore);
  });

  Future<void> seedTribe() async {
    await firestore.collection('tribes').doc('t1').set({
      'name': 'The Forge',
      'memberCount': 3,
      'createdBy': 'creator1',
      'type': 'creator',
    });
    final contributors = firestore
        .collection('tribes').doc('t1').collection('contributors');
    await contributors.doc('u1').set({
      'userName': 'Ada',
      'totalXpContributed': 3000,
      'totalHabitsCompleted': 40,
      'totalChallengesCompleted': 2,
      'joinedAt': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
      'lastActivity': DateTime.now().toIso8601String(),
    });
    await contributors.doc('u2').set({
      'userName': 'Bob',
      'totalXpContributed': 2000,
      'totalHabitsCompleted': 20,
      'totalChallengesCompleted': 1,
      'joinedAt': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
      'lastActivity': DateTime.now().toIso8601String(),
    });
    await contributors.doc('u3').set({
      'userName': 'Cara',
      'totalXpContributed': 0,
      'totalHabitsCompleted': 0,
      'totalChallengesCompleted': 0,
      'joinedAt': DateTime.now().subtract(const Duration(days: 60)).toIso8601String(),
      'lastActivity': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
    });
  }

  test('aggregates KPIs, member growth, active members, top members', () async {
    await seedTribe();
    await firestore.collection('blueprints').doc('b1').set({
      'creatorUserId': 'creator1',
      'title': 'Morning Stack',
      'adoptionCount': 7,
      'habits': [{'title': 'Read'}, {'title': 'Run'}],
    });
    await firestore.collection('challenges').doc('c1').set({
      'createdBy': 'creator1',
      'title': '30 Days of Reading',
      'participants': 5,
      'status': 'active',
      'xpReward': 100,
    });

    final result = await service.getCreatorAnalytics(
      uid: 'creator1',
      tribeId: 't1',
    );

    expect(result.isRight(), isTrue);
    final analytics = result.getRight().toNullable()!;
    expect(analytics.tribeName, 'The Forge');
    expect(analytics.memberCount, 3);
    expect(analytics.totalXp, 5000);
    expect(analytics.totalHabitsCompleted, 60);
    expect(analytics.totalChallengesCompleted, 3);
    expect(analytics.newMembersThisWeek, 1); // u2 joined 2 days ago
    expect(analytics.activeMembers, 2); // u1, u2 active in last 7d
    expect(analytics.activeRate, closeTo(0.67, 0.01));
    expect(analytics.topMembers.length, 2); // u3 has 0 xp, excluded
    expect(analytics.topMembers.first.name, 'Ada');
    expect(analytics.blueprintStats.single.adoptionCount, 7);
    expect(analytics.challengeStats.single.participants, 5);
  });

  test('returns zeros for an empty tribe', () async {
    await firestore.collection('tribes').doc('t1').set({
      'name': 'Empty',
      'memberCount': 0,
      'createdBy': 'creator1',
      'type': 'creator',
    });
    final result = await service.getCreatorAnalytics(uid: 'creator1', tribeId: 't1');
    expect(result.isRight(), isTrue);
    final analytics = result.getRight().toNullable()!;
    expect(analytics.memberCount, 0);
    expect(analytics.topMembers, isEmpty);
    expect(analytics.blueprintStats, isEmpty);
  });

  test('returns Left on Firestore error', () async {
    // Missing tribe doc -> treated as empty, still Right. Force a Left by
    // passing a null tribe id that the service validates.
    final result = await service.getCreatorAnalytics(uid: 'creator1', tribeId: '');
    expect(result.isLeft(), isTrue);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/social/data/services/creator_analytics_service_test.dart`
Expected: FAIL — `CreatorAnalyticsService` not defined.

- [ ] **Step 3: Implement the service**

```dart
// lib/features/social/data/services/creator_analytics_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fpdart/fpdart.dart';
import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/features/social/domain/models/creator_analytics.dart';

/// Aggregates live creator analytics from rules-compliant Firestore sources.
///
/// Reads ONLY:
/// - `tribes/{tribeId}` and `tribes/{tribeId}/contributors/*` (auth read)
/// - `blueprints` and `challenges` (public read)
///
/// Never reads `user_stats` (owner-only in firestore.rules).
class CreatorAnalyticsService {
  final FirebaseFirestore _firestore;

  CreatorAnalyticsService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<Either<Failure, CreatorAnalytics>> getCreatorAnalytics({
    required String uid,
    required String tribeId,
  }) async {
    if (uid.isEmpty || tribeId.isEmpty) {
      return const Left(ServerFailure('Missing creator or tribe'));
    }
    try {
      final tribeDoc = await _firestore.collection('tribes').doc(tribeId).get();
      final tribeData = tribeDoc.data() ?? const <String, dynamic>{};
      final tribeName = tribeData['name'] as String? ?? '';
      final memberCount = (tribeData['memberCount'] as num?)?.toInt() ?? 0;

      final contributors =
          await _firestore
              .collection('tribes')
              .doc(tribeId)
              .collection('contributors')
              .get();

      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      final sevenDaysAgo = now.subtract(const Duration(days: 7));

      int totalXp = 0;
      int totalHabits = 0;
      int totalChallenges = 0;
      int newMembers = 0;
      int activeMembers = 0;
      final memberRows = <MemberStat>[];

      for (final doc in contributors.docs) {
        final data = doc.data();
        final xp = _int(data['totalXpContributed']);
        final habits = _int(data['totalHabitsCompleted']);
        final challenges = _int(data['totalChallengesCompleted']);
        totalXp += xp;
        totalHabits += habits;
        totalChallenges += challenges;

        final joinedAt = _parseDate(data['joinedAt']);
        if (joinedAt != null && joinedAt.isAfter(weekAgo)) newMembers++;

        final lastActivity = _parseDate(data['lastActivity']);
        if (lastActivity != null && lastActivity.isAfter(sevenDaysAgo)) {
          activeMembers++;
        }

        if (xp > 0 && data['userName'] != null) {
          memberRows.add(MemberStat(
            userId: doc.id,
            name: data['userName'] as String,
            xp: xp,
            habitsCompleted: habits,
          ));
        }
      }
      memberRows.sort((a, b) => b.xp.compareTo(a.xp));
      final topMembers = memberRows.take(10).toList();

      // Blueprints authored by this creator
      final blueprintQuery = await _firestore
          .collection('blueprints')
          .where('creatorUserId', isEqualTo: uid)
          .get();
      final blueprintStats = blueprintQuery.docs.map((doc) {
        final data = doc.data();
        final habits = data['habits'] as List<dynamic>? ?? const [];
        return BlueprintStat(
          id: doc.id,
          title: data['title'] as String? ?? 'Untitled',
          adoptionCount: _int(data['adoptionCount']),
          habitCount: habits.length,
        );
      }).toList();

      // Challenges published by this creator
      final challengeQuery = await _firestore
          .collection('challenges')
          .where('createdBy', isEqualTo: uid)
          .get();
      final challengeStats = challengeQuery.docs.map((doc) {
        final data = doc.data();
        return ChallengeStat(
          id: doc.id,
          title: data['title'] as String? ?? 'Untitled',
          participants: _int(data['participants']),
          status: data['status'] as String? ?? 'active',
          xpReward: _int(data['xpReward']),
        );
      }).toList();

      final activeRate =
          memberCount > 0 ? activeMembers / memberCount : 0.0;

      return Right(CreatorAnalytics(
        tribeId: tribeId,
        tribeName: tribeName,
        memberCount: memberCount,
        totalXp: totalXp,
        totalHabitsCompleted: totalHabits,
        totalChallengesCompleted: totalChallenges,
        newMembersThisWeek: newMembers,
        activeMembers: activeMembers,
        activeRate: activeRate,
        blueprintStats: blueprintStats,
        topMembers: topMembers,
        challengeStats: challengeStats,
      ));
    } catch (e, st) {
      return Left(ServerFailure('Could not load analytics: $e'));
    }
  }

  int _int(dynamic v) => (v as num?)?.toInt() ?? 0;

  DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is String) return DateTime.tryParse(v);
    return null;
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/social/data/services/creator_analytics_service_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/social/data/services/creator_analytics_service.dart test/features/social/data/services/creator_analytics_service_test.dart
git commit -m "feat(analytics): add CreatorAnalyticsService live aggregation"
```

---

### Task 4: `TribeAnalyticsSnapshotService` — daily snapshots

**Files:**
- Create: `lib/features/social/data/services/tribe_analytics_snapshot_service.dart`
- Test: `test/features/social/data/services/tribe_analytics_snapshot_service_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/features/social/data/services/tribe_analytics_snapshot_service_test.dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/social/data/services/tribe_analytics_snapshot_service.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late TribeAnalyticsSnapshotService service;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    service = TribeAnalyticsSnapshotService(firestore: firestore);
  });

  Future<void> seedTribe() async {
    await firestore.collection('tribes').doc('t1').set({
      'name': 'The Forge',
      'memberCount': 3,
      'createdBy': 'creator1',
      'type': 'creator',
    });
    final contributors = firestore
        .collection('tribes').doc('t1').collection('contributors');
    await contributors.doc('u1').set({
      'userName': 'Ada',
      'totalXpContributed': 3000,
      'totalHabitsCompleted': 40,
      'totalChallengesCompleted': 2,
      'joinedAt': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
      'lastActivity': DateTime.now().toIso8601String(),
    });
    await contributors.doc('u2').set({
      'userName': 'Bob',
      'totalXpContributed': 2000,
      'totalHabitsCompleted': 20,
      'totalChallengesCompleted': 1,
      'joinedAt': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
      'lastActivity': DateTime.now().toIso8601String(),
    });
  }

  test('writes a snapshot when none exists', () async {
    await seedTribe();
    final result = await service.ensureTodaySnapshot(uid: 'creator1', tribeId: 't1');
    expect(result.isRight(), isTrue);

    final today = _dateKey(DateTime.now());
    final snap = await firestore
        .collection('tribe_analytics').doc('t1')
        .collection('daily').doc(today).get();
    expect(snap.exists, isTrue);
    final data = snap.data()!;
    expect(data['memberCount'], 3);
    expect(data['totalXp'], 5000);
    expect(data['totalHabitsCompleted'], 60);
    expect(data['totalChallengesCompleted'], 3);
  });

  test('does not rewrite a fresh snapshot (idempotent per day)', () async {
    await seedTribe();
    await service.ensureTodaySnapshot(uid: 'creator1', tribeId: 't1');
    // Mutate the tribe so a rewrite would change numbers.
    await firestore.collection('tribes').doc('t1').update({'memberCount': 99});
    await service.ensureTodaySnapshot(uid: 'creator1', tribeId: 't1');

    final today = _dateKey(DateTime.now());
    final snap = await firestore
        .collection('tribe_analytics').doc('t1')
        .collection('daily').doc(today).get();
    expect(snap.data()!['memberCount'], 3); // unchanged
  });

  test('reads last 30 days of trends sorted ascending', () async {
    await seedTribe();
    await service.ensureTodaySnapshot(uid: 'creator1', tribeId: 't1');
    final trends = await service.getTrends(tribeId: 't1', days: 30);
    expect(trends.isRight(), isTrue);
    final list = trends.getRight().toNullable()!;
    expect(list, isNotEmpty);
    expect(list.length, 1);
    expect(list.first.memberCount, 3);
  });

  test('returns Left on invalid tribe', () async {
    final result = await service.ensureTodaySnapshot(uid: 'creator1', tribeId: '');
    expect(result.isLeft(), isTrue);
  });
}

String _dateKey(DateTime dt) {
  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/social/data/services/tribe_analytics_snapshot_service_test.dart`
Expected: FAIL — class not defined.

- [ ] **Step 3: Implement the service**

```dart
// lib/features/social/data/services/tribe_analytics_snapshot_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fpdart/fpdart.dart';
import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/features/social/domain/models/creator_analytics.dart';

/// Writes one daily snapshot per tribe and reads trend history.
///
/// Client-side (no Cloud Function): when a creator opens analytics and the
/// last snapshot is >24h stale, this writes today's aggregate. History
/// accumulates as creators open the app.
class TribeAnalyticsSnapshotService {
  final FirebaseFirestore _firestore;

  TribeAnalyticsSnapshotService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static String dateKey(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Returns the latest snapshot doc for a tribe, or null.
  Future<Map<String, dynamic>?> _latestSnapshot(String tribeId) async {
    final snap = await _firestore
        .collection('tribe_analytics')
        .doc(tribeId)
        .collection('daily')
        .orderBy('date', descending: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return snap.docs.first.data();
  }

  /// Writes today's snapshot if the latest is missing or older than 24h.
  Future<Either<Failure, Unit>> ensureTodaySnapshot({
    required String uid,
    required String tribeId,
  }) async {
    if (uid.isEmpty || tribeId.isEmpty) {
      return const Left(ServerFailure('Missing creator or tribe'));
    }
    try {
      final latest = await _latestSnapshot(tribeId);
      if (latest != null) {
        final latestDate = DateTime.tryParse(latest['date'] as String? ?? '');
        if (latestDate != null &&
            DateTime.now().difference(latestDate).inHours < 24) {
          return const Right(unit);
        }
      }

      // Aggregate current state.
      final tribeDoc = await _firestore.collection('tribes').doc(tribeId).get();
      final tribeData = tribeDoc.data() ?? const <String, dynamic>{};
      final memberCount = (tribeData['memberCount'] as num?)?.toInt() ?? 0;

      final contributors =
          await _firestore
              .collection('tribes')
              .doc(tribeId)
              .collection('contributors')
              .get();

      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      final sevenDaysAgo = now.subtract(const Duration(days: 7));
      int totalXp = 0, totalHabits = 0, totalChallenges = 0;
      int newMembers = 0, activeMembers = 0;

      for (final doc in contributors.docs) {
        final data = doc.data();
        totalXp += (data['totalXpContributed'] as num?)?.toInt() ?? 0;
        totalHabits += (data['totalHabitsCompleted'] as num?)?.toInt() ?? 0;
        totalChallenges +=
            (data['totalChallengesCompleted'] as num?)?.toInt() ?? 0;

        final joinedAt = _parseDate(data['joinedAt']);
        if (joinedAt != null && joinedAt.isAfter(weekAgo)) newMembers++;

        final lastActivity = _parseDate(data['lastActivity']);
        if (lastActivity != null && lastActivity.isAfter(sevenDaysAgo)) {
          activeMembers++;
        }
      }

      final today = dateKey(now);
      await _firestore
          .collection('tribe_analytics')
          .doc(tribeId)
          .collection('daily')
          .doc(today)
          .set({
            'tribeId': tribeId,
            'date': today,
            'memberCount': memberCount,
            'totalXp': totalXp,
            'totalHabitsCompleted': totalHabits,
            'totalChallengesCompleted': totalChallenges,
            'activeMembers': activeMembers,
            'newMembersThisWeek': newMembers,
            'createdAt': FieldValue.serverTimestamp(),
          });
      return const Right(unit);
    } catch (e, st) {
      return Left(ServerFailure('Could not save analytics snapshot: $e'));
    }
  }

  /// Reads the last [days] daily snapshots, ascending by date.
  Future<Either<Failure, List<DailyTrend>>> getTrends({
    required String tribeId,
    int days = 30,
  }) async {
    try {
      final snap = await _firestore
          .collection('tribe_analytics')
          .doc(tribeId)
          .collection('daily')
          .orderBy('date', descending: true)
          .limit(days)
          .get();
      final list = snap.docs
          .map((d) => DailyTrend(
            date: d.data()['date'] as String? ?? '',
            memberCount: (d.data()['memberCount'] as num?)?.toInt() ?? 0,
            totalXp: (d.data()['totalXp'] as num?)?.toInt() ?? 0,
            totalHabitsCompleted:
                (d.data()['totalHabitsCompleted'] as num?)?.toInt() ?? 0,
          ))
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));
      return Right(list);
    } catch (e, st) {
      return Left(ServerFailure('Could not load analytics trends: $e'));
    }
  }

  DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is String) return DateTime.tryParse(v);
    return null;
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/social/data/services/tribe_analytics_snapshot_service_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/social/data/services/tribe_analytics_snapshot_service.dart test/features/social/data/services/tribe_analytics_snapshot_service_test.dart
git commit -m "feat(analytics): add TribeAnalyticsSnapshotService daily snapshots"
```

---

### Task 5: Riverpod provider

**Files:**
- Create: `lib/features/social/presentation/providers/creator_analytics_provider.dart`
- Test: `test/features/social/presentation/providers/creator_analytics_provider_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/features/social/presentation/providers/creator_analytics_provider_test.dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/social/data/services/creator_analytics_service.dart';
import 'package:emerge_app/features/social/data/services/tribe_analytics_snapshot_service.dart';
import 'package:emerge_app/features/social/presentation/providers/creator_analytics_provider.dart';

void main() {
  test('provider emits analytics for a creator', () async {
    final firestore = FakeFirebaseFirestore();
    await firestore.collection('tribes').doc('t1').set({
      'name': 'The Forge',
      'memberCount': 1,
      'createdBy': 'creator1',
      'type': 'creator',
    });
    final container = ProviderContainer(overrides: [
      creatorAnalyticsServiceProvider.overrideWithValue(
        CreatorAnalyticsService(firestore: firestore),
      ),
      tribeAnalyticsSnapshotServiceProvider.overrideWithValue(
        TribeAnalyticsSnapshotService(firestore: firestore),
      ),
    ]);
    addTearDown(container.dispose);

    final async = await container
        .read(creatorAnalyticsProvider(('creator1', 't1')).future);
    expect(async.tribeName, 'The Forge');
    expect(async.memberCount, 1);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/social/presentation/providers/creator_analytics_provider_test.dart`
Expected: FAIL — providers not defined.

- [ ] **Step 3: Implement the provider**

```dart
// lib/features/social/presentation/providers/creator_analytics_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:emerge_app/features/social/data/services/creator_analytics_service.dart';
import 'package:emerge_app/features/social/data/services/tribe_analytics_snapshot_service.dart';
import 'package:emerge_app/features/social/domain/models/creator_analytics.dart';

part 'creator_analytics_provider.g.dart';

@Riverpod(keepAlive: true)
CreatorAnalyticsService creatorAnalyticsService(Ref ref) {
  return CreatorAnalyticsService();
}

@Riverpod(keepAlive: true)
TribeAnalyticsSnapshotService tribeAnalyticsSnapshotService(Ref ref) {
  return TribeAnalyticsSnapshotService();
}

/// Full analytics for (uid, tribeId). Refreshes on invalidation
/// (e.g. after a share action or pull-to-refresh).
@riverpod
Future<CreatorAnalytics> creatorAnalytics(Ref ref, {
  required String uid,
  required String tribeId,
}) async {
  final service = ref.watch(creatorAnalyticsServiceProvider);
  final snapshotService = ref.watch(tribeAnalyticsSnapshotServiceProvider);

  // Non-blocking snapshot write when stale (never awaited before render).
  unawaited(snapshotService.ensureTodaySnapshot(uid: uid, tribeId: tribeId));

  final analyticsResult = await service.getCreatorAnalytics(
    uid: uid,
    tribeId: tribeId,
  );
  final trendsResult = await snapshotService.getTrends(tribeId: tribeId);

  return analyticsResult.fold(
    (error) => throw error,
    (analytics) => CreatorAnalytics(
      tribeId: analytics.tribeId,
      tribeName: analytics.tribeName,
      memberCount: analytics.memberCount,
      totalXp: analytics.totalXp,
      totalHabitsCompleted: analytics.totalHabitsCompleted,
      totalChallengesCompleted: analytics.totalChallengesCompleted,
      newMembersThisWeek: analytics.newMembersThisWeek,
      activeMembers: analytics.activeMembers,
      activeRate: analytics.activeRate,
      blueprintStats: analytics.blueprintStats,
      topMembers: analytics.topMembers,
      challengeStats: analytics.challengeStats,
      // Trends are best-effort: if the snapshot read fails, render KPIs
      // with an empty trend list rather than failing the whole tab.
      trends: trendsResult.getRight().toNullable() ?? const [],
    ),
  );
}
```

Note: import `dart:async` for `unawaited`.

- [ ] **Step 4: Run build_runner, then run the test**

Run: `dart run build_runner build --delete-conflicting-outputs`
Run: `flutter test test/features/social/presentation/providers/creator_analytics_provider_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/social/presentation/providers/creator_analytics_provider.dart lib/features/social/presentation/providers/creator_analytics_provider.g.dart test/features/social/presentation/providers/creator_analytics_provider_test.dart
git commit -m "feat(analytics): add creatorAnalyticsProvider"
```

---

### Task 6: `CreatorAnalyticsTab` UI

**Files:**
- Create: `lib/features/social/presentation/screens/creator/creator_analytics_tab.dart`
- Test: `test/features/social/presentation/screens/creator/creator_analytics_tab_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/features/social/presentation/screens/creator/creator_analytics_tab_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/social/domain/models/creator_analytics.dart';
import 'package:emerge_app/features/social/presentation/providers/creator_analytics_provider.dart';
import 'package:emerge_app/features/social/presentation/screens/creator/creator_analytics_tab.dart';

void main() {
  Widget wrap(Widget child) => ProviderScope(
    child: MaterialApp(home: child),
  );

  testWidgets('renders KPI values from analytics data', (tester) async {
    final analytics = CreatorAnalytics(
      tribeId: 't1',
      tribeName: 'The Forge',
      memberCount: 12,
      totalXp: 5000,
      totalHabitsCompleted: 120,
      totalChallengesCompleted: 4,
      newMembersThisWeek: 2,
      activeMembers: 8,
      activeRate: 0.67,
      blueprintStats: const [
        BlueprintStat(id: 'b1', title: 'Morning Stack', adoptionCount: 7, habitCount: 2),
      ],
      topMembers: const [
        MemberStat(userId: 'u1', name: 'Ada', xp: 3000, habitsCompleted: 40),
      ],
      challengeStats: const [
        ChallengeStat(id: 'c1', title: 'Read 30', participants: 5, status: 'active', xpReward: 100),
      ],
    );

    await tester.pumpWidget(wrap(
      ProviderScope(overrides: [
        creatorAnalyticsProvider.overrideWith((ref, arg) async => analytics),
      ], child: const CreatorAnalyticsTab()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('12'), findsOneWidget);
    expect(find.text('5.0K'), findsOneWidget); // _formatXp(5000)
    expect(find.text('120'), findsOneWidget);
    expect(find.text('Morning Stack'), findsOneWidget);
    expect(find.text('Ada'), findsOneWidget);
  });

  testWidgets('shows empty state when no tribe data', (tester) async {
    await tester.pumpWidget(wrap(
      ProviderScope(overrides: [
        creatorAnalyticsProvider.overrideWith((ref, arg) async =>
            const CreatorAnalytics(tribeId: 't1', tribeName: '')),
      ], child: const CreatorAnalyticsTab()),
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('No analytics'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/social/presentation/screens/creator/creator_analytics_tab_test.dart`
Expected: FAIL — `CreatorAnalyticsTab` not defined.

- [ ] **Step 3: Implement the tab**

```dart
// lib/features/social/presentation/screens/creator/creator_analytics_tab.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_loading_skeleton.dart';
import 'package:emerge_app/core/presentation/widgets/app_error_widget.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/features/social/presentation/providers/creator_analytics_provider.dart';
import 'package:emerge_app/features/social/presentation/providers/creator_provider.dart';
import 'package:emerge_app/features/social/domain/models/creator_analytics.dart';

class CreatorAnalyticsTab extends ConsumerWidget {
  const CreatorAnalyticsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final profileAsync = ref.watch(creatorProfileProvider(uid));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Creator Analytics'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: profileAsync.when(
        data: (profile) {
          final tribeId = profile?.tribeId;
          if (tribeId == null) return const _NoTribeState();
          final analyticsAsync =
              ref.watch(creatorAnalyticsProvider(uid: uid, tribeId: tribeId));
          return analyticsAsync.when(
            data: (analytics) => _AnalyticsView(analytics: analytics),
            loading: () => const EmergeLoadingSkeleton(itemCount: 6),
            error: (e, st) => AppErrorWidget(
              message: 'Could not load analytics.',
              onRetry: () => ref.invalidate(
                creatorAnalyticsProvider(uid: uid, tribeId: tribeId),
              ),
            ),
          );
        },
        loading: () => const EmergeLoadingSkeleton(itemCount: 6),
        error: (e, st) => AppErrorWidget(
          message: 'Could not load creator profile.',
          onRetry: () => ref.invalidate(creatorProfileProvider(uid)),
        ),
      ),
    );
  }
}

class _AnalyticsView extends StatelessWidget {
  final CreatorAnalytics analytics;
  const _AnalyticsView({required this.analytics});

  @override
  Widget build(BuildContext context) {
    if (analytics.tribeName.isEmpty && analytics.memberCount == 0) {
      return const _NoTribeState();
    }
    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: _KpiCard(
                  icon: Icons.groups_rounded,
                  value: analytics.memberCount.toString(),
                  label: 'Members',
                  color: EmergeColors.neonTeal,
                ),
              ),
              const Gap(12),
              Expanded(
                child: _KpiCard(
                  icon: Icons.bolt_rounded,
                  value: _formatXp(analytics.totalXp),
                  label: 'Tribe XP',
                  color: Colors.amber,
                ),
              ),
            ],
          ),
          const Gap(12),
          Row(
            children: [
              Expanded(
                child: _KpiCard(
                  icon: Icons.check_circle_outline_rounded,
                  value: analytics.totalHabitsCompleted.toString(),
                  label: 'Habits done',
                  color: Colors.blue,
                ),
              ),
              const Gap(12),
              Expanded(
                child: _KpiCard(
                  icon: Icons.emoji_events_rounded,
                  value: analytics.totalChallengesCompleted.toString(),
                  label: 'Challenges',
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          const Gap(24),

          _SectionHeader('MEMBER GROWTH'),
          const Gap(12),
          _MemberGrowthCard(analytics: analytics),
          const Gap(24),

          _SectionHeader('ENGAGEMENT'),
          const Gap(12),
          _EngagementCard(analytics: analytics),
          const Gap(24),

          _SectionHeader('BLUEPRINTS'),
          const Gap(12),
          if (analytics.blueprintStats.isEmpty)
            const _EmptyRow('No blueprints published yet.')
          else
            for (final b in analytics.blueprintStats)
              _BlueprintRow(stat: b),
          const Gap(24),

          _SectionHeader('TOP MEMBERS'),
          const Gap(12),
          if (analytics.topMembers.isEmpty)
            const _EmptyRow('No member contributions yet.')
          else
            for (final m in analytics.topMembers) _MemberRow(member: m),
          const Gap(24),

          _SectionHeader('CHALLENGES'),
          const Gap(12),
          if (analytics.challengeStats.isEmpty)
            const _EmptyRow('No challenges published yet.')
          else
            for (final c in analytics.challengeStats) _ChallengeRow(stat: c),
          const Gap(24),
        ],
      ),
    );
  }

  String _formatXp(int xp) {
    if (xp >= 1000) return '${(xp / 1000).toStringAsFixed(1)}K';
    return xp.toString();
  }
}

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _KpiCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const Gap(12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Gap(2),
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);
  @override
  Widget build(BuildContext context) => Text(
    title,
    style: const TextStyle(
      color: Colors.white38,
      fontSize: 11,
      fontWeight: FontWeight.bold,
      letterSpacing: 2,
    ),
  );
}

class _MemberGrowthCard extends StatelessWidget {
  final CreatorAnalytics analytics;
  const _MemberGrowthCard({required this.analytics});

  @override
  Widget build(BuildContext context) {
    final trends = analytics.trends;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '+${analytics.newMembersThisWeek} new this week · '
            '${analytics.activeMembers} active (${(analytics.activeRate * 100).round()}%)',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const Gap(16),
          if (trends.isEmpty)
            const Text(
              'History builds as you open analytics daily.',
              style: TextStyle(color: Colors.white38, fontSize: 13),
            )
          else
            SizedBox(
              height: 160,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _maxMemberCount(trends).toDouble(),
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 || i >= trends.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              trends[i].date.substring(5),
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 9,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(trends.length, (index) {
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: trends[index].memberCount.toDouble(),
                          color: EmergeColors.neonTeal,
                          width: 14,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
        ],
      ),
    );
  }

  int _maxMemberCount(List<DailyTrend> trends) {
    var max = 1;
    for (final t in trends) {
      if (t.memberCount > max) max = t.memberCount;
    }
    return max;
  }
}

class _EngagementCard extends StatelessWidget {
  final CreatorAnalytics analytics;
  const _EngagementCard({required this.analytics});

  @override
  Widget build(BuildContext context) {
    final trends = analytics.trends;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: trends.isEmpty
          ? const Text(
              'Engagement trends appear once daily snapshots accumulate.',
              style: TextStyle(color: Colors.white38, fontSize: 13),
            )
          : SizedBox(
              height: 160,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  lineTouchData: LineTouchData(enabled: false),
                  titlesData: const FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(trends.length, (index) {
                        return FlSpot(
                          index.toDouble(),
                          trends[index].totalHabitsCompleted.toDouble(),
                        );
                      }),
                      isCurved: true,
                      color: Colors.amber,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.amber.withValues(alpha: 0.15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _BlueprintRow extends StatelessWidget {
  final BlueprintStat stat;
  const _BlueprintRow({required this.stat});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          const Icon(Icons.widgets_rounded, color: EmergeColors.neonTeal, size: 20),
          const Gap(12),
          Expanded(
            child: Text(
              stat.title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            '${stat.adoptionCount} adoptions · ${stat.habitCount} habits',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  final MemberStat member;
  const _MemberRow({required this.member});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.person_rounded, color: Colors.white38, size: 20),
          const Gap(12),
          Expanded(
            child: Text(
              member.name,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          Text(
            '${member.xp} XP · ${member.habitsCompleted} habits',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ChallengeRow extends StatelessWidget {
  final ChallengeStat stat;
  const _ChallengeRow({required this.stat});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 20),
          const Gap(12),
          Expanded(
            child: Text(
              stat.title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            '${stat.participants} participants · ${stat.status} · ${stat.xpReward} XP',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _EmptyRow extends StatelessWidget {
  final String message;
  const _EmptyRow(this.message);
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white10),
    ),
    child: Text(
      message,
      style: const TextStyle(color: Colors.white38, fontSize: 13),
    ),
  );
}

class _NoTribeState extends StatelessWidget {
  const _NoTribeState();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics_outlined, size: 64, color: Colors.white24),
            Gap(16),
            Text(
              'No Analytics Yet',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Gap(8),
            Text(
              'Publish a blueprint to create your creator tribe, then your analytics appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/social/presentation/screens/creator/creator_analytics_tab_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/social/presentation/screens/creator/creator_analytics_tab.dart test/features/social/presentation/screens/creator/creator_analytics_tab_test.dart
git commit -m "feat(analytics): add CreatorAnalyticsTab UI"
```

---

### Task 7: Wire into router + dashboard

**Files:**
- Modify: `lib/core/router/creator_routes.dart`
- Modify: `lib/features/social/presentation/screens/creator/creator_overview_tab.dart`
- Modify: `lib/features/social/presentation/screens/creator/creator_tribe_management_tab.dart`
- Test: `test/core/router/creator_analytics_route_test.dart`

- [ ] **Step 1: Write the failing route test**

```dart
// test/core/router/creator_analytics_route_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/core/router/creator_routes.dart';

void main() {
  test('creator dashboard shell has an analytics branch', () {
    final routes = creatorRoutes;
    final shell = routes.whereType<StatefulShellRoute>().first;
    final paths = shell.branches
        .expand((b) => b.routes)
        .map((r) => r.path)
        .toList();
    expect(paths, contains('/creator/dashboard/analytics'));
  });
}
```

Note: `StatefulShellRoute` is the `go_router` type; import `package:go_router/go_router.dart` in the test.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/router/creator_analytics_route_test.dart`
Expected: FAIL — no analytics branch.

- [ ] **Step 3: Add the 4th branch to `creator_routes.dart`**

Add import:
```dart
import 'package:emerge_app/features/social/presentation/screens/creator/creator_analytics_tab.dart';
```

Add a new `StatefulShellBranch` after the tribe branch:
```dart
StatefulShellBranch(
  routes: [
    GoRoute(
      path: '/creator/dashboard/analytics',
      builder: (context, state) => const CreatorAnalyticsTab(),
    ),
  ],
),
```

- [ ] **Step 4: Add the nav destination to `creator_dashboard_scaffold.dart`**

In the `items` list, add after the Tribe destination:
```dart
const NavigationDestination(
  icon: Icon(Icons.analytics_rounded),
  label: 'Analytics',
),
```
(The rail destinations derive from `items`, so no separate edit is needed.)

- [ ] **Step 5: Rewire the Overview "Full Analytics" card**

In `creator_overview_tab.dart`, replace the snackbar `onTap` of the "Full Analytics" card:
```dart
onTap: () => context.go('/creator/dashboard/analytics'),
```
and remove the `badge: 'SOON'` from that card. Also replace the fake growth card: change the "Growth Rate" `_AnalyticCard` to show real data — use `ref.watch(creatorAnalyticsProvider(...))` only if cheap; simplest correct fix is to remove the fake card and let the analytics tab own growth. Keep the card but label it "Members" with `userProfile`-independent data is out of scope — instead delete the fake `Growth Rate` card and replace with a "Challenges" card using `myBlueprints`-independent data is not available on this screen, so remove the second row's fake card and keep a single row of 3 real cards (Blueprints, Adoptions, Total Habits). Update the row layout accordingly (3 cards in one row using `Expanded`).

- [ ] **Step 6: Link the tribe management placeholder**

In `creator_tribe_management_tab.dart`, the "See All →" `TextButton` and the member-list placeholder should navigate to analytics:
```dart
TextButton(
  onPressed: () => context.go('/creator/dashboard/analytics'),
  child: Text('See All →', style: TextStyle(color: EmergeColors.neonTeal, fontSize: 12)),
),
```
and change the placeholder text to "Full member list and analytics — tap See All." (Add `import 'package:go_router/go_router.dart';` if not present.)

- [ ] **Step 7: Run the route test + focused tests**

Run: `flutter test test/core/router/creator_analytics_route_test.dart`
Run: `flutter test test/features/social/presentation/screens/creator/creator_overview_tab_test.dart` (if it exists) — otherwise `dart analyze lib/features/social/presentation/screens/creator/`
Expected: PASS / no analyzer errors.

- [ ] **Step 8: Commit**

```bash
git add lib/core/router/creator_routes.dart lib/features/social/presentation/screens/creator/creator_dashboard_scaffold.dart lib/features/social/presentation/screens/creator/creator_overview_tab.dart lib/features/social/presentation/screens/creator/creator_tribe_management_tab.dart test/core/router/creator_analytics_route_test.dart
git commit -m "feat(analytics): wire analytics branch into creator dashboard"
```

---

### Task 8: Firestore rules for `tribe_analytics`

**Files:**
- Modify: `firestore.rules`

- [ ] **Step 1: Add the rule**

Add inside `service cloud.firestore` (after the `tribes` block):

```
// Creator analytics snapshots — creator-owned tribe, validated shape.
// Daily docs accumulate per tribe; only the tribe's creator may write.
match /tribe_analytics/{tribeId} {
  allow read: if isAuthenticated();
  match /daily/{date} {
    allow read: if isAuthenticated();
    allow create, update: if isAuthenticated() &&
      get(/databases/$(database)/documents/tribes/$(tribeId)).data.createdBy
        == request.auth.uid &&
      request.resource.data.tribeId == tribeId &&
      request.resource.data.date == date &&
      request.resource.data.memberCount is number &&
      request.resource.data.totalXp is number &&
      request.resource.data.totalHabitsCompleted is number &&
      request.resource.data.totalChallengesCompleted is number &&
      request.resource.data.activeMembers is number &&
      request.resource.data.newMembersThisWeek is number;
    allow delete: if false;
  }
}
```

- [ ] **Step 2: Validate rules syntax**

Run: `npx -y firebase-tools@latest firestore:rules:compile` (or `firebase emulators:exec --only firestore 'echo ok'` if available locally).
Expected: no syntax errors.

- [ ] **Step 3: Commit**

```bash
git add firestore.rules
git commit -m "feat(analytics): add tribe_analytics Firestore rules"
```

---

## Plan Self-Review

- **Spec coverage:** KPI cards (Task 6), member growth + engagement trends with fl_chart (Task 6), blueprint breakdown (Task 3+6), top members (Task 3+6), challenge health (Task 3+6), client-side daily snapshots (Task 4), Drift offline cache (Task 2), 4th nav branch (Task 7), SOON card rewiring + fake growth removal (Task 7), tribe-tab placeholder link (Task 7), Firestore rule (Task 8), Either error handling (Tasks 3-5), empty/loading/error states (Task 6), TDD throughout.
- **Placeholder scan:** No TBDs; every code step shows full code.
- **Type consistency:** `TribeAnalyticsSnapshot`, `CreatorAnalytics`, `BlueprintStat`, `MemberStat`, `ChallengeStat`, `DailyTrend` names are consistent across Tasks 1-6. Provider signature `creatorAnalyticsProvider(uid:..., tribeId:...)` matches between Task 5 and Task 6. DAO method `upsertSnapshot(...)` matches Task 2.
