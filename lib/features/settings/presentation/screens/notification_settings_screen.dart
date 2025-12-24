import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/gamification/data/repositories/user_stats_repository.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userStatsStreamProvider);
    final userProfile = userProfileAsync.value;
    final settings = userProfile?.settings ?? const UserSettings();

    // Use settings from profile
    final allowAll = settings.notificationsEnabled;
    final habitReminders = settings.habitReminders;
    final streakWarnings = settings.streakWarnings;
    final aiInsights = settings.aiInsights;
    final communityUpdates = settings.communityUpdates;
    final rewards = settings.rewardsUpdates;
    final sound = settings.soundsEnabled; // Shared with general settings
    final vibration = settings.hapticsEnabled; // Shared with general settings
    final dnd = settings.doNotDisturb;

    return Scaffold(
      backgroundColor: EmergeColors.background,
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppTheme.textMainDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textMainDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: HexMeshBackground()),
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Master Toggle
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: EmergeColors.hexLine),
                ),
                child: Row(
                  children: [
                    Icon(Icons.notifications_active, color: EmergeColors.teal),
                    const Gap(16),
                    const Expanded(
                      child: Text(
                        'Allow All Notifications',
                        style: TextStyle(
                          color: AppTheme.textMainDark,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Switch(
                      value: allowAll,
                      onChanged: (val) => _updateSettings(
                        context,
                        ref,
                        userProfile,
                        settings.copyWith(notificationsEnabled: val),
                      ),
                      activeThumbColor: EmergeColors.teal,
                      activeTrackColor: EmergeColors.teal.withValues(
                        alpha: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(24),

              if (allowAll) ...[
                _buildSectionHeader('Notification Types'),
                _buildSectionContainer([
                  _buildSwitchTile(
                    'Habit Reminders',
                    'Get nudged to complete your daily tasks',
                    habitReminders,
                    (val) => _updateSettings(
                      context,
                      ref,
                      userProfile,
                      settings.copyWith(habitReminders: val),
                    ),
                  ),
                  _buildSwitchTile(
                    'Streak Warnings',
                    'Alerts when you\'re about to lose a streak',
                    streakWarnings,
                    (val) => _updateSettings(
                      context,
                      ref,
                      userProfile,
                      settings.copyWith(streakWarnings: val),
                    ),
                  ),
                  _buildSwitchTile(
                    'AI-Powered Insights',
                    'Daily analysis and coaching tips',
                    aiInsights,
                    (val) => _updateSettings(
                      context,
                      ref,
                      userProfile,
                      settings.copyWith(aiInsights: val),
                    ),
                  ),
                  _buildSwitchTile(
                    'Community Updates',
                    'Friend activity and challenge alerts',
                    communityUpdates,
                    (val) => _updateSettings(
                      context,
                      ref,
                      userProfile,
                      settings.copyWith(communityUpdates: val),
                    ),
                  ),
                  _buildSwitchTile(
                    'Rewards & Achievements',
                    'Level ups and badge unlocks',
                    rewards,
                    (val) => _updateSettings(
                      context,
                      ref,
                      userProfile,
                      settings.copyWith(rewardsUpdates: val),
                    ),
                  ),
                ]),
                const Gap(24),

                _buildSectionHeader('General Settings'),
                _buildSectionContainer([
                  _buildSwitchTile(
                    'Notification Sound',
                    null,
                    sound,
                    (val) => _updateSettings(
                      context,
                      ref,
                      userProfile,
                      settings.copyWith(soundsEnabled: val),
                    ),
                  ),
                  _buildSwitchTile(
                    'Vibration',
                    null,
                    vibration,
                    (val) => _updateSettings(
                      context,
                      ref,
                      userProfile,
                      settings.copyWith(hapticsEnabled: val),
                    ),
                  ),
                  _buildSwitchTile(
                    'Do Not Disturb',
                    'Silence notifications during sleep hours',
                    dnd,
                    (val) => _updateSettings(
                      context,
                      ref,
                      userProfile,
                      settings.copyWith(doNotDisturb: val),
                    ),
                  ),
                ]),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: AppTheme.textSecondaryDark,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSectionContainer(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EmergeColors.hexLine),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String? subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(
          color: AppTheme.textMainDark,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(color: AppTheme.textSecondaryDark),
            )
          : null,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: EmergeColors.teal,
        activeTrackColor: EmergeColors.teal.withValues(alpha: 0.5),
        inactiveThumbColor: Colors.grey,
        inactiveTrackColor: Colors.grey.withValues(alpha: 0.3),
      ),
    );
  }

  Future<void> _updateSettings(
    BuildContext context,
    WidgetRef ref,
    UserProfile? profile,
    UserSettings settings,
  ) async {
    if (profile == null) return;
    final updatedProfile = profile.copyWith(settings: settings);
    await ref.read(userStatsRepositoryProvider).saveUserStats(updatedProfile);
  }
}
