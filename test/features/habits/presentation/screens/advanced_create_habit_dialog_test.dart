import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:emerge_app/features/habits/presentation/screens/advanced_create_habit_dialog.dart';
import 'package:emerge_app/features/monetization/presentation/providers/subscription_provider.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/companion/data/repositories/companion_repository.dart';
import 'package:emerge_app/features/companion/presentation/providers/companion_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../helpers/widget_test_utils.dart';
import '../../../../helpers/mocks/habit_mocks.dart';

class TestIsPremium extends IsPremium {
  final bool premium;

  TestIsPremium(this.premium);

  @override
  Future<bool> build() async => premium;
}

Widget _createTestWidget({
  required MockHabitRepository mockRepo,
  required CompanionRepository compRepo,
}) {
  return createScreenUnderTest(
    screen: MaterialApp(
      home: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => showDialog(
            context: context,
            builder: (_) => const AdvancedCreateHabitDialog(),
          ),
          child: const Text('Open Dialog'),
        ),
      ),
    ),
    overrides: [
      habitRepositoryProvider.overrideWithValue(mockRepo),
      habitsProvider.overrideWith((ref) => Stream.value(testHabits)),
      isPremiumProvider.overrideWith(() => TestIsPremium(false)),
      userStatsStreamProvider.overrideWith(
        (ref) => Stream.value(
          const UserProfile(uid: 'test', displayName: 'Test'),
        ),
      ),
      companionRepositoryProvider.overrideWithValue(compRepo),
    ],
  );
}

void main() {
  late MockHabitRepository mockRepo;
  late CompanionRepository compRepo;

  setUp(() async {
    mockRepo = MockHabitRepository();
    SharedPreferences.setMockInitialValues({
      'companion_visited_/habits/create': true,
    });
    compRepo = CompanionRepository();
    await compRepo.init();
  });

  Future<void> openDialog(WidgetTester tester) async {
    await tester.pumpWidget(_createTestWidget(mockRepo: mockRepo, compRepo: compRepo));
    await tester.pump();
    await tester.tap(find.text('Open Dialog'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    // flush microtasks from the Future.delayed callback
    await tester.pump();
  }

  group('AdvancedCreateHabitDialog', () {
    testWidgets('renders dialog with form fields', (tester) async {
      await openDialog(tester);

      expect(find.text('HABIT TITLE'), findsOneWidget);
      expect(find.text('FORGE HABIT'), findsOneWidget);
      expect(find.text('Identity'), findsOneWidget);
      expect(find.text('ICON'), findsOneWidget);
      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('shows validation error on empty title', (tester) async {
      await openDialog(tester);

      final forgeButton = find.text('FORGE HABIT');
      await tester.ensureVisible(forgeButton);
      await tester.tap(forgeButton);
      await tester.pump();

      expect(find.text('Required'), findsOneWidget);
    });

    testWidgets('entering title updates identity statement', (tester) async {
      await openDialog(tester);

      await tester.enterText(find.byType(TextFormField).first, 'Morning Run');
      await tester.pump();

      // RichText with TextSpan — use byWidgetPredicate
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is RichText &&
              w.text.toPlainText().contains('I am the type of person who'),
        ),
        findsOneWidget,
      );
    });
  });
}
