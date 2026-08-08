import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:url_launcher/url_launcher.dart';

/// Play Store deep link for the rating fallback (web + mobile fallback).
const String playStoreReviewUrl =
    'https://play.google.com/store/apps/details?id=com.emerge.emerge_app';

/// Launches the appropriate review surface:
/// - native: in_app_review.requestReview() (falls back if unavailable)
/// - web: opens the Play Store page
abstract class ReviewLauncher {
  Future<bool> launch();
}

class DefaultReviewLauncher implements ReviewLauncher {
  @override
  Future<bool> launch() async {
    if (kIsWeb) {
      return launchUrl(Uri.parse(playStoreReviewUrl));
    }
    try {
      final inAppReview = InAppReview.instance;
      if (await inAppReview.isAvailable()) {
        await inAppReview.requestReview();
        return true;
      }
      // Fall back to the store page when the native prompt is unavailable
      // (simulator, rate-limited, etc.).
      return launchUrl(Uri.parse(playStoreReviewUrl));
    } catch (_) {
      return launchUrl(Uri.parse(playStoreReviewUrl));
    }
  }
}
