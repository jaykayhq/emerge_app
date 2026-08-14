import 'package:emerge_app/features/narrator/presentation/widgets/narrator_guide_card.dart';
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
    await tester.pump(); // post-frame gate resolves, card builds
    await tester.pump(const Duration(milliseconds: 400)); // typewriter ticks
    expect(find.textContaining('Start here'), findsOneWidget);
    expect(find.text('field'), findsOneWidget);
  });

  testWidgets(
    'renders without an enclosing Scaffold (host provides its own Material)',
    (tester) async {
      // The host's internal transparent Material must cover the card's
      // InkWell/IconButton even when the screen has no Scaffold ancestor —
      // the shared helper always wraps in a Scaffold, masking that crash.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localSettingsRepositoryProvider.overrideWithValue(
              _FakeSettings(tutorialsEnabled: true),
            ),
          ],
          child: MaterialApp(
            home: NarratorGuideHost(
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
      await tester.pump(); // post-frame gate resolves, card builds
      await tester.pump(const Duration(milliseconds: 400)); // typewriter ticks
      expect(find.textContaining('Start here'), findsOneWidget);
      expect(find.text('field'), findsOneWidget);
    },
  );

  testWidgets('does not show when tutorials are disabled', (tester) async {
    await tester.pumpWidget(
      host(settings: _FakeSettings(tutorialsEnabled: false)),
    );
    await tester.pump(); // post-frame gate resolves (nothing to show)
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('Start here'), findsNothing);
  });

  testWidgets('does not show when the node was already seen', (tester) async {
    await tester.pumpWidget(
      host(
        settings: _FakeSettings(tutorialsEnabled: true, seen: {'habit_create'}),
      ),
    );
    await tester.pump(); // post-frame gate resolves (nothing to show)
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('Start here'), findsNothing);
  });

  testWidgets('Next advances to the final step and Got it marks seen', (
    tester,
  ) async {
    final settings = _FakeSettings(tutorialsEnabled: true);
    await tester.pumpWidget(host(settings: settings));
    await tester.pump(); // post-frame gate resolves, card builds
    await tester.pump(const Duration(milliseconds: 400)); // typewriter ticks
    // Let the first script finish typing.
    await tester.pump(const Duration(seconds: 2));
    await tester.tap(find.text('Next →'));
    await tester.pump(); // script swap rebuild
    await tester.pump(const Duration(milliseconds: 400));
    // Let the second script finish typing ('press this' is mid-script and
    // needs ~857ms at 35 cps).
    await tester.pump(const Duration(seconds: 2));
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
    await tester.pump(); // post-frame gate resolves, card builds
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('Start here'), findsNothing);
    expect(settings.recorded, contains('habit_create'));
  });

  testWidgets('Next scrolls an offscreen target before showing the next step', (
    tester,
  ) async {
    final settings = _FakeSettings(tutorialsEnabled: true);
    final firstKey = GlobalKey();
    final secondKey = GlobalKey();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localSettingsRepositoryProvider.overrideWithValue(settings),
        ],
        child: MaterialApp(
          home: NarratorGuideHost(
            nodeId: 'habit_create',
            targets: {'name_field': firstKey, 'create_button': secondKey},
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: SizedBox(key: firstKey, height: 40)),
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      const SizedBox(height: 1800),
                      SizedBox(
                        key: secondKey,
                        width: double.infinity,
                        height: 40,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    await tester.tap(find.text('Next →'));
    for (var index = 0; index < 10; index++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    final viewport = tester.getRect(find.byType(CustomScrollView));
    final target = tester.getRect(find.byKey(secondKey));
    final card = tester.getRect(find.byType(NarratorGuideCard));
    expect(viewport.overlaps(target), isTrue);
    expect(viewport.overlaps(card), isTrue);
    expect(find.textContaining('When it feels real'), findsOneWidget);
  });

  testWidgets('keeps a card-only step visible when its target is unavailable', (
    tester,
  ) async {
    final settings = _FakeSettings(tutorialsEnabled: true);
    final firstKey = GlobalKey();
    final missingKey = GlobalKey();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localSettingsRepositoryProvider.overrideWithValue(settings),
        ],
        child: MaterialApp(
          home: NarratorGuideHost(
            nodeId: 'habit_create',
            targets: {'name_field': firstKey, 'create_button': missingKey},
            child: SizedBox(key: firstKey, height: 40),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.tap(find.text('Next →'));
    await tester.pump();

    final host = tester.getRect(find.byType(NarratorGuideHost));
    final card = tester.getRect(find.byType(NarratorGuideCard));
    expect(host.overlaps(card), isTrue);
    expect(find.byType(NarratorGuideCard), findsOneWidget);
  });

  testWidgets('the spotlight painter is present with a hole rect', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(settings: _FakeSettings(tutorialsEnabled: true)),
    );
    await tester.pump(); // post-frame gate resolves, card builds
    await tester.pump(const Duration(milliseconds: 400));
    final painter = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((p) => p.painter)
        .whereType<SpotlightPainter>()
        .first;
    final targetBox = fabKey.currentContext!.findRenderObject() as RenderBox;
    final targetRect = targetBox.localToGlobal(Offset.zero) & targetBox.size;
    expect(painter.holeRect, isNotNull);
    expect(painter.holeRect!.contains(targetRect.center), true);
  });

  testWidgets(
    'guide card renders clear of a low target instead of covering it',
    (tester) async {
      final targetKey = GlobalKey();
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
                targets: {'name_field': targetKey},
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    key: targetKey,
                    width: 120,
                    height: 60,
                    color: Colors.red,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(); // post-frame gate resolves, card builds
      await tester.pump(const Duration(milliseconds: 400)); // typewriter ticks
      await tester.pump(); // measure callback repositions using the real height

      final cardFinder = find.byType(NarratorGuideCard);
      expect(cardFinder, findsOneWidget);
      final cardBox = tester.getRect(cardFinder);
      final targetBox = tester.getRect(find.byKey(targetKey));
      // The card must sit clear of — strictly above — the spotlighted element.
      expect(cardBox.overlaps(targetBox), isFalse);
      expect(cardBox.bottom, lessThanOrEqualTo(targetBox.top + 1));
    },
  );

  testWidgets(
    'card stays clear of a low target on a phone-width multi-line script',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final targetKey = GlobalKey();
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
                targets: {'name_field': targetKey},
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    key: targetKey,
                    width: 120,
                    height: 60,
                    color: Colors.red,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(); // post-frame gate resolves, card builds
      await tester
          .pump(); // host settles at the one-line height (hole + measure go quiet)
      // Type the script out across frames. The host has no reason to rebuild
      // while the typewriter wraps to extra lines, so without a re-measure
      // the card's bottom creeps past the target.
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(); // final frame settles

      final cardBox = tester.getRect(find.byType(NarratorGuideCard));
      final targetBox = tester.getRect(find.byKey(targetKey));
      expect(cardBox.overlaps(targetBox), isFalse);
      expect(cardBox.bottom, lessThanOrEqualTo(targetBox.top + 1));
    },
  );
}
