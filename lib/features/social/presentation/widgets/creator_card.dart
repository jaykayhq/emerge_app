import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:emerge_app/core/presentation/widgets/fallback_initial_avatar.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/features/social/domain/entities/creator_profile.dart';

/// Compact verified-creator card for the All Tribes CREATORS section.
/// Taps through to the creator's profile ([CreatorProfileScreen]).
class CreatorCard extends StatelessWidget {
  final CreatorProfile creator;

  const CreatorCard({super.key, required this.creator});

  @override
  Widget build(BuildContext context) {
    final name = creator.displayName?.isNotEmpty == true
        ? creator.displayName!
        : 'Creator';
    final count = creator.blueprintCount;
    final blueprintsLabel = '$count ${count == 1 ? 'blueprint' : 'blueprints'}';

    return SizedBox(
      width: 96,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/social/creator/${creator.userId}'),
        child: Column(
          children: [
            FallbackInitialAvatar(
              name: name,
              size: 64,
              imageUrl: creator.avatarUrl,
              borderColor: EmergeColors.nebulaPrimaryContainer,
              borderWidth: 1.5,
            ),
            const Gap(8),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(2),
            Text(
              blueprintsLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white54, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
