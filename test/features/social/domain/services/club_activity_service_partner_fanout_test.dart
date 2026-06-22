import 'package:emerge_app/core/drift/database.dart';
import 'package:emerge_app/core/sync/sync_engine_barrel.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/social/domain/repositories/leaderboard_repository.dart';
import 'package:emerge_app/features/social/domain/services/club_activity_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

// ignore_for_file: subtype_of_sealed_class

class MockSyncEngine extends Mock implements EnhancedSyncEngine {}

class MockTribeActivityDao extends Mock implements TribeActivityDao {}

class MockLeaderboardRepository extends Mock implements LeaderboardRepository {}

void main() {
  late MockSyncEngine mockSyncEngine;
  late MockTribeActivityDao mockActivityDao;
  late MockLeaderboardRepository mockLeaderboardRepo;

  setUpAll(() {
    registerFallbackValue(TribeActivityTableCompanion());
    registerFallbackValue(UserArchetype.none);
  });

  setUp(() {
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
    when(() => mockActivityDao.insertActivity(any()))
        .thenAnswer((_) async {});
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
  });

  group('SocialActivityService partner fan-out', () {
    test(
        'logHabitCompletion fans out a partner_activity doc to each partner of the actor',
        () async {
      final partnerIds = <String>['p1', 'p2'];
      final service = SocialActivityService(
        syncEngine: mockSyncEngine,
        activityDao: mockActivityDao,
        leaderboardRepo: mockLeaderboardRepo,
        getPartnerIds: (userId) async {
          // Confirm the lookup was invoked with the actor's id.
          expect(userId, 'me');
          return partnerIds;
        },
      );

      await service.logHabitCompletion(
        userId: 'me',
        userName: 'Me',
        archetype: 'athlete',
        habitId: 'h1',
        habitTitle: 'Cold Plunge',
        streakDay: 1,
        attribute: 'body',
      );

      // Expect: 2 partner fan-out writes (one per partner).
      // Capture all calls so we can inspect both partner writes.
      final captured = verify(
        () => mockSyncEngine.enqueueSet(
          collectionPath: captureAny(named: 'collectionPath'),
          documentId: captureAny(named: 'documentId'),
          data: captureAny(named: 'data'),
        ),
      ).captured;

      // captured is a flat list of args across all matching calls, in
      // positional order: [collectionPath, documentId, data, ...] for
      // each call. Group into triples.
      final callCount = 3; // [collectionPath, documentId, data]
      final calls = <List<dynamic>>[];
      for (var i = 0; i + callCount <= captured.length; i += callCount) {
        calls.add(captured.sublist(i, i + callCount));
      }

      // Two partner fan-out writes — one for each partner.
      final partnerWrites = calls
          .where((call) =>
              (call[0] as String).startsWith('users/') &&
              (call[0] as String).endsWith('/partner_activity'))
          .toList();
      expect(partnerWrites.length, 2);

      // Each write carries denormalized actor info.
      for (final call in partnerWrites) {
        final data = call[2] as Map<String, dynamic>;
        expect(data['type'], 'habit_complete');
        expect(data['userId'], 'me');
        expect(data['userName'], 'Me');
        expect((data['data'] as Map)['habitTitle'], 'Cold Plunge');
        expect(data['timestamp'], isA<String>());
      }
    });

    test('users with no partners produce no partner fan-out writes', () async {
      final service = SocialActivityService(
        syncEngine: mockSyncEngine,
        activityDao: mockActivityDao,
        leaderboardRepo: mockLeaderboardRepo,
        getPartnerIds: (userId) async => <String>[],
      );

      await service.logHabitCompletion(
        userId: 'loner',
        userName: 'Loner',
        archetype: 'athlete',
        habitId: 'h1',
        habitTitle: 'Meditate',
        streakDay: 1,
        attribute: 'mind',
      );

      // No calls with /partner_activity should occur.
      verifyNever(
        () => mockSyncEngine.enqueueSet(
          collectionPath: any(
            that: endsWith('/partner_activity'),
            named: 'collectionPath',
          ),
          documentId: any(named: 'documentId'),
          data: any(named: 'data'),
        ),
      );
    });

    test('no partner lookup wired → no partner fan-out (no crash)', () async {
      final service = SocialActivityService(
        syncEngine: mockSyncEngine,
        activityDao: mockActivityDao,
        leaderboardRepo: mockLeaderboardRepo,
      );

      await expectLater(
        service.logHabitCompletion(
          userId: 'me',
          userName: 'Me',
          archetype: 'athlete',
          habitId: 'h1',
          habitTitle: 'Run',
          streakDay: 1,
          attribute: 'body',
        ),
        completes,
      );
    });

    test(
        'getPartnerIds is not invoked when the partner-lookup callback is null',
        () async {
      final service = SocialActivityService(
        syncEngine: mockSyncEngine,
        activityDao: mockActivityDao,
        leaderboardRepo: mockLeaderboardRepo,
      );

      await service.logStreakMilestone(
        userId: 'me',
        userName: 'Me',
        archetype: 'athlete',
        streakDays: 7,
      );
      // No assertion on getPartnerIds — it simply is never invoked.
      // Just confirms the service completes without throwing.
    });
  });
}
