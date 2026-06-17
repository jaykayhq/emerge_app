import 'package:emerge_app/features/social/domain/repositories/leaderboard_repository.dart';
import 'package:emerge_app/features/social/presentation/providers/leaderboard_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockLeaderboardRepository extends Mock implements LeaderboardRepository {}

ProviderContainer _makeContainer(LeaderboardRepository repo) {
  return ProviderContainer(
    overrides: [
      leaderboardRepositoryProvider.overrideWithValue(repo),
    ],
  );
}

void main() {
  late MockLeaderboardRepository mockRepo;

  setUp(() {
    mockRepo = MockLeaderboardRepository();
  });

  group('leaderboardRepositoryProvider', () {
    test('returns repository', () {
      final container = _makeContainer(mockRepo);
      expect(container.read(leaderboardRepositoryProvider), mockRepo);
      container.dispose();
    });
  });

  group('clubLeaderboardProvider', () {
    test('returns leaderboard stream', () async {
      when(() => mockRepo.watchClubLeaderboard('club-1'))
          .thenAnswer((_) => const Stream.empty());
      final container = _makeContainer(mockRepo);
      final result = container.read(clubLeaderboardProvider('club-1'));
      expect(result, isNotNull);
      container.dispose();
    });
  });

  group('challengeLeaderboardProvider', () {
    test('returns leaderboard stream', () async {
      when(() => mockRepo.watchChallengeLeaderboard('ch-1'))
          .thenAnswer((_) => const Stream.empty());
      final container = _makeContainer(mockRepo);
      final result = container.read(challengeLeaderboardProvider('ch-1'));
      expect(result, isNotNull);
      container.dispose();
    });
  });
}
