import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';
import 'package:emerge_app/core/drift/app_database.dart';
import 'package:emerge_app/core/drift/daos/leaderboard_entries_dao.dart';
import 'package:emerge_app/core/drift/daos/tribe_stats_dao.dart';

class FirestoreDriftSyncer {
  final FirebaseFirestore firestore;
  final LeaderboardEntriesDao leaderboardDao;
  final TribeStatsDao tribeStatsDao;
  StreamSubscription? _leaderboardSub;
  StreamSubscription? _tribeStatsSub;

  FirestoreDriftSyncer({
    required this.firestore,
    required this.leaderboardDao,
    required this.tribeStatsDao,
  });

  void start(String tribeId) {
    _leaderboardSub = firestore
        .collection('club_leaderboards')
        .where('tribeId', isEqualTo: tribeId)
        .snapshots()
        .listen((snapshot) {
      for (final doc in snapshot.docs) {
        final data = doc.data();
        leaderboardDao.upsertEntry(LeaderboardEntriesTableCompanion(
          id: Value(doc.id),
          tribeId: Value(data['tribeId'] as String? ?? tribeId),
          userId: Value(data['userId'] as String? ?? ''),
          userName: Value(data['userName'] as String? ?? ''),
          xp: Value(data['xp'] as int? ?? 0),
          level: Value(data['level'] as int? ?? 1),
          rank: Value(data['rank'] as int? ?? 0),
          archetype: Value(data['archetype'] as String? ?? ''),
          updatedAt: Value(DateTime.now().toIso8601String()),
        ));
      }
    });

    _tribeStatsSub = firestore
        .collection('tribes')
        .doc(tribeId)
        .snapshots()
        .listen((doc) {
      if (!doc.exists) return;
      final data = doc.data()!;
      tribeStatsDao.upsertStats(TribeStatsTableCompanion(
        tribeId: Value(doc.id),
        totalXp: Value(data['totalXp'] as int? ?? 0),
        memberCount: Value(data['memberCount'] as int? ?? 0),
        totalHabitsCompleted: Value(data['totalHabitsCompleted'] as int? ?? 0),
        updatedAt: Value(DateTime.now().toIso8601String()),
      ));
    });
  }

  void stop() {
    _leaderboardSub?.cancel();
    _tribeStatsSub?.cancel();
  }
}
