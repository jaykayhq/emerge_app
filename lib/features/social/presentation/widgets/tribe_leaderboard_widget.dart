import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_loading_skeleton.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';
import 'package:emerge_app/features/social/presentation/widgets/glass_panel.dart';

class TribeLeaderboardSection extends ConsumerStatefulWidget {
  const TribeLeaderboardSection({super.key});

  @override
  ConsumerState<TribeLeaderboardSection> createState() => _TribeLeaderboardSectionState();
}

class _TribeLeaderboardSectionState extends ConsumerState<TribeLeaderboardSection> {
  int _timeScope = 0;

  static const _timeLabels = ['Weekly', 'Monthly', 'All-time'];

  @override
  Widget build(BuildContext context) {
    final leaderboardAsync = ref.watch(worldLeaderboardProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'ELITE RANKINGS',
              style: TextStyle(
                color: EmergeColors.nebulaPrimary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            GestureDetector(
              onTap: () => context.push('/social/leaderboard'),
              child: const Text(
                'Full Board →',
                style: TextStyle(color: EmergeColors.nebulaSecondary, fontSize: 12),
              ),
            ),
          ],
        ),
        const Gap(16),
        SegmentedButton<int>(
          selected: {_timeScope},
          onSelectionChanged: (s) => setState(() => _timeScope = s.first),
          showSelectedIcon: false,
          style: SegmentedButton.styleFrom(
            selectedBackgroundColor: EmergeColors.nebulaSecondary.withValues(alpha: 0.2),
            selectedForegroundColor: EmergeColors.nebulaSecondary,
            side: BorderSide(color: EmergeColors.nebulaPrimaryContainer.withValues(alpha: 0.3)),
          ),
          segments: List.generate(
            _timeLabels.length,
            (i) => ButtonSegment(value: i, label: Text(_timeLabels[i], style: const TextStyle(fontSize: 12))),
          ),
        ),
        const Gap(24),
        leaderboardAsync.when(
          data: (entries) {
            if (entries.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text('No rankings yet', style: TextStyle(color: Colors.white38)),
                ),
              );
            }

            final display = entries;
            final top3 = display.take(3).toList();
            final rest = display.skip(3).toList();
            final maxXp = display.isNotEmpty ? display.first.stats.totalXp.toDouble() : 1.0;

            return Column(
              children: [
                if (top3.isNotEmpty) _PodiumLayout(top3: top3, maxXp: maxXp),
                const Gap(24),
                ...rest.asMap().entries.map((entry) {
                  final i = entry.key;
                  final e = entry.value;
                  final rank = i + 4;
                  final barFraction = (e.stats.totalXp / maxXp).clamp(0.0, 1.0);
                  return _LeaderboardRow(
                    rank: rank,
                    name: e.tribe.name,
                    xp: e.stats.totalXp,
                    barFraction: barFraction,
                    isTop3: false,
                  );
                }),
                const Gap(8),
                const _YouPinnedRow(),
              ],
            );
          },
          loading: () => const EmergeLoadingSkeleton(itemCount: 5),
          error: (e, _) => const Center(child: Text('Could not load leaderboard', style: TextStyle(color: Colors.white38))),
        ),
      ],
    );
  }
}

class _PodiumLayout extends StatelessWidget {
  final List<dynamic> top3;
  final double maxXp;

  const _PodiumLayout({required this.top3, required this.maxXp});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (top3.length > 1)
          Expanded(child: _PodiumColumn(rank: 2, entry: top3[1], height: 120, color: Colors.blueGrey.shade300)),
        const Gap(12),
        if (top3.isNotEmpty)
          Expanded(child: _PodiumColumn(rank: 1, entry: top3[0], height: 160, color: Colors.amber)),
        const Gap(12),
        if (top3.length > 2)
          Expanded(child: _PodiumColumn(rank: 3, entry: top3[2], height: 100, color: Colors.brown.shade300)),
      ],
    );
  }
}

class _PodiumColumn extends StatelessWidget {
  final int rank;
  final dynamic entry;
  final double height;
  final Color color;

  const _PodiumColumn({
    required this.rank,
    required this.entry,
    required this.height,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          entry.tribe.name,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
          overflow: TextOverflow.ellipsis,
        ),
        const Gap(8),
        Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                color.withValues(alpha: 0.8),
                color.withValues(alpha: 0.2),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            border: Border.all(color: color.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, -10),
              )
            ]
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '#$rank',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white),
              ),
              const Gap(8),
              Text(
                '${(entry.stats.totalXp / 1000).toStringAsFixed(1)}k',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final int rank;
  final String name;
  final int xp;
  final double barFraction;
  final bool isTop3;

  const _LeaderboardRow({
    required this.rank,
    required this.name,
    required this.xp,
    required this.barFraction,
    required this.isTop3,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassPanel(
        level: GlassLevel.level1,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 30,
              child: Text(
                '#$rank',
                style: const TextStyle(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.bold),
              ),
            ),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(color: Colors.white, fontSize: 14), overflow: TextOverflow.ellipsis),
                  const Gap(6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: barFraction,
                      backgroundColor: Colors.white10,
                      color: EmergeColors.nebulaSecondary,
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            ),
            const Gap(16),
            Text('${(xp / 1000).toStringAsFixed(1)}K XP', style: TextStyle(color: EmergeColors.nebulaSecondary, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _YouPinnedRow extends StatelessWidget {
  const _YouPinnedRow();

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      level: GlassLevel.level2,
      isElectric: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: const Row(
        children: [
          SizedBox(width: 30, child: Text('📍', style: TextStyle(fontSize: 16))),
          Gap(12),
          Expanded(child: Text('Your Tribe', style: TextStyle(color: EmergeColors.nebulaPrimary, fontWeight: FontWeight.bold, fontSize: 14))),
          Text('Check in to rank up 🔥', style: TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}