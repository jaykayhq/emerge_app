import 'package:emerge_app/features/world_map/presentation/widgets/world_bonfire.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders a fallback fire and forwards semantic taps', (
    tester,
  ) async {
    var tapCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WorldBonfire(health: 0.7, onTap: () => tapCount++),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.bySemanticsLabel('World health 70 percent'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('World health 70 percent'));

    expect(tapCount, 1);
  });

  testWidgets('keeps the procedural fire when shader loading fails', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WorldBonfire(
            health: 0.2,
            shaderLoader: () => Future.error(StateError('shader unavailable')),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('world-bonfire-procedural-painter')),
      findsOneWidget,
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('renders the procedural painter at the requested size', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: WorldBonfire(health: 0.5))),
    );

    final renderBox = tester.renderObject<RenderBox>(
      find.byKey(const ValueKey('world-bonfire-footprint')),
    );
    expect(renderBox.size.width, inInclusiveRange(200, 224));
    expect(renderBox.size.height, inInclusiveRange(200, 224));
  });
}
