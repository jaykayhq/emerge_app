// test/core/presentation/widgets/shareable/shareable_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/core/presentation/widgets/shareable/shareable_card.dart';
import 'package:emerge_app/core/presentation/widgets/shareable/shareable_card_data.dart';

void main() {
  group('ShareableCard widget', () {
    testWidgets('renders headline, stats, footer at 9:16', (tester) async {
      const data = ShareableCardData(
        headline: 'MY WEEK',
        subheadline: 'Aug 10 – 16',
        stats: [
          ShareableStat(label: 'Habits', value: '42', color: Color(0xFF2BEE79)),
          ShareableStat(label: 'XP', value: '+500', color: Color(0xFFFFD700)),
        ],
        footer: 'Built with Emerge',
      );
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AspectRatio(
                aspectRatio: 9 / 16,
                child: ShareableCard(data: data),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('MY WEEK'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
      expect(find.text('+500'), findsOneWidget);
      expect(find.text('Built with Emerge'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('handles empty stats without overflow', (tester) async {
      const data = ShareableCardData(headline: 'HEADLINE', footer: 'Footer');
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AspectRatio(
                aspectRatio: 9 / 16,
                child: ShareableCard(data: data),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('HEADLINE'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('long values truncate instead of overflowing', (tester) async {
      const data = ShareableCardData(
        headline: 'A VERY LONG HEADLINE THAT WOULD WRAP ONTO MANY LINES',
        subheadline:
            'A very long subheadline that should never push the footer off the card',
        stats: [
          ShareableStat(
            label: 'Long label',
            value: '12,345,678,901,234,567,890 XP EARNED TOTAL SO FAR',
            color: Color(0xFF2BEE79),
          ),
        ],
        footer: 'Built with Emerge',
      );
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AspectRatio(
                aspectRatio: 9 / 16,
                child: ShareableCard(data: data),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Built with Emerge'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('ShareableCardData', () {
    test('carries headline and stats', () {
      const data = ShareableCardData(
        headline: 'MY WEEK IN EMERGE',
        subheadline: 'Week of Aug 10 – 16',
        stats: [
          ShareableStat(label: 'Habits', value: '42', color: Color(0xFF2BEE79)),
          ShareableStat(label: 'XP', value: '+500', color: Color(0xFFFFD700)),
        ],
        footer: 'Built with Emerge',
      );
      expect(data.headline, 'MY WEEK IN EMERGE');
      expect(data.stats.length, 2);
      expect(data.stats.first.value, '42');
      expect(data.footer, 'Built with Emerge');
    });

    test('defaults stats to empty list', () {
      const data = ShareableCardData(headline: 'X');
      expect(data.stats, isEmpty);
      expect(data.subheadline, isNull);
    });
  });
}
