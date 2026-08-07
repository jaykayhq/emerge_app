import 'package:emerge_app/features/social/domain/models/challenge.dart';

/// A claimable sponsor reward surfaced from a completed sponsored challenge.
class AffiliateReward {
  final String url;
  final String title;
  final String sponsor;
  final AffiliateNetwork network;

  const AffiliateReward({
    required this.url,
    required this.title,
    required this.sponsor,
    required this.network,
  });
}

/// Returns the claimable sponsor reward for [challenge], or null when the
/// challenge is not sponsored or has no affiliate link configured.
AffiliateReward? affiliateRewardFor(Challenge challenge) {
  if (!challenge.isSponsored) return null;
  final url = challenge.affiliateUrl?.trim() ?? '';
  if (url.isEmpty) return null;

  final rewardDescription = challenge.rewardDescription?.trim();
  final title = (rewardDescription != null && rewardDescription.isNotEmpty)
      ? rewardDescription
      : (challenge.reward.trim().isNotEmpty ? challenge.reward.trim() : 'Sponsor reward');

  final sponsorName = challenge.sponsor?.trim();
  final sponsor = (sponsorName != null && sponsorName.isNotEmpty)
      ? sponsorName
      : 'Sponsor';

  return AffiliateReward(
    url: url,
    title: title,
    sponsor: sponsor,
    network: challenge.affiliateNetwork,
  );
}

/// Whether a challenge's sponsor reward may be claimed (the quest is finished).
bool affiliateRewardClaimable(Challenge challenge) {
  return challenge.status == ChallengeStatus.completed ||
      (challenge.totalDays > 0 &&
          challenge.currentDay >= challenge.totalDays);
}
