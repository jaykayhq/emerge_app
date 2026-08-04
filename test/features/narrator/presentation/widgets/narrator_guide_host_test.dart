import 'package:emerge_app/features/narrator/presentation/providers/narrator_guide_controller.dart';
import 'package:emerge_app/features/narrator/presentation/widgets/narrator_guide_host.dart';
import 'package:emerge_app/features/narrator/presentation/widgets/spotlight_painter.dart';
import 'package:emerge_app/features/onboarding/data/repositories/local_settings_repository.dart';
import 'package:emerge_app/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSettings extends LocalSettingsRepository {
  _FakeSettings({required this.tutorialsEnabled, this.seen = const {}});
  final bool tutorialsEnabled;
  final Set<String> seen;
  final Set<String> recorded = {};

  @override
  bool isTutorialsEnabled() => tutorialsEnabled;

  @override
  Future<bool> getHasSeenNarratorGuide(String nodeId) async =>
      seen.contains(nodeId);

  @override
  Future<void> setHasSeenNarratorGuide(String nodeId) async {
    recorded.add(nodeId);
  }
}

void main() {
  final fabKey = GlobalKey();

  Widget host({required _FakeSettings settings}) {
    return ProviderScope(
      overrides: [localSettingsRepositoryProvider.overrideWithValue(settings)],
      child: MaterialApp(
        home: Scaffold(
          body: NarratorGuideHost(
            nodeId: 'habit_create',
            targets: {'name_field': fabKey},
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                key: fabKey,
                width: 100,
                height: 40,
                child: const Text('field'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('shows the guide on first visit when tutorials are enabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(settings: _FakeSettings(tutorialsEnabled: true)),
    );
    await tester.pump(const Duration(milliseconds: 400)); // post-frame + show
    expect(find.textContaining('Start here'), findsOneWidget);
    expect(find.text('field'), findsOneWidget);
  });

  testWidgets('does not show when tutorials are disabled', (tester) async {
    await tester.pumpWidget(
      host(settings: _FakeSettings(tutorialsEnabled: false)),
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('Start here'), findsNothing);
  });

  testWidgets('does not show when the node was already seen', (tester) async {
    await tester.pumpWidget(
      host(
        settings: _FakeSettings(tutorialsEnabled: true, seen: {'habit_create'}),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('Start here'), findsNothing);
  });

  testWidgets('Next advances to the final step and Got it marks seen', (
    tester,
  ) async {
    final settings = _FakeSettings(tutorialsEnabled: true);
    await tester.pumpWidget(host(settings: settings));
    await tester.pump(const Duration(milliseconds: 400));
    // Let the first script finish typing.
    await tester.pump(const Duration(seconds: 2));
    await tester.tap(find.text('Next →'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('press this'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.tap(find.text('Got it'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('Start here'), findsNothing);
    expect(settings.recorded, contains('habit_create'));
  });

  testWidgets('Skip dismisses and marks seen', (tester) async {
    final settings = _FakeSettings(tutorialsEnabled: true);
    await tester.pumpWidget(host(settings: settings));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byIcon(Icons.close));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('Start here'), findsNothing);
    expect(settings.recorded, contains('habit_create'));
  });

  testWidgets('the spotlight painter is present with a hole rect', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(settings: _FakeSettings(tutorialsEnabled: true)),
    );
    await tester.pump(const Duration(milliseconds: 400));
    final painter = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((p) => p.painter)
        .whereType<SpotlightPainter>()
        .first;
    expect(painter.holeRect, isNotNull);
  });
}
