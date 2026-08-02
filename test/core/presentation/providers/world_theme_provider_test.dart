import 'package:emerge_app/core/domain/models/app_world_theme.dart';
import 'package:emerge_app/core/presentation/providers/world_theme_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kKey = 'app_world_theme';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  ProviderContainer makeContainer() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    return container;
  }

  test('setTheme ignores a locked theme and never persists it', () async {
    final container = makeContainer();
    await container
        .read(worldThemeProvider.notifier)
        .setTheme(AppWorldTheme.forest);

    expect(container.read(worldThemeProvider), AppWorldTheme.nebula);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(_kKey), isNull);
  });

  test('setTheme persists the unlocked theme', () async {
    final container = makeContainer();
    await container
        .read(worldThemeProvider.notifier)
        .setTheme(AppWorldTheme.nebula);

    expect(container.read(worldThemeProvider), AppWorldTheme.nebula);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(_kKey), 'nebula');
  });

  test('legacy locked value in prefs loads as nebula', () async {
    SharedPreferences.setMockInitialValues({_kKey: 'forest'});
    final container = makeContainer();

    // Kick off build() so _loadFromPrefs runs during the delay below;
    // reading only after the delay would leave it pending past disposal.
    container.read(worldThemeProvider);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(container.read(worldThemeProvider), AppWorldTheme.nebula);
  });

  test('unknown saved value loads as nebula', () async {
    SharedPreferences.setMockInitialValues({_kKey: 'jupiter'});
    final container = makeContainer();

    container.read(worldThemeProvider);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(container.read(worldThemeProvider), AppWorldTheme.nebula);
  });
}
