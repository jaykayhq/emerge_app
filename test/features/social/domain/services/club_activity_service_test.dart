import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/core/sync/sync_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/social/domain/services/club_activity_service.dart';
import 'package:emerge_app/core/drift/daos/tribe_activity_dao.dart';
import 'package:emerge_app/features/social/domain/repositories/leaderboard_repository.dart';
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
    registerFallbackValue(const TribeActivityTableCompanion());
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

    when(
      () => mockActivityDao.insertActivity(any()),
    ).thenAnswer((_) async => 1);
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
        ); // Global and Club (Leaderboard uses updateUserScore, not enqueueSet)

        verify(
          () => mockLeaderboardRepo.updateUserScore(
            any(),
            xp: any(named: 'xp'),
            level: any(named: 'level'),
            archetype: any(named: 'archetype'),
            userName: any(named: 'userName'),
            clubId: any(named: 'clubId'),
            isIncrement: any(named: 'isIncrement'),
          ),
        ).called(1);
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
        );

        verify(
          () => mockSyncEngine.enqueueSet(
            collectionPath: any(named: 'collectionPath'),
            documentId: any(named: 'documentId'),
            data: any(named: 'data'),
          ),
        ).called(2); // Global and Club
      });
    });
  });
}
