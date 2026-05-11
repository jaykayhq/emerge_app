import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';

class CachedStats {
  final TribeStats stats;
  final DateTime timestamp;
  
  static const Duration _cacheTtl = Duration(minutes: 5);
  
  CachedStats(this.stats, this.timestamp);
  
  bool isExpired() {
    return DateTime.now().difference(timestamp) > _cacheTtl;
  }
}
