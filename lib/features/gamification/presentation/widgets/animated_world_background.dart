import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Animated parallax world background with multiple layers
class AnimatedWorldBackground extends StatefulWidget {
  final String theme; // 'city', 'forest', 'sanctuary', 'island'
  final double scrollOffset;
  final bool isNightMode;

  const AnimatedWorldBackground({
    super.key,
    this.theme = 'city',
    this.scrollOffset = 0,
    this.isNightMode = false,
  });

  @override
  State<AnimatedWorldBackground> createState() =>
      _AnimatedWorldBackgroundState();
}

class _AnimatedWorldBackgroundState extends State<AnimatedWorldBackground>
    with TickerProviderStateMixin {
  late final AnimationController _cloudController;
  late final AnimationController _lightController;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _cloudController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();

    _lightController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _cloudController.dispose();
    _lightController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Sky gradient layer
          _buildSkyLayer(),

          // Clouds layer (far)
          AnimatedBuilder(
            animation: _cloudController,
            builder: (context, child) =>
                _buildCloudsLayer(_cloudController.value),
          ),

          // Far buildings/environment
          _buildFarLayer(),

          // Mid buildings/environment
          _buildMidLayer(),

          // Near buildings/environment
          _buildNearLayer(),

          // Foreground elements
          _buildForegroundLayer(),

          // Lighting effects overlay
          AnimatedBuilder(
            animation: _lightController,
            builder: (context, child) =>
                _buildLightingOverlay(_lightController.value),
          ),
        ],
      ),
    );
  }

  Widget _buildSkyLayer() {
    final isCity = widget.theme == 'city';
    final isNight = widget.isNightMode || _isNightTime();

    final gradientColors = isNight
        ? (isCity
              ? [
                  const Color(0xFF0a0a1a),
                  const Color(0xFF1a1a3a),
                  const Color(0xFF2a1a4a),
                ]
              : [
                  const Color(0xFF0a1520),
                  const Color(0xFF152535),
                  const Color(0xFF203545),
                ])
        : (isCity
              ? [
                  const Color(0xFF1a2a4a),
                  const Color(0xFF3a4a6a),
                  const Color(0xFF5a6a8a),
                ]
              : [
                  const Color(0xFF87CEEB),
                  const Color(0xFFB0E0E6),
                  const Color(0xFFE0F4FF),
                ]);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradientColors,
        ),
      ),
    );
  }

  Widget _buildCloudsLayer(double progress) {
    return CustomPaint(
      painter: CloudsPainter(
        progress: progress,
        isNight: widget.isNightMode || _isNightTime(),
        theme: widget.theme,
      ),
      size: Size.infinite,
    );
  }

  Widget _buildFarLayer() {
    if (widget.theme == 'city') {
      return Transform.translate(
        offset: Offset(widget.scrollOffset * 0.1, 0),
        child: CustomPaint(
          painter: CityLayerPainter(
            depth: 0, // Far
            animationValue: _pulseController.value,
            isNight: widget.isNightMode || _isNightTime(),
          ),
          size: Size.infinite,
        ),
      );
    }
    return _buildForestFarLayer();
  }

  Widget _buildMidLayer() {
    if (widget.theme == 'city') {
      return Transform.translate(
        offset: Offset(widget.scrollOffset * 0.3, 0),
        child: AnimatedBuilder(
          animation: _lightController,
          builder: (context, child) => CustomPaint(
            painter: CityLayerPainter(
              depth: 1, // Mid
              animationValue: _lightController.value,
              isNight: widget.isNightMode || _isNightTime(),
            ),
            size: Size.infinite,
          ),
        ),
      );
    }
    return _buildForestMidLayer();
  }

  Widget _buildNearLayer() {
    if (widget.theme == 'city') {
      return Transform.translate(
        offset: Offset(widget.scrollOffset * 0.5, 0),
        child: CustomPaint(
          painter: CityLayerPainter(
            depth: 2, // Near
            animationValue: _lightController.value,
            isNight: widget.isNightMode || _isNightTime(),
          ),
          size: Size.infinite,
        ),
      );
    }
    return _buildForestNearLayer();
  }

  Widget _buildForegroundLayer() {
    if (widget.theme == 'city') {
      return Transform.translate(
        offset: Offset(widget.scrollOffset * 0.7, 0),
        child: CustomPaint(
          painter: CityForegroundPainter(
            animationValue: _pulseController.value,
            isNight: widget.isNightMode || _isNightTime(),
          ),
          size: Size.infinite,
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildLightingOverlay(double value) {
    if (widget.theme != 'city') return const SizedBox.shrink();

    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.5,
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.1 + value * 0.05),
            ],
          ),
        ),
      ),
    );
  }

  // Forest theme fallbacks
  Widget _buildForestFarLayer() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            const Color(0xFF1a472a).withValues(alpha: 0.3),
          ],
        ),
      ),
    );
  }

  Widget _buildForestMidLayer() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      height: 300,
      child: CustomPaint(
        painter: ForestLayerPainter(depth: 1),
        size: Size.infinite,
      ),
    );
  }

  Widget _buildForestNearLayer() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      height: 200,
      child: CustomPaint(
        painter: ForestLayerPainter(depth: 2),
        size: Size.infinite,
      ),
    );
  }

  bool _isNightTime() {
    final hour = DateTime.now().hour;
    return hour < 6 || hour > 20;
  }
}

