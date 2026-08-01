# SP-G: Tribe Membership & XP Accounting Fixes — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix the tribe membership/XP accounting defects found in the SP-G audit: single-join guarantees (B1/B2), merge-preserving rejoins (B11), symmetric XP credit/debit across `user_stats`/`contributors` (B5/B6/B12), challenge XP reaching Firestore user stats and leaderboards (B5/B9), one leaderboard entry per user per active tribe (B7/B8/B14), server-authoritative tribe totals (B3/D4), recalc covering all tribes with per-member XP (B4/D10), stale-roster UI filtering (B10/D8), and rules validation of memberCount/members writes (B13/D9).

**Architecture:** Two guards make joins idempotent (Drift active-membership OR Firestore `users/{uid}/tribes` doc exists). A pure `CompletionXpSplit` + shared `user_stats` payload builder guarantees credit/debit symmetry by construction. The client stops writing `tribes.totalXp/*` (recalc-only); `TribeStatsService.syncTribeStats` is deleted. `SocialActivityService` log methods take an explicit `clubId` (= active tribe) and `logLevelUp` loses its absolute leaderboard write; the `firestore_drift_syncer` queries `club_leaderboards` by `clubId`. `firestore.rules` gains diff/value validation for `memberCount`/`members` and blocks client `official`/`brand` tribe creation. `functions/src/recalcTribes.ts` is rebuilt around a pure `aggregateTribeStats` (members = explicit membership docs + official-club archetype fallback; XP summed per member) and writes every tribe with members.

**Tech Stack:** Flutter 3.x, Dart 3.10+, Riverpod 3.x, drift, fpdart, mocktail, fake_cloud_firestore ^4.1.1; Cloud Functions (Node 22, jest + ts-jest + firebase-functions-test).

**Spec:** `docs/superpowers/specs/2026-08-01-sp-g-tribe-membership-xp-design.md`

---

## ⚠️ Pre-flight (read first)

1. **The working tree is dirty** (pre-existing uncommitted changes across ~30 files from earlier sessions, incl. `firestore.rules`, `drift_habit_repository.dart`, `tribe_lobby_screen.dart`). **Commit only the files each task names** — never `git add -A` or `git add lib` wholesale.
2. **Run `dart analyze lib` before starting** to establish the baseline error count. Only SP-G-introduced errors are this plan's responsibility.
3. One **pre-existing failing test is owned by SP-G**: `test/features/social/domain/services/tribe_membership_service_test.dart` ("joinTribe enqueues Firestore sync operations") — fixed in T3. Do not treat it as a regression.
4. All line references below were verified on 2026-08-01 working tree; if a referenced line has moved (parallel WIP), locate the cited symbol/behavior rather than the line number.
5. The sync engine applies **merge-sets** for both `set` and `update` operations (`lib/core/sync/sync_engine.dart:188-218`) — a payload that explicitly includes a key **overwrites** it; omitted keys are preserved. This is load-bearing for T2/T3 (D3).
6. No Drift schema changes, no new Firestore collections, no migrations in this plan.

## File structure

### New files

| Path | Responsibility |
|---|---|
| `lib/features/gamification/domain/services/completion_xp_split.dart` | Pure credit/debit deltas + shared `user_stats` enqueue payload builder |
| `test/features/gamification/domain/completion_xp_split_test.dart` | Pure math tests (B5/B6/B12 regression) |
| `functions/test/recalcTribes.test.ts` | Jest tests for the pure `aggregateTribeStats` (T12) |

### Modified files

| Path | Change |
|---|---|
| `lib/core/drift_repositories/drift_tribe_repository.dart` | T2 `joinClub` guard; T3 contributor payload without zero keys; T6 `_mergeTribeData` remote-preferred |
| `lib/features/social/domain/services/tribe_membership_service.dart` | T3 Firestore guard + merge-preserving contributor write |
| `test/features/social/domain/services/tribe_membership_service_test.dart` | T3 new/updated tests incl. fixing the pre-existing failure |
| `lib/core/drift_repositories/drift_habit_repository.dart` | T4 credit shape (challenge XP, drop tribes enqueue); T5 undo symmetry; T8 pass active tribe as clubId |
| `test/core/drift_repositories/drift_habit_repository_test.dart` | T4/T5/T8 assertions |
| `lib/core/drift_repositories/drift_challenge_repository.dart` | T6 reward enqueue + `logChallengeComplete` wiring |
| `lib/features/social/presentation/providers/challenge_provider.dart` | T6 construct repo with `socialActivityServiceProvider` |
| `test/core/drift_repositories/drift_challenge_repository_test.dart` | T6 tests |
| `lib/features/social/domain/services/club_activity_service.dart` | T7 `clubId` param; remove `logLevelUp` leaderboard write |
| `test/features/social/domain/services/club_activity_service_test.dart` (+ `_extended`, `_partner_fanout`) | T7 tests |
| `lib/features/social/domain/services/firestore_drift_syncer.dart` | T9 query/upsert by `clubId` |
| `test/features/social/domain/services/firestore_drift_syncer_test.dart` | T9 tests |
| `lib/features/social/presentation/screens/leaderboard_screen.dart` | T8 membership-based clubId; T10 filter |
| `test/features/social/presentation/screens/leaderboard_screen_test.dart` | T8/T10 tests |
| `lib/features/social/presentation/widgets/tribe_card.dart` | T11 dialog copy; drop `syncTribeStats` calls |
| `lib/features/social/data/services/tribe_stats_service.dart` | T11 remove `syncTribeStats` |
| `test/features/social/data/services/tribe_stats_service_test.dart` | T11 drop syncTribeStats tests |
| `test/features/social/presentation/widgets/tribe_card_test.dart`, `test/features/social/presentation/screens/all_tribes_screen_test.dart` | T11 updates |
| `lib/features/social/presentation/providers/cached_tribe_stats_provider.dart` | T11 remote-preferred merge |
| `lib/features/social/presentation/widgets/tribe_header_widgets.dart` | T10 `ContributorsSection` members filter |
| `lib/features/social/presentation/screens/tribe_members_tab.dart` | T10 pass members to sections |
| `test/features/social/presentation/widgets/tribe_header_widgets_test.dart` (new), `test/features/social/presentation/widgets/tribe_leaderboard_widget_test.dart` | T10 tests |
| `firestore.rules` | T11 rules validation (⚠️ file is already modified in the working tree — edit incrementally) |
| `functions/src/recalcTribes.ts` | T12 pure function; T13 recalc rewrite |

---

# Phase 1 — Pure foundation (TDD)

## Task 1: `CompletionXpSplit` pure domain + tests

