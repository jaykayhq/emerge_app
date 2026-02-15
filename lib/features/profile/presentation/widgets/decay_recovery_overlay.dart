import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Overlay widget that visualizes decay (missed days) and recovery states
/// Shows flickering, dimming, warning badges, and "Never Miss Twice" recovery effect
class DecayRecoveryOverlay extends StatefulWidget {
  final double entropyLevel; // 0.0 = healthy, 1.0 = max decay
  final int daysMissed; // 0, 1, 2, 3+
  final bool isRecovering; // True if completing habit after a miss
  final Color primaryColor;
  final Widget child;
  final VoidCallback? onRecoveryComplete;

  const DecayRecoveryOverlay({
    super.key,
    required this.entropyLevel,
    required this.daysMissed,
    required this.primaryColor,
    required this.child,
    this.isRecovering = false,
    this.onRecoveryComplete,
  });

  @override
  State<DecayRecoveryOverlay> createState() => _DecayRecoveryOverlayState();
}

class _DecayRecoveryOverlayState extends State<DecayRecoveryOverlay>
    with TickerProviderStateMixin {
  late AnimationController _flickerController;
  late AnimationController _recoveryController;
  late Animation<double> _flickerAnim;
  late Animation<double> _recoveryAnim;

  @override
  void initState() {
    super.initState();

    // Flicker animation for decay effect (irregular pulsing)
    _flickerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _flickerAnim =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.7), weight: 1),
          TweenSequenceItem(tween: Tween(begin: 0.7, end: 0.95), weight: 1),
          TweenSequenceItem(tween: Tween(begin: 0.95, end: 0.75), weight: 1),
          TweenSequenceItem(tween: Tween(begin: 0.75, end: 1.0), weight: 1),
        ]).animate(
          CurvedAnimation(parent: _flickerController, curve: Curves.easeInOut),
        );

    // Recovery animation (healing pulse)
    _recoveryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _recoveryAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _recoveryController, curve: Curves.easeOut),
    );

    _recoveryController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onRecoveryComplete?.call();
      }
    });

    _updateAnimations();
  }

  @override
  void didUpdateWidget(DecayRecoveryOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entropyLevel != widget.entropyLevel ||
        oldWidget.isRecovering != widget.isRecovering) {
      _updateAnimations();
    }
  }

  void _updateAnimations() {
    if (widget.entropyLevel > 0.3) {
      // Start flickering when entropy is noticeable
      _flickerController.repeat();
    } else {
      _flickerController.stop();
      _flickerController.value = 0;
    }

    if (widget.isRecovering) {
      _recoveryController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _flickerController.dispose();
    _recoveryController.dispose();
    super.dispose();
  }

  Color get _warningColor {
    if (widget.daysMissed >= 3) return const Color(0xFFf7768e); // Red
    if (widget.daysMissed >= 2) return const Color(0xFFff9e64); // Orange
    if (widget.daysMissed >= 1) return const Color(0xFFe0af68); // Amber
    return Colors.transparent;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_flickerController, _recoveryController]),
      builder: (context, child) {
        // Use IntrinsicHeight/Width to let Stack size from its non-positioned child
        return IntrinsicHeight(
          child: IntrinsicWidth(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Main child with decay effects applied
                _buildDecayedChild(),

                // Warning indicator badge
                if (widget.daysMissed > 0)
                  Positioned(top: 8, right: 8, child: _buildWarningBadge()),

                // Recovery healing wave effect
                if (widget.isRecovering && _recoveryAnim.value > 0)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _RecoveryWavePainter(
                          progress: _recoveryAnim.value,
                          color: widget.primaryColor,
                        ),
                      ),
                    ),
                  ),

                // "Never Miss Twice" message during recovery
                if (widget.isRecovering && _recoveryAnim.value > 0.3)
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: _buildRecoveryMessage(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDecayedChild() {
    double opacityMultiplier = 1.0;
    double scaleMultiplier = 1.0;

    // Apply flicker effect based on entropy
    if (widget.entropyLevel > 0.3) {
      opacityMultiplier = _flickerAnim.value;
    }

    // Subtle shrinking effect at high entropy
    if (widget.entropyLevel > 0.6) {
      scaleMultiplier = 1.0 - (widget.entropyLevel - 0.6) * 0.1;
    }

    // Recovery: restore to full during animation
    if (widget.isRecovering) {
      opacityMultiplier += (1.0 - opacityMultiplier) * _recoveryAnim.value;
      scaleMultiplier += (1.0 - scaleMultiplier) * _recoveryAnim.value;
    }

    return Opacity(
      opacity: opacityMultiplier.clamp(0.5, 1.0),
      child: Transform.scale(
        scale: scaleMultiplier.clamp(0.9, 1.0),
        child: widget.child,
      ),
    );
  }

  Widget _buildWarningBadge() {
    final opacity = widget.isRecovering ? 1.0 - _recoveryAnim.value : 1.0;

    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: _warningColor.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: _warningColor.withValues(alpha: 0.5),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.daysMissed >= 3 ? Icons.warning : Icons.schedule,
              color: Colors.white,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              _getWarningText(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getWarningText() {
    if (widget.daysMissed >= 3) return 'DANGER';
    if (widget.daysMissed >= 2) return '-${widget.daysMissed} DAYS';
    return 'MISSED 1';
  }

  Widget _buildRecoveryMessage() {
    final opacity = (_recoveryAnim.value - 0.3) / 0.7;

    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 40),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              widget.primaryColor.withValues(alpha: 0.8),
              widget.primaryColor.withValues(alpha: 0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: widget.primaryColor.withValues(alpha: 0.4),
              blurRadius: 12,
            ),
          ],
        ),
        child: const Text(
          '✨ NEVER MISS TWICE ✨',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}

/// Paints the healing wave effect during recovery
class _RecoveryWavePainter extends CustomPainter {
  final double progress;
  final Color color;

  _RecoveryWavePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width * 0.6;
    final currentRadius = maxRadius * progress;
    final alpha = (1.0 - progress) * 0.4;

    if (alpha <= 0) return;

    // Draw expanding healing ring
    final ringPaint = Paint()
      ..color = color.withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8 * (1 - progress)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawCircle(center, currentRadius, ringPaint);

    // Draw inner glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: alpha * 0.6),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: currentRadius));

    canvas.drawCircle(center, currentRadius * 0.8, glowPaint);

    // Draw sparkle particles during recovery
    if (progress > 0.2 && progress < 0.8) {
      _drawSparkles(canvas, size, center, progress);
    }
  }

  void _drawSparkles(Canvas canvas, Size size, Offset center, double progress) {
    const sparkleCount = 12;
    final sparkleProgress = (progress - 0.2) / 0.6;

    for (int i = 0; i < sparkleCount; i++) {
      final angle = (i / sparkleCount) * math.pi * 2;
      final distance = size.width * 0.2 + sparkleProgress * size.width * 0.35;
      final sparkleSize = 3.0 * (1 - sparkleProgress);
      final alpha = (1 - sparkleProgress) * 0.8;

      if (sparkleSize > 0 && alpha > 0) {
        final x = center.dx + math.cos(angle) * distance;
        final y = center.dy + math.sin(angle) * distance;

        final sparklePaint = Paint()
          ..color = Colors.white.withValues(alpha: alpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

        canvas.drawCircle(Offset(x, y), sparkleSize, sparklePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RecoveryWavePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
