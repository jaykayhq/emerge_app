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

  testWidgets('starter cards surface the recommended duration',
      (tester) async {
    final repo = _CapturingHabitRepository();
    final c = await container(repo);
    addTearDown(c.dispose);
    await pump(tester, c);

    expect(find.byIcon(Icons.timer_outlined), findsWidgets);
    final durationLabels = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? '')
        .where((s) => RegExp(r'^\d+ MIN$').hasMatch(s))
        .toList();
    expect(durationLabels, isNotEmpty,
        reason: 'at least one starter card must show a duration');
  });

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

  testWidgets('customized title reaches the created pack', (tester) async {
    final repo = _CapturingHabitRepository();
    final c = await container(repo);
    addTearDown(c.dispose);
    await pump(tester, c);

    final card = find.ancestor(
      of: find.text('Drink one glass of water'),
      matching: find.byType(AnimatedContainer),
    );
    await tester.tap(
      find.descendant(of: card, matching: find.byIcon(Icons.tune)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.enterText(
      find.widgetWithText(TextField, 'Habit Title'),
      'Morning hydration ritual',
    );
    await tester.tap(find.text('SAVE HABIT'));
    await tester.pump(const Duration(milliseconds: 300)); // _save delay + pop
    await tester.pump(const Duration(milliseconds: 300)); // sheet exit animation
    // Let any post-save snackbar fully expire so it can't obscure the CTA.
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('10-minute walk outside'));
    await tester.pump();

    await tester.tap(find.text('START MY JOURNEY'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));

    final byId = {for (final b in repo.createdBlueprints) b.id: b.title};
    expect(byId['athlete.hydration.glass'], 'Morning hydration ritual');
    expect(byId['athlete.walk.10min'], '10-minute walk outside');
  });
}
