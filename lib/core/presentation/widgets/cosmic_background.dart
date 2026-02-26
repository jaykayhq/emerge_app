import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Universal cosmic background widget based on the Stitch World Map design.
/// Features deep purple-black gradients, nebula effects, animated stars,
/// and cosmic dust particles that create an immersive space atmosphere.
///
/// This background is designed to work across all screens in the app,
/// providing visual consistency while reinforcing the identity-first theme.
class CosmicBackground extends StatefulWidget {
  final Widget child;
  final bool showNebula;
  final bool showStars;
  final bool showCosmicDust;
  final bool animate;
  final double opacity;

  const CosmicBackground({
    super.key,
    required this.child,
    this.showNebula = true,
    this.showStars = true,
    this.showCosmicDust = true,
    this.animate = true,
    this.opacity = 1.0,
  });

  @override
  State<CosmicBackground> createState() => _CosmicBackgroundState();
}

class _CosmicBackgroundState extends State<CosmicBackground>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _ticker = createTicker(_onTick);
      _ticker.start();
    }
  }

  void _onTick(Duration elapsed) {
    setState(() {
      _elapsed = elapsed;
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF0A0A1A), // Deep purple-black void
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Layer 1: Base gradient (void of space)
          Opacity(
            opacity: widget.opacity,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0A0A1A), // Near-black edges
                    Color(0xFF1A0A2A), // Rich purple center
                    Color(0xFF0A0A1A), // Near-black bottom
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // Layer 2: Nebula effects (swirling cosmic clouds)
          if (widget.showNebula)
            Opacity(
              opacity: widget.opacity,
              child: Positioned.fill(
                child: _NebulaLayer(elapsed: _elapsed, animate: widget.animate),
              ),
            ),

          // Layer 3: Star field (twinkling stars)
          if (widget.showStars)
            Opacity(
              opacity: widget.opacity,
              child: Positioned.fill(
                child: _StarFieldLayer(
                  elapsed: _elapsed,
                  animate: widget.animate,
                ),
              ),
            ),

          // Layer 4: Cosmic dust (wispy streaks)
          if (widget.showCosmicDust)
            Opacity(
              opacity: widget.opacity,
              child: Positioned.fill(
                child: _CosmicDustLayer(
                  elapsed: _elapsed,
                  animate: widget.animate,
                ),
              ),
            ),

          // Layer 5: Central glow (Valley of New Beginnings highlight)
          Opacity(
            opacity: widget.opacity * 0.6,
            child: Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.6,
                    colors: [
                      const Color(
                        0xFF2A1A3A,
                      ).withValues(alpha: 0.3), // Mid-tone purple
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Layer 6: Main content
          SafeArea(child: widget.child),
        ],
      ),
    );
  }
}

/// Nebula layer with swirling purple and blue gradients
class _NebulaLayer extends StatelessWidget {
  final Duration elapsed;
  final bool animate;

  const _NebulaLayer({required this.elapsed, required this.animate});

