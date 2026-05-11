import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/features/social/domain/models/cached_stats.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';
import 'package:emerge_app/features/social/data/services/tribe_stats_service.dart';

class TribeStatsCache {
  final Map<String, CachedStats> _cache = {};
  final Duration ttl;
  
  TribeStatsCache({this.ttl = const Duration(minutes: 5)});
  
  CachedStats? get(String tribeId) {
    final cached = _cache[tribeId];
    if (cached == null) return null;
    
    if (cached.isExpired()) {
      _cache.remove(tribeId);
      return null;
    }
    
    return cached;
  }
  
  void set(String tribeId, TribeStats stats) {
    _cache[tribeId] = CachedStats(stats, DateTime.now(), ttl: ttl);
  }
  
  void invalidate(String tribeId) {
    _cache.remove(tribeId);
  }
  
  void clear() {
    _cache.clear();
  }
}

final tribeStatsCacheProvider = Provider<TribeStatsCache>((ref) {
  return TribeStatsCache();
});

final cachedTribeStatsProvider = FutureProvider.family<TribeStats, String>((
  ref,
  tribeId,
) async {
  final cache = ref.watch(tribeStatsCacheProvider);
  final statsService = ref.watch(tribeStatsServiceProvider);
  
  // Check cache first
  final cached = cache.get(tribeId);
  if (cached != null) {
    return cached.stats;
  }
  
  // Calculate fresh stats
  final data = await statsService.getTribeStats(tribeId);
  final stats = TribeStats(
    memberCount: data['memberCount'] as int? ?? 0,
    totalXp: data['totalXp'] as int? ?? 0,
    totalHabitsCompleted: data['totalHabitsCompleted'] as int? ?? 0,
    totalChallengesCompleted: data['totalChallengesCompleted'] as int? ?? 0,
  );
  
  // Cache the result
  cache.set(tribeId, stats);
  
  return stats;
});
