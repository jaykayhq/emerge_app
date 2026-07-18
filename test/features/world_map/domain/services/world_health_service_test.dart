import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:emerge_app/features/world_map/domain/services/world_health_service.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/core/drift_repositories/repositories_barrel.dart';
import 'package:emerge_app/features/habits/domain/entities/habit_completion_entity.dart';
import 'package:emerge_app/features/habits/domain/repositories/habit_repository.dart';
import 'package:emerge_app/core/error/failure.dart';

class MockDriftRepo extends Mock implements DriftUserStatsRepository {}

class MockHabitRepo extends Mock implements HabitRepository {}

void main() {
  late MockDriftRepo mockRepo;
  late MockHabitRepo mockHabitRepo;
  late WorldHealthService service;

  setUp(() {
    mockRepo = MockDriftRepo();
    mockHabitRepo = MockHabitRepo();
    service = WorldHealthService(mockRepo, mockHabitRepo);

    when(() => mockHabitRepo.getCompletionsBetweenDates(any(), any(), any()))
        .thenAnswer((_) async => const Right([]));
    when(() => mockRepo.getUserStats(any()))
        .thenAnswer((_) async => UserProfile(uid: 'test'));
  });

  group('calculateWorldHealth', () {
    test('returns low health with no activity', () async {
      final profile = UserProfile(
        uid: 'test',
        worldState: const UserWorldState(lastActiveDate: null),
      );

      final health = await service.calculateWorldHealth(profile);

      expect(health, lessThan(0.3));
    });

    test('returns higher health with daily activity', () async {
      final now = DateTime.now();
      final activity = List.generate(
        7,
        (i) => HabitCompletionEntity(
          id: 'c$i',
          habitId: 'h',
          attribute: 'vitality',
          xpGained: 10,
          completedAt: now.subtract(Duration(days: i)),
        ),
      );

      when(() => mockHabitRepo.getCompletionsBetweenDates(any(), any(), any()))
          .thenAnswer((_) async => Right(activity));

      final profile = UserProfile(
        uid: 'test',
        worldState: UserWorldState(lastActiveDate: now),
      );

      final health = await service.calculateWorldHealth(profile);

      expect(health, greaterThanOrEqualTo(0.5));
    });

    test('applies no decay penalty when active today', () async {
      final now = DateTime.now();
      final profile = UserProfile(
        uid: 'test',
        worldState: UserWorldState(lastActiveDate: now),
      );

      final health = await service.calculateWorldHealth(profile);

      expect(health, greaterThan(0.0));
    });

    test('applies medium decay for 5 days inactive', () async {
      final now = DateTime.now();
      final fiveDaysAgo = now.subtract(const Duration(days: 5));
      final activeProfile = UserProfile(
        uid: 'test',
        worldState: UserWorldState(lastActiveDate: now),
      );
      final inactiveProfile = UserProfile(
        uid: 'test',
        worldState: UserWorldState(lastActiveDate: fiveDaysAgo),
      );

      final activeHealth = await service.calculateWorldHealth(activeProfile);
      final inactiveHealth = await service.calculateWorldHealth(inactiveProfile);

      expect(inactiveHealth, lessThan(activeHealth));
    });

    test('applies max streak bonus for 50+ day streak', () async {
      final now = DateTime.now();
      final profile = UserProfile(
        uid: 'test',
        worldState: UserWorldState(lastActiveDate: now),
        avatarStats: const UserAvatarStats(streak: 50),
      );

      final health = await service.calculateWorldHealth(profile);

      expect(health, greaterThan(0.2));
    });

    test('falls back to profile worldHealth on repository error', () async {
      when(() => mockHabitRepo.getCompletionsBetweenDates(any(), any(), any()))
          .thenAnswer((_) async => const Left(
            ServerFailure('Network error'),
          ));

      final profile = UserProfile(
        uid: 'test',
        worldState: const UserWorldState(entropy: 0.3),
      );

      final health = await service.calculateWorldHealth(profile);

      expect(health, closeTo(0.7, 0.01));
    });
  });

  group('getWorldHealth caching', () {
    test('returns cached value when fresh', () async {
      await service.getWorldHealth('user1');
      await service.getWorldHealth('user1');

      verify(() => mockRepo.getUserStats('user1')).called(1);
    });

    test('clearCache invalidates specific user cache', () async {
      await service.getWorldHealth('user1');
      service.clearCache('user1');
      await service.getWorldHealth('user1');

      verify(() => mockRepo.getUserStats('user1')).called(2);
    });

    test('clearCache without args clears all', () async {
      await service.getWorldHealth('user1');
      service.clearCache();
      await service.getWorldHealth('user1');

      verify(() => mockRepo.getUserStats('user1')).called(2);
    });
  });
}
