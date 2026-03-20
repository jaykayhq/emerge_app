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

  /// Get active solo challenges from user challenges
  List<Challenge> get activeSoloChallenges {
    return userChallenges
        .where((c) => c.status == ChallengeStatus.active)
        .toList();
  }

  /// Get completed challenges from user challenges
  List<Challenge> get completedChallenges {
    return userChallenges
        .where((c) => c.status == ChallengeStatus.completed)
        .toList();
  }
}
