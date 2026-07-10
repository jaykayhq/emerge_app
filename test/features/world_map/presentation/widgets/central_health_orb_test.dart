// test/features/world_map/presentation/widgets/central_health_orb_test.dart
import 'package:emerge_app/features/world_map/presentation/widgets/central_health_orb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildSubject(double health) => MaterialApp(
        home: Scaffold(
          body: CentralHealthOrb(
            currentHealth: health,
            maxHealth: 100,
            onTap: () {},
          ),
        ),
      );

  testWidgets('CentralHealthOrb renders health text', (tester) async {
    await tester.pumpWidget(buildSubject(85.5));
    expect(find.text('86 / 100'), findsOneWidget); // rounds to int
  });

  testWidgets('CentralHealthOrb responds to taps', (tester) async {
    bool tapped = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CentralHealthOrb(
          currentHealth: 100,
          maxHealth: 100,
          onTap: () => tapped = true,
        ),
      ),
    ));

    await tester.tap(find.byType(CentralHealthOrb));
    expect(tapped, isTrue);
  });
}
