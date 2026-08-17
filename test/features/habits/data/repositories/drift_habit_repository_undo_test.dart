import 'dart:convert';

import 'package:drift/native.dart';
import 'package:emerge_app/core/deletion/deletion_audit.dart';
import 'package:emerge_app/core/deletion/deletion_service.dart';
import 'package:emerge_app/core/deletion/sync_status.dart';
import 'package:emerge_app/core/drift/database.dart' hide isNotNull, isNull;
import 'package:emerge_app/core/drift_repositories/drift_habit_repository.dart';
import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/core/game_loop/game_loop_engine.dart';
import 'package:emerge_app/core/sync/sync_engine.dart';
import 'package:emerge_app/features/social/domain/services/club_activity_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockSocialActivityService extends Mock
    implements SocialActivityService {}

void main() {
  late AppDatabase db;
  late DriftHabitRepository repo;
  late MockSocialActivityService social;

  setUp(() async {
    db = AppDatabase.withExecutor(NativeDatabase.memory());
    final engine = EnhancedSyncEngine(
      db.mutationQueueDao,
      FakeFirebaseFirestore(),
      metrics: SyncMetrics(),
    );
    social = MockSocialActivityService();
    // Stub the fire-and-forget activity logging the repo calls.
    when(() => social.logHabitCompletion(
          userId: any(named: 'userId'),
          userName: any(named: 'userName'),
          archetype: any(named: 'archetype'),
          habitId: any(named: 'habitId'),
          habitTitle: any(named: 'habitTitle'),
          streakDay: any(named: 'streakDay'),
          attribute: any(named: 'attribute'),
          xpGained: any(named: 'xpGained'),
          currentLevel: any(named: 'currentLevel'),
          clubId: any(named: 'clubId'),
        )).thenAnswer((_) async {});
    when(() => social.logActivity(
          type: any(named: 'type'),
          userId: any(named: 'userId'),
          data: any(named: 'data'),
        )).thenAnswer((_) async {});
    when(() => social.undoHabitCompletion(
          userId: any(named: 'userId'),
          userName: any(named: 'userName'),
          archetype: any(named: 'archetype'),
          habitId: any(named: 'habitId'),
          xpToUndo: any(named: 'xpToUndo'),
          level: any(named: 'level'),
          clubId: any(named: 'clubId'),
        )).thenAnswer((_) async {});
    repo = DriftHabitRepository(
      db: db,
      gameLoopEngine: LocalGameLoopEngine(),
      syncEngine: engine,
      socialService: social,
      deletionService: DeletionService(
        db: db,
        syncEngine: engine,
        audit: DeletionAudit(metrics: SyncMetrics()),
      ),
    );
  });
  tearDown(() => db.close());

  Future<void> seedHabitAndStats() async {
    final now = DateTime.now();
    await db.habitsDao.insertFromData(
      id: 'h1',
      userId: 'u1',
      title: 'Read',
      currentStreak: 0,
      momentumScore: 50,
      createdAt: now.toIso8601String(),
      updatedAt: now.toIso8601String(),
    );
    await db.userStatsDao.upsertStats(
      UserStatsTableCompanion(
        userId: const Value('u1'),
        displayName: const Value('Test User'),
        archetype: const Value('athlete'),
        totalXp: const Value(0),
        vitalityXp: const Value(0),
        worldHealthScore: const Value(0.5),
        updatedAt: Value(now.toIso8601String()),
      ),
    );
  }

  test('completing an already-completed habit UNDOES it (removes today '
      'completion + resets streak), not a silent no-op', () async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    await seedHabitAndStats();

    // First completion -> should be a real completion.
    final first = await repo.completeHabit('h1', today);
    expect(first, const Right<Failure, bool>(true));
    final afterFirstRow = await db.habitsDao.getHabit('h1');
    expect(afterFirstRow!.currentStreak, 1);
    final completionsAfterFirst =
        await db.habitCompletionsDao.getTodayCompletions('u1');
    expect(completionsAfterFirst.length, 1,
        reason: 'first completion should create exactly one completion row');

    // Second completion same day -> this is the UNDO path.
    final second = await repo.completeHabit('h1', today);
    expect(second, const Right<Failure, bool>(false),
        reason: 'already-completed returns isUndo: false');

    // THE BUG: undo must actually remove today's completion + reset streak.
    final completionsAfterUndo =
        await db.habitCompletionsDao.getTodayCompletions('u1');
    expect(completionsAfterUndo.length, 0,
        reason: 'undo must delete today\'s completion row(s)');
    final afterUndoRow = await db.habitsDao.getHabit('h1');
    expect(afterUndoRow!.currentStreak, 0,
        reason: 'undo must reset streak to 0');
  });

  test('undo debits local tribe stats and mirrors the contributor write',
      () async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    await seedHabitAndStats();
    await db.tribeMembershipDao.upsertMembership(
      UserTribeTableData(
        userId: 'u1',
        tribeId: 't1',
        membershipType: 'creator',
        joinedAt: now.toIso8601String(),
        isActive: true,
      ),
    );

    final first = await repo.completeHabit('h1', today);
    expect(first, const Right<Failure, bool>(true));

    final afterCredit = await db.tribeStatsDao.getStats('t1');
    expect(afterCredit, isNotNull,
        reason: 'credit must create/update the local tribe stats row');
    expect(afterCredit!.totalHabitsCompleted, 1);
    expect(afterCredit.userHabitsCompleted, 1);

    final second = await repo.completeHabit('h1', today);
    expect(second, const Right<Failure, bool>(false));

    final afterUndo = await db.tribeStatsDao.getStats('t1');
    expect(afterUndo!.totalHabitsCompleted, 0,
        reason: 'undo must debit the local tribe stats habits counter');
    expect(afterUndo.userHabitsCompleted, 0);
    expect(afterUndo.totalXp, 0,
        reason: 'undo must debit the local tribe stats XP');
    expect(afterUndo.userContributionXp, 0);

    // The remote contributor record must be debited by the same total the
    // credit added (base + challenge XP), so the nightly recalc reconciles.
    final mutations = await db.mutationQueueDao.getAllPending();
    final contributorDebits = mutations
        .where((m) =>
            m.collectionPath == 'tribes/t1/contributors' &&
            m.operation == 'update')
        .toList();
    expect(contributorDebits, hasLength(1));
    final data = jsonDecode(contributorDebits.single.dataJson!) as Map;
    expect(data['totalHabitsCompleted'], {
      '__type__': 'increment',
      'value': -1,
    });
    expect((data['totalXpContributed'] as Map)['value'], -afterCredit.totalXp,
        reason: 'contributor XP debit must mirror the credited amount');
  });

  test('undo hands the reversed XP and credit-time tribe to the social '
      'service for leaderboard/activity reversal', () async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    await seedHabitAndStats();
    await db.tribeMembershipDao.upsertMembership(
      UserTribeTableData(
        userId: 'u1',
        tribeId: 't1',
        membershipType: 'creator',
        joinedAt: now.toIso8601String(),
        isActive: true,
      ),
    );

    final first = await repo.completeHabit('h1', today);
    expect(first, const Right<Failure, bool>(true));

    final second = await repo.completeHabit('h1', today);
    expect(second, const Right<Failure, bool>(false));

    verify(
      () => social.undoHabitCompletion(
        userId: 'u1',
        userName: 'Test User',
        archetype: 'athlete',
        habitId: 'h1',
        xpToUndo: any(named: 'xpToUndo'),
        level: any(named: 'level'),
        clubId: 't1',
      ),
    ).called(1);
  });
}
