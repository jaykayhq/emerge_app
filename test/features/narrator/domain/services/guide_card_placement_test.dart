import 'package:emerge_app/features/narrator/domain/services/guide_card_placement.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const cardHeight = 140.0;
  const margin = 16.0;

  test('no target -> pinned to the bottom like today', () {
    final pos = guideCardPositionFor(
      targetRect: null,
      screenSize: const Size(400, 800),
      cardHeight: cardHeight,
      margin: margin,
      topInset: 0,
      bottomInset: 24,
    );
    expect(pos.top, isNull);
    expect(pos.bottom, 48); // 24 fallback + 24 bottomInset
  });

  test('target near the bottom -> card sits above it', () {
    final pos = guideCardPositionFor(
      targetRect: const Rect.fromLTWH(100, 640, 200, 50),
      screenSize: const Size(400, 800),
      cardHeight: cardHeight,
      margin: margin,
      topInset: 0,
      bottomInset: 24,
    );
    // spaceAbove = 640 >= 156 -> above: top = 640 - 140 - 16.
    expect(pos.top, 484);
    expect(pos.bottom, isNull);
  });

  test('target near the top -> card sits below it', () {
    final pos = guideCardPositionFor(
      targetRect: const Rect.fromLTWH(100, 100, 200, 50),
      screenSize: const Size(400, 800),
      cardHeight: cardHeight,
      margin: margin,
      topInset: 0,
      bottomInset: 24,
    );
    // spaceAbove = 100 < 156; spaceBelow = 800 - 24 - 150 = 626 >= 156.
    expect(pos.top, 166); // target.bottom + margin
    expect(pos.bottom, isNull);
  });

  test('full-screen target -> falls back to bottom pinned', () {
    final pos = guideCardPositionFor(
      targetRect: const Rect.fromLTWH(0, 0, 400, 800),
      screenSize: const Size(400, 800),
      cardHeight: cardHeight,
      margin: margin,
      topInset: 0,
      bottomInset: 24,
    );
    expect(pos.top, isNull);
    expect(pos.bottom, 48);
  });
}
