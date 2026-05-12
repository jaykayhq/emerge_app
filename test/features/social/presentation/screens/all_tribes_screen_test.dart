import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/features/social/presentation/screens/all_tribes_screen.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_loading_skeleton.dart';
import 'package:emerge_app/features/social/domain/models/tribe.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';

void main() {
  testWidgets('AllTribesScreen displays list of tribes', (tester) async {
    final tribes = [
      Tribe(
        id: 'tribe-1',
        name: 'Tribe 1',
        description: 'Description 1',
        imageUrl: 'https://example.com/image1.png',
        memberCount: 10,
        ownerId: 'owner-1',
        tags: ['test'],
        levelRequirement: 1,
        rank: 1,
        totalXp: 1000,
        type: TribeType.official,
        archetypeId: 'scholar',
      ),
      Tribe(
        id: 'tribe-2',
        name: 'Tribe 2',
        description: 'Description 2',
        imageUrl: 'https://example.com/image2.png',
        memberCount: 20,
        ownerId: 'owner-2',
        tags: ['test'],
        levelRequirement: 1,
        rank: 2,
        totalXp: 2000,
        type: TribeType.official,
        archetypeId: 'athlete',
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allArchetypeClubsProvider.overrideWithValue(
            AsyncValue.data(tribes),
          ),
        ],
        child: const MaterialApp(
          home: AllTribesScreen(),
        ),
      ),
    );

    expect(find.text('TRIBE 1'), findsOneWidget);
    expect(find.text('TRIBE 2'), findsOneWidget);
  });

  testWidgets('AllTribesScreen shows loading state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allArchetypeClubsProvider.overrideWithValue(
            const AsyncValue.loading(),
          ),
        ],
        child: const MaterialApp(
          home: AllTribesScreen(),
        ),
      ),
    );

    expect(find.byType(EmergeLoadingSkeleton), findsOneWidget);
  });
}
