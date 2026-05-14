import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/social/domain/entities/leaderboard_entry.dart';
import 'package:emerge_app/features/social/domain/repositories/leaderboard_repository.dart';
import 'package:fpdart/fpdart.dart';

/// Firestore-backed implementation of [LeaderboardRepository].
///
/// Used on web platforms where Drift/SQLite is not available.
/// Streams leaderboard data directly from the `club_leaderboards`
/// and `challenge_leaderboards` collections with no local database layer.
///
/// Matches the interface of [DriftLeaderboardRepository] but operates
/// entirely via Firestore snapshots and direct writes.
class FirestoreLeaderboardRepository implements LeaderboardRepository {
  final FirebaseFirestore _firestore;

  FirestoreLeaderboardRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  @override
  Stream<List<LeaderboardEntry>> watchClubLeaderboard([String? clubId]) {
    if (clubId == null || clubId.isEmpty) return const Stream.empty();

    return _firestore
        .collection('club_leaderboards')
        .where('clubId', isEqualTo: clubId)
        .orderBy('xp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.asMap().entries.map((entry) {
        final data = entry.value.data();
        final rank = entry.key + 1;
        return LeaderboardEntry(
          userId: data['userId'] as String? ?? '',
          userName: data['userName'] as String? ?? 'Anonymous',
          xp: data['xp'] as int? ?? 0,
          level: data['level'] as int? ?? 1,
          archetype: UserArchetype.values.firstWhere(
            (e) => e.name == (data['archetype'] as String? ?? 'none'),
            orElse: () => UserArchetype.none,
          ),
          rank: rank,
          lastUpdated: data['lastUpdated'] != null
              ? _parseTimestamp(data['lastUpdated'])
              : null,
        );
      }).toList();
    });
  }

  @override
  Stream<List<LeaderboardEntry>> watchChallengeLeaderboard([
    String? challengeId,
  ]) {
    if (challengeId == null || challengeId.isEmpty) {
      return const Stream.empty();
    }

    return _firestore
        .collection('challenge_leaderboards')
        .where('challengeId', isEqualTo: challengeId)
        .orderBy('xp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.asMap().entries.map((entry) {
        final data = entry.value.data();
        final rank = entry.key + 1;
        return LeaderboardEntry(
          userId: data['userId'] as String? ?? '',
          userName: data['userName'] as String? ?? 'Anonymous',
          xp: data['xp'] as int? ?? 0,
          level: data['level'] as int? ?? 1,
          archetype: UserArchetype.values.firstWhere(
            (e) => e.name == (data['archetype'] as String? ?? 'none'),
            orElse: () => UserArchetype.none,
          ),
          rank: rank,
          lastUpdated: data['lastUpdated'] != null
              ? _parseTimestamp(data['lastUpdated'])
              : null,
        );
      }).toList();
    });
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
        final nowTimestamp = Timestamp.fromDate(DateTime.now());

        if (isIncrement) {
          await _firestore
              .collection('club_leaderboards')
              .doc(id)
              .set({
            'xp': FieldValue.increment(xp),
            'level': level,
            if (userName case final name?) 'userName': name,
            'lastUpdated': nowTimestamp,
          }, SetOptions(merge: true));
        } else {
          await _firestore
              .collection('club_leaderboards')
              .doc(id)
              .set({
            'userId': userId,
            'userName': userName ?? 'Anonymous',
            'clubId': clubId,
            'xp': xp,
            'level': level,
            'archetype': archetype.name,
            'lastUpdated': nowTimestamp,
          });
        }
      }

      if (challengeId != null && challengeId.isNotEmpty) {
        final id = '${userId}_$challengeId';
        final nowTimestamp = Timestamp.fromDate(DateTime.now());

        if (isIncrement) {
          await _firestore
              .collection('challenge_leaderboards')
              .doc(id)
              .set({
            'xp': FieldValue.increment(xp),
            'level': level,
            if (userName case final name?) 'userName': name,
            'lastUpdated': nowTimestamp,
          }, SetOptions(merge: true));
        } else {
          await _firestore
              .collection('challenge_leaderboards')
              .doc(id)
              .set({
            'userId': userId,
            'userName': userName ?? 'Anonymous',
            'challengeId': challengeId,
            'xp': xp,
            'level': level,
            'archetype': archetype.name,
            'lastUpdated': nowTimestamp,
          });
        }
      }

      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  /// Parses a timestamp value that could be a Firestore [Timestamp],
  /// an ISO-8601 [String], or null.
  DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
