import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/features/social/domain/models/challenge.dart';
import 'package:emerge_app/features/social/presentation/providers/challenge_bundle_provider.dart';

/// Featured quests available to join — the daily quest and weekly spotlight.
/// These are NOT active; they come from the static catalog with
/// [ChallengeStatus.featured]. Joined/active quests live in
/// [TribeYourQuestsSection].
class TribeQuestsForYouSection extends ConsumerWidget {
  const TribeQuestsForYouSection({super.key});

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
    final daily = ref.watch(dailyQuestFromBundleProvider);
    final weekly = ref.watch(weeklySpotlightFromBundleProvider);

    final pool = <Challenge>[
      ?daily,
      ?weekly,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: const Text(
            'QUESTS FOR YOU',
            style: TextStyle(
              color: EmergeColors.nebulaPrimary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ),
        if (pool.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              'No featured quests right now.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 12,
              ),
            ),
          )
        else
          Column(
            children: List.generate(pool.length, (i) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: _QuestRow(challenge: pool[i]),
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
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => context.push('/social/challenge/${challenge.id}'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
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
                TribeQuestsForYouSection.iconFor(challenge.category),
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
                    '${challenge.totalDays}-day quest · Tap to join',
                    style: const TextStyle(color: Colors.white60, fontSize: 11),
                  ),
                ],
              ),
            ),
            const Gap(8),
            const Icon(Icons.chevron_right, color: Colors.white38, size: 22),
          ],
        ),
      ),
    );
  }
}
