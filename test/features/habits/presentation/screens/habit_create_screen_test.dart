import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/domain/services/smart_defaults_service.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_suggestions_provider.dart';
import 'package:emerge_app/features/habits/presentation/providers/smart_defaults_provider.dart';
import 'package:emerge_app/features/habits/presentation/screens/habit_create_screen.dart'
    show HabitCreateScreen;
import 'package:emerge_app/features/habits/presentation/widgets/identity_sentence_builder.dart';
import 'package:emerge_app/features/onboarding/data/repositories/local_settings_repository.dart';
import 'package:emerge_app/features/world_map/presentation/widgets/nebula_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  setUp(() async {
    // Suppress the first-visit node guide (its full-screen overlay would
    // swallow the taps this suite performs).
    SharedPreferences.setMockInitialValues({
      'tutorialsEnabled': true,
      'hasSeenNarratorGuide_habit_create': true,
    });
    await LocalSettingsRepository().init();
  });

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

    testWidgets('renders the nebula background behind the form',
        (tester) async {
      await tester.pumpWidget(_createTestWidget());
      await tester.pump();

      expect(find.byType(NebulaBackground), findsOneWidget);
    });

    testWidgets('title sheet live-filters recommendations as you type',
        (tester) async {
      await tester.pumpWidget(_createTestWidget());
      await tester.pump();

      // Open the action sheet (tap the 'action' pill in the hero sentence).
      // Note: bounded pumps only — the nebula background animates forever,
      // so pumpAndSettle would never settle.
      await tester.tap(find.text('action'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350)); // sheet slide-up
      expect(find.text('WHAT ACTION?'), findsOneWidget);

      // Initially the curated suggestions are shown (top of the ranking).
      expect(find.text('Drink water'), findsOneWidget);

      // Type a term — only the closest matches stay ('Meditate' is a prefix
      // match; 'Metta Meditation' is a substring match from the template
      // library).
      await tester.enterText(find.byType(TextField), 'med');
      await tester.pump();

      expect(find.text('Drink water'), findsNothing);
      expect(find.text('Meditate'), findsOneWidget);
      expect(find.text('💖 Metta Meditation'), findsOneWidget);

      // Picking a template chip fills the title AND the emoji.
      await tester.tap(find.text('💖 Metta Meditation'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350)); // sheet slide-down

      expect(find.text('WHAT ACTION?'), findsNothing);
      expect(find.text('💖'), findsOneWidget);
      expect(find.text('Metta Meditation'), findsOneWidget);
    });
  });
}
