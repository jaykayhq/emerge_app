import 'package:emerge_app/features/timeline/presentation/widgets/recap_summary_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget buildTestApp(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('RecapSummaryCard - momentum arc + streak flame', () {
    testWidgets('shows momentum arc and streak flame', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const RecapSummaryCard(
            completionFraction: 0.75,
            currentStreak: 7,
            tribePercentile: 90,
          ),
        ),
      );

      expect(find.text('75%'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
      expect(find.text('day streak'), findsOneWidget);
      expect(
        find.text("You're ahead of 90% of your tribe today."),
        findsOneWidget,
      );
    });

    testWidgets('tapping fires onTap callback', (tester) async {
      int tapCount = 0;
      await tester.pumpWidget(
        buildTestApp(
          RecapSummaryCard(
            completionFraction: 0.5,
            currentStreak: 3,
            onTap: () => tapCount++,
          ),
        ),
      );

      await tester.tap(find.byType(RecapSummaryCard));
      await tester.pump();
      expect(tapCount, 1);
    });

    testWidgets('shows 0% when no completions', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const RecapSummaryCard(completionFraction: 0.0, currentStreak: 0),
        ),
      );

      expect(find.text('0%'), findsOneWidget);
      expect(find.text("Your day hasn't started yet."), findsOneWidget);
    });

    testWidgets('shows all-done narrative without tribe data', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const RecapSummaryCard(completionFraction: 1.0, currentStreak: 5),
        ),
      );

      expect(find.text('100%'), findsOneWidget);
      expect(find.text('All done today! Great work.'), findsOneWidget);
    });

    testWidgets('shows all-done narrative with tribe percentile', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          const RecapSummaryCard(
            completionFraction: 1.0,
            currentStreak: 5,
            tribePercentile: 95,
          ),
        ),
      );

      expect(find.text('100%'), findsOneWidget);
      expect(
        find.text("All done today! You're in the top 95% of your tribe."),
        findsOneWidget,
      );
    });

    testWidgets('shows encouraging narrative for low completions', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          const RecapSummaryCard(completionFraction: 0.3, currentStreak: 2),
        ),
      );

      expect(find.text('30%'), findsOneWidget);
      expect(find.text("Every habit counts — you're at 30%."), findsOneWidget);
    });

    testWidgets('streak display scales with value', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const RecapSummaryCard(completionFraction: 0.6, currentStreak: 21),
        ),
      );

      expect(find.text('21'), findsOneWidget);
      expect(find.text('🔥🔥'), findsOneWidget);
    });

    testWidgets('amber arc color for mid-range completion', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const RecapSummaryCard(completionFraction: 0.3, currentStreak: 1),
        ),
      );

      // completionFraction 0.3 is in the amber range (0.25–0.49)
      final progressIndicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      final arcColor =
          (progressIndicator.valueColor as AlwaysStoppedAnimation<Color>).value;
      expect(arcColor, const Color(0xFFFFC107));
    });

    testWidgets('coral arc color for low completion', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const RecapSummaryCard(completionFraction: 0.1, currentStreak: 0),
        ),
      );

      final progressIndicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      final arcColor =
          (progressIndicator.valueColor as AlwaysStoppedAnimation<Color>).value;
      expect(arcColor, const Color(0xFFFF6B6B));
    });

    testWidgets('narrative shows tribe percentile for partial completion', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          const RecapSummaryCard(
            completionFraction: 0.65,
            currentStreak: 8,
            tribePercentile: 75,
          ),
        ),
      );

      expect(
        find.text("You're ahead of 75% of your tribe today."),
        findsOneWidget,
      );
    });
  });
}
