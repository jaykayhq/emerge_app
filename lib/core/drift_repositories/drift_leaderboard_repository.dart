import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/core/drift/database.dart';
import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/core/sync/sync_engine.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/social/domain/entities/leaderboard_entry.dart';
import 'package:emerge_app/features/social/domain/repositories/leaderboard_repository.dart';
import 'package:fpdart/fpdart.dart';

class DriftLeaderboardRepository implements LeaderboardRepository {
  final AppDatabase _db;
  final EnhancedSyncEngine _syncEngine;
  final FirebaseFirestore _firestore;

  DriftLeaderboardRepository(this._db, this._syncEngine, [FirebaseFirestore? firestore])
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<LeaderboardEntry>> watchClubLeaderboard([String? clubId]) {
    if (clubId == null || clubId.isEmpty) return const Stream.empty();

    final controller = StreamController<List<LeaderboardEntry>>();

    StreamSubscription<List<LeaderboardEntriesTableData>>? localSub;
    StreamSubscription<QuerySnapshot>? remoteSub;

    void emitMerged(List<LeaderboardEntriesTableData> localRows, List<Map<String, dynamic>> remoteDocs) {
      final seen = <String>{};
      final merged = <LeaderboardEntry>[];

      for (final doc in remoteDocs) {
        final id = '${doc['userId']}_$clubId';
        if (seen.add(id)) {
          merged.add(LeaderboardEntry(
            userId: doc['userId'] as String? ?? '',
            userName: doc['userName'] as String? ?? 'Anonymous',
            xp: (doc['xp'] as num?)?.toInt() ?? 0,
            level: (doc['level'] as num?)?.toInt() ?? 1,
            archetype: UserArchetype.values.firstWhere(
              (e) => e.name == (doc['archetype'] as String? ?? 'none'),
              orElse: () => UserArchetype.none,
            ),
            rank: 0,
          ));
        }
      }

      for (final row in localRows) {
        final id = '${row.userId}_$clubId';
        if (seen.add(id)) {
          merged.add(LeaderboardEntry(
            userId: row.userId,
            userName: row.userName,
            xp: row.xp,
            level: row.level,
            archetype: UserArchetype.values.firstWhere(
              (e) => e.name == (row.archetype ?? 'none'),
              orElse: () => UserArchetype.none,
            ),
            rank: 0,
          ));
        }
      }

      merged.sort((a, b) => b.xp.compareTo(a.xp));
      final ranked = merged.asMap().entries.map((e) {
        return e.value.copyWith(rank: e.key + 1);
      }).toList();

      if (!controller.isClosed) controller.add(ranked);
    }

    var localRows = <LeaderboardEntriesTableData>[];
    var remoteDocs = <Map<String, dynamic>>[];
    var localReady = false;
    var remoteReady = false;

    localSub = _db.leaderboardEntriesDao.watchLeaderboard(clubId).listen(
      (rows) {
        localRows = rows;
        localReady = true;
        if (remoteReady) emitMerged(localRows, remoteDocs);
      },
      onError: controller.addError,
    );

    remoteSub = _firestore
        .collection('club_leaderboards')
        .where('clubId', isEqualTo: clubId)
        .orderBy('xp', descending: true)
        .limit(50)
        .snapshots()
        .listen(
      (snapshot) {
        remoteDocs = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
        remoteReady = true;
        if (localReady) emitMerged(localRows, remoteDocs);
      },
      onError: controller.addError,
    );

    controller.onCancel = () {
      localSub?.cancel();
      remoteSub?.cancel();
    };

    return controller.stream;
  }

  @override
  Stream<List<LeaderboardEntry>> watchChallengeLeaderboard([
    String? challengeId,
  ]) {
    return const Stream.empty();
  }

  @override
  Future<Either<Failure, Unit>> updateUserScore(
    String userId, {
    required int xp,
    required int level,
    required UserArchetype archetype,
    String? userName,
    String? clubId,
    String? challengeId,
    bool isIncrement = false,
  }) async {
    try {
      if (clubId != null && clubId.isNotEmpty) {
        final id = '${userId}_$clubId';
        final nowStr = DateTime.now().toUtc().toIso8601String();

        if (isIncrement) {
          await _db.leaderboardEntriesDao.incrementXp(id, xp, level);

          // Use enqueueSet with merge so the entry is created on first
          // habit completion (not just on level-up), avoiding permission
          // errors from update() on a non-existent Firestore document.
          await _syncEngine.enqueueSet(
            collectionPath: 'club_leaderboards',
            documentId: id,
            data: {
              'userId': userId,
              'clubId': clubId,
              'userName': userName,
              'xp': {'__type__': 'increment', 'value': xp},
              'level': level,
              'lastUpdated': nowStr,
            },
          );
        } else {
          await _db.leaderboardEntriesDao.insertFromData(
            id: id,
            tribeId: clubId,
            userId: userId,
            userName: userName ?? 'Anonymous',
            xp: xp,
            level: level,
            archetype: archetype.name,
            updatedAt: nowStr,
          );

          await _syncEngine.enqueueSet(
            collectionPath: 'club_leaderboards',
            documentId: id,
            data: {
              'userId': userId,
              'userName': userName ?? 'Anonymous',
              'clubId': clubId,
              'xp': xp,
              'level': level,
              'archetype': archetype.name,
              'lastUpdated': nowStr,
            },
          );
        }
      }
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
