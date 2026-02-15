import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// The Core Color Palette - Stitch Design System
class EmergeColors {
  // ============ COSMIC PURPLE GRADIENT ============
  static const Color background = Color(0xFF0F0F23); // Deep cosmic
  static const Color backgroundLight = Color(0xFF1A0A2E); // Cosmic purple dark
  static const Color surface = Color(0xFF1E1433); // Cosmic surface
  static const Color hexLine = Color(0xFF1E2229);

  // ============ NEON ACCENTS ============
  static const Color teal = Color(0xFF00F0FF); // Bright neon teal
  static const Color tealMuted = Color(0xFF00BFA5); // Muted teal
  static const Color violet = Color(0xFF7C4DFF); // Neon violet
  static const Color violetSoft = Color(0xFFbb9af7); // Tokyo Night Purple
  static const Color coral = Color(0xFFf7768e); // Tokyo Night Red
  static const Color yellow = Color(0xFFe0af68); // Tokyo Night Yellow
  static const Color lime = Color(0xFF76FF03); // Lime green accent

  // ============ GLASSMORPHISM ============
  static const Color glassWhite = Color(0x14FFFFFF); // 8% white
  static const Color glassWhiteMed = Color(0x1FFFFFFF); // 12% white
  static const Color glassBorder = Color(0x26FFFFFF); // 15% white

  // ============ GRADIENTS ============
  static const LinearGradient cosmicGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [backgroundLight, background],
  );

  static const LinearGradient neonGradient = LinearGradient(
    colors: [teal, violet],
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
// WIDGET: The Hexagonal Mesh Background
// ---------------------------------------------------------------------------

class HexMeshBackground extends StatelessWidget {
  const HexMeshBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: HexGridPainter(), child: Container());
  }
}

class HexGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = EmergeColors.hexLine
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const double hexSize = 40.0;
    final double width = size.width;
    final double height = size.height;

    // Mathematical constants for hexagon positioning
    final double xOffset = hexSize * math.sqrt(3);
    final double yOffset = hexSize * 1.5;

    for (double y = -hexSize; y < height + hexSize; y += yOffset) {
      for (double x = -hexSize; x < width + hexSize; x += xOffset) {
        // Shift every other row
        double xPos = x;
        if ((y / yOffset).round() % 2 != 0) {
          xPos += xOffset / 2;
        }
        drawHexagon(canvas, paint, Offset(xPos, y), hexSize);
      }
    }
  }

  void drawHexagon(Canvas canvas, Paint paint, Offset center, double size) {
    Path path = Path();
    for (int i = 0; i < 6; i++) {
      double angle = (60 * i - 30) * (math.pi / 180);
      double x = center.dx + size * math.cos(angle);
      double y = center.dy + size * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
