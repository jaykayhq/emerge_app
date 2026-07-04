import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/core/drift/database.dart';
import 'package:emerge_app/core/drift_repositories/repositories_barrel.dart';
import 'package:emerge_app/core/sync/sync_providers.dart';
import 'package:emerge_app/features/social/data/repositories/tribe_repository.dart'
    show TribeRepository;
import 'package:emerge_app/features/social/domain/models/tribe.dart';
import 'package:emerge_app/features/social/domain/services/club_activity_service.dart';
import 'package:emerge_app/features/social/presentation/providers/leaderboard_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final tribeRepositoryProvider = Provider<TribeRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final syncEngine = ref.watch(enhancedSyncEngineProvider);
  return DriftTribeRepository(db, syncEngine);
});

/// Provider for SocialActivityService - logs user activities to archetype clubs and global feed.
final socialActivityServiceProvider = Provider<SocialActivityService>((ref) {
  final syncEngine = ref.watch(enhancedSyncEngineProvider);
  final activityDao = ref.watch(tribeActivityDaoProvider);
  final leaderboardRepo = ref.watch(leaderboardRepositoryProvider);

  return SocialActivityService(
    syncEngine: syncEngine,
    activityDao: activityDao,
    leaderboardRepo: leaderboardRepo,
    // Partner lookup: read the actor's friends subcollection directly via
    // Firestore. We avoid depending on the friend repository here to break
    // a potential dependency cycle (the friend repo depends on this service).
    getPartnerIds: (userId) async {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('friends')
          .get();
      return snapshot.docs.map((d) => d.id).toList();
    },
  );
});

/// Active tribe override — when set, habit completions and XP contribute
/// to this tribe instead of the archetype-matched one. Null = auto-detect
/// by archetype.
class ActiveTribeId extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? tribeId) => state = tribeId;
}

final activeTribeIdProvider = NotifierProvider<ActiveTribeId, String?>(ActiveTribeId.new);

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
      final dao = ref.watch(leaderboardEntriesDaoProvider);
      return dao.watchLeaderboard(tribeId).map((rows) {
        return rows
            .take(10)
            .map(
              (r) => {
                'userId': r.userId,
                'id': r.userId,
                'userName': r.userName,
                'xp': r.xp,
                'contributionCount': r.xp,
                'level': r.level,
              },
            )
            .toList();
      });
    });

/// Real-time stream of activity feed for a given club.
///
/// Takes a [tribeId] as parameter and streams the activity collection,
/// ordered by timestamp descending, limited to 20 items.
final clubActivityProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, tribeId) {
      final repository = ref.watch(tribeRepositoryProvider);
      return repository.watchClubActivity(tribeId);
    });

/// Real-time stream of the global activity feed.
final globalActivityProvider = StreamProvider<List<Map<String, dynamic>>>((
  ref,
) {
  final repository = ref.watch(tribeRepositoryProvider);
  return repository.watchGlobalActivity();
});

/// Real-time stream of tribe aggregate stats (totalHabitsCompleted, etc.)
final tribeAggregateProvider =
    StreamProvider.family<Map<String, dynamic>, String>((ref, tribeId) {
      final repository = ref.watch(tribeRepositoryProvider);
      return repository.watchArchetypeClubs().map((list) {
        final tribe = list.firstWhere(
          (t) => t.id == tribeId,
          orElse: () => Tribe(
            id: tribeId,
            name: '',
            description: '',
            imageUrl: '',
            ownerId: '',
            tags: [],
            levelRequirement: 0,
            rank: 0,
            memberCount: 0,
            totalXp: 0,
          ),
        );
        return {
          'totalXp': tribe.totalXp,
          'memberCount': tribe.memberCount,
          'totalHabitsCompleted': tribe.totalHabitsCompleted,
          'totalChallengesCompleted': tribe.totalChallengesCompleted,
        };
      });
    });

/// Real-time stream of calculated tribe stats with actual member count and total XP.
///
/// This provider calculates real values from the members array and user_stats,
/// overriding the seeded/static values in the tribe document.
final realTimeTribeStatsProvider = StreamProvider.family<TribeStats, String>((
  ref,
  tribeId,
) {
  final repository = ref.watch(tribeRepositoryProvider);
  return repository.watchArchetypeClubs().map((list) {
    final tribe = list.firstWhere(
      (t) => t.id == tribeId,
      orElse: () => Tribe(
        id: tribeId,
        name: '',
        description: '',
        imageUrl: '',
        ownerId: '',
        tags: [],
        levelRequirement: 0,
        rank: 0,
        memberCount: 0,
        totalXp: 0,
      ),
    );
    return TribeStats(
      memberCount: tribe.memberCount,
      totalXp: tribe.totalXp,
      totalHabitsCompleted: tribe.totalHabitsCompleted,
      totalChallengesCompleted: tribe.totalChallengesCompleted,
    );
  });
});

