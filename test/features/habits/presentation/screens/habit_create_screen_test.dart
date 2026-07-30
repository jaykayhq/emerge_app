import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/domain/services/smart_defaults_service.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_suggestions_provider.dart';
import 'package:emerge_app/features/habits/presentation/providers/smart_defaults_provider.dart';
import 'package:emerge_app/features/habits/presentation/screens/habit_create_screen.dart'
    show HabitCreateScreen;
import 'package:emerge_app/features/habits/presentation/widgets/identity_sentence_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../../helpers/widget_test_utils.dart';

Widget _createTestWidget() {
  return createScreenUnderTest(
    screen: const HabitCreateScreen(),
    overrides: [
      // Short-circuit the archetype/habits-dependent providers so the screen
      // renders without Firestore or auth wiring.
      smartDefaultsProvider.overrideWith(
        (ref) => const SmartDefaults(
          time: TimeOfDay(hour: 7, minute: 0),
          attribute: HabitAttribute.vitality,
          difficulty: HabitDifficulty.easy,
          timerMinutes: 5,
        ),
      ),
      habitSuggestionsProvider.overrideWith(
        (ref) => const <String>['Drink water', 'Meditate'],
      ),
    ],
  );
}

void main() {
  group('HabitCreateScreen', () {
    testWidgets('renders header, identity builder, emoji + difficulty',
        (tester) async {
      await tester.pumpWidget(_createTestWidget());
      await tester.pump();

      // App bar title.
      expect(find.text('CREATE HABIT'), findsOneWidget);
      // Identity sentence builder copy.
      expect(
        find.text('I am the type of person who'),
        findsOneWidget,
      );
      // Default emoji shown in the sentence pill.
      expect(find.text('🔥'), findsOneWidget);
      // Difficulty chips render (default difficulty = medium).
      expect(find.text('MEDIUM'), findsOneWidget);
      // IdentitySentenceBuilder is present.
      expect(find.byType(IdentitySentenceBuilder), findsOneWidget);
    });

    testWidgets('forge button disabled until action is set',
        (tester) async {
      await tester.pumpWidget(_createTestWidget());
      await tester.pump();

      final forgeButton =
          find.widgetWithText(ElevatedButton, 'FORGE HABIT');
      expect(forgeButton, findsOneWidget);
      // With no action set, the button is disabled.
      expect(tester.widget<ElevatedButton>(forgeButton).enabled, isFalse);
    });

    testWidgets('sentence shows placeholder pills when empty',
        (tester) async {
      await tester.pumpWidget(_createTestWidget());
      await tester.pump();

      // Placeholder text for unset pills.
      expect(find.text('action'), findsOneWidget);
      expect(find.text('where...'), findsOneWidget);
    });
  });
}
