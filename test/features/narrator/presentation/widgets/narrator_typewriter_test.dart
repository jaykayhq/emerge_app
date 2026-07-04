import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/narrator/presentation/widgets/narrator_typewriter.dart';

void main() {
  testWidgets('NarratorTypewriter starts empty and reveals text over time',
      (tester) async {
    bool completed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NarratorTypewriter(
            text: 'Hello.',
            onComplete: () => completed = true,
          ),
        ),
      ),
    );

    // Initially: displayed text is empty
    final finder = find.byType(NarratorTypewriter);
    expect(finder, findsOneWidget);

    // Advance past initial delay (200ms) and first character
    await tester.pump(const Duration(milliseconds: 300));
    // At least 'H' should be revealed
    expect(find.textContaining('H'), findsWidgets);

    // Advance past all characters including period pause (total ~586ms + buffer)
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Hello.'), findsOneWidget);

    // onComplete fires after all characters revealed
    await tester.pump(const Duration(milliseconds: 50));
    expect(completed, isTrue);
  });

  testWidgets('NarratorTypewriter handles empty text', (tester) async {
    bool completed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NarratorTypewriter(
            text: '',
            onComplete: () => completed = true,
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 300));
    expect(completed, isTrue);
  });

  testWidgets('NarratorTypewriter respects custom style', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NarratorTypewriter(
            text: 'Test',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );

    // Wait for rendering before checking
    await tester.pump(const Duration(milliseconds: 600));
    final textWidget = tester.widget<Text>(find.byType(Text));
    expect(textWidget.style?.fontSize, 20);
    expect(textWidget.style?.fontWeight, FontWeight.bold);
    expect(textWidget.style?.color, isNull); // default: no color override
  });
}
