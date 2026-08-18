// lib/core/presentation/widgets/shareable/shareable_card.dart
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:emerge_app/core/presentation/widgets/animated_flame_logo.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/core/presentation/widgets/shareable/shareable_card_data.dart';

/// Branded 9:16 share card. Rendered inside a [RepaintBoundary] by
/// [ShareableImageExporter] for export, or shown as a live preview.
///
/// Uses a STATIC flame mark (FlamePainter at fixed flicker) instead of
/// [AnimatedFlameLogo] — repeating animations would make the export frame
/// unstable and prevent tests from settling.
class ShareableCard extends StatelessWidget {
  final ShareableCardData data;

  const ShareableCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            EmergeColors.cosmicVoidDark,
            EmergeColors.cosmicVoidCenter,
            EmergeColors.cosmicBlue,
          ],
        ),
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand mark
          const _FlameMark(size: 48),
          const Spacer(),
          // Headline
          Text(
            data.headline,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              height: 1.1,
            ),
          ),
          if (data.subheadline != null) ...[
            const Gap(8),
            Text(
              data.subheadline!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white60, fontSize: 16),
            ),
          ],
          const Gap(24),
          // Stats
          for (final stat in data.stats) _StatRow(stat: stat),
          const Spacer(),
          // Footer
          if (data.footer != null)
            Text(
              data.footer!,
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
          const Gap(12),
          const Text(
            'EMERGE',
            style: TextStyle(
              color: Colors.white24,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 4,
            ),
          ),
        ],
      ),
    );
  }
}

class _FlameMark extends StatelessWidget {
  final double size;
  const _FlameMark({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          CustomPaint(
            size: Size(size, size * 0.95),
            painter: FlamePainter(
              color: const Color(0xFF9D4EDD).withValues(alpha: 0.9),
              flicker: 0.0,
            ),
          ),
          CustomPaint(
            size: Size(size * 0.75, size * 0.70),
            painter: FlamePainter(color: EmergeColors.neonTeal, flicker: 0.33),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final ShareableStat stat;
  const _StatRow({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: stat.color.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(
              stat.icon ?? Icons.star_rounded,
              color: stat.color,
              size: 22,
            ),
          ),
          const Gap(16),
          Expanded(
            child: Text(
              stat.label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                letterSpacing: 1,
              ),
            ),
          ),
          Flexible(
            child: Text(
              stat.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: stat.color,
                fontSize: 30,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
