import 'package:flutter/material.dart';

/// A scrolling parallax background representing the "Valley of New Beginnings".
/// Consists of multiple layers (Sky, Far Mountains, Mid Hills, Foreground) that move at different speeds.
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
    // We use AnimatedBuilder to rebuild just the positioning when scroll changes
    // But since Parallax often needs smooth updates, and we have a scrollController,
    // we can use a LayoutBuilder + ListenableBuilder (or AnimatedBuilder) pattern.
    return ListenableBuilder(
      listenable: scrollController,
      builder: (context, child) {
        final scrollOffset = scrollController.hasClients
            ? scrollController.offset
            : 0.0;

        // Parallax factors (0.0 = static, 1.0 = moves with scroll)
        // For a "depth" effect where background moves SLOWER than foreground (content):
        // Layer 0 (Sky): Nearly static (factor 0.1)
        // Layer 1 (Far): Slow (factor 0.3)
        // Layer 2 (Mid): Medium (factor 0.6)
        // Layer 3 (Near): Fast (factor 0.8)

        return Stack(
          fit: StackFit.expand,
          children: [
            // 1. Base Gradient (Deep Space/Valley Night)
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0F172A), // Slate 900
                    Color(0xFF312E81), // Indigo 900
                    Color(0xFF4C1D95), // Violet 900
                  ],
                ),
              ),
            ),

            // 2. Stars / Nebula (The Sky) - Moves very slowly (Parallax depth: Far)
            Positioned.fill(
              top: scrollOffset * 0.05, // Moves slightly down as we scroll up
              bottom: -scrollOffset * 0.05,
              child: Image.network(
                'https://images.unsplash.com/photo-1534447677768-be436bb09401?q=80&w=2894&auto=format&fit=crop',
                fit: BoxFit.cover,
                opacity: const AlwaysStoppedAnimation(0.6),
              ),
            ),

            // 3. Far Mountains (Silhouette) - Moves slowly (Parallax depth: Mid-Far)
            Positioned(
              left: 0,
              right: 0,
              top:
                  0 +
                  scrollOffset * 0.15, // Moves down as visible window moves up
              height: 1200,
              child: ShaderMask(
                shaderCallback: (bounds) {
                  return const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black, Colors.transparent],
                    stops: [0.6, 1.0],
                  ).createShader(bounds);
                },
                blendMode: BlendMode.dstIn,
                child: Image.network(
                  'https://images.unsplash.com/photo-1572916127117-9195a639b596?q=80&w=2806&auto=format&fit=crop',
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // 4. Midground (Valley Hills) - Moves faster (Parallax depth: Mid)
            Positioned(
              left: 0,
              right: 0,
              top: 300 + scrollOffset * 0.3, // Moves down faster
              height: 1500,
              child: Opacity(
                opacity: 0.8,
                child: Image.network(
                  'https://images.unsplash.com/photo-1518098268026-4e1c26002c6d?q=80&w=2788&auto=format&fit=crop',
                  fit: BoxFit.cover,
                  color: const Color(0xFF4C1D95).withValues(alpha: 0.5),
                  colorBlendMode: BlendMode.hardLight,
                ),
              ),
            ),

            // 5. Overlay Gradient (Fog/Atmosphere)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      const Color(0xFF0F172A).withValues(alpha: 0.4),
                      const Color(0xFF0F172A).withValues(alpha: 0.8),
                    ],
                    stops: const [0.0, 0.7, 1.0],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
