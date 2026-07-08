import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/features/pulse_feed/domain/models/pulse_feed_card.dart';

/// A glassmorphism card that renders a single [PulseFeedCard].
///
/// Shows a type badge with a distinct colour, a headline, optional subtext,
/// and a relative "Xm ago" timestamp.
class PulseCardWidget extends ConsumerWidget {
  final PulseFeedCard card;

  const PulseCardWidget({super.key, required this.card});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typeColor = _typeColor(card.type);
    final typeLabel = _typeLabel(card.type);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: typeColor.withValues(alpha: 0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: typeColor.withValues(alpha: 0.08),
            blurRadius: 12,
            spreadRadius: -2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type badge (left)
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Icon(
                      _typeIcon(card.type),
                      color: typeColor,
                      size: 20,
                    ),
                  ),
                ),
                const Gap(12),
                // Body
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Type label + timestamp row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: typeColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              typeLabel,
                              style: TextStyle(
                                color: typeColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _formatTimeAgo(card.createdAt),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const Gap(8),
                      // Headline
                      Text(
                        card.headline,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                      // Subtext
                      if (card.subtext != null && card.subtext!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            card.subtext!,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 13,
                              height: 1.3,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static Color _typeColor(PulseFeedCardType type) => switch (type) {
        PulseFeedCardType.identityVote => EmergeColors.neonTeal,
        PulseFeedCardType.tribeActivity => const Color(0xFFFFB74D), // Amber
        PulseFeedCardType.weeklyInsight => EmergeColors.nebulaSecondary,
      };

  static IconData _typeIcon(PulseFeedCardType type) => switch (type) {
        PulseFeedCardType.identityVote => Icons.favorite_outline_rounded,
        PulseFeedCardType.tribeActivity => Icons.groups_rounded,
        PulseFeedCardType.weeklyInsight => Icons.auto_awesome_rounded,
      };

  static String _typeLabel(PulseFeedCardType type) => switch (type) {
        PulseFeedCardType.identityVote => 'IDENTITY VOTE',
        PulseFeedCardType.tribeActivity => 'TRIBE',
        PulseFeedCardType.weeklyInsight => 'INSIGHT',
      };

  /// Returns a human-readable relative timestamp like "5m ago", "3h ago",
  /// "2d ago".
  static String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${diff.inDays ~/ 7}w ago';
  }
}
