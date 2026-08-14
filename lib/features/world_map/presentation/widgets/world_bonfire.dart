import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:emerge_app/features/world_map/presentation/widgets/world_bonfire_visuals.dart';
import 'package:flutter/material.dart';

typedef WorldBonfireShaderLoader = Future<ui.FragmentProgram> Function();

class WorldBonfire extends StatefulWidget {
  final double health;
  final VoidCallback? onTap;
  final bool isStatusVisible;
  final WorldBonfireShaderLoader? shaderLoader;

  const WorldBonfire({
    super.key,
    required this.health,
    this.onTap,
    this.isStatusVisible = false,
    this.shaderLoader,
  });

  @override
  State<WorldBonfire> createState() => _WorldBonfireState();
}

class _WorldBonfireState extends State<WorldBonfire>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ambientController;
  ui.FragmentShader? _flameShader;
  bool _reduceMotion = false;
  bool _motionPreferenceInitialized = false;

  @override
  void initState() {
    super.initState();
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
      animationBehavior: AnimationBehavior.normal,
    )..repeat();
    _loadFlameShader();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_motionPreferenceInitialized && reduceMotion == _reduceMotion) {
      return;
    }

    _motionPreferenceInitialized = true;
    _reduceMotion = reduceMotion;
    if (reduceMotion) {
      _ambientController.stop(canceled: false);
    } else if (!_ambientController.isAnimating) {
      _ambientController.repeat();
    }
  }

  Future<void> _loadFlameShader() async {
    try {
      final loader =
          widget.shaderLoader ??
          () => ui.FragmentProgram.fromAsset('shaders/candle_flame.frag');
      final program = await loader();
      final shader = program.fragmentShader();
      if (mounted) {
        setState(() => _flameShader = shader);
      }
    } catch (error, stackTrace) {
      // The painter already renders the complete fire, so shader support is
      // an enhancement rather than a prerequisite for the map to work.
      AppLogger.d(
        'World bonfire shader unavailable; using painter fallback',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  void dispose() {
    _ambientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final semanticHealth = WorldBonfireVisualState.fromHealth(widget.health);
    final healthPercent = (semanticHealth.health * 100).round();

    return Semantics(
      button: widget.onTap != null,
      label: 'World health $healthPercent percent',
      hint: widget.onTap == null
          ? null
          : widget.isStatusVisible
          ? 'Double tap to hide world status'
          : 'Double tap to show world status',
      onTap: widget.onTap,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableExtent =
                constraints.hasBoundedWidth && constraints.hasBoundedHeight
                ? constraints.biggest.shortestSide
                : MediaQuery.sizeOf(context).shortestSide;
            final footprint = WorldBonfireGeometry.footprintFor(
              availableExtent,
            );

            return RepaintBoundary(
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(end: semanticHealth.health),
                duration: _reduceMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                builder: (context, animatedHealth, child) {
                  final visualState = WorldBonfireVisualState.fromHealth(
                    animatedHealth,
                  );
                  final geometry = WorldBonfireGeometry.fromVisualState(
                    visualState: visualState,
                    size: footprint,
                  );

                  return SizedBox(
                    key: const ValueKey('world-bonfire-footprint'),
                    width: footprint,
                    height: footprint,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CustomPaint(
                          key: const ValueKey(
                            'world-bonfire-procedural-painter',
                          ),
                          painter: WorldBonfirePainter(
                            visualState: visualState,
                            animation: _ambientController,
                          ),
                        ),
                        if (_flameShader != null)
                          Positioned.fromRect(
                            rect: geometry.coreRect,
                            child: CustomPaint(
                              painter: _CandleFlamePainter(
                                shader: _flameShader!,
                                visualState: visualState,
                                animation: _ambientController,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class WorldBonfirePainter extends CustomPainter {
  final WorldBonfireVisualState visualState;
  final Animation<double>? animation;
  final double animationValue;

  WorldBonfirePainter({
    required this.visualState,
    this.animation,
    this.animationValue = 0.0,
    Listenable? repaint,
  }) : super(repaint: repaint ?? animation);

  double get _currentAnimationValue => animation?.value ?? animationValue;

  @override
  void paint(Canvas canvas, Size size) {
    final geometry = WorldBonfireGeometry.fromVisualState(
      visualState: visualState,
      size: size.shortestSide,
    );
    final unit = geometry.unit;
    final centerX = geometry.centerX;
    final baseY = geometry.baseY;
    final phase = _currentAnimationValue * math.pi * 2;

    _paintGroundGlow(canvas, size, centerX, baseY, unit);
    _paintBase(canvas, centerX, baseY, unit);
    _paintOuterFlame(canvas, geometry, phase);
    _paintCandleFallback(canvas, centerX, baseY, unit, phase);
    _paintEmbers(canvas, centerX, baseY, unit, phase);
  }

  void _paintGroundGlow(
    Canvas canvas,
    Size size,
    double centerX,
    double baseY,
    double unit,
  ) {
    final glowRect = Rect.fromCenter(
      center: Offset(centerX, baseY + (8 * unit)),
      width: 170 * unit,
      height: 90 * unit,
    );
    final glow = RadialGradient(
      colors: [
        visualState.emberColor.withValues(
          alpha: visualState.glowOpacity * 0.45,
        ),
        visualState.emberColor.withValues(alpha: 0.0),
      ],
    );
    canvas.drawOval(glowRect, Paint()..shader = glow.createShader(glowRect));
  }

  void _paintBase(Canvas canvas, double centerX, double baseY, double unit) {
    final logColor = Color.lerp(
      const Color(0xFF24151B),
      const Color(0xFF4B2420),
      visualState.health,
    )!;
    final logHighlight = Color.lerp(
      const Color(0xFF5B2B20),
      const Color(0xFF9A4A24),
      visualState.health,
    )!;

    void drawLog(double angle, double yOffset, double xOffset) {
      canvas.save();
      canvas.translate(centerX + (xOffset * unit), baseY + (yOffset * unit));
      canvas.rotate(angle);
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: 100 * unit,
        height: 18 * unit,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(7 * unit)),
        Paint()..color = logColor,
      );
      canvas.drawLine(
        Offset(-34 * unit, -3 * unit),
        Offset(34 * unit, -3 * unit),
        Paint()
          ..color = logHighlight.withValues(alpha: 0.75)
          ..strokeWidth = 1.4 * unit,
      );
      canvas.restore();
    }

    drawLog(-0.23, 11, -4);
    drawLog(0.28, 16, 4);

    final stonePaint = Paint()..color = const Color(0xFF34283B);
    final stoneHighlight = Paint()
      ..color = Colors.white.withValues(alpha: 0.12);
    for (final stone in const [
      Offset(-62, 21),
      Offset(-38, 28),
      Offset(0, 29),
      Offset(38, 28),
      Offset(62, 21),
    ]) {
      final stoneCenter = Offset(
        centerX + (stone.dx * unit),
        baseY + (stone.dy * unit),
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: stoneCenter,
          width: 28 * unit,
          height: 16 * unit,
        ),
        stonePaint,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: stoneCenter.translate(-2 * unit, -2 * unit),
          width: 14 * unit,
          height: 4 * unit,
        ),
        stoneHighlight,
      );
    }
  }

  void _paintOuterFlame(
    Canvas canvas,
    WorldBonfireGeometry geometry,
    double phase,
  ) {
    final centerX = geometry.centerX;
    final baseY = geometry.baseY;
    final unit = geometry.unit;
    final halfWidth = geometry.halfWidth;
    final height = geometry.flameHeight;
    final tipY = baseY - height;
    final sway =
        math.sin(phase * 1.25) * visualState.flickerAmplitude * 26 * unit;
    final path = Path()
      ..moveTo(centerX + sway, tipY)
      ..cubicTo(
        centerX - (halfWidth * 0.08) + sway,
        tipY + (height * 0.22),
        centerX - (halfWidth * 0.92),
        baseY - (height * 0.46),
        centerX - (halfWidth * 0.84),
        baseY - (height * 0.16),
      )
      ..cubicTo(
        centerX - (halfWidth * 1.12),
        baseY - (height * 0.02),
        centerX - (halfWidth * 0.46),
        baseY + (height * 0.08),
        centerX,
        baseY,
      )
      ..cubicTo(
        centerX + (halfWidth * 0.54),
        baseY + (height * 0.08),
        centerX + (halfWidth * 1.08),
        baseY - (height * 0.04),
        centerX + (halfWidth * 0.78),
        baseY - (height * 0.22),
      )
      ..cubicTo(
        centerX + (halfWidth * 0.88) + sway,
        baseY - (height * 0.48),
        centerX + (halfWidth * 0.18) + sway,
        tipY + (height * 0.24),
        centerX + sway,
        tipY,
      )
      ..close();

    final flameRect = Rect.fromLTRB(
      centerX - halfWidth,
      tipY,
      centerX + halfWidth,
      baseY,
    );
    final baseColor = Color.lerp(
      const Color(0xFF7C211C),
      const Color(0xFFE85A26),
      visualState.health,
    )!;
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFFFFF0A1).withValues(alpha: visualState.outerOpacity),
        visualState.outerFlameColor.withValues(alpha: visualState.outerOpacity),
        baseColor.withValues(alpha: visualState.outerOpacity),
      ],
      stops: const [0.0, 0.42, 1.0],
    );
    canvas.drawPath(path, Paint()..shader = gradient.createShader(flameRect));

    _paintSideLick(
      canvas,
      centerX - (halfWidth * 0.55),
      baseY,
      -1,
      height * 0.58,
      halfWidth * 0.42,
      unit,
      phase,
    );
    _paintSideLick(
      canvas,
      centerX + (halfWidth * 0.55),
      baseY,
      1,
      height * 0.48,
      halfWidth * 0.36,
      unit,
      phase,
    );
  }

  void _paintSideLick(
    Canvas canvas,
    double baseX,
    double baseY,
    double direction,
    double height,
    double width,
    double unit,
    double phase,
  ) {
    final tipX = baseX + (direction * width * 0.34);
    final tipY = baseY - height;
    final lean = math.sin(phase * 1.7 + direction) * unit * 3;
    final path = Path()
      ..moveTo(baseX, baseY)
      ..cubicTo(
        baseX + (direction * width),
        baseY - (height * 0.06),
        baseX + (direction * width * 0.76),
        baseY - (height * 0.54),
        tipX + lean,
        tipY,
      )
      ..cubicTo(
        baseX + (direction * width * 0.02),
        tipY + (height * 0.28),
        baseX - (direction * width * 0.14),
        baseY - (height * 0.18),
        baseX,
        baseY,
      )
      ..close();

    final color = Color.lerp(
      const Color(0xFFD64025),
      const Color(0xFFFFA329),
      visualState.health,
    )!;
    canvas.drawPath(
      path,
      Paint()..color = color.withValues(alpha: visualState.outerOpacity * 0.9),
    );
  }

  void _paintCandleFallback(
    Canvas canvas,
    double centerX,
    double baseY,
    double unit,
    double phase,
  ) {
    final scale = visualState.flameScale;
    final height = 51 * scale * unit;
    final halfWidth = 16 * scale * unit;
    final sway = math.sin(phase * 1.45) * visualState.flickerAmplitude * 10;
    final tipY = baseY - height;
    final path = Path()
      ..moveTo(centerX + sway, tipY)
      ..cubicTo(
        centerX - (halfWidth * 0.15) + sway,
        tipY + (height * 0.3),
        centerX - halfWidth,
        baseY - (height * 0.36),
        centerX - (halfWidth * 0.72),
        baseY - (height * 0.08),
      )
      ..cubicTo(
        centerX - (halfWidth * 0.46),
        baseY + (height * 0.04),
        centerX + (halfWidth * 0.54),
        baseY + (height * 0.04),
        centerX + (halfWidth * 0.74),
        baseY - (height * 0.12),
      )
      ..cubicTo(
        centerX + halfWidth,
        baseY - (height * 0.42),
        centerX + (halfWidth * 0.12) + sway,
        tipY + (height * 0.24),
        centerX + sway,
        tipY,
      )
      ..close();
    final rect = Rect.fromLTRB(
      centerX - halfWidth,
      tipY,
      centerX + halfWidth,
      baseY,
    );
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.white.withValues(alpha: 0.96),
        const Color(0xFFFFF0A1).withValues(alpha: 0.98),
        visualState.emberColor.withValues(alpha: 0.98),
      ],
      stops: const [0.0, 0.42, 1.0],
    );
    canvas.drawPath(path, Paint()..shader = gradient.createShader(rect));
  }

  void _paintEmbers(
    Canvas canvas,
    double centerX,
    double baseY,
    double unit,
    double phase,
  ) {
    for (var index = 0; index < visualState.emberCount; index++) {
      final seed = index * 0.23;
      final travel =
          (phase / (math.pi * 2) * (0.65 + (index * 0.05)) + seed) % 1.0;
      final life = math.sin(travel * math.pi);
      final x =
          centerX +
          ((index - ((visualState.emberCount - 1) / 2)) * 13 * unit) +
          (math.sin(phase + (index * 1.8)) * 7 * unit);
      final y = baseY - ((14 + (travel * 62)) * unit);
      final radius = (1.2 + ((index % 2) * 0.7)) * unit;
      final color = visualState.emberColor.withValues(
        alpha: (0.18 + (life * 0.72)).clamp(0.0, 1.0),
      );
      canvas.drawCircle(
        Offset(x, y),
        radius * 2.4,
        Paint()..color = color.withValues(alpha: color.a * 0.2),
      );
      canvas.drawCircle(Offset(x, y), radius, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant WorldBonfirePainter oldDelegate) {
    return oldDelegate.visualState != visualState ||
        oldDelegate.animationValue != animationValue ||
        oldDelegate.animation != animation;
  }
}

class _CandleFlamePainter extends CustomPainter {
  final ui.FragmentShader shader;
  final WorldBonfireVisualState visualState;
  final Animation<double> animation;
  bool _disabled = false;

  _CandleFlamePainter({
    required this.shader,
    required this.visualState,
    required this.animation,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    if (_disabled) return;

    try {
      shader.setFloat(0, size.width);
      shader.setFloat(1, size.height);
      shader.setFloat(2, animation.value * math.pi * 2);
      shader.setFloat(3, visualState.health);
      canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
    } catch (error, stackTrace) {
      _disabled = true;
      AppLogger.d(
        'World bonfire shader failed during paint; using painter fallback',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CandleFlamePainter oldDelegate) {
    return oldDelegate.shader != shader ||
        oldDelegate.visualState != visualState ||
        oldDelegate.animation != animation;
  }
}
