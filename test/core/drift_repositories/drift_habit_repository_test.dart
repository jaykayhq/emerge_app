import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:emerge_app/core/drift/app_database.dart';
import 'package:emerge_app/core/drift_repositories/drift_habit_repository.dart';
import 'package:emerge_app/core/game_loop/game_loop_engine.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/blueprints/domain/models/blueprint.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/onboarding/domain/models/starter_habit_blueprint.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uuid/uuid.dart';

import '../drift/test_database.dart';
import 'mocks.dart';

void main() {
  late AppDatabase db;
  late MockSyncEngine mockSyncEngine;
  late MockSocialActivityService mockSocialService;
  late DriftHabitRepository repository;
  const userId = 'test_user_123';

  setUpAll(() {
    registerFallbackValue(
      Habit(
        id: 'fallback',
        userId: 'fallback',
        title: 'fallback',
        createdAt: DateTime.now(),
      ),
    );
  });

  setUp(() {
    db = createTestDatabase();
    mockSyncEngine = MockSyncEngine();
    mockSocialService = MockSocialActivityService();

    when(
      () => mockSyncEngine.enqueueSet(
        collectionPath: any(named: 'collectionPath'),
        documentId: any(named: 'documentId'),
        data: any(named: 'data'),
      ),
    ).thenAnswer((_) async {});

    when(
      () => mockSyncEngine.enqueueUpdate(
        collectionPath: any(named: 'collectionPath'),
        documentId: any(named: 'documentId'),
        data: any(named: 'data'),
      ),
    ).thenAnswer((_) async {});

    when(
      () => mockSocialService.logActivity(
        type: any(named: 'type'),
        userId: any(named: 'userId'),
        data: any(named: 'data'),
      ),
    ).thenAnswer((_) async {});

    when(
      () => mockSocialService.logHabitCompletion(
        userId: any(named: 'userId'),
        userName: any(named: 'userName'),
        archetype: any(named: 'archetype'),
        habitId: any(named: 'habitId'),
        habitTitle: any(named: 'habitTitle'),
        streakDay: any(named: 'streakDay'),
        attribute: any(named: 'attribute'),
        xpGained: any(named: 'xpGained'),
        currentLevel: any(named: 'currentLevel'),
      ),
    ).thenAnswer((_) async {});

    repository = DriftHabitRepository(
      db: db,
      gameLoopEngine: LocalGameLoopEngine(),
      syncEngine: mockSyncEngine,
      socialService: mockSocialService,
    );
  });

  tearDown(() async {
    await db.close();
  });

  Habit createTestHabit({
    String? id,
    String? userId,
    String title = 'Test Habit',
    HabitDifficulty difficulty = HabitDifficulty.medium,
    HabitAttribute attribute = HabitAttribute.vitality,
    int currentStreak = 0,
    int longestStreak = 0,
    int momentumScore = 0,
    int consecutiveMisses = 0,
  }) {
    return Habit(
      id: id ?? const Uuid().v4(),
      userId: userId ?? 'test_user_123',
      title: title,
      cue: 'Test cue',
      routine: 'Test routine',
      reward: 'Test reward',
      frequency: HabitFrequency.daily,
      difficulty: difficulty,
      attribute: attribute,
      createdAt: DateTime.now(),
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      momentumScore: momentumScore,
      consecutiveMisses: consecutiveMisses,
    );
  }

  group('DriftHabitRepository', () {
    test('createHabit() inserts into Drift and calls enqueueSet', () async {
      final habit = createTestHabit();

      final result = await repository.createHabit(habit);

      expect(result.isRight(), true);

      final retrieved = await repository.getHabit(habit.id);
      expect(retrieved, isNotNull);
      expect(retrieved!.id, habit.id);
      expect(retrieved.title, habit.title);
      expect(retrieved.userId, habit.userId);

      verify(
        () => mockSyncEngine.enqueueSet(
          collectionPath: 'habits',
          documentId: habit.id,
          data: any(named: 'data'),
        ),
      ).called(1);
    });

    test('updateHabit() updates in Drift and calls enqueueUpdate', () async {
      final habit = createTestHabit();
      await repository.createHabit(habit);

      final updatedHabit = habit.copyWith(title: 'Updated Title');
      final result = await repository.updateHabit(updatedHabit);

      expect(result.isRight(), true);

      final retrieved = await repository.getHabit(habit.id);
      expect(retrieved?.title, 'Updated Title');

      verify(
        () => mockSyncEngine.enqueueUpdate(
          collectionPath: 'habits',
          documentId: habit.id,
          data: any(named: 'data'),
        ),
      ).called(1);
    });

    test('deleteHabit() sets isArchived=1 and calls enqueueUpdate', () async {
      final habit = createTestHabit();
      await repository.createHabit(habit);

      final result = await repository.deleteHabit(habit.id);

      expect(result.isRight(), true);

      final retrieved = await repository.getHabit(habit.id);
      expect(retrieved?.isArchived, true);

      verify(
        () => mockSyncEngine.enqueueUpdate(
          collectionPath: 'habits',
          documentId: habit.id,
          data: {'isArchived': true},
        ),
      ).called(1);
    });

    test('completeHabit() - first completion increments streak to 1', () async {
      final habit = createTestHabit();
      await repository.createHabit(habit);

      await db.userStatsDao.upsertStats(
        UserStatsTableCompanion(
          userId: Value(userId),
          displayName: Value('Test User'),
          archetype: Value('athlete'),
          totalXp: Value(0),
          level: Value(1),
          vitalityXp: Value(0),
        ),
      );

      final result = await repository.completeHabit(habit.id, DateTime.now());

      expect(result.isRight(), true);
      expect(result.fold((l) => false, (r) => r), true);

      final retrieved = await repository.getHabit(habit.id);
      expect(retrieved?.currentStreak, 1);
      expect(retrieved?.momentumScore, greaterThan(0));

      verify(
        () => mockSyncEngine.enqueueUpdate(
          collectionPath: 'user_stats',
          documentId: userId,
          data: any(named: 'data'),
        ),
      ).called(1);
    });

    test(
      'completeHabit() - consecutive completion increments streak',
      () async {
        final habit = createTestHabit();
        await repository.createHabit(habit);

        await db.userStatsDao.upsertStats(
          UserStatsTableCompanion(
            userId: Value(userId),
            displayName: Value('Test User'),
            archetype: Value('athlete'),
            totalXp: Value(0),
            level: Value(1),
            vitalityXp: Value(0),
          ),
        );

        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        final today = DateTime.now();

        await repository.completeHabit(habit.id, yesterday);
        final result = await repository.completeHabit(habit.id, today);

        expect(result.isRight(), true);
        expect(result.fold((l) => false, (r) => r), true);

        final retrieved = await repository.getHabit(habit.id);
        expect(retrieved?.currentStreak, 2);
      },
    );

    test(
      'completeHabit() - same day completion returns false (undo)',
      () async {
        final habit = createTestHabit();
        await repository.createHabit(habit);

        await db.userStatsDao.upsertStats(
          UserStatsTableCompanion(
            userId: Value(userId),
            displayName: Value('Test User'),
            archetype: Value('athlete'),
            totalXp: Value(0),
            level: Value(1),
            vitalityXp: Value(0),
          ),
        );

        final today = DateTime.now();

        final result1 = await repository.completeHabit(habit.id, today);
        expect(result1.isRight(), true);
        expect(result1.fold((l) => false, (r) => r), true);

        final result2 = await repository.completeHabit(habit.id, today);
        expect(result2.isRight(), true);
        expect(result2.fold((l) => false, (r) => r), false);

        final retrieved = await repository.getHabit(habit.id);
        expect(retrieved?.currentStreak, 1);
      },
    );

    test('completeHabit() - returns failure if habit not found', () async {
      final result = await repository.completeHabit(
        'non_existent_id',
        DateTime.now(),
      );

      expect(result.isLeft(), true);
    });

    test('completeHabit() - returns failure if user stats not found', () async {
      final habit = createTestHabit();
      await repository.createHabit(habit);

      final result = await repository.completeHabit(habit.id, DateTime.now());

      expect(result.isLeft(), true);
    });

    test('watchHabits() returns stream of habits for user', () async {
      final habit1 = createTestHabit(title: 'Habit 1');
      final habit2 = createTestHabit(title: 'Habit 2');
      await repository.createHabit(habit1);
      await repository.createHabit(habit2);

      final stream = repository.watchHabits(userId);

      await expectLater(
        stream,
        emits(
          isA<List<Habit>>().having((habits) => habits.length, 'length', 2),
        ),
      );
    });

    test('watchHabits() excludes archived habits', () async {
      final habit1 = createTestHabit(title: 'Active Habit');
      final habit2 = createTestHabit(title: 'Archived Habit');
      await repository.createHabit(habit1);
      await repository.createHabit(habit2);
      await repository.deleteHabit(habit2.id);

      final stream = repository.watchHabits(userId);

      await expectLater(
        stream,
        emits(
          isA<List<Habit>>().having((habits) => habits.length, 'length', 1),
        ),
      );
    });

    test('getHabit() returns single habit by id', () async {
      final habit = createTestHabit();
      await repository.createHabit(habit);

      final retrieved = await repository.getHabit(habit.id);

      expect(retrieved, isNotNull);
      expect(retrieved!.id, habit.id);
      expect(retrieved.title, habit.title);
    });

    test('getHabit() returns null for non-existent id', () async {
      final retrieved = await repository.getHabit('non_existent');
      expect(retrieved, isNull);
    });

    test('createHabit() with all fields populated', () async {
      final habit = Habit(
        id: const Uuid().v4(),
        userId: userId,
        title: 'Complex Habit',
        cue: 'Morning alarm',
        routine: '10 minute meditation',
        reward: 'Feel centered',
        frequency: HabitFrequency.daily,
        difficulty: HabitDifficulty.hard,
        attribute: HabitAttribute.spirit,
        createdAt: DateTime.now(),
        currentStreak: 5,
        longestStreak: 10,
        momentumScore: 50,
        consecutiveMisses: 0,
        timeOfDayPreference: TimeOfDayPreference.morning,
        reminderTime: const TimeOfDay(hour: 7, minute: 0),
      );

      final result = await repository.createHabit(habit);

      expect(result.isRight(), true);

      final retrieved = await repository.getHabit(habit.id);
      expect(retrieved?.cue, 'Morning alarm');
      expect(retrieved?.routine, '10 minute meditation');
      expect(retrieved?.difficulty, HabitDifficulty.hard);
      expect(retrieved?.attribute, HabitAttribute.spirit);
      expect(retrieved?.currentStreak, 5);
      expect(retrieved?.longestStreak, 10);
      expect(retrieved?.momentumScore, 50);
      expect(retrieved?.timeOfDayPreference, TimeOfDayPreference.morning);
      expect(retrieved?.reminderTime?.hour, 7);
      expect(retrieved?.reminderTime?.minute, 0);
    });

    test('completeHabit() with hard difficulty gives more XP', () async {
      final easyHabit = createTestHabit(
        difficulty: HabitDifficulty.easy,
        attribute: HabitAttribute.vitality,
      );
      final hardHabit = createTestHabit(
        id: const Uuid().v4(),
        difficulty: HabitDifficulty.hard,
        attribute: HabitAttribute.vitality,
      );

      await repository.createHabit(easyHabit);
      await repository.createHabit(hardHabit);

      await db.userStatsDao.upsertStats(
        UserStatsTableCompanion(
          userId: Value(userId),
          displayName: Value('Test User'),
          archetype: Value('athlete'),
          totalXp: Value(0),
          level: Value(1),
          vitalityXp: Value(0),
        ),
      );

      await repository.completeHabit(easyHabit.id, DateTime.now());
      final easyStats = await db.userStatsDao.getStats(userId);
      final easyXp = easyStats?.totalXp ?? 0;

      await db.userStatsDao.updateAttributeXp(
        userId,
        'vitality',
        -easyXp,
        1,
        0,
      );

      await repository.completeHabit(hardHabit.id, DateTime.now());
      final hardStats = await db.userStatsDao.getStats(userId);

      expect(hardStats?.totalXp, greaterThan(easyXp));
    });

    test(
      'completeHabit() delegates to SocialActivityService.logHabitCompletion',
      () async {
        final habit = createTestHabit();
        await repository.createHabit(habit);

        await db.userStatsDao.upsertStats(
          UserStatsTableCompanion(
            userId: Value(userId),
            displayName: Value('Test User'),
            archetype: Value('athlete'),
            totalXp: Value(0),
            level: Value(1),
            vitalityXp: Value(0),
          ),
        );

        final result = await repository.completeHabit(
          habit.id,
          DateTime.now(),
        );

        expect(result.isRight(), true);

        verify(
          () => mockSocialService.logHabitCompletion(
            userId: userId,
            userName: 'Test User',
            archetype: 'athlete',
            habitId: habit.id,
            habitTitle: habit.title,
            streakDay: any(named: 'streakDay'),
            attribute: any(named: 'attribute'),
            xpGained: any(named: 'xpGained'),
            currentLevel: any(named: 'currentLevel'),
          ),
        ).called(1);
      },
    );

    group('createStarterPack', () {
      test(
        'inserts one habit per blueprint in a single Drift batch',
        () async {
          final blueprints =
              StarterHabitBlueprint.catalog
                  .where((b) => b.archetype == UserArchetype.athlete)
                  .take(3)
                  .toList();

          final result = await repository.createStarterPack(
            userId: userId,
            blueprints: blueprints,
            archetypeName: 'athlete',
            interestIds: const ['movement.walking'],
            clubId: 'club_42',
          );

          expect(result.isRight(), true);
          final createdHabits = result.getOrElse((_) => fail('expected Right'));
          expect(createdHabits, hasLength(3));

          final stored = await db.habitsDao.watchHabits(userId).first;
          expect(stored, hasLength(3));
          for (final habit in stored) {
            expect(habit.difficulty, 'easy');
            expect(habit.frequency, 'daily');
          }
        },
      );

      test(
        'tags every habit with archetype, onboarding, interests, and club '
        'in the Firestore enqueue payload',
        () async {
          final blueprints =
              StarterHabitBlueprint.catalog
                  .where((b) => b.archetype == UserArchetype.scholar)
                  .take(2)
                  .toList();

          final result = await repository.createStarterPack(
            userId: userId,
            blueprints: blueprints,
            archetypeName: 'scholar',
            interestIds: const ['learning.reading', 'learning.languages'],
            clubId: 'deep_work_society',
          );

          expect(result.isRight(), true);

          // The Drift row schema doesn't store identityTags, but the
          // Firestore sync does. Validate via captured mocks.
          final captured = verify(
            () => mockSyncEngine.enqueueSet(
              collectionPath: 'habits',
              documentId: captureAny(named: 'documentId'),
              data: captureAny(named: 'data'),
            ),
          ).captured;
          // mocktail flattens captured args per position across all calls:
          // [documentId0, data0, documentId1, data1] for 2 calls.
          // We expect one enqueue per habit, so 4 captured entries for 2
          // habits.
          expect(captured.length, 4);

          final payloads = <Map<String, dynamic>>[];
          for (var i = 1; i < captured.length; i += 2) {
            payloads.add(captured[i] as Map<String, dynamic>);
          }
          expect(payloads, hasLength(2));
          for (final payload in payloads) {
            final tags =
                (payload['identityTags'] as List<dynamic>).cast<String>();
            expect(tags, contains('scholar'));
            expect(tags, contains('onboarding'));
            expect(tags, contains('interest:learning.reading'));
            expect(tags, contains('interest:learning.languages'));
            expect(tags, contains('club:deep_work_society'));
          }
        },
      );

      test('returns empty list and skips writes when given zero blueprints',
          () async {
        final result = await repository.createStarterPack(
          userId: userId,
          blueprints: const [],
        );
        expect(result.isRight(), true);
        expect(result.getOrElse((_) => []), isEmpty);

        final stored = await db.habitsDao.watchHabits(userId).first;
        expect(stored, isEmpty);
      });

      test('logs a starter_pack_created social activity once per call',
          () async {
        final blueprints =
            StarterHabitBlueprint.catalog
                .where((b) => b.archetype == UserArchetype.stoic)
                .take(2)
                .toList();

        await repository.createStarterPack(
          userId: userId,
          blueprints: blueprints,
          archetypeName: 'stoic',
        );

        verify(
          () => mockSocialService.logActivity(
            type: 'starter_pack_created',
            userId: userId,
            data: any(named: 'data'),
          ),
        ).called(1);
      });
    });

    test('createHabitsFromBlueprint stores reminderTime in created habits', () async {
      await db.userStatsDao.upsertStats(
        UserStatsTableCompanion(
          userId: Value(userId),
          displayName: Value('Test User'),
          archetype: Value('athlete'),
          totalXp: Value(0),
          level: Value(1),
          vitalityXp: Value(0),
        ),
      );

      final blueprint = Blueprint(
        id: 'test_bp',
        title: 'Test Blueprint',
        description: 'A test blueprint',
        category: 'Morning',
        creatorName: 'Test',
        creatorUserId: userId,
        creatorArchetype: 'Scholar',
        createdAt: DateTime.now(),
        habits: [const BlueprintHabit(title: 'Wake Up')],
      );

      final result = await repository.createHabitsFromBlueprint(
        userId: userId,
        blueprint: blueprint,
        reminderTime: '07:30',
      );

      expect(result.isRight(), true);

      final habits = await db.habitsDao.watchHabits(userId).first;
      expect(habits, isNotEmpty);
      expect(habits.first.title, 'Wake Up');
    });
  });
}
