// lib/core/presentation/widgets/shareable/shareable_card_data.dart
import 'package:flutter/material.dart';

/// One stat row rendered on a [ShareableCard].
class ShareableStat {
  final String label;
  final String value;
  final Color color;
  final IconData? icon;

  const ShareableStat({
    required this.label,
    required this.value,
    required this.color,
    this.icon,
  });
}

/// Pure data for the branded 9:16 share card. No Flutter rendering here —
/// unit-testable without a widget tree.
class ShareableCardData {
  final String headline;
  final String? subheadline;
  final List<ShareableStat> stats;
  final String? footer;

  const ShareableCardData({
    required this.headline,
    this.subheadline,
    this.stats = const [],
    this.footer,
  });
}
