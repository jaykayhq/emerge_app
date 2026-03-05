import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/features/gamification/domain/entities/reward_item.dart';
import 'package:emerge_app/features/gamification/presentation/providers/reward_providers.dart';
import 'package:emerge_app/features/gamification/presentation/widgets/nameplate_renderer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

/// Reward Showcase Screen — "The Trophy Room"
/// Displays all titles, nameplates, and emblems grouped by rarity.
class RewardShowcaseScreen extends ConsumerWidget {
  const RewardShowcaseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rewardsByType = ref.watch(rewardsByTypeProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: EmergeColors.glassWhite,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                    const Gap(12),
                    const Text(
                      'Trophy Room',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.emoji_events,
                      color: EmergeColors.yellow,
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Titles Section
          _buildSectionHeader('Titles & Epithets', Icons.badge),
          _buildRewardGrid(rewardsByType[RewardType.title] ?? []),

          // Nameplates Section
          _buildSectionHeader('Nameplates', Icons.card_membership),
          _buildNameplateGrid(rewardsByType[RewardType.nameplate] ?? []),

          // Emblems Section
          _buildSectionHeader('Emblems', Icons.shield),
          _buildRewardGrid(rewardsByType[RewardType.emblem] ?? []),

          const SliverToBoxAdapter(child: Gap(80)),
        ],
      ),
    );
  }

  SliverToBoxAdapter _buildSectionHeader(String title, IconData icon) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
        child: Row(
          children: [
            Icon(icon, size: 18, color: EmergeColors.yellow),
            const Gap(8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildRewardGrid(List<RewardItem> rewards) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: rewards.map((r) => _RewardChip(reward: r)).toList(),
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildNameplateGrid(List<RewardItem> rewards) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: rewards.map((r) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: NameplateRenderer(
                nameplateKey: r.displayValue,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            r.description,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _RarityBadge(rarity: r.rarity),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _RewardChip extends StatelessWidget {
  final RewardItem reward;
  const _RewardChip({required this.reward});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: EmergeColors.glassWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _rarityBorderColor()),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (reward.type == RewardType.emblem)
            Text(reward.displayValue, style: const TextStyle(fontSize: 16))
          else
            Icon(
              reward.type == RewardType.title
                  ? Icons.format_quote
                  : Icons.card_membership,
              size: 14,
              color: _rarityColor(),
            ),
          const Gap(6),
          Text(
            reward.name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _rarityColor(),
            ),
          ),
          if (reward.source == RewardSource.purchase) ...[
            const Gap(4),
            Icon(
              Icons.diamond,
              size: 12,
              color: EmergeColors.yellow.withValues(alpha: 0.8),
            ),
          ],
        ],
      ),
    ).animate().fadeIn();
  }

  Color _rarityColor() {
    switch (reward.rarity) {
      case RewardRarity.common:
        return Colors.white70;
      case RewardRarity.rare:
        return const Color(0xFF4FC3F7);
      case RewardRarity.epic:
        return const Color(0xFFAB47BC);
      case RewardRarity.legendary:
        return EmergeColors.yellow;
    }
  }

  Color _rarityBorderColor() {
    return _rarityColor().withValues(alpha: 0.3);
  }
}

class _RarityBadge extends StatelessWidget {
  final RewardRarity rarity;
  const _RarityBadge({required this.rarity});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color().withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        rarity.name.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: _color(),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Color _color() {
    switch (rarity) {
      case RewardRarity.common:
        return Colors.white70;
      case RewardRarity.rare:
        return const Color(0xFF4FC3F7);
      case RewardRarity.epic:
        return const Color(0xFFAB47BC);
      case RewardRarity.legendary:
        return EmergeColors.yellow;
    }
  }
}
