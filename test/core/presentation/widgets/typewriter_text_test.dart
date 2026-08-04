import 'package:emerge_app/core/presentation/widgets/typewriter_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('visibleCharCount', () {
    test('returns 0 at t=0', () {
      expect(visibleCharCount('hello', 0, 35), 0);
    });

    test('advances linearly with elapsed time', () {
      expect(visibleCharCount('hello', 100, 35), 3); // 3.5 → floor 3
    });

    test('saturates at full length', () {
      expect(visibleCharCount('hello', 10000, 35), 5);
    });

    test('empty text stays 0', () {
      expect(visibleCharCount('', 1000, 35), 0);
    });

    test('zero cps stays 0', () {
      expect(visibleCharCount('hello', 1000, 0), 0);
    });
  });

  group('TypewriterText widget', () {
    // NOTE: never use pumpAndSettle with TypewriterText — the blinking
    // caret repeats forever. Always pump explicit durations.
    testWidgets('types out text progressively', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TypewriterText(text: 'Hello world', charsPerSecond: 100),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50)); // 5 chars
      // .first: the caret renders as a nested Text inside the main Text.rich.
      expect(
        tester
            .widget<Text>(find.byType(Text).first)
            .textSpan!
            .toPlainText(includePlaceholders: false),
        'Hello',
      );
      await tester.pump(const Duration(seconds: 1));
      expect(
        tester
            .widget<Text>(find.byType(Text).first)
            .textSpan!
            .toPlainText(includePlaceholders: false),
        'Hello world',
      );
    });

    testWidgets('tap completes instantly and fires onComplete', (tester) async {
      var completed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TypewriterText(
              text: 'Hello world',
              charsPerSecond: 1,
              onComplete: () => completed = true,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        tester
            .widget<Text>(find.byType(Text).first)
            .textSpan!
            .toPlainText(includePlaceholders: false),
        '',
      );
      await tester.tap(find.byType(TypewriterText));
      await tester.pump();
      expect(
        tester
            .widget<Text>(find.byType(Text).first)
            .textSpan!
            .toPlainText(includePlaceholders: false),
        'Hello world',
      );
      expect(completed, true);
    });

    testWidgets('reduced motion renders instantly with no caret', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: TypewriterText(text: 'Hello world', charsPerSecond: 1),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(
        tester
            .widget<Text>(find.byType(Text).first)
            .textSpan!
            .toPlainText(includePlaceholders: false),
        'Hello world',
      );
    });

    testWidgets('natural completion fires onComplete', (tester) async {
      var completed = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TypewriterText(
              text: 'Hello world', // 11 chars at 5 cps → 2.2 s
              charsPerSecond: 5,
              onComplete: () => completed++,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
      expect(completed, 1);
    });

    testWidgets('text change restarts typing and re-fires onComplete', (
      tester,
    ) async {
      var completed = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TypewriterText(
              text: 'Hello world',
              charsPerSecond: 100,
              onComplete: () => completed++,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(completed, 1);
      // Text change restarts typing from scratch.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TypewriterText(
              text: 'Short',
              charsPerSecond: 100,
              onComplete: () => completed++,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 20)); // 2 chars
      expect(
        tester
            .widget<Text>(find.byType(Text).first)
            .textSpan!
            .toPlainText(includePlaceholders: false),
        'Sh',
      );
      await tester.pump(const Duration(seconds: 1));
      expect(completed, 2);
      expect(
        tester
            .widget<Text>(find.byType(Text).first)
            .textSpan!
            .toPlainText(includePlaceholders: false),
        'Short',
      );
    });

    testWidgets('onComplete fires exactly once after natural completion', (
      tester,
    ) async {
      var completed = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TypewriterText(
              text: 'Hello',
              charsPerSecond: 100,
              onComplete: () => completed++,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(completed, 1);
      // Extra time and taps after completion must not re-fire.
      await tester.tap(find.byType(TypewriterText));
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.byType(TypewriterText));
      await tester.pump(const Duration(seconds: 1));
      expect(completed, 1);
    });

    testWidgets('onComplete fires exactly once after tap-skip', (tester) async {
      var completed = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TypewriterText(
              text: 'Hello world',
              charsPerSecond: 1,
              onComplete: () => completed++,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byType(TypewriterText));
      await tester.pump();
      expect(completed, 1);
      // Extra time and taps after the skip must not re-fire.
      await tester.pump(const Duration(seconds: 5));
      await tester.tap(find.byType(TypewriterText));
      await tester.pump(const Duration(seconds: 5));
      expect(completed, 1);
    });
    testWidgets('applies an explicit style', (tester) async {
      const style = TextStyle(color: Color(0xFF112233));
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TypewriterText(
              text: 'Hi',
              style: style,
              charsPerSecond: 1000,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(
        tester.widget<Text>(find.byType(Text).first).style?.color,
        const Color(0xFF112233),
      );
    });
  });
}
