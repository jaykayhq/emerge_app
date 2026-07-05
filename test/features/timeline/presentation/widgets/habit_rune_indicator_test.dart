import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/timeline/presentation/widgets/habit_rune_indicator.dart';

void main() {
  // Helper to generate a baseline habit
  Habit makeHabit({
    String twoMinute = '',
    String reward = '',
    List<String> envPriming = const [],
    HabitIntegrationType integration = HabitIntegrationType.none,
    String? anchorId,
  }) {
    return Habit(
      id: '1',
      userId: 'user1',
      title: 'Test Habit',
      attribute: HabitAttribute.vitality,
      difficulty: HabitDifficulty.easy,
      twoMinuteVersion: twoMinute,
      reward: reward,
      environmentPriming: envPriming,
      integrationType: integration,
      anchorHabitId: anchorId,
      createdAt: DateTime.now(),
    );
  }

  testWidgets('HabitRuneIndicator renders custom painter when unconfigured (dormant)', (tester) async {
    final habit = makeHabit();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: HabitRuneIndicator(habit: habit),
      ),
    ));

    expect(
      find.descendant(
        of: find.byType(HabitRuneIndicator),
        matching: find.byType(CustomPaint),
      ),
      findsOneWidget,
    );
  });

  testWidgets('HabitRuneIndicator renders container when configured (forged)', (tester) async {
    final habit = makeHabit(twoMinute: '2-min version');
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: HabitRuneIndicator(habit: habit),
      ),
    ));

    // When forged, it should not render the DashedCirclePainter custom painter
    expect(
      find.descendant(
        of: find.byType(HabitRuneIndicator),
        matching: find.byType(CustomPaint),
      ),
      findsNothing,
    );
  });

  testWidgets('HabitRuneIndicator pulses opacity over time when dormant', (tester) async {
    final habit = makeHabit();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: HabitRuneIndicator(habit: habit),
      ),
    ));

    final opacityFinder = find.descendant(
      of: find.byType(HabitRuneIndicator),
      matching: find.byType(Opacity),
    );
    final opacityWidget1 = tester.widget<Opacity>(opacityFinder);
    final initialOpacity = opacityWidget1.opacity;

    // Advance animation
    await tester.pump(const Duration(milliseconds: 750));

    final opacityWidget2 = tester.widget<Opacity>(opacityFinder);
    expect(opacityWidget2.opacity, isNot(equals(initialOpacity)));
  });
}
