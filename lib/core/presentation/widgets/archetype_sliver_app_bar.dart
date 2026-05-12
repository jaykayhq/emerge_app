import 'package:emerge_app/core/theme/archetype_theme.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A collapsing SliverAppBar that applies archetype-aware colors and styling
class ArchetypeSliverAppBar extends ConsumerWidget {
  final String title;
  final Widget? badge;
  final Widget? syncIndicator;
  final PreferredSizeWidget? bottom;
  final List<Widget>? actions;

  const ArchetypeSliverAppBar({
    super.key,
    required this.title,
    this.badge,
    this.syncIndicator,
    this.bottom,
    this.actions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userStatsStreamProvider);
    
    // Provide a default fallback while loading
    final archetype = userProfileAsync.asData?.value.archetype ?? UserArchetype.none;
    final archetypeTheme = ArchetypeTheme.forArchetype(archetype);

    return SliverAppBar(
      expandedHeight: bottom != null ? 140.0 : 100.0,
      floating: false,
      pinned: true,
      elevation: 0,
      actions: actions,
      backgroundColor: archetypeTheme.primaryColor.withValues(alpha: 0.1),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: EdgeInsets.only(
          left: 16.0,
          bottom: bottom != null ? 60.0 : 16.0,
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                shadows: [
                  Shadow(
                    color: archetypeTheme.primaryColor,
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 8),
              badge!,
            ],
            if (syncIndicator != null) ...[
              const SizedBox(width: 8),
              syncIndicator!,
            ],
          ],
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Base gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    archetypeTheme.primaryColor.withValues(alpha: 0.3),
                    archetypeTheme.accentColor.withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            // Tagline or Mantra in the background
            Positioned(
              right: 16,
              bottom: bottom != null ? 70 : 20,
              child: Opacity(
                opacity: 0.3,
                child: Text(
                  archetypeTheme.tagline.toUpperCase(),
                  style: TextStyle(
                    color: archetypeTheme.accentColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottom: bottom,
    );
  }
}
