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
    testWidgets('renders title, timer icon, menu icon', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          IndentedHabitItem(
            habit: _makeHabit(timerDurationMinutes: 2),
            selectedDate: DateTime.now(),
            onRowBodyTap: () {},
            onCheckboxTap: () {},
            onTimerTap: (_) async => null,
            onMenuTap: () {},
          ),
        ),
      );
      expect(find.text('Morning Meditation'), findsOneWidget);
      expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
      expect(find.byIcon(Icons.more_vert), findsOneWidget);
    });

    testWidgets('is NOT a Dismissible', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          IndentedHabitItem(
            habit: _makeHabit(),
            selectedDate: DateTime.now(),
            onRowBodyTap: () {},
            onCheckboxTap: () {},
            onTimerTap: (_) async => null,
            onMenuTap: () {},
          ),
        ),
      );
      expect(find.byType(Dismissible), findsNothing);
    });

    testWidgets('habit with no timer shows check circle (no timer icon)',
        (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          IndentedHabitItem(
            habit: _makeHabit(timerDurationMinutes: 0),
            selectedDate: DateTime.now(),
            onRowBodyTap: () {},
            onCheckboxTap: () {},
            onTimerTap: (_) async => null,
            onMenuTap: () {},
          ),
        ),
      );
      // No timer set -> no timer icon.
      expect(find.byIcon(Icons.timer_outlined), findsNothing);
      // Check circle (the dot container) is present.
      expect(find.text('·'), findsOneWidget);
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
            onTimerTap: (_) async => null,
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

    testWidgets('tap on check circle fires onCheckboxTap', (tester) async {
      var checkbox = 0;
      await tester.pumpWidget(
        buildTestApp(
          IndentedHabitItem(
            habit: _makeHabit(timerDurationMinutes: 0),
            selectedDate: DateTime.now(),
            onRowBodyTap: () {},
            onCheckboxTap: () => checkbox++,
            onTimerTap: (_) async => null,
            onMenuTap: () {},
          ),
        ),
      );
      // Tap the dot (check circle placeholder)
      await tester.tap(find.text('·'));
      await tester.pump();
      expect(checkbox, 1);
    });

    testWidgets('tap on timer icon fires onTimerTap', (tester) async {
      var timer = 0;
      await tester.pumpWidget(
        buildTestApp(
          IndentedHabitItem(
            habit: _makeHabit(timerDurationMinutes: 2),
            selectedDate: DateTime.now(),
            onRowBodyTap: () {},
            onCheckboxTap: () {},
            onTimerTap: (_) async {
              timer++;
              return null;
            },
            onMenuTap: () {},
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.timer_outlined));
      await tester.pumpAndSettle();
      expect(timer, 1);
    });

    testWidgets('tap on menu icon fires onMenuTap', (tester) async {
      var menu = 0;
      await tester.pumpWidget(
        buildTestApp(
          IndentedHabitItem(
            habit: _makeHabit(),
            selectedDate: DateTime.now(),
            onRowBodyTap: () {},
            onCheckboxTap: () {},
            onTimerTap: (_) async => null,
            onMenuTap: () => menu++,
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pump();
      expect(menu, 1);
    });

    testWidgets('tapping the TIMER icon with a returned duration starts the timer',
        (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          IndentedHabitItem(
            habit: _makeHabit(timerDurationMinutes: 5),
            selectedDate: DateTime.now(),
            onRowBodyTap: () {},
            onCheckboxTap: () {},
            onTimerTap: (_) async => 5,
            onMenuTap: () {},
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.timer_outlined));
      await tester.pumpAndSettle();
      // Running-timer state shows the pause control.
      expect(find.byIcon(Icons.pause), findsOneWidget);
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
            onTimerTap: (_) async => null,
            onMenuTap: () {},
          ),
        ),
      );
      final text = tester.widget<Text>(find.text('Morning Meditation'));
      expect(text.style?.decoration, TextDecoration.lineThrough);
    });

    testWidgets('shows check icon and undo when completed', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          IndentedHabitItem(
            habit: _makeHabit(completedToday: true, id: 'h2'),
            selectedDate: DateTime.now(),
            onRowBodyTap: () {},
            onCheckboxTap: () {},
            onTimerTap: (_) async => null,
            onMenuTap: () {},
          ),
        ),
      );
      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(find.byIcon(Icons.undo), findsOneWidget);
    });

    testWidgets('completed card has darker background', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          IndentedHabitItem(
            habit: _makeHabit(completedToday: true),
            selectedDate: DateTime.now(),
            onRowBodyTap: () {},
            onCheckboxTap: () {},
            onTimerTap: (_) async => null,
            onMenuTap: () {},
          ),
        ),
      );
      final container =
          tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
      final decoration = container.decoration as BoxDecoration;
      final gradient = decoration.gradient as LinearGradient;
      // Completed cards use the dark background gradient (0xFF1A1A2E)
      expect(
        gradient.colors[0],
        const Color(0xFF1A1A2E).withValues(alpha: 0.85),
      );
    });
  });

  group('IndentedHabitItem - attribute tag', () {
    testWidgets('shows attribute abbreviation pill', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          IndentedHabitItem(
            habit: _makeHabit(),
            selectedDate: DateTime.now(),
            onRowBodyTap: () {},
            onCheckboxTap: () {},
            onTimerTap: (_) async => null,
            onMenuTap: () {},
          ),
        ),
      );
      // Default habit attribute is vitality -> 'VIT'
      expect(find.text('VIT'), findsOneWidget);
    });
  });
}
