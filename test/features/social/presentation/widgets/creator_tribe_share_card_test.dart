// test/features/social/presentation/widgets/creator_tribe_share_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/social/presentation/widgets/creator_tribe_share_card.dart';

void main() {
  testWidgets('shares the tribe card on tap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CreatorTribeShareCard(
            tribeName: 'The Forge',
            creatorName: 'Ada',
            memberCount: 25,
            totalXp: 120000,
            totalHabitsCompleted: 900,
            totalChallengesCompleted: 12,
            onExport: () async => tapped = true,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Share tribe card'));
    await tester.pumpAndSettle();
    expect(tapped, isTrue);
  });
}