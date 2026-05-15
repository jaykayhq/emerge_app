import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/core/theme/archetype_theme.dart';
import 'package:emerge_app/features/social/domain/models/tribe.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/social/presentation/providers/cached_tribe_stats_provider.dart';
import 'package:emerge_app/features/social/domain/services/tribe_membership_service.dart';
import 'package:emerge_app/features/social/data/services/tribe_stats_service.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';

class TribeCard extends ConsumerWidget {
  final Tribe tribe;

  const TribeCard({super.key, required this.tribe});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(cachedTribeStatsProvider(tribe.id));
    final theme = ArchetypeTheme.forArchetype(
      tribe.archetypeId != null
          ? UserArchetype.values.firstWhere(
              (a) => a.name == tribe.archetypeId,
              orElse: () => UserArchetype.scholar,
            )
          : UserArchetype.scholar,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            EmergeColors.glassWhite.withValues(alpha: 0.1),
            EmergeColors.glassWhite.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EmergeColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [theme.primaryColor, theme.accentColor],
                  ),
                ),
                child: Center(
                  child: Text(
                    theme.emoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
              const Gap(16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tribe.name.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                    const Gap(4),
                    Text(
                      tribe.description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Gap(16),
          statsAsync.when(
            data: (stats) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  label: 'Members',
                  value: '${stats.memberCount}',
                  icon: Icons.people,
                  color: EmergeColors.teal,
                ),
                _StatItem(
                  label: 'XP',
                  value: stats.totalXp >= 1000
                      ? '${(stats.totalXp / 1000).toStringAsFixed(1)}k'
                      : '${stats.totalXp}',
                  icon: Icons.electric_bolt,
                  color: EmergeColors.yellow,
                ),
                _StatItem(
                  label: 'Habits',
                  value: '${stats.totalHabitsCompleted}',
                  icon: Icons.check_circle_outline,
                  color: EmergeColors.violet,
                ),
                _StatItem(
                  label: 'Quests',
                  value: '${stats.totalChallengesCompleted}',
                  icon: Icons.emoji_events,
                  color: EmergeColors.coral,
                ),
              ],
            ),
            loading: () => const Center(
              child: CircularProgressIndicator(color: EmergeColors.teal),
            ),
            error: (_, _) => const Center(
              child: Text(
                'Error loading stats',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ),
          const Gap(16),
          _MembershipButton(tribe: tribe),
        ],
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
    final statsService = ref.read(tribeStatsServiceProvider);

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          try {
            if (isMember) {
              await membershipService.leaveTribe(tribe.id);
              await statsService.syncTribeStats(tribe.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Left tribe successfully')),
                );
              }
            } else {
              await membershipService.joinTribe(tribe.id);
              await statsService.syncTribeStats(tribe.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Joined tribe successfully!')),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isMember
                ? const BorderSide(color: Colors.white24)
                : BorderSide.none,
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(
          isMember ? 'LEAVE TRIBE' : 'JOIN TRIBE',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const Gap(4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.white60),
        ),
      ],
    );
  }
}
