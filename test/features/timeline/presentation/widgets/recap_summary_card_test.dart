import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/timeline/presentation/widgets/recap_summary_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Habit _makeHabit({
  String id = 'h1',
  String title = 'Test Habit',
  DateTime? lastCompletedDate,
}) {
  return Habit(
    id: id,
    userId: 'u1',
    title: title,
    createdAt: DateTime.now(),
    lastCompletedDate: lastCompletedDate,
    attribute: HabitAttribute.vitality,
  );
}

Widget buildTestApp(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('RecapSummaryCard', () {
    testWidgets('shows weekly completion count, streak, and XP', (
      tester,
    ) async {
      final now = DateTime.now();
      final thisWeek = DateTime(
        now.year,
        now.month,
        now.day - (now.weekday % 7),
      );
      final lastWeek = thisWeek.subtract(const Duration(days: 8));

      final habits = [
        _makeHabit(
          id: 'h1',
          lastCompletedDate: thisWeek.add(const Duration(hours: 2)),
        ),
        _makeHabit(
          id: 'h2',
          lastCompletedDate: thisWeek.add(const Duration(hours: 4)),
        ),
        _makeHabit(
          id: 'h3',
          lastCompletedDate: thisWeek.add(const Duration(hours: 6)),
        ),
        _makeHabit(id: 'h4', lastCompletedDate: lastWeek), // outside this week
        _makeHabit(id: 'h5', lastCompletedDate: null), // never completed
      ];

      await tester.pumpWidget(
        buildTestApp(
          RecapSummaryCard(
            habits: habits,
            streak: 12,
            totalXp: 2400,
            onTap: () {},
          ),
        ),
      );

      // Should count 3 habits completed this week
      expect(find.text('3'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      // XP should be formatted as "2.4k" since >= 1000
      expect(find.text('2.4k'), findsOneWidget);
    });

    testWidgets('shows raw XP when under 1000', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          RecapSummaryCard(habits: [], streak: 0, totalXp: 240, onTap: () {}),
        ),
      );

      expect(find.text('240'), findsOneWidget);
    });

    testWidgets('shows 0 when no habits', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          RecapSummaryCard(habits: [], streak: 0, totalXp: 0, onTap: () {}),
        ),
      );

      expect(find.text('0'), findsWidgets);
    });

    testWidgets('shows labels correctly', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          RecapSummaryCard(habits: [], streak: 5, totalXp: 100, onTap: () {}),
        ),
      );

      expect(find.text('this week'), findsOneWidget);
      expect(find.text('day streak'), findsOneWidget);
      expect(find.text('total XP'), findsOneWidget);
    });

    testWidgets('tapping fires onTap callback', (tester) async {
      int tapCount = 0;
      await tester.pumpWidget(
        buildTestApp(
          RecapSummaryCard(
            habits: [],
            streak: 0,
            totalXp: 0,
            onTap: () => tapCount++,
          ),
        ),
      );

      await tester.tap(find.byType(RecapSummaryCard));
      await tester.pump();
      expect(tapCount, 1);
    });

    testWidgets('does not count habits completed before this week', (
      tester,
    ) async {
      final oldDate = DateTime.now().subtract(const Duration(days: 14));

      await tester.pumpWidget(
        buildTestApp(
          RecapSummaryCard(
            habits: [_makeHabit(id: 'h1', lastCompletedDate: oldDate)],
            streak: 0,
            totalXp: 0,
            onTap: () {},
          ),
        ),
      );

      expect(find.text('0'), findsWidgets);
      expect(find.text('1'), findsNothing);
    });
  });
}
