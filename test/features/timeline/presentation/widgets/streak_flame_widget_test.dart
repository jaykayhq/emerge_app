import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/timeline/presentation/widgets/streak_flame_widget.dart';
import 'package:emerge_app/features/timeline/presentation/widgets/completion_celebration.dart';
import 'package:emerge_app/features/timeline/presentation/widgets/month_calendar_strip.dart';

void main() {
  group('StreakFlameWidget', () {
    testWidgets('renders with zero streak inactive', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StreakFlameWidget(streakCount: 0, isActive: false),
          ),
        ),
      );
      expect(find.byType(StreakFlameWidget), findsOneWidget);
    });

    testWidgets('renders with 7-day streak active', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StreakFlameWidget(streakCount: 7, isActive: true),
          ),
        ),
      );
      expect(find.byType(StreakFlameWidget), findsOneWidget);
    });

    testWidgets('renders with 30-day streak', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StreakFlameWidget(streakCount: 30, isActive: true),
          ),
        ),
      );
      expect(find.byType(StreakFlameWidget), findsOneWidget);
    });

    testWidgets('renders with custom size', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StreakFlameWidget(streakCount: 5, isActive: true, size: 72),
          ),
        ),
      );
      expect(find.byType(StreakFlameWidget), findsOneWidget);
    });
  });

  group('CompletionCelebration', () {
    testWidgets('renders with required parameters', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompletionCelebration(
              xpEarned: 50,
              newStreak: 5,
              onComplete: () {},
            ),
          ),
        ),
      );
      expect(find.byType(CompletionCelebration), findsOneWidget);
      // Allow all internal timers/animations to complete (1.5s + buffer)
      await tester.pump(const Duration(milliseconds: 2000));
      await tester.pumpAndSettle();
    });

    testWidgets('renders with streak milestone', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompletionCelebration(
              xpEarned: 100,
              newStreak: 7,
              isStreakMilestone: true,
              onComplete: () {},
            ),
          ),
        ),
      );
      expect(find.byType(CompletionCelebration), findsOneWidget);
      // Allow all internal timers/animations to complete (1.5s + buffer)
      await tester.pump(const Duration(milliseconds: 2000));
      await tester.pumpAndSettle();
    });
  });

  group('MonthCalendarStrip', () {
    testWidgets('renders with no parameters', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: MonthCalendarStrip())),
      );
      expect(find.byType(MonthCalendarStrip), findsOneWidget);
    });

    testWidgets('renders with selected date', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MonthCalendarStrip(
              selectedDate: DateTime.now(),
              onDateSelected: (date) {},
            ),
          ),
        ),
      );
      expect(find.byType(MonthCalendarStrip), findsOneWidget);
    });
  });
}
