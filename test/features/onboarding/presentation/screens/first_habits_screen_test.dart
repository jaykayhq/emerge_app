import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/features/auth/domain/entities/auth_user.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:emerge_app/features/onboarding/domain/models/starter_habit_blueprint.dart';
import 'package:emerge_app/features/onboarding/presentation/providers/onboarding_state_notifier.dart';
import 'package:emerge_app/features/onboarding/presentation/screens/first_habits_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import '../../../habits/data/repositories/fake_habit_repository.dart';

class _FakeOnboarding extends EnhancedOnboardingNotifier {
  _FakeOnboarding(this._initial);
  final EnhancedOnboardingState _initial;

  @override
  EnhancedOnboardingState build() => _initial;

  @override
  void removeHabitStack(String stackId) {}

  @override
  Future<void> completeMilestone(int milestone) async {}
}

class _CapturingHabitRepository extends FakeHabitRepository {
  List<StarterHabitBlueprint> createdBlueprints = [];

  @override
  Future<Either<Failure, List<Habit>>> createStarterPack({
    required String userId,
    required List<StarterHabitBlueprint> blueprints,
    String? archetypeName,
    List<String> interestIds = const [],
    String? clubId,
  }) async {
    createdBlueprints = List.of(blueprints);
    return super.createStarterPack(
      userId: userId,
      blueprints: blueprints,
      archetypeName: archetypeName,
      interestIds: interestIds,
      clubId: clubId,
    );
  }
}

void main() {
  Future<ProviderContainer> container(_CapturingHabitRepository repo) async {
    return ProviderContainer(
      overrides: [
        habitRepositoryProvider.overrideWithValue(repo),
        authStateChangesProvider.overrideWithValue(
          const AsyncValue.data(AuthUser(id: 'u1', email: 'u@x.com')),
        ),
        enhancedOnboardingProvider.overrideWith(
          () => _FakeOnboarding(
            const EnhancedOnboardingState(
              selectedArchetype: UserArchetype.athlete,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> pump(WidgetTester tester, ProviderContainer c) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: const MaterialApp(home: FirstHabitsScreen()),
      ),
    );
    // Elapse the flutter_animate fade-in delays so no timers linger.
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('CTA disabled until at least one habit is selected',
      (tester) async {
    final repo = _CapturingHabitRepository();
    final c = await container(repo);
    addTearDown(c.dispose);
    await pump(tester, c);

    final start = find.widgetWithText(ElevatedButton, 'START MY JOURNEY');
    expect(tester.widget<ElevatedButton>(start).enabled, isFalse);

    await tester.tap(find.text('10-minute walk outside'));
    await tester.pump();
    expect(tester.widget<ElevatedButton>(start).enabled, isTrue);
  });

  testWidgets('creates the pack with only the selected habits',
      (tester) async {
    final repo = _CapturingHabitRepository();
    final c = await container(repo);
    addTearDown(c.dispose);
    await pump(tester, c);

    await tester.tap(find.text('Drink one glass of water'));
    await tester.pump();
    await tester.tap(find.text('10-minute walk outside'));
    await tester.pump();

    await tester.tap(find.text('START MY JOURNEY'));
    await tester.pump();
    // The screen has no GoRouter in this test, so the world-reveal push fails
    // and a "failed to save" snackbar appears; elapse its display timer.
    await tester.pump(const Duration(seconds: 5));

    final ids = repo.createdBlueprints.map((b) => b.id).toList();
    expect(ids, contains('athlete.hydration.glass'));
    expect(ids, contains('athlete.walk.10min'));
    expect(ids, isNot(contains('athlete.warmup.breath')));
  });
}
