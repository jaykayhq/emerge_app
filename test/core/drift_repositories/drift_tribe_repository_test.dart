import 'dart:async';
import 'dart:convert';

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

        // Tribe doc memberCount/members are server-owned (Cloud Function
        // trigger). The client must never enqueue a tribe-doc write — it
        // dead-letters against the rules.
        verifyNever(
          () => mockSyncEngine.enqueueSet(
            collectionPath: 'tribes',
            documentId: tribeId,
            data: any(named: 'data'),
          ),
        );
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

      // Tribe doc updates are server-owned; the client only removes the
      // membership doc.
      verifyNever(
        () => mockSyncEngine.enqueueSet(
          collectionPath: 'tribes',
          documentId: tribeId,
          data: any(named: 'data'),
        ),
      );
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

    test(
      'getUserTribes() returns empty list when user has no tribes',
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

        final tribes = await repository.getUserTribes(userId);

        expect(tribes, isEmpty);
      },
    );

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
      expect(
        withImages,
        isNotEmpty,
        reason: 'seeded clubs should expose an imageUrl',
      );
    });

    test('watchArchetypeClubs() excludes local rows without an archetypeId '
        'so creator tribes never pollute the official-clubs UI', () async {
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
      // Creator tribe row — archetypeId omitted (null). Created locally by
      // join/completion credit once the DAO creates rows on demand.
      await db.tribeStatsDao.upsertStats(
        TribeStatsTableCompanion(
          tribeId: Value('creator_tribe_1'),
          tribeName: Value('Midnight Wolves'),
          memberCount: Value(1),
          totalXp: Value(20),
          totalHabitsCompleted: Value(1),
          totalChallengesCompleted: Value(0),
          userContributionXp: Value(20),
          userHabitsCompleted: Value(1),
          userChallengesCompleted: Value(0),
          updatedAt: Value(DateTime.now().toIso8601String()),
        ),
      );

      final stream = repository.watchArchetypeClubs().asBroadcastStream();
      final first = await stream.first;

      final ids = first.map((t) => t.id).toList();
      expect(ids, contains(tribeId));
      expect(ids, isNot(contains('creator_tribe_1')));
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

    test(
      'early-returns when a Firestore membership doc already exists',
      () async {
        await seedStats(tribeId: 'tribeA', memberCount: 0);

        await fakeFirestore
            .collection('users')
            .doc('user1')
            .collection('tribes')
            .doc('tribeA')
            .set({'tribeId': 'tribeA', 'joinedAt': Timestamp.now()});

        await guardRepository.joinClub('user1', 'tribeA');

        final stats = await db.tribeStatsDao.getStats('tribeA');
        expect(stats?.memberCount, 0); // no local increment
        final queue = await db.mutationQueueDao.getAllPending();
        expect(queue, isEmpty); // nothing enqueued
      },
    );

    test('early-returns when a Drift membership is active', () async {
      await db.tribeMembershipDao.upsertMembership(
        UserTribeTableCompanion(
          userId: const Value('user1'),
          tribeId: const Value('tribeA'),
          membershipType: const Value('archetype'),
          joinedAt: Value(DateTime.now().toIso8601String()),
          isActive: const Value(true),
        ),
      );

      await guardRepository.joinClub('user1', 'tribeA');

      final queue = await db.mutationQueueDao.getAllPending();
      expect(queue, isEmpty);
    });

    test('still joins when no membership exists anywhere', () async {
      await guardRepository.joinClub('user1', 'tribeA');
      final queue = await db.mutationQueueDao.getAllPending();
      // user tribes + contributors only — the tribe doc is server-owned and
      // must never be enqueued by the client.
      expect(queue.length, 2);
    });

    test(
      'joinClub contributor payload omits zero totals (preserves on rejoin)',
      () async {
        await guardRepository.joinClub('user1', 'tribeA');
        final queue = await db.mutationQueueDao.getAllPending();
        final contributorOp = queue.singleWhere(
          (m) => m.collectionPath == 'tribes/tribeA/contributors',
        );
        final data = Map<String, dynamic>.from(
          (contributorOp.dataJson != null
                  ? jsonDecode(contributorOp.dataJson!)
                  : {})
              as Map,
        );
        expect(data.containsKey('totalXpContributed'), false);
        expect(data.containsKey('contributionCount'), false);
      },
    );
  });

  group('_mergeTribeData D4 remote-preferred merge (via watchUserTribes)', () {
    // SP-G D4: tribe totals are recalc-only (server-authoritative D10) —
    // remote Firestore values must win over stale/inflated local Drift
    // totals, and local values must survive while remote is absent.
    Future<void> seedLocalStats({
      required String tribeId,
      required int totalXp,
      required int memberCount,
      required int habits,
      required int challenges,
    }) async {
      await db.tribeStatsDao.upsertStats(
        TribeStatsTableCompanion(
          tribeId: Value(tribeId),
          tribeName: const Value('Merge Tribe'),
          archetypeId: const Value('athlete'),
          memberCount: Value(memberCount),
          totalXp: Value(totalXp),
          totalHabitsCompleted: Value(habits),
          totalChallengesCompleted: Value(challenges),
          userContributionXp: const Value(0),
          userHabitsCompleted: const Value(0),
          userChallengesCompleted: const Value(0),
          updatedAt: Value(DateTime.now().toIso8601String()),
        ),
      );
      await db.tribeMembershipDao.upsertMembership(
        UserTribeTableCompanion(
          userId: const Value('mergeUser'),
          tribeId: Value(tribeId),
          membershipType: const Value('archetype'),
          joinedAt: Value(DateTime.now().toIso8601String()),
          isActive: const Value(true),
        ),
      );
    }

    /// Waits until the merged stream emits a tribe matching [predicate];
    /// times out (test failure) if that value never appears.
    Future<Tribe> firstMergedEmission(
      Stream<List<Tribe>> stream,
      bool Function(Tribe) predicate,
    ) async {
      final completer = Completer<Tribe>();
      late StreamSubscription<List<Tribe>> sub;
      sub = stream.listen(
        (tribes) {
          for (final tribe in tribes) {
            if (predicate(tribe)) {
              sub.cancel();
              if (!completer.isCompleted) completer.complete(tribe);
            }
          }
        },
        onError: (Object e, StackTrace st) {
          sub.cancel();
          if (!completer.isCompleted) completer.completeError(e, st);
        },
      );
      return completer.future.timeout(const Duration(seconds: 5));
    }

    test(
      'remote totalXp wins over inflated local (recalc-only totals)',
      () async {
        await seedLocalStats(
          tribeId: 'mergeTribe',
          totalXp: 5000,
          memberCount: 3,
          habits: 40,
          challenges: 4,
        );

        // Broadcast so both phases below can listen without re-subscribing
        // the single-subscription stream.
        final stream = repository
            .watchUserTribes('mergeUser')
            .asBroadcastStream();

        // Phase 1: local-only merge must be observed (remote not yet present),
        // so the remote doc below can never win by arriving first.
        final localSeen = Completer<void>();
        final localSub = stream.listen((tribes) {
          for (final t in tribes) {
            if (t.totalXp == 5000 && !localSeen.isCompleted) {
              localSeen.complete();
            }
          }
        });
        await localSeen.future.timeout(const Duration(seconds: 5));

        // Phase 2: after the remote doc lands, the merged tribe must carry the
        // remote (recalc'd, server-authoritative) totals.
        final remoteSeen = Completer<Tribe>();
        final remoteSub = stream.listen((tribes) {
          for (final t in tribes) {
            if (t.totalXp == 100 && !remoteSeen.isCompleted) {
              remoteSeen.complete(t);
            }
          }
        });

        await fakeFirestore.collection('tribes').doc('mergeTribe').set({
          'name': 'Merge Tribe',
          'type': 'official',
          'members': ['mergeUser'],
          'totalXp': 100,
          'memberCount': 1,
          'totalHabitsCompleted': 5,
          'totalChallengesCompleted': 1,
        });

        final tribe = await remoteSeen.future.timeout(
          const Duration(seconds: 5),
        );
        await localSub.cancel();
        await remoteSub.cancel();

        expect(tribe.totalXp, 100);
        expect(tribe.memberCount, 1);
        expect(tribe.totalHabitsCompleted, 5);
        expect(tribe.totalChallengesCompleted, 1);
      },
    );

    test('local totalXp survives when remote doc is absent', () async {
      await seedLocalStats(
        tribeId: 'mergeTribe',
        totalXp: 5000,
        memberCount: 3,
        habits: 40,
        challenges: 4,
      );

      final tribe = await firstMergedEmission(
        repository.watchUserTribes('mergeUser'),
        (t) => t.totalXp == 5000,
      );

      expect(tribe.totalXp, 5000);
      expect(tribe.memberCount, 3);
      expect(tribe.totalHabitsCompleted, 40);
      expect(tribe.totalChallengesCompleted, 4);
    });
  });
}
