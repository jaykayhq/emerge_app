import 'package:drift/native.dart';
import 'package:emerge_app/core/deletion/deletion_audit.dart';
import 'package:emerge_app/core/deletion/deletion_service.dart';
import 'package:emerge_app/core/deletion/sync_status.dart';
import 'package:emerge_app/core/drift/database.dart';
import 'package:emerge_app/core/drift_repositories/drift_habit_repository.dart';
import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/core/game_loop/game_loop_engine.dart';
import 'package:emerge_app/core/sync/sync_engine.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/onboarding/domain/models/interest.dart';
import 'package:emerge_app/features/onboarding/domain/models/starter_habit_blueprint.dart';
import 'package:emerge_app/features/social/domain/services/club_activity_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockSocialActivityService extends Mock implements SocialActivityService {}

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
    when(
      () => social.logActivity(
        type: any(named: 'type'),
        userId: any(named: 'userId'),
        data: any(named: 'data'),
      ),
    ).thenAnswer((_) async {});
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

  test(
    'deleteHabit archives via DeletionService and preserves fields',
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
    },
  );

  test('deleteHabit of missing habit returns Left', () async {
    final res = await repo.deleteHabit('nope');
    expect(res.isLeft(), isTrue);
  });

  test(
    'createStarterPack persists timeOfDayPreference derived from the cue',
    () async {
      final res = await repo.createStarterPack(
        userId: 'u1',
        blueprints: const [
          StarterHabitBlueprint(
            id: 'athlete.squats.10',
            title: '10 squats',
            shortCue: 'After breakfast',
            attribute: HabitAttribute.vitality,
            timerDurationMinutes: 3,
            archetype: UserArchetype.athlete,
            interestCategories: [InterestCategory.movement],
            clubTags: [],
            sourceAttribution: 'happytrainers.com',
          ),
          StarterHabitBlueprint(
            id: 'scholar.read.2pages',
            title: 'Read 2 pages',
            shortCue: 'Before bed',
            attribute: HabitAttribute.intellect,
            timerDurationMinutes: 5,
            archetype: UserArchetype.scholar,
            interestCategories: [InterestCategory.learning],
            clubTags: [],
            sourceAttribution: 'James Clear',
          ),
        ],
      );

      final habits = res.getRight().getOrElse(() => <Habit>[]);
      expect(habits.length, 2);
      expect(habits[0].timeOfDayPreference, TimeOfDayPreference.morning);
      expect(habits[1].timeOfDayPreference, TimeOfDayPreference.anytime);

      final row = await db.habitsDao.getHabit(habits[0].id);
      expect(row!.timeOfDayPreference, 'morning');
    },
  );
}
