import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/activity.dart';
import '../../domain/services/global_activity_service.dart';

part 'global_activity_provider.g.dart';

@riverpod
GlobalActivityService globalActivityService(Ref ref) {
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
