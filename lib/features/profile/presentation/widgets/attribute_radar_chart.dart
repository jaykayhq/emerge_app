import 'dart:math' as math;
import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';

/// Hexagonal radar chart displaying 6 attributes:
/// Creativity, Focus, Output, Resilience, Vitality, Discipline
class AttributeRadarChart extends StatefulWidget {
  final Map<String, double> attributes; // Values 0.0-1.0
  final double size;
  final ValueChanged<String>? onAttributeTap;

  const AttributeRadarChart({
    super.key,
    required this.attributes,
    this.size = 200,
    this.onAttributeTap,
  });

  static const List<String> attributeNames = [
    'Creativity',
    'Focus',
    'Output',
    'Resilience',
    'Vitality',
    'Discipline',
  ];

  static const List<IconData> attributeIcons = [
    Icons.palette,
    Icons.center_focus_strong,
    Icons.trending_up,
    Icons.shield,
    Icons.favorite,
    Icons.schedule,
  ];

  static const List<Color> attributeColors = [
    Colors.orangeAccent,
    Colors.blueAccent,
    Colors.greenAccent,
    Colors.purpleAccent,
    Colors.redAccent,
    Colors.tealAccent,
  ];

  @override
  State<AttributeRadarChart> createState() => _AttributeRadarChartState();
}

class _AttributeRadarChartState extends State<AttributeRadarChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fillAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fillAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _controller.forward());
  }

  @override
  void didUpdateWidget(AttributeRadarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.attributes != widget.attributes) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background hexagon grid
          CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _HexagonGridPainter(),
          ),

          // Filled attributes area
          CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _AttributeAreaPainter(
              attributes: widget.attributes,
              attributeNames: AttributeRadarChart.attributeNames,
              fillProgress: _fillAnimation.value,
            ),
          ),

          // Attribute labels around the hexagon
          ...List.generate(6, (index) {
            final angle = (index * 60 - 90) * (math.pi / 180);
            final labelOffset = widget.size * 0.58;
            final x = math.cos(angle) * labelOffset;
            final y = math.sin(angle) * labelOffset;
            final name = AttributeRadarChart.attributeNames[index];
            final value = widget.attributes[name] ?? 0.0;

            return Positioned(
              left: widget.size / 2 + x - 30,
              top: widget.size / 2 + y - 20,
              child: GestureDetector(
                onTap: () => widget.onAttributeTap?.call(name),
                child: SizedBox(
                  width: 60,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        AttributeRadarChart.attributeIcons[index],
                        color: AttributeRadarChart.attributeColors[index],
                        size: 16,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        name.substring(0, 3),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.textSecondaryDark,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        '${(value * 100).toInt()}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AttributeRadarChart.attributeColors[index],
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _HexagonGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width * 0.4;

    final linePaint = Paint()
      ..color = EmergeColors.hexLine.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw concentric hexagons
    for (int ring = 1; ring <= 4; ring++) {
      final radius = maxRadius * (ring / 4);
      _drawHexagon(canvas, center, radius, linePaint);
    }

    // Draw lines from center to vertices
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 - 90) * (math.pi / 180);
      final endX = center.dx + math.cos(angle) * maxRadius;
      final endY = center.dy + math.sin(angle) * maxRadius;
      canvas.drawLine(center, Offset(endX, endY), linePaint);
    }
  }

  void _drawHexagon(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 - 90) * (math.pi / 180);
      final x = center.dx + math.cos(angle) * radius;
      final y = center.dy + math.sin(angle) * radius;
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

class _AttributeAreaPainter extends CustomPainter {
  final Map<String, double> attributes;
  final List<String> attributeNames;
  final double fillProgress;

  _AttributeAreaPainter({
    required this.attributes,
    required this.attributeNames,
    this.fillProgress = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width * 0.4;

    final fillPaint = Paint()
      ..color = EmergeColors.teal.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = EmergeColors.teal
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    for (int i = 0; i < 6; i++) {
      final name = attributeNames[i];
      final value = (attributes[name] ?? 0.0).clamp(0.0, 1.0);
      final angle = (i * 60 - 90) * (math.pi / 180);
      final radius = maxRadius * value * fillProgress;
      final x = center.dx + math.cos(angle) * radius;
      final y = center.dy + math.sin(angle) * radius;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);

    // Draw vertex points
    final pointPaint = Paint()
      ..color = EmergeColors.teal
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 6; i++) {
      final name = attributeNames[i];
      final value = (attributes[name] ?? 0.0).clamp(0.0, 1.0);
      final angle = (i * 60 - 90) * (math.pi / 180);
      final radius = maxRadius * value * fillProgress;
      final x = center.dx + math.cos(angle) * radius;
      final y = center.dy + math.sin(angle) * radius;

      canvas.drawCircle(Offset(x, y), 4, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _AttributeAreaPainter oldDelegate) {
    return oldDelegate.fillProgress != fillProgress ||
        oldDelegate.attributes != attributes;
  }
}
