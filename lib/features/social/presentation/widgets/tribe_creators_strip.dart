import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:emerge_app/core/presentation/widgets/fallback_initial_avatar.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/features/social/presentation/providers/creator_provider.dart';

/// Horizontal scroll of verified creator FACES (no blueprint tiles).
/// Reads from [verifiedCreatorsStreamProvider]; falls back to a graceful
/// empty state if no creators have been seeded yet.
class TribeCreatorsStrip extends ConsumerWidget {
  const TribeCreatorsStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final creatorsAsync = ref.watch(verifiedCreatorsStreamProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Row(
            children: [
              Text(
                'CREATORS',
                style: TextStyle(
                  color: EmergeColors.nebulaPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => context.push('/creators'),
                child: const Text(
                  'View All →',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 110,
          child: creatorsAsync.when(
            data: (creators) {
              if (creators.isEmpty) {
                return const _EmptyState();
              }
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                physics: const BouncingScrollPhysics(),
                itemCount: creators.length,
                separatorBuilder: (_, _) => const Gap(14),
                itemBuilder: (context, index) {
                  final creator = creators[index];
                  return _CreatorFace(
                    name: creator.displayName ?? 'Creator',
                    userId: creator.userId,
                    avatarUrl: creator.avatarUrl,
                  );
                },
              );
            },
            loading: () => const Center(
              child: SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (_, _) => const _EmptyState(),
          ),
        ),
      ],
    );
  }
}

class _CreatorFace extends StatelessWidget {
  final String name;
  final String userId;
  final String? avatarUrl;

  const _CreatorFace({
    required this.name,
    required this.userId,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 84,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/social/creator/$userId'),
        child: Column(
          children: [
            FallbackInitialAvatar(
              name: name,
              size: 64,
              imageUrl: avatarUrl,
              borderColor: EmergeColors.nebulaPrimaryContainer,
              borderWidth: 1.5,
            ),
            const Gap(8),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32),
        child: Text(
          'No creators discovered yet.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ),
    );
  }
}
