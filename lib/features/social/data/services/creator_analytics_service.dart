// lib/features/social/data/services/creator_analytics_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fpdart/fpdart.dart';
import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/features/social/domain/models/creator_analytics.dart';
import 'package:emerge_app/features/social/domain/services/tribe_aggregates.dart';

/// Aggregates live creator analytics from rules-compliant Firestore sources.
///
/// Reads ONLY:
/// - `tribes/{tribeId}` and `tribes/{tribeId}/contributors/*` (auth read)
/// - `blueprints` and `challenges` (public read)
///
/// Never reads `user_stats` (owner-only in firestore.rules).
class CreatorAnalyticsService {
  final FirebaseFirestore _firestore;

  CreatorAnalyticsService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<Either<Failure, CreatorAnalytics>> getCreatorAnalytics({
    required String uid,
    required String tribeId,
  }) async {
    if (uid.isEmpty || tribeId.isEmpty) {
      return const Left(ServerFailure('Missing creator or tribe'));
    }
    try {
      final tribeDoc = await _firestore.collection('tribes').doc(tribeId).get();
      final tribeData = tribeDoc.data() ?? const <String, dynamic>{};
      final tribeName = tribeData['name'] as String? ?? '';
      final memberCount = (tribeData['memberCount'] as num?)?.toInt() ?? 0;

      final contributors =
          await _firestore
              .collection('tribes')
              .doc(tribeId)
              .collection('contributors')
              .get();

      final now = DateTime.now().toUtc();
      final records = <ContributorRecord>[];
      final memberRows = <MemberStat>[];

      for (final doc in contributors.docs) {
        final data = doc.data();
        final xp = _int(data['totalXpContributed']);
        final habits = _int(data['totalHabitsCompleted']);
        final challenges = _int(data['totalChallengesCompleted']);
        final joinedAt = _parseDate(data['joinedAt']);
        final lastActivity = _parseDate(data['lastActivity']);

        records.add(
          ContributorRecord(
            totalXpContributed: xp,
            totalHabitsCompleted: habits,
            totalChallengesCompleted: challenges,
            joinedAt: joinedAt,
            lastActivity: lastActivity,
          ),
        );

        if (xp > 0 && data['userName'] != null) {
          memberRows.add(MemberStat(
            userId: doc.id,
            name: data['userName'] as String,
            xp: xp,
            habitsCompleted: habits,
          ));
        }
      }
      final agg = aggregateTribeContributors(
        contributors: records,
        now: now,
      );
      final totalXp = agg.totalXp;
      final totalHabits = agg.totalHabitsCompleted;
      final totalChallenges = agg.totalChallengesCompleted;
      final newMembers = agg.newMembers;
      final activeMembers = agg.activeMembers;

      memberRows.sort((a, b) => b.xp.compareTo(a.xp));
      final topMembers = memberRows.take(10).toList();

      // Blueprints authored by this creator
      final blueprintQuery = await _firestore
          .collection('blueprints')
          .where('creatorUserId', isEqualTo: uid)
          .get();
      final blueprintStats = blueprintQuery.docs.map((doc) {
        final data = doc.data();
        final habits = data['habits'] as List<dynamic>? ?? const [];
        return BlueprintStat(
          id: doc.id,
          title: data['title'] as String? ?? 'Untitled',
          adoptionCount: _int(data['adoptionCount']),
          habitCount: habits.length,
        );
      }).toList();

      // Challenges published by this creator
      final challengeQuery = await _firestore
          .collection('challenges')
          .where('createdBy', isEqualTo: uid)
          .get();
      final challengeStats = challengeQuery.docs.map((doc) {
        final data = doc.data();
        return ChallengeStat(
          id: doc.id,
          title: data['title'] as String? ?? 'Untitled',
          participants: _int(data['participants']),
          status: data['status'] as String? ?? 'active',
          xpReward: _int(data['xpReward']),
        );
      }).toList();

      final activeRate = memberCount > 0 ? activeMembers / memberCount : 0.0;

      return Right(CreatorAnalytics(
        tribeId: tribeId,
        tribeName: tribeName,
        memberCount: memberCount,
        totalXp: totalXp,
        totalHabitsCompleted: totalHabits,
        totalChallengesCompleted: totalChallenges,
        newMembersThisWeek: newMembers,
        activeMembers: activeMembers,
        activeRate: activeRate,
        blueprintStats: blueprintStats,
        topMembers: topMembers,
        challengeStats: challengeStats,
      ));
    } catch (e) {
      return Left(ServerFailure('Could not load analytics: $e'));
    }
  }

  int _int(dynamic v) => (v as num?)?.toInt() ?? 0;

  DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is String) return DateTime.tryParse(v);
    return null;
  }
}