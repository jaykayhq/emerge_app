import 'package:emerge_app/features/narrator/domain/models/narrator_trigger.dart';
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
    // The discover node died with the blueprints page in SP-F: its legacy
    // flag must not migrate into a node-guide flag.
    expect(await repo.getHasSeenNodeGuide('discover'), isFalse);
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

  test('app installed-at round-trips', () async {
    final repo = LocalSettingsRepository();
    await repo.init();

    expect(repo.getAppInstalledAt(), isNull);

    final installed = DateTime(2026, 7, 20, 9, 30);
    await repo.setAppInstalledAt(installed);
    expect(repo.getAppInstalledAt(), installed);
  });

  test('last app open round-trips', () async {
    final repo = LocalSettingsRepository();
    await repo.init();

    expect(repo.getLastAppOpen(), isNull);

    final lastOpen = DateTime(2026, 8, 1, 8, 15);
    await repo.setLastAppOpen(lastOpen);
    expect(repo.getLastAppOpen(), lastOpen);
  });

  test('recent narrator triggers round-trip', () async {
    final repo = LocalSettingsRepository();
    await repo.init();

    expect(await repo.getRecentNarratorTriggers(), isEmpty);

    final first = DateTime(2026, 8, 1, 7, 0);
    final second = DateTime(2026, 8, 1, 8, 0);
    await repo.recordNarratorTrigger(NarratorTrigger.longAbsence, first);
    await repo.recordNarratorTrigger(NarratorTrigger.streakBreakFirstMiss,
        second);

    final loaded = await repo.getRecentNarratorTriggers();
    expect(loaded, {
      NarratorTrigger.longAbsence: first,
      NarratorTrigger.streakBreakFirstMiss: second,
    });
  });

  test('recent narrator triggers tolerate unknown names and bad JSON',
      () async {
    SharedPreferences.setMockInitialValues({
      'narrator_recent_triggers':
          '{"longAbsence":"2026-08-01T07:00:00.000",'
              '"totallyUnknownTrigger":"2026-08-01T08:00:00.000",'
              '"morningBriefEarlyDays":"not-a-date"}',
    });
    final repo = LocalSettingsRepository();
    await repo.init();

    final loaded = await repo.getRecentNarratorTriggers();
    // Unknown trigger name skipped; unparseable timestamp skipped.
    expect(loaded, {
      NarratorTrigger.longAbsence: DateTime(2026, 8, 1, 7),
    });
  });

  test('recent narrator triggers degrade to empty on storage failure',
      () async {
    SharedPreferences.setMockInitialValues({
      'narrator_recent_triggers': '{{{not json',
    });
    final repo = LocalSettingsRepository();
    await repo.init();

    expect(await repo.getRecentNarratorTriggers(), isEmpty);
  });
}
