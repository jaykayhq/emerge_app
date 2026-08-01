import 'package:emerge_app/features/onboarding/data/repositories/local_settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('migrates companion visited flags to node-guide flags', () async {
    SharedPreferences.setMockInitialValues({
      'companion_visited_/timeline': true,
      'companion_visited_/challenges': true,
      'companion_visited_/discover': true,
      'companion_visited_/tribes': false,
    });
    final repo = LocalSettingsRepository();
    await repo.init();
    await repo.migrateVisitedFlags();

    expect(await repo.getHasSeenNodeGuide('timeline'), isTrue);
    expect(await repo.getHasSeenNodeGuide('challenges'), isTrue);
    expect(await repo.getHasSeenNodeGuide('discover'), isTrue);
    // False legacy flags do not migrate.
    expect(await repo.getHasSeenNodeGuide('tribes'), isFalse);

    // Legacy keys are always removed, whether or not they migrated.
    final keys = (await SharedPreferences.getInstance()).getKeys();
    expect(keys.contains('companion_visited_/timeline'), isFalse);
    expect(keys.contains('companion_visited_/challenges'), isFalse);
    expect(keys.contains('companion_visited_/discover'), isFalse);
    expect(keys.contains('companion_visited_/tribes'), isFalse);
  });

  test('does not overwrite an existing seen flag', () async {
    SharedPreferences.setMockInitialValues({
      'companion_visited_/timeline': true,
      'hasSeenNodeGuide_timeline': true,
    });
    final repo = LocalSettingsRepository();
    await repo.init();
    await repo.migrateVisitedFlags();
    // Pins the no-overwrite invariant: both flags start true, so this test
    // cannot observe a redundant write (setting true over true is
    // value-invisible); the guard in migrateVisitedFlags is what matters.
    expect(await repo.getHasSeenNodeGuide('timeline'), isTrue);
  });

  test('is idempotent — second run is a no-op', () async {
    SharedPreferences.setMockInitialValues({
      'companion_visited_/challenges': true,
    });
    final repo = LocalSettingsRepository();
    await repo.init();
    await repo.migrateVisitedFlags();
    await repo.migrateVisitedFlags();
    expect(await repo.getHasSeenNodeGuide('challenges'), isTrue);
  });

  test('removes unknown-route legacy flags without creating a node flag',
      () async {
    SharedPreferences.setMockInitialValues({
      'companion_visited_/insights': true,
    });
    final repo = LocalSettingsRepository();
    await repo.init();
    await repo.migrateVisitedFlags();

    // '/insights' is not in the migration map: the legacy key is still
    // removed, but no hasSeenNodeGuide_insights flag is created.
    final keys = (await SharedPreferences.getInstance()).getKeys();
    expect(keys.contains('companion_visited_/insights'), isFalse);
    expect(await repo.getHasSeenNodeGuide('insights'), isFalse);
  });
}
