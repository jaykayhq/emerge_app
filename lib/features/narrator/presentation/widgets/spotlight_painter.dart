import 'package:flutter/material.dart';

/// Dims the whole screen except a rounded-rect "spotlight hole" around the
/// section a narrator guide step explains. No hole → full dim (card-only
/// step). The hole rect must be in the same coordinate space as the painter
/// (global/screen space — `RenderBox.localToGlobal`).
class SpotlightPainter extends CustomPainter {
  final Rect? holeRect;
  final double cornerRadius;
  final Color scrimColor;

  const SpotlightPainter({
    this.holeRect,
    this.cornerRadius = 16,
    this.scrimColor = const Color(0x99000000),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    final hole = holeRect;
    final hasHole = hole != null && !hole.isEmpty && bounds.overlaps(hole);
    var path = Path()..addRect(bounds);
    if (hasHole) {
      final holePath = Path()
        ..addRRect(
          RRect.fromRectAndRadius(hole, Radius.circular(cornerRadius)),
        );
      path = Path.combine(PathOperation.difference, path, holePath);
    }
    canvas.drawPath(path, Paint()..color = scrimColor);
    if (hasHole) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          hole.inflate(2),
          Radius.circular(cornerRadius + 2),
        ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.white.withValues(alpha: 0.35),
      );
    }
  }

  @override
  bool shouldRepaint(SpotlightPainter oldDelegate) =>
      oldDelegate.holeRect != holeRect ||
      oldDelegate.cornerRadius != cornerRadius ||
      oldDelegate.scrimColor != scrimColor;
}
