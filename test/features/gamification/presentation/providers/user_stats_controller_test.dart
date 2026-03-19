import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/gamification/data/repositories/user_stats_repository.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/social/domain/services/club_activity_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// Mocks
class MockUserStatsRepository extends Mock implements UserStatsRepository {}

class MockSocialActivityService extends Mock implements SocialActivityService {}

void main() {
  late MockUserStatsRepository mockRepository;
  late MockSocialActivityService mockSocialActivityService;
  late UserStatsController controller;
  late UserProfile testUserProfile;

  setUpAll(() {
    // Register fallback values for mocktail
    registerFallbackValue(const UserProfile(uid: 'test-user'));
    registerFallbackValue(const UserWorldState());
    registerFallbackValue(const UserAvatarStats());
  });

  setUp(() {
    mockRepository = MockUserStatsRepository();
    mockSocialActivityService = MockSocialActivityService();

    // Setup default test user profile
    testUserProfile = UserProfile(
      uid: 'test-user',
      archetype: UserArchetype.athlete,
      identityVotes: {'Runner': 3},
      avatarStats: const UserAvatarStats(
        level: 2,
        strengthXp: 200,
        vitalityXp: 150,
        intellectXp: 100,
        creativityXp: 50,
      ),
      worldState: const UserWorldState(
        activeNodes: [],
        claimedNodes: [],
        highestCompletedNodeLevel: 0,
      ),
      onboardingProgress: 4,
    );

    // Mock repository to return test user profile
    when(() => mockRepository.getUserStats(any()))
        .thenAnswer((_) async => testUserProfile);
    when(() => mockRepository.saveUserStats(any()))
        .thenAnswer((_) async {});
    when(() => mockSocialActivityService.logLevelUp(
      userId: any(named: 'userId'),
      userName: any(named: 'userName'),
      archetype: any(named: 'archetype'),
      newLevel: any(named: 'newLevel'),
      totalXp: any(named: 'totalXp'),
    )).thenAnswer((_) async {});
    when(() => mockSocialActivityService.logNodeClaim(
      userId: any(named: 'userId'),
      userName: any(named: 'userName'),
      archetype: any(named: 'archetype'),
      nodeId: any(named: 'nodeId'),
      nodeName: any(named: 'nodeName'),
    )).thenAnswer((_) async {});

    controller = UserStatsController(
      repository: mockRepository,
      socialActivityService: mockSocialActivityService,
      userId: 'test-user',
      userName: 'TestUser',
    );
  });

  tearDown(() {
    controller.dispose();
  });

  group('UserStatsController - startMission', () {
    test('should add node to active nodes', () async {
      // Arrange
      final initialWorldState = const UserWorldState(
        activeNodes: [],
        claimedNodes: [],
        highestCompletedNodeLevel: 0,
      );
      final profileWithState = testUserProfile.copyWith(
        worldState: initialWorldState,
      );
      when(() => mockRepository.getUserStats(any()))
          .thenAnswer((_) async => profileWithState);

      // Act
      await controller.startMission('athlete_1_1');

      // Assert
      final captured = verify(() => mockRepository.saveUserStats(any()))
          .captured.last as UserProfile;
      expect(captured.worldState.activeNodes, contains('athlete_1_1'));
      expect(captured.worldState.activeNodes, hasLength(1));
    });

    test('should not start mission if node is already active', () async {
      // Arrange
      final initialWorldState = const UserWorldState(
        activeNodes: ['athlete_1_1'],
        claimedNodes: [],
        highestCompletedNodeLevel: 0,
      );
      final profileWithState = testUserProfile.copyWith(
        worldState: initialWorldState,
      );
      when(() => mockRepository.getUserStats(any()))
          .thenAnswer((_) async => profileWithState);

      // Act
      await controller.startMission('athlete_1_1');

      // Assert - should not call saveUserStats since node is already active
      verifyNever(() => mockRepository.saveUserStats(any()));
    });

    test('should not start mission if node is already claimed', () async {
      // Arrange
      final initialWorldState = const UserWorldState(
        activeNodes: [],
        claimedNodes: ['athlete_1_1'],
        highestCompletedNodeLevel: 1,
      );
      final profileWithState = testUserProfile.copyWith(
        worldState: initialWorldState,
      );
      when(() => mockRepository.getUserStats(any()))
          .thenAnswer((_) async => profileWithState);

      // Act
      await controller.startMission('athlete_1_1');

      // Assert - should not call saveUserStats since node is already claimed
      verifyNever(() => mockRepository.saveUserStats(any()));
    });

    test('should handle empty userId gracefully', () async {
      // Arrange
      final emptyController = UserStatsController(
        repository: mockRepository,
        socialActivityService: mockSocialActivityService,
        userId: '',
        userName: 'TestUser',
      );

      // Act - should not throw
      await emptyController.startMission('athlete_1_1');

      // Assert - no repository calls made
      verifyNever(() => mockRepository.getUserStats(any()));

      emptyController.dispose();
    });
  });

  group('UserStatsController - completeMission', () {
    test('should distribute XP and move node to claimed', () async {
      // Arrange
      final initialWorldState = const UserWorldState(
        activeNodes: ['athlete_1_1'],
        claimedNodes: [],
        highestCompletedNodeLevel: 0,
      );
      final profileWithState = testUserProfile.copyWith(
        worldState: initialWorldState,
        avatarStats: const UserAvatarStats(
          level: 2,
          strengthXp: 200,
          vitalityXp: 150,
          intellectXp: 100,
          creativityXp: 50,
        ),
      );
      when(() => mockRepository.getUserStats(any()))
          .thenAnswer((_) async => profileWithState);

      final xpBoosts = {'strength': 50, 'vitality': 30};

      // Act
      await controller.completeMission('athlete_1_1', xpBoosts, 1);

      // Assert
      final captured = verify(() => mockRepository.saveUserStats(any()))
          .captured.last as UserProfile;

      // Node should be moved from active to claimed
      expect(captured.worldState.activeNodes, isNot(contains('athlete_1_1')));
      expect(captured.worldState.claimedNodes, contains('athlete_1_1'));
      expect(captured.worldState.highestCompletedNodeLevel, greaterThanOrEqualTo(1));

      // Social activity should be logged
      verify(() => mockSocialActivityService.logNodeClaim(
        userId: 'test-user',
        userName: 'TestUser',
        archetype: any(named: 'archetype'),
        nodeId: 'athlete_1_1',
        nodeName: '1',
      )).called(1);
    });

    test('should not claim node if already claimed', () async {
      // Arrange
      final initialWorldState = const UserWorldState(
        activeNodes: [],
        claimedNodes: ['athlete_1_1'],
        highestCompletedNodeLevel: 1,
      );
      final profileWithState = testUserProfile.copyWith(
        worldState: initialWorldState,
      );
      when(() => mockRepository.getUserStats(any()))
          .thenAnswer((_) async => profileWithState);

      // Act
      await controller.completeMission('athlete_1_1', {'strength': 50}, 1);

      // Assert - should not call saveUserStats
      verifyNever(() => mockRepository.saveUserStats(any()));
    });

    test('should handle empty XP boosts by defaulting to strength', () async {
      // Arrange
      final initialWorldState = const UserWorldState(
        activeNodes: ['athlete_1_1'],
        claimedNodes: [],
        highestCompletedNodeLevel: 0,
      );
      final profileWithState = testUserProfile.copyWith(
        worldState: initialWorldState,
      );
      when(() => mockRepository.getUserStats(any()))
          .thenAnswer((_) async => profileWithState);

      // Act
      await controller.completeMission('athlete_1_1', {}, 1);

      // Assert
      verify(() => mockRepository.saveUserStats(any())).called(1);
    });

    test('should cap level based on node gate', () async {
      // Arrange
      final initialWorldState = const UserWorldState(
        activeNodes: ['athlete_1_1'],
        claimedNodes: [],
        highestCompletedNodeLevel: 0,
      );
      final highLevelProfile = testUserProfile.copyWith(
        worldState: initialWorldState,
        avatarStats: const UserAvatarStats(
          level: 10,
          strengthXp: 5000,
          vitalityXp: 0,
          intellectXp: 0,
          creativityXp: 0,
          focusXp: 0,
          spiritXp: 0,
        ),
      );
      when(() => mockRepository.getUserStats(any()))
          .thenAnswer((_) async => highLevelProfile);

      // Act
      await controller.completeMission('athlete_1_1', {'strength': 100}, 1);

      // Assert - level should be capped at highestCompletedNodeLevel + 1 = 2
      final captured = verify(() => mockRepository.saveUserStats(any()))
          .captured.last as UserProfile;
      expect(captured.avatarStats.level, lessThanOrEqualTo(2));
    });
  });

  group('UserStatsController - emerge', () {
    test('should set hasEmerged to true', () async {
      // Arrange
      final profileNotEmerged = testUserProfile.copyWith(hasEmerged: false);
      when(() => mockRepository.getUserStats(any()))
          .thenAnswer((_) async => profileNotEmerged);

      // Act
      await controller.emerge();

      // Assert
      final captured = verify(() => mockRepository.saveUserStats(any()))
          .captured.last as UserProfile;
      expect(captured.hasEmerged, isTrue);
    });

    test('should not update if already emerged', () async {
      // Arrange
      final profileEmerged = testUserProfile.copyWith(hasEmerged: true);
      when(() => mockRepository.getUserStats(any()))
          .thenAnswer((_) async => profileEmerged);

      // Act
      await controller.emerge();

      // Assert - should not call saveUserStats since already emerged
      verifyNever(() => mockRepository.saveUserStats(any()));
    });

    test('should handle empty userId gracefully', () async {
      // Arrange
      final emptyController = UserStatsController(
        repository: mockRepository,
        socialActivityService: mockSocialActivityService,
        userId: '',
        userName: 'TestUser',
      );

      // Act - should not throw
      await emptyController.emerge();

      // Assert - no repository calls made
      verifyNever(() => mockRepository.getUserStats(any()));

      emptyController.dispose();
    });
  });

  group('UserStatsController - updateWorldState', () {
    test('should update world state in repository', () async {
      // Arrange
      final newWorldState = const UserWorldState(
        activeNodes: ['test-node'],
        claimedNodes: [],
        highestCompletedNodeLevel: 1,
        unlockedBuildings: ['gym'],
      );

      // Act
      await controller.updateWorldState(newWorldState);

      // Assert
      final captured = verify(() => mockRepository.saveUserStats(any()))
          .captured.last as UserProfile;
      expect(captured.worldState.activeNodes, equals(['test-node']));
      expect(captured.worldState.highestCompletedNodeLevel, equals(1));
      expect(captured.worldState.unlockedBuildings, equals(['gym']));
    });

    test('should handle empty userId gracefully', () async {
      // Arrange
      final emptyController = UserStatsController(
        repository: mockRepository,
        socialActivityService: mockSocialActivityService,
        userId: '',
        userName: 'TestUser',
      );
      final newWorldState = const UserWorldState(
        activeNodes: ['test-node'],
        claimedNodes: [],
        highestCompletedNodeLevel: 1,
      );

      // Act - should not throw
      await emptyController.updateWorldState(newWorldState);

      // Assert - no repository calls made
      verifyNever(() => mockRepository.getUserStats(any()));

      emptyController.dispose();
    });
  });

  group('UserStatsController - unlockBuilding', () {
    test('should unlock building in world state', () async {
      // Arrange
      final initialWorldState = const UserWorldState(
        activeNodes: [],
        claimedNodes: [],
        highestCompletedNodeLevel: 1,
        unlockedBuildings: [],
      );
      final profileWithState = testUserProfile.copyWith(
        worldState: initialWorldState,
      );
      when(() => mockRepository.getUserStats(any()))
          .thenAnswer((_) async => profileWithState);

      // Act
      await controller.unlockBuilding('gym');

      // Assert
      final captured = verify(() => mockRepository.saveUserStats(any()))
          .captured.last as UserProfile;
      expect(captured.worldState.unlockedBuildings, contains('gym'));
    });

    test('should handle empty userId gracefully', () async {
      // Arrange
      final emptyController = UserStatsController(
        repository: mockRepository,
        socialActivityService: mockSocialActivityService,
        userId: '',
        userName: 'TestUser',
      );

      // Act - should not throw
      await emptyController.unlockBuilding('gym');

      // Assert - no repository calls made
      verifyNever(() => mockRepository.getUserStats(any()));

      emptyController.dispose();
    });
  });

  group('UserStatsController - lifecycle', () {
    test('should dispose subscription', () {
      // Arrange
      final testController = UserStatsController(
        repository: mockRepository,
        socialActivityService: mockSocialActivityService,
        userId: 'test-user',
        userName: 'TestUser',
      );

      // Act & Assert - should not throw
      expect(() => testController.dispose(), returnsNormally);
    });

    test('should handle repository errors gracefully', () async {
      // Arrange
      when(() => mockRepository.getUserStats(any()))
          .thenThrow(Exception('Database error'));

      // Act & Assert
      expect(
        () => controller.startMission('athlete_1_1'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