/// Global aggregate stats across all archetype tribes
final globalAggregateStatsProvider = StreamProvider<TribeStats>((ref) {
  final repository = ref.watch(tribeRepositoryProvider);
  return repository.watchArchetypeClubs().map((list) {
    int totalXp = 0;
    int totalHabits = 0;
    int totalChallenges = 0;
    int totalMembers = 0;
    for (final tribe in list) {
      totalXp += tribe.totalXp;
      totalHabits += tribe.totalHabitsCompleted;
      totalChallenges += tribe.totalChallengesCompleted;
      totalMembers += tribe.memberCount;
    }
    return TribeStats(
      memberCount: totalMembers,
      totalXp: totalXp,
      totalHabitsCompleted: totalHabits,
      totalChallengesCompleted: totalChallenges,
    );
  });
});

/// World leaderboard — merges local Drift tribe list with Firestore
/// tribe doc data so cross-user stats (XP, member count, habits) are
/// visible to all users. Emitted sorted by merged totalXp descending.
final worldLeaderboardProvider =
    StreamProvider<List<({Tribe tribe, TribeStats stats})>>((ref) {
      final dao = ref.watch(tribeStatsDaoProvider);
      final firestore = FirebaseFirestore.instance;
      final controller =
          StreamController<List<({Tribe tribe, TribeStats stats})>>();

      StreamSubscription<List<TribeStatsTableData>>? localSub;
      StreamSubscription<QuerySnapshot>? remoteSub;

      // Index local rows by tribeId for O(1) merge
      var localIndex = <String, TribeStatsTableData>{};
      var remoteDocs = <String, Map<String, dynamic>>{};

      void emitMerged() {

        // Build entries from Firestore (source of truth for cross-user data).
        // Merge local increments for the current user's own tribe.
        final entries = remoteDocs.entries
            .where((e) => e.value['type'] == TribeType.official.name)
            .map((e) {
              final tid = e.key;
              final remote = e.value;
              final local = localIndex[tid];

              final remoteXp = (remote['totalXp'] as num?)?.toInt() ?? 0;
              final remoteHabits =
                  (remote['totalHabitsCompleted'] as num?)?.toInt() ?? 0;
              final remoteChallenges =
                  (remote['totalChallengesCompleted'] as num?)?.toInt() ?? 0;
              final remoteMemberCount =
                  (remote['memberCount'] as num?)?.toInt() ?? 0;

              // Local may have higher XP if offline habit was completed but not yet synced
              final localXp = local?.totalXp ?? 0;
              final localHabits = local?.totalHabitsCompleted ?? 0;
              final localChallenges = local?.totalChallengesCompleted ?? 0;

              final totalXp = localXp > remoteXp ? localXp : remoteXp;
              final totalHabitsCompleted = localHabits > remoteHabits
                  ? localHabits
                  : remoteHabits;
              final totalChallengesCompleted =
                  localChallenges > remoteChallenges
                  ? localChallenges
                  : remoteChallenges;
              // memberCount always comes from Firestore (authoritative)
              final memberCount = remoteMemberCount;

              return (
                tribe: Tribe(
                  id: tid,
                  name: remote['name'] as String? ?? local?.tribeName ?? '',
                  description: remote['description'] as String? ?? '',
                  imageUrl: remote['imageUrl'] as String? ?? '',
                  ownerId: remote['ownerId'] as String? ?? '',
                  tags: List<String>.from(remote['tags'] ?? const []),
                  levelRequirement: 0,
                  rank: 0,
                  totalXp: totalXp,
                  memberCount: memberCount,
                  archetypeId:
                      remote['archetypeId'] as String? ?? local?.archetypeId,
                  isVerified: remote['isVerified'] as bool? ?? false,
                  totalHabitsCompleted: totalHabitsCompleted,
                  totalChallengesCompleted: totalChallengesCompleted,
                ),
                stats: TribeStats(
                  memberCount: memberCount,
                  totalXp: totalXp,
                  totalHabitsCompleted: totalHabitsCompleted,
                  totalChallengesCompleted: totalChallengesCompleted,
                ),
              );
            })
            .toList();

        entries.sort((a, b) => b.stats.totalXp.compareTo(a.stats.totalXp));

        if (!controller.isClosed) controller.add(entries);
      }

      localSub = dao.watchAll().listen((rows) {
        localIndex = {for (final r in rows) r.tribeId: r};
        emitMerged();
      }, onError: controller.addError);

      remoteSub = firestore
          .collection('tribes')
          .where('type', isEqualTo: TribeType.official.name)
          .snapshots()
          .listen(
            (snap) {
              remoteDocs = {for (final doc in snap.docs) doc.id: doc.data()};
              emitMerged();
            },
            onError: (Object err) {
              // Remote failure: just log, UI already showing local data
            },
          );

      controller.onCancel = () {
        localSub?.cancel();
        remoteSub?.cancel();
      };

      return controller.stream;
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
