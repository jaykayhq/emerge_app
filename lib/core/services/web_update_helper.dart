import 'web_update_stub.dart' if (dart.library.html) 'web_update_web.dart';

void reloadAppWindow() {
  reloadWindow();
}

void dismissUpdateNotification(String version) {
  storeDismissedVersion(version);
}

String? getLastDismissedVersion() {
  return getDismissedVersion();
}
