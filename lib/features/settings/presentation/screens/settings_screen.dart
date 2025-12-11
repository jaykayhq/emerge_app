import 'package:emerge_app/core/theme/theme_provider.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/settings/presentation/screens/notification_settings_screen.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/gamification/data/repositories/user_stats_repository.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
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
    final userProfile = userProfileAsync.value;
    final currentTheme = userProfile?.worldTheme ?? 'Default';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Settings',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            _buildProfileHeader(context),
            const SizedBox(height: 32),

            // Account Section
            _buildSectionHeader(context, 'Account'),
            _buildSectionContainer(context, [
              _buildListTile(
                context,
                Icons.person_outline,
                'Manage Profile',
                onTap: () {},
              ),
              _buildListTile(
                context,
                Icons.email_outlined,
                'Email',
                subtitle: 'aveline@emerge.app',
                onTap: () {},
              ),
              _buildListTile(
                context,
                Icons.lock_outline,
                'Change Password',
                onTap: () {},
              ),
              _buildListTile(
                context,
                Icons.card_membership,
                'Manage Subscription',
                trailingText: 'Pro',
                onTap: () {},
              ),
            ]),
            const SizedBox(height: 24),

            // Notifications Section
            _buildSectionHeader(context, 'Notifications'),
            _buildSectionContainer(context, [
              _buildListTile(
                context,
                Icons.notifications_outlined,
                'Notification Settings',
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
              _buildListTile(
                context,
                Icons.favorite_outline,
                'HealthKit',
                trailingText: 'Connected',
                onTap: () {},
              ),
              _buildListTile(
                context,
                Icons.timer_outlined,
                'Screen Time',
                trailingText: 'Not Connected',
                onTap: () {},
              ),
              _buildListTile(
                context,
                Icons.download_outlined,
                'Export Data',
                onTap: () {},
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
                    color: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.palette_outlined,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                title: const Text(
                  'Dark Mode',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                value: isDark,
                onChanged: (value) {
                  ref.read(themeControllerProvider.notifier).toggleTheme();
                },
                activeTrackColor: Theme.of(context).primaryColor,
              ),
              _buildListTile(
                context,
                Icons.volume_up_outlined,
                'Sounds & Haptics',
                onTap: () {},
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
                Icons.help_outline,
                'Help & Support',
                onTap: () {},
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
                          builder: (context) =>
                              const Center(child: CircularProgressIndicator()),
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
                            SnackBar(content: Text('Error logging out: $e')),
                          );
                        }
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(
                        color: Colors.red.withValues(alpha: 0.5),
                      ),
                      foregroundColor: Colors.red,
                    ),
                    child: const Text(
                      'Log Out',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Version 1.0.0',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: const DecorationImage(
              image: NetworkImage(
                "https://lh3.googleusercontent.com/aida-public/AB6AXuDXX4DMI3PNwoIobdv3M0kHgySqlyZuCXQEGQUgdJXpA5mwbsKHJvmSF_b8U0bSP4T7IS2zTiDIyJ9gCSiF0SkdVecWazlJDsnOAPPdyk9lJCVmrLkFLcrTworovRjgOLzyIAZjjoovH_YzaJ70lURVr4scEgCe07BzXocj2ilEZVNMjQWyTtI4NEauhJcPqduprhFz6Y_sThtXB6SxzHb50w1-mQLsQpJV7Mu5oJ195vsfhJsynTZuOFfzHPu1JDpmL_r2-5RENX0",
              ),
              fit: BoxFit.cover,
            ),
            color: Colors.grey[300],
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aveline',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              'Level 12 Paladin',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSectionContainer(BuildContext context, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
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
          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Theme.of(context).primaryColor),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null)
            Text(trailingText, style: const TextStyle(color: Colors.grey)),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: Colors.grey),
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
        return SimpleDialog(
          title: const Text('Select World Theme'),
          children: [
            SimpleDialogOption(
              onPressed: () {
                _updateWorldTheme(context, ref, profile, null);
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text('Default (Archetype)'),
              ),
            ),
            SimpleDialogOption(
              onPressed: () {
                _updateWorldTheme(context, ref, profile, 'forest');
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text('Forest'),
              ),
            ),
            SimpleDialogOption(
              onPressed: () {
                _updateWorldTheme(context, ref, profile, 'city');
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text('City'),
              ),
            ),
          ],
        );
      },
    );
  }

  void _updateWorldTheme(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
    String? theme,
  ) async {
    Navigator.pop(context);
    final updatedProfile = profile.copyWith(worldTheme: theme);
    await ref.read(userStatsRepositoryProvider).saveUserStats(updatedProfile);
  }
}
