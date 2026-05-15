import 'package:emerge_app/core/drift/database.dart';
import 'package:emerge_app/core/drift_repositories/repositories_barrel.dart';
import 'package:emerge_app/core/sync/sync_providers.dart';
import 'package:emerge_app/features/social/data/repositories/tribe_repository.dart' show TribeRepository;
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
  );
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
      final repository = ref.watch(tribeRepositoryProvider);
      return Stream.fromFuture(repository.getClubContributors(tribeId));
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
