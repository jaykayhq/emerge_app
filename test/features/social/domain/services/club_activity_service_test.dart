import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/core/sync/sync_engine_barrel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/social/domain/services/club_activity_service.dart';
import 'package:emerge_app/features/social/domain/repositories/leaderboard_repository.dart';
import 'package:emerge_app/features/social/domain/entities/leaderboard_entry.dart';
import 'package:emerge_app/core/drift/database.dart';
import 'package:fpdart/fpdart.dart';

// ignore_for_file: subtype_of_sealed_class

// Mock classes
class MockFirestore extends Mock implements FirebaseFirestore {}

class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {
  @override
  String get id => 'mock_id';
}

class MockSyncEngine extends Mock implements EnhancedSyncEngine {}

class MockTribeActivityDao extends Mock implements TribeActivityDao {}

class MockLeaderboardRepository extends Mock implements LeaderboardRepository {}

/// Records every [LeaderboardRepository.updateUserScore] invocation so tests
/// can assert on the resolved club and the write shape (SP-G T7, B7/B8).
class RecordingLeaderboardRepository implements LeaderboardRepository {
  String? lastClubId;
  bool? lastIsIncrement;
  final List<
      ({
        String userId,
        int xp,
        int level,
        String? clubId,
        bool isIncrement,
      })> updateCalls = [];

  @override
  Future<Either<Failure, Unit>> updateUserScore(
    String userId, {
    required int xp,
    required int level,
    required UserArchetype archetype,
    String? userName,
    String? clubId,
    String? challengeId,
    bool isIncrement = false,
  }) async {
    lastClubId = clubId;
    lastIsIncrement = isIncrement;
    updateCalls.add((
      userId: userId,
      xp: xp,
      level: level,
      clubId: clubId,
      isIncrement: isIncrement,
    ));
    return const Right(unit);
  }

  @override
  Stream<List<LeaderboardEntry>> watchClubLeaderboard([String? clubId]) =>
      const Stream.empty();

  @override
  Stream<List<LeaderboardEntry>> watchChallengeLeaderboard([
    String? challengeId,
  ]) =>
      const Stream.empty();
}

class MockTransaction extends Mock implements Transaction {
  @override
  Transaction set<T>(
    DocumentReference<T> documentRef,
    T data, [
    SetOptions? options,
  ]) {
    return this;
  }

  @override
  Future<DocumentSnapshot<T>> get<T>(DocumentReference<T> docRef) async {
    return MockDocumentSnapshot<T>();
  }
}

class MockDocumentSnapshot<T> extends Mock implements DocumentSnapshot<T> {
  @override
  bool get exists => true;

  @override
  T? data() => {} as T?;
}

