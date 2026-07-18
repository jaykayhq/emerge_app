import 'package:emerge_app/core/drift_repositories/drift_user_stats_repository.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/gamification/data/repositories/user_stats_repository.dart';
import 'package:emerge_app/features/gamification/domain/services/weekly_recap_service.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/domain/entities/habit_completion_entity.dart';
import 'package:emerge_app/features/habits/domain/repositories/habit_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:emerge_app/features/monetization/presentation/providers/subscription_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

class MockDriftUserStatsRepository extends Mock
    implements DriftUserStatsRepository {}

class MockHabitRepository extends Mock implements HabitRepository {}

/// Test notifier that returns a fixed premium value.
class TestIsPremium extends IsPremium {
  final bool premium;
  TestIsPremium(this.premium);

  @override
  Future<bool> build() async => premium;
}

UserProfile _profile({
  int level = 1,
  double entropy = 0.5,
}) {
  return UserProfile(
    uid: 'test-user-1',
    avatarStats: UserAvatarStats(level: level),
    worldState: UserWorldState(entropy: entropy),
  );
}

HabitCompletionEntity _activity({
  required String habitId,
  int xpEarned = 10,
  String attribute = 'strength',
  required DateTime date,
}) {
  return HabitCompletionEntity(
    id: '$habitId-${date.millisecondsSinceEpoch}',
    habitId: habitId,
    attribute: attribute,
    xpGained: xpEarned,
    completedAt: date,
  );
}

Habit _habit({
  required String id,
  required String title,
}) {
  return Habit(
    id: id,
    userId: 'test-user-1',
    title: title,
    cue: 'cue',
    routine: 'routine',
    reward: 'reward',
    frequency: HabitFrequency.daily,
    difficulty: HabitDifficulty.medium,
    createdAt: DateTime(2025, 1, 1),
  );
}

/// Shortcut to create a ProviderContainer for a given premium state.
ProviderContainer _makeContainer({
  required MockDriftUserStatsRepository driftRepo,
  required MockHabitRepository habitRepo,
  required bool premium,
}) {
  return ProviderContainer(overrides: [
    userStatsRepositoryProvider.overrideWithValue(driftRepo),
    habitRepositoryProvider.overrideWithValue(habitRepo),
    isPremiumProvider.overrideWith(() => TestIsPremium(premium)),
  ]);
}

