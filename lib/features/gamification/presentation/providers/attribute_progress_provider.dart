import 'package:emerge_app/core/constants/gamification_constants.dart';
import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'attribute_progress_provider.g.dart';

/// Attribute progress data from actual avatarStats
/// Shows how much each attribute contributes to the overall level
class AttributeProgress {
  final String attribute;
  final int totalXp;
  final int currentLevel;
  final int overallLevel;
  final int
  contributionToOverall; // How much XP this attribute contributes to current level progress
  final int xpForNextLevel;
  final double
  contributionPercent; // Percentage of total XP this attribute provides

  const AttributeProgress({
    required this.attribute,
    required this.totalXp,
    required this.currentLevel,
    required this.overallLevel,
    required this.contributionToOverall,
    required this.xpForNextLevel,
    required this.contributionPercent,
  });

  /// Progress percentage toward next level (0.0 to 1.0)
  double get progressPercent => contributionToOverall / xpForNextLevel;

  @override
  String toString() =>
      'AttributeProgress(attribute: $attribute, totalXp: $totalXp, level: $currentLevel, contributes: $contributionToOverall to overall level $overallLevel)';
}

/// Provider that calculates attribute progress from actual avatarStats
///
/// This provider reads the real XP values from the user's avatarStats
/// and calculates how much each attribute contributes to the overall level.
@riverpod
Map<String, AttributeProgress> attributeProgressFromHabits(Ref ref) {
  // Watch user stats stream for real-time updates
  final userAsync = ref.watch(userStatsStreamProvider);

  // Return empty map if loading or error
  if (!userAsync.hasValue || userAsync.value == null) {
    return {};
  }

  final profile = userAsync.value!;
  final stats = profile.avatarStats;

  // Debug: Log the stats to see what we're getting
  AppLogger.d(
    'AttributeProgress: totalXp=${stats.totalXp}, level=${stats.level}',
  );
  AppLogger.d(
    'AttributeProgress: strengthXp=${stats.strengthXp}, intellectXp=${stats.intellectXp}, vitalityXp=${stats.vitalityXp}',
  );

  // Get total XP for level calculation
  final totalXp = stats.totalXp;
  final overallLevel = stats.level;

  // Calculate XP progress toward next level
  // Level 1: 0-499 XP, Level 2: 500-999 XP, etc.
  final xpInCurrentLevel = totalXp % GamificationConstants.xpPerLevel;
  final xpForNextLevel = GamificationConstants.xpPerLevel;

  final Map<String, AttributeProgress> progress = {};

  // Map each attribute's XP to progress data
  final attributes = {
    'strength': stats.strengthXp,
    'intellect': stats.intellectXp,
    'vitality': stats.vitalityXp,
    'creativity': stats.creativityXp,
    'focus': stats.focusXp,
    'spirit': stats.spiritXp,
  };

  AppLogger.d('AttributeProgress: Attributes map=$attributes');

  for (final entry in attributes.entries) {
    final attr = entry.key;
    final attrXp = entry.value;

    // Calculate individual attribute level
    final attrLevel = (attrXp / GamificationConstants.xpPerLevel).floor() + 1;

    // Calculate how much this attribute contributes to current overall level progress
    // This is the min of: attribute XP, and remaining XP needed for next level
    final contribution = attrXp < xpInCurrentLevel ? attrXp : xpInCurrentLevel;

    // Calculate percentage of total XP this attribute provides
    final contributionPercent = totalXp > 0 ? attrXp / totalXp : 0.0;

    progress[attr] = AttributeProgress(
      attribute: attr,
      totalXp: attrXp,
      currentLevel: attrLevel,
      overallLevel: overallLevel,
      contributionToOverall: contribution,
      xpForNextLevel: xpForNextLevel,
      contributionPercent: contributionPercent,
    );
  }

  return progress;
}

/// Provider for a specific attribute's progress
@riverpod
AttributeProgress? attributeProgress(Ref ref, String attribute) {
  final allProgress = ref.watch(attributeProgressFromHabitsProvider);
  return allProgress[attribute.toLowerCase()];
}
