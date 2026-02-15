import 'dart:ui';
import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

/// A glassmorphic sidebar menu for world management
///
/// This provides quick access to world features while maintaining
/// focus on the visualization. Positioned at top-left to align with AppBar.
class WorldSidebarMenu extends StatelessWidget {
  const WorldSidebarMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top:
          MediaQuery.of(context).padding.top + 8, // Status bar + AppBar padding
      left: 16,
      child: _MenuButton(onPressed: () => _showMenuSheet(context)),
    );
  }

  void _showMenuSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const _WorldMenuSheet(),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _MenuButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(16),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(Icons.menu_rounded, color: Colors.white, size: 24),
              ),
            ),
          ),
        ),
      ),
    ).animate().scale(delay: 300.ms, duration: 400.ms);
  }
}

class _WorldMenuSheet extends ConsumerWidget {
  const _WorldMenuSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userStatsStreamProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.7,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark.withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(
                color: AppTheme.primary.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // User Progression Header
              userProfileAsync.when(
                data: (profile) {
                  final level = profile.avatarStats.level;
                  final totalXp = profile.avatarStats.totalXp;
                  final xpForCurrentLevel = (level - 1) * 100;
                  final xpProgress = totalXp - xpForCurrentLevel;
                  final progressPercent = (xpProgress / 100).clamp(0.0, 1.0);
                  final cityLevel = profile.worldState.cityLevel;
                  final forestLevel = profile.worldState.forestLevel;

                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Main header with world icon
                        Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppTheme.primary,
                                    AppTheme.primary.withValues(alpha: 0.6),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.public,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const Gap(16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Text(
                                        'Your World',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primary.withValues(
                                            alpha: 0.2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: AppTheme.primary.withValues(
                                              alpha: 0.5,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          'Lvl $level',
                                          style: const TextStyle(
                                            color: AppTheme.primary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        '$totalXp total XP',
                                        style: const TextStyle(
                                          color: Colors.white54,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Text(
                                        'City: $cityLevel • Forest: $forestLevel',
                                        style: const TextStyle(
                                          color: Colors.white54,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // XP Progress Bar
                        Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Stack(
                                children: [
                                  Container(
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  FractionallySizedBox(
                                    widthFactor: progressPercent,
                                    child: Container(
                                      height: 8,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            EmergeColors.teal,
                                            EmergeColors.coral,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '$xpProgress / 100 XP',
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 11,
                                  ),
                                ),
                                Text(
                                  '${100 - xpProgress} XP to next level',
                                  style: const TextStyle(
                                    color: AppTheme.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 100.ms);
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  ),
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),

              const Divider(height: 1, color: Colors.white10),

              // Menu items
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    _MenuItem(
                      icon: Icons.settings_rounded,
                      title: 'World Settings',
                      subtitle: 'Customize appearance',
                      color: Colors.blue,
                      delay: 150.ms,
                      onTap: () {
                        Navigator.pop(context);
                        _showWorldSettings(context);
                      },
                    ),
                    _MenuItem(
                      icon: Icons.grid_view_rounded,
                      title: 'Zones',
                      subtitle: 'View all territories',
                      color: Colors.green,
                      delay: 200.ms,
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/world/zones');
                      },
                    ),
                    _MenuItem(
                      icon: Icons.construction_rounded,
                      title: 'Build Mode',
                      subtitle: 'Place buildings',
                      color: Colors.orange,
                      delay: 250.ms,
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/world/build');
                      },
                    ),
                    _MenuItem(
                      icon: Icons.terrain_rounded,
                      title: 'Expand Land',
                      subtitle: 'Unlock territories',
                      color: Colors.purple,
                      delay: 300.ms,
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/world/expand');
                      },
                    ),
                    const Gap(16),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showWorldSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (c) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'World Settings',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Gap(20),
            ListTile(
              leading: const Icon(Icons.palette, color: Colors.teal),
              title: const Text(
                'Change Theme',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Customize world appearance',
                style: TextStyle(color: Colors.white54),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.white54),
              onTap: () {
                Navigator.pop(c);
                context.push('/profile/settings');
              },
            ),
            const Gap(16),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Duration delay;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.delay,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
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
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: color.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: delay).slideX(begin: 0.2, end: 0);
  }
}
