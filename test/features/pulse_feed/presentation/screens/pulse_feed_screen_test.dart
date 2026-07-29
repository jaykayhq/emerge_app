import 'package:emerge_app/features/pulse_feed/domain/models/pulse_feed_card.dart';
import 'package:emerge_app/features/pulse_feed/presentation/providers/pulse_feed_providers.dart';
import 'package:emerge_app/features/pulse_feed/presentation/screens/pulse_feed_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Force the empty state (no tribe selected) via provider override.
  final override = pulseFeedProvider.overrideWith((ref) => Stream.value(<PulseFeedCard>[]));

  testWidgets('empty state shows the three onboarding prompts', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [override],
        child: MaterialApp(home: PulseFeedScreen()),
      ),
    );
    await tester.pump(); // single frame; ring animates forever so no pumpAndSettle
    expect(find.text('Your Pulse is just getting started'), findsOneWidget);
    expect(find.text('Complete a habit'), findsOneWidget);
    expect(find.text('Explore tribes'), findsOneWidget);
    expect(find.text('Invite friends'), findsOneWidget);
  });

  testWidgets('pulse ring keeps a FIXED outer size across animation '
      'frames (heart still pulses, page does not bob)', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [override],
        child: MaterialApp(home: PulseFeedScreen()),
      ),
    );
    await tester.pump(); // single frame; ring animates forever so no pumpAndSettle

    // Across several animation frames the ring's outer SizedBox must stay
    // a constant 180x180. If it ever changes size per frame, the
    // empty-state page re-lays-out and bobs up/down.
    SizedBox? fixedBox;
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 400));
      final boxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
      final match = boxes.where((b) => b.width == 180 && b.height == 180);
      expect(match, isNotEmpty,
          reason: 'pulse ring must be wrapped in a fixed 180x180 box');
      fixedBox = match.first;
    }
    expect(fixedBox!.width, 180);
    expect(fixedBox.height, 180);
  });
}
