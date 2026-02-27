import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/core/presentation/widgets/glassmorphism_card.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/world_map/domain/models/archetype_map_config.dart';
import 'package:emerge_app/features/world_map/domain/models/archetype_maps_catalog.dart';
import 'package:emerge_app/features/world_map/domain/models/world_node.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';

class CurrentMissionBanner extends ConsumerWidget {
  const CurrentMissionBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userStatsAsync = ref.watch(userStatsStreamProvider);

    return userStatsAsync.when(
      data: (profile) {
        final archetype = profile.archetype;
        final config = ArchetypeMapsCatalog.getMapForArchetype(archetype);

        final claimedNodes = profile.worldState.claimedNodes;

        // Find the first node that is NOT claimed AND meets level requirements
        WorldNode? currentMission;
        for (final node in config.nodes) {
          if (!claimedNodes.contains(node.id)) {
            // Found the next available active node
            currentMission = node;
            break;
          }
        }

        if (currentMission == null) {
          // All missions completed for this map!
          return _buildBanner(
            context,
            title: 'World Conquered',
            description: 'You have claimed all nodes in this realm.',
            icon: Icons.emoji_events,
            color: Colors.amber,
          );
        }

        final isLocked =
            profile.avatarStats.level < currentMission.requiredLevel;

        return GestureDetector(
          onTap: () {
            if (currentMission != null) {
              _showMissionDetail(context, currentMission, config, profile);
            }
          },
          child: _buildBanner(
            context,
            title: isLocked
                ? 'Next Mission (Locked)'
                : 'Current Mission: ${currentMission.name}',
            description: isLocked
                ? 'Reach Level ${currentMission.requiredLevel} to unlock.'
                : currentMission.description,
            icon: isLocked ? Icons.lock : currentMission.icon,
            color: isLocked ? Colors.grey : config.primaryColor,
          ),
        );
      },
      loading: () => const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void _showMissionDetail(
    BuildContext context,
    WorldNode node,
    ArchetypeMapConfig config,
    UserProfile profile,
  ) {
    final isLocked = profile.avatarStats.level < node.requiredLevel;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppTheme.cosmicVoidDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          border: Border(
            top: BorderSide(color: AppTheme.glassBorder, width: 1),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Gap(24),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: (isLocked ? Colors.grey : config.primaryColor)
                        .withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(node.emoji, style: const TextStyle(fontSize: 32)),
                ),
                const Gap(16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        node.name,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        isLocked ? 'LOCKED' : 'ACTIVE MISSION',
                        style: TextStyle(
                          color: isLocked
                              ? Colors.white38
                              : config.primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Gap(24),
            Text(
              'THE DIRECTIVE',
              style: TextStyle(
                color: config.primaryColor.withValues(alpha: 0.7),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const Gap(8),
            Text(
              isLocked
                  ? 'Reach Level ${node.requiredLevel} to unlock the full directive for this node.'
                  : node.directive.isNotEmpty
                  ? node.directive
                  : node.description,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const Gap(24),
            Text(
              'TARGETED GROWTH',
              style: TextStyle(
                color: config.primaryColor.withValues(alpha: 0.7),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const Gap(12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: node.targetedAttributes.map((attr) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_circle_outline,
                        size: 14,
                        color: config.primaryColor,
                      ),
                      const Gap(6),
                      Text(
                        attr.name,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const Gap(32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.go('/');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: config.primaryColor,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'VIEW WORLD MAP',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
            const Gap(16),
          ],
        ),
      ),
    );
  }

  Widget _buildBanner(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    return GlassmorphismCard(
      glowColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Gap(4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondaryDark,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Gap(8),
          Icon(
            Icons.chevron_right,
            color: AppTheme.textSecondaryDark,
            size: 20,
          ),
        ],
      ),
    );
  }
}
