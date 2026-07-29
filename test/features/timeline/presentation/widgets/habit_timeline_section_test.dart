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
            habit: _makeHabit(timerDurationMinutes: 0),
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
      // No timer set -> standard mark-complete checkbox.
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
            onTimerTap: (_) async => null,
            onMenuTap: () {},
          ),
        ),
      );
      expect(find.byType(Dismissible), findsNothing);
    });

    testWidgets('habit with timer set shows mark-complete checkbox + timer badge, no PLAY',
        (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          IndentedHabitItem(
            habit: _makeHabit(timerDurationMinutes: 5),
            selectedDate: DateTime.now(),
            onRowBodyTap: () {},
            onCheckboxTap: () {},
            onTimerTap: (_) async => null,
            onMenuTap: () {},
          ),
        ),
      );
      // Timer-set state: mark-complete checkbox is present (PLAY removed).
      expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsNothing);
      // Timer badge reflects the configured duration.
      expect(find.text('⏱ 5m'), findsOneWidget);
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

    testWidgets('tap on checkbox fires onCheckboxTap only', (tester) async {
      var body = 0, checkbox = 0, menu = 0;
      await tester.pumpWidget(
        buildTestApp(
          IndentedHabitItem(
            habit: _makeHabit(timerDurationMinutes: 0),
            selectedDate: DateTime.now(),
            onRowBodyTap: () => body++,
            onCheckboxTap: () => checkbox++,
            onTimerTap: (_) async => null,
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
            habit: _makeHabit(timerDurationMinutes: 2),
            selectedDate: DateTime.now(),
            onRowBodyTap: () => body++,
            onCheckboxTap: () => checkbox++,
            onTimerTap: (_) async {
              timer++;
              return null;
            },
            onMenuTap: () => menu++,
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.timer_outlined));
      await tester.pumpAndSettle();
      expect(timer, 1);
      expect(body, 0);
    });

    testWidgets('tap on menu icon fires onMenuTap only', (tester) async {
      var body = 0, checkbox = 0, menu = 0;
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
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pump();
      expect(menu, 1);
      expect(body, 0);
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
      // Running-timer state shows the pause control (no mark-complete).
      expect(find.byIcon(Icons.pause), findsOneWidget);
      expect(find.byIcon(Icons.radio_button_unchecked), findsNothing);
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

    testWidgets('shows check_circle and xp badge when completed', (tester) async {
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
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.textContaining('XP'), findsWidgets);
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

  group('IndentedHabitItem - first incomplete glow', () {
    testWidgets('first incomplete habit has green border glow', (tester) async {
      final now = DateTime.now();
      await tester.pumpWidget(
        buildTestApp(
          IndentedHabitItem(
            habit: _makeHabit(completedToday: false),
            selectedDate: now,
            onRowBodyTap: () {},
            onCheckboxTap: () {},
            onTimerTap: (_) async => null,
            onMenuTap: () {},
            isFirstIncomplete: true,
          ),
        ),
      );
      final container =
          tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
      final decoration = container.decoration as BoxDecoration;
      expect(
        decoration.border,
        Border.all(
          color: const Color(0xFF2BEE79).withValues(alpha: 0.25),
          width: 1.5,
        ),
      );
    });

    testWidgets('non-first incomplete uses default border', (tester) async {
      final now = DateTime.now();
      await tester.pumpWidget(
        buildTestApp(
          IndentedHabitItem(
            habit: _makeHabit(completedToday: false),
            selectedDate: now,
            onRowBodyTap: () {},
            onCheckboxTap: () {},
            onTimerTap: (_) async => null,
            onMenuTap: () {},
            isFirstIncomplete: false,
          ),
        ),
      );
      final container =
          tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
      final decoration = container.decoration as BoxDecoration;
      expect(
        decoration.border,
        Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1.0,
        ),
      );
    });
  });

  group('IndentedHabitItem - timer habit button layout (user intent)', () {
    // Per request: remove the separate PLAY button, restore the mark-complete
    // checkbox for timer habits, and make the TIMER button do what PLAY did
    // (start the countdown).

    testWidgets('timer-set habit shows mark-complete checkbox (no PLAY button)',
        (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          IndentedHabitItem(
            habit: _makeHabit(timerDurationMinutes: 5),
            selectedDate: DateTime.now(),
            onRowBodyTap: () {},
            onCheckboxTap: () {},
            onTimerTap: (_) async => null,
            onMenuTap: () {},
          ),
        ),
      );
      // Restored mark-complete checkbox is present even when a timer is set.
      expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget);
      // The dedicated PLAY button must be gone.
      expect(find.byIcon(Icons.play_arrow), findsNothing);
      // Timer badge still reflects the configured duration.
      expect(find.text('⏱ 5m'), findsOneWidget);
    });

    testWidgets('tapping the TIMER icon starts the timer (old PLAY behavior)',
        (tester) async {
      var timer = 0;
      await tester.pumpWidget(
        buildTestApp(
          IndentedHabitItem(
            habit: _makeHabit(timerDurationMinutes: 5),
            selectedDate: DateTime.now(),
            onRowBodyTap: () {},
            onCheckboxTap: () {},
            onTimerTap: (_) async {
              timer++;
              return 5;
            },
            onMenuTap: () {},
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.timer_outlined));
      await tester.pumpAndSettle();
      // Timer started -> running state shows pause control.
      expect(timer, 1);
      expect(find.byIcon(Icons.pause), findsOneWidget);
      expect(find.byIcon(Icons.radio_button_unchecked), findsNothing);
    });
  });
}
