import 'package:emerge_app/features/gamification/domain/entities/reward_catalog.dart';
import 'package:emerge_app/features/gamification/domain/entities/reward_item.dart';
import 'package:emerge_app/features/gamification/domain/entities/user_stats.dart';

/// Service for managing reward unlocks, equips, and eligibility checks.
class RewardService {
  /// Check which rewards a user is eligible to unlock based on current stats.
  List<RewardItem> getEligibleRewards(UserStats stats) {
    return RewardCatalog.all.where((reward) {
      // Already unlocked — skip
      if (stats.unlockedRewardIds.contains(reward.id)) return false;

      // IAP rewards are handled separately
      if (reward.source == RewardSource.purchase) return false;

      // Check level requirement
      if (reward.levelRequirement > stats.currentLevel) return false;

      // Check specific unlock conditions
      return _meetsUnlockCondition(reward, stats);
    }).toList();
  }

  /// Get all rewards a user has already unlocked.
  List<RewardItem> getUnlockedRewards(UserStats stats) {
    return stats.unlockedRewardIds
        .map((id) => RewardCatalog.getById(id))
        .where((r) => r != null)
        .cast<RewardItem>()
        .toList();
  }

  /// Get newly unlocked rewards (delta between eligible and already unlocked).
  List<RewardItem> checkForNewUnlocks(UserStats stats) {
    return getEligibleRewards(stats);
  }

  /// Unlock a reward and return updated stats.
  /// Returns null if already unlocked or not eligible.
  UserStats? unlockReward(UserStats stats, String rewardId) {
    // Already unlocked
    if (stats.unlockedRewardIds.contains(rewardId)) return null;

    final reward = RewardCatalog.getById(rewardId);
    if (reward == null) return null;

    // For non-purchase: verify eligibility
    if (reward.source != RewardSource.purchase) {
      if (!_meetsUnlockCondition(reward, stats)) return null;
      if (reward.levelRequirement > stats.currentLevel) return null;
    }

    return stats.copyWith(
      unlockedRewardIds: [...stats.unlockedRewardIds, rewardId],
    );
  }

  /// Equip a title. Returns updated stats, or null if not unlocked.
  UserStats? equipTitle(UserStats stats, String titleId) {
    if (!stats.unlockedRewardIds.contains(titleId)) return null;

    final reward = RewardCatalog.getById(titleId);
    if (reward == null || reward.type != RewardType.title) return null;

    return stats.copyWith(equippedTitleId: titleId);
  }

  /// Equip a nameplate. Returns updated stats, or null if not unlocked.
  UserStats? equipNameplate(UserStats stats, String nameplateId) {
    if (!stats.unlockedRewardIds.contains(nameplateId)) return null;

    final reward = RewardCatalog.getById(nameplateId);
    if (reward == null || reward.type != RewardType.nameplate) return null;

    return stats.copyWith(equippedNameplateId: nameplateId);
  }

  /// Equip an emblem (max 3). Returns updated stats, or null if not unlocked.
  UserStats? equipEmblem(UserStats stats, String emblemId) {
    if (!stats.unlockedRewardIds.contains(emblemId)) return null;

    final reward = RewardCatalog.getById(emblemId);
    if (reward == null || reward.type != RewardType.emblem) return null;

    final current = List<String>.from(stats.equippedEmblemIds);

    // If already equipped, remove it (toggle off)
    if (current.contains(emblemId)) {
      current.remove(emblemId);
      return stats.copyWith(equippedEmblemIds: current);
    }

    // Max 3 emblems — remove oldest if full
    if (current.length >= 3) {
      current.removeAt(0);
    }
    current.add(emblemId);

    return stats.copyWith(equippedEmblemIds: current);
  }

  /// Get the display value for the user's equipped title.
  String getEquippedTitleDisplay(UserStats stats) {
    if (stats.equippedTitleId == null) return '';
    final reward = RewardCatalog.getById(stats.equippedTitleId!);
    return reward?.displayValue ?? '';
  }

  /// Get the display key for the user's equipped nameplate.
  String getEquippedNameplateKey(UserStats stats) {
    if (stats.equippedNameplateId == null) return 'default';
    final reward = RewardCatalog.getById(stats.equippedNameplateId!);
    return reward?.displayValue ?? 'default';
  }

  // ===================== PRIVATE =====================

  bool _meetsUnlockCondition(RewardItem reward, UserStats stats) {
    switch (reward.id) {
      // Titles
      case 'title_initiate':
        return stats.currentXp > 0;
      case 'title_focused':
        return stats.currentStreak >= 3;
      case 'title_disciplined':
        return stats.currentXp >= 100; // ~10 habits completed
      case 'title_unyielding':
        return stats.currentStreak >= 7;
      case 'title_ironclad':
        return stats.currentStreak >= 14;
      case 'title_relentless':
        return stats.completedChallenges >= 3;
      case 'title_ascendant':
        return stats.currentLevel >= 5;
      case 'title_emerged':
        return stats.currentLevel >= 5; // And hasEmerged, checked elsewhere
      case 'title_forgemaster':
        return stats.currentStreak >= 30;
      case 'title_referrer':
        return stats.successfulReferrals >= 5;
      case 'title_eternal':
        return stats.currentStreak >= 100;

      // Nameplates
      case 'nameplate_default':
        return true;
      case 'nameplate_ember':
        return stats.currentStreak >= 7;
      case 'nameplate_aurora':
        return stats.currentLevel >= 5;

      // Emblems
      case 'emblem_first_step':
        return stats.currentXp > 0;
      case 'emblem_streak_7':
        return stats.currentStreak >= 7;
      case 'emblem_streak_30':
        return stats.currentStreak >= 30;
      case 'emblem_contract_keeper':
        return stats.completedContracts >= 3;

      default:
        return false;
    }
  }
}
