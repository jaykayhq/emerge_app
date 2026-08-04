import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/monetization/domain/services/coach_ask_quota.dart';
import 'package:emerge_app/features/monetization/presentation/providers/subscription_provider.dart';
import 'package:emerge_app/features/narrator/presentation/providers/narrator_providers.dart';
import 'package:emerge_app/features/narrator/presentation/widgets/narrator_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Habit _habit(String title) => Habit(
  id: title,
  userId: 'u',
  title: title,
  cue: '',
  routine: '',
  reward: '',
  createdAt: DateTime.now(),
  difficulty: HabitDifficulty.medium,
);

/// isPremiumProvider is a class-based AsyncNotifier ([IsPremium]), so the
/// override must supply a subclass rather than a builder function.
class _FakeIsPremium extends IsPremium {
  _FakeIsPremium(this._premium);
  final bool _premium;

  @override
  Future<bool> build() async => _premium;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> container({List<Habit> habits = const []}) async {
    // NOTE: no SharedPreferences.setMockInitialValues({}) here — that would
    // wipe the per-test quota seeds set before container() is called (the
    // lazy keepAlive coachAskQuotaControllerProvider reads prefs on first
    // watch, which happens after pumpCard). Tests that need a quota seed
    // pass it explicitly via setMockInitialValues in their body.
    return ProviderContainer(
      overrides: [
        habitsProvider.overrideWith((ref) => Stream.value(habits)),
        userStatsStreamProvider.overrideWith(
          (ref) => Stream.value(UserProfile(uid: 'u')),
        ),
        latestNarratorInsightProvider.overrideWith((ref) async => null),
        isPremiumProvider.overrideWith(() => _FakeIsPremium(false)),
      ],
    );
  }

  Future<void> pumpCard(WidgetTester tester, ProviderContainer c) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: const MaterialApp(home: Scaffold(body: NarratorCard())),
      ),
    );
    // Let the typed line finish (no pumpAndSettle — blinking caret).
    await tester.pump(const Duration(seconds: 2));
  }

  testWidgets('shows the day-status line when nothing is pending', (
    tester,
  ) async {
    final c = await container();
    addTearDown(c.dispose);
    await pumpCard(tester, c);
    expect(find.textContaining('Add a habit'), findsOneWidget);
  });

  testWidgets('shows remaining-habits chip with a non-empty day', (
    tester,
  ) async {
    final c = await container(habits: [_habit('Read'), _habit('Run')]);
    addTearDown(c.dispose);
    await pumpCard(tester, c);
    expect(find.textContaining('left today'), findsWidgets);
    expect(find.text('2 left today'), findsOneWidget);
  });

  testWidgets('dismiss hides the card for the session', (tester) async {
    final c = await container();
    addTearDown(c.dispose);
    await pumpCard(tester, c);
    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    expect(find.textContaining('Add a habit'), findsNothing);
  });

  testWidgets('ask chip expands, free ask consumes quota and types a reply', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'coach_asks_${CoachAskQuota.dateKeyFor(DateTime.now())}': 0,
    });
    final c = await container();
    addTearDown(c.dispose);
    await pumpCard(tester, c);
    await tester.tap(find.text('✎ Ask the narrator'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'hi');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2)); // quota + typed reply
    // 'hi'.length % 5 == 2 → pool index 2
    expect(
      find.textContaining('One miss is a slip, not a fall'),
      findsOneWidget,
    );
  });

  testWidgets('exhausted quota opens the premium limit dialog', (tester) async {
    SharedPreferences.setMockInitialValues({
      'coach_asks_${CoachAskQuota.dateKeyFor(DateTime.now())}': 3,
    });
    final c = await container();
    addTearDown(c.dispose);
    await pumpCard(tester, c);
    await tester.tap(find.text('✎ Ask the narrator'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'hi');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();
    expect(
      find.text("You've used your 3 free coach asks today"),
      findsOneWidget,
    );
  });
}
