import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/presentation/screens/streak_recovery_screen.dart';

void main() {
  final habit = Habit(
    id: 'h1',
    userId: 'u1',
    title: 'Read 10 Pages',
    createdAt: DateTime.now(),
  );

  Widget buildScreen({required Habit habit, int xp = 50}) {
    return ProviderScope(
      child: MaterialApp(
        home: StreakRecoveryScreen(habit: habit, xpEarned: xp),
      ),
    );
  }

  testWidgets(
    'displays habit title, xp, messaging, and icon', (tester) async {
      await tester.pumpWidget(buildScreen(habit: habit));

      expect(find.textContaining('Never miss twice'), findsOneWidget);
      expect(find.textContaining('Read 10 Pages'), findsOneWidget);
      expect(find.text('50'), findsOneWidget);
      expect(find.text('+'), findsOneWidget);
      expect(find.text('XP'), findsOneWidget);
      expect(find.text('CONTINUE'), findsOneWidget);
      expect(find.text('MOMENTUM RESTORED'), findsOneWidget);
      expect(find.byIcon(Icons.shield_outlined), findsOneWidget);
    },
  );

  testWidgets('pops on CONTINUE tap', (tester) async {
    await tester.pumpWidget(buildScreen(habit: habit));

    await tester.tap(find.text('CONTINUE'));
    await tester.pumpAndSettle();

    expect(find.byType(StreakRecoveryScreen), findsNothing);
  });

  testWidgets('renders with zero XP', (tester) async {
    await tester.pumpWidget(buildScreen(habit: habit, xp: 0));

    expect(find.text('0'), findsOneWidget);
    expect(find.text('CONTINUE'), findsOneWidget);
  });

  testWidgets('renders with different habit title', (tester) async {
    final otherHabit = Habit(
      id: 'h2',
      userId: 'u1',
      title: 'Meditate 5 mins',
      createdAt: DateTime.now(),
    );
    await tester.pumpWidget(buildScreen(habit: otherHabit));

    expect(find.textContaining('Meditate 5 mins'), findsOneWidget);
    expect(find.text('50'), findsOneWidget);
  });
}
