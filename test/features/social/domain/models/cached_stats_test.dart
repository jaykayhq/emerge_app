import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/social/domain/models/cached_stats.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';

void main() {
  group('CachedStats', () {
    test('should store stats with timestamp', () {
      final stats = TribeStats(
        memberCount: 10,
        totalXp: 1000,
        totalHabitsCompleted: 50,
        totalChallengesCompleted: 5,
      );
      final timestamp = DateTime(2026, 5, 11, 12, 0);
      
      final cached = CachedStats(stats, timestamp);
      
      expect(cached.stats, equals(stats));
      expect(cached.timestamp, equals(timestamp));
    });

    test('should check if cache is expired', () {
      final stats = TribeStats(
        memberCount: 10,
        totalXp: 1000,
        totalHabitsCompleted: 50,
        totalChallengesCompleted: 5,
      );
      final oldTimestamp = DateTime.now().subtract(const Duration(minutes: 6));
      final recentTimestamp = DateTime.now().subtract(const Duration(minutes: 4));
      
      final oldCache = CachedStats(stats, oldTimestamp);
      final recentCache = CachedStats(stats, recentTimestamp);
      
      expect(oldCache.isExpired(), isTrue);
      expect(recentCache.isExpired(), isFalse);
    });
  });
}
