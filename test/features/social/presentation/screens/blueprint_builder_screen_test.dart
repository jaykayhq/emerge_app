import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/features/social/presentation/screens/creator/blueprint_builder_screen.dart';

Widget createWidgetUnderTest() {
  return const ProviderScope(
    child: MaterialApp(
      home: BlueprintBuilderScreen(),
    ),
  );
}

void main() {
  testWidgets('BlueprintBuilderScreen renders correctly and shows validation errors on empty submit',
      (WidgetTester tester) async {
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
    await tester.pump(const Duration(seconds: 1));

    // Verify validation triggers
    expect(find.text('Identity requires a name'), findsOneWidget);
    expect(find.text("Give your followers a 'why'"), findsOneWidget);
  });

  testWidgets('shows empty state with add-habit prompt', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Scroll down to the habits section
    await tester.scrollUntilVisible(
      find.text('No actions forged yet.'),
      200.0,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();

    expect(find.text('No actions forged yet.'), findsOneWidget);
    expect(find.text('Tap to add your first habit'), findsOneWidget);
  });

  testWidgets('add-habit dialog opens and shows timer picker options',
      (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Scroll to and tap the empty state to open the dialog
    await tester.scrollUntilVisible(
      find.text('No actions forged yet.'),
      200.0,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('No actions forged yet.'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify dialog opened with Forge Action title
    expect(find.text('Forge Action'), findsOneWidget);
    expect(find.text('FORGE'), findsOneWidget);

    // Verify timer picker is present with all options
    expect(find.text('TIMER (MINUTES)'), findsOneWidget);
    expect(find.text('Off'), findsOneWidget);
    expect(find.text('2M'), findsOneWidget);
    expect(find.text('5M'), findsOneWidget);
    expect(find.text('10M'), findsOneWidget);
    expect(find.text('15M'), findsOneWidget);
    expect(find.text('20M'), findsOneWidget);
  });

  testWidgets('add-habit dialog shows attribute and health integration dropdowns',
      (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Scroll to and tap the empty state to open the dialog
    await tester.scrollUntilVisible(
      find.text('No actions forged yet.'),
      200.0,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('No actions forged yet.'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify attribute and health integration labels
    expect(find.text('ATTRIBUTE'), findsOneWidget);
    expect(find.text('HEALTH INTEGRATION'), findsOneWidget);
  });

  testWidgets('creating a habit with timer and health fields shows in the list',
      (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Scroll to the empty state and tap to open dialog
    await tester.scrollUntilVisible(
      find.text('No actions forged yet.'),
      200.0,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('No actions forged yet.'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Enter a title
    await tester.enterText(
      find.widgetWithText(TextField, 'Action Title (e.g., Deep Work)'),
      'Morning Stretch',
    );
    await tester.pump();

    // Select 5M timer
    await tester.tap(find.text('5M'));
    await tester.pump();

    // Tap FORGE to create the habit
    await tester.tap(find.text('FORGE'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify the habit appears in the list
    expect(find.text('Morning Stretch'), findsOneWidget);

    // Check subtitle shows frequency and time of day
    expect(find.textContaining('Daily'), findsOneWidget);
  });

  testWidgets('creating multiple habits increments the list',
      (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Scroll to the empty state and tap
    await tester.scrollUntilVisible(
      find.text('No actions forged yet.'),
      200.0,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('No actions forged yet.'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Create first habit
    await tester.enterText(
      find.widgetWithText(TextField, 'Action Title (e.g., Deep Work)'),
      'Run 5K',
    );
    await tester.pump();
    await tester.tap(find.text('FORGE'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Tap ADD ANOTHER ACTION to open dialog again
    await tester.scrollUntilVisible(
      find.text('ADD ANOTHER ACTION'),
      200.0,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('ADD ANOTHER ACTION'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Create second habit
    await tester.enterText(
      find.widgetWithText(TextField, 'Action Title (e.g., Deep Work)'),
      'Read 30m',
    );
    await tester.pump();
    await tester.tap(find.text('FORGE'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Both habits should appear
    expect(find.text('Run 5K'), findsOneWidget);
    expect(find.text('Read 30m'), findsOneWidget);
  });

  testWidgets('remove habit button works',
      (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Scroll to the empty state and tap
    await tester.scrollUntilVisible(
      find.text('No actions forged yet.'),
      200.0,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('No actions forged yet.'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Create a habit
    await tester.enterText(
      find.widgetWithText(TextField, 'Action Title (e.g., Deep Work)'),
      'Test Habit',
    );
    await tester.pump();
    await tester.tap(find.text('FORGE'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify habit exists
    expect(find.text('Test Habit'), findsOneWidget);

    // Tap the remove button (IconButton with remove_circle_outline icon)
    await tester.tap(find.byIcon(Icons.remove_circle_outline_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Habit should be removed, empty state returns
    expect(find.text('Test Habit'), findsNothing);
    expect(find.text('No actions forged yet.'), findsOneWidget);
  });
}
