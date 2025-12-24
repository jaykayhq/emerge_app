import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
import 'package:emerge_app/core/presentation/widgets/responsive_layout.dart';
import 'package:emerge_app/core/theme/app_theme.dart';

import 'package:emerge_app/features/auth/domain/entities/auth_user.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/gamification/presentation/widgets/avatar_display.dart';
import 'package:emerge_app/features/monetization/presentation/widgets/ad_banner_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

class UserProfileScreen extends ConsumerWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authStateChangesProvider);
    final statsAsync = ref.watch(userStatsStreamProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Character'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettings(context, ref, theme),
          ),
        ],
      ),
      body: statsAsync.when(
        data: (profile) {
          final stats = profile.avatarStats;
          return ResponsiveLayout(
            mobile: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildCharacterHeader(
                    context,
                    userAsync,
                    stats,
                    theme,
                    profile,
                  ),
                  const Gap(32),
                  _buildAttributes(stats, theme),
                  const Gap(32),
                  const Gap(32),
                  _buildEquipment(theme),
                  const Gap(32),
                  const AdBannerWidget(),
                ],
              ),
            ),
            tablet: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              _buildCharacterHeader(
                                context,
                                userAsync,
                                stats,
                                theme,
                                profile,
                              ),
                              const Gap(32),
                              _buildEquipment(theme),
                            ],
                          ),
                        ),
                      ),
                      const Gap(32),
                      Expanded(
                        flex: 3,
                        child: SingleChildScrollView(
                          child: _buildAttributes(stats, theme),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error loading character: $e')),
      ),
    );
  }

  Widget _buildCharacterHeader(
    BuildContext context,
    AsyncValue<AuthUser?> userAsync,
    UserAvatarStats stats,
    ThemeData theme,
    UserProfile profile,
  ) {
    return Column(
      children: [
        // Bitmoji-style Avatar Card
        GestureDetector(
          onTap: () => context.push('/profile/avatar'),
          child: Container(
            width: double.infinity,
            height: 300,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.primary.withValues(alpha: 0.1),
                  AppTheme.backgroundDark,
                ],
              ),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background Glow
                Positioned(
                  top: 50,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.2),
                          blurRadius: 50,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ),

                // Avatar
                SizedBox(
                  height: 250,
                  width: 250,
                  child: AvatarDisplay(avatar: profile.avatar, size: 250),
                ),

                // Edit Badge
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.edit,
                          color: AppTheme.backgroundDark,
                          size: 16,
                        ),
                        const Gap(8),
                        Text(
                          'Customize',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: AppTheme.backgroundDark,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn().slideY(begin: 0.1, end: 0),
        ),

        const Gap(24),

        // Name & Level
        Text(
          userAsync.value?.displayName ?? 'Hero',
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.textMainDark,
          ),
        ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2, end: 0),
        GestureDetector(
          onTap: () => context.push('/profile/leveling'),
          child: Column(
            children: [
              Text(
                'Level ${stats.level}',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: AppTheme.primary,
                ),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
              const Gap(8),
              // XP Bar
              Container(
                width: 200,
                height: 8,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor:
                      (stats.strengthXp +
                          stats.intellectXp +
                          stats.vitalityXp) %
                      100 /
                      100, // Approximate XP progress
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const Gap(16),
              // Goldilocks Button
              InkWell(
                onTap: () => context.push('/profile/goldilocks'),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.cyanAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.cyanAccent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.smart_toy,
                        size: 16,
                        color: Colors.cyanAccent,
                      ),
                      const Gap(8),
                      Text(
                        'Training Partner',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: Colors.cyanAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAttributes(UserAvatarStats stats, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attributes',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const Gap(16),
        _AttributeRow(
          label: 'Strength',
          value: stats.strengthXp,
          icon: Icons.fitness_center,
          color: EmergeColors.coral,
          theme: theme,
        ).animate().fadeIn(delay: 300.ms).slideX(),
        const Gap(12),
        _AttributeRow(
          label: 'Intellect',
          value: stats.intellectXp,
          icon: Icons.auto_stories,
          color: EmergeColors.violet,
          theme: theme,
        ).animate().fadeIn(delay: 400.ms).slideX(),
        const Gap(12),
        _AttributeRow(
          label: 'Vitality',
          value: stats.vitalityXp,
          icon: Icons.favorite,
          color: EmergeColors.teal,
          theme: theme,
        ).animate().fadeIn(delay: 500.ms).slideX(),
      ],
    );
  }

  Widget _buildEquipment(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Equipment',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const Gap(16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _EquipmentSlot(
              icon: FontAwesomeIcons.helmetSafety,
              label: 'Head',
              theme: theme,
            ),
            _EquipmentSlot(
              icon: FontAwesomeIcons.shirt,
              label: 'Body',
              theme: theme,
            ),
          ],
        ),
        const Gap(16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _EquipmentSlot(
              icon: FontAwesomeIcons.hammer,
              label: 'Main Hand',
              theme: theme,
            ),
            _EquipmentSlot(
              icon: FontAwesomeIcons.shield,
              label: 'Off Hand',
              theme: theme,
            ),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 600.ms);
  }

  void _showSettings(BuildContext context, WidgetRef ref, ThemeData theme) {
    context.push('/profile/settings');
  }
}

class _AttributeRow extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final ThemeData theme;

  const _AttributeRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate level from XP (simplified: level = xp / 100)
    final level = (value / 100).floor() + 1;
    final progress = (value % 100) / 100;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.textSecondaryDark.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Lvl $level',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Gap(8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: color.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 8,
                  ),
                ),
                const Gap(4),
                Text(
                  '${value % 100} / 100 XP',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondaryDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EquipmentSlot extends StatelessWidget {
  final IconData icon;
  final String label;
  final ThemeData theme;

  const _EquipmentSlot({
    required this.icon,
    required this.label,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.textSecondaryDark.withValues(alpha: 0.2),
              width: 2,
            ),
          ),
          child: Icon(
            icon,
            color: AppTheme.textSecondaryDark.withValues(alpha: 0.3),
            size: 32,
          ),
        ),
        const Gap(8),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondaryDark,
          ),
        ),
      ],
    );
  }
}