void main() {
  late ProviderContainer container;
  late MockDriftUserStatsRepository mockDriftRepo;
  late MockHabitRepository mockHabitRepo;

  const testUserId = 'test-user-1';

  setUp(() {
    mockDriftRepo = MockDriftUserStatsRepository();
    mockHabitRepo = MockHabitRepository();

    when(() => mockDriftRepo.getLatestRecap(any()))
        .thenAnswer((_) async => null);

    container = _makeContainer(
      driftRepo: mockDriftRepo,
      habitRepo: mockHabitRepo,
      premium: false,
    );
  });

  tearDown(() {
    container.dispose();
  });

  WeeklyRecapService service() => container.read(weeklyRecapServiceProvider);

  group('generateRecap', () {
    test('returns specific recap when recapId is provided', () async {
      final recapData = <String, dynamic>{
        'id': 'recap-1',
        'userId': testUserId,
        'startDate': '2025-06-09T00:00:00.000',
        'endDate': '2025-06-15T00:00:00.000',
        'totalHabitsCompleted': 5,
        'perfectDays': 3,
        'totalXpEarned': 100,
        'topHabitName': 'Test Habit',
        'currentLevel': 2,
        'worldGrowthPercentage': 0.8,
        'isComplete': true,
      };

      when(() => mockDriftRepo.getRecap(testUserId, 'recap-1'))
          .thenAnswer((_) async => recapData);

      final result = await service().generateRecap(
        userId: testUserId,
        recapId: 'recap-1',
      );

      expect(result, isNotNull);
      expect(result!.id, 'recap-1');
      expect(result.totalHabitsCompleted, 5);
      expect(result.totalXpEarned, 100);
    });

    test('returns existing recap when dates match and recap is complete',
        () async {
      final start = DateTime(2025, 6, 9);
      final end = DateTime(2025, 6, 15);

      final existingData = <String, dynamic>{
        'id': 'existing-recap',
        'userId': testUserId,
        'startDate': start.toIso8601String(),
        'endDate': end.toIso8601String(),
        'totalHabitsCompleted': 10,
        'perfectDays': 7,
        'totalXpEarned': 200,
        'topHabitName': 'Existing Habit',
        'currentLevel': 3,
        'worldGrowthPercentage': 0.9,
        'isComplete': true,
      };

      when(() => mockDriftRepo.getLatestRecap(testUserId))
          .thenAnswer((_) async => existingData);

      final result = await service().generateRecap(
        userId: testUserId,
        startDate: start,
        endDate: end,
      );

      expect(result, isNotNull);
      expect(result!.id, 'existing-recap');
      expect(result.topHabitName, 'Existing Habit');
      verify(() => mockDriftRepo.getLatestRecap(testUserId)).called(1);
      verifyNever(
        () => mockHabitRepo.getCompletionsBetweenDates(any(), any(), any()),
      );
    });

    test('replaces existing recap when dates differ', () async {
      final start = DateTime(2025, 6, 9);
      final end = DateTime(2025, 6, 15);

      final existingData = <String, dynamic>{
        'id': 'existing-recap',
        'userId': testUserId,
        'startDate': '2025-06-02T00:00:00.000',
        'endDate': '2025-06-08T00:00:00.000',
        'totalHabitsCompleted': 10,
        'perfectDays': 7,
        'totalXpEarned': 200,
        'topHabitName': 'Existing Habit',
        'currentLevel': 3,
        'worldGrowthPercentage': 0.9,
        'isComplete': true,
      };

      when(() => mockDriftRepo.getLatestRecap(testUserId))
          .thenAnswer((_) async => existingData);
      when(() => mockHabitRepo.getCompletionsBetweenDates(any(), any(), any()))
          .thenAnswer((_) async => const Right([]));
      when(() => mockDriftRepo.getUserStats(any()))
          .thenAnswer((_) async => _profile());
      when(() => mockDriftRepo.saveRecap(any(), any()))
          .thenAnswer((_) async => {});

      final result = await service().generateRecap(
        userId: testUserId,
        startDate: start,
        endDate: end,
      );

      expect(result, isNotNull);
      expect(result!.id, isNot('existing-recap'));
    });

    test('skips cache check when forceRefresh is true', () async {
      when(() => mockHabitRepo.getCompletionsBetweenDates(any(), any(), any()))
          .thenAnswer((_) async => const Right([]));
      when(() => mockDriftRepo.getUserStats(any()))
          .thenAnswer((_) async => _profile());
      when(() => mockDriftRepo.saveRecap(any(), any()))
          .thenAnswer((_) async => {});

      await service().generateRecap(
        userId: testUserId,
        forceRefresh: true,
      );

      verifyNever(() => mockDriftRepo.getLatestRecap(any()));
      verify(() => mockHabitRepo.getCompletionsBetweenDates(any(), any(), any()))
          .called(1);
    });

    test('generates local recap for non-premium user with isLocked=true',
        () async {
      when(() => mockHabitRepo.getCompletionsBetweenDates(any(), any(), any()))
          .thenAnswer((_) async => const Right([]));
      when(() => mockDriftRepo.getUserStats(any()))
          .thenAnswer((_) async => _profile(level: 1, entropy: 0.5));
      when(() => mockDriftRepo.saveRecap(any(), any()))
          .thenAnswer((_) async => {});

      final result = await service().generateRecap(
        userId: testUserId,
        startDate: DateTime(2025, 6, 9),
        endDate: DateTime(2025, 6, 15),
      );

      expect(result, isNotNull);
      expect(result!.isAiGenerated, false);
      expect(result.isLocked, true);
    });

    test('generates recap for premium user (AI fails, falls back to local)',
        () async {
      final premiumContainer = _makeContainer(
        driftRepo: mockDriftRepo,
        habitRepo: mockHabitRepo,
        premium: true,
      );

      when(() => mockHabitRepo.getCompletionsBetweenDates(any(), any(), any()))
          .thenAnswer((_) async => const Right([]));
      when(() => mockDriftRepo.getUserStats(any()))
          .thenAnswer((_) async => _profile(level: 1, entropy: 0.5));
      when(() => mockDriftRepo.saveRecap(any(), any()))
          .thenAnswer((_) async => {});

      await premiumContainer.read(isPremiumProvider.future);

      final result = await premiumContainer
          .read(weeklyRecapServiceProvider)
          .generateRecap(
            userId: testUserId,
            startDate: DateTime(2025, 6, 9),
            endDate: DateTime(2025, 6, 15),
          );

      expect(result, isNotNull);
      expect(result!.isLocked, false);
      expect(result.isAiGenerated, false);

      premiumContainer.dispose();
    });

    test('saves recap to repository', () async {
      when(() => mockHabitRepo.getCompletionsBetweenDates(any(), any(), any()))
          .thenAnswer((_) async => const Right([]));
      when(() => mockDriftRepo.getUserStats(any()))
          .thenAnswer((_) async => _profile());
      when(() => mockDriftRepo.saveRecap(any(), any()))
          .thenAnswer((_) async => {});

      await service().generateRecap(
        userId: testUserId,
        startDate: DateTime(2025, 6, 9),
        endDate: DateTime(2025, 6, 15),
      );

      verify(() => mockDriftRepo.saveRecap(any(), any())).called(1);
    });

    test('uses default date range when not provided', () async {
      when(() => mockDriftRepo.getLatestRecap(any()))
          .thenAnswer((_) async => null);
      when(() => mockHabitRepo.getCompletionsBetweenDates(any(), any(), any()))
          .thenAnswer((_) async => const Right([]));
      when(() => mockDriftRepo.getUserStats(any()))
          .thenAnswer((_) async => _profile());
      when(() => mockDriftRepo.saveRecap(any(), any()))
          .thenAnswer((_) async => {});

      final result = await service().generateRecap(
        userId: testUserId,
        forceRefresh: true,
      );

      expect(result, isNotNull);
    });

    test('marks recap as incomplete when range is less than 7 days',
        () async {
      when(() => mockHabitRepo.getCompletionsBetweenDates(any(), any(), any()))
          .thenAnswer((_) async => const Right([]));
      when(() => mockDriftRepo.getUserStats(any()))
          .thenAnswer((_) async => _profile());
      when(() => mockDriftRepo.saveRecap(any(), any()))
          .thenAnswer((_) async => {});

      final result = await service().generateRecap(
        userId: testUserId,
        startDate: DateTime(2025, 6, 9),
        endDate: DateTime(2025, 6, 12),
      );

      expect(result, isNotNull);
      expect(result!.isComplete, false);
    });
  });

  group('recap calculation', () {
    test('calculates correctly with empty activities', () async {
      when(() => mockHabitRepo.getCompletionsBetweenDates(any(), any(), any()))
          .thenAnswer((_) async => const Right([]));
      when(() => mockDriftRepo.getUserStats(any()))
          .thenAnswer((_) async => _profile(level: 1, entropy: 0.5));
      when(() => mockDriftRepo.saveRecap(any(), any()))
          .thenAnswer((_) async => {});

      final result = await service().generateRecap(
        userId: testUserId,
        startDate: DateTime(2025, 6, 9),
        endDate: DateTime(2025, 6, 15),
        forceRefresh: true,
      );

      expect(result!.totalHabitsCompleted, 0);
      expect(result.totalXpEarned, 0);
      expect(result.perfectDays, 0);
      expect(result.topHabitName, 'New Beginnings');
      expect(result.dominantIdentityThisWeek, 'Pioneer');
      expect(result.currentLevel, 1);
      expect(result.worldGrowthPercentage, closeTo(0.5, 0.01));
    });

    test('calculates habit completions and XP from activities', () async {
      final today = DateTime(2025, 6, 10);
      final activities = [
        _activity(
          habitId: 'habit-1',
          xpEarned: 10,
          attribute: 'strength',
          date: today,
        ),
        _activity(
          habitId: 'habit-2',
          xpEarned: 20,
          attribute: 'intellect',
          date: today,
        ),
        _activity(
          habitId: 'habit-1',
          xpEarned: 10,
          attribute: 'strength',
          date: today,
        ),
      ];

      when(() => mockHabitRepo.getCompletionsBetweenDates(any(), any(), any()))
          .thenAnswer((_) async => Right(activities));
      when(() => mockDriftRepo.getUserStats(any()))
          .thenAnswer((_) async => _profile(level: 3, entropy: 0.3));
      when(() => mockHabitRepo.getHabit('habit-1'))
          .thenAnswer((_) async => _habit(id: 'habit-1', title: 'Top Habit'));
      when(() => mockDriftRepo.saveRecap(any(), any()))
          .thenAnswer((_) async => {});

      final result = await service().generateRecap(
        userId: testUserId,
        startDate: DateTime(2025, 6, 9),
        endDate: DateTime(2025, 6, 15),
        forceRefresh: true,
      );

      expect(result!.totalHabitsCompleted, 3);
      expect(result.totalXpEarned, 40);
      expect(result.perfectDays, 1);
      expect(result.topHabitName, 'Top Habit');
      expect(result.dominantIdentityThisWeek, 'strength');
      expect(result.currentLevel, 3);
      expect(result.worldGrowthPercentage, closeTo(0.7, 0.01));
    });

    test('sets topHabitName to Unknown Habit when getHabit returns null',
        () async {
      final today = DateTime(2025, 6, 10);
      final activities = [
        _activity(
          habitId: 'unknown-habit',
          xpEarned: 10,
          attribute: 'focus',
          date: today,
        ),
      ];

      when(() => mockHabitRepo.getCompletionsBetweenDates(any(), any(), any()))
          .thenAnswer((_) async => Right(activities));
      when(() => mockDriftRepo.getUserStats(any()))
          .thenAnswer((_) async => _profile());
      when(() => mockHabitRepo.getHabit('unknown-habit'))
          .thenAnswer((_) async => null);
      when(() => mockDriftRepo.saveRecap(any(), any()))
          .thenAnswer((_) async => {});

      final result = await service().generateRecap(
        userId: testUserId,
        startDate: DateTime(2025, 6, 9),
        endDate: DateTime(2025, 6, 15),
        forceRefresh: true,
      );

      expect(result!.topHabitName, 'Unknown Habit');
    });

    test('calculates perfectDays across multiple dates', () async {
      final activities = [
        _activity(
          habitId: 'habit-1',
          attribute: 'vitality',
          date: DateTime(2025, 6, 9),
        ),
        _activity(
          habitId: 'habit-1',
          attribute: 'vitality',
          date: DateTime(2025, 6, 10),
        ),
        _activity(
          habitId: 'habit-1',
          attribute: 'vitality',
          date: DateTime(2025, 6, 10),
        ),
        _activity(
          habitId: 'habit-1',
          attribute: 'vitality',
          date: DateTime(2025, 6, 11),
        ),
      ];

      when(() => mockHabitRepo.getCompletionsBetweenDates(any(), any(), any()))
          .thenAnswer((_) async => Right(activities));
      when(() => mockDriftRepo.getUserStats(any()))
          .thenAnswer((_) async => _profile());
      when(() => mockHabitRepo.getHabit('habit-1'))
          .thenAnswer((_) async => _habit(id: 'habit-1', title: 'Daily Habit'));
      when(() => mockDriftRepo.saveRecap(any(), any()))
          .thenAnswer((_) async => {});

      final result = await service().generateRecap(
        userId: testUserId,
        startDate: DateTime(2025, 6, 9),
        endDate: DateTime(2025, 6, 15),
        forceRefresh: true,
      );

      expect(result!.perfectDays, 3);
      expect(result.totalHabitsCompleted, 4);
    });

    test('counts all completions from the date range', () async {
      final today = DateTime(2025, 6, 10);
      final activities = [
        _activity(
          habitId: 'habit-1',
          xpEarned: 10,
          attribute: 'strength',
          date: today,
        ),
        _activity(
          habitId: 'habit-2',
          xpEarned: 5,
          attribute: 'strength',
          date: today,
        ),
        _activity(
          habitId: 'habit-3',
          xpEarned: 50,
          attribute: 'intellect',
          date: today,
        ),
      ];

      when(() => mockHabitRepo.getCompletionsBetweenDates(any(), any(), any()))
          .thenAnswer((_) async => Right(activities));
      when(() => mockDriftRepo.getUserStats(any()))
          .thenAnswer((_) async => _profile());
      when(() => mockHabitRepo.getHabit('habit-1'))
          .thenAnswer((_) async => _habit(id: 'habit-1', title: 'Real Habit'));
      when(() => mockHabitRepo.getHabit('habit-2'))
          .thenAnswer((_) async => _habit(id: 'habit-2', title: 'Second Habit'));
      when(() => mockHabitRepo.getHabit('habit-3'))
          .thenAnswer((_) async => _habit(id: 'habit-3', title: 'Third Habit'));
      when(() => mockDriftRepo.saveRecap(any(), any()))
          .thenAnswer((_) async => {});

      final result = await service().generateRecap(
        userId: testUserId,
        startDate: DateTime(2025, 6, 9),
        endDate: DateTime(2025, 6, 15),
        forceRefresh: true,
      );

      expect(result!.totalHabitsCompleted, 3);
      expect(result.totalXpEarned, 65);
    });
  });
}
