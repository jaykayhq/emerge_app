import 'dart:async';

import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/rating/presentation/providers/rating_prompt_provider.dart';
import 'package:emerge_app/features/rating/presentation/widgets/rating_prompt_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Attaches the rating controller's UI callbacks for the app's lifetime.
///
/// The controller lives in a plain (auto-dispose) Riverpod provider, so
/// without a resident widget its `onPromptRequested`/`onOpenFeedback` hooks
/// would never be set and the instance would be dropped once unwatched.
/// Mounted at the shell root, this host:
///   - keeps the auto-dispose controller alive via [ref.watch] in [build],
///   - wires the callbacks after the first frame ([_attach]),
///   - clears them in [dispose] so a stale callback can never target a
///     dead context after the host (and shell) are torn down.
class RatingPromptHost extends ConsumerStatefulWidget {
  final Widget child;

  const RatingPromptHost({super.key, required this.child});

  @override
  ConsumerState<RatingPromptHost> createState() => _RatingPromptHostState();
}

class _RatingPromptHostState extends ConsumerState<RatingPromptHost> {
  // Held so dispose can clear the callbacks without reading the provider
  // during teardown.
  RatingPromptController? _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _attach());
  }

  void _attach() {
    if (!mounted) return;
    final controller = ref.read(ratingPromptControllerProvider);
    _controller = controller;
    // Captured per-attach so a re-attach never reuses a stale low rating.
    var lastLowRating = 0;

    controller.onPromptRequested = () async {
      if (!mounted) return;
      await showRatingPromptDialog(
        context,
        onRating: (rating) {
          if (rating <= 3) lastLowRating = rating;
          unawaited(controller.handleRating(rating));
        },
        onNotNow: () => controller.notNow(),
      );
    };

    controller.onOpenFeedback = () async {
      if (!mounted) return;
      final userId = ref.read(authStateChangesProvider).value?.id ?? '';
      if (userId.isEmpty) return;
      try {
        context.push('/feedback?userId=$userId&rating=$lastLowRating');
      } catch (_) {
        // No router in the test harness — safe to ignore.
      }
    };
  }

  @override
  void dispose() {
    _controller?.onPromptRequested = null;
    _controller?.onOpenFeedback = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Keep the auto-dispose controller alive for the host's lifetime so
    // milestone callers (`ref.read` from habit/challenge completion) always
    // receive the instance with the wired callbacks.
    ref.watch(ratingPromptControllerProvider);
    return widget.child;
  }
}
