import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/gamification/domain/entities/reward_catalog.dart';
import 'package:emerge_app/features/gamification/domain/entities/reward_item.dart';
import 'package:emerge_app/features/gamification/domain/entities/user_stats.dart';
import 'package:emerge_app/features/gamification/domain/services/reward_service.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final rewardServiceProvider = Provider((ref) => RewardService());

/// Convert UserProfile (from Firestore stream) to a UserStats snapshot
/// for the reward service. The reward fields are stored in `user_stats`
/// doc alongside avatarStats.
UserStats _profileToRewardStats(UserProfile profile) {
  return UserStats(
    userId: profile.uid,
    currentXp: profile.avatarStats.totalXp,
    currentLevel: profile.effectiveLevel,
    currentStreak: profile.avatarStats.streak,
    // These fields will eventually be stored in Firestore user_stats doc:
    unlockedRewardIds: const [],
    equippedTitleId: null,
    equippedNameplateId: null,
    equippedEmblemIds: const [],
    completedChallenges: 0,
    completedContracts: 0,
    successfulReferrals: 0,
  );
}

/// Rewards the current user is eligible to unlock based on level/streak.
final eligibleRewardsProvider = Provider<List<RewardItem>>((ref) {
  final statsAsync = ref.watch(userStatsStreamProvider);
  final service = ref.watch(rewardServiceProvider);

  return statsAsync.when(
    data: (profile) =>
        service.getEligibleRewards(_profileToRewardStats(profile)),
    loading: () => [],
    error: (_, __) => [],
  );
});

/// The user's equipped title display string.
final equippedTitleDisplayProvider = Provider<String>((ref) {
  final statsAsync = ref.watch(userStatsStreamProvider);
  final service = ref.watch(rewardServiceProvider);

  return statsAsync.when(
    data: (profile) =>
        service.getEquippedTitleDisplay(_profileToRewardStats(profile)),
    loading: () => '',
    error: (_, __) => '',
  );
});

/// The user's equipped nameplate key.
final equippedNameplateKeyProvider = Provider<String>((ref) {
  final statsAsync = ref.watch(userStatsStreamProvider);
  final service = ref.watch(rewardServiceProvider);

  return statsAsync.when(
    data: (profile) =>
        service.getEquippedNameplateKey(_profileToRewardStats(profile)),
    loading: () => 'default',
    error: (_, __) => 'default',
  );
});

/// All rewards in the catalog, grouped by type, for the showcase screen.
final rewardsByTypeProvider = Provider<Map<RewardType, List<RewardItem>>>((
  ref,
) {
  return {
    RewardType.title: RewardCatalog.byType(RewardType.title),
    RewardType.nameplate: RewardCatalog.byType(RewardType.nameplate),
    RewardType.emblem: RewardCatalog.byType(RewardType.emblem),
  };
});
