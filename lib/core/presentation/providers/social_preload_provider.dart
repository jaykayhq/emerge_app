import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/social/presentation/providers/challenge_bundle_provider.dart';
import 'package:emerge_app/features/social/presentation/providers/friend_provider.dart';
import 'package:emerge_app/features/social/presentation/providers/friends_leaderboard_provider.dart';
import 'package:emerge_app/features/social/presentation/providers/leaderboard_provider.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Comprehensive social data preloader for World Reveal screen
///
/// Preloads ALL social data during the 8-second animation sequence:
/// - Friends list + leaderboard (live XP from user_stats)
/// - Tribes/clubs + stats + contributors + activity
/// - Challenges (weekly spotlight, daily quest, archetype challenges)
/// - Global activity feed
///
/// COST ANALYSIS (per user, per day):
/// - Friends: ~1 read per friend (cached)
/// - Tribes: ~10-20 reads for all tribes + stats
/// - Challenges: ~3-5 reads
/// - Activity: ~1 read
/// Total: ~20-30 reads/day = ~$0.01-0.02 per 1000 users/month
///
/// All results are cached by Riverpod + Firestore, so navigating to these
/// screens later is instant with NO additional reads.
final socialDataPreloadProvider = FutureProvider<void>((ref) async {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return;

  // Get user profile first (needed for archetype-based queries)
  final profile = await ref.read(userStatsStreamProvider.future);
  if (profile.uid.isEmpty) return;

  // ==================== FRIENDS DATA ====================
  // Friends list (for friends screen + leaderboard)
  ref.listen(partnersListProvider, (previous, next) {});

  // Friends leaderboard with LIVE XP from user_stats
  ref.listen(friendsLeaderboardProvider, (previous, next) {});

  // Pending partner requests
  ref.listen(pendingPartnerRequestsProvider, (previous, next) {});

  // ==================== TRIBES/CLUBS DATA ====================
  // All archetype clubs (for world leaderboard)
  final tribes = await ref.read(allArchetypeClubsProvider.future);

  // User's archetype club
  ref.read(userClubProvider(profile.archetype.name).future);

  // Real-time stats for each tribe (total XP, member count)
  for (final tribe in tribes) {
    ref.read(realTimeTribeStatsProvider(tribe.id).future);
    // Club leaderboard (if exists)
    ref.read(clubLeaderboardProvider(tribe.id));
    // Club contributors
    ref.read(clubContributorsProvider(tribe.id));
    // Club activity feed
    ref.read(clubActivityProvider(tribe.id));
  }

  // Tribe aggregate stats
  for (final tribe in tribes) {
    ref.read(tribeAggregateProvider(tribe.id));
  }

  // ==================== CHALLENGES DATA ====================
  // Challenge bundle (includes: weekly spotlight, daily quest, archetype challenges, user challenges)
  ref.read(challengeBundleProvider.future);

  // Weekly spotlight specifically
  ref.read(weeklySpotlightFromBundleProvider);

  // Daily quest specifically
  ref.read(dailyQuestFromBundleProvider);

  // ==================== GLOBAL FEED ====================
  // Global activity feed
  ref.listen(globalActivityProvider, (previous, next) {});
});

/// Backward compatibility alias
final leaderboardPreloadProvider = socialDataPreloadProvider;
