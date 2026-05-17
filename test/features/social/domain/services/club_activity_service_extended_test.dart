import 'package:emerge_app/core/sync/sync_engine_barrel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/social/domain/services/club_activity_service.dart';
import 'package:emerge_app/features/social/domain/repositories/leaderboard_repository.dart';
import 'package:emerge_app/core/drift/database.dart';
import 'package:fpdart/fpdart.dart';

// ignore_for_file: subtype_of_sealed_class

// Mock classes
class MockSyncEngine extends Mock implements EnhancedSyncEngine {}

class MockTribeActivityDao extends Mock implements TribeActivityDao {}

class MockLeaderboardRepository extends Mock implements LeaderboardRepository {}

void main() {
  late SocialActivityService service;
  late MockSyncEngine mockSyncEngine;
  late MockTribeActivityDao mockActivityDao;
  late MockLeaderboardRepository mockLeaderboardRepo;

  setUpAll(() {
    registerFallbackValue(const Duration(seconds: 1));
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

    when(
      () => mockActivityDao.insertActivity(any()),
    ).thenAnswer((_) async {});
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

  group('SocialActivityService - Extended Activity Types', () {
    group('logStreakMilestone', () {
      test('enqueues to global_activities and tribes collection', () async {
        await service.logStreakMilestone(
          userId: 'user123',
          userName: 'Test User',
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

      test('uses correct archetype club mapping', () async {
        await service.logStreakMilestone(
          userId: 'user456',
          userName: 'Scholar User',
          archetype: 'scholar',
          streakDays: 30,
        );

        verify(
          () => mockSyncEngine.enqueueSet(
            collectionPath: 'global_activities',
            documentId: any(named: 'documentId'),
            data: any(named: 'data'),
          ),
        ).called(1);

        verify(
          () => mockSyncEngine.enqueueSet(
            collectionPath: 'tribes/deep_work_society/activity',
            documentId: any(named: 'documentId'),
            data: any(named: 'data'),
          ),
        ).called(1);
      });
    });

    group('logNodeClaim', () {
      test('enqueues to global_activities and tribes collection', () async {
        await service.logNodeClaim(
          userId: 'user123',
          userName: 'Test User',
          archetype: 'creator',
          nodeId: 'node_001',
          nodeName: 'Creative Hub',
        );

        verify(
          () => mockSyncEngine.enqueueSet(
            collectionPath: any(named: 'collectionPath'),
            documentId: any(named: 'documentId'),
            data: any(named: 'data'),
          ),
        ).called(2);
      });

      test('uses correct archetype club mapping', () async {
        await service.logNodeClaim(
          userId: 'user123',
          userName: 'Test User',
          archetype: 'creator',
          nodeId: 'node_001',
          nodeName: 'Creative Hub',
        );

        verify(
          () => mockSyncEngine.enqueueSet(
            collectionPath: 'global_activities',
            documentId: any(named: 'documentId'),
            data: any(named: 'data'),
          ),
        ).called(1);

        verify(
          () => mockSyncEngine.enqueueSet(
            collectionPath: 'tribes/creative_collective/activity',
            documentId: any(named: 'documentId'),
            data: any(named: 'data'),
          ),
        ).called(1);
      });
    });

    group('logBadgeEarned', () {
      test('enqueues to global_activities and tribes collection', () async {
        await service.logBadgeEarned(
          userId: 'user123',
          userName: 'Test User',
          archetype: 'stoic',
          badgeId: 'badge_001',
          badgeName: 'Iron Will',
        );

        verify(
          () => mockSyncEngine.enqueueSet(
            collectionPath: any(named: 'collectionPath'),
            documentId: any(named: 'documentId'),
            data: any(named: 'data'),
          ),
        ).called(2);
      });

      test('uses correct archetype club mapping', () async {
        await service.logBadgeEarned(
          userId: 'user123',
          userName: 'Test User',
          archetype: 'stoic',
          badgeId: 'badge_001',
          badgeName: 'Iron Will',
        );

        verify(
          () => mockSyncEngine.enqueueSet(
            collectionPath: 'global_activities',
            documentId: any(named: 'documentId'),
            data: any(named: 'data'),
          ),
        ).called(1);

        verify(
          () => mockSyncEngine.enqueueSet(
            collectionPath: 'tribes/mindful_masters/activity',
            documentId: any(named: 'documentId'),
            data: any(named: 'data'),
          ),
        ).called(1);
      });
    });

    group('logPartnerJoined', () {
      test('enqueues to global_activities and tribes collection', () async {
        await service.logPartnerJoined(
          userId: 'user123',
          userName: 'Test User',
          archetype: 'zealot',
          partnerName: 'Partner Name',
        );

        verify(
          () => mockSyncEngine.enqueueSet(
            collectionPath: any(named: 'collectionPath'),
            documentId: any(named: 'documentId'),
            data: any(named: 'data'),
          ),
        ).called(2);
      });

      test('uses correct archetype club mapping', () async {
        await service.logPartnerJoined(
          userId: 'user123',
          userName: 'Test User',
          archetype: 'zealot',
          partnerName: 'Partner Name',
        );

        verify(
          () => mockSyncEngine.enqueueSet(
            collectionPath: 'global_activities',
            documentId: any(named: 'documentId'),
            data: any(named: 'data'),
          ),
        ).called(1);

        verify(
          () => mockSyncEngine.enqueueSet(
            collectionPath: 'tribes/lunar_seekers/activity',
            documentId: any(named: 'documentId'),
            data: any(named: 'data'),
          ),
        ).called(1);
      });
    });

    group('logContractCommitted', () {
      test('enqueues to global_activities and tribes collection', () async {
        await service.logContractCommitted(
          userId: 'user123',
          userName: 'Test User',
          archetype: 'mystic',
          habitTitle: 'Morning Meditation',
          penalty: 'Donate 50 to charity',
        );

        verify(
          () => mockSyncEngine.enqueueSet(
            collectionPath: any(named: 'collectionPath'),
            documentId: any(named: 'documentId'),
            data: any(named: 'data'),
          ),
        ).called(2);
      });

      test('uses correct archetype club mapping', () async {
        await service.logContractCommitted(
          userId: 'user123',
          userName: 'Test User',
          archetype: 'mystic',
          habitTitle: 'Morning Meditation',
          penalty: 'Donate 50 to charity',
        );

        verify(
          () => mockSyncEngine.enqueueSet(
            collectionPath: 'global_activities',
            documentId: any(named: 'documentId'),
            data: any(named: 'data'),
          ),
        ).called(1);

        verify(
          () => mockSyncEngine.enqueueSet(
            collectionPath: 'tribes/lunar_seekers/activity',
            documentId: any(named: 'documentId'),
            data: any(named: 'data'),
          ),
        ).called(1);
      });
    });

    group('Error handling', () {
      test('logStreakMilestone does not throw on sync error', () async {
        when(
          () => mockSyncEngine.enqueueSet(
            collectionPath: any(named: 'collectionPath'),
            documentId: any(named: 'documentId'),
            data: any(named: 'data'),
          ),
        ).thenThrow(Exception('Network error'));

        await expectLater(
          service.logStreakMilestone(
            userId: 'user123',
            userName: 'Test User',
            archetype: 'athlete',
            streakDays: 7,
          ),
          completes,
        );
      });

      test('logNodeClaim does not throw on sync error', () async {
        when(
          () => mockSyncEngine.enqueueSet(
            collectionPath: any(named: 'collectionPath'),
            documentId: any(named: 'documentId'),
            data: any(named: 'data'),
          ),
        ).thenThrow(Exception('Network error'));

        await expectLater(
          service.logNodeClaim(
            userId: 'user123',
            userName: 'Test User',
            archetype: 'athlete',
            nodeId: 'node_001',
            nodeName: 'Test Node',
          ),
          completes,
        );
      });

      test('logBadgeEarned does not throw on sync error', () async {
        when(
          () => mockSyncEngine.enqueueSet(
            collectionPath: any(named: 'collectionPath'),
            documentId: any(named: 'documentId'),
            data: any(named: 'data'),
          ),
        ).thenThrow(Exception('Network error'));

        await expectLater(
          service.logBadgeEarned(
            userId: 'user123',
            userName: 'Test User',
            archetype: 'athlete',
            badgeId: 'badge_001',
            badgeName: 'Test Badge',
          ),
          completes,
        );
      });

      test('logPartnerJoined does not throw on sync error', () async {
        when(
          () => mockSyncEngine.enqueueSet(
            collectionPath: any(named: 'collectionPath'),
            documentId: any(named: 'documentId'),
            data: any(named: 'data'),
          ),
        ).thenThrow(Exception('Network error'));

        await expectLater(
          service.logPartnerJoined(
            userId: 'user123',
            userName: 'Test User',
            archetype: 'athlete',
            partnerName: 'Partner',
          ),
          completes,
        );
      });

      test('logContractCommitted does not throw on sync error', () async {
        when(
          () => mockSyncEngine.enqueueSet(
            collectionPath: any(named: 'collectionPath'),
            documentId: any(named: 'documentId'),
            data: any(named: 'data'),
          ),
        ).thenThrow(Exception('Network error'));

        await expectLater(
          service.logContractCommitted(
            userId: 'user123',
            userName: 'Test User',
            archetype: 'athlete',
            habitTitle: 'Test Habit',
            penalty: 'Test Penalty',
          ),
          completes,
        );
      });
    });
  });
}
