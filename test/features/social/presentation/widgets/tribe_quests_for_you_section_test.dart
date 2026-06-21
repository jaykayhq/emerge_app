import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:emerge_app/features/social/domain/models/challenge.dart';
import 'package:emerge_app/features/social/presentation/providers/challenge_bundle_provider.dart';
import 'package:emerge_app/features/social/presentation/widgets/tribe_quests_for_you_section.dart';

Challenge _challenge({
  required String id,
  required String title,
  required int currentDay,
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
      status: ChallengeStatus.featured,
      xpReward: 0,
      steps: const [],
    );

Widget buildTest({Challenge? daily, Challenge? weekly}) {
  return ProviderScope(
    overrides: [
      dailyQuestFromBundleProvider.overrideWith((ref) => daily),
      weeklySpotlightFromBundleProvider.overrideWith((ref) => weekly),
    ],
    child: MaterialApp.router(
      routerConfig: GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: TribeQuestsForYouSection()),
          ),
        ],
      ),
    ),
  );
}

void main() {
  testWidgets('header reads QUESTS FOR YOU', (tester) async {
    await tester.pumpWidget(buildTest());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('QUESTS FOR YOU'), findsOneWidget);
  });

  testWidgets('renders daily and weekly featured quests', (tester) async {
    await tester.pumpWidget(buildTest(
      daily: _challenge(id: 'd1', title: 'Daily Quest', currentDay: 0),
      weekly: _challenge(id: 'w1', title: 'Weekly Spotlight', currentDay: 0),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Daily Quest'), findsOneWidget);
    expect(find.text('Weekly Spotlight'), findsOneWidget);
  });

  testWidgets('empty state when both null', (tester) async {
    await tester.pumpWidget(buildTest());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.textContaining('No featured quests right now'), findsOneWidget);
  });
}
