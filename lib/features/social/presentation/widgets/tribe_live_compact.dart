import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';

enum _LiveTab { feed, leaderboard }

/// Compact two-tab segmented block for the lobby.
///
/// - LIVE FEED: 3 most-recent entries from [clubActivityProvider].
/// - LEADERBOARD: top 3 entries from [worldLeaderboardProvider].
class TribeLiveCompact extends ConsumerStatefulWidget {
  final String clubId;
  final UserProfile profile;

  const TribeLiveCompact({
    super.key,
    required this.clubId,
    required this.profile,
  });

  @override
  ConsumerState<TribeLiveCompact> createState() => _TribeLiveCompactState();
}

class _TribeLiveCompactState extends ConsumerState<TribeLiveCompact> {
  _LiveTab _tab = _LiveTab.feed;

  static String _iconForType(String type) {
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

  static String _actionForActivity(String type, Map<String, dynamic> data) {
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
        return 'committed to "$habitTitle" ⚔️';
      default:
        return 'made a move';
    }
  }

  static String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final now = DateTime.now();
    final activityTime = timestamp.toDate();
    final diff = now.difference(activityTime);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${activityTime.day}/${activityTime.month}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Row(
            children: [
              Text(
                'TRIBE PULSE',
                style: TextStyle(
                  color: EmergeColors.nebulaPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _SegmentedControl(
            leftLabel: 'LIVE FEED',
            rightLabel: 'LEADERBOARD',
            selected: _tab,
            onChanged: (next) => setState(() => _tab = next),
          ),
        ),
        const Gap(12),
        if (_tab == _LiveTab.feed)
          _LiveFeedBlock(
            clubId: widget.clubId,
            iconForType: _iconForType,
            actionForActivity: _actionForActivity,
            formatTimestamp: _formatTimestamp,
          )
        else
          _LeaderboardBlock(),
      ],
    );
  }
}

class _SegmentedControl extends StatelessWidget {
  final String leftLabel;
  final String rightLabel;
  final _LiveTab selected;
  final ValueChanged<_LiveTab> onChanged;

  const _SegmentedControl({
    required this.leftLabel,
    required this.rightLabel,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    Widget pill({required bool isSelected, required String label, required VoidCallback onTap}) {
      return Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? EmergeColors.nebulaPrimaryContainer.withValues(alpha: 0.18)
                  : Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? EmergeColors.nebulaPrimaryContainer.withValues(alpha: 0.6)
                    : Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? EmergeColors.nebulaPrimary
                    : Colors.white60,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        pill(
          isSelected: selected == _LiveTab.feed,
          label: leftLabel,
          onTap: () => onChanged(_LiveTab.feed),
        ),
        const SizedBox(width: 8),
        pill(
          isSelected: selected == _LiveTab.leaderboard,
          label: rightLabel,
          onTap: () => onChanged(_LiveTab.leaderboard),
        ),
      ],
    );
  }
}

class _LiveFeedBlock extends ConsumerWidget {
  final String clubId;
  final String Function(String) iconForType;
  final String Function(String, Map<String, dynamic>) actionForActivity;
  final String Function(Timestamp?) formatTimestamp;

  const _LiveFeedBlock({
    required this.clubId,
    required this.iconForType,
    required this.actionForActivity,
    required this.formatTimestamp,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(clubActivityProvider(clubId));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: activityAsync.when(
        data: (activities) {
          if (activities.isEmpty) return const _EmptyTab('No activity yet.');
          final top = activities.take(3).toList();
          return Column(
            children: [
              for (final activity in top)
                _ActivityRow(
                  icon: iconForType(activity['type'] as String? ?? 'unknown'),
                  text:
                      '${activity['userName'] ?? 'Someone'} ${actionForActivity(activity['type'] as String? ?? 'unknown', (activity['data'] as Map?)?.cast<String, dynamic>() ?? const {})}',
                  timestamp: formatTimestamp(
                    activity['timestamp'] is Timestamp
                        ? activity['timestamp'] as Timestamp
                        : null,
                  ),
                ),
              const Gap(8),
              _ViewMoreLink(
                label: 'View More',
                onTap: () => context.push('/social/activity?tribeId=$clubId'),
              ),
            ],
          );
        },
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        error: (_, _) => const _EmptyTab('Could not load activity.'),
      ),
    );
  }
}

class _LeaderboardBlock extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boardAsync = ref.watch(worldLeaderboardProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: boardAsync.when(
        data: (entries) {
          if (entries.isEmpty) return const _EmptyTab('Leaderboard is empty.');
          final top = entries.take(3).toList();
          return Column(
            children: [
              for (var i = 0; i < top.length; i++)
                _LeaderboardRow(
                  rank: i + 1,
                  tribeName: top[i].tribe.name,
                  xp: top[i].stats.totalXp,
                ),
              const Gap(8),
              _ViewMoreLink(
                label: 'View More',
                onTap: () => context.push('/social/leaderboard'),
              ),
            ],
          );
        },
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        error: (_, _) => const _EmptyTab('Could not load leaderboard.'),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final String icon;
  final String text;
  final String timestamp;

  const _ActivityRow({
    required this.icon,
    required this.text,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const Gap(10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
          if (timestamp.isNotEmpty)
            Text(
              timestamp,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 10,
              ),
            ),
        ],
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final int rank;
  final String tribeName;
  final int xp;

  const _LeaderboardRow({
    required this.rank,
    required this.tribeName,
    required this.xp,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: EmergeColors.nebulaPrimaryContainer.withValues(alpha: 0.2),
            ),
            alignment: Alignment.center,
            child: Text(
              '$rank',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const Gap(12),
          Expanded(
            child: Text(
              tribeName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            '$xp XP',
            style: TextStyle(
              color: EmergeColors.nebulaPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewMoreLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ViewMoreLink({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: onTap,
        child: Text(
          '$label →',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _EmptyTab extends StatelessWidget {
  final String message;

  const _EmptyTab(this.message);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ),
    );
  }
}
