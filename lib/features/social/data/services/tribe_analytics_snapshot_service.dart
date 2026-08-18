// lib/features/social/data/services/tribe_analytics_snapshot_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fpdart/fpdart.dart';
import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/features/social/domain/models/creator_analytics.dart';

/// Writes one daily snapshot per tribe and reads trend history.
///
/// Client-side (no Cloud Function): when a creator opens analytics and the
/// last snapshot is >24h stale, this writes today's aggregate. History
/// accumulates as creators open the app.
class TribeAnalyticsSnapshotService {
  final FirebaseFirestore _firestore;

  TribeAnalyticsSnapshotService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static String dateKey(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Returns the latest snapshot doc for a tribe, or null.
  Future<Map<String, dynamic>?> _latestSnapshot(String tribeId) async {
    final snap = await _firestore
        .collection('tribe_analytics')
        .doc(tribeId)
        .collection('daily')
        .orderBy('date', descending: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return snap.docs.first.data();
  }

  /// Writes today's snapshot if the latest is missing or older than 24h.
  Future<Either<Failure, Unit>> ensureTodaySnapshot({
    required String uid,
    required String tribeId,
  }) async {
    if (uid.isEmpty || tribeId.isEmpty) {
      return const Left(ServerFailure('Missing creator or tribe'));
    }
    try {
      final latest = await _latestSnapshot(tribeId);
      if (latest != null) {
        final latestDate = DateTime.tryParse(latest['date'] as String? ?? '');
        if (latestDate != null &&
            DateTime.now().difference(latestDate).inHours < 24) {
          return const Right(unit);
        }
      }

      // Aggregate current state.
      final tribeDoc = await _firestore.collection('tribes').doc(tribeId).get();
      final tribeData = tribeDoc.data() ?? const <String, dynamic>{};
      final memberCount = (tribeData['memberCount'] as num?)?.toInt() ?? 0;

      final contributors =
          await _firestore
              .collection('tribes')
              .doc(tribeId)
              .collection('contributors')
              .get();

      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      int totalXp = 0, totalHabits = 0, totalChallenges = 0;
      int newMembers = 0, activeMembers = 0;

      for (final doc in contributors.docs) {
        final data = doc.data();
        totalXp += (data['totalXpContributed'] as num?)?.toInt() ?? 0;
        totalHabits += (data['totalHabitsCompleted'] as num?)?.toInt() ?? 0;
        totalChallenges +=
            (data['totalChallengesCompleted'] as num?)?.toInt() ?? 0;

        final joinedAt = _parseDate(data['joinedAt']);
        if (joinedAt != null && joinedAt.isAfter(weekAgo)) newMembers++;

        final lastActivity = _parseDate(data['lastActivity']);
        if (lastActivity != null && lastActivity.isAfter(weekAgo)) {
          activeMembers++;
        }
      }

      final today = dateKey(now);
      await _firestore
          .collection('tribe_analytics')
          .doc(tribeId)
          .collection('daily')
          .doc(today)
          .set({
            'tribeId': tribeId,
            'date': today,
            'memberCount': memberCount,
            'totalXp': totalXp,
            'totalHabitsCompleted': totalHabits,
            'totalChallengesCompleted': totalChallenges,
            'activeMembers': activeMembers,
            'newMembersThisWeek': newMembers,
            'createdAt': FieldValue.serverTimestamp(),
          });
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure('Could not save analytics snapshot: $e'));
    }
  }

  /// Reads the last [days] daily snapshots, ascending by date.
  Future<Either<Failure, List<DailyTrend>>> getTrends({
    required String tribeId,
    int days = 30,
  }) async {
    try {
      final snap = await _firestore
          .collection('tribe_analytics')
          .doc(tribeId)
          .collection('daily')
          .orderBy('date', descending: true)
          .limit(days)
          .get();
      final list = snap.docs
          .map((d) => DailyTrend(
            date: d.data()['date'] as String? ?? '',
            memberCount: (d.data()['memberCount'] as num?)?.toInt() ?? 0,
            totalXp: (d.data()['totalXp'] as num?)?.toInt() ?? 0,
            totalHabitsCompleted:
                (d.data()['totalHabitsCompleted'] as num?)?.toInt() ?? 0,
          ))
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));
      return Right(list);
    } catch (e) {
      return Left(ServerFailure('Could not load analytics trends: $e'));
    }
  }

  DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is String) return DateTime.tryParse(v);
    return null;
  }
}