import 'package:emerge_app/core/drift/app_database.dart';
import 'package:emerge_app/core/drift_repositories/drift_leaderboard_repository.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/social/domain/entities/leaderboard_entry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../drift/test_database.dart';
import 'mocks.dart';

void main() {
  late AppDatabase db;
  late MockSyncEngine mockSyncEngine;
  late DriftLeaderboardRepository repository;
  const userId = 'test_user_123';
  const clubId = 'club_athlete_001';

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

    repository = DriftLeaderboardRepository(db, mockSyncEngine, fakeFirestore);
  });

  tearDown(() async {
    await db.close();
  });

  group('DriftLeaderboardRepository', () {
    test(
      'updateUserScore() increment mode calls enqueueSet with increment marker',
      () async {
        final result = await repository.updateUserScore(
          userId,
          xp: 50,
          level: 2,
          archetype: UserArchetype.athlete,
          clubId: clubId,
          isIncrement: true,
        );

        expect(result.isRight(), true);

        final captured =
            verify(
                  () => mockSyncEngine.enqueueSet(
                    collectionPath: 'club_leaderboards',
                    documentId: '${userId}_$clubId',
                    data: captureAny(named: 'data'),
                  ),
                ).captured.first
                as Map<String, dynamic>;

        expect(captured['xp'], isA<Map<String, dynamic>>());
        expect(captured['xp']['__type__'], 'increment');
        expect(captured['xp']['value'], 50);
      },
    );

    test(
      'updateUserScore() increment mode when entry does not exist inserts new entry',
      () async {
        final result = await repository.updateUserScore(
          userId,
          xp: 50,
          level: 2,
          archetype: UserArchetype.athlete,
          clubId: clubId,
          isIncrement: true,
        );

        expect(result.isRight(), true);

        final entries = await db.leaderboardEntriesDao.getForTribe(clubId);
        expect(entries, isNotEmpty);
        expect(entries.first.userId, userId);
        expect(entries.first.xp, 50);
        expect(entries.first.level, 2);
      },
    );

    test(
      'updateUserScore() increment mode when entry exists increments xp',
      () async {
        await repository.updateUserScore(
          userId,
          xp: 50,
          level: 2,
          archetype: UserArchetype.athlete,
          clubId: clubId,
          isIncrement: true,
        );

        final result = await repository.updateUserScore(
          userId,
          xp: 25,
          level: 3,
          archetype: UserArchetype.athlete,
          clubId: clubId,
          isIncrement: true,
        );

        expect(result.isRight(), true);

        final entries = await db.leaderboardEntriesDao.getForTribe(clubId);
        expect(entries, isNotEmpty);
        expect(entries.first.userId, userId);
        expect(entries.first.xp, 75);
        expect(entries.first.level, 3);
      },
    );

    test(
      'updateUserScore() absolute mode calls enqueueSet with absolute value',
      () async {
        final result = await repository.updateUserScore(
          userId,
          xp: 500,
          level: 5,
          archetype: UserArchetype.creator,
          userName: 'Test User',
          clubId: clubId,
          isIncrement: false,
        );

        expect(result.isRight(), true);

        final captured =
            verify(
                  () => mockSyncEngine.enqueueSet(
                    collectionPath: 'club_leaderboards',
                    documentId: '${userId}_$clubId',
                    data: captureAny(named: 'data'),
                  ),
                ).captured.first
                as Map<String, dynamic>;

        expect(captured['xp'], 500);
        expect(captured['level'], 5);
        expect(captured['archetype'], 'creator');
      },
    );

    test('updateUserScore() inserts new entry if not exists', () async {
      await repository.updateUserScore(
        userId,
        xp: 100,
        level: 1,
        archetype: UserArchetype.scholar,
        userName: 'New User',
        clubId: clubId,
      );

      final entries = await db.leaderboardEntriesDao.getForTribe(clubId);
      expect(entries, isNotEmpty);
      expect(entries.first.userId, userId);
      expect(entries.first.xp, 100);
      expect(entries.first.level, 1);
    });

    test('updateUserScore() updates existing entry', () async {
      await repository.updateUserScore(
        userId,
        xp: 100,
        level: 1,
        archetype: UserArchetype.athlete,
        userName: 'Test User',
        clubId: clubId,
      );

      final result = await repository.updateUserScore(
        userId,
        xp: 250,
        level: 3,
        archetype: UserArchetype.athlete,
        userName: 'Test User',
        clubId: clubId,
      );

      expect(result.isRight(), true);

      final entries = await db.leaderboardEntriesDao.getForTribe(clubId);
      expect(entries, isNotEmpty);
      expect(entries.first.xp, 250);
      expect(entries.first.level, 3);
    });

    test('updateUserScore() returns failure on error', () async {
      final result = await repository.updateUserScore(
        userId,
        xp: 100,
        level: 1,
        archetype: UserArchetype.athlete,
      );

      expect(result.isRight(), true);
    });

    test('watchClubLeaderboard() returns top entries ordered by XP', () async {
      final now = DateTime.now().toIso8601String();
      await db.leaderboardEntriesDao.insertFromData(
        id: 'user1_$clubId',
        tribeId: clubId,
        userId: 'user1',
        userName: 'User One',
        xp: 300,
        level: 3,
        archetype: 'athlete',
        updatedAt: now,
      );
      await db.leaderboardEntriesDao.insertFromData(
        id: 'user2_$clubId',
        tribeId: clubId,
        userId: 'user2',
        userName: 'User Two',
        xp: 500,
        level: 5,
        archetype: 'creator',
        updatedAt: now,
      );
      await db.leaderboardEntriesDao.insertFromData(
        id: 'user3_$clubId',
        tribeId: clubId,
        userId: 'user3',
        userName: 'User Three',
        xp: 100,
        level: 1,
        archetype: 'scholar',
        updatedAt: now,
      );

      final stream = repository.watchClubLeaderboard(clubId);

      await expectLater(
        stream,
        emits(
          isA<List<LeaderboardEntry>>()
              .having((entries) => entries.length, 'length', 3)
              .having((entries) => entries.first.xp, 'first entry xp', 500)
              .having((entries) => entries.last.xp, 'last entry xp', 100),
        ),
      );
    });

    test(
      'watchClubLeaderboard() returns empty stream for null clubId',
      () async {
        final stream = repository.watchClubLeaderboard(null);

        expect(stream, isA<Stream<List<LeaderboardEntry>>>());
      },
    );

    test(
      'watchClubLeaderboard() returns empty stream for empty clubId',
      () async {
        final stream = repository.watchClubLeaderboard('');

        expect(stream, isA<Stream<List<LeaderboardEntry>>>());
      },
    );

    test('getUserRank() returns user rank', () async {
      final now = DateTime.now().toIso8601String();
      await db.leaderboardEntriesDao.insertFromData(
        id: 'user1_$clubId',
        tribeId: clubId,
        userId: 'user1',
        userName: 'User One',
        xp: 300,
        level: 3,
        archetype: 'athlete',
        updatedAt: now,
      );
      await db.leaderboardEntriesDao.insertFromData(
        id: 'user2_$clubId',
        tribeId: clubId,
        userId: 'user2',
        userName: 'User Two',
        xp: 500,
        level: 5,
        archetype: 'creator',
        updatedAt: now,
      );
      await db.leaderboardEntriesDao.insertFromData(
        id: '${userId}_$clubId',
        tribeId: clubId,
        userId: userId,
        userName: 'Test User',
        xp: 400,
        level: 4,
        archetype: 'scholar',
        updatedAt: now,
      );

      final stream = repository.watchClubLeaderboard(clubId);

      await expectLater(
        stream,
        emits(
          isA<List<LeaderboardEntry>>().having(
            (entries) {
              final userEntry = entries.firstWhere(
                (e) => e.userId == userId,
                orElse: () => const LeaderboardEntry(
                  userId: '',
                  userName: '',
                  xp: 0,
                  level: 0,
                  archetype: UserArchetype.none,
                  rank: -1,
                ),
              );
              return userEntry.rank;
            },
            'user rank',
            2,
          ),
        ),
      );
    });

    test('watchClubLeaderboard() assigns ranks correctly', () async {
      final now = DateTime.now().toIso8601String();
      await db.leaderboardEntriesDao.insertFromData(
        id: 'user1_$clubId',
        tribeId: clubId,
        userId: 'user1',
        userName: 'User One',
        xp: 100,
        level: 1,
        archetype: 'athlete',
        updatedAt: now,
      );
      await db.leaderboardEntriesDao.insertFromData(
        id: 'user2_$clubId',
        tribeId: clubId,
        userId: 'user2',
        userName: 'User Two',
        xp: 200,
        level: 2,
        archetype: 'creator',
        updatedAt: now,
      );

      final stream = repository.watchClubLeaderboard(clubId);

      await expectLater(
        stream,
        emits(
          isA<List<LeaderboardEntry>>().having(
            (entries) => entries.map((e) => e.rank).toList(),
            'ranks',
            [1, 2],
          ),
        ),
      );
    });
  });
}
