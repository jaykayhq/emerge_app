import 'package:emerge_app/features/auth/domain/entities/auth_user.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/core/drift_repositories/repositories_barrel.dart';
import 'package:emerge_app/features/gamification/data/repositories/user_stats_repository.dart';
import 'package:emerge_app/features/world_map/domain/services/world_health_service.dart';
import 'package:emerge_app/features/world_map/presentation/providers/world_health_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockWorldHealthService extends Mock implements WorldHealthService {}
class MockUserStatsRepository extends Mock implements DriftUserStatsRepository {}

ProviderContainer _makeContainer({
  required WorldHealthService healthService,
  DriftUserStatsRepository? statsRepo,
  AuthUser? authUser,
}) {
  return ProviderContainer(
    overrides: [
      authStateChangesProvider.overrideWithValue(
        AsyncValue.data(authUser ?? const AuthUser(id: 'test', email: 'test@example.com')),
      ),
      worldHealthServiceProvider.overrideWithValue(healthService),
      if (statsRepo != null)
        userStatsRepositoryProvider.overrideWithValue(statsRepo),
    ],
  );
}

void main() {
  late MockWorldHealthService mockService;
  late MockUserStatsRepository mockRepo;

  setUp(() {
    mockService = MockWorldHealthService();
    mockRepo = MockUserStatsRepository();
  });

  group('worldHealthServiceProvider', () {
    test('creates service with repository', () {
      final container = _makeContainer(
        healthService: mockService,
        statsRepo: mockRepo,
      );
      final service = container.read(worldHealthServiceProvider);
      expect(service, mockService);
      container.dispose();
    });
  });

  group('worldHealthProvider', () {
    test('returns default 0.5 when no user', () async {
      final container = ProviderContainer(
        overrides: [
          authStateChangesProvider.overrideWithValue(
            const AsyncValue<AuthUser>.loading(),
          ),
          worldHealthServiceProvider.overrideWithValue(mockService),
        ],
      );
      final result = await container.read(worldHealthProvider.future);
      expect(result, 0.5);
      container.dispose();
    });

    test('returns health from service for authed user', () async {
      when(() => mockService.getWorldHealth('test')).thenAnswer((_) async => 0.85);
      final container = _makeContainer(healthService: mockService);
      final result = await container.read(worldHealthProvider.future);
      expect(result, 0.85);
      container.dispose();
    });
  });

  group('worldHealthStreamProvider', () {
    test('returns 0.5 when no user', () async {
      final container = ProviderContainer(
        overrides: [
          authStateChangesProvider.overrideWithValue(
            const AsyncValue<AuthUser>.loading(),
          ),
          userStatsRepositoryProvider.overrideWithValue(mockRepo),
          worldHealthServiceProvider.overrideWithValue(mockService),
        ],
      );
      final sub = container.listen(worldHealthStreamProvider, (_, _) {});
      final result = await container.read(worldHealthStreamProvider.future);
      expect(result, 0.5);
      sub.close();
      container.dispose();
    });

    test('streams momentum score from user profile', () async {
      when(() => mockRepo.watchUserStats('test')).thenAnswer(
        (_) => Stream.value(const UserProfile(uid: 'test', momentumScore: 0.75)),
      );
      final container = _makeContainer(
        healthService: mockService,
        statsRepo: mockRepo,
      );
      final sub = container.listen(worldHealthStreamProvider, (_, _) {});
      final result = await container.read(worldHealthStreamProvider.future);
      expect(result, 0.75);
      sub.close();
      container.dispose();
    });
  });

  group('worldEntropyStreamProvider', () {
    test('returns 0.0 when no user', () async {
      final container = ProviderContainer(
        overrides: [
          authStateChangesProvider.overrideWithValue(
            const AsyncValue<AuthUser>.loading(),
          ),
          userStatsRepositoryProvider.overrideWithValue(mockRepo),
          worldHealthServiceProvider.overrideWithValue(mockService),
        ],
      );
      final sub = container.listen(worldEntropyStreamProvider, (_, _) {});
      final result = await container.read(worldEntropyStreamProvider.future);
      expect(result, 0.0);
      sub.close();
      container.dispose();
    });

    test('streams entropy from user profile world state', () async {
      when(() => mockRepo.watchUserStats('test')).thenAnswer(
        (_) => Stream.value(
          const UserProfile(uid: 'test').copyWith(
            worldState: UserWorldState(entropy: 0.3),
          ),
        ),
      );
      final container = _makeContainer(
        healthService: mockService,
        statsRepo: mockRepo,
      );
      final sub = container.listen(worldEntropyStreamProvider, (_, _) {});
      final result = await container.read(worldEntropyStreamProvider.future);
      expect(result, 0.3);
      sub.close();
      container.dispose();
    });
  });
}