/// Painter for animated clouds
class CloudsPainter extends CustomPainter {
  final double progress;
  final bool isNight;
  final String theme;

  CloudsPainter({
    required this.progress,
    required this.isNight,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isNight ? Colors.grey.shade800 : Colors.white).withValues(
        alpha: isNight ? 0.3 : 0.6,
      );

    // Draw scrolling clouds
    for (int i = 0; i < 8; i++) {
      final baseX =
          (i * 150.0 + progress * size.width * 2) % (size.width + 200) - 100;
      final y = 50.0 + (i % 3) * 40;
      final cloudSize = 40.0 + (i % 4) * 20;

      _drawCloud(canvas, Offset(baseX, y), cloudSize, paint);
    }

    // For city theme, add hologram-like elements
    if (theme == 'city' && isNight) {
      final holoPaint = Paint()
        ..color = Colors.cyan.withValues(
          alpha: 0.1 + (math.sin(progress * math.pi * 2) * 0.05),
        );

      for (int i = 0; i < 3; i++) {
        final x = size.width * (0.2 + i * 0.3);
        final y = size.height * 0.15;
        canvas.drawCircle(Offset(x, y), 20, holoPaint);
      }
    }
  }

  void _drawCloud(Canvas canvas, Offset center, double size, Paint paint) {
    // Draw fluffy cloud shape
    canvas.drawCircle(center, size * 0.5, paint);
    canvas.drawCircle(center + Offset(-size * 0.4, 0), size * 0.35, paint);
    canvas.drawCircle(center + Offset(size * 0.4, 0), size * 0.35, paint);
    canvas.drawCircle(
      center + Offset(-size * 0.2, -size * 0.2),
      size * 0.3,
      paint,
    );
    canvas.drawCircle(
      center + Offset(size * 0.2, -size * 0.2),
      size * 0.3,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CloudsPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isNight != isNight;
  }
}

/// Painter for futuristic city layers
class CityLayerPainter extends CustomPainter {
  final int depth; // 0=far, 1=mid, 2=near
  final double animationValue;
  final bool isNight;

  CityLayerPainter({
    required this.depth,
    required this.animationValue,
    required this.isNight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final baseY = size.height * (0.4 + depth * 0.1);
    final buildingCount = 8 + depth * 4;
    final maxHeight = size.height * (0.3 + depth * 0.15);

    final random = math.Random(depth * 100);

    for (int i = 0; i < buildingCount; i++) {
      final x = (i / buildingCount) * size.width;
      final width = 20.0 + random.nextDouble() * 40 + depth * 10;
      final height = maxHeight * (0.4 + random.nextDouble() * 0.6);

      _drawBuilding(canvas, x, baseY, width, height, random, i);
    }
  }

  void _drawBuilding(
    Canvas canvas,
    double x,
    double baseY,
    double width,
    double height,
    math.Random random,
    int index,
  ) {
    final rect = Rect.fromLTWH(x, baseY - height, width, height);

    // Building body gradient
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: isNight
          ? [
              const Color(0xFF1a1a2a),
              const Color(0xFF2a2a4a),
              const Color(0xFF3a3a5a),
            ]
          : [
              const Color(0xFF4a5a7a),
              const Color(0xFF5a6a8a),
              const Color(0xFF6a7a9a),
            ],
    );

    final buildingPaint = Paint()..shader = gradient.createShader(rect);

    canvas.drawRect(rect, buildingPaint);

    // Draw windows
    _drawWindows(canvas, rect, random, index);

    // Neon accents for night city
    if (isNight && depth >= 1) {
      _drawNeonAccents(canvas, rect, random, index);
    }
  }