  @override
  Widget build(BuildContext context) {
    final phase = animate ? elapsed.inMilliseconds / 5000.0 : 0.0;

    return Stack(
      children: [
        // Top-left nebula (purple)
        Positioned(
          top: -100 + (animate ? math.sin(phase) * 30 : 0),
          left: -100 + (animate ? math.cos(phase * 0.7) * 30 : 0),
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF2A1A3A).withValues(alpha: 0.25),
                  const Color(0xFF1A0A3A).withValues(alpha: 0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Top-right nebula (blue)
        Positioned(
          top: -50 + (animate ? math.cos(phase * 0.8) * 25 : 0),
          right: -100 + (animate ? math.sin(phase * 0.6) * 30 : 0),
          child: Container(
            width: 350,
            height: 350,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF0A1A3A).withValues(alpha: 0.2),
                  const Color(0xFF1A0A2A).withValues(alpha: 0.08),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Bottom nebula (deeper purple)
        Positioned(
          bottom: -150 + (animate ? math.sin(phase * 0.5) * 20 : 0),
          left: 100 + (animate ? math.cos(phase * 0.9) * 40 : 0),
          child: Container(
            width: 500,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF1A0A2A).withValues(alpha: 0.2),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Center-left nebula glow
        Positioned(
          top: 200 + (animate ? math.sin(phase * 0.6) * 20 : 0),
          left: -80 + (animate ? math.cos(phase * 0.7) * 25 : 0),
          child: Container(
            width: 250,
            height: 350,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF2A1A3A).withValues(alpha: 0.15),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Center-right nebula glow
        Positioned(
          top: 400 + (animate ? math.cos(phase * 0.8) * 25 : 0),
          right: -100 + (animate ? math.sin(phase * 0.5) * 30 : 0),
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF0A1A3A).withValues(alpha: 0.12),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Animated star field with twinkling effect
class _StarFieldLayer extends StatelessWidget {
  final Duration elapsed;
  final bool animate;

  const _StarFieldLayer({required this.elapsed, required this.animate});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _StarFieldPainter(elapsed: elapsed, animate: animate),
    );
  }
}

class _StarFieldPainter extends CustomPainter {
  final Duration elapsed;
  final bool animate;

  _StarFieldPainter({required this.elapsed, required this.animate});

  @override
  void paint(Canvas canvas, Size size) {
    final time = elapsed.inMilliseconds / 1000.0;

    // Generate deterministic stars based on position
    final random = math.Random(42); // Fixed seed for consistency

    for (int i = 0; i < 80; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final baseSize = random.nextDouble() * 1.5 + 0.5;
      final phase = random.nextDouble() * math.pi * 2;
      final speed = random.nextDouble() * 0.5 + 0.3;

      // Twinkle effect
      final twinkle = animate
          ? (math.sin(time * speed + phase) * 0.5 + 0.5)
          : 0.7;

      // Star color variations (white, blue-tinted, gold-tinted)
      final colorType = random.nextDouble();
      final baseColor = colorType < 0.7
          ? const Color(0xFFFFFFFF) // White
          : colorType < 0.85
          ? const Color(0xFFAACFFF) // Blue-tinted
          : const Color(0xFFFFD700); // Gold-tinted

      // Draw star glow for larger stars
      if (baseSize > 1.2) {
        final glowPaint = Paint()
          ..color = baseColor.withValues(alpha: 0.15 * twinkle)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
        canvas.drawCircle(Offset(x, y), baseSize * 3, glowPaint);
      }

      // Draw star
      final starPaint = Paint()
        ..color = baseColor.withValues(
          alpha: (0.5 + twinkle * 0.5).clamp(0.0, 1.0),
        );
      canvas.drawCircle(Offset(x, y), baseSize, starPaint);
    }

    // Add slow drift animation for some stars
    if (animate) {
      for (int i = 0; i < 20; i++) {
        final baseX = (i * 73.7) % size.width;
        final baseY = (i * 53.1) % size.height;
        final driftX = (time * 5 + i * 20) % (size.width + 100) - 50;
        final y = baseY + math.sin(time * 0.1 + i) * 10;

        final driftPaint = Paint()
          ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.3);
        canvas.drawCircle(
          Offset((baseX + driftX) % size.width, y),
          0.8,
          driftPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StarFieldPainter oldDelegate) =>
      animate && oldDelegate.elapsed != elapsed;
}

/// Cosmic dust layer with wispy streaks
class _CosmicDustLayer extends StatelessWidget {
  final Duration elapsed;
  final bool animate;

  const _CosmicDustLayer({required this.elapsed, required this.animate});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CosmicDustPainter(elapsed: elapsed, animate: animate),
    );
  }
}

class _CosmicDustPainter extends CustomPainter {
  final Duration elapsed;
  final bool animate;

  _CosmicDustPainter({required this.elapsed, required this.animate});

  @override
  void paint(Canvas canvas, Size size) {
    final time = elapsed.inMilliseconds / 3000.0;

    // Draw wispy cosmic dust streaks
    final dustPaths = [
      // Streak 1
      {
        'start': Offset(size.width * 0.1, size.height * 0.2),
        'end': Offset(size.width * 0.3, size.height * 0.35),
        'color': const Color(0xFF2A1A3A),
      },
      // Streak 2
      {
        'start': Offset(size.width * 0.6, size.height * 0.1),
        'end': Offset(size.width * 0.8, size.height * 0.25),
        'color': const Color(0xFF1A2A3A),
      },
      // Streak 3
      {
        'start': Offset(size.width * 0.2, size.height * 0.6),
        'end': Offset(size.width * 0.4, size.height * 0.75),
        'color': const Color(0xFF2A1A3A),
      },
      // Streak 4
      {
        'start': Offset(size.width * 0.7, size.height * 0.5),
        'end': Offset(size.width * 0.9, size.height * 0.65),
        'color': const Color(0xFF1A2A3A),
      },
      // Streak 5
      {
        'start': Offset(size.width * 0.4, size.height * 0.8),
        'end': Offset(size.width * 0.6, size.height * 0.9),
        'color': const Color(0xFF2A1A3A),
      },
    ];

    for (final streak in dustPaths) {
      final start = streak['start'] as Offset;
      final end = streak['end'] as Offset;
      final color = streak['color'] as Color;

      final phase = animate ? time + dustPaths.indexOf(streak) : 0.0;
      final opacity = animate ? (math.sin(phase) * 0.5 + 0.5) * 0.15 : 0.1;

      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 40
        ..strokeCap = StrokeCap.round;

      // Add subtle movement to streaks
      final offset = animate
          ? Offset(math.sin(phase * 0.5) * 5, math.cos(phase * 0.3) * 3)
          : Offset.zero;

      canvas.drawLine(start + offset, end + offset, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CosmicDustPainter oldDelegate) =>
      animate && oldDelegate.elapsed != elapsed;
}
