// ignore: avoid_web_libraries_in_flutter
import 'package:web/web.dart' as web;

void assignWindowLocation(String url) {
  try {
    web.window.location.assign(url);
  } catch (e) {
    // Fallback if navigation fails.
  }
}
