import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:emerge_app/core/theme/archetype_theme.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_loading_skeleton.dart';
import 'package:emerge_app/core/presentation/widgets/app_error_widget.dart';
import 'package:emerge_app/features/social/domain/models/tribe.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';
import 'package:emerge_app/features/social/presentation/widgets/tribe_header_widgets.dart';
import 'package:emerge_app/features/social/presentation/widgets/tribe_activity_feed.dart';

class SanctumToggleItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const SanctumToggleItem({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? EmergeColors.teal : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.white60,
          ),
        ),
      ),
    );
  }
}

class TribeSanctumTab extends ConsumerStatefulWidget {
  const TribeSanctumTab({super.key});

  @override
  ConsumerState<TribeSanctumTab> createState() => _TribeSanctumTabState();
}

class _TribeSanctumTabState extends ConsumerState<TribeSanctumTab> {
  bool _showGlobalActivity = false;
  final GlobalKey _emblemKey = GlobalKey();
  final GlobalKey _feedKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userStatsStreamProvider);
    final clubsAsync = ref.watch(allArchetypeClubsProvider);

    return clubsAsync.when(
      data: (clubs) {
        return profileAsync.when(
          data: (profile) {
            final theme = ArchetypeTheme.forArchetype(profile.archetype);

            final matchingIndex = clubs.isNotEmpty
                ? clubs.indexWhere(
                    (club) => club.archetypeId == profile.archetype.name,
                  )
                : -1;
            final userClub = matchingIndex != -1
                ? clubs[matchingIndex]
                : clubs
                      .where(
                        (club) =>
                            club.archetypeId == null ||
                            club.archetypeId!.isEmpty,
                      )
                      .firstOrNull;

            if (userClub == null) {
              return const Center(
                child: Text(
                  'No clubs available for your archetype yet.',
                  style: TextStyle(color: Colors.white70),
                ),
              );
            }

            return _buildSanctumTab(userClub, theme, profile);
          },
          loading: () => const EmergeLoadingSkeleton(itemCount: 1),
          error: (error, stack) => AppErrorWidget(
            message: 'Could not load your profile',
            onRetry: () => ref.invalidate(userStatsStreamProvider),
          ),
        );
      },
      loading: () => const EmergeLoadingSkeleton(itemCount: 5),
      error: (error, _) => AppErrorWidget(
        message: 'Could not load tribes',
        onRetry: () => ref.invalidate(allArchetypeClubsProvider),
      ),
    );
  }

  Widget _buildSanctumTab(Tribe userClub, ArchetypeTheme theme, UserProfile profile) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(allArchetypeClubsProvider);
        ref.invalidate(userStatsStreamProvider);
      },
      color: EmergeColors.teal,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const Gap(16),
            ArchetypeClubEmblem(
              key: _emblemKey,
              theme: theme,
            ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),
            const Gap(16),
            Text(
              userClub.name.toUpperCase(),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
            ).animate().fadeIn(delay: 100.ms),
            const Gap(4),
            Text(
              userClub.description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ).animate().fadeIn(delay: 150.ms),
            const Gap(16),
            RealTimeMemberCount(
              tribeId: userClub.id,
            ).animate().fadeIn(delay: 200.ms),
            const Gap(32),
            RealTimeTribeProgressMetrics(
              isGlobal: _showGlobalActivity,
              tribeId: userClub.id,
              theme: theme,
            ).animate().fadeIn(delay: 350.ms),
            const Gap(32),
            Row(
              key: _feedKey,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _showGlobalActivity ? 'Global Activity' : 'Recent Activity',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: EmergeColors.glassWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: EmergeColors.glassBorder),
                  ),
                  child: Row(
                    children: [
                      SanctumToggleItem(
                        label: 'Tribe',
                        isSelected: !_showGlobalActivity,
                        onTap: () => setState(() => _showGlobalActivity = false),
                      ),
                      SanctumToggleItem(
                        label: 'Global',
                        isSelected: _showGlobalActivity,
                        onTap: () => setState(() => _showGlobalActivity = true),
                      ),
                    ],
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 500.ms),
            const Gap(16),
            TribeActivitySection(
              clubId: _showGlobalActivity ? null : userClub.id,
              isGlobal: _showGlobalActivity,
            ).animate().fadeIn(delay: 550.ms),
            const Gap(32),
          ],
        ),
      ),
    );
  }
}
