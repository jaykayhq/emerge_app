import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/features/social/domain/entities/social_entities.dart';
import 'package:emerge_app/features/social/presentation/providers/friend_provider.dart';
import 'package:emerge_app/features/monetization/presentation/providers/contract_provider.dart';

/// The official lobby home for the user's accountability partners.
/// Replaces the two misrouted deep-links from the live feed. Tapping the
/// section navigates to [/social/accountability] (FriendsScreen).
///
/// Supersedes the orphaned [TribeAccountabilitySection], which is deleted
/// in Phase 6.
class TribeCircleSection extends ConsumerWidget {
  const TribeCircleSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partnersAsync = ref.watch(partnersListStreamProvider);
    final contractsAsync = ref.watch(activeOnlyContractsProvider);
    final requestsAsync = ref.watch(pendingPartnerRequestsStreamProvider);

    return GestureDetector(
      onTap: () => context.push('/social/accountability'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'YOUR CIRCLE',
                  style: TextStyle(
                    color: EmergeColors.nebulaPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                requestsAsync.maybeWhen(
                  data: (reqs) => reqs.isEmpty
                      ? const SizedBox.shrink()
                      : _RequestBadge(count: reqs.length),
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            ),
            const Gap(12),
            SizedBox(
              height: 56,
              child: partnersAsync.when(
                loading: () => const Center(
                  child: SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                error: (_, _) => const Text(
                  'Could not load partners.',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                data: (partners) {
                  if (partners.isEmpty) {
                    return Row(
                      children: [
                        Icon(
                          Icons.person_add,
                          color: Colors.white.withValues(alpha: 0.5),
                          size: 20,
                        ),
                        const Gap(8),
                        Expanded(
                          child: Text(
                            'Add your first partner',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                  return ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: partners.length,
                    separatorBuilder: (_, _) => const Gap(10),
                    itemBuilder: (_, i) => _PartnerAvatar(partner: partners[i]),
                  );
                },
              ),
            ),
            const Gap(10),
            contractsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (contracts) => Row(
                children: [
                  Icon(
                    Icons.handshake,
                    color: EmergeColors.yellow.withValues(alpha: 0.8),
                    size: 14,
                  ),
                  const Gap(6),
                  Text(
                    '${contracts.length} active contract${contracts.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 11,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.chevron_right,
                    color: Colors.white38,
                    size: 18,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PartnerAvatar extends StatelessWidget {
  final Friend partner;
  const _PartnerAvatar({required this.partner});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: EmergeColors.glassWhite,
              child: Text(
                partner.name.isNotEmpty
                    ? partner.name[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            if (partner.isOnline)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.greenAccent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black87, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
        const Gap(3),
        Text(
          partner.name.split(' ').first,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
      ],
    );
  }
}

class _RequestBadge extends StatelessWidget {
  final int count;
  const _RequestBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: EmergeColors.coral,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
