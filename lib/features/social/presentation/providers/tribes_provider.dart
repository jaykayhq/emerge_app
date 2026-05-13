import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/core/drift/database.dart';
import 'package:emerge_app/core/drift_repositories/drift_tribe_repository.dart';
import 'package:emerge_app/core/sync/sync_providers.dart';
import 'package:emerge_app/features/social/data/repositories/tribe_repository.dart';
import 'package:emerge_app/features/social/data/services/tribe_stats_service.dart';
import 'package:emerge_app/features/social/domain/models/tribe.dart';
import 'package:emerge_app/features/social/domain/services/club_activity_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final tribeRepositoryProvider = Provider<TribeRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final syncEngine = ref.watch(enhancedSyncEngineProvider);
  return DriftTribeRepository(db, syncEngine);
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
  return repository.watchArchetypeClubs().map((list) {
    // Sort locally to avoid index requirements
    final sorted = List<Tribe>.from(list);
    sorted.sort((a, b) => (a.archetypeId ?? '').compareTo(b.archetypeId ?? ''));
    return sorted;
  });
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
          .snapshots()
          .map((snapshot) {
            final activities = snapshot.docs
                .map((doc) => doc.data())
                .toList();
            // Sort by timestamp descending client-side (avoids composite index requirement)
            activities.sort((a, b) {
              final aTs = a['timestamp'] as Timestamp?;
              final bTs = b['timestamp'] as Timestamp?;
              if (aTs == null && bTs == null) return 0;
              if (aTs == null) return 1;
              if (bTs == null) return -1;
              return bTs.compareTo(aTs);
            });
            return activities.take(20).toList();
          });
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

  return firestore.collection('tribes').doc(tribeId).snapshots().map((
    tribeDoc,
  ) {
    if (!tribeDoc.exists) {
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

    return TribeStats(
      memberCount: memberCount,
      totalXp: data['totalXp'] as int? ?? 0,
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TribeStats &&
        other.memberCount == memberCount &&
        other.totalXp == totalXp &&
        other.totalHabitsCompleted == totalHabitsCompleted &&
        other.totalChallengesCompleted == totalChallengesCompleted;
  }

  @override
  int get hashCode => Object.hash(
        memberCount,
        totalXp,
        totalHabitsCompleted,
        totalChallengesCompleted,
      );
}
