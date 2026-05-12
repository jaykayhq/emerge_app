import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/features/social/presentation/widgets/tribe_card.dart';
import 'package:emerge_app/features/social/domain/models/tribe.dart';
import 'package:emerge_app/features/social/presentation/providers/cached_tribe_stats_provider.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';

void main() {
  testWidgets('TribeCard displays tribe information', (tester) async {
    final tribe = Tribe(
      id: 'test-tribe-1',
      name: 'Test Tribe',
      description: 'A test tribe',
      imageUrl: 'https://example.com/image.png',
      memberCount: 10,
      ownerId: 'owner-1',
      tags: ['test'],
      levelRequirement: 1,
      rank: 1,
      totalXp: 1000,
      type: TribeType.userPublic,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: TribeCard(tribe: tribe),
          ),
        ),
      ),
    );

    expect(find.text('TEST TRIBE'), findsOneWidget);
    expect(find.text('A test tribe'), findsOneWidget);
  });

  testWidgets('TribeCard displays stats', (tester) async {
    final tribe = Tribe(
      id: 'test-tribe-1',
      name: 'Test Tribe',
      description: 'A test tribe',
      imageUrl: 'https://example.com/image.png',
      memberCount: 10,
      ownerId: 'owner-1',
      tags: ['test'],
      levelRequirement: 1,
      rank: 1,
      totalXp: 1000,
      type: TribeType.userPublic,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cachedTribeStatsProvider(tribe.id).overrideWithValue(
            AsyncValue.data(TribeStats(
              memberCount: 10,
              totalXp: 1000,
              totalHabitsCompleted: 50,
              totalChallengesCompleted: 5,
            )),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: TribeCard(tribe: tribe),
          ),
        ),
      ),
    );

    expect(find.text('10'), findsOneWidget);
    expect(find.text('1.0k'), findsOneWidget);
  });
}
