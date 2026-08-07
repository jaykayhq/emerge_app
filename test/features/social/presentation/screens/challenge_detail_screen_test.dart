import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/features/social/presentation/screens/challenge_detail_screen.dart';
import 'package:emerge_app/features/social/domain/models/challenge.dart';
import 'package:emerge_app/features/social/data/services/affiliate_reward_service.dart';
import 'package:emerge_app/features/social/presentation/providers/challenge_provider.dart';

void main() {
  final testChallenge = Challenge(
    id: 'test_1',
    title: 'Test Challenge',
    description: 'A test challenge description',
    imageUrl: '',
    reward: 'Test Reward',
    participants: 100,
    daysLeft: 10,
    totalDays: 7,
    currentDay: 3,
    status: ChallengeStatus.featured,
    xpReward: 250,
    steps: [
      ChallengeStep(day: 1, title: 'Step One', description: 'Do step one'),
      ChallengeStep(day: 2, title: 'Step Two', description: 'Do step two'),
    ],
  );

  testWidgets('ChallengeDetailScreen renders challenge details', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: ChallengeDetailScreen(challenge: testChallenge),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Test Challenge'), findsOneWidget);
    expect(find.text('A test challenge description'), findsOneWidget);
    expect(find.text('JOURNEY LOG'), findsOneWidget);
    expect(find.text('Step One'), findsOneWidget);
    expect(find.text('Step Two'), findsOneWidget);
    expect(find.text('JOIN QUEST'), findsOneWidget);
  });

  testWidgets('shows sponsor reward card with claim button for completed sponsored challenge', (
    tester,
  ) async {
    final sponsored = Challenge(
      id: 'test_sponsored',
      title: 'Sponsored Challenge',
      description: 'A sponsored challenge',
      imageUrl: '',
      reward: 'Voucher',
      participants: 50,
      daysLeft: 0,
      totalDays: 7,
      currentDay: 7,
      status: ChallengeStatus.completed,
      xpReward: 250,
      steps: [
        ChallengeStep(day: 1, title: 'Step One', description: 'Do step one'),
      ],
      category: ChallengeCategory.fitness,
      sponsor: 'Nike',
      isSponsored: true,
      affiliateUrl: 'https://example.com/reward',
      rewardDescription: '20% off Nike',
      affiliateNetwork: AffiliateNetwork.direct,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: ChallengeDetailScreen(challenge: sponsored),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('SPONSOR REWARD'), findsOneWidget);
    expect(find.text('20% off Nike'), findsOneWidget);
    expect(find.text('CLAIM REWARD'), findsOneWidget);
  });

  testWidgets('shows locked sponsor reward for an unfinished sponsored challenge', (
    tester,
  ) async {
    final inProgress = Challenge(
      id: 'test_sponsored_active',
      title: 'Sponsored Challenge',
      description: 'A sponsored challenge',
      imageUrl: '',
      reward: 'Voucher',
      participants: 50,
      daysLeft: 4,
      totalDays: 7,
      currentDay: 2,
      status: ChallengeStatus.active,
      xpReward: 250,
      steps: [
        ChallengeStep(day: 1, title: 'Step One', description: 'Do step one'),
      ],
      category: ChallengeCategory.fitness,
      sponsor: 'Nike',
      isSponsored: true,
      affiliateUrl: 'https://example.com/reward',
      rewardDescription: '20% off Nike',
      affiliateNetwork: AffiliateNetwork.direct,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: ChallengeDetailScreen(challenge: inProgress),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Complete this quest to claim your reward'), findsOneWidget);
    expect(find.text('CLAIM REWARD'), findsNothing);
  });

  testWidgets('shows failure snackbar when the reward link cannot be opened', (
    tester,
  ) async {
    final sponsored = Challenge(
      id: 'test_sponsored',
      title: 'Sponsored Challenge',
      description: 'A sponsored challenge',
      imageUrl: '',
      reward: 'Voucher',
      participants: 50,
      daysLeft: 0,
      totalDays: 7,
      currentDay: 7,
      status: ChallengeStatus.completed,
      xpReward: 250,
      steps: [
        ChallengeStep(day: 1, title: 'Step One', description: 'Do step one'),
      ],
      category: ChallengeCategory.fitness,
      sponsor: 'Nike',
      isSponsored: true,
      affiliateUrl: 'https://example.com/reward',
      rewardDescription: '20% off Nike',
      affiliateNetwork: AffiliateNetwork.direct,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          affiliateRewardServiceProvider.overrideWithValue(
            AffiliateRewardService(
              openUrl: (uri) async => false,
              logEvent: (name, params) async {},
            ),
          ),
        ],
        child: MaterialApp(
          home: ChallengeDetailScreen(challenge: sponsored),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 2));

    await tester.tap(find.text('CLAIM REWARD'));
    await tester.pump();

    expect(find.text('Could not open the reward link. Try again later.'), findsOneWidget);
  });

  testWidgets('duplicate claim taps log a single affiliate click', (tester) async {
    final sponsored = Challenge(
      id: 'test_sponsored',
      title: 'Sponsored Challenge',
      description: 'A sponsored challenge',
      imageUrl: '',
      reward: 'Voucher',
      participants: 50,
      daysLeft: 0,
      totalDays: 7,
      currentDay: 7,
      status: ChallengeStatus.completed,
      xpReward: 250,
      steps: [
        ChallengeStep(day: 1, title: 'Step One', description: 'Do step one'),
      ],
      category: ChallengeCategory.fitness,
      sponsor: 'Nike',
      isSponsored: true,
      affiliateUrl: 'https://example.com/reward',
      rewardDescription: '20% off Nike',
      affiliateNetwork: AffiliateNetwork.direct,
    );
    final completer = Completer<bool>();
    var clickCount = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          affiliateRewardServiceProvider.overrideWithValue(
            AffiliateRewardService(
              openUrl: (uri) {
                clickCount++;
                return completer.future;
              },
              logEvent: (name, params) async {},
            ),
          ),
        ],
        child: MaterialApp(
          home: ChallengeDetailScreen(challenge: sponsored),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 2));

    await tester.tap(find.text('CLAIM REWARD'));
    await tester.pump();
    await tester.tap(find.text('CLAIM REWARD'));
    await tester.pump();
    completer.complete(true);
    await tester.pump();

    expect(clickCount, 1);
  });
}