**Files:**
- Create: `lib/features/gamification/domain/services/completion_xp_split.dart`
- Test: `test/features/gamification/domain/completion_xp_split_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:emerge_app/features/gamification/domain/services/completion_xp_split.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CompletionXpSplit', () {
    test('user stats receive base + challenge XP', () {
      const split = CompletionXpSplit(xpGained: 10, challengeXp: 5);
      expect(split.userStatsDelta, 15);
    });

    test('tribe totals and contributors receive base XP only', () {
      const split = CompletionXpSplit(xpGained: 10, challengeXp: 5);
      expect(split.tribeDelta, 10);
    });

    test('undo debits are exact mirrors of credit deltas', () {
      const credit = CompletionXpSplit(xpGained: 10, challengeXp: 5);
      const undo = CompletionXpSplit.fromStoredRow(xpGained: 10, challengeXp: 5);
      expect(undo.userStatsDelta, -credit.userStatsDelta);
      expect(undo.tribeDelta, -credit.tribeDelta);
    });

    test('zero-challenge split behaves like legacy', () {
      const split = CompletionXpSplit(xpGained: 7, challengeXp: 0);
      expect(split.userStatsDelta, 7);
      expect(split.tribeDelta, 7);
    });
  });

  group('buildUserStatsXpPayload', () {
    test('emits the single write shape used by credit and undo', () {
      final payload = buildUserStatsXpPayload(
        totalDelta: 15,
        attr: 'vitality',
        level: 3,
        streak: 4,
        updatedAt: '2026-08-01T12:00:00.000',
      );
      expect(payload['avatarStats.totalXp'],
          {'__type__': 'increment', 'value': 15});
      expect(payload['avatarStats.vitalityXp'],
          {'__type__': 'increment', 'value': 15});
      expect(payload['avatarStats.level'], 3);
      expect(payload['avatarStats.streak'], 4);
      expect(payload['updatedAt'], '2026-08-01T12:00:00.000');
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/gamification/domain/completion_xp_split_test.dart`
Expected: FAIL with "Target of URI doesn't exist: '...completion_xp_split.dart'"

- [ ] **Step 3: Implement**

