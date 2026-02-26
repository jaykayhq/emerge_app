import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';

/// Sweatcoin-inspired rich challenge card with cover image, rewards, and prizes.
class ChallengeCard extends StatelessWidget {
  final String id;
  final String title;
  final String description;
  final String? coverImageUrl;
  final String? sponsorLogoUrl;
  final String? sponsorName;
  final int xpReward;
  final int daysRemaining;
  final String? prizeDescription;
  final bool isJoined;
  final VoidCallback? onJoin;
  final VoidCallback? onTap;

  // New affiliate fields
  final bool isSponsored;
  final String? rewardDescription;
  final String? category;
  final String? affiliatePartnerId;

  const ChallengeCard({
    super.key,
    required this.id,
    required this.title,
    required this.description,
    this.coverImageUrl,
    this.sponsorLogoUrl,
    this.sponsorName,
    this.xpReward = 50,
    this.daysRemaining = 7,
    this.prizeDescription,
    this.isJoined = false,
    this.onJoin,
    this.onTap,
    // New affiliate fields with defaults
    this.isSponsored = false,
    this.rewardDescription,
    this.category,
    this.affiliatePartnerId,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: Stack(
                children: [
                  Container(
                    height: 140,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.primary.withValues(alpha: 0.3),
                          AppTheme.secondary.withValues(alpha: 0.3),
                        ],
                      ),
                    ),
                    child: coverImageUrl != null
                        ? Image.network(
                            coverImageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _defaultCover(),
                          )
                        : _defaultCover(),
                  ),
                  // XP Badge
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.bolt, size: 14, color: Colors.black),
                          const Gap(4),
                          Text(
                            '+$xpReward XP',
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Top-right badges (Sponsored and/or Sponsor)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Sponsored Badge
                        if (isSponsored)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.amber.shade700,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star,
                                  size: 12,
                                  color: Colors.black87,
                                ),
                                const Gap(4),
                                const Text(
                                  'Sponsored',
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        // Sponsor Name (if different from sponsored badge)
                        if (sponsorName != null && !isSponsored)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              sponsorName!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Category Tag (bottom of image)
                  if (category != null && category != 'all')
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.secondary.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _formatCategory(category!),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textMainDark,
                    ),
                  ),
                  const Gap(4),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondaryDark,
                    ),
                  ),
                  const Gap(16),

                  // Prize Row
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _PrizeChip(
                        icon: Icons.bolt,
                        label: '+$xpReward XP',
                        color: AppTheme.primary,
                      ),
                      _PrizeChip(
                        icon: Icons.timer_outlined,
                        label: '$daysRemaining days',
                        color: AppTheme.secondary,
                      ),
                      if (rewardDescription != null)
                        _PrizeChip(
                          icon: Icons.card_giftcard,
                          label: '🎁 ${rewardDescription!}',
                          color: Colors.amber,
                        ),
                      if (prizeDescription != null && rewardDescription == null)
                        _PrizeChip(
                          icon: Icons.card_giftcard,
                          label: prizeDescription!,
                          color: Colors.amber,
                        ),
                    ],
                  ),
                  const Gap(16),

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isJoined ? null : onJoin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isJoined
                            ? Colors.grey
                            : AppTheme.primary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        isJoined ? 'Joined' : 'Join Challenge',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }

  Widget _defaultCover() {
    return Center(
      child: Icon(
        Icons.emoji_events,
        size: 48,
        color: AppTheme.primary.withValues(alpha: 0.5),
      ),
    );
  }

  String _formatCategory(String category) {
    // Convert 'fitness' -> 'Fitness', 'mindfulness' -> 'Mindfulness', etc.
    return category[0].toUpperCase() + category.substring(1);
  }
}

class _PrizeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _PrizeChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const Gap(4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
