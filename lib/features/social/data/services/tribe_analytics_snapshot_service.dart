// lib/features/social/data/services/tribe_analytics_snapshot_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fpdart/fpdart.dart';
import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/features/social/domain/models/creator_analytics.dart';
import 'package:emerge_app/features/social/domain/services/tribe_aggregates.dart';

/// Writes one daily snapshot per tribe and reads trend history.
///
/// Client-side (no Cloud Function): when a creator opens analytics and the
/// last snapshot is >24h stale, this writes today's aggregate. History
/// accumulates as creators open the app.
class TribeAnalyticsSnapshotService {
  final FirebaseFirestore _firestore;
  final DateTime Function() _now;

  TribeAnalyticsSnapshotService({
    FirebaseFirestore? firestore,
    DateTime Function()? now,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _now = now ?? DateTime.now;

  /// yyyy-MM-dd of [dt] in UTC — must match the Node snapshot job's dateKey
  /// (scripts/tribe-analytics-snapshot/snapshot.js) so client and server
  /// write identical doc ids regardless of the device timezone.
  static String dateKey(DateTime dt) {
    final t = dt.toUtc();
    final y = t.year.toString().padLeft(4, '0');
    final m = t.month.toString().padLeft(2, '0');
    final d = t.day.toString().padLeft(2, '0');
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
      final now = _now();
      final latest = await _latestSnapshot(tribeId);
      if (latest != null) {
        final latestDate = DateTime.tryParse(latest['date'] as String? ?? '');
        final nowUtc = now.toUtc();
        final isFresh = latestDate != null &&
            // A future-dated doc (bad clock or malicious write) must never
            // suppress today's write — mirror the Node backstop's guard.
            !latestDate.isAfter(nowUtc) &&
            nowUtc
                    .difference(
                      DateTime.utc(
                        latestDate.year,
                        latestDate.month,
                        latestDate.day,
                      ),
                    )
                    .inHours <=
                24;
        if (isFresh) {
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

      final records = contributors.docs.map(
        (doc) => ContributorRecord(
          totalXpContributed:
              (doc.data()['totalXpContributed'] as num?)?.toInt() ?? 0,
          totalHabitsCompleted:
              (doc.data()['totalHabitsCompleted'] as num?)?.toInt() ?? 0,
          totalChallengesCompleted:
              (doc.data()['totalChallengesCompleted'] as num?)?.toInt() ?? 0,
          joinedAt: _parseDate(doc.data()['joinedAt']),
          lastActivity: _parseDate(doc.data()['lastActivity']),
        ),
      );
      final agg = aggregateTribeContributors(contributors: records, now: now);

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
            'totalXp': agg.totalXp,
            'totalHabitsCompleted': agg.totalHabitsCompleted,
            'totalChallengesCompleted': agg.totalChallengesCompleted,
            'activeMembers': agg.activeMembers,
            'newMembersThisWeek': agg.newMembers,
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