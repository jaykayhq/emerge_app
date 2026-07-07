import 'package:emerge_app/features/narrator/domain/models/narrator_appearance.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_line.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_trigger.dart';
import 'package:emerge_app/features/narrator/presentation/widgets/narrator_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('NarratorSheet renders header with EMERGE text',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => NarratorSheet.show(
                  context,
                  const NarratorAppearance(
                    trigger: NarratorTrigger.levelUp,
                    shellText: 'Welcome test text.',
                    buttonA: 'Action A',
                    buttonB: 'Action B',
                    line: GenericLine('Welcome test text.'),
                  ),
                ),
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      ),
    );

    // Open the narrator dialog
    await tester.tap(find.text('Show'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Header should be visible
    expect(find.text('EMERGE'), findsOneWidget);

    // Instant text should be visible (no typewriter)
    expect(find.text('Welcome test text.'), findsOneWidget);
  });

  testWidgets('NarratorSheet shows action buttons immediately with text',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => NarratorSheet.show(
                  context,
                  const NarratorAppearance(
                    trigger: NarratorTrigger.levelUp,
                    shellText: 'Short text.',
                    buttonA: 'Action A',
                    buttonB: 'Action B',
                    line: GenericLine('Short text.'),
                  ),
                ),
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      ),
    );

    // Open the narrator dialog and wait for entry animation
    await tester.tap(find.text('Show'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Action buttons should be visible immediately (no typewriter delay)
    expect(find.text('Action A'), findsOneWidget);
    expect(find.text('Action B'), findsOneWidget);
  });

  testWidgets('NarratorSheet dismisses on barrier tap', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => NarratorSheet.show(
                  context,
                  const NarratorAppearance(
                    trigger: NarratorTrigger.levelUp,
                    shellText: 'Dismiss test.',
                    buttonA: 'OK',
                    buttonB: 'Cancel',
                    line: GenericLine('Dismiss test.'),
                  ),
                ),
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      ),
    );

    // Open the narrator dialog
    await tester.tap(find.text('Show'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Dialog should be visible
    expect(find.text('EMERGE'), findsOneWidget);

    // Tap outside the dialog (the barrier)
    await tester.tapAt(const Offset(10, 10));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Dialog should be dismissed
    expect(find.text('EMERGE'), findsNothing);
  });

  testWidgets('NarratorSheet action button tap dismisses dialog',
      (tester) async {
    String? tappedButton;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => NarratorSheet.show(
                  context,
                  const NarratorAppearance(
                    trigger: NarratorTrigger.levelUp,
                    shellText: 'Button test.',
                    buttonA: 'Confirm',
                    buttonB: 'Skip',
                    line: GenericLine('Button test.'),
                  ),
                  onResponse: (label, _) => tappedButton = label,
                ),
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      ),
    );

    // Open the narrator dialog
    await tester.tap(find.text('Show'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Tap the first action button
    await tester.tap(find.text('Confirm'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Dialog should be dismissed
    expect(find.text('EMERGE'), findsNothing);
    // onResponse should have been called
    expect(tappedButton, 'Confirm');
  });

  testWidgets('NarratorSheet entry animation plays',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => NarratorSheet.show(
                  context,
                  const NarratorAppearance(
                    trigger: NarratorTrigger.levelUp,
                    shellText: 'Animation test.',
                    buttonA: 'OK',
                    buttonB: 'Cancel',
                    line: GenericLine('Animation test.'),
                  ),
                ),
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      ),
    );

    // Open the narrator dialog
    await tester.tap(find.text('Show'));
    await tester.pump();

    // After the animation completes (400ms), content should be visible
    await tester.pump(const Duration(milliseconds: 500));

    // EMERGE header should be visible after entry animation
    expect(find.text('EMERGE'), findsOneWidget);
  });
}
