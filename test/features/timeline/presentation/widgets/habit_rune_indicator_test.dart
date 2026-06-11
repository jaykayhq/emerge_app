import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/timeline/presentation/widgets/habit_rune_indicator.dart';

Habit _makeHabit({
  required int currentStreak,
  required HabitAttribute attribute,
}) {
  return Habit(
    id: 'habit_1',
    userId: 'user1',
    title: 'Test Habit',
    currentStreak: currentStreak,
    attribute: attribute,
    createdAt: DateTime(2024, 1, 1),
  );
}

void main() {
  group('HabitRuneIndicator', () {
    testWidgets('renders with zero streak (unforged)', (tester) async {
      final habit = _makeHabit(
        currentStreak: 0,
        attribute: HabitAttribute.vitality,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: HabitRuneIndicator(habit: habit)),
        ),
      );
      expect(find.byType(HabitRuneIndicator), findsOneWidget);
      // Let animation settle
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('renders with streak of 7', (tester) async {
      final habit = _makeHabit(
        currentStreak: 7,
        attribute: HabitAttribute.strength,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: HabitRuneIndicator(habit: habit)),
        ),
      );
      expect(find.byType(HabitRuneIndicator), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('renders with high streak (30)', (tester) async {
      final habit = _makeHabit(
        currentStreak: 30,
        attribute: HabitAttribute.intellect,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: HabitRuneIndicator(habit: habit)),
        ),
      );
      expect(find.byType(HabitRuneIndicator), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('renders with different attributes', (tester) async {
      for (final attr in HabitAttribute.values) {
        final habit = _makeHabit(currentStreak: 5, attribute: attr);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: HabitRuneIndicator(habit: habit)),
          ),
        );
        expect(find.byType(HabitRuneIndicator), findsOneWidget);
      }
    });

    testWidgets('updates when habit changes', (tester) async {
      var habit = _makeHabit(
        currentStreak: 0,
        attribute: HabitAttribute.vitality,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: HabitRuneIndicator(habit: habit)),
        ),
      );
      expect(find.byType(HabitRuneIndicator), findsOneWidget);

      habit = _makeHabit(currentStreak: 10, attribute: HabitAttribute.vitality);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: HabitRuneIndicator(habit: habit)),
        ),
      );
      expect(find.byType(HabitRuneIndicator), findsOneWidget);
    });
  });
}
