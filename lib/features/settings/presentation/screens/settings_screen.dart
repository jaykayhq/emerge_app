import 'dart:ui';
import 'package:emerge_app/core/constants/gamification_constants.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/core/theme/theme_provider.dart';
import 'package:emerge_app/features/auth/domain/entities/auth_user.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/gamification/data/repositories/user_stats_repository.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/settings/presentation/screens/notification_settings_screen.dart';
import 'package:emerge_app/features/settings/presentation/providers/digital_wellbeing_provider.dart';
import 'package:emerge_app/features/tutorial/presentation/providers/tutorial_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeControllerProvider);
    final isDark = themeMode == ThemeMode.dark;
    final userProfileAsync = ref.watch(userStatsStreamProvider);
    final authUserAsync = ref.watch(authStateChangesProvider);
    final userProfile = userProfileAsync.value;
    final authUser = authUserAsync.value;

    final currentTheme = userProfile?.worldTheme ?? 'Default';
    final userSettings = userProfile?.settings ?? const UserSettings();
    final wellbeingAsync = ref.watch(digitalWellbeingProvider);

    return Scaffold(
      backgroundColor: EmergeColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textMainDark),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Settings',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.textMainDark,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: HexMeshBackground()),
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Header
                if (authUser != null && userProfile != null)
                  _buildProfileHeader(context, authUser, userProfile),
                const SizedBox(height: 32),

                // Account Section
                _buildSectionHeader(context, 'Account'),
                _buildSectionContainer(context, [
                  _buildListTile(
                    context,
                    Icons.edit_outlined,
                    'Edit Name',
                    onTap: () => _showEditNameDialog(context, ref, authUser),
                  ),
                  _buildListTile(
                    context,
                    Icons.email_outlined,
                    'Email',
                    subtitle: authUser?.email ?? 'No email',
                    onTap:
                        () {}, // Email usually not editable directly without re-auth
                  ),
                  _buildListTile(
                    context,
                    Icons.lock_outline,
                    'Change Password',
                    onTap: () async {
                      if (authUser?.email != null) {
                        final result = await ref
                            .read(authRepositoryProvider)
                            .sendPasswordResetEmail(authUser!.email);
                        if (context.mounted) {
                          result.fold(
                            (
                              failure,
                            ) => ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Error sending reset email: ${failure.message}',
                                ),
                              ),
                            ),
                            (_) => ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Password reset email sent'),
                              ),
                            ),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('No email address found'),
                          ),
                        );
                      }
                    },
                  ),
                  _buildListTile(
                    context,
                    Icons.card_membership,
                    'Manage Subscription',
                    trailingText: 'Free',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Premium features coming soon!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ]),
                const SizedBox(height: 24),

                // Notifications Section
                _buildSectionHeader(context, 'Notifications'),
                _buildSectionContainer(context, [
                  SwitchListTile(
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: EmergeColors.teal.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.notifications_outlined,
                        color: EmergeColors.teal,
                      ),
                    ),
                    title: Text(
                      'Enable Notifications',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textMainDark,
                      ),
                    ),
                    value: userSettings.notificationsEnabled,
                    onChanged: (value) {
                      _updateSettings(
                        context,
                        ref,
                        userProfile,
                        userSettings.copyWith(notificationsEnabled: value),
                      );
                    },
                    activeThumbColor: EmergeColors.teal,
                    activeTrackColor: EmergeColors.teal.withValues(alpha: 0.5),
                    tileColor: AppTheme.surfaceDark,
                  ),
                  _buildListTile(
                    context,
                    Icons.settings_outlined,
                    'Notification Preferences',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const NotificationSettingsScreen(),
                        ),
                      );
                    },
                  ),
                ]),
                const SizedBox(height: 24),

                // Integrations & Data
                _buildSectionHeader(context, 'Integrations & Data'),
                _buildSectionContainer(context, [
                  wellbeingAsync.when(
                    data: (wellbeingState) => SwitchListTile(
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: EmergeColors.teal.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.favorite_outline,
                          color: EmergeColors.teal,
                        ),
                      ),
                      title: Text(
                        'Google Fit / Health Connect',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textMainDark,
                        ),
                      ),
                      subtitle: Text(
                        wellbeingState.isGoogleFitConnected
                            ? 'Connected'
                            : 'Not Connected',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondaryDark,
                        ),
                      ),
                      value: wellbeingState.isGoogleFitConnected,
                      onChanged: (value) async {
                        try {
                          await ref
                              .read(digitalWellbeingProvider.notifier)
                              .toggleGoogleFit(value);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  value
                                      ? 'Connected to Google Fit'
                                      : 'Disconnected from Google Fit',
                                ),
                                backgroundColor: EmergeColors.teal,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      },
                      activeThumbColor: EmergeColors.teal,
                      activeTrackColor: EmergeColors.teal.withValues(
                        alpha: 0.5,
                      ),
                      tileColor: AppTheme.surfaceDark,
                    ),
                    loading: () => const ListTile(
                      title: Text(
                        'Google Fit / Health Connect',
                        style: TextStyle(color: Colors.white),
                      ),
                      trailing: CircularProgressIndicator(),
                      tileColor: AppTheme.surfaceDark,
                    ),
                    error: (err, stack) => ListTile(
                      title: const Text(
                        'Google Fit / Health Connect',
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: const Text(
                        'Error loading status',
                        style: TextStyle(color: Colors.red),
                      ),
                      tileColor: AppTheme.surfaceDark,
                    ),
                  ),
                  wellbeingAsync.when(
                    data: (wellbeingState) => SwitchListTile(
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: EmergeColors.teal.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.timer_outlined,
                          color: EmergeColors.teal,
                        ),
                      ),
                      title: Text(
                        'Screen Time API',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textMainDark,
                        ),
                      ),
                      subtitle: Text(
                        wellbeingState.isScreenTimeConnected
                            ? 'Connected'
                            : 'Not Connected',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondaryDark,
                        ),
                      ),
                      value: wellbeingState.isScreenTimeConnected,
                      onChanged: (value) async {
                        try {
                          await ref
                              .read(digitalWellbeingProvider.notifier)
                              .toggleScreenTime(value);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  value
                                      ? 'Connected to Screen Time API'
                                      : 'Disconnected from Screen Time API',
                                ),
                                backgroundColor: EmergeColors.teal,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      },
                      activeThumbColor: EmergeColors.teal,
                      activeTrackColor: EmergeColors.teal.withValues(
                        alpha: 0.5,
                      ),
                      tileColor: AppTheme.surfaceDark,
                    ),
                    loading: () => const ListTile(
                      title: Text(
                        'Screen Time API',
                        style: TextStyle(color: Colors.white),
                      ),
                      trailing: CircularProgressIndicator(),
                      tileColor: AppTheme.surfaceDark,
                    ),
                    error: (err, stack) => ListTile(
                      title: const Text(
                        'Screen Time API',
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: const Text(
                        'Error loading status',
                        style: TextStyle(color: Colors.red),
                      ),
                      tileColor: AppTheme.surfaceDark,
                    ),
                  ),
                  _buildListTile(
                    context,
                    Icons.download_outlined,
                    'Export Data',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Exporting data...')),
                      );
                    },
                  ),
                ]),
                const SizedBox(height: 24),

                // General Section
                _buildSectionHeader(context, 'General'),
                _buildSectionContainer(context, [
                  SwitchListTile(
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: EmergeColors.teal.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.palette_outlined,
                        color: EmergeColors.teal,
                      ),
                    ),
                    title: Text(
                      'Dark Mode',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textMainDark,
                      ),
                    ),
                    value: isDark,
                    onChanged: (value) {
                      ref.read(themeControllerProvider.notifier).toggleTheme();
                    },
                    activeThumbColor: EmergeColors.teal,
                    activeTrackColor: EmergeColors.teal.withValues(alpha: 0.5),
                    tileColor: AppTheme.surfaceDark,
                  ),
                  SwitchListTile(
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: EmergeColors.teal.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.volume_up_outlined,
                        color: EmergeColors.teal,
                      ),
                    ),
                    title: Text(
                      'Sounds & Haptics',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textMainDark,
                      ),
                    ),
                    value: userSettings.soundsEnabled,
                    onChanged: (value) {
                      _updateSettings(
                        context,
                        ref,
                        userProfile,
                        userSettings.copyWith(soundsEnabled: value),
                      );
                    },
                    activeThumbColor: EmergeColors.teal,
                    activeTrackColor: EmergeColors.teal.withValues(alpha: 0.5),
                    tileColor: AppTheme.surfaceDark,
                  ),
                  _buildListTile(
                    context,
                    Icons.map_outlined,
                    'World Theme',
                    trailingText: currentTheme == 'forest'
                        ? 'Forest'
                        : currentTheme == 'city'
                        ? 'City'
                        : 'Default',
                    onTap: () {
                      _showThemeSelectionDialog(context, ref, userProfile);
                    },
                  ),
                ]),
                const SizedBox(height: 24),

                // Support & Legal
                _buildSectionHeader(context, 'Support & Legal'),
                _buildSectionContainer(context, [
                  _buildListTile(
                    context,
                    Icons.replay_outlined,
                    'Redo Tutorials',
                    onTap: () {
                      _showRedoTutorialsDialog(context, ref);
                    },
                  ),
                  _buildListTile(
                    context,
                    Icons.help_outline,
                    'Help & Support (FAQ)',
                    onTap: () {
                      _showFaqDialog(context);
                    },
                  ),
                  _buildListTile(
                    context,
                    Icons.privacy_tip_outlined,
                    'Privacy Policy',
                    onTap: () {},
                  ),
                  _buildListTile(
                    context,
                    Icons.description_outlined,
                    'Terms of Service',
                    onTap: () {},
                  ),
                ]),
                const SizedBox(height: 32),

                // Action Buttons
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: Consumer(
                    builder: (context, ref, child) {
                      return OutlinedButton(
                        onPressed: () async {
                          try {
                            // Show loading indicator
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );

                            await ref.read(authRepositoryProvider).signOut();

                            if (context.mounted) {
                              Navigator.of(context).pop(); // Dismiss loading
                              // Router will handle redirect
                            }
                          } catch (e) {
                            if (context.mounted) {
                              Navigator.of(context).pop(); // Dismiss loading
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error logging out: $e'),
                                ),
                              );
                            }
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: const BorderSide(color: EmergeColors.coral),
                          foregroundColor: EmergeColors.coral,
                        ),
                        child: Text(
                          'Log Out',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: EmergeColors.coral,
                              ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'Version 1.0.0',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondaryDark,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    AuthUser authUser,
    UserProfile profile,
  ) {
    final avatarStats = profile.avatarStats;
    final currentLevel = avatarStats.level;
    final totalXp = avatarStats.totalXp;
    final xpPerLevel = GamificationConstants.xpPerLevel;
    final xpForCurrentLevel = (currentLevel - 1) * xpPerLevel;
    final xpForNextLevel = currentLevel * xpPerLevel;
    final xpProgress = totalXp - xpForCurrentLevel;
    final xpNeeded = xpForNextLevel - totalXp;
    final progressPercent = (xpProgress / xpPerLevel).clamp(0.0, 1.0);

    return Row(
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: EmergeColors.teal.withValues(alpha: 0.2),
            ),
            child: const Icon(Icons.person, size: 40, color: EmergeColors.teal),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                authUser.displayName ?? 'Jae Kay',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textMainDark,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    'Level $currentLevel',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: EmergeColors.teal,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: EmergeColors.teal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      profile.characterClass ?? 'Novice',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: EmergeColors.teal,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // XP Progress Bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'XP',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondaryDark,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '$xpProgress / $xpPerLevel',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondaryDark,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Stack(
                    children: [
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceDark,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: progressPercent,
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [EmergeColors.teal, EmergeColors.coral],
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$xpNeeded XP to next level • Total: $totalXp XP',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondaryDark,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppTheme.textSecondaryDark,
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSectionContainer(BuildContext context, List<Widget> children) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Column(children: children),
        ),
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context,
    IconData icon,
    String title, {
    String? subtitle,
    String? trailingText,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: EmergeColors.teal.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: EmergeColors.teal),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
          color: AppTheme.textMainDark,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondaryDark,
              ),
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null)
            Text(
              trailingText,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondaryDark,
              ),
            ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: AppTheme.textSecondaryDark),
        ],
      ),
    );
  }

  void _showThemeSelectionDialog(
    BuildContext context,
    WidgetRef ref,
    UserProfile? profile,
  ) {
    if (profile == null) return;
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: AppTheme.surfaceDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select World Theme',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.textMainDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose the visual style for your world',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondaryDark,
                  ),
                ),
                const SizedBox(height: 20),
                _buildThemeOption(
                  context,
                  ref,
                  profile,
                  'city',
                  'Futuristic City',
                  'Neon-lit cyberpunk metropolis',
                  Icons.location_city,
                  Colors.cyan,
                ),
                _buildThemeOption(
                  context,
                  ref,
                  profile,
                  'forest',
                  'Enchanted Forest',
                  'Enchanted Forest sanctuary',
                  Icons.forest,
                  Colors.green,
                ),
                _buildThemeOption(
                  context,
                  ref,
                  profile,
                  'sanctuary',
                  'Floating Sanctuary',
                  'Serene sky islands',
                  Icons.cloud,
                  Colors.purple,
                ),
                _buildThemeOption(
                  context,
                  ref,
                  profile,
                  null,
                  'Default (Archetype)',
                  'Based on your character',
                  Icons.auto_awesome,
                  EmergeColors.teal,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
    String? themeValue,
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    final currentTheme = profile.worldTheme;
    final isSelected = currentTheme == themeValue;

    return GestureDetector(
      onTap: () => _updateWorldTheme(context, ref, profile, themeValue),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textMainDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondaryDark,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: color, size: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _updateWorldTheme(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
    String? theme,
  ) async {
    Navigator.pop(context);
    if (profile.uid.isEmpty) return; // Prevent saving with empty UID
    final updatedProfile = profile.copyWith(worldTheme: theme);
    await ref.read(userStatsRepositoryProvider).saveUserStats(updatedProfile);
  }

  Future<void> _updateSettings(
    BuildContext context,
    WidgetRef ref,
    UserProfile? profile,
    UserSettings settings,
  ) async {
    if (profile == null || profile.uid.isEmpty) return;
    final updatedProfile = profile.copyWith(settings: settings);
    await ref.read(userStatsRepositoryProvider).saveUserStats(updatedProfile);
  }

  void _showEditNameDialog(
    BuildContext context,
    WidgetRef ref,
    AuthUser? user,
  ) {
    if (user == null) return;
    final controller = TextEditingController(text: user.displayName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: Text(
          'Edit Name',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: AppTheme.textMainDark),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: AppTheme.textMainDark),
          decoration: InputDecoration(
            labelText: 'Display Name',
            labelStyle: const TextStyle(color: AppTheme.textSecondaryDark),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppTheme.textSecondaryDark),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: EmergeColors.teal),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.textSecondaryDark,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              await ref
                  .read(authRepositoryProvider)
                  .updateDisplayName(controller.text);
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: Text(
              'Save',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: EmergeColors.teal),
            ),
          ),
        ],
      ),
    );
  }

  void _showRedoTutorialsDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text(
          'Reset Tutorials?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This will reset all onboarding tutorials so they appear again on each screen.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'CANCEL',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(tutorialProvider.notifier).resetTutorials();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tutorials reset successfully!')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: EmergeColors.teal),
            child: const Text(
              'RESET',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFaqDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text(
          'Frequently Asked Questions',
          style: TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              _buildFaqItem(
                'What is an Archetype?',
                'Archetypes are identity templates that define your growth path and visual evolution.',
              ),
              _buildFaqItem(
                'How do I level up?',
                'Complete your daily habits! Each habit earns you XP. Every 500 XP increases your level.',
              ),
              _buildFaqItem(
                'What is World Decay?',
                'If you miss your habits for multiple days, your inner world begins to fade. Consistency is key!',
              ),
              _buildFaqItem(
                'How do I unlock nodes?',
                'Nodes in the World Map are unlocked by reaching the required level and maintaining consistency.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'CLOSE',
              style: TextStyle(color: EmergeColors.teal),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
              color: EmergeColors.teal,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            answer,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const Divider(color: Colors.white10, height: 16),
        ],
      ),
    );
  }
}
