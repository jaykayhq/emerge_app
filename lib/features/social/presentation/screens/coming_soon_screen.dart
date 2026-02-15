import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Coming Soon screen for features not yet available
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EmergeColors.background,
      body: Stack(
        children: [
          const Positioned.fill(child: HexMeshBackground()),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 32.0),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icon container
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: EmergeColors.teal.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: EmergeColors.teal.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.construction,
                          size: 60,
                          color: EmergeColors.teal,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Title
                      Text(
                        'Coming Soon',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textMainDark,
                            ),
                      ),
                      const SizedBox(height: 16),

                      // Description
                      Text(
                        'We\'re working hard to bring you an amazing community experience. Stay tuned for updates!',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.textSecondaryDark,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Info cards
                      _buildInfoCard(
                        context,
                        Icons.groups_outlined,
                        'Tribes & Clubs',
                        'Connect with like-minded people',
                      ),
                      const SizedBox(height: 16),
                      _buildInfoCard(
                        context,
                        Icons.emoji_events_outlined,
                        'Challenges',
                        'Compete and grow together',
                      ),
                      const SizedBox(height: 16),
                      _buildInfoCard(
                        context,
                        Icons.leaderboard_outlined,
                        'Leaderboards',
                        'Track your progress among friends',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EmergeColors.hexLine),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: EmergeColors.teal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: EmergeColors.teal, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
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
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondaryDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
