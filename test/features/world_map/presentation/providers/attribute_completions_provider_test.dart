import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/world_map/presentation/providers/attribute_completions_provider.dart';
import 'package:emerge_app/features/habits/domain/entities/habit_completion_entity.dart';
import 'package:emerge_app/features/habits/domain/repositories/habit_repository.dart';
import 'package:emerge_app/features/auth/domain/entities/auth_user.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MockHabitRepository extends Mock implements HabitRepository {}

void main() {
  late MockHabitRepository mockRepository;
  
  setUp(() {
    mockRepository = MockHabitRepository();
  });

  test('attributeCompletions handles null user gracefully', () async {
    final container = ProviderContainer(
      overrides: [
        authStateChangesProvider.overrideWith((ref) async* { yield AuthUser.empty; }),
      ],
    );

    // Prevent auto-dispose from cancelling the future immediately
    final subscription = container.listen(attributeCompletionsProvider('vitality'), (_, _) {});
    
    final result = await container.read(attributeCompletionsProvider('vitality').future);
    expect(result, equals([0, 0, 0, 0, 0, 0, 0]));
    
    subscription.close();
  });

  test('attributeCompletions accumulates XP into correct day buckets', () async {
    final testUser = const AuthUser(id: 'user123', email: 'test@example.com');
    final now = DateTime.now();
    
    // Create completions at different offsets
    final completions = [
      // Today (index 6)
      HabitCompletionEntity(
        id: 'c1',
        habitId: 'h1',
        attribute: 'vitality',
        xpGained: 10,
        completedAt: now,
      ),
      // Today (index 6) - same attribute, should accumulate
      HabitCompletionEntity(
        id: 'c2',
        habitId: 'h2',
        attribute: 'vitality',
        xpGained: 15,
        completedAt: now,
      ),
      // Today - different attribute, should be ignored
      HabitCompletionEntity(
        id: 'c3',
        habitId: 'h3',
        attribute: 'focus',
        xpGained: 20,
        completedAt: now,
      ),
      // 2 days ago (index 4)
      HabitCompletionEntity(
        id: 'c4',
        habitId: 'h1',
        attribute: 'vitality',
        xpGained: 5,
        completedAt: now.subtract(const Duration(days: 2)),
      ),
      // 8 days ago (out of bounds, should be ignored)
      HabitCompletionEntity(
        id: 'c5',
        habitId: 'h1',
        attribute: 'vitality',
        xpGained: 50,
        completedAt: now.subtract(const Duration(days: 8)),
      ),
    ];

    when(() => mockRepository.getCompletionsBetweenDates(
      any(),
      any(),
      any(),
    )).thenAnswer((_) async => Right(completions));

    final container = ProviderContainer(
      overrides: [
        authStateChangesProvider.overrideWith((ref) async* { yield testUser; }),
        habitRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );

    // Prevent auto-dispose from cancelling the future immediately
    final subscription = container.listen(attributeCompletionsProvider('vitality'), (_, _) {});

    final result = await container.read(attributeCompletionsProvider('vitality').future);
    
    // Expected buckets: [0, 0, 0, 0, 5, 0, 25]
    // 0: 6 days ago
    // 1: 5 days ago
    // 2: 4 days ago
    // 3: 3 days ago
    // 4: 2 days ago (5 XP)
    // 5: 1 day ago
    // 6: Today (10 + 15 = 25 XP)
    expect(result, equals([0, 0, 0, 0, 5, 0, 25]));
    
    subscription.close();
  });
}
