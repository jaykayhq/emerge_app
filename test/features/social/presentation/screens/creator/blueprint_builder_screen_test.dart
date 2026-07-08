import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/features/social/presentation/screens/creator/blueprint_builder_screen.dart';

void main() {
  Widget createWidgetUnderTest() {
    return const ProviderScope(
      child: MaterialApp(
        home: BlueprintBuilderScreen(),
      ),
    );
  }

  testWidgets('BlueprintBuilderScreen renders correctly and shows validation errors on empty submit', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('FORGE BLUEPRINT'), findsOneWidget);
    expect(find.text('Blueprint Name'), findsOneWidget);
    expect(find.text('EMIT TO WORLD'), findsOneWidget);

    // Try to submit the form empty
    final button = find.text('EMIT TO WORLD');
    await tester.ensureVisible(button);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(button, warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify validation triggers
    expect(find.text('Identity requires a name'), findsOneWidget);
    expect(find.text("Give your followers a 'why'"), findsOneWidget);
  });
}
