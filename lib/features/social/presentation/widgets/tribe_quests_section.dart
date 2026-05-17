import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:emerge_app/features/social/domain/models/challenge.dart';
import 'package:emerge_app/features/social/presentation/providers/challenge_bundle_provider.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';

class TribeQuestsSection extends ConsumerWidget {
  const TribeQuestsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bundleAsync = ref.watch(challengeBundleProvider);

    return bundleAsync.when(
      data: (bundle) {
        final active = bundle.activeSoloChallenges;
        final completed = bundle.completedChallenges;

        if (active.isEmpty && completed.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Quests',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                GestureDetector(
                  onTap: () => context.push('/challenges'),
                  child: const Text(
                    'Browse More >',
                    style: TextStyle(fontSize: 12, color: EmergeColors.teal),
                  ),
                ),
              ],
            ),
            const Gap(16),
            if (active.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.bolt, size: 14, color: EmergeColors.teal),
                  const Gap(4),
                  Text(
                    'Active (${active.length})',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: EmergeColors.teal,
                    ),
                  ),
                ],
              ),
              const Gap(8),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: active.length,
                  itemBuilder: (context, index) {
                    return TribeChallengeMiniCard(challenge: active[index]);
                  },
                ),
              ),
              const Gap(16),
            ],
            if (completed.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.verified, size: 14, color: EmergeColors.yellow),
                  const Gap(4),
                  Text(
                    'Completed (${completed.length})',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: EmergeColors.yellow,
                    ),
                  ),
                ],
              ),
              const Gap(8),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: completed.length,
                  itemBuilder: (context, index) {
                    return TribeChallengeMiniCard(challenge: completed[index], isCompleted: true);
                  },
                ),
              ),
            ],
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class TribeChallengeMiniCard extends StatelessWidget {
  final Challenge challenge;
  final bool isCompleted;

  const TribeChallengeMiniCard({super.key, required this.challenge, this.isCompleted = false});

  @override
  Widget build(BuildContext context) {
    final progress = challenge.totalDays > 0
        ? challenge.currentDay / challenge.totalDays
        : 0.0;

    return GestureDetector(
      onTap: () => context.push('/challenge/${challenge.id}'),
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isCompleted
              ? EmergeColors.teal.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCompleted
                ? EmergeColors.teal.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.1),
          ),
          image: challenge.imageUrl.isNotEmpty
              ? DecorationImage(
                  image:
                      challenge.imageUrl.startsWith('images/') ||
                          challenge.imageUrl.startsWith('assets/images/')
                      ? AssetImage(challenge.imageUrl) as ImageProvider
                      : NetworkImage(challenge.imageUrl),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withValues(alpha: isCompleted ? 0.5 : 0.7),
                    BlendMode.darken,
                  ),
                )
              : null,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      challenge.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isCompleted ? EmergeColors.teal : Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isCompleted)
                    const Icon(
                      Icons.check_circle,
                      size: 16,
                      color: EmergeColors.teal,
                    ),
                ],
              ),
              const Gap(4),
              Text(
                isCompleted
                    ? 'Completed'
                    : 'Day ${challenge.currentDay} of ${challenge.totalDays}',
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
              const Spacer(),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white10,
                  valueColor: const AlwaysStoppedAnimation(EmergeColors.teal),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
