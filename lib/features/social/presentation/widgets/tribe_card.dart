import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/features/social/domain/models/tribe.dart';
import 'package:emerge_app/features/onboarding/presentation/widgets/club_emblem_images.dart';
import 'package:emerge_app/features/social/presentation/providers/cached_tribe_stats_provider.dart';
import 'package:emerge_app/features/social/domain/services/tribe_membership_service.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:go_router/go_router.dart';

/// Compact grid card for the All Tribes screen (mirrors the onboarding
/// [ClubBoxCard] look): image emblem on top, name + stats below, and a
/// JOIN/LEAVE button. Images come from the tribe's own imageUrl with a
/// deterministic per-club fallback — no emoji.
class TribeCard extends ConsumerWidget {
  final Tribe tribe;

  const TribeCard({super.key, required this.tribe});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(cachedTribeStatsProvider(tribe.id));
    final imageUrl = clubEmblemImageUrl(
      existingImageUrl: tribe.imageUrl,
      archetypeId: tribe.archetypeId,
      clubId: tribe.id,
    );
    final isAsset = isBundledEmblem(imageUrl);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EmergeColors.glassBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: GestureDetector(
        onTap: () => context.push('/social/tribe/${tribe.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Emblem image area (top) — tappable: opens the club's lobby.
            Expanded(
              flex: 5,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      EmergeColors.teal.withValues(alpha: 0.25),
                      Colors.transparent,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: isAsset
                    ? Image.asset(
                        imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(
                              child: Icon(
                                Icons.groups,
                                size: 36,
                                color: EmergeColors.teal,
                              ),
                            ),
                      )
                    : Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: EmergeColors.teal,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(
                              child: Icon(
                                Icons.groups,
                                size: 36,
                                color: EmergeColors.teal,
                              ),
                            ),
                      ),
              ),
            ),
            // Info area.
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tribe.name.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Gap(4),
                    statsAsync.when(
                      data: (stats) => Row(
                        children: [
                          const Icon(
                            Icons.people,
                            size: 12,
                            color: EmergeColors.teal,
                          ),
                          const Gap(4),
                          Text(
                            '${stats.memberCount}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white70,
                            ),
                          ),
                          const Gap(8),
                          const Icon(
                            Icons.electric_bolt,
                            size: 12,
                            color: EmergeColors.yellow,
                          ),
                          const Gap(4),
                          Expanded(
                            child: Text(
                              stats.totalXp >= 1000
                                  ? '${(stats.totalXp / 1000).toStringAsFixed(1)}k XP'
                                  : '${stats.totalXp} XP',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ],
                      ),
                      loading: () => const SizedBox(
                        height: 12,
                        child: LinearProgressIndicator(
                          color: EmergeColors.teal,
                          backgroundColor: Colors.white10,
                          minHeight: 2,
                        ),
                      ),
                      error: (_, _) => const Text(
                        'Stats unavailable',
                        style: TextStyle(fontSize: 11, color: Colors.white38),
                      ),
                    ),
                    const Spacer(),
                    _MembershipButton(tribe: tribe),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MembershipButton extends ConsumerWidget {
  final Tribe tribe;
  const _MembershipButton({required this.tribe});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateChangesProvider).value;
    if (user == null) return const SizedBox.shrink();

    final isMember = tribe.members.contains(user.id);
    final membershipService = ref.read(tribeMembershipServiceProvider);

    return SizedBox(
      width: double.infinity,
      height: 32,
      child: ElevatedButton(
        onPressed: () async {
          try {
            if (isMember) {
              // Confirmation dialog before leaving
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Leave Tribe'),
                  content: const Text(
                    'Are you sure you want to leave? Your streak progress stays, '
                    'and your contributions remain on the tribe\'s record.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text(
                        'Leave',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
              if (confirmed != true) return;

              await membershipService.leaveTribe(user.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Left tribe successfully')),
                );
              }
            } else {
              await membershipService.joinTribe(
                userId: user.id,
                tribeId: tribe.id,
                type: tribe.archetypeId != null ? 'archetype' : 'creator',
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Joined ${tribe.name}! It is now your active tribe.',
                    ),
                  ),
                );
              }
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Error: $e')));
            }
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isMember ? Colors.white10 : EmergeColors.teal,
          foregroundColor: isMember ? Colors.white70 : Colors.black,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: isMember
                ? const BorderSide(color: Colors.white24)
                : BorderSide.none,
          ),
        ),
        child: Text(
          isMember ? 'LEAVE' : 'JOIN',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}
