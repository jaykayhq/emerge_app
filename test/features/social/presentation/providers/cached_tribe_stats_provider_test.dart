import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/features/social/presentation/providers/cached_tribe_stats_provider.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';
import 'package:emerge_app/features/social/data/services/tribe_stats_service.dart';

class MockTribeStatsService implements TribeStatsService {
  final Map<String, Map<String, dynamic>> _mockData = {};

  void setMockData(String tribeId, Map<String, dynamic> data) {
    _mockData[tribeId] = data;
  }

  @override
  Future<Map<String, dynamic>> getTribeStats(String tribeId) async {
    return _mockData[tribeId] ?? {
      'memberCount': 0,
      'totalXp': 0,
      'totalHabitsCompleted': 0,
      'totalChallengesCompleted': 0,
    };
  }

  @override
  Future<int> getMemberCount(String tribeId) async {
    return _mockData[tribeId]?['memberCount'] as int? ?? 0;
  }

  @override
  Future<int> getTotalXp(String tribeId) async {
    return _mockData[tribeId]?['totalXp'] as int? ?? 0;
  }

  @override
  Future<int> getTotalHabitsCompleted(String tribeId) async {
    return _mockData[tribeId]?['totalHabitsCompleted'] as int? ?? 0;
  }

  @override
  Future<int> getTotalChallengesCompleted(String tribeId) async {
    return _mockData[tribeId]?['totalChallengesCompleted'] as int? ?? 0;
  }

  @override
  Future<void> syncTribeStats(String tribeId) async {
    // No-op for mock
  }
}

void main() {
  group('cachedTribeStatsProvider', () {
    test('should return cached stats if available', () async {
      final mockService = MockTribeStatsService();
      final container = ProviderContainer(
        overrides: [
          tribeStatsServiceProvider.overrideWithValue(mockService),
        ],
      );
      final tribeId = 'test-tribe-1';
      final expectedStats = TribeStats(
        memberCount: 10,
        totalXp: 1000,
        totalHabitsCompleted: 50,
        totalChallengesCompleted: 5,
      );

      // Set cache
      container.read(tribeStatsCacheProvider).set(tribeId, expectedStats);

      // Read provider
      final statsAsync = container.read(cachedTribeStatsProvider(tribeId).future);
      final stats = await statsAsync;

      expect(stats, equals(expectedStats));

      container.dispose();
    });

    test('should calculate fresh stats if cache is empty', () async {
      final mockService = MockTribeStatsService();
      final tribeId = 'test-tribe-2';
      final expectedStats = TribeStats(
        memberCount: 20,
        totalXp: 2000,
        totalHabitsCompleted: 100,
        totalChallengesCompleted: 10,
      );

      mockService.setMockData(tribeId, {
        'memberCount': 20,
        'totalXp': 2000,
        'totalHabitsCompleted': 100,
        'totalChallengesCompleted': 10,
      });

      final container = ProviderContainer(
        overrides: [
          tribeStatsServiceProvider.overrideWithValue(mockService),
        ],
      );

      // Read provider (will calculate fresh stats)
      final statsAsync = container.read(cachedTribeStatsProvider(tribeId).future);
      final stats = await statsAsync;

      expect(stats, equals(expectedStats));

      container.dispose();
    });
  });
}
