import 'package:emerge_app/core/presentation/widgets/growth_background.dart';
import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class AccountabilityScreen extends StatelessWidget {
  const AccountabilityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GrowthBackground(
      appBar: AppBar(
        title: const Text('Accountability'),
        backgroundColor: Colors.transparent,
      ),
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildInfoBanner(context),
          const Gap(24),
          _SectionHeader(title: 'Active Commitments'),
          const Gap(12),
          _ActiveChallengeCard(
            partnerName: 'Sarah Chen',
            challengeName: '30 Day Meditation Streak',
            progress: 0.4, // 12/30
            daysLeft: 18,
            wager: '\$5 Charity Donation',
            status: 'On Track',
          ),
          const Gap(24),
          _SectionHeader(title: 'Pending Requests'),
          const Gap(12),
          _PendingRequestCard(
            partnerName: 'Mike Johnson',
            challengeName: 'Race to 5k Steps',
            message: 'Bet you can\'t beat me today!',
            timeAgo: '2h ago',
          ),
          const Gap(24),
          _SectionHeader(title: 'Your Partners'),
          const Gap(12),
          _PartnerCard(name: 'Sarah Chen', streak: 12),
          const Gap(80),
        ],
      ),
    );
  }

  Widget _buildInfoBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppTheme.primary),
          const Gap(12),
          Expanded(
            child: Text(
              'Accountability increases success rates by 95%. Keep your promises!',
              style: TextStyle(color: AppTheme.textMainDark, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        letterSpacing: 1.1,
        color: AppTheme.textSecondaryDark,
      ),
    );
  }
}

class _ActiveChallengeCard extends StatelessWidget {
  final String partnerName;
  final String challengeName;
  final double progress;
  final int daysLeft;
  final String wager;
  final String status;

  const _ActiveChallengeCard({
    required this.partnerName,
    required this.challengeName,
    required this.progress,
    required this.daysLeft,
    required this.wager,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: AppTheme.primary,
                    child: Text(
                      partnerName[0],
                      style: const TextStyle(fontSize: 10, color: Colors.black),
                    ),
                  ),
                  const Gap(8),
                  Text(
                    'vs $partnerName',
                    style: TextStyle(
                      color: AppTheme.textSecondaryDark,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Gap(12),
          Text(
            challengeName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const Gap(8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(4),
          ),
          const Gap(8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$daysLeft days left',
                style: TextStyle(
                  color: AppTheme.textSecondaryDark,
                  fontSize: 12,
                ),
              ),
              Row(
                children: [
                  Icon(Icons.warning_amber, size: 12, color: Colors.redAccent),
                  const Gap(4),
                  Text(
                    wager,
                    style: TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PendingRequestCard extends StatelessWidget {
  final String partnerName;
  final String challengeName;
  final String message;
  final String timeAgo;

  const _PendingRequestCard({
    required this.partnerName,
    required this.challengeName,
    required this.message,
    required this.timeAgo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey,
                child: Text(partnerName[0]),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$partnerName challenged you',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      timeAgo,
                      style: TextStyle(
                        color: AppTheme.textSecondaryDark,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Gap(12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  challengeName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
                const Gap(4),
                Text(
                  '"$message"',
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          const Gap(16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  child: const Text('Decline'),
                ),
              ),
              const Gap(12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Accept'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PartnerCard extends StatelessWidget {
  final String name;
  final int streak;

  const _PartnerCard({required this.name, required this.streak});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      tileColor: AppTheme.surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: CircleAvatar(
        backgroundColor: Colors.blueAccent,
        child: Text(name[0]),
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text('$streak day streak together'),
      trailing: IconButton(
        icon: const Icon(Icons.chat_bubble_outline),
        onPressed: () {},
      ),
    );
  }
}
