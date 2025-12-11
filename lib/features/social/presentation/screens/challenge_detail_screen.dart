import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/features/social/domain/models/challenge.dart';
import 'package:emerge_app/features/social/presentation/providers/challenge_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

class ChallengeDetailScreen extends ConsumerWidget {
  final Challenge challenge;

  const ChallengeDetailScreen({super.key, required this.challenge});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: AppTheme.backgroundDark,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(challenge.imageUrl, fit: BoxFit.cover),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, AppTheme.backgroundDark],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
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
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Gap(8),
                  Text(
                    challenge.description,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                  ),
                  const Gap(16),
                  Row(
                    children: [
                      Icon(Icons.emoji_events, color: AppTheme.primary),
                      const Gap(8),
                      Text(
                        'Reward: ${challenge.reward}',
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Gap(24),
                  if (challenge.status == ChallengeStatus.featured)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          ref
                              .read(challengesProvider.notifier)
                              .joinChallenge(challenge.id);
                          context.pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Challenge Joined!'),
                              backgroundColor: AppTheme.primary,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.black,
                        ),
                        child: const Text('Join Quest'),
                      ),
                    ),
                  const Gap(24),
                  const Text(
                    'Timeline',
                    style: TextStyle(
                      color: Colors.white,
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
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: step.day <= challenge.currentDay
                      ? AppTheme.primary
                      : Colors.white10,
                  child: Text(
                    '${step.day}',
                    style: TextStyle(
                      color: step.day <= challenge.currentDay
                          ? Colors.black
                          : Colors.white,
                    ),
                  ),
                ),
                title: Text(
                  step.title,
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  step.description,
                  style: const TextStyle(color: Colors.white54),
                ),
              );
            }, childCount: challenge.steps.length),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
        ],
      ),
    );
  }
}
