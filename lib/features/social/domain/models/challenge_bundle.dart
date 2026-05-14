import 'package:emerge_app/features/social/domain/models/challenge.dart';

/// Bundled challenge data for efficient single-fetch loading
/// Used to prevent multiple rebuild waves in ChallengesScreen
class ChallengeBundleData {
  final Challenge? weeklySpotlight;
  final Challenge? dailyQuest;
  final List<Challenge> userChallenges;
  final List<Challenge> archetypeChallenges;
  final List<Challenge> featuredChallenges;

  const ChallengeBundleData({
    required this.weeklySpotlight,
    required this.dailyQuest,
    required this.userChallenges,
    required this.archetypeChallenges,
    this.featuredChallenges = const [],
  });

  /// Returns an empty bundle for loading/error states
  factory ChallengeBundleData.empty() {
    return const ChallengeBundleData(
      weeklySpotlight: null,
      dailyQuest: null,
      userChallenges: [],
      archetypeChallenges: [],
      featuredChallenges: [],
    );
  }

  /// Get active solo challenges from user challenges (excluding daily/weekly)
  List<Challenge> get activeSoloChallenges {
    return userChallenges.where((c) {
      if (c.status != ChallengeStatus.active) return false;
      // Exclude daily quest and weekly spotlight from solo section
      if (dailyQuest != null && c.id == dailyQuest!.id) return false;
      if (weeklySpotlight != null && c.id == weeklySpotlight!.id) return false;
      return true;
    }).toList();
  }

  /// Whether the user has already joined the daily quest
  bool get isDailyQuestJoined =>
      dailyQuest != null && userChallenges.any((c) => c.id == dailyQuest!.id);

  /// Whether the user has already joined the weekly spotlight
  bool get isWeeklySpotlightJoined =>
      weeklySpotlight != null &&
      userChallenges.any((c) => c.id == weeklySpotlight!.id);

  /// The active daily quest from user's joined challenges (if joined)
  Challenge? get activeDailyChallenge {
    if (dailyQuest == null) return null;
    return userChallenges.cast<Challenge?>().firstWhere(
      (c) => c != null && c.id == dailyQuest!.id,
      orElse: () => null,
    );
  }

  /// The active weekly spotlight from user's joined challenges (if joined)
  Challenge? get activeWeeklyChallenge {
    if (weeklySpotlight == null) return null;
    return userChallenges.cast<Challenge?>().firstWhere(
      (c) => c != null && c.id == weeklySpotlight!.id,
      orElse: () => null,
    );
  }

  /// Get completed challenges from user challenges
  List<Challenge> get completedChallenges {
    return userChallenges
        .where((c) => c.status == ChallengeStatus.completed)
        .toList();
  }
}
