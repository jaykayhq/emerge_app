import 'package:drift/native.dart';
import 'package:emerge_app/core/deletion/deletion_audit.dart';
import 'package:emerge_app/core/deletion/deletion_service.dart';
import 'package:emerge_app/core/deletion/sync_status.dart';
import 'package:emerge_app/core/drift/database.dart';
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

  setUp(() async {
    db = AppDatabase.withExecutor(NativeDatabase.memory());
    final engine = EnhancedSyncEngine(
      db.mutationQueueDao,
      FakeFirebaseFirestore(),
      metrics: SyncMetrics(),
    );
    final social = MockSocialActivityService();
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
        )).thenAnswer((_) async {});
    when(() => social.logActivity(
          type: any(named: 'type'),
          userId: any(named: 'userId'),
          data: any(named: 'data'),
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

  test('completing an already-completed habit UNDOES it (removes today '
      'completion + resets streak), not a silent no-op', () async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

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
        totalXp: const Value(0),
        vitalityXp: const Value(0),
        worldHealthScore: const Value(0.5),
        updatedAt: Value(now.toIso8601String()),
      ),
    );

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
}
