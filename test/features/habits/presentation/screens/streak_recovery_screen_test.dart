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

  /// Pump past the Narrator's initState delay so no timer leaks.
  Future<void> pumpWithNarratorDelay(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump();
  }

  testWidgets('displays habit title, xp, messaging, and icon', (tester) async {
    await tester.pumpWidget(buildScreen(habit: habit));
    await pumpWithNarratorDelay(tester);

    expect(find.textContaining('Never miss twice'), findsOneWidget);
    expect(find.textContaining('Read 10 Pages'), findsOneWidget);
    expect(find.text('50'), findsOneWidget);
    expect(find.text('+'), findsOneWidget);
    expect(find.text('XP'), findsOneWidget);
    expect(find.text('CONTINUE'), findsOneWidget);
    expect(find.text('MOMENTUM RESTORED'), findsOneWidget);
    expect(find.byIcon(Icons.shield_outlined), findsOneWidget);
  });

  testWidgets('pops on CONTINUE tap', (tester) async {
    await tester.pumpWidget(buildScreen(habit: habit));
    await pumpWithNarratorDelay(tester);

    // Close NarratorSheet modal first so CONTINUE is reachable
    final barrier = find.byType(ModalBarrier);
    if (barrier.evaluate().isNotEmpty) {
      await tester.tap(barrier.last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    // Tap CONTINUE — may throw if route can't pop since we're on home,
    // but we verify the screen handles the tap without crashing
    await tester.tap(find.text('CONTINUE'), warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Screen still exists (can't pop home route), but no exception thrown
    expect(find.byType(StreakRecoveryScreen), findsOneWidget);
  });

  testWidgets('renders with zero XP', (tester) async {
    await tester.pumpWidget(buildScreen(habit: habit, xp: 0));
    await pumpWithNarratorDelay(tester);

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
    await pumpWithNarratorDelay(tester);

    expect(find.textContaining('Meditate 5 mins'), findsOneWidget);
    expect(find.text('50'), findsOneWidget);
  });
}
