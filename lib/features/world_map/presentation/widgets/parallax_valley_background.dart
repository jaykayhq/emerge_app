import 'package:flutter/material.dart';

/// A scrolling parallax background representing the "Valley of New Beginnings".
/// Uses cosmic purple-black palette with 3 depth layers that move at different speeds.
/// Based on the Stitch World Map cosmic design.
/// Wrapped in RepaintBoundary for performance isolation.
class ParallaxValleyBackground extends StatelessWidget {
  final ScrollController scrollController;
  final double mapHeight;

  const ParallaxValleyBackground({
    super.key,
    required this.scrollController,
    required this.mapHeight,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: scrollController,
      builder: (context, child) {
        final scrollOffset = scrollController.hasClients
            ? scrollController.offset
            : 0.0;

        return Stack(
          fit: StackFit.expand,
          children: [
            // Layer 0: Base cosmic gradient (static)
            RepaintBoundary(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF0A0A1A), // Near-black void
                      Color(0xFF1A0A2A), // Rich purple center
                      Color(0xFF2A1A3A), // Mid-tone purple
                    ],
                  ),
                ),
              ),
            ),

            // Layer 1: Far cosmic mist (parallax 0.1x) — slowest
            RepaintBoundary(
              child: Positioned.fill(
                top: scrollOffset * 0.05,
                bottom: -scrollOffset * 0.05,
                child: CustomPaint(
                  painter: _CosmicSkyPainter(
                    scrollOffset: scrollOffset,
                    layerFactor: 0.1,
                  ),
                ),
              ),
            ),

            // Layer 2: Mid-ground nebula hills (parallax 0.3x)
            RepaintBoundary(
              child: Positioned(
                left: 0,
                right: 0,
                top: 200 + scrollOffset * 0.2,
                height: mapHeight * 0.8,
                child: CustomPaint(
                  painter: _CosmicHillsPainter(
                    scrollOffset: scrollOffset,
                    color: const Color(0xFF1A0A2A),
                  ),
                ),
              ),
            ),

            // Layer 3: Near-ground cosmic formations (parallax 0.5x) — fastest
            RepaintBoundary(
              child: Positioned(
                left: 0,
                right: 0,
                top: 400 + scrollOffset * 0.4,
                height: mapHeight * 0.6,
                child: CustomPaint(
                  painter: _CosmicHillsPainter(
                    scrollOffset: scrollOffset,
                    color: const Color(0xFF2A1A3A),
                  ),
                ),
              ),
            ),

            // Layer 4: Atmospheric fog overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      const Color(0xFF1A0A2A).withValues(alpha: 0.3),
                      const Color(0xFF0A0A1A).withValues(alpha: 0.7),
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                ),
              ),
            ),

            // Layer 5: Star particles (subtle white/blue glow dots)
            RepaintBoundary(
              child: Positioned.fill(
                child: CustomPaint(
                  painter: _StarPainter(scrollOffset: scrollOffset),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Paints subtle gradient sky with cosmic tones
class _CosmicSkyPainter extends CustomPainter {
  final double scrollOffset;
  final double layerFactor;

  _CosmicSkyPainter({required this.scrollOffset, required this.layerFactor});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw subtle stars/dots with cosmic colors
    final colors = [
      const Color(0xFF2BEE79).withValues(alpha: 0.08), // Green accent
      const Color(0xFFAACFFF).withValues(alpha: 0.08), // Blue stars
      const Color(0xFFFFD700).withValues(alpha: 0.06), // Gold stars
    ];

    for (int i = 0; i < 40; i++) {
      final x = (i * 47.3) % size.width;
      final y = ((i * 29.7) % size.height) + scrollOffset * layerFactor;
      final colorIndex = i % colors.length;

      final paint = Paint()..color = colors[colorIndex];
      canvas.drawCircle(Offset(x, y % size.height), 1.5 + (i % 3) * 0.5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CosmicSkyPainter oldDelegate) =>
      oldDelegate.scrollOffset != scrollOffset;
}

/// Paints wavy hills for the mid and near ground layers (cosmic theme)
class _CosmicHillsPainter extends CustomPainter {
  final double scrollOffset;
  final Color color;

  _CosmicHillsPainter({required this.scrollOffset, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: 0.5);

    final path = Path();
    path.moveTo(0, size.height * 0.4);

    // Wavy cosmic hills
    for (double x = 0; x <= size.width; x += 20) {
      final y =
          size.height * 0.4 +
          30 * (0.5 + 0.5 * ((x + scrollOffset * 0.1) * 0.01).abs() % 1);
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CosmicHillsPainter oldDelegate) =>
      oldDelegate.scrollOffset != scrollOffset;
}

/// Paints floating star particles with subtle glow
class _StarPainter extends CustomPainter {
  final double scrollOffset;

  _StarPainter({required this.scrollOffset});

  @override
  void paint(Canvas canvas, Size size) {
    final glowPaint = Paint()
      ..color = const Color(0xFF2BEE79).withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    final dotPaint = Paint()
      ..color = const Color(0xFF2BEE79).withValues(alpha: 0.35);

    // Also add blue stars
    final blueGlowPaint = Paint()
      ..color = const Color(0xFFAACFFF).withValues(alpha: 0.10)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    final blueDotPaint = Paint()
      ..color = const Color(0xFFAACFFF).withValues(alpha: 0.30);

    for (int i = 0; i < 12; i++) {
      final phase = scrollOffset * 0.002 + i * 1.7;
      final x = (i * 73.7 + phase * 20) % size.width;
      final y = (i * 53.1 + scrollOffset * 0.08) % size.height;

      final isGreen = i % 2 == 0;
      // Glow
      canvas.drawCircle(Offset(x, y), 4, isGreen ? glowPaint : blueGlowPaint);
      // Dot
      canvas.drawCircle(Offset(x, y), 1.5, isGreen ? dotPaint : blueDotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarPainter oldDelegate) =>
      oldDelegate.scrollOffset != scrollOffset;
}
