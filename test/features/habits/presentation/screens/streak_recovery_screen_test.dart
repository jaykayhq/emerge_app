import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/presentation/screens/streak_recovery_screen.dart';

void main() {
  testWidgets('StreakRecoveryScreen displays habit title, xp, and correct messaging', (WidgetTester tester) async {
    final habit = Habit(
      id: 'h1',
      userId: 'u1',
      title: 'Read 10 Pages',
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: StreakRecoveryScreen(
            habit: habit,
            xpEarned: 50,
          ),
        ),
      ),
    );

    expect(find.textContaining('Never miss twice'), findsOneWidget);
    expect(find.textContaining('Read 10 Pages'), findsOneWidget);
    expect(find.textContaining('50'), findsOneWidget); // XP earned
    expect(find.text('CONTINUE'), findsOneWidget);
  });

  testWidgets('StreakRecoveryScreen pops on CONTINUE tap', (WidgetTester tester) async {
    final habit = Habit(
      id: 'h1',
      userId: 'u1',
      title: 'Read 10 Pages',
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: StreakRecoveryScreen(
            habit: habit,
            xpEarned: 50,
          ),
        ),
      ),
    );

    await tester.tap(find.text('CONTINUE'));
    await tester.pumpAndSettle();
    
    // The screen should pop out, so we expect nothing from this screen to remain
    expect(find.byType(StreakRecoveryScreen), findsNothing);
  });
}
