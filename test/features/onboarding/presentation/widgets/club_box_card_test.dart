import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/onboarding/presentation/widgets/club_box_card.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          // Mirrors the onboarding grid tile: a narrow, bounded box.
          child: SizedBox(width: 120, height: 160, child: child),
        ),
      ),
    );
  }

  testWidgets('renders with a long activity status without layout errors', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        ClubBoxCard(
          title: 'Sunrise Ritual',
          memberCount: 1240,
          activityStatus: '🔥 Active right now with a very long status string',
          typeTag: 'ARCHETYPE',
          onTap: () {},
        ),
      ),
    );

    // Regression for the unbounded-width crash: the info Row used Flexible
    // inside a FittedBox (which hands its child unbounded width), throwing
    // "RenderFlex children have non-zero flex but incoming width constraints
    // are unbounded" every frame. Any exception here fails the test.
    expect(tester.takeException(), isNull);
    expect(find.text('Sunrise Ritual'), findsOneWidget);
  });

  testWidgets('renders with the short default status too', (tester) async {
    await tester.pumpWidget(
      wrap(
        ClubBoxCard(
          title: 'Night Owls',
          memberCount: 88,
          activityStatus: '🌙 Quiet',
          typeTag: 'CREATOR',
          onTap: () {},
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Night Owls'), findsOneWidget);
  });

  testWidgets('forwards taps to onTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      wrap(
        ClubBoxCard(
          title: 'Sunrise Ritual',
          memberCount: 1240,
          activityStatus: '🌙 Quiet',
          typeTag: 'ARCHETYPE',
          onTap: () => tapped = true,
        ),
      ),
    );

    await tester.tap(find.text('Sunrise Ritual'));
    expect(tapped, isTrue);
  });

  testWidgets('renders bundled asset emblem when imageUrl is an assets path', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        ClubBoxCard(
          title: 'Morning Warriors',
          imageUrl: 'assets/images/clubs/morning_warriors.webp',
          memberCount: 120,
          activityStatus: '🔥 Active',
          typeTag: 'ARCHETYPE',
          onTap: () => {},
        ),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    expect(
      (image.image as AssetImage).assetName,
      'assets/images/clubs/morning_warriors.webp',
    );
  });
}
