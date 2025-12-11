import 'package:emerge_app/features/auth/domain/entities/auth_user.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/gamification/data/repositories/user_stats_repository.dart';
import 'package:emerge_app/features/gamification/domain/services/gamification_service.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/domain/repositories/habit_repository.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockUserStatsRepository extends Mock implements UserStatsRepository {}

class MockGamificationService extends Mock implements GamificationService {}

class MockHabitRepository extends Mock implements HabitRepository {}

class MockRef extends Mock implements Ref {}

class FakeUserProfile extends Fake implements UserProfile {}

class FakeUserAvatarStats extends Fake implements UserAvatarStats {}

class FakeUserWorldState extends Fake implements UserWorldState {}

void main() {
  late MockUserStatsRepository mockUserStatsRepository;
  late MockGamificationService mockGamificationService;
  late MockHabitRepository mockHabitRepository;
  late MockRef mockRef;
  late UserStatsController controller;

  setUpAll(() {
    registerFallbackValue(FakeUserProfile());
    registerFallbackValue(FakeUserAvatarStats());
    registerFallbackValue(FakeUserWorldState());
  });

  setUp(() {
    mockUserStatsRepository = MockUserStatsRepository();
    mockGamificationService = MockGamificationService();
    mockHabitRepository = MockHabitRepository();
    mockRef = MockRef();

    // Setup default Ref reads
    when(
      () => mockRef.read(userStatsRepositoryProvider),
    ).thenReturn(mockUserStatsRepository);
    when(
      () => mockRef.read(gamificationServiceProvider),
    ).thenReturn(mockGamificationService);
    when(
      () => mockRef.read(habitRepositoryProvider),
    ).thenReturn(mockHabitRepository);
    when(() => mockRef.read(authStateChangesProvider)).thenReturn(
      const AsyncValue.data(AuthUser(id: '123', email: 'test@test.com')),
    );

    controller = UserStatsController(mockRef);
  });

  tearDown(() {
    controller.dispose();
  });

  test('awardXpForHabit should calculate XP and update user stats', () async {
    // Arrange
    final habit = Habit(
      id: '1',
      userId: '123',
      title: 'Test Habit',
      cue: 'Cue',
      routine: 'Routine',
      reward: 'Reward',
      createdAt: DateTime.now(),
      difficulty: HabitDifficulty.medium,
    );

    const initialStats = UserAvatarStats(level: 1, strengthXp: 0);
    const newStats = UserAvatarStats(level: 1, strengthXp: 20);
    const initialProfile = UserProfile(uid: '123', avatarStats: initialStats);

    when(
      () => mockUserStatsRepository.getUserStats('123'),
    ).thenAnswer((_) async => initialProfile);
    when(() => mockGamificationService.calculateXpGain(habit)).thenReturn(20);
    when(
      () => mockGamificationService.addXp(any(), 20, habit.attribute),
    ).thenReturn(newStats);
    when(
      () => mockGamificationService.reduceEntropy(any(), any()),
    ).thenReturn(const UserWorldState());
    when(
      () => mockUserStatsRepository.saveUserStats(any()),
    ).thenAnswer((_) async {});

    // Act
    await controller.awardXpForHabit(habit);

    // Assert
    verify(() => mockUserStatsRepository.saveUserStats(any())).called(1);
    verify(
      () => mockGamificationService.addXp(any(), 20, habit.attribute),
    ).called(1);
  });
}
