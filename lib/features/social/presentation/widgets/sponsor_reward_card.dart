import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/features/social/domain/models/challenge.dart';
import 'package:emerge_app/features/social/domain/services/affiliate_reward.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';

/// Glassmorphic card previewing a sponsored challenge's reward.
///
/// Claiming is only possible once the quest is finished; before that the card
/// shows a locked state so the sponsor stays visible during the quest.
class SponsorRewardCard extends StatelessWidget {
  final AffiliateReward reward;
  final bool claimable;
  final VoidCallback? onClaim;

  const SponsorRewardCard({
    super.key,
    required this.reward,
    required this.claimable,
    this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            EmergeColors.yellow.withValues(alpha: 0.12),
            Colors.white.withValues(alpha: 0.04),
          ],
        ),
        border: Border.all(color: EmergeColors.yellow.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: EmergeColors.yellow.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.workspace_premium, size: 12, color: EmergeColors.yellow),
                    Gap(4),
                    Text(
                      'SPONSOR REWARD',
                      style: TextStyle(
                        color: EmergeColors.yellow,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (reward.network != AffiliateNetwork.none)
                Text(
                  reward.network.name.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
            ],
          ),
          const Gap(12),
          Text(
            reward.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Gap(4),
          Text(
            'by ${reward.sponsor}',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
          ),
          const Gap(16),
          if (claimable)
            _ClaimButton(onClaim: onClaim)
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Complete this quest to claim your reward',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.05);
  }
}

class _ClaimButton extends StatelessWidget {
  final VoidCallback? onClaim;

  const _ClaimButton({this.onClaim});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          gradient: EmergeColors.neonGradient,
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onClaim,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Center(
              child: Text(
                'CLAIM REWARD',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
