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

  Future<ProviderContainer> container({
    List<Habit> habits = const [],
    bool premium = false,
  }) async {
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
        isPremiumProvider.overrideWith(() => _FakeIsPremium(premium)),
      ],
    );
  }

  Future<void> pumpCard(
    WidgetTester tester,
    ProviderContainer c, {
    Future<String> Function(String context, String question)? coach,
  }) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp(
          home: Scaffold(body: NarratorCard(coach: coach)),
        ),
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
    await tester.tap(find.text('✎ Ask the coach'));
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
    // The free ask consumed one of the day's three asks.
    expect(find.text('2 of 3 coach asks left today'), findsOneWidget);
  });

  testWidgets('exhausted quota opens the premium limit dialog', (tester) async {
    SharedPreferences.setMockInitialValues({
      'coach_asks_${CoachAskQuota.dateKeyFor(DateTime.now())}': 3,
    });
    final c = await container();
    addTearDown(c.dispose);
    await pumpCard(tester, c);
    await tester.tap(find.text('✎ Ask the coach'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'hi');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();
    expect(
      find.text("You've used your 3 free coach asks today"),
      findsOneWidget,
    );
  });

  testWidgets('premium ask with injected coach shows personal advice', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'coach_asks_${CoachAskQuota.dateKeyFor(DateTime.now())}': 0,
    });
    final c = await container(premium: true);
    addTearDown(c.dispose);
    await pumpCard(tester, c, coach: (ctx, q) async => 'Personal advice');
    await tester.tap(find.text('✎ Ask the coach'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'help me');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2)); // coach + typed reply
    expect(find.textContaining('Personal advice'), findsOneWidget);
    expect(find.text('DATA-GROUNDED'), findsOneWidget);
    expect(find.text('Unlimited coach asks'), findsOneWidget);
  });

  testWidgets('premium coach failure falls back to the generic reply', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'coach_asks_${CoachAskQuota.dateKeyFor(DateTime.now())}': 0,
    });
    final c = await container(premium: true);
    addTearDown(c.dispose);
    await pumpCard(tester, c, coach: (ctx, q) async => throw Exception('x'));
    await tester.tap(find.text('✎ Ask the coach'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'hi');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2)); // failure + typed reply
    expect(find.textContaining("I'm here — keep going."), findsOneWidget);
  });

  testWidgets('latched ask-focus request replays on mount', (tester) async {
    final c = await container();
    addTearDown(c.dispose);
    // Bump while the card is unmounted: the request must latch and replay
    // when the card mounts, expanding the ask field.
    c.read(narratorAskFocusProvider.notifier).request();
    await pumpCard(tester, c);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('quota hint stays "X of 3" regardless of how many habits exist', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'coach_asks_${CoachAskQuota.dateKeyFor(DateTime.now())}': 0,
    });
    // 8 habits — the exact scenario that previously displayed "8 of 8".
    final c = await container(
      habits: List.generate(8, (i) => _habit('Habit $i')),
    );
    addTearDown(c.dispose);
    await pumpCard(tester, c);
    // Prove the premise: the 8 habits are actually rendered.
    expect(find.text('8 left today'), findsOneWidget);
    // The hint renders inside the expanded ask UI.
    await tester.tap(find.text('✎ Ask the coach'));
    await tester.pump();
    expect(find.text('3 of 3 coach asks left today'), findsOneWidget);
  });
}
