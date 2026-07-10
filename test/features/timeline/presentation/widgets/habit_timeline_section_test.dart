import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/timeline/presentation/widgets/habit_timeline_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Habit _makeHabit({
  String id = 'h1',
  String title = 'Morning Meditation',
  int timerDurationMinutes = 2,
  bool completedToday = false,
}) {
  final now = DateTime.now();
  return Habit(
    id: id,
    userId: 'u1',
    title: title,
    createdAt: now,
    timerDurationMinutes: timerDurationMinutes,
    lastCompletedDate: completedToday ? now : null,
    attribute: HabitAttribute.vitality,
  );
}

Widget buildTestApp(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('IndentedHabitItem - layout', () {
    testWidgets('renders title, checkbox, timer icon, menu icon', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          IndentedHabitItem(
            habit: _makeHabit(),
            selectedDate: DateTime.now(),
            onRowBodyTap: () {},
            onCheckboxTap: () {},
            onTimerTap: () {},
            onMenuTap: () {},
          ),
        ),
      );
      expect(find.text('Morning Meditation'), findsOneWidget);
      expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
      expect(find.byIcon(Icons.more_vert), findsOneWidget);
      // Checkbox: radio_button_unchecked when not completed
      expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget);
    });

    testWidgets('is NOT a Dismissible', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          IndentedHabitItem(
            habit: _makeHabit(),
            selectedDate: DateTime.now(),
            onRowBodyTap: () {},
            onCheckboxTap: () {},
            onTimerTap: () {},
            onMenuTap: () {},
          ),
        ),
      );
      expect(find.byType(Dismissible), findsNothing);
    });
  });

  group('IndentedHabitItem - tap zones', () {
    testWidgets('tap on title fires onRowBodyTap only', (tester) async {
      var body = 0, checkbox = 0, timer = 0, menu = 0;
      await tester.pumpWidget(
        buildTestApp(
          IndentedHabitItem(
            habit: _makeHabit(),
            selectedDate: DateTime.now(),
            onRowBodyTap: () => body++,
            onCheckboxTap: () => checkbox++,
            onTimerTap: () => timer++,
            onMenuTap: () => menu++,
          ),
        ),
      );
      await tester.tap(find.text('Morning Meditation'));
      await tester.pump();
      expect(body, 1);
      expect(checkbox, 0);
      expect(timer, 0);
      expect(menu, 0);
    });

    testWidgets('tap on checkbox fires onCheckboxTap only', (tester) async {
      var body = 0, checkbox = 0, timer = 0, menu = 0;
      await tester.pumpWidget(
        buildTestApp(
          IndentedHabitItem(
            habit: _makeHabit(),
            selectedDate: DateTime.now(),
            onRowBodyTap: () => body++,
            onCheckboxTap: () => checkbox++,
            onTimerTap: () => timer++,
            onMenuTap: () => menu++,
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.radio_button_unchecked));
      await tester.pump();
      expect(checkbox, 1);
      expect(body, 0);
    });

    testWidgets('tap on timer icon fires onTimerTap only', (tester) async {
      var body = 0, checkbox = 0, timer = 0, menu = 0;
      await tester.pumpWidget(
        buildTestApp(
          IndentedHabitItem(
            habit: _makeHabit(),
            selectedDate: DateTime.now(),
            onRowBodyTap: () => body++,
            onCheckboxTap: () => checkbox++,
            onTimerTap: () => timer++,
            onMenuTap: () => menu++,
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.timer_outlined));
      await tester.pump();
      expect(timer, 1);
      expect(body, 0);
    });

    testWidgets('tap on menu icon fires onMenuTap only', (tester) async {
      var body = 0, checkbox = 0, timer = 0, menu = 0;
      await tester.pumpWidget(
        buildTestApp(
          IndentedHabitItem(
            habit: _makeHabit(),
            selectedDate: DateTime.now(),
            onRowBodyTap: () => body++,
            onCheckboxTap: () => checkbox++,
            onTimerTap: () => timer++,
            onMenuTap: () => menu++,
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pump();
      expect(menu, 1);
      expect(body, 0);
    });
  });

  group('IndentedHabitItem - completed visual', () {
    testWidgets('shows strike-through title when completed', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          IndentedHabitItem(
            habit: _makeHabit(completedToday: true),
            selectedDate: DateTime.now(),
            onRowBodyTap: () {},
            onCheckboxTap: () {},
            onTimerTap: () {},
            onMenuTap: () {},
          ),
        ),
      );
      final text = tester.widget<Text>(find.text('Morning Meditation'));
      expect(text.style?.decoration, TextDecoration.lineThrough);
    });

    testWidgets('shows check_circle and xp badge when completed', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          IndentedHabitItem(
            habit: _makeHabit(completedToday: true, id: 'h2'),
            selectedDate: DateTime.now(),
            onRowBodyTap: () {},
            onCheckboxTap: () {},
            onTimerTap: () {},
            onMenuTap: () {},
          ),
        ),
      );
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.textContaining('XP'), findsWidgets);
    });
  });
}
