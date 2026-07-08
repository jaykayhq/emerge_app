import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/features/social/presentation/screens/challenge_detail_screen.dart';
import 'package:emerge_app/features/social/domain/models/challenge.dart';

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
}
