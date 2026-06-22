import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/auth/domain/entities/auth_user.dart';
import 'package:emerge_app/features/blueprints/domain/models/blueprint.dart';
import 'package:emerge_app/features/blueprints/presentation/providers/blueprint_detail_controller.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/monetization/presentation/providers/subscription_provider.dart'
    show isPremiumProvider, IsPremium;
import 'package:emerge_app/features/social/presentation/screens/blueprint_detail_screen.dart';

class MockBlueprintDetailController extends Mock
    implements BlueprintDetailController {}

class _MockIsPremium extends IsPremium {
  @override
  Future<bool> build() async => false;
}

final testBlueprint = Blueprint(
  id: 'test-bp-1',
  creatorUserId: 'creator-1',
  creatorName: 'Test Creator',
  creatorArchetype: 'Scholar',
  title: 'Test Blueprint',
  description: 'A test blueprint description.',
  habits: [],
  createdAt: DateTime(2024, 1, 1),
  category: 'Scholar',
  imageUrl: null,
);

final testBlueprintWithTimerHealth = Blueprint(
  id: 'test-bp-2',
  creatorUserId: 'creator-1',
  creatorName: 'Test Creator',
  creatorArchetype: 'Scholar',
  title: 'Timer Health Blueprint',
  description: 'Has timer and health integration.',
  habits: [
    const BlueprintHabit(
      title: 'Morning Run',
      frequency: 'Daily',
      timeOfDay: 'Morning',
      timerDurationMinutes: 10,
      integrationType: HabitIntegrationType.healthSteps,
    ),
    const BlueprintHabit(
      title: 'Screen Limit',
      frequency: 'Daily',
      timeOfDay: 'Evening',
      timerDurationMinutes: 5,
      integrationType: HabitIntegrationType.screenTimeLimit,
    ),
    const BlueprintHabit(
      title: 'Read a Book',
      frequency: 'Daily',
      timeOfDay: 'Anytime',
      timerDurationMinutes: 0,
      integrationType: HabitIntegrationType.none,
    ),
  ],
  createdAt: DateTime(2024, 1, 1),
  category: 'Fitness',
  imageUrl: null,
);

final testUser = AuthUser(
  id: 'test-uid',
  email: 'test@example.com',
  displayName: 'Test User',
);

Widget _buildTest() {
  return ProviderScope(
    overrides: [
      authStateChangesProvider.overrideWith(
        (ref) => Stream.value(testUser),
      ),
      isPremiumProvider.overrideWith(() => _MockIsPremium()),
      blueprintDetailControllerProvider.overrideWith(
        () => MockBlueprintDetailController(),
      ),
    ],
    child: MaterialApp(
      home: BlueprintDetailScreen(blueprint: testBlueprint),
    ),
  );
}

void main() {
  testWidgets('BlueprintDetailScreen renders with data', (tester) async {
    await tester.pumpWidget(_buildTest());
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('By Test Creator'), findsOneWidget);
    expect(find.text('A test blueprint description.'), findsOneWidget);
    expect(find.text('THE HABIT STACK'), findsOneWidget);
    expect(find.text('ABOUT THIS BLUEPRINT'), findsOneWidget);
  });

  testWidgets('BlueprintDetailScreen shows adopt button',
      (tester) async {
    await tester.pumpWidget(_buildTest());
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('ADOPT BLUEPRINT'), findsOneWidget);
  });

  group('timer & health integration badges', () {
    Widget buildTestWithTimerHealth() {
      return ProviderScope(
        overrides: [
          authStateChangesProvider.overrideWith(
            (ref) => Stream.value(testUser),
          ),
          isPremiumProvider.overrideWith(() => _MockIsPremium()),
          blueprintDetailControllerProvider.overrideWith(
            () => MockBlueprintDetailController(),
          ),
        ],
        child: MaterialApp(
          home: BlueprintDetailScreen(blueprint: testBlueprintWithTimerHealth),
        ),
      );
    }

    testWidgets('shows timer badge when habit has timerDurationMinutes > 0',
        (tester) async {
      await tester.pumpWidget(buildTestWithTimerHealth());
      await tester.pump(const Duration(milliseconds: 100));

      // Morning Run has 10M timer
      expect(find.text('10M'), findsOneWidget);
      // Screen Limit has 5M timer
      expect(find.text('5M'), findsOneWidget);
    });

    testWidgets('shows health steps badge when integration is healthSteps',
        (tester) async {
      await tester.pumpWidget(buildTestWithTimerHealth());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Steps'), findsOneWidget);
    });

    testWidgets('shows screen time badge when integration is screenTimeLimit',
        (tester) async {
      await tester.pumpWidget(buildTestWithTimerHealth());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Screen Time'), findsOneWidget);
    });

    testWidgets('hides timer badge when timerDurationMinutes is 0',
        (tester) async {
      await tester.pumpWidget(buildTestWithTimerHealth());
      await tester.pump(const Duration(milliseconds: 100));

      // Read a Book has 0M timer — should not show a timer badge
      // We check that only 10M and 5M appear, not '0M'
      expect(find.text('0M'), findsNothing);
    });

    testWidgets('shows health integration badges for habits with non-none integration',
        (tester) async {
      await tester.pumpWidget(buildTestWithTimerHealth());
      await tester.pump(const Duration(milliseconds: 100));

      // Morning Run has healthSteps → shows 'Steps' badge
      // Screen Limit has screenTimeLimit → shows 'Screen Time' badge
      expect(find.text('Steps'), findsOneWidget);
      expect(find.text('Screen Time'), findsOneWidget);
    });
  });
}
