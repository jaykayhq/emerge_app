import 'package:emerge_app/features/social/data/repositories/tribe_repository.dart';
import 'package:emerge_app/features/social/presentation/providers/cached_tribe_stats_provider.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTribeRepository extends Mock implements TribeRepository {}

ProviderContainer _makeContainer(TribeRepository tribeRepo) {
  return ProviderContainer(
    overrides: [
      tribeRepositoryProvider.overrideWithValue(tribeRepo),
    ],
  );
}

void main() {
  late MockTribeRepository mockRepo;

  setUp(() {
    mockRepo = MockTribeRepository();
  });

  group('tribeRepositoryProvider', () {
    test('creates repository', () {
      final container = _makeContainer(mockRepo);
      expect(container.read(tribeRepositoryProvider), mockRepo);
      container.dispose();
    });
  });

  group('userClubProvider', () {
    test('returns club by archetype ID', () async {
      when(() => mockRepo.getArchetypeClub('club-1')).thenAnswer((_) async => null);
      final container = _makeContainer(mockRepo);
      final result = await container.read(userClubProvider('club-1').future);
      expect(result, isNull);
      container.dispose();
    });
  });

  group('allArchetypeClubsProvider', () {
    test('returns clubs stream', () async {
      when(() => mockRepo.watchArchetypeClubs()).thenAnswer((_) => const Stream.empty());
      final container = _makeContainer(mockRepo);
      final result = container.read(allArchetypeClubsProvider);
      expect(result, isNotNull);
      container.dispose();
    });
  });

  group('globalActivityProvider', () {
    test('returns activity stream', () async {
      when(() => mockRepo.watchGlobalActivity()).thenAnswer((_) => const Stream.empty());
      final container = _makeContainer(mockRepo);
      final result = container.read(globalActivityProvider);
      expect(result, isNotNull);
      container.dispose();
    });
  });

  group('realTimeTribeStatsProvider', () {
    test('returns stats stream', () async {
      when(() => mockRepo.watchArchetypeClubs()).thenAnswer((_) => const Stream.empty());
      final container = _makeContainer(mockRepo);
      final result = container.read(realTimeTribeStatsProvider('tribe-1'));
      expect(result, isNotNull);
      container.dispose();
    });
  });

  group('globalAggregateStatsProvider', () {
    test('returns aggregate stats stream', () async {
      when(() => mockRepo.watchArchetypeClubs()).thenAnswer((_) => const Stream.empty());
      final container = _makeContainer(mockRepo);
      final result = container.read(globalAggregateStatsProvider);
      expect(result, isNotNull);
      container.dispose();
    });
  });

  group('tribeStatsCacheProvider', () {
    test('creates cache instance', () {
      final container = _makeContainer(mockRepo);
      expect(container.read(tribeStatsCacheProvider), isNotNull);
      container.dispose();
    });
  });
}
