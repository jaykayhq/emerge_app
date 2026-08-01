import 'package:emerge_app/features/monetization/domain/services/coach_ask_quota.dart';
import 'package:emerge_app/features/monetization/presentation/providers/coach_ask_quota_provider.dart';
import 'package:emerge_app/features/monetization/presentation/providers/subscription_provider.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_appearance.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_line.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_trigger.dart';
import 'package:emerge_app/features/narrator/presentation/widgets/narrator_sheet.dart';
import 'package:emerge_app/features/onboarding/data/repositories/local_settings_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeIsPremium extends IsPremium {
  _FakeIsPremium(this._premium);
  final bool _premium;

  @override
  Future<bool> build() async => _premium;
}

class _FakeQuota extends CoachAskQuotaController {
  _FakeQuota(this._quota);
  final CoachAskQuota _quota;

  @override
  Future<CoachAskQuota> build() async => _quota;
}

/// Seeds the coach node guide as already-seen so the first-visit overlay
/// doesn't block the sheet under test (tutorials default to enabled).
Future<void> seedCoachGuideSeen() async {
  SharedPreferences.setMockInitialValues({
    'tutorialsEnabled': true,
    'hasSeenNodeGuide_coach': true,
  });
  await LocalSettingsRepository().init();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const appearance = NarratorAppearance(
    trigger: NarratorTrigger.askNarrator,
    shellText: 'Ask your coach anything.',
    buttonA: 'Later',
    buttonB: 'Later',
    line: GenericLine('Ask your coach anything.'),
  );

  Widget harness({bool premium = false, CoachAskQuota? quota}) {
    return ProviderScope(
      overrides: [
        isPremiumProvider.overrideWith(() => _FakeIsPremium(premium)),
        coachAskQuotaControllerProvider.overrideWith(
          () => _FakeQuota(
            quota ??
                const CoachAskQuota(
                  dateKey: '2026-08-01',
                  usedToday: 0,
                  isPremium: false,
                ),
          ),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => NarratorSheet.show(context, appearance,
                  showAskField: true),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('coach mode shows the ask field with quota hint', (tester) async {
    await seedCoachGuideSeen();
    await tester.pumpWidget(harness());
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('3 of 3 coach asks left today'), findsOneWidget);
  });

  testWidgets('submitting an ask shows a response and decrements the quota',
      (tester) async {
    await seedCoachGuideSeen();
    await tester.pumpWidget(harness());
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.enterText(find.byType(TextField), 'a');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Deterministic: pool[question.length % 5] with length 1 -> pool[1].
    expect(find.textContaining('future self'), findsOneWidget);
    expect(find.text('2 of 3 coach asks left today'), findsOneWidget);
  });

  testWidgets('exhausted quota shows the premium limit dialog', (tester) async {
    await seedCoachGuideSeen();
    await tester.pumpWidget(
      harness(
        quota: const CoachAskQuota(
          dateKey: '2026-08-01',
          usedToday: 3,
          isPremium: false,
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.enterText(find.byType(TextField), 'a');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text("You've used your 3 free coach asks today"), findsOneWidget);
  });

  testWidgets('premium user sees the unlimited quota hint', (tester) async {
    await seedCoachGuideSeen();
    await tester.pumpWidget(harness(premium: true));
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Unlimited coach asks'), findsOneWidget);
  });

  testWidgets('coach mode shows the first-visit guide overlay before the sheet',
      (tester) async {
    // Coach node unseen — tutorials default to enabled, so the guide is due.
    SharedPreferences.setMockInitialValues({
      'tutorialsEnabled': true,
    });
    await LocalSettingsRepository().init();

    await tester.pumpWidget(harness());
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // The guide overlay appears first; the sheet is not open yet.
    expect(find.text('Your Coach'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);

    // Dismissing the guide marks the node seen and then opens the sheet.
    await tester.tap(find.text("GOT IT — LET'S GO"));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Your Coach'), findsNothing);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('3 of 3 coach asks left today'), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('hasSeenNodeGuide_coach'), isTrue);
  });
}
