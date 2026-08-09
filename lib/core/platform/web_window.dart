import 'web_window_stub.dart' if (dart.library.html) 'web_window_web.dart';

/// Redirects the browser to [url] on web; no-op elsewhere.
void redirectTo(String url) {
  assignWindowLocation(url);
}
