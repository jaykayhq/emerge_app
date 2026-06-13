import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:emerge_app/core/utils/app_logger.dart';

// Current app version matching the pubspec.yaml
const String kAppVersion = '1.0.5+9';

final webUpdateServiceProvider = NotifierProvider<WebUpdateService, bool>(() {
  return WebUpdateService();
});

class WebUpdateService extends Notifier<bool> {
  Timer? _timer;

  @override
  bool build() {
    if (kIsWeb) {
      ref.onDispose(() {
        _timer?.cancel();
      });
      startChecking();
    }
    return false;
  }

  void startChecking() {
    // Check immediately on startup
    checkUpdate();

    // Check periodically every 5 minutes
    _timer = Timer.periodic(const Duration(minutes: 5), (_) {
      checkUpdate();
    });
  }

  Future<void> checkUpdate() async {
    if (!kIsWeb) return;

    try {
      final cacheBuster = DateTime.now().millisecondsSinceEpoch;
      // Fetch the version file directly from the domain root using a cache buster
      final response = await http.get(Uri.parse('/version.json?t=$cacheBuster'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final serverVersion = data['version'] as String?;
        if (serverVersion != null && serverVersion != kAppVersion) {
          AppLogger.i('WebUpdateService: New version available: $serverVersion (Current: $kAppVersion)');
          state = true; // Update available!
        }
      }
    } catch (e) {
      AppLogger.e('WebUpdateService: Error checking for web update: $e');
    }
  }
}
