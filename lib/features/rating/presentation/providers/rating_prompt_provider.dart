import 'package:emerge_app/core/services/web_update_service.dart' show kAppVersion;
import 'package:emerge_app/features/rating/domain/rating_prompt_gate.dart';
import 'package:emerge_app/features/rating/domain/rating_prompt_store.dart';
import 'package:emerge_app/features/rating/domain/review_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final ratingPromptStoreProvider = Provider<RatingPromptStore>(
  (_) => SharedPreferencesRatingPromptStore(),
);

final reviewLauncherProvider = Provider<ReviewLauncher>(
  (_) => DefaultReviewLauncher(),
);

/// Observes milestone signals and owns the gate decision + persistence.
/// Per the approved spec: a milestone PROMPTS (shows the rating dialog);
/// the user's rating then routes to review (>=4) or feedback (<=3).
class RatingPromptController {
  RatingPromptController({
    required RatingPromptStore store,
    required ReviewLauncher launcher,
  })  : _store = store,
        _launcher = launcher;

  final RatingPromptStore _store;
  final ReviewLauncher _launcher;

  String currentVersion = kAppVersion;

  /// Invoked when the gate says the rating dialog should be shown.
  Future<void> Function()? onPromptRequested;

  /// Invoked when the user rates low and the feedback form should open.
  Future<void> Function()? onOpenFeedback;

  Future<void> notifyMilestone(RatingPromptSignal signal) async {
    final now = DateTime.now();
    final shouldAsk = RatingPromptGate.shouldAsk(
      signal: signal,
      now: now,
      lastAskedAt: await _store.lastAskedAt(),
      versionAskedFor: await _store.versionAskedFor(),
      dontAskAgain: await _store.dontAskAgain(),
      currentVersion: currentVersion,
      cooldown: RatingPromptGate.standardCooldown,
    );
    if (!shouldAsk) return;
    await onPromptRequested?.call();
  }

  Future<void> handleRating(int rating) async {
    await _store.recordAsked(DateTime.now(), currentVersion);
    if (rating >= 4) {
      await _launcher.launch();
    } else {
      await onOpenFeedback?.call();
    }
  }

  Future<void> notNow() async {
    await _store.recordAsked(DateTime.now(), currentVersion);
  }
}

final ratingPromptControllerProvider = Provider<RatingPromptController>((ref) {
  return RatingPromptController(
    store: ref.watch(ratingPromptStoreProvider),
    launcher: ref.watch(reviewLauncherProvider),
  );
});
