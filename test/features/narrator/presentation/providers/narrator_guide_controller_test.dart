import 'package:emerge_app/features/narrator/presentation/providers/narrator_guide_controller.dart';
import 'package:emerge_app/features/onboarding/data/repositories/local_settings_repository.dart';
import 'package:emerge_app/features/onboarding/presentation/providers/onboarding_provider.dart';
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
      seen.contains(nodeId) || recorded.contains(nodeId);

  @override
  Future<void> setHasSeenNarratorGuide(String nodeId) async {
    recorded.add(nodeId);
  }
}

void main() {
  ProviderContainer container(_FakeSettings settings) => ProviderContainer(
    overrides: [localSettingsRepositoryProvider.overrideWithValue(settings)],
  );

  test(
    'shouldShow is true on first visit when tutorials are enabled',
    () async {
      final c = container(_FakeSettings(tutorialsEnabled: true));
      addTearDown(c.dispose);
      final controller = c.read(narratorGuideControllerProvider);
      expect(await controller.shouldShow('timeline'), true);
    },
  );

  test('shouldShow is false when tutorials are disabled', () async {
    final c = container(_FakeSettings(tutorialsEnabled: false));
    addTearDown(c.dispose);
    final controller = c.read(narratorGuideControllerProvider);
    expect(await controller.shouldShow('timeline'), false);
  });

  test('shouldShow is false when the guide was already seen', () async {
    final c = container(
      _FakeSettings(tutorialsEnabled: true, seen: {'timeline'}),
    );
    addTearDown(c.dispose);
    final controller = c.read(narratorGuideControllerProvider);
    expect(await controller.shouldShow('timeline'), false);
  });

  test('shouldShow is false after markSeen', () async {
    final c = container(_FakeSettings(tutorialsEnabled: true));
    addTearDown(c.dispose);
    final controller = c.read(narratorGuideControllerProvider);
    await controller.markSeen('timeline');
    expect(await controller.shouldShow('timeline'), false);
  });
}
