import 'package:emerge_app/features/auth/domain/entities/auth_user.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/domain/services/smart_defaults_service.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_suggestions_provider.dart';
import 'package:emerge_app/features/habits/presentation/providers/smart_defaults_provider.dart';
import 'package:emerge_app/features/habits/presentation/screens/habit_create_screen.dart'
    show HabitCreateScreen;
import 'package:emerge_app/features/habits/presentation/widgets/identity_sentence_builder.dart';
import 'package:emerge_app/features/onboarding/data/repositories/local_settings_repository.dart';
import 'package:emerge_app/features/world_map/presentation/widgets/nebula_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  group('HabitCreateScreen - time-of-day persistence', () {
    testWidgets('stores timeOfDayPreference derived from the reminder time',
        (tester) async {
      Habit? captured;
      await tester.pumpWidget(
        createScreenUnderTest(
          // `_createHabit` reads `authStateChangesProvider.value` synchronously,
          // but `ref.read` alone doesn't subscribe a StreamProvider in
          // Riverpod 3 — nothing else in this screen tree watches auth.
          // Watch it here so the stream value is ready before FORGE HABIT.
          screen: Consumer(
            builder: (context, ref, _) {
              ref.watch(authStateChangesProvider);
              return const HabitCreateScreen();
            },
          ),
          overrides: [
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
            authStateChangesProvider.overrideWith(
              (ref) =>
                  Stream.value(const AuthUser(id: 'u1', email: 'u@x.com')),
            ),
            createHabitProvider.overrideWith((ref, habit) async {
              captured = habit;
            }),
          ],
        ),
      );
      await tester.pump();

      // Fill the title via the typeahead (this also enables FORGE HABIT).
      await tester.tap(find.text('action'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.enterText(find.byType(TextField), 'med');
      await tester.pump();
      await tester.tap(find.text('Meditate'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      await tester.tap(find.text('FORGE HABIT'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(captured, isNotNull);
      // Smart default time is 7:00 AM → morning.
      expect(captured!.timeOfDayPreference, TimeOfDayPreference.morning);
      expect(captured!.reminderTime, const TimeOfDay(hour: 7, minute: 0));
    });
  });

  group('HabitCreateScreen - integrations', () {
    testWidgets('integration pill opens the sheet and applies a steps target',
        (tester) async {
      await tester.pumpWidget(_createTestWidget());
      await tester.pump();

      expect(find.text('NO INTEGRATION'), findsOneWidget);

      await tester.tap(find.text('NO INTEGRATION'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('LINK INTEGRATION'), findsOneWidget);
      await tester.tap(find.text('Health Steps'));
      await tester.pump();

      await tester.enterText(
        find.byKey(const Key('integration_target_field')),
        '10000',
      );
      await tester.tap(find.text('CONFIRM'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('STEPS 10000'), findsOneWidget);
    });

    testWidgets('invalid target keeps the sheet open and shows an error',
        (tester) async {
      await tester.pumpWidget(_createTestWidget());
      await tester.pump();

      await tester.tap(find.text('NO INTEGRATION'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      await tester.tap(find.text('Health Steps'));
      await tester.pump();

      await tester.enterText(
        find.byKey(const Key('integration_target_field')),
        '0',
      );
      await tester.tap(find.text('CONFIRM'));
      await tester.pump();

      // Sheet stays open and the inline error is shown.
      expect(find.text('LINK INTEGRATION'), findsOneWidget);
      expect(find.text('Enter a valid target above 0.'), findsOneWidget);
      // Nothing was applied — the pill is unchanged.
      expect(find.text('NO INTEGRATION'), findsOneWidget);
      expect(find.text('STEPS 0'), findsNothing);
    });

    testWidgets('switching integration type resets target and clears the error',
        (tester) async {
      await tester.pumpWidget(_createTestWidget());
      await tester.pump();

      await tester.tap(find.text('NO INTEGRATION'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      await tester.tap(find.text('Health Steps'));
      await tester.pump();

      // Enter an invalid target and confirm → error appears.
      await tester.enterText(
        find.byKey(const Key('integration_target_field')),
        '0',
      );
      await tester.tap(find.text('CONFIRM'));
      await tester.pump();
      expect(find.text('Enter a valid target above 0.'), findsOneWidget);

      // Switching to Screen Time Limit resets the field to its default and
      // clears the error.
      await tester.tap(find.text('Screen Time Limit'));
      await tester.pump();

      final targetField = tester.widget<TextField>(
        find.byKey(const Key('integration_target_field')),
      );
      expect(targetField.controller!.text, '30');
      expect(find.text('Enter a valid target above 0.'), findsNothing);
    });
  });
}
