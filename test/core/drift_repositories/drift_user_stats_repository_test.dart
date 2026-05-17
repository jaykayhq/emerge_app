import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:emerge_app/core/drift/app_database.dart';
import 'package:emerge_app/core/drift_repositories/drift_user_stats_repository.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../drift/test_database.dart';
import 'mocks.dart';

void main() {
  late AppDatabase db;
  late MockSyncEngine mockSyncEngine;
  late DriftUserStatsRepository repository;
  const userId = 'test_user_123';

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

    repository = DriftUserStatsRepository(db, mockSyncEngine, fakeFirestore);
  });

  tearDown(() async {
    await db.close();
  });

  UserProfile createTestProfile({
    String uid = userId,
    String? displayName,
    UserArchetype archetype = UserArchetype.athlete,
    int level = 1,
    int streak = 0,
    int worldHealth = 100,
  }) {
    return UserProfile(
      uid: uid,
      displayName: displayName,
      archetype: archetype,
      avatarStats: UserAvatarStats(
        level: level,
        streak: streak,
        strengthXp: 100,
        intellectXp: 50,
        vitalityXp: 75,
        creativityXp: 25,
        focusXp: 30,
        spiritXp: 20,
        challengeXp: 10,
      ),
      worldState: UserWorldState(entropy: 1.0 - (worldHealth / 100.0)),
    );
  }

  group('DriftUserStatsRepository', () {
    test('saveUserStats() inserts into Drift and calls enqueueSet and enqueueUpdate', () async {
      final profile = createTestProfile(displayName: 'Test User');

      await repository.saveUserStats(profile);

      final retrieved = await db.userStatsDao.getStats(userId);
      expect(retrieved, isNotNull);
      expect(retrieved!.userId, userId);

      verify(
        () => mockSyncEngine.enqueueSet(
          collectionPath: 'user_stats',
          documentId: userId,
          data: any(named: 'data'),
        ),
      ).called(1);

      verify(
        () => mockSyncEngine.enqueueUpdate(
          collectionPath: 'users',
          documentId: userId,
          data: any(named: 'data'),
        ),
      ).called(1);
    });

    test('saveUserStats() includes all fields', () async {
      final profile = createTestProfile(
        displayName: 'Full Profile',
        archetype: UserArchetype.creator,
        level: 5,
        streak: 10,
        worldHealth: 80,
      );

      await repository.saveUserStats(profile);

      final retrieved = await db.userStatsDao.getStats(userId);
      expect(retrieved, isNotNull);
      expect(retrieved!.displayName, 'Full Profile');
      expect(retrieved.archetype, 'creator');
      expect(retrieved.level, 5);
      expect(retrieved.streak, 10);
      expect(retrieved.strengthXp, 100);
      expect(retrieved.intellectXp, 50);
      expect(retrieved.vitalityXp, 75);
      expect(retrieved.creativityXp, 25);
      expect(retrieved.focusXp, 30);
      expect(retrieved.spiritXp, 20);
      expect(retrieved.worldHealthScore, closeTo(0.8, 0.01));

      final captured = verify(
        () => mockSyncEngine.enqueueSet(
          collectionPath: 'user_stats',
          documentId: userId,
          data: captureAny(named: 'data'),
        ),
      ).captured.first as Map<String, dynamic>;

      expect(captured['uid'], userId);
      expect(captured['displayName'], 'Full Profile');
      expect(captured['archetype'], 'creator');
      expect(captured['avatarStats']['level'], 5);
      expect(captured['avatarStats']['streak'], 10);
    });

    test('updateWorldHealth() updates in Drift and calls enqueueUpdate', () async {
      await db.userStatsDao.upsertStats(
        UserStatsTableCompanion(
          userId: Value(userId),
          displayName: Value('Test User'),
          worldHealthScore: Value(1.0),
        ),
      );

      await repository.updateWorldHealth(userId, 60);

      final retrieved = await db.userStatsDao.getStats(userId);
      expect(retrieved, isNotNull);
      expect(retrieved!.worldHealthScore, closeTo(0.6, 0.01));

      final captured = verify(
        () => mockSyncEngine.enqueueUpdate(
          collectionPath: 'users',
          documentId: userId,
          data: captureAny(named: 'data'),
        ),
      ).captured.first as Map<String, dynamic>;

      expect(captured['worldState.entropy'], closeTo(0.4, 0.01));
    });

    test('updateAttributeXp() updates attribute XP via DAO', () async {
      await db.userStatsDao.upsertStats(
        UserStatsTableCompanion(
          userId: Value(userId),
          displayName: Value('Test User'),
          totalXp: Value(100),
          level: Value(2),
          strengthXp: Value(50),
          intellectXp: Value(30),
          vitalityXp: Value(20),
          creativityXp: Value(10),
          focusXp: Value(5),
          spiritXp: Value(5),
        ),
      );

      await db.userStatsDao.updateAttributeXp(userId, 'strength', 25, 3, 125);

      final retrieved = await db.userStatsDao.getStats(userId);
      expect(retrieved, isNotNull);
      expect(retrieved!.strengthXp, 75);
      expect(retrieved.totalXp, 125);
      expect(retrieved.level, 3);
    });

    test('getUserStats() returns stats for user', () async {
      await db.userStatsDao.upsertStats(
        UserStatsTableCompanion(
          userId: Value(userId),
          displayName: Value('Test User'),
          archetype: Value('scholar'),
          totalXp: Value(200),
          level: Value(3),
          streak: Value(7),
          strengthXp: Value(50),
          intellectXp: Value(80),
          vitalityXp: Value(40),
          creativityXp: Value(20),
          focusXp: Value(10),
          spiritXp: Value(10),
          worldHealthScore: Value(0.75),
        ),
      );

      final result = await repository.getUserStats(userId);

      expect(result.uid, userId);
      expect(result.displayName, 'Test User');
      expect(result.archetype, UserArchetype.scholar);
      expect(result.avatarStats.level, 3);
      expect(result.avatarStats.streak, 7);
    });

    test('getUserStats() returns empty profile for non-existent user', () async {
      final result = await repository.getUserStats('non_existent_user');

      expect(result.uid, 'non_existent_user');
      expect(result.displayName, isNull);
      expect(result.archetype, UserArchetype.none);
      expect(result.avatarStats.level, 1);
    });

    test('watchUserStats() returns stream of stats', () async {
      await db.userStatsDao.upsertStats(
        UserStatsTableCompanion(
          userId: Value(userId),
          displayName: Value('Stream User'),
          totalXp: Value(100),
          level: Value(2),
        ),
      );

      final stream = repository.watchUserStats(userId);

      await expectLater(
        stream,
        emits(
          isA<UserProfile>().having(
            (p) => p.displayName,
            'displayName',
            'Stream User',
          ),
        ),
      );
    });

    test('watchUserStats() emits empty profile for non-existent user', () async {
      final stream = repository.watchUserStats('non_existent');

      await expectLater(
        stream,
        emits(
          isA<UserProfile>().having(
            (p) => p.uid,
            'uid',
            'non_existent',
          ),
        ),
      );
    });
  });
}
