import 'dart:ui';
import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
import 'package:flutter/material.dart';

/// Sticky bottom Identity Votes counter
/// "Identity Votes: 5/8" with glassmorphism styling
class IdentityVotesCounter extends StatelessWidget {
  final int completed;
  final int total;

  const IdentityVotesCounter({
    super.key,
    required this.completed,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? completed / total : 0.0;

    return Container(
      margin: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.15),
                  Colors.white.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: EmergeColors.teal.withValues(alpha: 0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: EmergeColors.teal.withValues(alpha: 0.2),
                  blurRadius: 20,
                  spreadRadius: -5,
                ),
              ],
            ),
            child: Row(
              children: [
                // Progress indicator
                _buildProgressArc(progress),
                const SizedBox(width: 16),
                // Text info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              'Identity Votes',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: AppTheme.textMainDark,
                                    fontWeight: FontWeight.w600,
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: EmergeColors.teal.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: EmergeColors.teal.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              '$completed/$total',
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    color: EmergeColors.teal,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Becoming your ideal self',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondaryDark,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                // Decorative icon
                Icon(
                  Icons.how_to_vote,
                  color: EmergeColors.teal.withValues(alpha: 0.6),
                  size: 28,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressArc(double progress) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glow
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: EmergeColors.teal.withValues(alpha: 0.4),
                  blurRadius: 12,
                  spreadRadius: -2,
                ),
              ],
            ),
          ),
          // Ring
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 4,
              backgroundColor: EmergeColors.teal.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation(EmergeColors.teal),
            ),
          ),
          // Icon
          Icon(Icons.star, color: EmergeColors.teal, size: 18),
        ],
      ),
    );
  }
}
