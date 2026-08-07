import 'package:emerge_app/features/social/domain/models/challenge.dart';
import 'package:emerge_app/features/social/domain/services/affiliate_reward.dart';
import 'package:emerge_app/features/social/presentation/widgets/sponsor_reward_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const reward = AffiliateReward(
    url: 'https://example.com/reward',
    title: '20% off Nike',
    sponsor: 'Nike',
    network: AffiliateNetwork.direct,
  );

  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('shows reward title, sponsor and sponsor-reward label', (tester) async {
    await tester.pumpWidget(
      wrap(const SponsorRewardCard(reward: reward, claimable: false)),
    );
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('SPONSOR REWARD'), findsOneWidget);
    expect(find.text('20% off Nike'), findsOneWidget);
    expect(find.text('by Nike'), findsOneWidget);
  });

  testWidgets('shows claim button when claimable', (tester) async {
    await tester.pumpWidget(
      wrap(const SponsorRewardCard(reward: reward, claimable: true)),
    );
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('CLAIM REWARD'), findsOneWidget);
  });

  testWidgets('shows locked state when not claimable', (tester) async {
    await tester.pumpWidget(
      wrap(const SponsorRewardCard(reward: reward, claimable: false)),
    );
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('Complete this quest to claim your reward'), findsOneWidget);
  });

  testWidgets('fires onClaim when the claim button is tapped', (tester) async {
    var claimed = false;
    await tester.pumpWidget(
      wrap(
        SponsorRewardCard(
          reward: reward,
          claimable: true,
          onClaim: () => claimed = true,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 700));

    await tester.tap(find.text('CLAIM REWARD'));
    expect(claimed, isTrue);
  });
}
