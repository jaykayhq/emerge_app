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
    repo = DriftHabitRepository(
      db: db,
      gameLoopEngine: LocalGameLoopEngine(),
      syncEngine: engine,
      socialService: MockSocialActivityService(),
      deletionService: DeletionService(
        db: db,
        syncEngine: engine,
        audit: DeletionAudit(metrics: SyncMetrics()),
      ),
    );
  });
  tearDown(() => db.close());

  test('deleteHabit archives via DeletionService and preserves fields',
      () async {
    await db.habitsDao.insertFromData(
      id: 'h1',
      userId: 'u1',
      title: 'Read',
      cue: 'after coffee',
      currentStreak: 7,
      createdAt: DateTime(2026).toIso8601String(),
      updatedAt: DateTime(2026).toIso8601String(),
    );

    final res = await repo.deleteHabit('h1');
    expect(res, const Right<Failure, Unit>(unit));

    final row = await db.habitsDao.getHabit('h1');
    expect(row!.isArchived, 1);
    expect(row.cue, 'after coffee'); // not blanked by insertFromData
    expect(row.currentStreak, 7); // not reset

    final pending = await db.mutationQueueDao.getAllPending();
    expect(pending.length, 1);
    expect(pending.first.idempotencyKey, 'del:habit:h1');
  });

  test('deleteHabit of missing habit returns Left', () async {
    final res = await repo.deleteHabit('nope');
    expect(res.isLeft(), isTrue);
  });
}
