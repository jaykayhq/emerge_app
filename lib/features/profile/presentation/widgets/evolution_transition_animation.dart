import 'dart:math' as math;
import 'package:emerge_app/features/profile/domain/models/silhouette_evolution.dart';
import 'package:emerge_app/features/profile/domain/services/evolution_haptic_service.dart';
import 'package:flutter/material.dart';

/// Cinematic transition animation when crossing evolution phase thresholds
/// Sequence: Compression → Flash → Expansion → Reveal
class EvolutionTransitionAnimation extends StatefulWidget {
  final EvolutionPhase fromPhase;
  final EvolutionPhase toPhase;
  final Color primaryColor;
  final VoidCallback? onComplete;
  final Widget child;

  const EvolutionTransitionAnimation({
    super.key,
    required this.fromPhase,
    required this.toPhase,
    required this.primaryColor,
    required this.child,
    this.onComplete,
  });

  @override
  State<EvolutionTransitionAnimation> createState() =>
      _EvolutionTransitionAnimationState();
}

class _EvolutionTransitionAnimationState
    extends State<EvolutionTransitionAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _compressionAnim;
  late Animation<double> _flashAnim;
  late Animation<double> _expansionAnim;
  late Animation<double> _revealAnim;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Phase 1: Compression (0.0 - 0.25)
    _compressionAnim = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.25, curve: Curves.easeIn),
      ),
    );

    // Phase 2: Flash (0.25 - 0.45)
    _flashAnim =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 1),
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 1),
        ]).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.25, 0.45, curve: Curves.easeInOut),
          ),
        );

    // Phase 3: Expansion (0.45 - 0.70)
    _expansionAnim = Tween<double>(begin: 0.85, end: 1.1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.45, 0.70, curve: Curves.elasticOut),
      ),
    );

    // Phase 4: Settle to normal (0.70 - 1.0)
    _revealAnim = Tween<double>(begin: 1.1, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.70, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        EvolutionHapticService().evolutionComplete();
        widget.onComplete?.call();
      }
    });

    // Add listener for phase-specific haptics
    _controller.addListener(_triggerPhaseHaptics);

    // Start animation
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.removeListener(_triggerPhaseHaptics);
    _controller.dispose();
    super.dispose();
  }

  // Track which haptic phases have been triggered
  bool _compressionTriggered = false;
  bool _flashTriggered = false;
  bool _expansionTriggered = false;

  void _triggerPhaseHaptics() {
    final progress = _controller.value;
    final haptic = EvolutionHapticService();

    // Compression phase (0.0 - 0.25)
    if (progress >= 0.05 && !_compressionTriggered) {
      _compressionTriggered = true;
      haptic.compressionStart();
    }

    // Flash phase (0.25 - 0.45)
    if (progress >= 0.30 && !_flashTriggered) {
      _flashTriggered = true;
      haptic.flashImpact();
    }

    // Expansion phase (0.45 - 0.70)
    if (progress >= 0.50 && !_expansionTriggered) {
      _expansionTriggered = true;
      haptic.expansionRumble();
    }
  }

  double get _currentScale {
    final progress = _controller.value;
    if (progress < 0.25) {
      return _compressionAnim.value;
    } else if (progress < 0.45) {
      return 0.85;
    } else if (progress < 0.70) {
      return _expansionAnim.value;
    } else {
      return _revealAnim.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Scaled silhouette
            Transform.scale(scale: _currentScale, child: widget.child),

            // Flash overlay
            if (_flashAnim.value > 0)
              Positioned.fill(
                child: CustomPaint(
                  painter: _FlashPainter(
                    color: widget.primaryColor,
                    intensity: _flashAnim.value,
                  ),
                ),
              ),

            // Particle burst during expansion
            if (_expansionAnim.value > 0.85 && _controller.value < 0.8)
              _ParticleBurst(
                color: widget.primaryColor,
                progress: (_controller.value - 0.45) / 0.35,
              ),

            // Phase name reveal
            if (_controller.value > 0.7)
              Positioned(
                top: 20,
                child: _PhaseRevealText(
                  phase: widget.toPhase,
                  color: widget.primaryColor,
                  opacity: (_controller.value - 0.7) / 0.3,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _FlashPainter extends CustomPainter {
  final Color color;
  final double intensity;

  _FlashPainter({required this.color, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    final gradient = RadialGradient(
      center: Alignment.center,
      radius: 0.8,
      colors: [
        Colors.white.withValues(alpha: intensity * 0.9),
        color.withValues(alpha: intensity * 0.5),
        Colors.transparent,
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      );

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant _FlashPainter oldDelegate) {
    return oldDelegate.intensity != intensity;
  }
}

class _ParticleBurst extends StatelessWidget {
  final Color color;
  final double progress;

  const _ParticleBurst({required this.color, required this.progress});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _ParticleBurstPainter(color: color, progress: progress),
    );
  }
}

class _ParticleBurstPainter extends CustomPainter {
  final Color color;
  final double progress;

  _ParticleBurstPainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final random = math.Random(42);

    for (int i = 0; i < 30; i++) {
      final angle = random.nextDouble() * math.pi * 2;
      final baseDistance = 20 + random.nextDouble() * 30;
      final distance = baseDistance + progress * 150;
      final particleSize = (1 - progress) * (2 + random.nextDouble() * 4);
      final alpha = (1 - progress) * 0.8;

      if (particleSize > 0 && alpha > 0) {
        final x = center.dx + math.cos(angle) * distance;
        final y = center.dy + math.sin(angle) * distance * 0.7;

        final particlePaint = Paint()
          ..color = color.withValues(alpha: alpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

        canvas.drawCircle(Offset(x, y), particleSize, particlePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ParticleBurstPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _PhaseRevealText extends StatelessWidget {
  final EvolutionPhase phase;
  final Color color;
  final double opacity;

  const _PhaseRevealText({
    required this.phase,
    required this.color,
    required this.opacity,
  });

  String get _phaseName {
    switch (phase) {
      case EvolutionPhase.phantom:
        return 'THE PHANTOM';
      case EvolutionPhase.construct:
        return 'THE CONSTRUCT';
      case EvolutionPhase.incarnate:
        return 'THE INCARNATE';
      case EvolutionPhase.radiant:
        return 'THE RADIANT';
      case EvolutionPhase.ascended:
        return 'THE ASCENDED';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Text(
        _phaseName,
        style: TextStyle(
          color: color,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          letterSpacing: 6,
          shadows: [
            Shadow(color: color.withValues(alpha: 0.5), blurRadius: 10),
          ],
        ),
      ),
    );
  }
}