```dart
/// Pure per-channel XP split for a habit/challenge completion.
///
/// Credit and undo MUST debit exactly what was credited, per channel
/// (SP-G D5/D6). `user_stats` receives base + challenge XP; tribe totals
/// and contributor records only ever receive base XP (challenge XP reaches
/// tribe totals via the server recalc, which sums user_stats.totalXp).
class CompletionXpSplit {
  final int xpGained;
  final int challengeXp;

  const CompletionXpSplit({required this.xpGained, required this.challengeXp});

  /// Mirror constructor for the undo side (values come from a stored
  /// completion row's `xpGained`/`challengeXp` fields).
  factory CompletionXpSplit.fromStoredRow({
    required int xpGained,
    required int challengeXp,
  }) =>
      CompletionXpSplit(xpGained: xpGained, challengeXp: challengeXp);

  /// What user_stats is credited (and debited on undo).
  int get userStatsDelta => xpGained + challengeXp;

  /// What tribe totals/contributors are credited (and debited on undo).
  int get tribeDelta => xpGained;
}

/// The single `user_stats` enqueue shape used by the credit path
/// (completeHabit, challenge completion) AND the undo path, so credit and
/// debit can never drift apart. Mirrors the local Drift
/// updateAttributeXp semantics (totalXp + attribute bucket move together).
Map<String, dynamic> buildUserStatsXpPayload({
  required int totalDelta,
  required String attr,
  required int level,
  required int streak,
  required String updatedAt,
}) =>
    {
      'avatarStats.totalXp': {'__type__': 'increment', 'value': totalDelta},
      'avatarStats.level': level,
      'avatarStats.streak': streak,
      'avatarStats.${attr}Xp': {
        '__type__': 'increment',
        'value': totalDelta,
      },
      'updatedAt': updatedAt,
    };
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/gamification/domain/completion_xp_split_test.dart`
Expected: PASS — 6 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/features/gamification/domain/services/completion_xp_split.dart test/features/gamification/domain/completion_xp_split_test.dart
git commit -m "feat(gamification): CompletionXpSplit pure domain + user_stats payload builder (SP-G T1)"
```

---

# Phase 2 — Join/leave accounting (D1, D3)

## Task 2: `joinClub` idempotence guard (B1, B2)

**Files:**
- Modify: `lib/core/drift_repositories/drift_tribe_repository.dart` (`joinClub` `:392-445`)
- Test: `test/core/drift_repositories/drift_tribe_repository_test.dart`

- [ ] **Step 1: Write the failing test** (append to the existing test group; the file already constructs `DriftTribeRepository(db, syncEngine, fakeFirestore)` with in-memory Drift)

```dart
group('joinClub guard', () {
  test('early-returns when a Firestore membership doc already exists', () async {
    await fakeFirestore
        .collection('users').doc('user1').collection('tribes').doc('tribeA')
        .set({'tribeId': 'tribeA', 'joinedAt': Timestamp.now()});

    await repository.joinClub('user1', 'tribeA');

    final stats = await db.tribeStatsDao.getStats('tribeA');
    expect(stats?.memberCount, 0); // no local increment
    final queue = await db.mutationQueueDao.getAllPending();
    expect(queue, isEmpty);        // nothing enqueued
  });

  test('early-returns when a Drift membership is active', () async {
    await db.tribeMembershipDao.upsertMembership(UserTribeTableCompanion(
      userId: const Value('user1'),
      tribeId: const Value('tribeA'),
      membershipType: const Value('archetype'),
      joinedAt: Value(DateTime.now().toIso8601String()),
      isActive: const Value(true),
    ));

    await repository.joinClub('user1', 'tribeA');

    final queue = await db.mutationQueueDao.getAllPending();
    expect(queue, isEmpty);
  });

  test('still joins when no membership exists anywhere', () async {
    await repository.joinClub('user1', 'tribeA');
    final queue = await db.mutationQueueDao.getAllPending();
    expect(queue.length, 3); // user tribes + contributors + tribe doc
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/drift_repositories/drift_tribe_repository_test.dart`
Expected: FAIL — the guard tests fail because `joinClub` currently always increments/enqueues.

- [ ] **Step 3: Implement** — at the top of `joinClub` (before the Drift write at `:395`):

```dart
// SP-G D1: idempotence. Never join twice — the onboarding flow calls
// joinTribe (Firestore transaction) and this method back-to-back, and a
// reinstall can leave Firestore membership without local Drift state.
final localMembership =
    await _db.tribeMembershipDao.watchActiveMembership(userId).first;
if (localMembership != null && localMembership.isActive) return;

final existing = await _firestore
    .collection('users').doc(userId).collection('tribes').doc(tribeId)
    .get();
if (existing.exists) return;
```

Offline note: if the Firestore read throws (no connectivity), let the error propagate up the existing `try/catch`? No — `joinClub` has no try/catch; it is awaited by onboarding. Wrap ONLY the Firestore read: on error, degrade to the Drift-only check (documented in the spec, §8). Implementation:

```dart
var remoteExists = false;
try {
  remoteExists = await _firestore
      .collection('users').doc(userId).collection('tribes').doc(tribeId)
      .get()
      .then((s) => s.exists);
} catch (_) {
  remoteExists = false; // offline: Drift check only (best-effort guard)
}
if (localMembership != null || remoteExists) return;
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/drift_repositories/drift_tribe_repository_test.dart`
Expected: PASS — including the pre-existing `joinClub` tests (memberCount increment, enqueued paths).

- [ ] **Step 5: Commit**

```bash
git add lib/core/drift_repositories/drift_tribe_repository.dart test/core/drift_repositories/drift_tribe_repository_test.dart
git commit -m "fix(tribes): joinClub idempotence guard — no double join from onboarding/reinstall (SP-G T2, B1/B2)"
```

## Task 3: `joinTribe` Firestore guard + merge-preserving contributor write (B2, B11)

**Files:**
- Modify: `lib/features/social/domain/services/tribe_membership_service.dart` (`joinTribe` `:29-99`)
- Modify (tests): `test/features/social/domain/services/tribe_membership_service_test.dart`

- [ ] **Step 1: Write the failing tests** (replace the outdated "joinTribe enqueues Firestore sync operations" test with Firestore-state assertions; add the new guard/merge tests)

```dart
test('joinTribe rejects when a Firestore membership doc already exists', () async {
  await firestore
      .collection('users').doc('user1').collection('tribes').doc('morning_warriors')
      .set({'tribeId': 'morning_warriors', 'joinedAt': Timestamp.now()});

  final result = await service.joinTribe(
      userId: 'user1', tribeId: 'morning_warriors', type: 'archetype');

  expect(result.isLeft(), true);
  final tribe = await firestore.collection('tribes').doc('morning_warriors').get();
  expect((tribe.data()?['memberCount'] as int?) ?? 0, 0); // no +1
});

test('joinTribe preserves existing contributor totals on rejoin', () async {
  await firestore.collection('tribes').doc('morning_warriors').set({
    'memberCount': 0,
    'members': <String>[],
  });
  await firestore
      .collection('tribes').doc('morning_warriors').collection('contributors')
      .doc('user1')
      .set({'userId': 'user1', 'totalXpContributed': 250, 'contributionCount': 3});

  await service.joinTribe(userId: 'user1', tribeId: 'morning_warriors', type: 'archetype');

  final contributor = await firestore
      .collection('tribes').doc('morning_warriors').collection('contributors')
      .doc('user1').get();
  expect((contributor.data()?['totalXpContributed'] as int?) ?? 0, 250); // NOT reset to 0
});

test('joinTribe creates a zeroed contributor doc for a first join', () async {
  await service.joinTribe(userId: 'user1', tribeId: 'morning_warriors', type: 'archetype');
  final contributor = await firestore
      .collection('tribes').doc('morning_warriors').collection('contributors')
      .doc('user1').get();
  expect((contributor.data()?['totalXpContributed'] as int?) ?? 0, 0);
});

test('joinTribe writes membership atomically via transaction', () async {
  await service.joinTribe(userId: 'user1', tribeId: 'morning_warriors', type: 'archetype');
  final tribe = await firestore.collection('tribes').doc('morning_warriors').get();
  expect(tribe.data()?['memberCount'], 1);
  expect(tribe.data()?['members'], <String>['user1']);
  final membership = await firestore
      .collection('users').doc('user1').collection('tribes').doc('morning_warriors').get();
  expect(membership.exists, true);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/social/domain/services/tribe_membership_service_test.dart`
Expected: FAIL — guard test (Firestore doc exists yet join succeeds) and rejoin test (totals reset to 0). The old queue-assertion test is removed here (that behavior was replaced by the transaction in a prior sub-project; asserting Firestore state is the correct contract).

- [ ] **Step 3: Implement** — in `joinTribe`, before the transaction:

```dart
// SP-G D1/B2: the Drift-only guard below misses users whose Firestore
// membership survived a reinstall. Check Firestore first.
final existingDocs = await _firestore
    .collection('users').doc(userId).collection('tribes')
    .limit(1)
    .get();
if (existingDocs.docs.isNotEmpty) {
  return Left(UnknownFailure(
      'Already in tribe ${existingDocs.docs.first.id}'));
}
```

Then replace the contributor `transaction.set` (`:67-76`) with a read-and-branch (inside the same transaction):

```dart
// SP-G D3/B11: rejoining must never wipe previously contributed totals.
final contributorRef = _firestore
    .collection('tribes').doc(tribeId).collection('contributors').doc(userId);
final contributorSnap = await transaction.get(contributorRef);
if (contributorSnap.exists) {
  transaction.set(contributorRef, {
    'userId': userId,
    'joinedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
} else {
  transaction.set(contributorRef, {
    'userId': userId,
    'joinedAt': FieldValue.serverTimestamp(),
    'contributionCount': 0,
    'totalHabitsCompleted': 0,
    'totalXpContributed': 0,
  });
}
```

Also apply the D3 payload fix in `joinClub` (`drift_tribe_repository.dart:417-427`): remove `'contributionCount': 0, 'totalHabitsCompleted': 0, 'totalXpContributed': 0` from the enqueued contributor payload (merge-set would overwrite existing totals; omission preserves them — spec §3 D3). Add the matching test in `drift_tribe_repository_test.dart`:

```dart
test('joinClub contributor payload omits zero totals (preserves on rejoin)', () async {
  await repository.joinClub('user1', 'tribeA');
  final queue = await db.mutationQueueDao.getAllPending();
  final contributorOp = queue.singleWhere(
      (m) => m.collectionPath == 'tribes/tribeA/contributors');
  final data = Map<String, dynamic>.from(
      (contributorOp.dataJson != null ? jsonDecode(contributorOp.dataJson!) : {}) as Map);
  expect(data.containsKey('totalXpContributed'), false);
  expect(data.containsKey('contributionCount'), false);
});
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/social/domain/services/tribe_membership_service_test.dart && flutter test test/core/drift_repositories/drift_tribe_repository_test.dart`
Expected: PASS — including the previously failing joinTribe tests (SP-A handoff item now closed).

- [ ] **Step 5: Commit**

```bash
git add lib/features/social/domain/services/tribe_membership_service.dart lib/core/drift_repositories/drift_tribe_repository.dart test/features/social/domain/services/tribe_membership_service_test.dart test/core/drift_repositories/drift_tribe_repository_test.dart
git commit -m "fix(tribes): joinTribe Firestore guard + merge-preserving contributor writes (SP-G T3, B2/B11)"
```

---

# Phase 3 — XP accounting symmetry (D4, D5, D6)

## Task 4: Completion credit — challenge XP in user_stats, no client tribe-total writes (B5, B3)

**Files:**
- Modify: `lib/core/drift_repositories/drift_habit_repository.dart` (`completeHabit` credit: `:348-512`, tribe enqueue `:514-524`)
- Test: `test/core/drift_repositories/drift_habit_repository_test.dart`

- [ ] **Step 1: Write the failing tests** (append to `group('DriftHabitRepository')`; `mockSyncEngine` is the existing mocktail mock; seed a user with an active challenge via `db.challengeProgressDao.insertFromData` so `processHabitCompletion` returns `challengeXpEarned > 0`)

```dart
test('completeHabit credits challenge XP to Firestore user_stats', () async {
  // seed habit + stats + an active challenge with xpReward that completes today
  // (see the existing challenge helpers in this file; assert challengeXpEarned > 0)
  await repository.completeHabit(habit.id, DateTime.now(), activeTribeId: 'tribeA');

  verify(() => mockSyncEngine.enqueueUpdate(
    collectionPath: 'user_stats',
    documentId: userId,
    data: argThat(contains('avatarStats.totalXp')),
  )).called(1);
  // capture the payload: totalXp increment value == result.xpGained + challengeXpEarned
});

test('completeHabit no longer enqueues tribe totalXp/totalHabitsCompleted', () async {
  await repository.completeHabit(habit.id, DateTime.now(), activeTribeId: 'tribeA');
  final tribeOps = logCalls.where((c) =>
      c.collectionPath == 'tribes' &&
      (c.data?['totalXp'] != null || c.data?['totalHabitsCompleted'] != null));
  expect(tribeOps, isEmpty);
});
```

The existing tests use `verify(...)` on `mockSyncEngine` — use `verifyNever` for the tribes assertions, or capture with `untilCalled`/`captureAny` per the file's existing convention. For the exact increment value, assert the enqueued map equals `buildUserStatsXpPayload(totalDelta: expected, ...)`.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/drift_repositories/drift_habit_repository_test.dart`
Expected: FAIL — the user_stats increment currently uses `result.xpGained` only, and the `tribes` enqueue still exists.

- [ ] **Step 3: Implement**

In `completeHabit`:
- Replace the `user_stats` enqueue (`:494-512`) with the shared builder (T1):

```dart
await _syncEngine.enqueueUpdate(
  collectionPath: 'user_stats',
  documentId: statsRow.userId,
  data: buildUserStatsXpPayload(
    totalDelta: totalXpGained, // = result.xpGained + challengeXpEarned (already computed at :355)
    attr: attr,
    level: newLevel,
    streak: result.newStreak,
    updatedAt: nowStr,
  ),
);
```

- Delete the `tribes` enqueue block (`:514-524` — the `enqueueUpdate` on `'tribes'` with `totalXp`/`totalHabitsCompleted`). Keep the `contributors` enqueue (`:526-541`) unchanged (it is rules-legal and still client-authoritative). The local Drift `incrementContribution` (`:434-459`) stays — instant local UI only.
- Note: `attr` and `totalXpGained` are already in scope in the transaction (`:346-355`); the enqueue sits after the transaction (line ~462+), so use the pre-computed values captured outside (the current code already references `statsRow`/`newLevel`/`nowStr` there).

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/drift_repositories/drift_habit_repository_test.dart`
Expected: PASS — credit-shape tests + all existing completion tests.

- [ ] **Step 5: Commit**

```bash
git add lib/core/drift_repositories/drift_habit_repository.dart test/core/drift_repositories/drift_habit_repository_test.dart
git commit -m "fix(xp): credit challenge XP to Firestore user_stats; stop client tribe-total writes (SP-G T4, B5/B3)"
```

## Task 5: Undo symmetry — user_stats debit + exact contributor debit (B6, B12)

**Files:**
- Modify: `lib/core/drift_repositories/drift_habit_repository.dart` (undo path `:222-344`)
- Test: `test/core/drift_repositories/drift_habit_repository_test.dart`

- [ ] **Step 1: Write the failing tests** (extend the existing "same day completion returns false (undo)" test at `:268-313`)

```dart
test('undo debits Firestore user_stats by the exact credited amount', () async {
  // complete once with a challenge completing (xp 10 + challenge 5),
  // then call completeHabit again the same day to trigger the undo
  final result2 = await repository.completeHabit(habit.id, today); // undo

  expect(result2.fold((l) => false, (r) => r), false);
  verify(() => mockSyncEngine.enqueueUpdate(
    collectionPath: 'user_stats',
    documentId: userId,
    data: argThat(
      containsPair('avatarStats.totalXp',
          {'__type__': 'increment', 'value': -15}), // -(xpGained + challengeXp)
    ),
  )).called(1);
});

test('undo debits contributors by base XP only (no challenge XP)', () async {
  // same setup; assert the contributors enqueue uses value -10 (last.xpGained)
  verify(() => mockSyncEngine.enqueueUpdate(
    collectionPath: 'tribes/tribeA/contributors',
    documentId: userId,
    data: argThat(containsPair('totalXpContributed',
        {'__type__': 'increment', 'value': -10})),
  )).called(1);
});

test('undo no longer enqueues tribes.totalXp writes', () async {
  // assert no 'tribes' enqueue with totalXp in the undo path
  verifyNever(() => mockSyncEngine.enqueueUpdate(
    collectionPath: 'tribes',
    documentId: any(named: 'documentId'),
    data: any(named: 'data', that: contains('totalXp')),
  ));
});
```

(Use the file's existing `argThat`/`containsPair` import conventions; if `containsPair` is unavailable, match with a predicate over the captured map.)

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/drift_repositories/drift_habit_repository_test.dart`
Expected: FAIL — no user_stats enqueue exists in the undo path, contributor debit is `-xpToUndo` (includes challenge XP), tribe debit exists.

- [ ] **Step 3: Implement**

In the undo branch (`:258-333`), inside the existing `_db.transaction`, after the completion-row deletes:
- Replace the tribe-debit enqueue (`:303-315`) with the `user_stats` debit:

```dart
// SP-G D6/B12: mirror the credit exactly on user_stats.
await _syncEngine.enqueueUpdate(
  collectionPath: 'user_stats',
  documentId: statsRow.userId,
  data: buildUserStatsXpPayload(
    totalDelta: -xpToUndo, // -(last.xpGained + last.challengeXp) — matches credit
    attr: attr,
    level: newLevel,
    streak: newStreak,
    updatedAt: DateTime.now().toIso8601String(),
  ),
);
```

- Change the contributor debit (`:320-322`) from `-xpToUndo` to `-last.xpGained` (contributors only ever received base XP):

```dart
'totalXpContributed': {'__type__': 'increment', 'value': -last.xpGained},
```

- Delete the `tribes` enqueue block (`:303-315`) entirely (D4 — tribe totals are recalc-only).
- Keep the completion-row delete enqueues and the local Drift updates unchanged.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/drift_repositories/drift_habit_repository_test.dart`
Expected: PASS — undo symmetry tests + all existing tests (including the pre-existing undo delete-verification).

- [ ] **Step 5: Commit**

```bash
git add lib/core/drift_repositories/drift_habit_repository.dart test/core/drift_repositories/drift_habit_repository_test.dart
git commit -m "fix(xp): symmetric undo — user_stats debit enqueued, contributor debit matches credit (SP-G T5, B6/B12)"
```

## Task 6: Challenge completion — user_stats reward + leaderboard wiring (B9, B5)

**Files:**
- Modify: `lib/core/drift_repositories/drift_challenge_repository.dart` (`updateProgress` `:68-122`; constructor `:15`)
- Modify: `lib/features/social/presentation/providers/challenge_provider.dart` (`:16-22`)
- Test: `test/core/drift_repositories/drift_challenge_repository_test.dart`

- [ ] **Step 1: Write the failing tests**

```dart
// Use the existing test harness; DriftChallengeRepository now takes
// (db, engine, syncEngine, socialService) — update the construction helper.
test('completing a challenge credits XP to Firestore user_stats', () async {
  await db.userStatsDao.upsertStats(/* user with totalXp 0, vitalityXp 0 */);
  await db.challengeProgressDao.insertFromData(
    challengeId: 'c1', userId: userId, title: 'T', attribute: 'vitality',
    totalDays: 3, xpReward: 50, joinedAt: ..., updatedAt: ...);

  await repository.updateProgress(userId, 'c1', 3); // completes it

  verify(() => mockSyncEngine.enqueueUpdate(
    collectionPath: 'user_stats',
    documentId: userId,
    data: argThat(containsPair('avatarStats.totalXp',
        {'__type__': 'increment', 'value': 50})),
  )).called(1);
});

test('completing a challenge calls logChallengeComplete with the active tribe', () async {
  await db.tribeMembershipDao.upsertMembership(/* user1 -> tribeA active */);
  await repository.updateProgress(userId, 'c1', 3);

  verify(() => mockSocialService.logChallengeComplete(
    userId: userId,
    userName: any(named: 'userName'),
    archetype: any(named: 'archetype'),
    challengeId: 'c1',
    challengeTitle: any(named: 'challengeTitle'),
    xpReward: 50,
    clubId: 'tribeA',
  )).called(1);
});

test('partial progress does not credit XP', () async {
  await repository.updateProgress(userId, 'c1', 2); // not complete
  verifyNever(() => mockSyncEngine.enqueueUpdate(
    collectionPath: 'user_stats',
    documentId: userId,
    data: any(named: 'data'),
  ));
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/drift_repositories/drift_challenge_repository_test.dart`
Expected: FAIL — constructor arity mismatch + no user_stats enqueue + no logChallengeComplete call today.

- [ ] **Step 3: Implement**

- Constructor: add `SocialActivityService socialService` (4th positional). Update `challengeRepositoryProvider` (`challenge_provider.dart:16-22`) to pass `ref.watch(socialActivityServiceProvider)` (import from `tribes_provider.dart` — already imported; no cycle: `socialActivityServiceProvider` depends only on sync engine/dao/leaderboard repo).
- In `updateProgress`, inside the `result.isCompleted && result.xpReward != null` branch (`:92-105`), after the local `updateAttributeXp`:

```dart
final userName = stats.displayName ?? userId;
final nowStr = DateTime.now().toIso8601String();
await _syncEngine.enqueueUpdate(
  collectionPath: 'user_stats',
  documentId: userId,
  data: buildUserStatsXpPayload(
    totalDelta: result.xpReward!,
    attr: 'vitality',
    level: newLevel,
    streak: stats.streak,
    updatedAt: nowStr,
  ),
);

// Active tribe for leaderboard attribution (local read — offline-safe).
String? activeTribeId;
final membership =
    await _db.tribeMembershipDao.watchActiveMembership(userId).first;
activeTribeId = membership?.tribeId;

await socialService.logChallengeComplete(
  userId: userId,
  userName: userName,
  archetype: stats.archetype ?? 'none',
  challengeId: challengeId,
  challengeTitle: challenge.title,
  xpReward: result.xpReward!,
  clubId: activeTribeId, // D7: active tribe; service falls back to archetype when null
);
```

(Note: `challenge` is already resolved at `:75-78`; `stats` at `:93`; `newLevel` at `:96`. `logChallengeComplete`'s new optional `clubId` parameter is added in T7 — implement T7's signature first or do T6 and T7 in the same task if the reviewer prefers; the plan keeps them separate: T6 may compile against the new signature only after T7 lands, so **implement T7 immediately after T6** and run the combined suite.)

- [ ] **Step 4: Run test to verify it passes** (after T7 lands)

Run: `flutter test test/core/drift_repositories/drift_challenge_repository_test.dart test/features/social/domain/services/club_activity_service_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/drift_repositories/drift_challenge_repository.dart lib/features/social/presentation/providers/challenge_provider.dart test/core/drift_repositories/drift_challenge_repository_test.dart
git commit -m "feat(challenges): credit challenge XP to user_stats + logChallengeComplete wiring (SP-G T6, B9)"
```

---

# Phase 4 — Leaderboard attribution (D7, B14)

## Task 7: `clubId` override on SocialActivityService + remove `logLevelUp` leaderboard write (B7, B8)

**Files:**
- Modify: `lib/features/social/domain/services/club_activity_service.dart`
- Test: `test/features/social/domain/services/club_activity_service_test.dart`, `club_activity_service_extended_test.dart`, `club_activity_service_partner_fanout_test.dart`

- [ ] **Step 1: Write the failing tests** (the service tests already construct `SocialActivityService` with a fake `LeaderboardRepository` — extend with recording)

```dart
test('logHabitCompletion uses the provided clubId (active tribe) for the leaderboard', () async {
  await service.logHabitCompletion(
    userId: 'u1', userName: 'A', archetype: 'athlete',
    habitId: 'h1', habitTitle: 'H', streakDay: 1, attribute: 'vitality',
    xpGained: 10, currentLevel: 2, clubId: 'my_tribe',
  );
  expect(leaderboardRepo.lastClubId, 'my_tribe');      // NOT morning_warriors
  expect(leaderboardRepo.lastIsIncrement, true);
});

test('logLevelUp writes no leaderboard entry', () async {
  await service.logLevelUp(
    userId: 'u1', userName: 'A', archetype: 'athlete',
    newLevel: 3, totalXp: 250, clubId: 'my_tribe',
  );
  expect(leaderboardRepo.updateCalls, isEmpty);       // activity feeds still written
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/social/domain/services/club_activity_service_test.dart`
Expected: FAIL — no `clubId` parameter exists; `logLevelUp` still writes the leaderboard.

- [ ] **Step 3: Implement**

- Add `String? clubId` as the last named parameter of `logHabitCompletion`, `logLevelUp`, `logChallengeComplete`, `logStreakMilestone`, `logNodeClaim`, `logBadgeEarned`, `logPartnerJoined`, `logContractCommitted`; resolve once at the top of each: `final resolvedClubId = clubId ?? _getClubIdForArchetype(archetype);` and use `resolvedClubId` everywhere the method currently calls `_getClubIdForArchetype` (Drift activity row, global activity payload, club activity path, leaderboard call).
- In `logLevelUp`: **delete the `updateUserScore` block (`:271-283`)** — keep the Drift activity row, global/club activity feeds, and partner fan-out. Add a comment: level is derivable from XP; the increment path is the single write shape (SP-G D7).
- Leave `logChallengeComplete`'s `updateUserScore(..., isIncrement: true)` as-is (it becomes reachable via T6).
- `logHabitCompletion`'s leaderboard call (`:183-197`) keeps `isIncrement: true` but uses `resolvedClubId`.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/social/domain/services/club_activity_service_test.dart test/features/social/domain/services/club_activity_service_extended_test.dart test/features/social/domain/services/club_activity_service_partner_fanout_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/social/domain/services/club_activity_service.dart test/features/social/domain/services/club_activity_service_test.dart test/features/social/domain/services/club_activity_service_extended_test.dart test/features/social/domain/services/club_activity_service_partner_fanout_test.dart
git commit -m "fix(leaderboard): clubId override + drop logLevelUp absolute write (SP-G T7, B7/B8)"
```

## Task 8: Attribution plumbing — habit completions and leaderboard screen use the active tribe (B8, B14-UI)

**Files:**
- Modify: `lib/core/drift_repositories/drift_habit_repository.dart` (`completeHabit` social call `:466-476`)
- Modify: `lib/features/social/presentation/screens/leaderboard_screen.dart` (`_TribeLeaderboardTab` `:142-233`, `_archetypeToClubId` `:123-138`)
- Test: `test/core/drift_repositories/drift_habit_repository_test.dart`, `test/features/social/presentation/screens/leaderboard_screen_test.dart`

- [ ] **Step 1: Write the failing tests**

```dart
// drift_habit_repository_test.dart
test('completeHabit passes the active tribe as clubId to social logging', () async {
  await db.tribeMembershipDao.upsertMembership(/* user1 -> tribeA active */);
  await repository.completeHabit(habit.id, DateTime.now(), activeTribeId: 'tribeA');
  verify(() => mockSocialService.logHabitCompletion(
    userId: userId,
    userName: any(named: 'userName'),
    archetype: any(named: 'archetype'),
    habitId: habit.id,
    habitTitle: any(named: 'habitTitle'),
    streakDay: any(named: 'streakDay'),
    attribute: any(named: 'attribute'),
    xpGained: any(named: 'xpGained'),
    currentLevel: any(named: 'currentLevel'),
    clubId: 'tribeA',
  )).called(1);
});

// leaderboard_screen_test.dart — extend the existing tribe-tab test
test('tribe leaderboard tab watches the ACTIVE tribe, not the archetype club', () async {
  // seed active membership -> tribeA (activeMembershipProvider backed by Drift)
  // pump the screen; assert clubLeaderboardProvider was read with 'tribeA'
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/drift_repositories/drift_habit_repository_test.dart test/features/social/presentation/screens/leaderboard_screen_test.dart`
Expected: FAIL — `clubId` not passed; leaderboard screen still uses `_archetypeToClubId`.

- [ ] **Step 3: Implement**

- `drift_habit_repository.dart`: in `completeHabit`, pass `clubId: tribeId` to `_socialService.logHabitCompletion` (the variable `tribeId` resolved at `:360-459`; it is null when the user has no tribe — the service falls back to archetype).
- `leaderboard_screen.dart` `_TribeLeaderboardTab.build`: watch `activeMembershipProvider` (from `tribes_provider.dart`); `final clubId = membership?.tribeId ?? _archetypeToClubId(profile.archetype.name);` and watch `clubLeaderboardProvider(clubId)`. Keep `_archetypeToClubId` as the fallback (no membership yet).
- If the widget test harness cannot seed `activeMembershipProvider` cheaply, cover the fallback branch and the membership branch with two pumped states (existing test file already pumps the screen with a profile; add Drift membership seeding via `appDatabaseProvider` override — check the existing harness in `leaderboard_screen_test.dart` for the provider-override pattern and reuse it).

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/drift_repositories/drift_habit_repository_test.dart test/features/social/presentation/screens/leaderboard_screen_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/drift_repositories/drift_habit_repository.dart lib/features/social/presentation/screens/leaderboard_screen.dart test/core/drift_repositories/drift_habit_repository_test.dart test/features/social/presentation/screens/leaderboard_screen_test.dart
git commit -m "fix(leaderboard): attribute to the active tribe everywhere (SP-G T8, B8)"
```

## Task 9: Syncer reads `club_leaderboards` by `clubId` (B14)

**Files:**
- Modify: `lib/features/social/domain/services/firestore_drift_syncer.dart` (`:26-29`, `:37`)
- Test: `test/features/social/domain/services/firestore_drift_syncer_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
test('start() pulls leaderboard rows by clubId, not tribeId', () async {
  // seed fakeFirestore club_leaderboards with doc {userId, clubId: 'tribeA', xp, level}
  syncer.start('tribeA');
  await pumpEventQueue();
  final rows = await leaderboardDao.getForTribe('tribeA');
  expect(rows, isNotEmpty);
  expect(rows.first.tribeId, 'tribeA');
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/social/domain/services/firestore_drift_syncer_test.dart`
Expected: FAIL — the query `where('tribeId', ...)` matches nothing; no rows synced.

- [ ] **Step 3: Implement**

- `firestore_drift_syncer.dart:28`: `where('clubId', isEqualTo: tribeId)`.
- `:37`: upsert `tribeId: Value(data['clubId'] as String? ?? tribeId)` (the Drift table column stays `tribeId`; it is the leaderboard's key and equals the tribe/club id).
- Update the existing tests in the file that seeded `tribeId` on remote docs to seed `clubId` instead.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/social/domain/services/firestore_drift_syncer_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/social/domain/services/firestore_drift_syncer.dart test/features/social/domain/services/firestore_drift_syncer_test.dart
git commit -m "fix(sync): club_leaderboards pulled by clubId field (SP-G T9, B14)"
```

---

# Phase 5 — Stale-roster UI filtering (D8)

## Task 10: Contributors and leaderboard views filter out users who left (B10)

**Files:**
- Modify: `lib/features/social/presentation/screens/tribe_members_tab.dart` (pass members: `:383-391`), `lib/features/social/presentation/widgets/tribe_header_widgets.dart` (`ContributorsSection` `:255-323`), `lib/features/social/presentation/screens/leaderboard_screen.dart` (tribe tab list)
- Test: `test/features/social/presentation/widgets/tribe_leaderboard_widget_test.dart`, new `test/features/social/presentation/widgets/tribe_header_widgets_test.dart`, `test/features/social/presentation/screens/leaderboard_screen_test.dart`

- [ ] **Step 1: Write the failing tests**

```dart
// tribe_header_widgets_test.dart (new)
test('ContributorsSection hides users not in the members array', () async {
  // pump ContributorsSection(clubId: 'tribeA', members: ['u1'])
  // with Drift leaderboard entries for u1 and u2 (u2 left)
  expect(find.text('U1'), findsOneWidget);
  expect(find.text('U2'), findsNothing);
});

test('ContributorsSection shows everyone when members is empty (creator tribes)', () async {
  // same pump with members: [] -> both u1 and u2 visible
});

// tribe_leaderboard_widget_test.dart
test('TribeLeaderboardSection hides leavers when members is provided', () async {
  // pump TribeLeaderboardSection(clubId: 'tribeA', members: ['u1'], ...)
  // Drift entries u1, u2 -> only u1 rendered
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/social/presentation/widgets/tribe_header_widgets_test.dart test/features/social/presentation/widgets/tribe_leaderboard_widget_test.dart`
Expected: FAIL — sections render all entries (no filter).

- [ ] **Step 3: Implement**

- `ContributorsSection`: add `final List<String> members;` (default `const []`). Filter: `final visible = members.isEmpty ? contributors : contributors.where((c) => members.contains(c['userId'])).toList();` and render `visible` (empty → `SizedBox.shrink()` as today).
- `TribeMembersTab._buildMembersTab`: pass `members: userClub.members` to `ContributorsSection` and `TribeLeaderboardSection`.
- `TribeLeaderboardSection`: add the same optional `members` filter (it already has `clubId`/`archetypeName`); filter the `entries` list before ranking display.
- `leaderboard_screen.dart` tribe tab: watch the active tribe's remote members (via `watchUserTribes(userId)` stream — it already listens to `tribes where members arrayContains user`; take the first doc's `members`) and filter `entries` before passing to `_LeaderboardList`. When no membership, fall back to unfiltered (archetype club view).

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/social/presentation/widgets/tribe_header_widgets_test.dart test/features/social/presentation/widgets/tribe_leaderboard_widget_test.dart test/features/social/presentation/screens/leaderboard_screen_test.dart test/features/social/presentation/screens/tribe_lobby_screen_test.dart`
Expected: PASS (lobby test guards the tab wiring).

- [ ] **Step 5: Commit**

```bash
git add lib/features/social/presentation/screens/tribe_members_tab.dart lib/features/social/presentation/widgets/tribe_header_widgets.dart lib/features/social/presentation/screens/leaderboard_screen.dart test/features/social/presentation/widgets/tribe_header_widgets_test.dart test/features/social/presentation/widgets/tribe_leaderboard_widget_test.dart test/features/social/presentation/screens/leaderboard_screen_test.dart
git commit -m "fix(ui): roster/leaderboard filter out users who left the tribe (SP-G T10, B10)"
```

---

# Phase 6 — Rules hardening (D9)

## Task 11: `firestore.rules` — memberCount/members diff validation + leave copy cleanup (B13, D2)

**Files:**
- Modify: `firestore.rules` (`tribes` block `:361-372`; create branch `:363`)
- Modify: `lib/features/social/presentation/widgets/tribe_card.dart` (dialog copy `:195-198`; drop `syncTribeStats` calls `:217,229`), `lib/features/social/data/services/tribe_stats_service.dart` (remove `syncTribeStats` `:236-254`), `lib/features/social/presentation/providers/cached_tribe_stats_provider.dart` (remote-preferred merge `:39-73`), `lib/core/drift_repositories/drift_tribe_repository.dart` (`_mergeTribeData` remote-preferred `:679-692`)
- Test: `test/features/social/presentation/widgets/tribe_card_test.dart`, `test/features/social/presentation/screens/all_tribes_screen_test.dart`, `test/features/social/data/services/tribe_stats_service_test.dart`

> Not TDD: no rules-test harness exists (verified — no `@firebase/rules-unit-testing` in any package.json; `firestore-tests/` holds only emulator logs). The rules edit is verified manually against the emulator (Step 4). The Dart changes in this task are TDD'd normally.

- [ ] **Step 1: Dart-side failing tests** (tribe_card)

```dart
test('leave dialog says contributions stay on the tribe record', () async {
  // pump TribeCard for a tribe where user is a member; tap LEAVE
  expect(find.textContaining('contributions stay'), findsOneWidget);
  expect(find.textContaining('lose your'), findsNothing);
});

test('join/leave do not call syncTribeStats', () async {
  // pump, tap LEAVE (confirm), assert no TribeStatsService.syncTribeStats invocation
  // (the button handler calls membershipService.leaveTribe only)
});
```

- [ ] **Step 2: Run Dart tests to verify they fail**

Run: `flutter test test/features/social/presentation/widgets/tribe_card_test.dart test/features/social/data/services/tribe_stats_service_test.dart test/features/social/presentation/screens/all_tribes_screen_test.dart`
Expected: FAIL — old copy present; syncTribeStats still called and still tested.

- [ ] **Step 3: Implement**

**Dart:**
- `tribe_card.dart:195-198` copy → `'Are you sure you want to leave? Your streak progress stays, and your contributions remain on the tribe\'s record.'`
- `tribe_card.dart:217,229`: delete the two `await statsService.syncTribeStats(tribe.id);` lines and the now-unused `statsService` read (`:181`).
- `tribe_stats_service.dart`: delete `syncTribeStats` (`:236-254`); keep the read helpers. Update `tribe_stats_service_test.dart`: remove the syncTribeStats tests; keep/adapt getTribeStats tests.
- `cached_tribe_stats_provider.dart:39-73`: change `totalXp`/`totalHabitsCompleted`/`totalChallengesCompleted` merge from max() to remote-preferred: `final totalXp = remoteData?['totalXp'] as int? ?? localTotalXp;` (same for habits/challenges; memberCount already remote-preferred).
- `drift_tribe_repository.dart:_mergeTribeData:679-692`: same remote-preferred switch (match `watchArchetypeClubs.emitMerged` which already prefers remote).

**Rules (`firestore.rules:361-372`) — replace the update branch:**

```javascript
match /tribes/{tribeId} {
  allow read: if isAuthenticated();
  allow create: if isAuthenticated() && isValidTribe(request.resource.data) &&
                 request.resource.data.type != 'official' &&
                 request.resource.data.type != 'brand';
  allow update: if isAuthenticated() && isValidTribe(request.resource.data) && (
    resource.data.createdBy == request.auth.uid ||
    isAdmin() ||
    // SP-G D9: aggregate membership writes only — keys, ±1 delta, and the
    // caller's own uid must be the added/removed member.
    (request.resource.data.diff(resource.data).affectedKeys()
        .hasOnly(['memberCount', 'members', 'lastStatsSync']) &&
     'members' in resource.data &&
     (request.resource.data.memberCount == resource.data.memberCount + 1 ||
      request.resource.data.memberCount == resource.data.memberCount - 1) &&
     request.resource.data.memberCount == resource.data.memberCount +
         (request.resource.data.members.size() - resource.data.members.size()) &&
     ((request.resource.data.members.size() == resource.data.members.size() + 1 &&
       request.resource.data.members.hasAll(resource.data.members) &&
       request.resource.data.members.hasAny([request.auth.uid])) ||
      (request.resource.data.members.size() + 1 == resource.data.members.size() &&
       resource.data.members.hasAll(request.resource.data.members) &&
       resource.data.members.hasAny([request.auth.uid]))))
  );
  allow delete: if isAdmin();
  ...
}
```

Leave the `contributors`/`activity` sub-rules untouched (`:376-391`). Note: the working tree already has uncommitted `firestore.rules` changes — edit the current file content incrementally, preserving unrelated edits.

- [ ] **Step 4: Verify rules against the emulator (manual, documented)**

```bash
firebase emulators:start --only firestore
# From a scratch script (throwaway, not committed) using the Admin SDK with
# rules enforcement ON (or the firebase CLI rules tester), replay:
#  JOIN:   update memberCount +1, members arrayUnion([uid])        -> ALLOW
#  LEAVE:  update memberCount -1, members arrayRemove([uid])       -> ALLOW
#  BAD+2:  memberCount +2, members +2                              -> DENY
#  BADKEY: update totalXp only (diff keys)                         -> DENY
#  BADVAL: memberCount +1 but members +1 without caller's uid      -> DENY
#  CREATE official / brand                                         -> DENY
#  CREATE userPrivate (creator tribe)                              -> ALLOW
```

Record the results in the task's final commit message body or a scratch note; do not commit the scratch script.

- [ ] **Step 5: Run Dart tests to verify they pass**

Run: `flutter test test/features/social/presentation/widgets/tribe_card_test.dart test/features/social/data/services/tribe_stats_service_test.dart test/features/social/presentation/screens/all_tribes_screen_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add firestore.rules lib/features/social/presentation/widgets/tribe_card.dart lib/features/social/data/services/tribe_stats_service.dart lib/features/social/presentation/providers/cached_tribe_stats_provider.dart lib/core/drift_repositories/drift_tribe_repository.dart test/features/social/presentation/widgets/tribe_card_test.dart test/features/social/data/services/tribe_stats_service_test.dart test/features/social/presentation/screens/all_tribes_screen_test.dart
git commit -m "fix(rules): memberCount/members diff validation, official/brand create ban; leave copy + recalc-only tribe totals (SP-G T11, B13/D2/D4)"
```

---

# Phase 7 — Server recalc (D10)

## Task 12: Pure `aggregateTribeStats` + jest tests

**Files:**
- Modify: `functions/src/recalcTribes.ts` (add + export the pure function)
- Create: `functions/test/recalcTribes.test.ts`

- [ ] **Step 1: Write the failing test** (functions tooling: jest + ts-jest, `cd functions && npm test`, tests import TS sources directly)

```ts
import { aggregateTribeStats } from "../src/recalcTribes";

describe("aggregateTribeStats", () => {
  it("uses explicit membership over the archetype club", () => {
    const out = aggregateTribeStats({
      membershipMap: new Map([["u1", "creative_collective"]]),
      archetypeMap: new Map([["u1", "athlete"]]),
      clubMap: { athlete: "morning_warriors" },
      userStatsXp: new Map([["u1", 100]]),
    });
    expect(out.get("creative_collective")?.members).toEqual(["u1"]);
    expect(out.get("creative_collective")?.totalXp).toBe(100);
    expect(out.has("morning_warriors")).toBe(false);
  });

  it("falls back to the official archetype club for users without explicit membership", () => {
    const out = aggregateTribeStats({
      membershipMap: new Map(),
      archetypeMap: new Map([["u2", "stoic"]]),
      clubMap: { stoic: "mindful_masters" },
      userStatsXp: new Map([["u2", 42]]),
    });
    expect(out.get("mindful_masters")?.members).toEqual(["u2"]);
    expect(out.get("mindful_masters")?.totalXp).toBe(42);
  });

  it("drops users with no explicit membership and no official club (archetype none/unknown)", () => {
    const out = aggregateTribeStats({
      membershipMap: new Map(),
      archetypeMap: new Map([["u3", "none"]]),
      clubMap: {},
      userStatsXp: new Map([["u3", 7]]),
    });
    expect(out.size).toBe(0);
  });

  it("aggregates XP per member directly, not by archetype bucket", () => {
    const out = aggregateTribeStats({
      membershipMap: new Map([["a1", "creative_collective"], ["a2", "creative_collective"]]),
      archetypeMap: new Map([["a1", "athlete"], ["a2", "stoic"]]),
      clubMap: { athlete: "morning_warriors", stoic: "mindful_masters" },
      userStatsXp: new Map([["a1", 10], ["a2", 20]]),
    });
    expect(out.get("creative_collective")?.totalXp).toBe(30);
    expect(out.get("morning_warriors")).toBeUndefined();
    expect(out.get("mindful_masters")).toBeUndefined();
  });

  it("members without user_stats docs contribute 0 XP", () => {
    const out = aggregateTribeStats({
      membershipMap: new Map([["u5", "deep_work_society"]]),
      archetypeMap: new Map(),
      clubMap: {},
      userStatsXp: new Map(),
    });
    expect(out.get("deep_work_society")?.totalXp).toBe(0);
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd functions && npm test -- --testPathPattern=recalcTribes`
Expected: FAIL — `aggregateTribeStats` does not exist.

- [ ] **Step 3: Implement** (append to `functions/src/recalcTribes.ts`; keep the existing `recalcTribesInternal` untouched for now — T13 rewires it)

```ts
export interface TribeAggregationInput {
  /** uid -> explicit tribeId from users/{uid}/tribes (collectionGroup). */
  membershipMap: Map<string, string>;
  /** uid -> lowercase archetype (may be 'none'). */
  archetypeMap: Map<string, string>;
  /** archetype -> official clubId (the 6 official clubs). */
  clubMap: Record<string, string>;
  /** uid -> user_stats.avatarStats.totalXp. */
  userStatsXp: Map<string, number>;
}

/**
 * Pure SP-G D10 aggregation: members = explicit membership docs, plus the
 * official archetype club as a fallback ONLY for users without explicit
 * membership. XP is summed per member directly (no archetype bucketing).
 */
export function aggregateTribeStats(
  input: TribeAggregationInput,
): Map<string, { members: string[]; totalXp: number }> {
  const byTribe = new Map<string, { members: string[]; totalXp: number }>();
  const ensure = (tribeId: string) => {
    let entry = byTribe.get(tribeId);
    if (!entry) {
      entry = { members: [], totalXp: 0 };
      byTribe.set(tribeId, entry);
    }
    return entry;
  };

  const uids = new Set([...input.membershipMap.keys(), ...input.archetypeMap.keys()]);
  for (const uid of uids) {
    const tribeId =
      input.membershipMap.get(uid) ??
      input.clubMap[input.archetypeMap.get(uid) ?? ""];
    if (!tribeId) continue; // no explicit membership and no official club
    const entry = ensure(tribeId);
    entry.members.push(uid);
    entry.totalXp += input.userStatsXp.get(uid) ?? 0;
  }
  return byTribe;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd functions && npm test -- --testPathPattern=recalcTribes`
Expected: PASS — 5 tests.

- [ ] **Step 5: Commit**

```bash
git add functions/src/recalcTribes.ts functions/test/recalcTribes.test.ts
git commit -m "feat(functions): pure aggregateTribeStats — explicit membership + per-member XP (SP-G T12, B4)"
```

## Task 13: Rewire `recalcTribesInternal` to all tribes with merge-set writes

**Files:**
- Modify: `functions/src/recalcTribes.ts` (`recalcTribesInternal` `:16-164`)

- [ ] **Step 1: Write the failing test** (jest — drive `recalcTribesInternal` with a stubbed `db` that records batch calls; the function takes `db` as a parameter, so a minimal fake with `collection().stream()`, `collectionGroup().stream()`, and `batch()` recording is sufficient)

```ts
import { recalcTribesInternal } from "../src/recalcTribes";

describe("recalcTribesInternal", () => {
  it("writes every tribe from membership docs, not just official clubs", async () => {
    // fake db: users stream -> [{id: 'u1', archetype: 'athlete'}]
    //           collectionGroup('tribes') -> u1 -> creator_tribe_42 (explicit)
    //           user_stats stream -> {id: 'u1', avatarStats: {totalXp: 300}}
    //           global_activities stream -> []
    // assert the batch contains a write to 'tribes/creator_tribe_42' with
    // members ['u1'], memberCount 1, totalXp 300, and NO write for
    // morning_warriors (u1's archetype club).
  });

  it("uses merge-set writes so creator tribe fields are preserved", async () => {
    // assert batch.set(..., {merge: true}) is used for tribe docs
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd functions && npm test -- --testPathPattern=recalcTribes`
Expected: FAIL — current implementation only writes the 6 official club ids and uses `batch.update`.

- [ ] **Step 3: Implement** — rewrite `recalcTribesInternal`:

1. Stream `users` with `select("archetype")` into `archetypeMap` (drop the `userToTribeMap` + `clubMap`-only handling).
2. Stream `collectionGroup("tribes")` into `membershipMap` (uid → tribeId; keep the existing path-shape guard `parts.length === 4`).
3. Stream `user_stats` into `userStatsXp` (uid → `avatarStats.totalXp` (fallback root `totalXp`), same precedence as today `:93-97`).
4. Stream `global_activities` into per-clubId `{habits, challenges}` (unchanged semantics — keep the existing aggregation `:113-132`).
5. `const byTribe = aggregateTribeStats({membershipMap, archetypeMap, clubMap, userStatsXp});`
6. `const tribeIds = new Set([...byTribe.keys(), ...new Set(Object.values(clubMap))]);`
7. Chunk `tribeIds` into batches of 500; per tribe: `batch.set(tribeRef, {members, memberCount: members.length, totalXp, totalHabitsCompleted: activities.habits, totalChallengesCompleted: activities.challenges, lastStatsSync: admin.firestore.FieldValue.serverTimestamp()}, {merge: true})` — merge preserves creator-tribe `ownerId`/`name`/`type` and creates missing docs.
8. Keep the log lines and the return count; keep the non-transactional batch (documented tradeoff in the spec §8).
9. Delete the now-unused `userToTribeMap`/`tribeMembers`/`tribeXp` scaffolding.

- [ ] **Step 4: Run test to verify it passes**

Run: `cd functions && npm test`
Expected: PASS — recalcTribes suite + all pre-existing functions tests (`index.test.ts`, `create_starter_pack.test.ts`, `paystack.test.ts`, `seed_starter_habits.test.ts`).

- [ ] **Step 5: Commit**

```bash
git add functions/src/recalcTribes.ts
git commit -m "feat(functions): recalc all tribes from explicit membership with merge-set writes (SP-G T13, B4)"
```

---

# Phase 8 — Final verification

## Task 14: Whole-repo sweep + dead code check

**Steps:**

- [ ] **Step 1: Static analysis**

Run: `dart analyze lib test`
Expected: 0 issues introduced by SP-G (baseline from Pre-flight item 2 may show pre-existing ones — compare, don't fix unrelated).

- [ ] **Step 2: Full Flutter test suite**

Run: `flutter test`
Expected: all pass, including the previously failing `tribe_membership_service_test.dart` (fixed in T3) and the SP-A handoff item.

- [ ] **Step 3: Functions suite**

Run: `cd functions && npm test`
Expected: PASS.

- [ ] **Step 4: Dead-code / leftover check**

Run: `grep -rn "syncTribeStats" lib test` → no hits; `grep -rn "tribeId" lib/features/social/domain/services/firestore_drift_syncer.dart` → only the Drift column mapping; `grep -rn "isIncrement: false" lib` → only `DriftLeaderboardRepository.updateUserScore`'s signature/default (no callers pass `false` anymore).

- [ ] **Step 5: Commit any stragglers from earlier tasks that were necessarily combined** (e.g., if T6's compile dependency forced the T7 signature change into the same commit, note it here; otherwise no commit).

```bash
# only if there are uncommitted SP-G files
git add -u lib test functions firestore.rules
git commit -m "chore(sp-g): final sweep leftovers"
```

**Final state:** `dart analyze lib test` clean (SP-G delta), full `flutter test` green, `cd functions && npm test` green; manual smoke (device run) still needed for: onboarding join → single memberCount bump, leave dialog copy, challenge completion leaderboard row, and the 3AM recalc result for a creator tribe.

---

## Out of scope (see spec §10 for the full list)

XP spoofing (B15 → SP-H), server-side join/leave callables (SP-H), D2's clean-break alternative (user chose Keep everything), backfill purges of already-stale data, new rules-test harness.
