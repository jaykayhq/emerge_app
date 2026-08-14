import 'dart:ui';

/// Resolved position for the guide card. Exactly one of [top]/[bottom] is
/// non-null so it can be passed straight to a `Positioned` widget.
typedef GuideCardPosition = ({double? top, double? bottom});

/// Chooses where the first-visit guide card goes so it never covers the
/// spotlighted target when there is room elsewhere:
///  1. above the target if that space fits;
///  2. else below the target if that space fits;
///  3. else pinned to the bottom (current behavior).
GuideCardPosition guideCardPositionFor({
  required Rect? targetRect,
  required Size screenSize,
  required double cardHeight,
  required double margin,
  required double topInset,
  required double bottomInset,
}) {
  const fallback = 24.0;
  final viewport = Offset.zero & screenSize;
  if (targetRect == null || !viewport.overlaps(targetRect)) {
    return (top: null, bottom: fallback + bottomInset);
  }

  final spaceAbove = targetRect.top - topInset;
  final spaceBelow = screenSize.height - bottomInset - targetRect.bottom;

  if (spaceAbove >= cardHeight + margin) {
    return (top: targetRect.top - cardHeight - margin, bottom: null);
  }
  if (spaceBelow >= cardHeight + margin) {
    return (top: targetRect.bottom + margin, bottom: null);
  }
  return (top: null, bottom: fallback + bottomInset);
}
