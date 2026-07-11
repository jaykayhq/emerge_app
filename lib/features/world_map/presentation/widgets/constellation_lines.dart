import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ConstellationLines extends StatelessWidget {
  final Offset center;
  final List<Offset> nodePositions;

  const ConstellationLines({
    super.key,
    required this.center,
    required this.nodePositions,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ConstellationPainter(
        center: center,
        nodePositions: nodePositions,
      ),
      size: Size.infinite,
    );
  }
}

class _ConstellationPainter extends CustomPainter {
  final Offset center;
  final List<Offset> nodePositions;

  _ConstellationPainter({
    required this.center,
    required this.nodePositions,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..strokeWidth = 2.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);

    for (var node in nodePositions) {
      canvas.drawLine(center, node, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConstellationPainter oldDelegate) {
    return oldDelegate.center != center ||
        !listEquals(oldDelegate.nodePositions, nodePositions);
  }
}
