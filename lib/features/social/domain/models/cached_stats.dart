import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';

class CachedStats {
  final TribeStats stats;
  final DateTime timestamp;
  final Duration ttl;
  
  static const Duration _defaultCacheTtl = Duration(minutes: 5);
  
  CachedStats(this.stats, this.timestamp, {this.ttl = _defaultCacheTtl});
  
  bool isExpired() {
    return DateTime.now().difference(timestamp) > ttl;
  }
}
