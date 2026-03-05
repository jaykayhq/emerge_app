import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/features/gamification/domain/entities/reward_catalog.dart';
import 'package:emerge_app/features/gamification/domain/entities/reward_item.dart';
import 'package:emerge_app/features/gamification/presentation/widgets/nameplate_renderer.dart';
import 'package:emerge_app/features/monetization/presentation/providers/subscription_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

/// The Bazaar — Shop Screen for purchasing premium rewards (IAP).
class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  bool _purchasing = false;

  @override
  Widget build(BuildContext context) {
    final premiumTitles = RewardCatalog.purchasable
        .where((r) => r.type == RewardType.title)
        .toList();
    final premiumNameplates = RewardCatalog.purchasable
        .where((r) => r.type == RewardType.nameplate)
        .toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Stack(
        children: [
          // Background shimmer
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF1A0A2E),
                    AppTheme.backgroundDark,
                    const Color(0xFF0A0A15),
                  ],
                ),
              ),
            ),
          ),

          // Content
          CustomScrollView(
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'The Bazaar',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Premium Collectibles',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.diamond,
                                size: 14,
                                color: Colors.black87,
                              ),
                              Gap(4),
                              Text(
                                'PREMIUM',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                  letterSpacing: 0.5,
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

              // Premium Banner
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1A0A2E), Color(0xFF2D0B3D)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: EmergeColors.yellow.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: EmergeColors.yellow.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.storefront,
                            color: EmergeColors.yellow,
                            size: 24,
                          ),
                        ),
                        const Gap(12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Exclusive Collectibles',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Legendary titles & nameplates that set you apart.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms),
                ),
              ),

              // Legendary Titles Section
              _buildSectionHeader('Legendary Titles', Icons.military_tech),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: premiumTitles
                        .map(
                          (r) => _ShopItemCard(
                            reward: r,
                            onPurchase: () => _handlePurchase(r),
                            isPurchasing: _purchasing,
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: Gap(24)),

              // Legendary Nameplates Section
              _buildSectionHeader(
                'Legendary Nameplates',
                Icons.card_membership,
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: premiumNameplates
                        .map(
                          (r) => _ShopNameplateCard(
                            reward: r,
                            onPurchase: () => _handlePurchase(r),
                            isPurchasing: _purchasing,
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: Gap(80)),
            ],
          ),
        ],
      ),
    );
  }

  SliverToBoxAdapter _buildSectionHeader(String title, IconData icon) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
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

  Future<void> _handlePurchase(RewardItem reward) async {
    if (_purchasing || reward.iapProductId == null) return;

    setState(() => _purchasing = true);

    final repo = ref.read(monetizationRepositoryProvider);
    final result = await repo.purchaseConsumable(reward.iapProductId!);

    if (mounted) {
      setState(() => _purchasing = false);

      result.fold(
        (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: EmergeColors.coral),
          );
        },
        (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${reward.name} unlocked! ✨'),
              backgroundColor: EmergeColors.teal,
            ),
          );
        },
      );
    }
  }
}

class _ShopItemCard extends StatelessWidget {
  final RewardItem reward;
  final VoidCallback onPurchase;
  final bool isPurchasing;

  const _ShopItemCard({
    required this.reward,
    required this.onPurchase,
    required this.isPurchasing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: EmergeColors.glassWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: EmergeColors.yellow.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: EmergeColors.yellow.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(
                Icons.format_quote,
                color: EmergeColors.yellow,
                size: 20,
              ),
            ),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reward.displayValue.trim(),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: EmergeColors.yellow,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const Gap(2),
                Text(
                  reward.description,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          const Gap(8),
          GestureDetector(
            onTap: isPurchasing ? null : onPurchase,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: isPurchasing
                    ? null
                    : const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
                      ),
                color: isPurchasing
                    ? Colors.white.withValues(alpha: 0.1)
                    : null,
                borderRadius: BorderRadius.circular(20),
              ),
              child: isPurchasing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white54,
                      ),
                    )
                  : const Text(
                      'BUY',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn();
  }
}

class _ShopNameplateCard extends StatelessWidget {
  final RewardItem reward;
  final VoidCallback onPurchase;
  final bool isPurchasing;

  const _ShopNameplateCard({
    required this.reward,
    required this.onPurchase,
    required this.isPurchasing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: NameplateRenderer(
        nameplateKey: reward.displayValue,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reward.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Gap(2),
                  Text(
                    reward.description,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            const Gap(8),
            GestureDetector(
              onTap: isPurchasing ? null : onPurchase,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: isPurchasing
                      ? null
                      : const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
                        ),
                  color: isPurchasing
                      ? Colors.white.withValues(alpha: 0.1)
                      : null,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: isPurchasing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white54,
                        ),
                      )
                    : const Text(
                        'BUY',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn();
  }
}
