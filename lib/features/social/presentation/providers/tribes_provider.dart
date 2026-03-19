import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/features/social/data/repositories/tribe_repository.dart';
import 'package:emerge_app/features/social/data/services/tribe_stats_service.dart';
import 'package:emerge_app/features/social/domain/models/tribe.dart';
import 'package:emerge_app/features/social/domain/services/club_activity_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final tribeRepositoryProvider = Provider<TribeRepository>((ref) {
  return FirestoreTribeRepository(FirebaseFirestore.instance);
});

/// Provider for TribeStatsService - calculates real-time tribe statistics
final tribeStatsServiceProvider = Provider<TribeStatsService>((ref) {
  return TribeStatsService(firestore: FirebaseFirestore.instance);
});

/// Provider for SocialActivityService - logs user activities to archetype clubs and global feed.
final socialActivityServiceProvider = Provider<SocialActivityService>((ref) {
  return SocialActivityService(firestore: FirebaseFirestore.instance);
});

/// The user's archetype club — auto-joined based on their archetype.
final userClubProvider = FutureProvider.family<Tribe?, String>((
  ref,
  archetypeId,
) {
  final repository = ref.watch(tribeRepositoryProvider);
  return repository.getArchetypeClub(archetypeId);
});

/// All official archetype clubs (Real-time).
final allArchetypeClubsProvider = StreamProvider<List<Tribe>>((ref) {
  final repository = ref.watch(tribeRepositoryProvider);
  return repository.watchArchetypeClubs();
});

/// Real-time stream of top contributors for a given club.
///
/// Takes a [tribeId] as parameter and streams the contributors collection,
/// ordered by contributionCount descending, limited to 10 items.
final clubContributorsProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, tribeId) {
      final firestore = FirebaseFirestore.instance;

      return firestore
          .collection('tribes')
          .doc(tribeId)
          .collection('contributors')
          .orderBy('contributionCount', descending: true)
          .limit(10)
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
    });

/// Real-time stream of activity feed for a given club.
///
/// Takes a [tribeId] as parameter and streams the activity collection,
/// ordered by timestamp descending, limited to 20 items.
final clubActivityProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, tribeId) {
      final firestore = FirebaseFirestore.instance;

      return firestore
          .collection('tribes')
          .doc(tribeId)
          .collection('activity')
          .orderBy('timestamp', descending: true)
          .limit(20)
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
    });

/// Real-time stream of the global activity feed.
final globalActivityProvider = StreamProvider<List<Map<String, dynamic>>>((
  ref,
) {
  final firestore = FirebaseFirestore.instance;

  return firestore
      .collection('global_activities')
      .orderBy('timestamp', descending: true)
      .limit(30)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
});

/// Real-time stream of tribe aggregate stats (totalHabitsCompleted, etc.)
final tribeAggregateProvider =
    StreamProvider.family<Map<String, dynamic>, String>((ref, tribeId) {
      final firestore = FirebaseFirestore.instance;

      return firestore
          .collection('tribes')
          .doc(tribeId)
          .snapshots()
          .map((doc) => doc.data() ?? <String, dynamic>{});
    });

/// Real-time stream of calculated tribe stats with actual member count and total XP.
///
/// This provider calculates real values from the members array and user_stats,
/// overriding the seeded/static values in the tribe document.
final realTimeTribeStatsProvider = StreamProvider.family<TribeStats, String>((
  ref,
  tribeId,
) {
  final firestore = FirebaseFirestore.instance;

  return firestore.collection('tribes').doc(tribeId).snapshots().asyncMap((
    tribeDoc,
  ) async {
    if (!tribeDoc.exists) {
      debugPrint('🔍 Tribe $tribeId does not exist');
      return TribeStats(
        memberCount: 0,
        totalXp: 0,
        totalHabitsCompleted: 0,
        totalChallengesCompleted: 0,
      );
    }

    final data = tribeDoc.data()!;
    final members = data['members'] as List<dynamic>?;
    final memberCount = members?.length ?? 0;

    debugPrint('🔍 Tribe $tribeId: $memberCount members in array');

    // Calculate total XP from tribe members' user_stats
    int totalXp = 0;
    if (members != null && members.isNotEmpty) {
      final memberIds = members.cast<String>();
      debugPrint(
        '🔍 Querying XP for members: ${memberIds.take(5).toList()}...',
      );

      // Query user_stats for tribe members (batched due to Firestore 'in' query limit)
      const batchSize = 30;
      for (var i = 0; i < memberIds.length; i += batchSize) {
        final batch = memberIds.skip(i).take(batchSize).toList();
        final userStatsSnapshot = await firestore
            .collection('user_stats')
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        debugPrint(
          '🔍 Found ${userStatsSnapshot.docs.length} user_stats docs in batch',
        );

        for (final doc in userStatsSnapshot.docs) {
          final userData = doc.data();
          // Sum XP from avatarStats - only sum attribute XP fields
          final avatarStats = userData['avatarStats'] as Map<String, dynamic>?;
          if (avatarStats != null) {
            // Only sum the 6 attribute XP fields (exclude level, streak, attributeXp map)
            totalXp += avatarStats['strengthXp'] as int? ?? 0;
            totalXp += avatarStats['intellectXp'] as int? ?? 0;
            totalXp += avatarStats['vitalityXp'] as int? ?? 0;
            totalXp += avatarStats['creativityXp'] as int? ?? 0;
            totalXp += avatarStats['focusXp'] as int? ?? 0;
            totalXp += avatarStats['spiritXp'] as int? ?? 0;

            // Also sum any custom attribute XP from the attributeXp map
            final customAttributeXp =
                avatarStats['attributeXp'] as Map<String, dynamic>?;
            if (customAttributeXp != null) {
              for (final value in customAttributeXp.values) {
                if (value is int) totalXp += value;
              }
            }
          }
          // Also add direct totalXp if present (fallback)
          final directTotalXp = userData['totalXp'] as int?;
          if (directTotalXp != null) totalXp += directTotalXp;
        }
      }
      debugPrint('🔍 Calculated total XP: $totalXp');
    }

    return TribeStats(
      memberCount: memberCount,
      totalXp: totalXp,
      totalHabitsCompleted: data['totalHabitsCompleted'] as int? ?? 0,
      totalChallengesCompleted: data['totalChallengesCompleted'] as int? ?? 0,
    );
  });
});

/// Model for tribe statistics
class TribeStats {
  final int memberCount;
  final int totalXp;
  final int totalHabitsCompleted;
  final int totalChallengesCompleted;

  TribeStats({
    required this.memberCount,
    required this.totalXp,
    required this.totalHabitsCompleted,
    required this.totalChallengesCompleted,
  });
}
