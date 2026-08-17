import 'package:emerge_app/core/drift/database.dart';
import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/core/sync/sync_engine_barrel.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/social/domain/entities/leaderboard_entry.dart';
import 'package:emerge_app/features/social/domain/repositories/leaderboard_repository.dart';
import 'package:emerge_app/features/social/domain/services/club_activity_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockSyncEngine extends Mock implements EnhancedSyncEngine {}

class MockTribeActivityDao extends Mock implements TribeActivityDao {}

class RecordingLeaderboardRepository implements LeaderboardRepository {
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

void main() {
  late MockSyncEngine mockSyncEngine;
  late MockTribeActivityDao mockActivityDao;

  setUp(() {
    mockSyncEngine = MockSyncEngine();
    mockActivityDao = MockTribeActivityDao();

    when(
      () => mockSyncEngine.enqueueMutation(
        collectionPath: any(named: 'collectionPath'),
        documentId: any(named: 'documentId'),
        operation: any(named: 'operation'),
      ),
    ).thenAnswer((_) async {});
  });

  group('undoHabitCompletion', () {
    final creditRow = TribeActivityTableData(
      id: 'u1_h1_1710000000000',
      userId: 'u1',
      userName: 'A',
      tribeId: 'my_tribe',
      type: 'habit_complete',
      description: 'Completed habit: Read',
      value: 10,
      timestamp: '2024-03-09T12:00:00.000Z',
    );

    test('deletes the global + tribe activity docs the credit wrote', () async {
      when(
        () => mockActivityDao.getLatestHabitCompletion('u1', 'h1'),
      ).thenAnswer((_) async => creditRow);
      when(() => mockActivityDao.deleteActivity(any())).thenAnswer((_) async {});

      final service = SocialActivityService(
        syncEngine: mockSyncEngine,
        activityDao: mockActivityDao,
        leaderboardRepo: RecordingLeaderboardRepository(),
      );

      await service.undoHabitCompletion(
        userId: 'u1',
        userName: 'A',
        archetype: 'athlete',
        habitId: 'h1',
        xpToUndo: 10,
        level: 2,
        clubId: 'my_tribe',
      );

      verify(
        () => mockSyncEngine.enqueueMutation(
          collectionPath: 'global_activities',
          documentId: 'u1_h1_1710000000000',
          operation: 'delete',
        ),
      ).called(1);
      verify(
        () => mockSyncEngine.enqueueMutation(
          collectionPath: 'tribes/my_tribe/activity',
          documentId: 'u1_h1_1710000000000',
          operation: 'delete',
        ),
      ).called(1);
      verify(() => mockActivityDao.deleteActivity('u1_h1_1710000000000'))
          .called(1);
    });

    test('negates the leaderboard XP at the credit-time tribe', () async {
      when(
        () => mockActivityDao.getLatestHabitCompletion('u1', 'h1'),
      ).thenAnswer((_) async => creditRow);
      when(() => mockActivityDao.deleteActivity(any())).thenAnswer((_) async {});
      final leaderboardRepo = RecordingLeaderboardRepository();

      final service = SocialActivityService(
        syncEngine: mockSyncEngine,
        activityDao: mockActivityDao,
        leaderboardRepo: leaderboardRepo,
      );

      await service.undoHabitCompletion(
        userId: 'u1',
        userName: 'A',
        archetype: 'athlete',
        habitId: 'h1',
        xpToUndo: 40,
        level: 3,
        clubId: 'my_tribe',
      );

      expect(leaderboardRepo.updateCalls, hasLength(1));
      expect(leaderboardRepo.updateCalls.single.xp, -40);
      expect(leaderboardRepo.updateCalls.single.level, 3);
      expect(leaderboardRepo.updateCalls.single.clubId, 'my_tribe');
      expect(leaderboardRepo.updateCalls.single.isIncrement, true);
    });

    test('falls back to the archetype club and skips deletes without a '
        'local row', () async {
      when(
        () => mockActivityDao.getLatestHabitCompletion('u1', 'h1'),
      ).thenAnswer((_) async => null);
      final leaderboardRepo = RecordingLeaderboardRepository();

      final service = SocialActivityService(
        syncEngine: mockSyncEngine,
        activityDao: mockActivityDao,
        leaderboardRepo: leaderboardRepo,
      );

      await service.undoHabitCompletion(
        userId: 'u1',
        userName: 'A',
        archetype: 'athlete',
        habitId: 'h1',
        xpToUndo: 10,
        level: 2,
      );

      verifyNever(
        () => mockSyncEngine.enqueueMutation(
          collectionPath: any(named: 'collectionPath'),
          documentId: any(named: 'documentId'),
          operation: any(named: 'operation'),
        ),
      );
      expect(leaderboardRepo.updateCalls.single.clubId, 'morning_warriors');
      expect(leaderboardRepo.updateCalls.single.xp, -10);
    });

    test('does not write the leaderboard when there is nothing to undo', () async {
      when(
        () => mockActivityDao.getLatestHabitCompletion('u1', 'h1'),
      ).thenAnswer((_) async => null);
      final leaderboardRepo = RecordingLeaderboardRepository();

      final service = SocialActivityService(
        syncEngine: mockSyncEngine,
        activityDao: mockActivityDao,
        leaderboardRepo: leaderboardRepo,
      );

      await service.undoHabitCompletion(
        userId: 'u1',
        userName: 'A',
        archetype: 'athlete',
        habitId: 'h1',
        xpToUndo: 0,
        level: 1,
      );

      expect(leaderboardRepo.updateCalls, isEmpty);
    });
  });
}
