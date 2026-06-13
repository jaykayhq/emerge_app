// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void reloadWindow() {
  try {
    html.window.location.reload();
  } catch (e) {
    // Fallback if reload fails
  }
}
