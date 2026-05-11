import 'package:emerge_app/features/social/domain/models/cached_stats.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';

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