import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/features/social/presentation/providers/friend_provider.dart';
import 'package:emerge_app/features/monetization/presentation/providers/contract_provider.dart';

class TribeAccountabilitySection extends ConsumerWidget {
  const TribeAccountabilitySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partnersAsync = ref.watch(partnersListStreamProvider);
    final contractsAsync = ref.watch(activeOnlyContractsProvider);
    final requestsAsync = ref.watch(pendingPartnerRequestsStreamProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Accountability Circle',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            requestsAsync.maybeWhen(
              data: (requests) => requests.isNotEmpty
                  ? _RequestBadge(count: requests.length)
                  : const SizedBox.shrink(),
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
        const Gap(16),

        // Horizontal Row for Partners and Contracts
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // Habit Contracts Summary Card
              contractsAsync.when(
                data: (contracts) => _AccountabilityToolCard(
                  title: 'Contracts',
                  value: '${contracts.length}',
                  icon: Icons.handshake,
                  color: EmergeColors.yellow,
                  onTap: () => context.push('/tribes/contracts'),
                ),
                loading: () => const _LoadingCard(),
                error: (err, stack) => const SizedBox.shrink(),
              ),

              const Gap(12),

              // Partners List
              partnersAsync.when(
                data: (partners) {
                  if (partners.isEmpty) {
                    return _AccountabilityToolCard(
                      title: 'Partners',
                      value: '0',
                      icon: Icons.person_add,
                      color: EmergeColors.teal,
                      onTap: () => context.push('/tribes/accountability'),
                    );
                  }
                  return Row(
                    children: partners.map((partner) {
                      return _PartnerAvatarCircle(partner: partner);
                    }).toList(),
                  );
                },
                loading: () => const Row(
                  children: [_LoadingCircle(), Gap(12), _LoadingCircle()],
                ),
                error: (err, stack) => const SizedBox.shrink(),
              ),

              // Add Partner Button
              const Gap(12),
              _AddPartnerButton(
                onTap: () => context.push('/tribes/accountability'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AccountabilityToolCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _AccountabilityToolCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(title, style: TextStyle(color: Colors.white70, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class _PartnerAvatarCircle extends StatelessWidget {
  final dynamic
  partner; // Using dynamic for now to match whatever entity we have

  const _PartnerAvatarCircle({required this.partner});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: EmergeColors.teal.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            child: CircleAvatar(
              backgroundColor: EmergeColors.glassWhite,
              child: Text(
                partner.name.isNotEmpty ? partner.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const Gap(4),
          Text(
            partner.name.split(' ').first,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _AddPartnerButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddPartnerButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        margin: const EdgeInsets.only(bottom: 20), // Align with avatars
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24, style: BorderStyle.solid),
        ),
        child: const Icon(Icons.add, color: Colors.white54),
      ),
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
        '$count Requests',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

class _LoadingCircle extends StatelessWidget {
  const _LoadingCircle();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.05),
      ),
    );
  }
}