void main() {
  late SocialActivityService service;
  late MockFirestore mockFirestore;
  late MockSyncEngine mockSyncEngine;
  late MockTribeActivityDao mockActivityDao;
  late MockLeaderboardRepository mockLeaderboardRepo;

  setUpAll(() {
    registerFallbackValue(const Duration(seconds: 1));
    registerFallbackValue(TribeActivityTableCompanion());
    registerFallbackValue(UserArchetype.none);
  });

  setUp(() {
    mockFirestore = MockFirestore();
    mockSyncEngine = MockSyncEngine();
    mockActivityDao = MockTribeActivityDao();
    mockLeaderboardRepo = MockLeaderboardRepository();

    when(
      () => mockSyncEngine.enqueueSet(
        collectionPath: any(named: 'collectionPath'),
        documentId: any(named: 'documentId'),
        data: any(named: 'data'),
      ),
    ).thenAnswer((_) async {});

    when(() => mockActivityDao.insertActivity(any())).thenAnswer((_) async {});
    when(
      () => mockLeaderboardRepo.updateUserScore(
        any(),
        xp: any(named: 'xp'),
        level: any(named: 'level'),
        archetype: any(named: 'archetype'),
        userName: any(named: 'userName'),
        clubId: any(named: 'clubId'),
        isIncrement: any(named: 'isIncrement'),
      ),
    ).thenAnswer((_) async => const Right(unit));

    service = SocialActivityService(
      syncEngine: mockSyncEngine,
      activityDao: mockActivityDao,
      leaderboardRepo: mockLeaderboardRepo,
    );
  });

  group('SocialActivityService', () {
    final mockCollection = MockCollectionReference();
    final mockDoc = MockDocumentReference();

    setUp(() {
      when(() => mockFirestore.collection(any())).thenReturn(mockCollection);
      when(() => mockCollection.doc(any())).thenReturn(mockDoc);
      when(() => mockDoc.collection(any())).thenReturn(mockCollection);

      when(
        () => mockFirestore.runTransaction<Null>(
          any(),
          timeout: any(named: 'timeout'),
          maxAttempts: any(named: 'maxAttempts'),
        ),
      ).thenAnswer((invocation) async {
        final handler =
            invocation.positionalArguments[0]
                as Future<dynamic> Function(Transaction);
        await handler(MockTransaction());
      });
    });

    group('logHabitCompletion', () {
      test('completes without throwing when transaction succeeds', () async {
        await expectLater(
          service.logHabitCompletion(
            userId: 'user123',
            userName: 'Test User',
            archetype: 'athlete',
            habitId: 'habit456',
            habitTitle: 'Morning Workout',
            streakDay: 5,
            attribute: 'vitality',
            xpGained: 50,
            currentLevel: 5,
          ),
          completes,
        );
      });

      test('uses the provided clubId (active tribe) for the leaderboard', () async {
        final leaderboardRepo = RecordingLeaderboardRepository();
        final service = SocialActivityService(
          syncEngine: mockSyncEngine,
          activityDao: mockActivityDao,
          leaderboardRepo: leaderboardRepo,
        );

        await service.logHabitCompletion(
          userId: 'u1',
          userName: 'A',
          archetype: 'athlete',
          habitId: 'h1',
          habitTitle: 'H',
          streakDay: 1,
          attribute: 'vitality',
          xpGained: 10,
          currentLevel: 2,
          clubId: 'my_tribe',
        );

        expect(leaderboardRepo.lastClubId, 'my_tribe'); // NOT morning_warriors
        expect(leaderboardRepo.lastIsIncrement, true);
      });
    });

    group('logLevelUp', () {
      test('logs level up correctly', () async {
        await service.logLevelUp(
          userId: 'user123',
          userName: 'Test User',
          archetype: 'scholar',
          newLevel: 10,
          totalXp: 5000,
        );

        verify(
          () => mockSyncEngine.enqueueSet(
            collectionPath: any(named: 'collectionPath'),
            documentId: any(named: 'documentId'),
            data: any(named: 'data'),
          ),
        ).called(
          2,
        ); // Global and Club (Level-up no longer writes the leaderboard; B7)

        // Level is derivable from XP, so logLevelUp must NOT write the
        // leaderboard — that would double-count against the increment path.
        verifyNever(
          () => mockLeaderboardRepo.updateUserScore(
            any(),
            xp: any(named: 'xp'),
            level: any(named: 'level'),
            archetype: any(named: 'archetype'),
            userName: any(named: 'userName'),
            clubId: any(named: 'clubId'),
            isIncrement: any(named: 'isIncrement'),
          ),
        );
      });

      test('writes no leaderboard entry', () async {
        final leaderboardRepo = RecordingLeaderboardRepository();
        final service = SocialActivityService(
          syncEngine: mockSyncEngine,
          activityDao: mockActivityDao,
          leaderboardRepo: leaderboardRepo,
        );

        await service.logLevelUp(
          userId: 'u1',
          userName: 'A',
          archetype: 'athlete',
          newLevel: 3,
          totalXp: 250,
          clubId: 'my_tribe',
        );

        expect(leaderboardRepo.updateCalls, isEmpty);
      });
    });

    group('logChallengeComplete', () {
      test('logs challenge completion correctly', () async {
        await service.logChallengeComplete(
          userId: 'user123',
          userName: 'Test User',
          archetype: 'creator',
          challengeId: 'challenge789',
          challengeTitle: 'Design Sprint',
          xpReward: 100,
          level: 1,
        );

        verify(
          () => mockSyncEngine.enqueueSet(
            collectionPath: any(named: 'collectionPath'),
            documentId: any(named: 'documentId'),
            data: any(named: 'data'),
          ),
        ).called(2); // Global and Club
      });

      test('leaderboard write keeps the real level (no reset to 1)', () async {
        final leaderboardRepo = RecordingLeaderboardRepository();
        final service = SocialActivityService(
          syncEngine: mockSyncEngine,
          activityDao: mockActivityDao,
          leaderboardRepo: leaderboardRepo,
        );

        await service.logChallengeComplete(
          userId: 'u1',
          userName: 'A',
          archetype: 'creator',
          challengeId: 'ch1',
          challengeTitle: 'C',
          xpReward: 100,
          level: 5, // user is level 5 before this challenge completes
          clubId: 'my_tribe',
        );

        expect(leaderboardRepo.updateCalls, hasLength(1));
        expect(leaderboardRepo.updateCalls.first.level, 5);
        expect(leaderboardRepo.updateCalls.first.isIncrement, true);
        expect(leaderboardRepo.lastClubId, 'my_tribe');
      });
    });

    group('logActivity', () {
      test('enqueues set to global_activities', () async {
        await service.logActivity(
          type: 'test_event',
          userId: 'user1',
          data: {'key': 'value'},
        );

        verify(
          () => mockSyncEngine.enqueueSet(
            collectionPath: 'global_activities',
            documentId: any(named: 'documentId'),
            data: any(named: 'data'),
          ),
        ).called(1);
      });

      test('does not throw on success', () async {
        await expectLater(
          service.logActivity(
            type: 'test_event',
            userId: 'user1',
            data: {'key': 'value'},
          ),
          completes,
        );
      });
    });

    group('logStreakMilestone', () {
      test('enqueues set for global and club activity', () async {
        await service.logStreakMilestone(
          userId: 'u1',
          userName: 'Test',
          archetype: 'athlete',
          streakDays: 7,
        );

        verify(
          () => mockSyncEngine.enqueueSet(
            collectionPath: any(named: 'collectionPath'),
            documentId: any(named: 'documentId'),
            data: any(named: 'data'),
          ),
        ).called(2);
      });
    });

    group('logNodeClaim', () {
      test('enqueues set for global and club activity', () async {
        await service.logNodeClaim(
          userId: 'u1',
          userName: 'Test',
          archetype: 'stoic',
          nodeId: 'n1',
          nodeName: 'Focus Node',
        );

        verify(
          () => mockSyncEngine.enqueueSet(
            collectionPath: any(named: 'collectionPath'),
            documentId: any(named: 'documentId'),
            data: any(named: 'data'),
          ),
        ).called(2);
      });
    });

    group('logBadgeEarned', () {
      test('enqueues set for global and club activity', () async {
        await service.logBadgeEarned(
          userId: 'u1',
          userName: 'Test',
          archetype: 'creator',
          badgeId: 'b1',
          badgeName: 'Gold Star',
        );

        verify(
          () => mockSyncEngine.enqueueSet(
            collectionPath: any(named: 'collectionPath'),
            documentId: any(named: 'documentId'),
            data: any(named: 'data'),
          ),
        ).called(2);
      });
    });

    group('logPartnerJoined', () {
      test('enqueues set for global and club activity', () async {
        await service.logPartnerJoined(
          userId: 'u1',
          userName: 'Test',
          archetype: 'scholar',
          partnerName: 'Partner',
        );

        verify(
          () => mockSyncEngine.enqueueSet(
            collectionPath: any(named: 'collectionPath'),
            documentId: any(named: 'documentId'),
            data: any(named: 'data'),
          ),
        ).called(2);
      });
    });

    group('logContractCommitted', () {
      test('enqueues set for global and club activity', () async {
        await service.logContractCommitted(
          userId: 'u1',
          userName: 'Test',
          archetype: 'zealot',
          habitTitle: 'No Snooze',
          penalty: '\$50',
        );

        verify(
          () => mockSyncEngine.enqueueSet(
            collectionPath: any(named: 'collectionPath'),
            documentId: any(named: 'documentId'),
            data: any(named: 'data'),
          ),
        ).called(2);
      });
    });
  });
}
