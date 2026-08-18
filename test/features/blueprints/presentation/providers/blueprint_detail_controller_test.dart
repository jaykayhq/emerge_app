import 'package:emerge_app/core/services/remote_config_service.dart';
import 'package:emerge_app/features/auth/domain/entities/auth_user.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/blueprints/data/repositories/blueprint_repository.dart';
import 'package:emerge_app/features/blueprints/domain/models/blueprint.dart';
import 'package:emerge_app/features/blueprints/presentation/providers/blueprint_detail_controller.dart';
import 'package:emerge_app/features/habits/domain/repositories/habit_repository.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:emerge_app/features/monetization/presentation/providers/subscription_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';

class MockHabitRepository extends Mock implements HabitRepository {}

class MockBlueprintRepository extends Mock implements BlueprintRepository {}

class MockRemoteConfigService extends Mock implements RemoteConfigService {}

class TestIsPremium extends IsPremium {
  final bool premium;
  TestIsPremium(this.premium);
  @override
  Future<bool> build() async => premium;
}

ProviderContainer _makeContainer({
  required HabitRepository habitRepo,
  required BlueprintRepository blueprintRepo,
  RemoteConfigService? remoteConfig,
  bool premium = false,
  AuthUser? authUser,
}) {
  return ProviderContainer(
    overrides: [
      authStateChangesProvider.overrideWithValue(
        AsyncValue.data(
          authUser ?? const AuthUser(id: 'test', email: 'test@example.com'),
        ),
      ),
      habitRepositoryProvider.overrideWithValue(habitRepo),
      blueprintRepositoryProvider.overrideWithValue(blueprintRepo),
      if (remoteConfig != null)
        remoteConfigServiceProvider.overrideWithValue(remoteConfig),
      isPremiumProvider.overrideWith(() => TestIsPremium(premium)),
      habitsProvider.overrideWith((ref) => Stream.value([])),
    ],
  );
}

