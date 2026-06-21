import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/features/social/domain/models/challenge.dart';
import 'package:emerge_app/features/social/presentation/providers/challenge_provider.dart';

/// Quests the user has joined and is currently progressing.
/// Reads only [userChallengesProvider] filtered to
/// [ChallengeStatus.active]. Featured/available quests live in
/// [TribeQuestsForYouSection].
class TribeYourQuestsSection extends ConsumerWidget {
  const TribeYourQuestsSection({super.key});

  static IconData iconFor(ChallengeCategory category) {
    switch (category) {
      case ChallengeCategory.fitness:
        return Icons.directions_run;
      case ChallengeCategory.mindfulness:
        return Icons.self_improvement;
      case ChallengeCategory.learning:
        return Icons.menu_book;
      case ChallengeCategory.productivity:
        return Icons.bolt;
      case ChallengeCategory.creative:
        return Icons.palette;
      case ChallengeCategory.faith:
        return Icons.auto_awesome;
      case ChallengeCategory.nutrition:
        return Icons.restaurant;
      case ChallengeCategory.all:
        return Icons.flag;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengesAsync = ref.watch(userChallengesProvider);

    final List<Challenge> active =
        challengesAsync.value
                ?.where((c) => c.status == ChallengeStatus.active)
                .toList() ??
            <Challenge>[];

    active.sort((a, b) => b.currentDay.compareTo(a.currentDay));
    final top = active.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Row(
            children: [
              const Text(
                'YOUR QUESTS',
                style: TextStyle(
                  color: EmergeColors.nebulaPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => context.push('/social/challenges'),
                child: const Text(
                  'View All \u2192',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (challengesAsync.isLoading)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Center(
              child: SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else if (top.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              'No quests in progress \u2014 pick one below.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 12,
              ),
            ),
          )
        else
          Column(
            children: List.generate(top.length, (i) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: _QuestRow(challenge: top[i]),
              );
            }),
          ),
      ],
    );
  }
}

class _QuestRow extends StatelessWidget {
  final Challenge challenge;
  const _QuestRow({required this.challenge});

  @override
  Widget build(BuildContext context) {
    final progress = challenge.totalDays == 0
        ? 0.0
        : (challenge.currentDay / challenge.totalDays).clamp(0.0, 1.0);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => context.push('/social/challenge/${challenge.id}'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: EmergeColors.nebulaCtaGradient,
              ),
              alignment: Alignment.center,
              child: Icon(
                TribeYourQuestsSection.iconFor(challenge.category),
                color: Colors.black,
                size: 20,
              ),
            ),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    challenge.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Gap(2),
                  Text(
                    'Day ${challenge.currentDay}/${challenge.totalDays}',
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 11,
                    ),
                  ),
                  const Gap(6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 4,
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        EmergeColors.nebulaPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Gap(8),
            const Icon(
              Icons.chevron_right,
              color: Colors.white38,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
