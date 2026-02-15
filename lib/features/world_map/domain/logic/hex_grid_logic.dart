import 'dart:math';
import 'package:flutter/material.dart';
import 'package:emerge_app/features/world_map/domain/models/hex_location.dart';

/// Layout helpers for Pointy-Topped Hexagons
class HexLayout {
  final double size; // radius from center to corner
  final HexOrientation orientation;

  const HexLayout({
    required this.size,
    this.orientation = HexOrientation.pointy,
  });

  /// Convert Hex to Pixel (Center of hex)
  Offset hexToPixel(HexLocation h) {
    // Pointy-Topped
    // x = size * (sqrt(3) * q  +  sqrt(3)/2 * r)
    // y = size * (0 * q  +  3/2 * r)
    final x = size * (sqrt(3) * h.q + sqrt(3) / 2 * h.r);
    final y = size * (3.0 / 2 * h.r);
    return Offset(x, y);
  }

  /// Convert Pixel to Hex (Rounding required)
  HexLocation pixelToHex(Offset p) {
    // Pointy-Topped Inverse
    final q = (sqrt(3) / 3 * p.dx - 1 / 3 * p.dy) / size;
    final r = (2 / 3 * p.dy) / size;
    return _hexRound(q, r);
  }

  HexLocation _hexRound(double fracQ, double fracR) {
    double fracS = -fracQ - fracR;
    int q = fracQ.round();
    int r = fracR.round();
    int s = fracS.round();

    double qDiff = (q - fracQ).abs();
    double rDiff = (r - fracR).abs();
    double sDiff = (s - fracS).abs();

    if (qDiff > rDiff && qDiff > sDiff) {
      q = -r - s;
    } else if (rDiff > sDiff) {
      r = -q - s;
    }
    // s is not stored, so no update needed
    return HexLocation(q, r);
  }
}

enum HexOrientation { pointy, flat }
