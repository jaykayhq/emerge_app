import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/features/social/presentation/providers/cached_tribe_stats_provider.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';

void main() {
  group('TribeStatsCache', () {
    test('should store and retrieve cached stats', () {
      final cache = TribeStatsCache();
      final tribeId = 'test-tribe-1';
      final stats = TribeStats(
        memberCount: 10,
        totalXp: 1000,
        totalHabitsCompleted: 50,
        totalChallengesCompleted: 5,
      );
      
      cache.set(tribeId, stats);
      final retrieved = cache.get(tribeId);
      
      expect(retrieved, isNotNull);
      expect(retrieved!.stats, equals(stats));
    });

    test('should return null for non-existent cache', () {
      final cache = TribeStatsCache();
      final result = cache.get('non-existent');
      
      expect(result, isNull);
    });

    test('should expire cache after TTL', () async {
      final cache = TribeStatsCache(ttl: const Duration(milliseconds: 1));
      final tribeId = 'test-tribe-2';
      final stats = TribeStats(
        memberCount: 10,
        totalXp: 1000,
        totalHabitsCompleted: 50,
        totalChallengesCompleted: 5,
      );
      
      cache.set(tribeId, stats);
      
      // Wait for cache to expire
      await Future.delayed(const Duration(milliseconds: 10));
      
      final retrieved = cache.get(tribeId);
      expect(retrieved, isNull);
    });

    test('should invalidate cache', () {
      final cache = TribeStatsCache();
      final tribeId = 'test-tribe-3';
      final stats = TribeStats(
        memberCount: 10,
        totalXp: 1000,
        totalHabitsCompleted: 50,
        totalChallengesCompleted: 5,
      );
      
      cache.set(tribeId, stats);
      cache.invalidate(tribeId);
      
      final retrieved = cache.get(tribeId);
      expect(retrieved, isNull);
    });
  });
}