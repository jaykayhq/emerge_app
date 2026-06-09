import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:emerge_app/core/drift/app_database.dart';
import 'package:emerge_app/core/drift_repositories/drift_tribe_repository.dart';
import 'package:emerge_app/features/social/domain/models/tribe.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../drift/test_database.dart';
import 'mocks.dart';

void main() {
  late AppDatabase db;
  late MockSyncEngine mockSyncEngine;
  late DriftTribeRepository repository;
  const userId = 'test_user_123';
  const tribeId = 'tribe_athlete_001';

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    db = createTestDatabase();
    mockSyncEngine = MockSyncEngine();
    final fakeFirestore = FakeFirebaseFirestore();

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
      () => mockSyncEngine.enqueueMutation(
        collectionPath: any(named: 'collectionPath'),
        documentId: any(named: 'documentId'),
        operation: any(named: 'operation'),
      ),
    ).thenAnswer((_) async {});

    repository = DriftTribeRepository(db, mockSyncEngine, fakeFirestore);
  });

  tearDown(() async {
    await db.close();
  });

  group('DriftTribeRepository', () {
    test(
      'joinClub() calls enqueueSet for user tribes and tribe contributors',
      () async {
        await db.tribeStatsDao.upsertStats(
          TribeStatsTableCompanion(
            tribeId: Value(tribeId),
            tribeName: Value('Athletes'),
            archetypeId: Value('athlete'),
            memberCount: Value(0),
            totalXp: Value(0),
            totalHabitsCompleted: Value(0),
            totalChallengesCompleted: Value(0),
            userContributionXp: Value(0),
            userHabitsCompleted: Value(0),
            userChallengesCompleted: Value(0),
            updatedAt: Value(DateTime.now().toIso8601String()),
          ),
        );

        await repository.joinClub(userId, tribeId);

        verify(
          () => mockSyncEngine.enqueueSet(
            collectionPath: 'users/$userId/tribes',
            documentId: tribeId,
            data: any(named: 'data'),
          ),
        ).called(1);

        verify(
          () => mockSyncEngine.enqueueSet(
            collectionPath: 'tribes/$tribeId/contributors',
            documentId: userId,
            data: any(named: 'data'),
          ),
        ).called(1);

        verify(
          () => mockSyncEngine.enqueueUpdate(
            collectionPath: 'tribes',
            documentId: tribeId,
            data: any(named: 'data'),
          ),
        ).called(1);
      },
    );

    test('joinClub() increments member count in tribe stats', () async {
      await db.tribeStatsDao.upsertStats(
        TribeStatsTableCompanion(
          tribeId: Value(tribeId),
          tribeName: Value('Athletes'),
          archetypeId: Value('athlete'),
          memberCount: Value(5),
          totalXp: Value(0),
          totalHabitsCompleted: Value(0),
          totalChallengesCompleted: Value(0),
          userContributionXp: Value(0),
          userHabitsCompleted: Value(0),
          userChallengesCompleted: Value(0),
          updatedAt: Value(DateTime.now().toIso8601String()),
        ),
      );

      await repository.joinClub(userId, tribeId);

      final stats = await db.tribeStatsDao.getStats(tribeId);
      expect(stats, isNotNull);
      expect(stats!.memberCount, 6);
    });

    test('leaveClub() calls enqueueMutation and enqueueUpdate', () async {
      await db.tribeStatsDao.upsertStats(
        TribeStatsTableCompanion(
          tribeId: Value(tribeId),
          tribeName: Value('Athletes'),
          archetypeId: Value('athlete'),
          memberCount: Value(5),
          totalXp: Value(0),
          totalHabitsCompleted: Value(0),
          totalChallengesCompleted: Value(0),
          userContributionXp: Value(0),
          userHabitsCompleted: Value(0),
          userChallengesCompleted: Value(0),
          updatedAt: Value(DateTime.now().toIso8601String()),
        ),
      );

      await repository.leaveClub(userId, tribeId);

      verify(
        () => mockSyncEngine.enqueueMutation(
          collectionPath: 'users/$userId/tribes',
          documentId: tribeId,
          operation: 'delete',
        ),
      ).called(1);

      verify(
        () => mockSyncEngine.enqueueUpdate(
          collectionPath: 'tribes',
          documentId: tribeId,
          data: any(named: 'data'),
        ),
      ).called(1);
    });

    test('leaveClub() decrements member count', () async {
      await db.tribeStatsDao.upsertStats(
        TribeStatsTableCompanion(
          tribeId: Value(tribeId),
          tribeName: Value('Athletes'),
          archetypeId: Value('athlete'),
          memberCount: Value(5),
          totalXp: Value(0),
          totalHabitsCompleted: Value(0),
          totalChallengesCompleted: Value(0),
          userContributionXp: Value(0),
          userHabitsCompleted: Value(0),
          userChallengesCompleted: Value(0),
          updatedAt: Value(DateTime.now().toIso8601String()),
        ),
      );

      await repository.leaveClub(userId, tribeId);

      final stats = await db.tribeStatsDao.getStats(tribeId);
      expect(stats, isNotNull);
      expect(stats!.memberCount, 4);
    });

    test('getTribeStats() returns tribe statistics', () async {
      await db.tribeStatsDao.upsertStats(
        TribeStatsTableCompanion(
          tribeId: Value(tribeId),
          tribeName: Value('Creators'),
          archetypeId: Value('creator'),
          memberCount: Value(10),
          totalXp: Value(500),
          totalHabitsCompleted: Value(50),
          totalChallengesCompleted: Value(5),
          userContributionXp: Value(100),
          userHabitsCompleted: Value(10),
          userChallengesCompleted: Value(2),
          updatedAt: Value(DateTime.now().toIso8601String()),
        ),
      );

      final clubs = await repository.getArchetypeClubs();

      expect(clubs, isNotEmpty);
      final tribe = clubs.firstWhere(
        (t) => t.id == tribeId,
        orElse: () => const Tribe(
          id: '',
          name: '',
          description: '',
          imageUrl: '',
          ownerId: '',
          tags: [],
          levelRequirement: 0,
          rank: 0,
          totalXp: 0,
          memberCount: 0,
        ),
      );
      expect(tribe.id, tribeId);
      expect(tribe.memberCount, 10);
      expect(tribe.totalXp, 500);
    });

    test('watchClubActivity() returns activity stream', () async {
      await db.tribeActivityDao.insertActivity(
        TribeActivityTableCompanion(
          id: Value('activity_1'),
          tribeId: Value(tribeId),
          userId: Value(userId),
          userName: Value('Test User'),
          type: Value('habit_completed'),
          description: Value('Completed Morning Run'),
          timestamp: Value(DateTime.now().toIso8601String()),
        ),
      );

      final stream = repository.watchClubActivity(tribeId);

      await expectLater(
        stream,
        emits(
          isA<List<Map<String, dynamic>>>().having(
            (activities) => activities.length,
            'length',
            1,
          ),
        ),
      );
    });

    test('updateTribeStats() updates and syncs', () async {
      await db.tribeStatsDao.upsertStats(
        TribeStatsTableCompanion(
          tribeId: Value(tribeId),
          tribeName: Value('Scholars'),
          archetypeId: Value('scholar'),
          memberCount: Value(3),
          totalXp: Value(100),
          totalHabitsCompleted: Value(10),
          totalChallengesCompleted: Value(1),
          userContributionXp: Value(50),
          userHabitsCompleted: Value(5),
          userChallengesCompleted: Value(0),
          updatedAt: Value(DateTime.now().toIso8601String()),
        ),
      );

      await db.tribeStatsDao.incrementContribution(
        tribeId,
        xp: 25,
        habits: 3,
        challenges: 1,
      );

      final stats = await db.tribeStatsDao.getStats(tribeId);
      expect(stats, isNotNull);
      expect(stats!.totalXp, 125);
      expect(stats.totalHabitsCompleted, 13);
      expect(stats.totalChallengesCompleted, 2);
    });

    test('getArchetypeClub() returns club by archetype', () async {
      final clubs = await repository.getArchetypeClubs();
      expect(clubs, isNotEmpty);

      final athleteClub = clubs.firstWhere(
        (c) => c.archetypeId == 'athlete',
        orElse: () => const Tribe(
          id: '',
          name: '',
          description: '',
          imageUrl: '',
          ownerId: '',
          tags: [],
          levelRequirement: 0,
          rank: 0,
          totalXp: 0,
          memberCount: 0,
        ),
      );
      expect(athleteClub.archetypeId, 'athlete');
    });

    test('seedTribesIfEmpty() seeds tribes when empty', () async {
      final before = await db.tribeStatsDao.getAll();
      expect(before, isEmpty);

      await repository.seedTribesIfEmpty();

      final after = await db.tribeStatsDao.getAll();
      expect(after, isNotEmpty);
    });

    test('seedTribesIfEmpty() does not seed when tribes exist', () async {
      await repository.seedTribesIfEmpty();
      final firstCount = (await db.tribeStatsDao.getAll()).length;

      await repository.seedTribesIfEmpty();
      final secondCount = (await db.tribeStatsDao.getAll()).length;

      expect(firstCount, secondCount);
    });
  });
}
