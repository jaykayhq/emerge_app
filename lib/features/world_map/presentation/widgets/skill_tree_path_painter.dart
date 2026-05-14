import 'package:flutter/material.dart';

/// Paints the winding path connecting skill nodes
/// Uses Quadratic Bezier curves for smooth transitions
class SkillTreePathPainter extends CustomPainter {
  final List<Offset> nodePositions;
  final Color color;
  final double progress; // 0.0 to 1.0 (animation state)

  SkillTreePathPainter({
    required this.nodePositions,
    required this.color,
    this.progress = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (nodePositions.length < 2) return;

    final paint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12.0
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(nodePositions[0].dx, nodePositions[0].dy);

    for (int i = 0; i < nodePositions.length - 1; i++) {
      final p1 = nodePositions[i];
      final p2 = nodePositions[i + 1];

      // Calculate control points for S-curve
      // If we are zigzagging (x changes direction), we need a control point in the middle
      final controlX = (p1.dx + p2.dx) / 2;
      final controlY = (p1.dy + p2.dy) / 2;

      // Add some curvature variance based on index
      final curveOffset = (i % 2 == 0) ? 40.0 : -40.0;

      path.quadraticBezierTo(controlX + curveOffset, controlY, p2.dx, p2.dy);
    }

    // Draw background path (faded)
    canvas.drawPath(path, paint);

    // Draw animated progress path (filled)
    if (progress > 0) {
      final activePaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12.0
        ..strokeCap = StrokeCap.round
        // Gradient shader for "flow" effect
        ..shader = LinearGradient(
          colors: [color.withValues(alpha: 0.5), color],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

      // Extract path for animation
      final metrics = path.computeMetrics();
      for (final metric in metrics) {
        final length = metric.length;
        final extractLength = length * progress;
        final extractedPath = metric.extractPath(0, extractLength);
        canvas.drawPath(extractedPath, activePaint);
      }
    }

    // Draw "dots" along the path for extra texture
    _drawPathDots(canvas, path, color);
  }

  void _drawPathDots(Canvas canvas, Path path, Color color) {
    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    // Use path metrics to place dots
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      final length = metric.length;
      final dotSpacing = 30.0;

      for (double d = 0; d < length; d += dotSpacing) {
        final pos = metric.getTangentForOffset(d)?.position;
        if (pos != null) {
          canvas.drawCircle(pos, 3, dotPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant SkillTreePathPainter oldDelegate) {
    return oldDelegate.nodePositions != nodePositions ||
        oldDelegate.color != color ||
        oldDelegate.progress != progress;
  }
}
