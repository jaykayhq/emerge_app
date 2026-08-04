import 'package:emerge_app/features/onboarding/data/repositories/local_settings_repository.dart';
import 'package:emerge_app/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:emerge_app/features/tutorials/presentation/widgets/node_guide_host.dart';
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
  Future<bool> getHasSeenNarratorGuide(String nodeId) async => seen.contains(nodeId);

  @override
  Future<void> setHasSeenNarratorGuide(String nodeId) async {
    recorded.add(nodeId);
  }
}

void main() {
  Widget host({required _FakeSettings settings}) {
    return ProviderScope(
      overrides: [
        localSettingsRepositoryProvider.overrideWithValue(settings),
      ],
      child: const MaterialApp(
        home: Scaffold(body: NodeGuideHost(nodeId: 'timeline', child: Text('content'))),
      ),
    );
  }

  testWidgets('shows the guide on first visit when tutorials are enabled',
      (tester) async {
    await tester.pumpWidget(host(settings: _FakeSettings(tutorialsEnabled: true)));
    await tester.pumpAndSettle();
    expect(find.text('Your Daily Timeline'), findsOneWidget);
    expect(find.text('content'), findsOneWidget);
  });

  testWidgets('does not show when tutorials are disabled', (tester) async {
    await tester.pumpWidget(host(settings: _FakeSettings(tutorialsEnabled: false)));
    await tester.pumpAndSettle();
    expect(find.text('Your Daily Timeline'), findsNothing);
  });

  testWidgets('does not show when the node was already seen', (tester) async {
    await tester.pumpWidget(
      host(settings: _FakeSettings(tutorialsEnabled: true, seen: {'timeline'})),
    );
    await tester.pumpAndSettle();
    expect(find.text('Your Daily Timeline'), findsNothing);
  });

  testWidgets('dismiss marks the node as seen', (tester) async {
    final settings = _FakeSettings(tutorialsEnabled: true);
    await tester.pumpWidget(host(settings: settings));
    await tester.pumpAndSettle();
    await tester.tap(find.text("GOT IT — LET'S GO"));
    await tester.pumpAndSettle();
    expect(find.text('Your Daily Timeline'), findsNothing);
    expect(settings.recorded, contains('timeline'));
  });
}
