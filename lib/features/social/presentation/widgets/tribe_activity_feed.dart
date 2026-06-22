import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gap/gap.dart';
import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_loading_skeleton.dart';
import 'package:emerge_app/core/presentation/widgets/app_error_widget.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';

class TribeActivitySection extends ConsumerWidget {
  final String? clubId;
  final bool isGlobal;

  const TribeActivitySection({super.key, this.clubId, this.isGlobal = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = isGlobal
        ? ref.watch(globalActivityProvider)
        : ref.watch(clubActivityProvider(clubId!));

    return activityAsync.when(
      data: (activities) {
        if (activities.isEmpty) {
          return const _EmptyState(
            message: 'No activity yet. Be the first to make a mark!',
            icon: Icons.history,
          );
        }

        return SingleChildScrollView(
          child: Column(
            children: activities.map((activity) {
              return TribeActivityTile(activity: activity);
            }).toList(),
          ),
        );
      },
      loading: () => const EmergeLoadingSkeleton(itemCount: 5),
      error: (error, _) => AppErrorWidget(
        message: 'Could not load activity',
        onRetry: () {
          if (isGlobal) {
            ref.invalidate(globalActivityProvider);
          } else {
            ref.invalidate(clubActivityProvider(clubId!));
          }
        },
      ),
    );
  }
}

class TribeActivityTile extends StatelessWidget {
  final Map<String, dynamic> activity;

  const TribeActivityTile({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    final type = activity['type'] as String? ?? 'unknown';
    final userName = activity['userName'] as String? ?? 'Someone';
    final data = activity['data'] as Map<String, dynamic>? ?? {};
    final actionText = _buildActionText(type, data);
    final Timestamp? timestamp;
    final rawTimestamp = activity['timestamp'];
    if (rawTimestamp is Timestamp) {
      timestamp = rawTimestamp;
    } else if (rawTimestamp is String) {
      timestamp = Timestamp.fromDate(DateTime.parse(rawTimestamp));
    } else {
      timestamp = null;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_getActivityIcon(type), style: const TextStyle(fontSize: 20)),
          const Gap(12),
          Expanded(
            child: Text(
              '$userName $actionText',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                height: 1.4,
              ),
            ),
          ),
          if (timestamp != null)
            Text(
              _formatTimestamp(timestamp),
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondaryDark.withValues(alpha: 0.6),
              ),
            ),
        ],
      ),
    );
  }

  String _buildActionText(String type, Map<String, dynamic> data) {
    switch (type) {
      case 'habit_complete':
        final title = data['habitTitle'] as String? ?? 'a habit';
        final streak = data['streakDay'] as int? ?? 0;
        return streak > 1
            ? 'completed $title (Day $streak 🔥)'
            : 'completed $title';
      case 'challenge_complete':
        final title = data['challengeTitle'] as String? ?? 'a challenge';
        return 'conquered $title 🏆';
      case 'level_up':
        final level = data['newLevel'] as int? ?? 0;
        return 'reached Level $level! 🎖️';
      case 'streak_milestone':
        final streak = data['streakDays'] as int? ?? 0;
        return 'hit a $streak-day streak! 🔥';
      case 'node_claim':
        final nodeName = data['nodeName'] as String? ?? 'a node';
        return 'claimed the $nodeName node 🏰';
      case 'badge_earned':
        final badgeName = data['badgeName'] as String? ?? 'a badge';
        return 'earned the "$badgeName" badge 🎖️';
      case 'partner_joined':
        final partnerName = data['partnerName'] as String? ?? 'someone';
        return 'formed an accountability bond with $partnerName 🤝';
      case 'contract_committed':
        final habitTitle = data['habitTitle'] as String? ?? 'a habit';
        return 'committed to "$habitTitle" with high stakes ⚔️';
      default:
        return 'made a move';
    }
  }

  String _getActivityIcon(String type) {
    switch (type) {
      case 'habit_complete':
        return '✅';
      case 'level_up':
        return '🎖️';
      case 'challenge_complete':
        return '🏆';
      case 'badge_earned':
        return '🎖️';
      case 'streak_milestone':
        return '🔥';
      case 'club_goal':
        return '🎯';
      case 'member_joined':
        return '👋';
      case 'node_claim':
        return '🏰';
      case 'partner_joined':
        return '🤝';
      case 'contract_committed':
        return '⚔️';
      default:
        return '📌';
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final activityTime = timestamp.toDate();
    final difference = now.difference(activityTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${activityTime.day}/${activityTime.month}';
    }
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;

  const _EmptyState({required this.message, this.icon = Icons.info_outline});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Colors.white38),
            const Gap(16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
