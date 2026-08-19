import 'dart:math' as math;
import 'package:flutter/material.dart';

/// An animated overlay widget that emits a burst of glowing ember sparks
/// traveling along curved trajectories from a start offset (e.g., CTA button)
/// toward a target offset (e.g., central Bonfire).
class WorldSparkBurst extends StatefulWidget {
  final Offset startOffset;
  final Offset targetOffset;
  final VoidCallback onComplete;
  final Color sparkColor;
  final Duration duration;

  const WorldSparkBurst({
    super.key,
    required this.startOffset,
    required this.targetOffset,
    required this.onComplete,
    this.sparkColor = const Color(0xFFFFA329),
    this.duration = const Duration(milliseconds: 900),
  });

  @override
  State<WorldSparkBurst> createState() => _WorldSparkBurstState();
}

class _WorldSparkBurstState extends State<WorldSparkBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_SparkData> _sparks;
  bool _hasCompleted = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _sparks = _generateSparks(24);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_hasCompleted) {
        _hasCompleted = true;
        widget.onComplete();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    if (disableAnimations) {
      if (!_hasCompleted) {
        _hasCompleted = true;
        _controller.stop();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            widget.onComplete();
          }
        });
      }
    } else {
      if (!_controller.isAnimating && !_controller.isCompleted) {
        _controller.forward();
      }
    }
  }

  List<_SparkData> _generateSparks(int count) {
    final random = math.Random(42);
    return List.generate(count, (index) {
      final delay = (index / count) * 0.25;
      final duration = 0.65 + (random.nextDouble() * 0.3);
      final arcSign = index.isEven ? 1.0 : -1.0;
      final arcMagnitude = 20.0 + (random.nextDouble() * 70.0);
      final arc = arcSign * arcMagnitude;
      final size = 2.0 + (random.nextDouble() * 3.0);
      final jitter = 0.8 + (random.nextDouble() * 0.4);

      return _SparkData(
        delay: delay,
        duration: duration,
        arcOffset: arc,
        size: size,
        alphaJitter: jitter,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return const SizedBox.shrink();
    }

    return RepaintBoundary(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              size: Size.infinite,
              painter: _SparkBurstPainter(
                progress: _controller.value,
                startOffset: widget.startOffset,
                targetOffset: widget.targetOffset,
                sparkColor: widget.sparkColor,
                sparks: _sparks,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SparkData {
  final double delay;
  final double duration;
  final double arcOffset;
  final double size;
  final double alphaJitter;

  const _SparkData({
    required this.delay,
    required this.duration,
    required this.arcOffset,
    required this.size,
    required this.alphaJitter,
  });
}

class _SparkBurstPainter extends CustomPainter {
  final double progress;
  final Offset startOffset;
  final Offset targetOffset;
  final Color sparkColor;
  final List<_SparkData> sparks;

  static const MaskFilter _glowMaskFilter =
      MaskFilter.blur(BlurStyle.normal, 5.0);
  final Paint _glowPaint = Paint()..maskFilter = _glowMaskFilter;
  final Paint _tailPaint = Paint();
  final Paint _corePaint = Paint();

  _SparkBurstPainter({
    required this.progress,
    required this.startOffset,
    required this.targetOffset,
    required this.sparkColor,
    required this.sparks,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final diff = targetOffset - startOffset;
    final dist = diff.distance;
    if (dist <= 0) return;

    final normal = Offset(-diff.dy, diff.dx) / dist;

    for (final spark in sparks) {
      final sparkProgress =
          ((progress - spark.delay) / spark.duration).clamp(0.0, 1.0);
      if (sparkProgress <= 0.0 || sparkProgress >= 1.0) continue;

      final easedProgress = Curves.easeInOutCubic.transform(sparkProgress);
      final basePos = Offset.lerp(startOffset, targetOffset, easedProgress)!;
      final arc = math.sin(easedProgress * math.pi) * spark.arcOffset;
      final currentPos = basePos + (normal * arc);

      // Fade in quickly, stay bright, fade out on approach
      final opacity =
          (math.sin(sparkProgress * math.pi) * spark.alphaJitter).clamp(
            0.0,
            1.0,
          );
      final currentSize =
          spark.size * (0.8 + (math.sin(sparkProgress * math.pi) * 0.4));

      // Outer glow
      _glowPaint.color = sparkColor.withValues(alpha: opacity * 0.4);
      canvas.drawCircle(currentPos, currentSize * 2.2, _glowPaint);

      // Trailing ember dot
      if (sparkProgress > 0.05) {
        final prevEased = Curves.easeInOutCubic.transform(
          (sparkProgress - 0.04).clamp(0.0, 1.0),
        );
        final prevBase = Offset.lerp(startOffset, targetOffset, prevEased)!;
        final prevArc = math.sin(prevEased * math.pi) * spark.arcOffset;
        final prevPos = prevBase + (normal * prevArc);

        _tailPaint.color = sparkColor.withValues(alpha: opacity * 0.35);
        canvas.drawCircle(prevPos, currentSize * 0.6, _tailPaint);
      }

      // Bright inner core
      final coreColor = Color.lerp(
        sparkColor,
        Colors.white,
        0.65,
      )!.withValues(alpha: opacity);
      _corePaint.color = coreColor;
      canvas.drawCircle(currentPos, currentSize, _corePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparkBurstPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.startOffset != startOffset ||
        oldDelegate.targetOffset != targetOffset ||
        oldDelegate.sparkColor != sparkColor;
  }
}
