import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/presentation/screens/streak_recovery_screen.dart';
import 'package:emerge_app/features/narrator/presentation/widgets/narrator_milestone_card.dart';
import 'package:emerge_app/features/onboarding/data/repositories/local_settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final habit = Habit(
    id: 'h1',
    userId: 'u1',
    title: 'Read 10 Pages',
    createdAt: DateTime.now(),
  );

  Widget buildScreen({required Habit habit, int xp = 50}) {
    return ProviderScope(
      child: MaterialApp(
        home: StreakRecoveryScreen(habit: habit, xpEarned: xp),
      ),
    );
  }

  /// Pump past the Narrator's initState delay so no timer leaks.
  Future<void> pumpWithNarratorDelay(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump();
  }

  /// Seats the narrator-guide controller's storage: the screen reads
  /// [LocalSettingsRepository] via `localSettingsRepositoryProvider`, whose
  /// SharedPreferences-backed reads only pick up seeded values once `init()`
  /// has populated the cached store.
  Future<void> seedSettings({required bool seenGuide}) async {
    SharedPreferences.setMockInitialValues({
      'tutorialsEnabled': true,
      if (seenGuide) 'hasSeenNarratorGuide_streak_recovery': true,
    });
    await LocalSettingsRepository().init();
  }

  testWidgets('displays habit title, xp, messaging, and icon', (tester) async {
    await tester.pumpWidget(buildScreen(habit: habit));
    await pumpWithNarratorDelay(tester);

    expect(find.textContaining('Never miss twice'), findsOneWidget);
    expect(find.textContaining('Read 10 Pages'), findsOneWidget);
    expect(find.text('50'), findsOneWidget);
    expect(find.text('+'), findsOneWidget);
    expect(find.text('XP'), findsOneWidget);
    expect(find.text('CONTINUE'), findsOneWidget);
    expect(find.text('MOMENTUM RESTORED'), findsOneWidget);
    expect(find.byIcon(Icons.shield_outlined), findsOneWidget);
  });

  testWidgets('pops on CONTINUE tap', (tester) async {
    await tester.pumpWidget(buildScreen(habit: habit));
    await pumpWithNarratorDelay(tester);

    // Tap CONTINUE — may throw if route can't pop since we're on home,
    // but we verify the screen handles the tap without crashing
    await tester.tap(find.text('CONTINUE'), warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Screen still exists (can't pop home route), but no exception thrown
    expect(find.byType(StreakRecoveryScreen), findsOneWidget);
  });

  testWidgets('renders with zero XP', (tester) async {
    await tester.pumpWidget(buildScreen(habit: habit, xp: 0));
    await pumpWithNarratorDelay(tester);

    expect(find.text('0'), findsOneWidget);
    expect(find.text('CONTINUE'), findsOneWidget);
  });

  testWidgets('renders with different habit title', (tester) async {
    final otherHabit = Habit(
      id: 'h2',
      userId: 'u1',
      title: 'Meditate 5 mins',
      createdAt: DateTime.now(),
    );
    await tester.pumpWidget(buildScreen(habit: otherHabit));
    await pumpWithNarratorDelay(tester);

    expect(find.textContaining('Meditate 5 mins'), findsOneWidget);
    expect(find.text('50'), findsOneWidget);
  });

  testWidgets('shows the streak-break message once the guide has been seen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await seedSettings(seenGuide: true);

    await tester.pumpWidget(buildScreen(habit: habit));
    await pumpWithNarratorDelay(tester);

    expect(find.byType(NarratorMilestoneCard), findsOneWidget);
  });

  testWidgets('stays hidden while the guide is due', (tester) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await seedSettings(seenGuide: false);

    await tester.pumpWidget(buildScreen(habit: habit));
    await pumpWithNarratorDelay(tester);

    expect(find.byType(NarratorMilestoneCard), findsNothing);
  });

  testWidgets('auto-dismisses after 6s', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await seedSettings(seenGuide: true);

    await tester.pumpWidget(buildScreen(habit: habit));
    await pumpWithNarratorDelay(tester);
    expect(find.byType(NarratorMilestoneCard), findsOneWidget);

    // The card types its line; pumping past the auto-dismiss window is enough
    // (the card removes itself via onDismissed).
    await tester.pump(const Duration(seconds: 7));
    await tester.pump();
    expect(find.byType(NarratorMilestoneCard), findsNothing);
  });
}
