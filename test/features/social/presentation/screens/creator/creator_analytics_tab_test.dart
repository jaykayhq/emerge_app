// test/features/social/presentation/screens/creator/creator_analytics_tab_test.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/social/domain/entities/creator_profile.dart';
import 'package:emerge_app/features/social/domain/models/creator_analytics.dart';
import 'package:emerge_app/features/social/presentation/providers/creator_analytics_provider.dart';
import 'package:emerge_app/features/social/presentation/providers/creator_provider.dart';
import 'package:emerge_app/features/social/presentation/screens/creator/creator_analytics_tab.dart';

Widget _buildTest({
  CreatorProfile? profile,
  required CreatorAnalytics analytics,
}) {
  return ProviderScope(
    overrides: [
      creatorProfileProvider.overrideWith((ref, uid) => Stream.value(profile)),
      creatorAnalyticsProvider.overrideWith((ref, arg) async => analytics),
    ],
    child: const MaterialApp(home: CreatorAnalyticsTab()),
  );
}

void main() {
  setUpAll(() async {
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
  });

  testWidgets('renders KPI values from analytics data', (tester) async {
    final analytics = CreatorAnalytics(
      tribeId: 't1',
      tribeName: 'The Forge',
      memberCount: 12,
      totalXp: 5000,
      totalHabitsCompleted: 120,
      totalChallengesCompleted: 4,
      newMembersThisWeek: 2,
      activeMembers: 8,
      activeRate: 0.67,
      blueprintStats: const [
        BlueprintStat(id: 'b1', title: 'Morning Stack', adoptionCount: 7, habitCount: 2),
      ],
      topMembers: const [
        MemberStat(userId: 'u1', name: 'Ada', xp: 3000, habitsCompleted: 40),
      ],
      challengeStats: const [
        ChallengeStat(id: 'c1', title: 'Read 30', participants: 5, status: 'active', xpReward: 100),
      ],
    );

    await tester.pumpWidget(_buildTest(
      profile: const CreatorProfile(userId: 'creator1', tribeId: 't1'),
      analytics: analytics,
    ));
    await tester.pumpAndSettle();

    expect(find.text('12'), findsOneWidget);
    expect(find.text('5.0K'), findsOneWidget); // _formatXp(5000)
    expect(find.text('120'), findsOneWidget);

    // ListView builds lazily — scroll to the lower sections.
    await tester.scrollUntilVisible(
      find.text('Morning Stack'),
      200,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('Morning Stack'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Ada'),
      200,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('Ada'), findsOneWidget);
  });

  testWidgets('shows empty state when creator has no tribe', (tester) async {
    await tester.pumpWidget(_buildTest(
      profile: const CreatorProfile(userId: 'creator1'), // tribeId null
      analytics: const CreatorAnalytics(tribeId: 't1', tribeName: ''),
    ));
    await tester.pumpAndSettle();
    expect(find.text('No Analytics Yet'), findsOneWidget);
  });
}