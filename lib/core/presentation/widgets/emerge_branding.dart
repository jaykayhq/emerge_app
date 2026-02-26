import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// The Core Color Palette - Plain Dark Background
class EmergeColors {
  // ============ PLAIN DARK BACKGROUND ============
  static const Color background = Color(0xFF0A0A1A); // Dark void
  static const Color backgroundLight = Color(0xFF1A0A2A); // Slightly lighter
  static const Color surface = Color(0xFF222222); // Surface for cards
  static const Color hexLine = Color(0xFF3A3A5A); // Border lines

  // ============ STITCH ACCENTS ============
  static const Color teal = Color(0xFF2BEE79); // Primary green (buttons/cards)
  static const Color tealMuted = Color(0xFF92C9A8); // Muted green text
  static const Color violet = Color(0xFF1DB954); // Secondary green
  static const Color violetSoft = Color(0xFF4ADE80); // Soft green
  static const Color coral = Color(0xFFf7768e); // Error / warning red
  static const Color yellow = Color(0xFFe0af68); // Accent yellow
  static const Color lime = Color(0xFF2BEE79); // Lime = primary green

  // ============ GLASSMORPHISM ============
  static const Color glassWhite = Color(0x14FFFFFF); // 8% white
  static const Color glassWhiteMed = Color(0x1FFFFFFF); // 12% white
  static const Color glassBorder = Color(0x26FFFFFF); // 15% white
  static const Color glassGreen = Color(0x142BEE79); // 8% green tint

  // ============ GRADIENTS ============
  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [backgroundLight, background],
  );

  static const LinearGradient neonGradient = LinearGradient(
    colors: [teal, Color(0xFF1DB954)],
  );

  static const LinearGradient warmGradient = LinearGradient(
    colors: [coral, yellow],
  );
}

// ---------------------------------------------------------------------------
// WIDGET: The Custom "Unfolding E" Logo Painter
// ---------------------------------------------------------------------------

class EmergeLogoWidget extends StatefulWidget {
  final double size;
  final bool animate;

  const EmergeLogoWidget({super.key, required this.size, this.animate = true});

  @override
  State<EmergeLogoWidget> createState() => _EmergeLogoWidgetState();
}

class _EmergeLogoWidgetState extends State<EmergeLogoWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _progressAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.8, curve: Curves.easeInOutCubic),
    );

    _rotationAnimation = Tween<double>(begin: -0.5, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutBack),
      ),
    );

    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: widget.animate ? _rotationAnimation.value : 0,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: EmergeColors.background.withValues(alpha: 0.5),
              boxShadow: [
                BoxShadow(
                  color: EmergeColors.teal.withValues(
                    alpha: 0.2 * _progressAnimation.value,
                  ),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: CustomPaint(
              painter: UnfoldingELogoPainter(
                progress: _progressAnimation.value,
              ),
            ),
          ),
        );
      },
    );
  }
}

class UnfoldingELogoPainter extends CustomPainter {
  final double progress;

  UnfoldingELogoPainter({this.progress = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Define Gradients for the strokes
    final Paint bottomPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF2E3192), Color(0xFF1BFFFF)],
      ).createShader(Rect.fromLTWH(0, h * 0.6, w, h * 0.2))
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = w * 0.12;

    final Paint middlePaint = Paint()
      ..shader = const LinearGradient(
        colors: [EmergeColors.violet, EmergeColors.coral],
      ).createShader(Rect.fromLTWH(0, h * 0.4, w, h * 0.2))
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = w * 0.12;

    final Paint topPaint = Paint()
      ..shader = const LinearGradient(
        colors: [EmergeColors.coral, EmergeColors.yellow],
      ).createShader(Rect.fromLTWH(0, 0, w, h * 0.4))
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = w * 0.12;

    // Paths
    Path bottomPath = Path();
    bottomPath.moveTo(w * 0.25, h * 0.75);
    bottomPath.quadraticBezierTo(w * 0.5, h * 0.85, w * 0.75, h * 0.70);

    Path middlePath = Path();
    middlePath.moveTo(w * 0.25, h * 0.55);
    middlePath.quadraticBezierTo(w * 0.5, h * 0.65, w * 0.85, h * 0.45);

    Path topPath = Path();
    topPath.moveTo(w * 0.25, h * 0.35);
    topPath.quadraticBezierTo(w * 0.4, h * 0.25, w * 0.70, h * 0.15);

    // Animate Paths sequentially
    // Total progress 0.0 -> 1.0
    // Bottom: 0.0 -> 0.4
    // Middle: 0.2 -> 0.7
    // Top:    0.5 -> 1.0

    double bottomProgress = (progress / 0.4).clamp(0.0, 1.0);
    double middleProgress = ((progress - 0.2) / 0.5).clamp(0.0, 1.0);
    double topProgress = ((progress - 0.5) / 0.5).clamp(0.0, 1.0);

    _drawPath(canvas, bottomPath, bottomPaint, bottomProgress);
    _drawPath(canvas, middlePath, middlePaint, middleProgress);
    _drawPath(canvas, topPath, topPaint, topProgress);
  }

  void _drawPath(Canvas canvas, Path path, Paint paint, double progress) {
    if (progress <= 0) return;

    ui.PathMetric pathMetric = path.computeMetrics().first;
    Path extract = pathMetric.extractPath(0.0, pathMetric.length * progress);
    canvas.drawPath(extract, paint);
  }

  @override
  bool shouldRepaint(covariant UnfoldingELogoPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ---------------------------------------------------------------------------
// WIDGET: Plain Dark Background (no green hex mesh)
// ---------------------------------------------------------------------------

class HexMeshBackground extends StatelessWidget {
  const HexMeshBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Base: Plain dark gradient
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF0A0A1A), // Dark void top
                Color(0xFF1A0A2A), // Dark purple center
                Color(0xFF0A0A1A), // Dark void bottom
              ],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
        ),

        // Subtle radial glow (top-left) - no green tint
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-0.6, -0.4),
              radius: 1.2,
              colors: [
                EmergeColors.teal.withValues(alpha: 0.02), // Very subtle
                Colors.transparent,
              ],
            ),
          ),
        ),

        // Subtle radial glow (bottom-right)
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0.7, 0.6),
              radius: 1.0,
              colors: [
                Colors.white.withValues(
                  alpha: 0.01,
                ), // White tint instead of green
                Colors.transparent,
              ],
            ),
          ),
        ),
      ],
    );
  }
}
