import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
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

final cachedTribeStatsProvider = StreamProvider.family<TribeStats, String>((
  ref,
  tribeId,
) {
  final dao = ref.watch(tribeStatsDaoProvider);
  final firestore = FirebaseFirestore.instance;

  final controller = StreamController<TribeStats>();

  StreamSubscription<TribeStatsTableData?>? localSub;
  StreamSubscription<DocumentSnapshot>? remoteSub;

  void emitMerged(TribeStatsTableData? localRow, Map<String, dynamic>? remoteData) {
    final localTotalXp = localRow?.totalXp ?? 0;
    final remoteTotalXp = remoteData?['totalXp'] as int? ?? 0;
    final localHabits = localRow?.totalHabitsCompleted ?? 0;
    final remoteHabits = remoteData?['totalHabitsCompleted'] as int? ?? 0;
    final localChallenges = localRow?.totalChallengesCompleted ?? 0;
    final remoteChallenges = remoteData?['totalChallengesCompleted'] as int? ?? 0;
    // memberCount can decrease (leave tribe) so use remote if available
    final memberCount = remoteData?['memberCount'] as int? ?? localRow?.memberCount ?? 0;
    // XP/habits/challenges are monotonic — take the higher value so
    // locally-completed habits are shown immediately, not overridden by
    // stale Firestore data during the async sync window.
    final totalXp = localTotalXp > remoteTotalXp ? localTotalXp : remoteTotalXp;
    final totalHabitsCompleted = localHabits > remoteHabits ? localHabits : remoteHabits;
    final totalChallengesCompleted = localChallenges > remoteChallenges ? localChallenges : remoteChallenges;

    if (!controller.isClosed) {
      controller.add(TribeStats(
        memberCount: memberCount,
        totalXp: totalXp,
        totalHabitsCompleted: totalHabitsCompleted,
        totalChallengesCompleted: totalChallengesCompleted,
      ));
    }
  }

  var localRow = null as TribeStatsTableData?;
  var remoteData = null as Map<String, dynamic>?;
  var localReady = false;
  var remoteReady = false;

  localSub = dao.watchStats(tribeId).listen(
    (row) {
      localRow = row;
      localReady = true;
      if (remoteReady) emitMerged(localRow, remoteData);
    },
    onError: controller.addError,
  );

  remoteSub = firestore.collection('tribes').doc(tribeId).snapshots().listen(
    (snapshot) {
      remoteData = snapshot.data();
      remoteReady = true;
      if (localReady) emitMerged(localRow, remoteData);
    },
    onError: controller.addError,
  );

  controller.onCancel = () {
    localSub?.cancel();
    remoteSub?.cancel();
  };

  return controller.stream;
});
