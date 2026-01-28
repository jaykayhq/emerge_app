import 'dart:ui';
import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/core/theme/theme_provider.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/gamification/data/repositories/user_stats_repository.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/settings/presentation/screens/notification_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

/// A slide-down settings sheet using DraggableScrollableSheet.
/// Triggered from Profile screen via settings icon.
class SettingsSheet extends ConsumerWidget {
  const SettingsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SettingsSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeControllerProvider);
    final isDark = themeMode == ThemeMode.dark;
    final userProfileAsync = ref.watch(userStatsStreamProvider);
    final authUserAsync = ref.watch(authStateChangesProvider);
    final userProfile = userProfileAsync.value;
    final authUser = authUserAsync.value;
    final userSettings = userProfile?.settings ?? const UserSettings();

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark.withValues(alpha: 0.95),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Column(
                children: [
                  // Handle
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Settings',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textMainDark,
                              ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Gap(8),

                  // Content
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        // Profile Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.backgroundDark,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: AppTheme.primary,
                                child: Text(
                                  (authUser?.email.isNotEmpty ?? false)
                                      ? authUser!.email[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const Gap(16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      authUser?.displayName ?? 'Emerge User',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    Text(
                                      authUser?.email ?? '',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppTheme.textSecondaryDark,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Gap(24),

                        // Appearance
                        _SectionHeader(title: 'Appearance'),
                        const Gap(8),
                        _SettingsTile(
                          icon: Icons.dark_mode_outlined,
                          title: 'Dark Mode',
                          trailing: Switch(
                            value: isDark,
                            onChanged: (_) {
                              ref
                                  .read(themeControllerProvider.notifier)
                                  .toggleTheme();
                            },
                            activeTrackColor: AppTheme.primary,
                          ),
                        ),
                        const Gap(16),

                        // Notifications
                        _SectionHeader(title: 'Notifications'),
                        const Gap(8),
                        _SettingsTile(
                          icon: Icons.notifications_outlined,
                          title: 'Push Notifications',
                          trailing: Switch(
                            value: userSettings.notificationsEnabled,
                            onChanged: (value) {
                              _updateSettings(
                                context,
                                ref,
                                userProfile,
                                userSettings.copyWith(
                                  notificationsEnabled: value,
                                ),
                              );
                            },
                            activeTrackColor: AppTheme.primary,
                          ),
                        ),
                        _SettingsTile(
                          icon: Icons.tune,
                          title: 'Notification Preferences',
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    const NotificationSettingsScreen(),
                              ),
                            );
                          },
                        ),
                        const Gap(16),

                        // Integrations
                        _SectionHeader(title: 'Integrations'),
                        const Gap(8),
                        _SettingsTile(
                          icon: Icons.favorite_border,
                          title: 'HealthKit',
                          subtitle: userSettings.healthKitConnected
                              ? 'Connected'
                              : 'Not Connected',
                          trailing: Switch(
                            value: userSettings.healthKitConnected,
                            onChanged: (value) {
                              _updateSettings(
                                context,
                                ref,
                                userProfile,
                                userSettings.copyWith(
                                  healthKitConnected: value,
                                ),
                              );
                            },
                            activeTrackColor: AppTheme.primary,
                          ),
                        ),
                        const Gap(16),

                        // Account Actions
                        _SectionHeader(title: 'Account'),
                        const Gap(8),
                        _SettingsTile(
                          icon: Icons.lock_outline,
                          title: 'Change Password',
                          onTap: () async {
                            if (authUser?.email != null) {
                              await ref
                                  .read(authRepositoryProvider)
                                  .sendPasswordResetEmail(authUser!.email);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Password reset email sent'),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                        _SettingsTile(
                          icon: Icons.logout,
                          title: 'Sign Out',
                          titleColor: EmergeColors.coral,
                          onTap: () async {
                            Navigator.pop(context);
                            await ref.read(authRepositoryProvider).signOut();
                          },
                        ),
                        const Gap(32),

                        // App Info
                        Center(
                          child: Text(
                            'Emerge v1.0.0',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppTheme.textSecondaryDark),
                          ),
                        ),
                        const Gap(24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _updateSettings(
    BuildContext context,
    WidgetRef ref,
    UserProfile? userProfile,
    UserSettings settings,
  ) {
    if (userProfile != null) {
      ref
          .read(userStatsRepositoryProvider)
          .saveUserStats(userProfile.copyWith(settings: settings));
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: AppTheme.textSecondaryDark,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? titleColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.titleColor,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = titleColor ?? EmergeColors.teal;
    return Material(
      color: AppTheme.backgroundDark,
      borderRadius: BorderRadius.circular(12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: titleColor ?? AppTheme.textMainDark,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondaryDark,
                ),
              )
            : null,
        trailing:
            trailing ??
            (onTap != null ? const Icon(Icons.chevron_right) : null),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
