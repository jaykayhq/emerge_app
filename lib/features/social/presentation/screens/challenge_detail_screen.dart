import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/core/presentation/widgets/world_background.dart';
import 'package:emerge_app/core/domain/models/app_world_theme.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/gamification/data/repositories/user_stats_repository.dart';

import 'package:emerge_app/features/social/domain/models/challenge.dart';
import 'package:emerge_app/features/social/presentation/providers/challenge_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

class ChallengeDetailScreen extends ConsumerWidget {
  final Challenge? challenge;
  final String? challengeId;

  const ChallengeDetailScreen({
    super.key,
    this.challenge,
    this.challengeId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengeAsync = challenge != null
        ? AsyncValue.data(challenge!)
        : ref.watch(challengeByIdProvider(challengeId ?? ''));

    return challengeAsync.when(
      loading: () => const Scaffold(
        backgroundColor: EmergeColors.background,
        body: Center(child: CircularProgressIndicator(color: EmergeColors.teal)),
      ),
      error: (err, stack) => Scaffold(
        backgroundColor: EmergeColors.background,
        body: Center(
          child: Text(
            'Error loading challenge: $err',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
      data: (challenge) {
        if (challenge == null) {
          return const Scaffold(
            backgroundColor: EmergeColors.background,
            body: Center(
              child: Text(
                'Challenge not found',
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
        }

        return WorldBackground(
          themeOverride: AppWorldTheme.nebula,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 250,
                pinned: true,
                backgroundColor: EmergeColors.background,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      challenge.imageUrl.startsWith('images/')
                          ? Image.asset(
                              challenge.imageUrl,
                              fit: BoxFit.cover,
                            )
                          : Image.network(
                              challenge.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: EmergeColors.teal.withValues(alpha:0.2),
                                child: const Center(
                                  child: Icon(
                                    Icons.emoji_events,
                                    size: 64,
                                    color: EmergeColors.teal,
                                  ),
                                ),
                              ),
                            ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              EmergeColors.background,
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                leading: IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: AppTheme.textMainDark,
                  ),
                  onPressed: () => context.pop(),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        challenge.title,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: AppTheme.textMainDark,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const Gap(8),
                      Text(
                        challenge.description,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.textSecondaryDark,
                        ),
                      ),
                      const Gap(16),
                      Row(
                        children: [
                          Icon(Icons.emoji_events, color: EmergeColors.yellow),
                          const Gap(8),
                          Text(
                            'Reward: ${challenge.reward}',
                            style: const TextStyle(
                              color: EmergeColors.yellow,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Gap(24),
                      if (challenge.status == ChallengeStatus.featured ||
                          challenge.status == ChallengeStatus.active)
                        Container(
                          width: double.infinity,
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: const LinearGradient(
                              colors: [EmergeColors.teal, EmergeColors.violet],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: EmergeColors.teal.withValues(alpha:0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () async {
                              try {
                                final userAsync = ref.read(
                                  authStateChangesProvider,
                                );
                                final user = userAsync.value;

                                if (user != null) {
                                  final repo = ref.read(
                                    challengeRepositoryProvider,
                                  );

                                  if (challenge.status ==
                                      ChallengeStatus.featured) {
                                    // 1. Join Challenge
                                    final result = await repo.joinChallenge(
                                      user.id,
                                      challenge.id,
                                    );

                                    await result.fold(
                                      (failure) async {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Failed to join: ${failure.message}',
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      },
                                      (_) async {
                                        // 2. Log Activity for XP
                                        final userStatsRepo = ref.read(
                                          userStatsRepositoryProvider,
                                        );
                                        await userStatsRepo.logActivity(
                                          userId: user.id,
                                          type: 'joined_challenge',
                                          sourceId: challenge.id,
                                          date: DateTime.now(),
                                        );

                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Challenge Joined! (+25 XP)',
                                              ),
                                              backgroundColor:
                                                  EmergeColors.teal,
                                            ),
                                          );
                                          context.pop();
                                        }
                                      },
                                    );
                                  } else if (challenge.status ==
                                      ChallengeStatus.active) {
                                    // Update Progress
                                    final newProgress =
                                        challenge.currentDay + 1;
                                    final result = await repo.updateProgress(
                                      user.id,
                                      challenge.id,
                                      newProgress,
                                    );

                                    await result.fold(
                                      (failure) async {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Failed to update progress: ${failure.message}',
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      },
                                      (_) async {
                                        if (context.mounted) {
                                          final isCompleted =
                                              newProgress >=
                                              challenge.totalDays;
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                isCompleted
                                                    ? 'Quest Completed! You earned ${challenge.xpReward} XP.'
                                                    : 'Progress saved! Day $newProgress complete.',
                                              ),
                                              backgroundColor:
                                                  EmergeColors.teal,
                                            ),
                                          );
                                          context.pop();
                                        }
                                      },
                                    );
                                  }
                                } else {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Please sign in first.'),
                                      ),
                                    );
                                  }
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Action failed: $e'),
                                    ),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              challenge.status == ChallengeStatus.featured
                                  ? 'Join Quest'
                                  : (challenge.currentDay + 1 >=
                                            challenge.totalDays
                                        ? 'Finish Quest'
                                        : 'Complete Day ${challenge.currentDay + 1}'),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      const Gap(24),
                      Text(
                        'Timeline',
                        style: TextStyle(
                          color: AppTheme.textMainDark,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Gap(16),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final step = challenge.steps[index];
                  final isCompleted = step.day <= challenge.currentDay;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isCompleted
                          ? EmergeColors.teal
                          : AppTheme.surfaceDark,
                      child: Text(
                        '${step.day}',
                        style: TextStyle(
                          color: isCompleted
                              ? Colors.white
                              : AppTheme.textSecondaryDark,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      step.title,
                      style: const TextStyle(
                        color: AppTheme.textMainDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      step.description,
                      style: const TextStyle(color: AppTheme.textSecondaryDark),
                    ),
                  );
                }, childCount: challenge.steps.length),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
            ],
          ),
        ),
      );
    },
  );
}
}
