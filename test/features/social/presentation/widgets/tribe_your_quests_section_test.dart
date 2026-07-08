import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:emerge_app/features/social/domain/models/challenge.dart';
import 'package:emerge_app/features/social/presentation/providers/challenge_provider.dart';
import 'package:emerge_app/features/social/presentation/widgets/tribe_your_quests_section.dart';

Challenge _challenge({
  required String id,
  required String title,
  required int currentDay,
  required ChallengeStatus status,
}) =>
    Challenge(
      id: id,
      title: title,
      description: '',
      imageUrl: '',
      reward: '',
      participants: 0,
      daysLeft: 0,
      totalDays: 30,
      currentDay: currentDay,
      status: status,
      xpReward: 0,
      steps: const [],
    );

Widget buildTest({
  List<Challenge>? userChallenges,
  Future<List<Challenge>>? userChallengesAsync,
  GoRouter? router,
}) {
  return ProviderScope(
    overrides: [
      userChallengesProvider.overrideWith(
        (ref) =>
            userChallengesAsync ?? Future.value(userChallenges ?? <Challenge>[]),
      ),
    ],
    child: MaterialApp.router(
      routerConfig: router ??
          GoRouter(
            initialLocation: '/',
            routes: [
              GoRoute(
                path: '/',
                builder: (_, _) => const Scaffold(
                  body: TribeYourQuestsSection(),
                ),
              ),
            ],
          ),
    ),
  );
}

void main() {
  testWidgets('header reads YOUR QUESTS', (tester) async {
    await tester.pumpWidget(buildTest());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('YOUR QUESTS'), findsOneWidget);
  });

  testWidgets('renders only active challenges, excludes completed/featured',
      (tester) async {
    await tester.pumpWidget(buildTest(userChallenges: [
      _challenge(
          id: 'a1', title: 'Active One', currentDay: 5, status: ChallengeStatus.active),
      _challenge(
          id: 'c1',
          title: 'Completed One',
          currentDay: 30,
          status: ChallengeStatus.completed),
    ]));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Active One'), findsOneWidget);
    expect(find.text('Completed One'), findsNothing);
  });

  testWidgets('empty state prompts to pick one below', (tester) async {
    await tester.pumpWidget(buildTest());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.textContaining('No quests in progress'), findsOneWidget);
  });

  testWidgets('shows loading indicator while pending', (tester) async {
    await tester.pumpWidget(
      buildTest(userChallengesAsync: Completer<List<Challenge>>().future),
    );
    await tester.pump();
    // While the future has not completed, a spinner is shown.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
