// test/features/world_map/presentation/widgets/central_health_orb_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/world_map/presentation/widgets/central_health_orb.dart';

void main() {
  testWidgets('CentralHealthOrb tracks 7 taps for easter egg', (tester) async {
    int easterEggCount = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CentralHealthOrb(
          currentHealth: 50,
          maxHealth: 100,
          onEasterEggTriggered: () => easterEggCount++,
        ),
      ),
    ));

    // Wait for the shader to load and the CircularProgressIndicator to be replaced
    for (int i = 0; i < 50; i++) {
      if (find.byType(GestureDetector).evaluate().isNotEmpty) break;
      await tester.pump(const Duration(milliseconds: 50));
    }

    final orb = find.byType(GestureDetector).first;
    for (int i = 0; i < 7; i++) {
      await tester.tap(orb);
    }
    
    expect(easterEggCount, 1);
  });
}
