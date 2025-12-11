import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _allowAll = true;
  bool _habitReminders = true;
  bool _streakWarnings = true;
  bool _aiInsights = true;
  bool _communityUpdates = false;
  bool _rewards = true;
  bool _sound = true;
  bool _vibration = true;
  bool _dnd = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Master Toggle
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.notifications_active, color: AppTheme.primary),
                const Gap(16),
                const Expanded(
                  child: Text(
                    'Allow All Notifications',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Switch(
                  value: _allowAll,
                  onChanged: (val) => setState(() => _allowAll = val),
                  activeThumbColor: AppTheme.primary,
                ),
              ],
            ),
          ),
          const Gap(24),

          if (_allowAll) ...[
            _buildSectionHeader('Notification Types'),
            _buildSectionContainer([
              _buildSwitchTile(
                'Habit Reminders',
                'Get nudged to complete your daily tasks',
                _habitReminders,
                (val) => setState(() => _habitReminders = val),
              ),
              _buildSwitchTile(
                'Streak Warnings',
                'Alerts when you\'re about to lose a streak',
                _streakWarnings,
                (val) => setState(() => _streakWarnings = val),
              ),
              _buildSwitchTile(
                'AI-Powered Insights',
                'Daily analysis and coaching tips',
                _aiInsights,
                (val) => setState(() => _aiInsights = val),
              ),
              _buildSwitchTile(
                'Community Updates',
                'Friend activity and challenge alerts',
                _communityUpdates,
                (val) => setState(() => _communityUpdates = val),
              ),
              _buildSwitchTile(
                'Rewards & Achievements',
                'Level ups and badge unlocks',
                _rewards,
                (val) => setState(() => _rewards = val),
              ),
            ]),
            const Gap(24),

            _buildSectionHeader('General Settings'),
            _buildSectionContainer([
              _buildSwitchTile(
                'Notification Sound',
                null,
                _sound,
                (val) => setState(() => _sound = val),
              ),
              _buildSwitchTile(
                'Vibration',
                null,
                _vibration,
                (val) => setState(() => _vibration = val),
              ),
              _buildSwitchTile(
                'Do Not Disturb',
                'Silence notifications during sleep hours',
                _dnd,
                (val) => setState(() => _dnd = val),
              ),
            ]),
          ],
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
          color: Colors.grey[500],
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
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            )
          : null,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppTheme.primary,
        activeTrackColor: AppTheme.primary.withValues(alpha: 0.3),
        inactiveThumbColor: Colors.grey,
        inactiveTrackColor: Colors.grey.withValues(alpha: 0.3),
      ),
    );
  }
}
