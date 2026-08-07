import 'package:emerge_app/features/social/data/services/affiliate_reward_service.dart';
import 'package:emerge_app/features/social/domain/models/challenge.dart';
import 'package:emerge_app/features/social/domain/services/affiliate_reward.dart';
import 'package:flutter_test/flutter_test.dart';

const _challenge = Challenge(
  id: 'c1',
  title: '30-Day Run',
  description: 'desc',
  imageUrl: '',
  reward: 'Test Reward',
  participants: 10,
  daysLeft: 0,
  totalDays: 7,
  currentDay: 7,
  status: ChallengeStatus.completed,
  xpReward: 250,
  steps: [],
  category: ChallengeCategory.fitness,
  sponsor: 'Nike',
  isSponsored: true,
  affiliateUrl: 'https://example.com/reward',
  rewardDescription: '20% off Nike',
  affiliateNetwork: AffiliateNetwork.direct,
);

void main() {
  test('logs affiliate_link_clicked then opens the url', () async {
    Uri? openedUri;
    String? loggedName;
    Map<String, Object>? loggedParams;
    final service = AffiliateRewardService(
      openUrl: (uri) async {
        openedUri = uri;
        return true;
      },
      logEvent: (name, params) async {
        loggedName = name;
        loggedParams = params;
      },
    );

    final ok = await service.claimReward(
      challenge: _challenge,
      reward: affiliateRewardFor(_challenge)!,
      userId: 'user_1',
    );

    expect(ok, isTrue);
    expect(openedUri, Uri.parse('https://example.com/reward'));
    expect(loggedName, 'affiliate_link_clicked');
    expect(loggedParams!['challenge_id'], 'c1');
    expect(loggedParams!['challenge_name'], '30-Day Run');
    expect(loggedParams!['partner_name'], 'Nike');
    expect(loggedParams!['affiliate_network'], 'direct');
    expect(loggedParams!['has_affiliate'], true);
    expect(loggedParams!['user_id'], 'user_1');
  });

  test('does not open urls with non-http schemes', () async {
    var opened = false;
    final service = AffiliateRewardService(
      openUrl: (uri) async {
        opened = true;
        return true;
      },
      logEvent: (name, params) async {},
    );
    const reward = AffiliateReward(
      url: 'javascript:alert(1)',
      title: 'x',
      sponsor: 'y',
      network: AffiliateNetwork.none,
    );

    final ok = await service.claimReward(challenge: _challenge, reward: reward);

    expect(ok, isFalse);
    expect(opened, isFalse);
  });

  test('returns false when the opener fails', () async {
    final service = AffiliateRewardService(
      openUrl: (uri) async => false,
      logEvent: (name, params) async {},
    );

    final ok = await service.claimReward(
      challenge: _challenge,
      reward: affiliateRewardFor(_challenge)!,
    );

    expect(ok, isFalse);
  });
}
