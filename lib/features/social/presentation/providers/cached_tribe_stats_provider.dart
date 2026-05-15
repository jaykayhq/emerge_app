import 'package:emerge_app/core/drift/database.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TribeStatsCache {
  final Map<String, TribeStats> _cache = {};

  void set(String tribeId, TribeStats stats) {
    _cache[tribeId] = stats;
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
  final dao = ref.watch(tribeStatsDaoProvider);
  final row = await dao.getStats(tribeId);
  if (row == null) {
    return TribeStats(
      memberCount: 0,
      totalXp: 0,
      totalHabitsCompleted: 0,
      totalChallengesCompleted: 0,
    );
  }
  return TribeStats(
    memberCount: row.memberCount,
    totalXp: row.totalXp,
    totalHabitsCompleted: row.totalHabitsCompleted,
    totalChallengesCompleted: row.totalChallengesCompleted,
  );
});
