import 'package:emerge_app/features/auth/domain/entities/auth_user.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/social/domain/repositories/challenge_repository.dart';
import 'package:emerge_app/features/social/presentation/providers/challenge_bundle_provider.dart';
import 'package:emerge_app/features/social/presentation/providers/challenge_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockChallengeRepository extends Mock implements ChallengeRepository {}

void main() {
  late MockChallengeRepository mockRepo;

  setUp(() {
    mockRepo = MockChallengeRepository();
  });

  group('challengeBundleProvider', () {
    test('bundle can be read without error', () async {
      when(() => mockRepo.getWeeklySpotlight(
        archetypeId: any(named: 'archetypeId'),
      )).thenAnswer((_) async => null);
      when(() => mockRepo.getUserChallenges('test')).thenAnswer(
        (_) async => [],
      );
      when(() => mockRepo.getChallengesByArchetype(any())).thenAnswer(
        (_) async => [],
      );
      when(() => mockRepo.getChallenges(
        featuredOnly: any(named: 'featuredOnly'),
      )).thenAnswer((_) async => []);

      final container = ProviderContainer(
        overrides: [
          challengeRepositoryProvider.overrideWithValue(mockRepo),
          authStateChangesProvider.overrideWithValue(
            AsyncValue.data(
              const AuthUser(id: 'test', email: 'test@example.com'),
            ),
          ),
          userStatsStreamProvider.overrideWithValue(
            AsyncValue.data(
              const UserProfile(uid: 'test', archetype: UserArchetype.athlete),
            ),
          ),
        ],
      );

      final result = await container.read(challengeBundleProvider.future);
      expect(result, isNotNull);
      container.dispose();
    });
  });
}
