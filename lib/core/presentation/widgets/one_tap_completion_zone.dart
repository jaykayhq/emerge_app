import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:emerge_app/core/presentation/widgets/completion_particles.dart';

/// A 48×48 circular tap zone for one-tap habit completion.
///
/// Shows a particle burst animation on tap and calls [onComplete].
/// Provides haptic feedback on every tap.
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

  void _handleTap() {
    HapticFeedback.lightImpact();
    widget.onComplete();
    if (mounted) {
      setState(() => _showParticles = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: Container(
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
            ),
            if (_showParticles)
              const Positioned.fill(
                child: IgnorePointer(
                  child: SizedBox.expand(),
                ),
              ),
            if (_showParticles)
              Positioned(
                left: -26,
                top: -26,
                child: IgnorePointer(
                  child: CompletionParticles(
                    color: widget.color,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
