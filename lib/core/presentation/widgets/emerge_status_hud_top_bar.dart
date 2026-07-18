import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:emerge_app/core/theme/archetype_theme.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';

class EmergeStatusHudTopBar extends ConsumerWidget {
  final PreferredSizeWidget? bottom;
  
  const EmergeStatusHudTopBar({super.key, this.bottom});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userStatsStreamProvider);
    
    final profile = userProfileAsync.value;
    if (profile == null) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    
    final archetype = profile.archetype;
    final level = profile.effectiveLevel;
    final theme = ArchetypeTheme.forArchetype(archetype);
    final xpProgress = (profile.avatarStats.totalXp % 500) / 500.0;

    return SliverAppBar(
      expandedHeight: bottom != null ? 140.0 : 100.0,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.primaryColor.withValues(alpha: 0.3),
                    theme.accentColor.withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ],
        ),
        titlePadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(theme.journeyIcon, color: theme.primaryColor, size: 18),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        theme.journeyName.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        theme.tagline.toUpperCase(),
                        style: TextStyle(
                          color: theme.accentColor.withValues(alpha: 0.8),
                          fontSize: 8,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.primaryColor.withValues(alpha: 0.6)),
                  ),
                  child: Text(
                    'LVL $level',
                    style: TextStyle(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => context.push('/profile'),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: theme.primaryColor.withValues(alpha: 0.4), width: 1.5),
                    ),
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
                      child: Icon(Icons.person_outline, color: theme.primaryColor, size: 14),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: xpProgress,
              backgroundColor: theme.primaryColor.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
              minHeight: 2,
              borderRadius: BorderRadius.circular(99),
            ),
          ],
        ),
      ),
      bottom: bottom,
    );
  }
}
