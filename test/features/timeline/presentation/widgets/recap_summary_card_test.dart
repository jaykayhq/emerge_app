import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/timeline/presentation/widgets/recap_summary_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Habit _makeHabit({
  String id = 'h1',
  String title = 'Test Habit',
  DateTime? lastCompletedDate,
  DateTime? createdAt,
}) {
  return Habit(
    id: id,
    userId: 'u1',
    title: title,
    createdAt: createdAt ?? DateTime.now(),
    lastCompletedDate: lastCompletedDate,
    attribute: HabitAttribute.vitality,
  );
}

Widget buildTestApp(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('RecapSummaryCard', () {
    testWidgets('shows RECAP label, today count, weekly count and streak', (
      tester,
    ) async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final thisWeek = DateTime(
        now.year,
        now.month,
        now.day - (now.weekday % 7),
      );
      final lastWeek = thisWeek.subtract(const Duration(days: 8));

      final habits = [
        _makeHabit(
          id: 'h1',
          createdAt: today.subtract(const Duration(days: 1)),
          lastCompletedDate: today, // completed today
        ),
        _makeHabit(
          id: 'h2',
          lastCompletedDate: thisWeek.add(const Duration(hours: 2)),
        ),
        _makeHabit(
          id: 'h3',
          lastCompletedDate: thisWeek.add(const Duration(hours: 4)),
        ),
        _makeHabit(
          id: 'h4',
          lastCompletedDate: thisWeek.add(const Duration(hours: 6)),
        ),
        _makeHabit(id: 'h5', lastCompletedDate: lastWeek), // outside this week
        _makeHabit(id: 'h6', lastCompletedDate: null), // never completed
      ];

      await tester.pumpWidget(
        buildTestApp(
          RecapSummaryCard(habits: habits, streak: 12, onTap: () {}),
        ),
      );

      // Eyebrow label
      expect(find.text('RECAP'), findsOneWidget);
      // Today done: 1 completed today out of 6 habits -> "1/6"
      expect(find.text('1/6'), findsOneWidget);
      // This week: 4 habits completed this week
      expect(find.text('4'), findsOneWidget);
      // Streak
      expect(find.text('12'), findsOneWidget);
    });

    testWidgets('today count reflects only today completions', (tester) async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final habits = [
        _makeHabit(
          id: 'h1',
          createdAt: today.subtract(const Duration(days: 1)),
          lastCompletedDate: today,
        ),
        _makeHabit(
          id: 'h2',
          lastCompletedDate: today.subtract(const Duration(days: 1)),
        ),
      ];

      await tester.pumpWidget(
        buildTestApp(
          RecapSummaryCard(habits: habits, streak: 3, onTap: () {}),
        ),
      );

      expect(find.text('1/2'), findsOneWidget);
    });

    testWidgets('shows 0 when no habits', (tester) async {
      await tester.pumpWidget(
        buildTestApp(RecapSummaryCard(habits: [], streak: 0, onTap: () {})),
      );

      expect(find.text('RECAP'), findsOneWidget);
      expect(find.text('0/0'), findsOneWidget);
      expect(find.text('0'), findsWidgets);
    });

    testWidgets('shows labels correctly', (tester) async {
      await tester.pumpWidget(
        buildTestApp(RecapSummaryCard(habits: [], streak: 5, onTap: () {})),
      );

      expect(find.text('today done'), findsOneWidget);
      expect(find.text('this week'), findsOneWidget);
      expect(find.text('day streak'), findsOneWidget);
    });

    testWidgets('tapping fires onTap callback', (tester) async {
      int tapCount = 0;
      await tester.pumpWidget(
        buildTestApp(
          RecapSummaryCard(habits: [], streak: 0, onTap: () => tapCount++),
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
            onTap: () {},
          ),
        ),
      );

      // This week count is 0 (only the old one exists).
      expect(find.text('0'), findsWidgets);
      expect(find.text('1'), findsNothing);
    });
  });
}
