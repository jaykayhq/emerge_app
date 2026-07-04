import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:emerge_app/core/presentation/widgets/completion_particles.dart';

/// A 48×48 circular tap zone for one-tap habit completion.
///
/// Shows a particle burst animation on tap and calls [onComplete].
/// Provides haptic feedback on every tap.
///
/// Guard against double-taps: a second tap within 900 ms of the first is
/// silently ignored so [onComplete] is never called twice per interaction.
class OneTapCompletionZone extends StatefulWidget {
  final Color color;
  final VoidCallback onComplete;

  const OneTapCompletionZone({
    super.key,
    required this.color,
    required this.onComplete,
  });

  @override
  State<OneTapCompletionZone> createState() => _OneTapCompletionZoneState();
}

class _OneTapCompletionZoneState extends State<OneTapCompletionZone> {
  bool _showParticles = false;

  /// True while the 800 ms animation (+ buffer) is in progress.
  /// A second tap during this window is ignored.
  bool _isProcessing = false;

  void _handleTap() {
    if (_isProcessing) return;
    _isProcessing = true;
    HapticFeedback.lightImpact();
    widget.onComplete();
    if (mounted) {
      setState(() => _showParticles = true);
    }
    // Reset guard after animation completes (800 ms) + safety buffer
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _isProcessing = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              color: Colors.white,
              size: 24,
            ),
          ),
          if (_showParticles)
            Positioned(
              left: -26,
              top: -26,
              child: IgnorePointer(
                child: CompletionParticles(
                  color: widget.color,
                  onComplete: () {
                    if (mounted) setState(() => _showParticles = false);
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
