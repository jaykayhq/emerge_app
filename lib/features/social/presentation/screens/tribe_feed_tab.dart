import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/features/social/domain/models/social_post.dart';
import 'package:emerge_app/features/social/data/repositories/social_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:timeago/timeago.dart' as timeago;

class TribeFeedTab extends ConsumerWidget {
  const TribeFeedTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(socialFeedProvider);

    return feedAsync.when(
      data: (posts) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];
          return _PostCard(post: post);
        },
      ),
      loading: () => const Center(
        child: CircularProgressIndicator(color: EmergeColors.teal),
      ),
      error: (err, stack) => Center(
        child: Text(
          'Error loading feed: $err',
          style: const TextStyle(color: Colors.white70),
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final SocialPost post;
  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha:0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha:0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: post.userAvatarUrl.isNotEmpty
                    ? NetworkImage(post.userAvatarUrl)
                    : null,
                child: post.userAvatarUrl.isEmpty
                    ? const Icon(Icons.person, color: Colors.white70)
                    : null,
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      timeago.format(post.timestamp),
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _PostTypeBadge(type: post.type),
            ],
          ),
          const Gap(12),
          Text(
            post.content,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const Gap(16),
          Row(
            children: [
              _ActionButton(
                icon: post.isLikedByMe ? Icons.favorite : Icons.favorite_border,
                label: '${post.likes}',
                color: post.isLikedByMe ? Colors.red : Colors.white60,
                onTap: () {},
              ),
              const Gap(16),
              _ActionButton(
                icon: Icons.chat_bubble_outline,
                label: '${post.comments}',
                color: Colors.white60,
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PostTypeBadge extends StatelessWidget {
  final PostType type;
  const _PostTypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    String label = '';
    Color color = Colors.grey;

    switch (type) {
      case PostType.challengeJoin:
        label = 'CHALLENGE';
        color = EmergeColors.teal;
        break;
      case PostType.habitCompletion:
        label = 'HABIT';
        color = EmergeColors.violet;
        break;
      case PostType.levelUp:
        label = 'LEVEL UP';
        color = Colors.amber;
        break;
      case PostType.regular:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha:0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const Gap(6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
