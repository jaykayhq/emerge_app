import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';

/// Sweatcoin-inspired Friends Leaderboard with time filters and rankings.
/// Now with Hybrid Accountability (Nudge/Challenge).
class FriendsLeaderboard extends StatefulWidget {
  final List<FriendRankEntry> friends;
  final VoidCallback? onAddFriend;
  final VoidCallback? onShareLink;
  final Function(FriendRankEntry, String)?
  onAction; // action: 'nudge' or 'challenge'

  const FriendsLeaderboard({
    super.key,
    required this.friends,
    this.onAddFriend,
    this.onShareLink,
    this.onAction,
  });

  @override
  State<FriendsLeaderboard> createState() => _FriendsLeaderboardState();
}

class _FriendsLeaderboardState extends State<FriendsLeaderboard> {
  int _selectedFilter = 0;
  final List<String> _filters = [
    'Today',
    'This Week',
    'This Month',
    '🔥 Streaks',
  ];

  @override
  Widget build(BuildContext context) {
    // Find "me" to determine relative actions
    final myEntry = widget.friends.cast<FriendRankEntry?>().firstWhere(
      (f) => f?.isYou == true,
      orElse: () => null,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Time Filters
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: List.generate(_filters.length, (index) {
              final isSelected = _selectedFilter == index;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(_filters[index]),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedFilter = index),
                  backgroundColor: AppTheme.surfaceDark,
                  selectedColor: AppTheme.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.black : AppTheme.textMainDark,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected
                          ? AppTheme.primary
                          : Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const Gap(20),

        // Leaderboard
        if (widget.friends.isEmpty)
          _EmptyFriendsState(onAddFriend: widget.onAddFriend)
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: widget.friends.length,
            separatorBuilder: (_, __) => const Gap(8),
            itemBuilder: (context, index) {
              final entry = widget.friends[index];
              // Determine action type
              String? actionType;
              if (!entry.isYou && myEntry != null) {
                if (entry.xp > myEntry.xp) {
                  actionType = 'challenge';
                } else {
                  actionType = 'nudge';
                }
              }

              return _FriendRankTile(
                rank: index + 1,
                entry: entry,
                actionType: actionType,
                onAction: widget.onAction != null
                    ? () => widget.onAction!(entry, actionType!)
                    : null,
              ).animate(delay: (50 * index).ms).fadeIn().slideX(begin: 0.1);
            },
          ),

        const Gap(24),

        // Add Friends Slots
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'ADD FRIENDS',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.textSecondaryDark,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const Gap(12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: List.generate(3, (index) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index < 2 ? 8 : 0),
                  child: _AddFriendSlot(onTap: widget.onAddFriend),
                ),
              );
            }),
          ),
        ),

        const Gap(24),

        // Invite Link Card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _InviteLinkCard(onShare: widget.onShareLink),
        ),
      ],
    );
  }
}

class FriendRankEntry {
  final String id;
  final String name;
  final String? avatarUrl;
  final int xp;
  final int streak;
  final bool isYou;

  const FriendRankEntry({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.xp,
    this.streak = 0,
    this.isYou = false,
  });
}

class _FriendRankTile extends StatelessWidget {
  final int rank;
  final FriendRankEntry entry;
  final String? actionType; // 'nudge' or 'challenge'
  final VoidCallback? onAction;

  const _FriendRankTile({
    required this.rank,
    required this.entry,
    this.actionType,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isTop3 = rank <= 3;
    final rankColors = [Colors.amber, Colors.grey.shade300, Colors.orange];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: entry.isYou
            ? AppTheme.primary.withValues(alpha: 0.1)
            : AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: entry.isYou
            ? Border.all(color: AppTheme.primary.withValues(alpha: 0.3))
            : null,
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isTop3 ? rankColors[rank - 1] : AppTheme.backgroundDark,
            ),
            child: Text(
              '$rank',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isTop3 ? Colors.black : AppTheme.textMainDark,
                fontSize: 14,
              ),
            ),
          ),
          const Gap(12),

          // Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
            backgroundImage: entry.avatarUrl != null
                ? NetworkImage(entry.avatarUrl!)
                : null,
            onBackgroundImageError: entry.avatarUrl != null ? (_, __) {} : null,
            child: entry.avatarUrl == null
                ? Text(
                    entry.name.isNotEmpty ? entry.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const Gap(12),

          // Name & Badge
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.isYou ? '${entry.name} (You)' : entry.name,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textMainDark,
                        ),
                      ),
                    ),
                    if (entry.streak > 0) ...[
                      const Gap(6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '🔥 ${entry.streak}',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  '${_formatNumber(entry.xp)} XP',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondaryDark,
                  ),
                ),
              ],
            ),
          ),

          // Action Button
          if (actionType != null)
            _ActionButton(type: actionType!, onTap: onAction),
        ],
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

class _ActionButton extends StatelessWidget {
  final String type; // 'nudge' or 'challenge'
  final VoidCallback? onTap;

  const _ActionButton({required this.type, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isNudge = type == 'nudge';
    final color = isNudge ? AppTheme.primary : Colors.redAccent;
    final icon = isNudge ? Icons.waving_hand : Icons.local_fire_department;
    final label = isNudge ? 'Nudge' : 'Challenge';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            const Gap(4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyFriendsState extends StatelessWidget {
  final VoidCallback? onAddFriend;

  const _EmptyFriendsState({this.onAddFriend});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: AppTheme.textSecondaryDark.withValues(alpha: 0.5),
          ),
          const Gap(16),
          Text(
            'No friends yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textSecondaryDark,
            ),
          ),
          const Gap(8),
          Text(
            'Add friends to see how you stack up!',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondaryDark),
          ),
          const Gap(24),
          ElevatedButton.icon(
            onPressed: onAddFriend,
            icon: const Icon(Icons.person_add),
            label: const Text('Add Friend'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddFriendSlot extends StatelessWidget {
  final VoidCallback? onTap;

  const _AddFriendSlot({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primary.withValues(alpha: 0.3),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: Icon(Icons.add, color: AppTheme.primary, size: 20),
            ),
            const Gap(4),
            Text(
              'Add',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InviteLinkCard extends StatelessWidget {
  final VoidCallback? onShare;

  const _InviteLinkCard({this.onShare});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primary.withValues(alpha: 0.15),
            AppTheme.secondary.withValues(alpha: 0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.link, color: AppTheme.primary),
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Personal Invite Link',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textMainDark,
                  ),
                ),
                const Gap(2),
                Text(
                  'Share and earn XP when friends join',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondaryDark,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onShare,
            icon: const Icon(Icons.share),
            color: AppTheme.primary,
          ),
        ],
      ),
    );
  }
}
