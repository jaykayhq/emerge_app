import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:emerge_app/core/drift/app_database.dart';
import 'package:emerge_app/core/drift_repositories/drift_tribe_repository.dart';
import 'package:emerge_app/core/sync/sync_engine.dart';
import 'package:emerge_app/features/social/domain/models/tribe.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../drift/test_database.dart';
import 'mocks.dart' hide FakeFirebaseFirestore;

void main() {
  late AppDatabase db;
  late MockSyncEngine mockSyncEngine;
  late FakeFirebaseFirestore fakeFirestore;
  late DriftTribeRepository repository;
  const userId = 'test_user_123';
  const tribeId = 'tribe_athlete_001';

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    db = createTestDatabase();
    mockSyncEngine = MockSyncEngine();
    fakeFirestore = FakeFirebaseFirestore();

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
          () => mockSyncEngine.enqueueSet(
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
        () => mockSyncEngine.enqueueSet(
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

    test('getUserTribes() returns empty list when user has no tribes', () async {
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

      final tribes = await repository.getUserTribes(userId);

      expect(tribes, isEmpty);
    });

    test('getUserTribes() returns empty list on Firestore error', () async {
      final tribes = await repository.getUserTribes(userId);

      expect(tribes, isEmpty);
    });

    test('getArchetypeClubs() surfaces seed imageUrl (not empty) so cards '
        'match the Firestore/All-Tribes imagery', () async {
      await repository.seedTribesIfEmpty();

      final clubs = await repository.getArchetypeClubs();
      expect(clubs, isNotEmpty);

      // The seed catalog carries a per-club Unsplash image; Drift must
      // surface it instead of dropping it to '' (which caused the
      // onboarding vs All-Tribes image mismatch).
      final withImages = clubs.where((c) => c.imageUrl.isNotEmpty).toList();
      expect(withImages, isNotEmpty,
          reason: 'seeded clubs should expose an imageUrl');
    });
  });

  group('joinClub guard', () {
    // Uses the real sync engine (backed by the in-memory Drift queue) so
    // enqueued mutations are observable; the outer harness's MockSyncEngine
    // swallows them.
    late DriftTribeRepository guardRepository;

    setUp(() {
      guardRepository = DriftTribeRepository(
        db,
        EnhancedSyncEngine(db.mutationQueueDao, fakeFirestore),
        fakeFirestore,
      );
    });

    Future<void> seedStats({
      required String tribeId,
      required int memberCount,
    }) {
      return db.tribeStatsDao.upsertStats(
        TribeStatsTableCompanion(
          tribeId: Value(tribeId),
          tribeName: Value('Athletes'),
          archetypeId: Value('athlete'),
          memberCount: Value(memberCount),
          totalXp: Value(0),
          totalHabitsCompleted: Value(0),
          totalChallengesCompleted: Value(0),
          userContributionXp: Value(0),
          userHabitsCompleted: Value(0),
          userChallengesCompleted: Value(0),
          updatedAt: Value(DateTime.now().toIso8601String()),
        ),
      );
    }

    test('early-returns when a Firestore membership doc already exists',
        () async {
      await seedStats(tribeId: 'tribeA', memberCount: 0);

      await fakeFirestore
          .collection('users').doc('user1').collection('tribes').doc('tribeA')
          .set({'tribeId': 'tribeA', 'joinedAt': Timestamp.now()});

      await guardRepository.joinClub('user1', 'tribeA');

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

      await guardRepository.joinClub('user1', 'tribeA');

      final queue = await db.mutationQueueDao.getAllPending();
      expect(queue, isEmpty);
    });

    test('still joins when no membership exists anywhere', () async {
      await guardRepository.joinClub('user1', 'tribeA');
      final queue = await db.mutationQueueDao.getAllPending();
      expect(queue.length, 3); // user tribes + contributors + tribe doc
    });
  });
}
