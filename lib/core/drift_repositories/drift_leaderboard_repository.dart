import 'dart:async';
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

  DriftLeaderboardRepository(this._db, this._syncEngine);

  @override
  Stream<List<LeaderboardEntry>> watchClubLeaderboard([String? clubId]) {
    if (clubId == null || clubId.isEmpty) return const Stream.empty();
    return _db.leaderboardEntriesDao.watchLeaderboard(clubId).map((rows) {
      return rows.asMap().entries.map((entry) {
        final row = entry.value;
        return LeaderboardEntry(
          userId: row.userId,
          userName: row.userName,
          xp: row.xp,
          level: row.level,
          archetype: UserArchetype.values.firstWhere(
            (e) => e.name == (row.archetype ?? 'none'),
            orElse: () => UserArchetype.none,
          ),
          rank: entry.key + 1,
        );
      }).toList();
    });
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

          await _syncEngine.enqueueUpdate(
            collectionPath: 'club_leaderboards',
            documentId: id,
            data: {
              'xp': {'__type__': 'increment', 'value': xp},
              'level': level,
              'userName': ?userName,
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
