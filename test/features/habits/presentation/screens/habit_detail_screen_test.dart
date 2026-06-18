import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:emerge_app/features/habits/presentation/screens/habit_detail_screen.dart';
import '../../../../helpers/widget_test_utils.dart';
import '../../../../helpers/mocks/habit_mocks.dart';

Widget _createTestWidget({
  required List<Habit> habits,
  required MockHabitRepository mockRepo,
}) {
  return createScreenUnderTest(
    screen: const HabitDetailScreen(habitId: 'h1'),
    overrides: [
      habitRepositoryProvider.overrideWithValue(mockRepo),
      habitsProvider.overrideWith((ref) => Stream.value(habits)),
    ],
  );
}

void main() {
  late MockHabitRepository mockRepo;

  setUp(() {
    mockRepo = MockHabitRepository();
  });

  group('HabitDetailScreen - loading', () {
    testWidgets('shows loading indicator', (tester) async {
      await tester.pumpWidget(
        createScreenUnderTest(
          screen: const HabitDetailScreen(habitId: 'h1'),
          overrides: [
            habitRepositoryProvider.overrideWithValue(mockRepo),
            habitsProvider.overrideWith((ref) => const Stream.empty()),
          ],
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('HabitDetailScreen - habit not found', () {
    testWidgets('shows not found message', (tester) async {
      await tester.pumpWidget(
        _createTestWidget(habits: [], mockRepo: mockRepo),
      );
      await tester.pump();

      expect(find.text('Habit not found'), findsOneWidget);
    });
  });

  group('HabitDetailScreen - habit data', () {
    testWidgets('renders habit title and streak', (tester) async {
      await tester.pumpWidget(
        _createTestWidget(habits: testHabits, mockRepo: mockRepo),
      );
      await tester.pump();

      expect(find.text('Morning Run'), findsOneWidget);
      expect(find.textContaining('day streak'), findsOneWidget);
    });

    testWidgets('renders completed today badge', (tester) async {
      final completedHabit = testHabits[0].copyWith(
        lastCompletedDate: DateTime.now(),
      );

      await tester.pumpWidget(
        _createTestWidget(
          habits: [completedHabit, testHabits[1]],
          mockRepo: mockRepo,
        ),
      );
      await tester.pump();

      expect(find.text('COMPLETED TODAY'), findsOneWidget);
      expect(find.text('Completed Today!'), findsOneWidget);
    });
  });
}
