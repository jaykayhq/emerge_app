import 'package:emerge_app/features/narrator/presentation/widgets/narrator_guide_host.dart';
import 'package:emerge_app/features/onboarding/data/repositories/local_settings_repository.dart';
import 'package:emerge_app/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// Reproduces the reported symptom: after the coach guide is dismissed, the
// underlying screen should be fully interactive (no invisible absorbing layer).
class _FakeSettings extends LocalSettingsRepository {
  _FakeSettings({required this.tutorialsEnabled});
  final bool tutorialsEnabled;
  final Set<String> recorded = {};

  @override
  bool isTutorialsEnabled() => tutorialsEnabled;

  @override
  Future<bool> getHasSeenNarratorGuide(String nodeId) async => false;

  @override
  Future<void> setHasSeenNarratorGuide(String nodeId) async {
    recorded.add(nodeId);
  }
}

void main() {
  testWidgets(
    'screen child stays fully tappable after the guide is dismissed',
    (tester) async {
      var taps = 0;
      final fabKey = GlobalKey();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localSettingsRepositoryProvider.overrideWithValue(
              _FakeSettings(tutorialsEnabled: true),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: NarratorGuideHost(
                nodeId: 'habit_create',
                targets: {'name_field': fabKey},
                child: Scaffold(
                  // Mimics the real screens (WorldBackground wraps a Scaffold).
                  body: Center(
                    child: ElevatedButton(
                      onPressed: () => taps++,
                      child: const Text('interactive'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      // Guide is showing.
      expect(find.textContaining('Start here'), findsOneWidget);

      // Finish the guide.
      await tester.pump(const Duration(seconds: 2));
      await tester.tap(find.text('Next →'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(seconds: 2));
      await tester.tap(find.text('Got it'));
      await tester.pump(const Duration(milliseconds: 400));

      // Guide card should be gone.
      expect(find.textContaining('Start here'), findsNothing);

      // The underlying screen button must be tappable — if an invisible
      // absorbing layer remained, this tap would not register.
      expect(find.text('interactive'), findsOneWidget);
      await tester.tap(find.text('interactive'));
      await tester.pump();
      expect(taps, 1);
    },
  );
}
