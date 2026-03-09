import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/activity.dart';
import '../../domain/services/global_activity_service.dart';

part 'global_activity_provider.g.dart';

@riverpod
GlobalActivityService globalActivityService(GlobalActivityServiceRef ref) {
  return GlobalActivityService(FirebaseFirestore.instance);
}

@riverpod
class GlobalActivity extends _$GlobalActivity {
  late GlobalActivityService _service;

  @override
  Stream<List<Activity>> build(String? clubId, {int limit = 50}) {
    _service = ref.watch(globalActivityServiceProvider);

    if (clubId != null && clubId.isNotEmpty) {
      return _service.getClubActivityFeed(clubId, limit: limit);
    } else {
      return _service.getGlobalActivityFeed(limit: limit);
    }
  }
}

/// Auto-disposing stream provider for global activity feed
/// Usage: ref.watch(globalActivityFeedProvider)
@Riverpod(keepAlive: false)
Stream<List<Activity>> globalActivityFeed(GlobalActivityFeedRef ref) {
  final service = ref.watch(globalActivityServiceProvider);
  return service.getGlobalActivityFeed(limit: 50);
}

/// Auto-disposing family stream provider for club-specific activity feeds
/// Usage: ref.watch(clubActivityFeedProvider('athlete_club'))
@Riverpod(keepAlive: false)
Stream<List<Activity>> clubActivityFeed(
  ClubActivityFeedRef ref,
  String clubId,
) {
  final service = ref.watch(globalActivityServiceProvider);
  return service.getClubActivityFeed(clubId, limit: 50);
}
