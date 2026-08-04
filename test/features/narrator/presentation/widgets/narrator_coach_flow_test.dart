import 'package:emerge_app/features/monetization/presentation/providers/subscription_provider.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_appearance.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_line.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_trigger.dart';
import 'package:emerge_app/features/narrator/presentation/widgets/narrator_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Free-tier stand-in: coach mode must render the quota hint without
/// touching Firebase/RevenueCat.
class _FreeIsPremium extends IsPremium {
  @override
  Future<bool> build() async => false;
}

/// Regression for the timeline AI-button flow: `NarratorSheet.show` in coach
/// mode first renders the first-visit `NodeGuideOverlay` (FeatureCoachMark),
/// then the sheet itself. Any layout assertion in that chain leaves the user
/// with a blank sheet — these tests prove the full chain renders cleanly.
void main() {
  setUp(() {
    // Tutorials on by default; coach node never seen; quota counter fresh.
    SharedPreferences.setMockInitialValues({
      'tutorialsEnabled': true,
    });
  });

  Widget host() {
    return ProviderScope(
      overrides: [
        // Coach-mode sheet watches premium state for the quota hint; keep it
        // on the free tier without touching Firebase.
        isPremiumProvider.overrideWith(() => _FreeIsPremium()),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => NarratorSheet.show(
                context,
                const NarratorAppearance(
                  trigger: NarratorTrigger.levelUp,
                  shellText: 'Ask your coach anything.',
                  buttonA: 'Later',
                  buttonB: 'Later',
                  line: GenericLine('Ask your coach anything.'),
                ),
                showAskField: true,
              ),
              child: const Text('Open coach'),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('coach flow: first-visit overlay renders without exceptions',
      (tester) async {
    await tester.pumpWidget(host());
    await tester.tap(find.text('Open coach'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // The node guide overlay is on top of (not instead of) the sheet.
    expect(tester.takeException(), isNull);
    expect(find.text("GOT IT — LET'S GO"), findsOneWidget);
  });

  testWidgets('coach flow: dismissing the overlay reveals the ask field',
      (tester) async {
    await tester.pumpWidget(host());
    await tester.tap(find.text('Open coach'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text("GOT IT — LET'S GO"));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(tester.takeException(), isNull);
    // Sheet header + ask field + quota hint, exactly like the timeline AI
    // button produces.
    expect(find.text('COACH'), findsOneWidget);
    expect(find.text('Ask your coach anything.'), findsOneWidget);
    expect(
      find.widgetWithText(TextField, 'Ask your coach anything…'),
      findsOneWidget,
    );
    expect(find.text('3 of 3 coach asks left today'), findsOneWidget);
  });

  testWidgets('coach flow: overlay never returns once marked seen',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'tutorialsEnabled': true,
      'hasSeenNarratorGuide_coach': true,
    });
    await tester.pumpWidget(host());
    await tester.tap(find.text('Open coach'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(tester.takeException(), isNull);
    expect(find.text("GOT IT — LET'S GO"), findsNothing);
    expect(find.text('COACH'), findsOneWidget);
  });
}
