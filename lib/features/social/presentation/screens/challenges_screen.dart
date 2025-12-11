import 'package:emerge_app/core/presentation/widgets/growth_background.dart';
import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/features/social/data/repositories/social_repository.dart';
import 'package:emerge_app/features/social/domain/entities/social_entities.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

class ChallengesScreen extends ConsumerWidget {
  const ChallengesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: GrowthBackground(
        appBar: AppBar(
          title: const Text('Challenges'),
          backgroundColor: Colors.transparent,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Active'),
              Tab(text: 'Community'),
            ],
          ),
        ),
        child: TabBarView(
          children: [_ActiveChallengesTab(), _CommunityChallengesTab()],
        ),
      ),
    );
  }
}

class _ActiveChallengesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengesAsync = ref.watch(activeChallengesProvider);

    return challengesAsync.when(
      data: (challenges) {
        if (challenges.isEmpty) {
          return const Center(child: Text('No active challenges'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: challenges.length,
          separatorBuilder: (context, index) => const Gap(16),
          itemBuilder: (context, index) {
            return _ChallengeCard(
              challenge: challenges[index],
            ).animate().fadeIn(delay: (100 * index).ms).slideY();
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}

class _CommunityChallengesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Community Challenges Coming Soon',
        style: TextStyle(color: AppTheme.textSecondaryDark),
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  final Challenge challenge;

  const _ChallengeCard({required this.challenge});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.emoji_events,
                    color: AppTheme.secondary,
                  ),
                ),
                const Gap(16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        challenge.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${challenge.daysLeft} days left',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Gap(16),
            Text(
              challenge.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Gap(16),
            LinearProgressIndicator(
              value: 0.7, // Mock progress
              backgroundColor: AppTheme.backgroundDark,
              color: AppTheme.secondary,
              borderRadius: BorderRadius.circular(4),
            ),
            const Gap(8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${challenge.participants} participants',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.textSecondaryDark,
                  ),
                ),
                Text(
                  '70%',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
