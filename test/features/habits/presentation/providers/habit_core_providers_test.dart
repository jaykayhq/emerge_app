import 'package:emerge_app/features/auth/domain/entities/auth_user.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/domain/repositories/habit_repository.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockHabitRepository extends Mock implements HabitRepository {}

ProviderContainer _makeContainer({
  required HabitRepository habitRepo,
  AuthUser? authUser,
}) {
  return ProviderContainer(
    overrides: [
      authStateChangesProvider.overrideWithValue(
        AsyncValue.data(authUser ?? const AuthUser(id: 'test', email: 'test@example.com')),
      ),
      habitRepositoryProvider.overrideWithValue(habitRepo),
    ],
  );
}

void main() {
  late MockHabitRepository mockRepo;

  setUp(() {
    mockRepo = MockHabitRepository();
  });

  group('momentumServiceProvider', () {
    test('creates a MomentumService instance', () {
      final container = _makeContainer(habitRepo: mockRepo);
      expect(container.read(momentumServiceProvider), isNotNull);
      container.dispose();
    });
  });

  group('habitsProvider', () {
    test('returns empty list when no user', () async {
      final container = ProviderContainer(
        overrides: [
          authStateChangesProvider.overrideWithValue(
            const AsyncValue.data(AuthUser.empty),
          ),
          habitRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      final sub = container.listen(habitsProvider, (_, _) {});
      final result = await container.read(habitsProvider.future);
      expect(result, []);
      sub.close();
      container.dispose();
    });

    test('returns habits from repository', () async {
      final now = DateTime.now();
      final habits = [Habit(id: '1', userId: 'test', title: 'Test', createdAt: now)];
      when(() => mockRepo.watchHabits('test')).thenAnswer(
        (_) => Stream.value(habits).asBroadcastStream(),
      );
      final container = _makeContainer(habitRepo: mockRepo);
      final sub = container.listen(habitsProvider, (_, _) {});
      final result = await container.read(habitsProvider.future);
      expect(result, habits);
      sub.close();
      container.dispose();
    });
  });

  group('habitActivityProvider', () {
    test('returns empty list when no user', () async {
      final container = ProviderContainer(
        overrides: [
          authStateChangesProvider.overrideWithValue(
            const AsyncValue<AuthUser>.loading(),
          ),
          habitRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      final result = await container.read(
        habitActivityProvider(start: DateTime(2024), end: DateTime(2025)).future,
      );
      expect(result, []);
      container.dispose();
    });

    test('returns activity from repository', () async {
      final now = DateTime.now();
      when(() => mockRepo.getActivity('test', now, now.add(const Duration(days: 1))))
          .thenAnswer((_) async => []);
      final container = _makeContainer(habitRepo: mockRepo);
      final result = await container.read(
        habitActivityProvider(start: now, end: now.add(const Duration(days: 1))).future,
      );
      expect(result, []);
      container.dispose();
    });
  });
}
