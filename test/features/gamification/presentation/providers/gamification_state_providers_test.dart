import 'package:emerge_app/features/auth/domain/entities/auth_user.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/core/drift_repositories/repositories_barrel.dart';
import 'package:emerge_app/features/gamification/data/repositories/user_stats_repository.dart';
import 'package:emerge_app/features/gamification/presentation/providers/recap_hub_provider.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockUserStatsRepository extends Mock implements DriftUserStatsRepository {}

void main() {
  late MockUserStatsRepository mockStatsRepo;

  setUp(() {
    mockStatsRepo = MockUserStatsRepository();
    when(() => mockStatsRepo.getRecaps(any(), limit: any(named: 'limit')))
        .thenAnswer((_) async => []);
  });

  group('userStatsStreamProvider', () {
    test('reads overridden value', () {
      final container = ProviderContainer(
        overrides: [
          userStatsStreamProvider.overrideWithValue(
            AsyncValue.data(
              const UserProfile(uid: 'test', archetype: UserArchetype.scholar),
            ),
          ),
        ],
      );
      expect(
        container.read(userStatsStreamProvider).requireValue.archetype,
        UserArchetype.scholar,
      );
      container.dispose();
    });
  });

  group('recapRefreshCounterProvider', () {
    test('initial value is 0', () {
      final container = ProviderContainer(
        overrides: [
          userStatsRepositoryProvider.overrideWithValue(mockStatsRepo),
        ],
      );
      expect(container.read(recapRefreshCounterProvider), 0);
      container.dispose();
    });

    test('increment increases value', () {
      final container = ProviderContainer(
        overrides: [
          userStatsRepositoryProvider.overrideWithValue(mockStatsRepo),
        ],
      );
      container.read(recapRefreshCounterProvider.notifier).increment();
      expect(container.read(recapRefreshCounterProvider), 1);
      container.dispose();
    });
  });

  group('historicalRecapsProvider', () {
    final validRecapMap = {
      'id': 'recap_1',
      'userId': 'test',
      'startDate': '2024-01-01T00:00:00.000',
      'endDate': '2024-01-07T00:00:00.000',
      'totalHabitsCompleted': 15,
      'perfectDays': 5,
      'totalXpEarned': 500,
      'topHabitName': 'Morning Run',
      'currentLevel': 3,
      'worldGrowthPercentage': 0.65,
    };

    test('returns empty list for empty auth user', () async {
      final container = ProviderContainer(
        overrides: [
          authStateChangesProvider.overrideWithValue(
            const AsyncValue.data(AuthUser.empty),
          ),
          userStatsRepositoryProvider.overrideWithValue(mockStatsRepo),
        ],
      );
      final result = await container.read(historicalRecapsProvider.future);
      expect(result, []);
      container.dispose();
    });

    test('returns recaps from repository', () async {
      when(() => mockStatsRepo.getRecaps('test', limit: 20)).thenAnswer(
        (_) async => [validRecapMap],
      );
      final container = ProviderContainer(
        overrides: [
          authStateChangesProvider.overrideWithValue(
            const AsyncValue.data(AuthUser(id: 'test', email: 'test@example.com')),
          ),
          userStatsRepositoryProvider.overrideWithValue(mockStatsRepo),
        ],
      );
      final result = await container.read(historicalRecapsProvider.future);
      expect(result.length, 1);
      expect(result.first.totalXpEarned, 500);
      container.dispose();
    });

    test('handles repository error gracefully', () async {
      when(() => mockStatsRepo.getRecaps('test', limit: 20)).thenThrow(Exception('DB error'));
      final container = ProviderContainer(
        overrides: [
          authStateChangesProvider.overrideWithValue(
            const AsyncValue.data(AuthUser(id: 'test', email: 'test@example.com')),
          ),
          userStatsRepositoryProvider.overrideWithValue(mockStatsRepo),
        ],
      );
      final result = await container.read(historicalRecapsProvider.future);
      expect(result, []);
      container.dispose();
    });
  });
}
