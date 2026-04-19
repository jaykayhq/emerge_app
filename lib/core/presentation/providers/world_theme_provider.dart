// lib/core/presentation/providers/world_theme_provider.dart
import 'package:emerge_app/core/domain/models/app_world_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kWorldThemeKey = 'app_world_theme';

/// Persisted Riverpod notifier for the user's selected world theme.
/// Defaults to [AppWorldTheme.nebula] so existing users see no change.
class WorldThemeNotifier extends Notifier<AppWorldTheme> {
  @override
  AppWorldTheme build() {
    // Return the default immediately, then load persisted value asynchronously.
    _loadFromPrefs();
    return AppWorldTheme.nebula;
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kWorldThemeKey);
    if (saved != null) {
      final theme = AppWorldTheme.values.firstWhere(
        (t) => t.name == saved,
        orElse: () => AppWorldTheme.nebula,
      );
      state = theme;
    }
  }

  Future<void> setTheme(AppWorldTheme theme) async {
    state = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kWorldThemeKey, theme.name);
  }
}

final worldThemeProvider =
    NotifierProvider<WorldThemeNotifier, AppWorldTheme>(WorldThemeNotifier.new);
