import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';

/// Sweatcoin-inspired Club card with cover image, logo, member count, and XP.
class ClubCard extends StatelessWidget {
  final String id;
  final String name;
  final String? description;
  final String? coverImageUrl;
  final String? logoUrl;
  final int memberCount;
  final int totalXp;
  final bool isVerified;
  final bool isJoined;
  final VoidCallback? onTap;
  final VoidCallback? onJoin;

  const ClubCard({
    super.key,
    required this.id,
    required this.name,
    this.description,
    this.coverImageUrl,
    this.logoUrl,
    this.memberCount = 0,
    this.totalXp = 0,
    this.isVerified = false,
    this.isJoined = false,
    this.onTap,
    this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180,
        constraints: const BoxConstraints(
          minHeight: 190, // Ensure content fits without overflow
        ),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Allow flexible height
          children: [
            // Cover Image with Logo
            SizedBox(
              height: 70, // Reduced from 80 to prevent overflow
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: Container(
                      height: 70,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primary.withValues(alpha: 0.2),
                            AppTheme.secondary.withValues(alpha: 0.2),
                          ],
                        ),
                      ),
                      child: coverImageUrl != null
                          ? Image.network(
                              coverImageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const SizedBox.shrink(),
                            )
                          : null,
                    ),
                  ),
                  // Logo
                  Positioned(
                    bottom: -18, // Adjusted for smaller cover
                    left: 12,
                    child: Container(
                      width: 40, // Slightly smaller
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundDark,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.surfaceDark, width: 3),
                      ),
                      child: logoUrl != null
                          ? ClipOval(
                              child: Image.network(
                                logoUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _defaultLogo(),
                              ),
                            )
                          : _defaultLogo(),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 24, 12, 10), // Reduced padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textMainDark,
                                fontSize: 13, // Slightly smaller
                              ),
                        ),
                      ),
                      if (isVerified) ...[
                        const Gap(3),
                        Icon(Icons.verified, size: 12, color: AppTheme.primary),
                      ],
                    ],
                  ),
                  const Gap(6), // Reduced gap
                  Row(
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 12,
                        color: AppTheme.textSecondaryDark,
                      ),
                      const Gap(3),
                      Text(
                        _formatNumber(memberCount),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondaryDark,
                          fontSize: 11,
                        ),
                      ),
                      const Gap(10),
                      Icon(Icons.bolt, size: 12, color: AppTheme.primary),
                      const Gap(2),
                      Text(
                        '${_formatNumber(totalXp)} XP',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.primary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const Gap(8), // Reduced gap
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: isJoined ? null : onJoin,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isJoined
                            ? Colors.grey
                            : AppTheme.primary,
                        side: BorderSide(
                          color: isJoined ? Colors.grey : AppTheme.primary,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 5), // Reduced padding
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        isJoined ? 'Joined' : 'Join',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95));
  }

  Widget _defaultLogo() {
    return Center(
      child: Icon(
        Icons.groups,
        size: 24,
        color: AppTheme.primary.withValues(alpha: 0.5),
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}