void main() {
  late MockHabitRepository mockHabitRepo;
  late MockBlueprintRepository mockBlueprintRepo;
  late MockRemoteConfigService mockRemoteConfig;

  setUpAll(() {
    registerFallbackValue(
      Blueprint(
        id: '',
        creatorUserId: '',
        creatorName: '',
        creatorArchetype: '',
        title: '',
        description: '',
        category: '',
        difficulty: BlueprintDifficulty.beginner,
        createdAt: DateTime.now(),
        habits: [],
      ),
    );
  });

  setUp(() {
    mockHabitRepo = MockHabitRepository();
    mockBlueprintRepo = MockBlueprintRepository();
    mockRemoteConfig = MockRemoteConfigService();
    when(() => mockRemoteConfig.freeHabitLimit).thenReturn(5);
  });

  group('blueprintDetailControllerProvider', () {
    test('adoptBlueprint creates habits and increments adoption', () async {
      final blueprint = Blueprint(
        id: 'bp-1',
        creatorUserId: 'creator-1',
        creatorName: 'Creator',
        creatorArchetype: 'Athlete',
        title: 'Test Blueprint',
        description: 'A test',
        category: 'health',
        difficulty: BlueprintDifficulty.beginner,
        createdAt: DateTime.now(),
        habits: [
          BlueprintHabit(
            title: 'Morning Run',
            frequency: 'daily',
            timeOfDay: 'morning',
          ),
        ],
        isPremium: false,
      );

      when(
        () => mockHabitRepo.createHabitsFromBlueprint(
          userId: any(named: 'userId'),
          blueprint: any(named: 'blueprint'),
          reminderTime: any(named: 'reminderTime'),
        ),
      ).thenAnswer((_) async => const Right(unit));

      when(
        () => mockBlueprintRepo.incrementAdoptionCount('bp-1'),
      ).thenAnswer((_) async {});

      final container = _makeContainer(
        habitRepo: mockHabitRepo,
        blueprintRepo: mockBlueprintRepo,
        remoteConfig: mockRemoteConfig,
      );

      await container
          .read(blueprintDetailControllerProvider.notifier)
          .adoptBlueprint(blueprint);

      verify(() => mockBlueprintRepo.incrementAdoptionCount('bp-1')).called(1);
      container.dispose();
    });

    test(
      'adoptBlueprint succeeds even when incrementAdoptionCount fails',
      () async {
        final blueprint = Blueprint(
          id: 'bp-1',
          creatorUserId: 'creator-1',
          creatorName: 'Creator',
          creatorArchetype: 'Athlete',
          title: 'Test Blueprint',
          description: 'A test',
          category: 'health',
          difficulty: BlueprintDifficulty.beginner,
          createdAt: DateTime.now(),
          habits: [
            BlueprintHabit(
              title: 'Morning Run',
              frequency: 'daily',
              timeOfDay: 'morning',
            ),
          ],
          isPremium: false,
        );

        when(
          () => mockHabitRepo.createHabitsFromBlueprint(
            userId: any(named: 'userId'),
            blueprint: any(named: 'blueprint'),
            reminderTime: any(named: 'reminderTime'),
          ),
        ).thenAnswer((_) async => const Right(unit));

        // A Firestore hiccup on the counter must NOT fail the adoption or
        // strand the state on AsyncLoading after habits were created.
        when(
          () => mockBlueprintRepo.incrementAdoptionCount('bp-1'),
        ).thenThrow(Exception('firestore down'));

        final container = _makeContainer(
          habitRepo: mockHabitRepo,
          blueprintRepo: mockBlueprintRepo,
          remoteConfig: mockRemoteConfig,
        );

        await container
            .read(blueprintDetailControllerProvider.notifier)
            .adoptBlueprint(blueprint);

        expect(
          container.read(blueprintDetailControllerProvider),
          isA<AsyncData<void>>(),
          reason:
              'state must settle on success even if the counter write fails',
        );
        container.dispose();
      },
    );

    test(
      'adoptBlueprint invalidates the cached blueprintByIdProvider',
      () async {
        final blueprint = Blueprint(
          id: 'bp-1',
          creatorUserId: 'creator-1',
          creatorName: 'Creator',
          creatorArchetype: 'Athlete',
          title: 'Test Blueprint',
          description: 'A test',
          category: 'health',
          difficulty: BlueprintDifficulty.beginner,
          createdAt: DateTime.now(),
          habits: [
            BlueprintHabit(
              title: 'Morning Run',
              frequency: 'daily',
              timeOfDay: 'morning',
            ),
          ],
          isPremium: false,
        );

        var fetchCalls = 0;
        when(
          () => mockHabitRepo.createHabitsFromBlueprint(
            userId: any(named: 'userId'),
            blueprint: any(named: 'blueprint'),
            reminderTime: any(named: 'reminderTime'),
          ),
        ).thenAnswer((_) async => const Right(unit));
        when(
          () => mockBlueprintRepo.incrementAdoptionCount('bp-1'),
        ).thenAnswer((_) async {});
        when(() => mockBlueprintRepo.getBlueprintById('bp-1')).thenAnswer((
          _,
        ) async {
          fetchCalls++;
          return blueprint;
        });

        final container = _makeContainer(
          habitRepo: mockHabitRepo,
          blueprintRepo: mockBlueprintRepo,
          remoteConfig: mockRemoteConfig,
        );

        // Keep the autoDispose family provider alive so invalidation triggers
        // an actual recompute we can observe.
        final sub = container.listen<AsyncValue<Blueprint?>>(
          blueprintByIdProvider('bp-1'),
          (_, _) {},
        );
        addTearDown(sub.close);
        await container.read(blueprintByIdProvider('bp-1').future);
        expect(fetchCalls, 1);

        await container
            .read(blueprintDetailControllerProvider.notifier)
            .adoptBlueprint(blueprint);
        // Invalidation schedules the re-fetch asynchronously; poll instead of
        // assuming a fixed delay so the assertion is timing-robust.
        for (var i = 0; i < 50; i++) {
          if (fetchCalls >= 2) break;
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }

        expect(
          fetchCalls,
          2,
          reason: 'invalidation must re-fetch the single-doc blueprint',
        );
        container.dispose();
      },
    );

    test('throws when user not authenticated', () async {
      final container = ProviderContainer(
        overrides: [
          authStateChangesProvider.overrideWithValue(
            const AsyncValue<AuthUser>.loading(),
          ),
          habitRepositoryProvider.overrideWithValue(mockHabitRepo),
          blueprintRepositoryProvider.overrideWithValue(mockBlueprintRepo),
          isPremiumProvider.overrideWith(() => TestIsPremium(false)),
          habitsProvider.overrideWith((ref) => Stream.value([])),
        ],
      );

      expect(
        () => container
            .read(blueprintDetailControllerProvider.notifier)
            .adoptBlueprint(
              Blueprint(
                id: 'bp-1',
                creatorUserId: 'creator-1',
                creatorName: 'Creator',
                creatorArchetype: 'Athlete',
                title: 'Test',
                description: '',
                category: '',
                difficulty: BlueprintDifficulty.beginner,
                createdAt: DateTime.now(),
                habits: [],
                isPremium: false,
              ),
            ),
        throwsException,
      );
      container.dispose();
    });
  });
}
