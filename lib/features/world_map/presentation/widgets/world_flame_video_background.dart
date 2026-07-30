import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:emerge_app/core/domain/models/app_world_theme.dart';

/// Full-screen looping flame video background for the world map.
///
/// Cross-fades between two looping videos based on [healthState]:
/// - thriving / neutral -> neutral_increasing.mp4 (bright, surging flame)
/// - decaying -> decreasing_dimming.mp4 (dimming, fading flame)
///
/// WorldHealthState has three cases (thriving, neutral, decaying); the split
/// puts only the low-health `decaying` state on the dimming video so the
/// world looks alive unless health has actually dropped below 0.40.
///
/// If neither video initializes (e.g. under flutter_test, or on a platform
/// without video support), renders [fallback] instead.
class WorldFlameVideoBackground extends StatefulWidget {
  final WorldHealthState healthState;
  final Widget fallback;

  const WorldFlameVideoBackground({
    super.key,
    required this.healthState,
    required this.fallback,
  });

  @override
  State<WorldFlameVideoBackground> createState() =>
      _WorldFlameVideoBackgroundState();
}

class _WorldFlameVideoBackgroundState extends State<WorldFlameVideoBackground> {
  late final VideoPlayerController _neutralIncreasingController;
  late final VideoPlayerController _decreasingDimmingController;
  bool _neutralIncreasingInitialized = false;
  bool _decreasingDimmingInitialized = false;

  bool get _isDimmingActive =>
      widget.healthState == WorldHealthState.decaying;

  @override
  void initState() {
    super.initState();
    _neutralIncreasingController = VideoPlayerController.asset(
      'assets/videos/world_health/neutral_increasing.mp4',
    );
    _decreasingDimmingController = VideoPlayerController.asset(
      'assets/videos/world_health/decreasing_dimming.mp4',
    );
    _initController(_neutralIncreasingController, () {
      _neutralIncreasingInitialized = true;
    });
    _initController(_decreasingDimmingController, () {
      _decreasingDimmingInitialized = true;
    });
  }

  Future<void> _initController(
    VideoPlayerController controller,
    VoidCallback markInitialized,
  ) async {
    try {
      await controller.initialize();
      await controller.setLooping(true);
      // Muted playback is required for autoplay on web.
      await controller.setVolume(0);
      await controller.play();
      if (mounted) {
        setState(markInitialized);
      }
    } catch (_) {
      // Never throw: leave the initialized flag false so the fallback
      // (or the other video) is used instead.
    }
  }

  @override
  void didUpdateWidget(covariant WorldFlameVideoBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    // AnimatedOpacity handles the crossfade when the active video changes;
    // the framework rebuilds automatically on widget update.
  }

  @override
  void dispose() {
    _neutralIncreasingController.dispose();
    _decreasingDimmingController.dispose();
    super.dispose();
  }

  Widget _buildVideoLayer(VideoPlayerController controller, bool isActive) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 400),
      opacity: isActive ? 1 : 0,
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: controller.value.size.width,
            height: controller.value.size.height,
            child: VideoPlayer(controller),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_neutralIncreasingInitialized && !_decreasingDimmingInitialized) {
      return widget.fallback;
    }

    final activeInitialized = _isDimmingActive
        ? _decreasingDimmingInitialized
        : _neutralIncreasingInitialized;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Keep the fallback behind the videos when the active one isn't ready.
        if (!activeInitialized) widget.fallback,
        if (_neutralIncreasingInitialized)
          _buildVideoLayer(_neutralIncreasingController, !_isDimmingActive),
        if (_decreasingDimmingInitialized)
          _buildVideoLayer(_decreasingDimmingController, _isDimmingActive),
      ],
    );
  }
}
