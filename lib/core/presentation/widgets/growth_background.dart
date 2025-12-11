import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class GrowthBackground extends StatelessWidget {
  final Widget child;
  final bool showPattern;
  final PreferredSizeWidget? appBar;

  const GrowthBackground({
    super.key,
    required this.child,
    this.showPattern = true,
    this.appBar,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: appBar,
      extendBodyBehindAppBar: true, // Allow background to show behind app bar
      body: Stack(
        children: [
          // Base Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        const Color(0xFF1A1A1A), // Dark Grey
                        const Color(0xFF2D3436), // Slate Blue
                      ]
                    : [
                        const Color(0xFFF8F9FA), // Off White
                        const Color(0xFFE3F2FD), // Light Blue tint
                      ],
              ),
            ),
          ),

          // Growth/Grind Pattern (Subtle Overlay)
          if (showPattern)
            Positioned.fill(
              child: Opacity(
                opacity: 0.05,
                child: CustomPaint(
                  painter: _GridPainter(
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ),

          // Accent Orbs (Vitality & Energy)
          // Accent Orbs (Vitality & Energy)
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.primary.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.primary.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Main Content
          SafeArea(child: child),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final Color color;

  _GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    const gridSize = 40.0;

    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
