// ignore: avoid_web_libraries_in_flutter
import 'package:web/web.dart' as web;

void reloadWindow() {
  try {
    web.window.location.reload();
  } catch (e) {
    // Fallback if reload fails
  }
}

void storeDismissedVersion(String version) {
  try {
    web.window.localStorage.setItem('emerge_dismissed_version', version);
  } catch (_) {
    // localStorage may be unavailable (private browsing, etc.)
  }
}

String? getDismissedVersion() {
  try {
    return web.window.localStorage.getItem('emerge_dismissed_version');
  } catch (_) {
    return null;
  }
}