  void _drawWindows(
    Canvas canvas,
    Rect building,
    math.Random random,
    int index,
  ) {
    final windowPaint = Paint();
    final rows = (building.height / 15).floor();
    final cols = (building.width / 12).floor();

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final isLit =
            random.nextDouble() > 0.3 ||
            (isNight && (row + col + index) % 3 == 0 && animationValue > 0.5);

        windowPaint.color = isLit
            ? (isNight
                  ? Color.lerp(
                      Colors.amber.shade200,
                      Colors.cyan.shade200,
                      random.nextDouble(),
                    )!
                  : Colors.lightBlue.shade100)
            : Colors.grey.shade800;

        final windowRect = Rect.fromLTWH(
          building.left + 4 + col * 12,
          building.top + 4 + row * 15,
          8,
          10,
        );

        canvas.drawRect(windowRect, windowPaint);
      }
    }
  }

  void _drawNeonAccents(
    Canvas canvas,
    Rect building,
    math.Random random,
    int index,
  ) {
    final neonColors = [Colors.cyan, Colors.pink, Colors.purple, Colors.amber];
    final color = neonColors[(index + depth) % neonColors.length];

    final neonPaint = Paint()
      ..color = color.withValues(alpha: 0.6 + animationValue * 0.4)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Horizontal accent line
    final lineY = building.top + building.height * 0.2;
    canvas.drawLine(
      Offset(building.left, lineY),
      Offset(building.right, lineY),
      neonPaint,
    );

    // Glow effect
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawLine(
      Offset(building.left, lineY),
      Offset(building.right, lineY),
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CityLayerPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.isNight != isNight;
  }
}

/// Painter for city foreground elements
class CityForegroundPainter extends CustomPainter {
  final double animationValue;
  final bool isNight;

  CityForegroundPainter({required this.animationValue, required this.isNight});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw street level
    final streetPaint = Paint()..color = const Color(0xFF2a2a3a);

    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.85, size.width, size.height * 0.15),
      streetPaint,
    );

    // Draw road markings
    final markingPaint = Paint()
      ..color = Colors.yellow.withValues(alpha: 0.6)
      ..strokeWidth = 3;

    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(
        Offset(x, size.height * 0.92),
        Offset(x + 20, size.height * 0.92),
        markingPaint,
      );
    }

    // Draw streetlights
    if (isNight) {
      for (double x = 50; x < size.width; x += 150) {
        _drawStreetlight(canvas, Offset(x, size.height * 0.85));
      }
    }
  }

  void _drawStreetlight(Canvas canvas, Offset base) {
    // Pole
    final polePaint = Paint()..color = Colors.grey.shade700;
    canvas.drawRect(Rect.fromLTWH(base.dx - 2, base.dy - 60, 4, 60), polePaint);

    // Light fixture
    canvas.drawCircle(base - const Offset(0, 60), 8, polePaint);

    // Light glow
    final glowPaint = Paint()
      ..color = Colors.amber.withValues(alpha: 0.3 + animationValue * 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

    canvas.drawCircle(base - const Offset(0, 60), 25, glowPaint);

    // Light cone
    final path = Path()
      ..moveTo(base.dx - 15, base.dy - 55)
      ..lineTo(base.dx - 30, base.dy)
      ..lineTo(base.dx + 30, base.dy)
      ..lineTo(base.dx + 15, base.dy - 55)
      ..close();

    final conePaint = Paint()
      ..color = Colors.amber.withValues(alpha: 0.08 + animationValue * 0.04);

    canvas.drawPath(path, conePaint);
  }

  @override
  bool shouldRepaint(covariant CityForegroundPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.isNight != isNight;
  }
}

/// Painter for forest layers (fallback theme)
class ForestLayerPainter extends CustomPainter {
  final int depth;

  ForestLayerPainter({required this.depth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = depth == 1
          ? const Color(0xFF1a472a).withValues(alpha: 0.7)
          : const Color(0xFF2d5a27);

    // Draw tree silhouettes
    final treeCount = 10 + depth * 5;
    final random = math.Random(depth * 42);

    for (int i = 0; i < treeCount; i++) {
      final x = (i / treeCount) * size.width;
      final treeHeight = 50.0 + random.nextDouble() * 100;
      _drawTree(canvas, Offset(x, size.height), treeHeight, paint);
    }
  }

  void _drawTree(Canvas canvas, Offset base, double height, Paint paint) {
    final path = Path()
      ..moveTo(base.dx, base.dy)
      ..lineTo(base.dx - height * 0.3, base.dy - height * 0.4)
      ..lineTo(base.dx - height * 0.2, base.dy - height * 0.4)
      ..lineTo(base.dx - height * 0.35, base.dy - height * 0.7)
      ..lineTo(base.dx - height * 0.15, base.dy - height * 0.7)
      ..lineTo(base.dx, base.dy - height)
      ..lineTo(base.dx + height * 0.15, base.dy - height * 0.7)
      ..lineTo(base.dx + height * 0.35, base.dy - height * 0.7)
      ..lineTo(base.dx + height * 0.2, base.dy - height * 0.4)
      ..lineTo(base.dx + height * 0.3, base.dy - height * 0.4)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant ForestLayerPainter oldDelegate) => false;
}
