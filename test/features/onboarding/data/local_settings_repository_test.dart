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
  });

  test('does not overwrite an existing seen flag', () async {
    SharedPreferences.setMockInitialValues({
      'companion_visited_/timeline': true,
      'hasSeenNodeGuide_timeline': true,
    });
    final repo = LocalSettingsRepository();
    await repo.init();
    await repo.migrateVisitedFlags();
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
}
