import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Calculates the positions for nodes arranged in a ring layout.
List<Offset> calculateRingNodePositions({
  required Size size,
  required double radius,
  required int nodeCount,
}) {
  final angleStep = (2 * math.pi) / nodeCount;
  final center = Offset(size.width / 2, size.height / 2);
  
  return List.generate(nodeCount, (index) {
    // Start at top (-pi/2) and go clockwise
    final angle = -math.pi / 2 + (index * angleStep);
    return Offset(
      center.dx + (radius * math.cos(angle)),
      center.dy + (radius * math.sin(angle)),
    );
  });
}
