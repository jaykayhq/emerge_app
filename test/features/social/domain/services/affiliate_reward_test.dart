import 'package:emerge_app/features/social/domain/models/challenge.dart';
import 'package:emerge_app/features/social/domain/services/affiliate_reward.dart';
import 'package:flutter_test/flutter_test.dart';

Challenge _challenge({
  bool isSponsored = true,
  String? affiliateUrl = 'https://example.com/reward',
  String reward = 'Test Reward',
  String? rewardDescription,
  String? sponsor = 'Nike',
  AffiliateNetwork network = AffiliateNetwork.direct,
  int currentDay = 7,
  int totalDays = 7,
  ChallengeStatus status = ChallengeStatus.completed,
}) {
  return Challenge(
    id: 'c1',
    title: '30-Day Run',
    description: 'desc',
    imageUrl: '',
    reward: reward,
    participants: 10,
    daysLeft: 0,
    totalDays: totalDays,
    currentDay: currentDay,
    status: status,
    xpReward: 250,
    steps: const [],
    category: ChallengeCategory.fitness,
    sponsor: sponsor,
    isSponsored: isSponsored,
    affiliateUrl: affiliateUrl,
    rewardDescription: rewardDescription,
    affiliateNetwork: network,
  );
}

void main() {
  group('affiliateRewardFor', () {
    test('returns null for non-sponsored challenges', () {
      expect(affiliateRewardFor(_challenge(isSponsored: false)), isNull);
    });

    test('returns null when affiliate url is null or blank', () {
      expect(affiliateRewardFor(_challenge(affiliateUrl: null)), isNull);
      expect(affiliateRewardFor(_challenge(affiliateUrl: '   ')), isNull);
    });

    test('prefers rewardDescription over reward for the title', () {
      final reward = affiliateRewardFor(
        _challenge(rewardDescription: '20% off Nike', reward: 'Voucher'),
      );
      expect(reward, isNotNull);
      expect(reward!.title, '20% off Nike');
      expect(reward.sponsor, 'Nike');
      expect(reward.url, 'https://example.com/reward');
      expect(reward.network, AffiliateNetwork.direct);
    });

    test('falls back to reward text and generic sponsor', () {
      final reward = affiliateRewardFor(
        _challenge(rewardDescription: null, reward: 'Exclusive gear', sponsor: null),
      );
      expect(reward!.title, 'Exclusive gear');
      expect(reward.sponsor, 'Sponsor');
    });
  });

  group('affiliateRewardClaimable', () {
    test('true when status is completed', () {
      expect(
        affiliateRewardClaimable(_challenge(status: ChallengeStatus.completed)),
        isTrue,
      );
    });

    test('true when progress reached the final day while active', () {
      expect(
        affiliateRewardClaimable(
          _challenge(status: ChallengeStatus.active, currentDay: 7, totalDays: 7),
        ),
        isTrue,
      );
    });

    test('false while still in progress', () {
      expect(
        affiliateRewardClaimable(
          _challenge(status: ChallengeStatus.active, currentDay: 3, totalDays: 7),
        ),
        isFalse,
      );
    });
  });
}
