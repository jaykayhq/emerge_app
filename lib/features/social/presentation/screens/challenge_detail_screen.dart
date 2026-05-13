import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/core/presentation/widgets/world_background.dart';
import 'package:emerge_app/core/domain/models/app_world_theme.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/social/domain/models/challenge.dart';
import 'package:emerge_app/features/social/presentation/providers/challenge_provider.dart';
import 'package:emerge_app/features/social/presentation/widgets/quest_confirmation_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';

class ChallengeDetailScreen extends ConsumerWidget {
  final Challenge? challenge;
  final String? challengeId;

  const ChallengeDetailScreen({
    super.key,
    this.challenge,
    this.challengeId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengeAsync = challenge != null
        ? AsyncValue.data(challenge!)
        : ref.watch(challengeByIdProvider(challengeId ?? ''));

    return challengeAsync.when(
      loading: () => const Scaffold(
        backgroundColor: EmergeColors.background,
        body: Center(child: CircularProgressIndicator(color: EmergeColors.teal)),
      ),
      error: (err, stack) => Scaffold(
        backgroundColor: EmergeColors.background,
        body: Center(
          child: Text(
            'Error loading challenge: $err',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
      data: (challenge) {
        if (challenge == null) {
          return const Scaffold(
            backgroundColor: EmergeColors.background,
            body: Center(
              child: Text(
                'Challenge not found',
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
        }

        final progress = challenge.totalDays > 0
            ? (challenge.currentDay / challenge.totalDays).clamp(0.0, 1.0)
            : 0.0;

        return WorldBackground(
          themeOverride: AppWorldTheme.nebula,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Stack(
              children: [
                CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverAppBar(
                      expandedHeight: 320,
                      pinned: true,
                      stretch: true,
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      flexibleSpace: FlexibleSpaceBar(
                        stretchModes: const [
                          StretchMode.zoomBackground,
                          StretchMode.blurBackground,
                        ],
                        background: Stack(
                          fit: StackFit.expand,
                          children: [
                            Hero(
                              tag: 'challenge_image_${challenge.id}',
                              child: challenge.imageUrl.startsWith('images/') || challenge.imageUrl.startsWith('assets/images/')
                                  ? Image.asset(
                                      challenge.imageUrl,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.network(
                                      challenge.imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        color: AppTheme.surfaceDark,
                                        child: const Center(
                                          child: Icon(
                                            Icons.image_not_supported_outlined,
                                            size: 48,
                                            color: Colors.white24,
                                          ),
                                        ),
                                      ),
                                    ),
                            ),
                            // Cinematic Gradient Overlay
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.3),
                                    Colors.transparent,
                                    EmergeColors.background.withValues(alpha: 0.8),
                                    EmergeColors.background,
                                  ],
                                  stops: const [0.0, 0.4, 0.8, 1.0],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      leading: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              color: Colors.white.withValues(alpha: 0.1),
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back, color: Colors.white),
                                onPressed: () => context.pop(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.bolt, size: 14, color: AppTheme.primary),
                                      const Gap(4),
                                      Text(
                                        '+${challenge.xpReward} XP',
                                        style: const TextStyle(
                                          color: AppTheme.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Gap(12),
                                if (challenge.isPremium)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: EmergeColors.yellow.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: EmergeColors.yellow.withValues(alpha: 0.3)),
                                    ),
                                    child: const Text(
                                      'PREMIUM',
                                      style: TextStyle(
                                        color: EmergeColors.yellow,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                              ],
                            ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),
                            const Gap(16),
                            Text(
                              challenge.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
                            const Gap(12),
                            Text(
                              challenge.description,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 16,
                                height: 1.5,
                              ),
                            ).animate().fadeIn(delay: 400.ms),
                            const Gap(32),

                            // Progress Section
                            if (challenge.status == ChallengeStatus.active) ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'CURRENT PROGRESS',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.4),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  Text(
                                    '${(progress * 100).toInt()}%',
                                    style: const TextStyle(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ).animate().fadeIn(delay: 500.ms),
                              const Gap(12),
                              Stack(
                                children: [
                                  Container(
                                    height: 12,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 1000),
                                    curve: Curves.easeOutExpo,
                                    height: 12,
                                    width: MediaQuery.of(context).size.width * 0.88 * progress,
                                    decoration: BoxDecoration(
                                      gradient: EmergeColors.neonGradient,
                                      borderRadius: BorderRadius.circular(6),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.primary.withValues(alpha: 0.3),
                                          blurRadius: 10,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ).animate().fadeIn(delay: 600.ms).scaleX(begin: 0, alignment: Alignment.centerLeft),
                              const Gap(40),
                            ],

                            // Timeline Section
                            Text(
                              'JOURNEY LOG',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                              ),
                            ).animate().fadeIn(delay: 700.ms),
                            const Gap(24),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final step = challenge.steps[index];
                            final isCompleted = step.day <= challenge.currentDay;
                            final isCurrent = step.day == challenge.currentDay + 1 && challenge.status == ChallengeStatus.active;

                            return IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Progress Line
                                  Column(
                                    children: [
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isCompleted
                                              ? AppTheme.primary
                                              : isCurrent
                                                  ? AppTheme.primary.withValues(alpha: 0.2)
                                                  : Colors.white.withValues(alpha: 0.1),
                                          border: isCurrent
                                              ? Border.all(color: AppTheme.primary, width: 2)
                                              : null,
                                          boxShadow: isCompleted ? [
                                            BoxShadow(
                                              color: AppTheme.primary.withValues(alpha: 0.3),
                                              blurRadius: 8,
                                            )
                                          ] : [],
                                        ),
                                        child: isCompleted
                                            ? const Icon(Icons.check, size: 14, color: Colors.black)
                                            : Center(
                                                child: Text(
                                                  '${step.day}',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: isCurrent ? AppTheme.primary : Colors.white24,
                                                  ),
                                                ),
                                              ),
                                      ),
                                      if (index < challenge.steps.length - 1)
                                        Expanded(
                                          child: Container(
                                            width: 2,
                                            color: isCompleted
                                                ? AppTheme.primary.withValues(alpha: 0.5)
                                                : Colors.white.withValues(alpha: 0.05),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const Gap(20),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          step.title,
                                          style: TextStyle(
                                            color: isCompleted ? Colors.white : Colors.white.withValues(alpha: 0.4),
                                            fontSize: 16,
                                            fontWeight: isCurrent || isCompleted ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                        const Gap(4),
                                        Text(
                                          step.description,
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.3),
                                            fontSize: 13,
                                          ),
                                        ),
                                        const Gap(24),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          childCount: challenge.steps.length,
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: Gap(120)),
                  ],
                ),

                // Bottom Action Button
                Positioned(
                  bottom: 32,
                  left: 24,
                  right: 24,
                  child: _buildActionButton(context, ref, challenge),
                ),
              ],
            ),
          ),
        );
      },
  );
}

  Widget _buildActionButton(BuildContext context, WidgetRef ref, Challenge challenge) {
    if (challenge.status != ChallengeStatus.featured && challenge.status != ChallengeStatus.active) {
      return const SizedBox.shrink();
    }

    final label = challenge.status == ChallengeStatus.featured
        ? 'JOIN QUEST'
        : (challenge.currentDay + 1 >= challenge.totalDays ? 'FINISH QUEST' : 'COMPLETE DAY ${challenge.currentDay + 1}');

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: GestureDetector(
          onTap: () => _showConfirmation(context, ref, challenge),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primary.withValues(alpha: 0.8),
                  const Color(0xFF6366F1).withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showConfirmation(BuildContext screenContext, WidgetRef ref, Challenge challenge) {
    showModalBottomSheet(
      context: screenContext,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => QuestConfirmationSheet(
        challenge: challenge,
        onConfirm: () async {
          final user = ref.read(authStateChangesProvider).value;
          if (user == null) return;

          final repo = ref.read(challengeRepositoryProvider);
          if (challenge.status == ChallengeStatus.featured) {
            final result = await repo.joinChallenge(user.id, challenge.id);
            result.fold(
              (failure) => _showError(screenContext, failure.message),
              (_) async {
                ref.invalidate(userChallengesProvider);
                ref.invalidate(archetypeChallengesProvider);
                if (screenContext.mounted) {
                  _showSuccess(screenContext, 'QUEST STARTED! (+25 XP)');
                  screenContext.go('/tribes/challenges');
                }
              },
            );
          } else {
            final newProgress = challenge.currentDay + 1;
            final result = await repo.updateProgress(user.id, challenge.id, newProgress);
            result.fold(
              (failure) => _showError(screenContext, failure.message),
              (_) {
                final isCompleted = newProgress >= challenge.totalDays;
                _showSuccess(
                  screenContext,
                  isCompleted ? 'QUEST COMPLETE! (+${challenge.xpReward} XP)' : 'PROGRESS SAVED!',
                );
                screenContext.pop();
              },
            );
          }
        },
      ),
    );
  }

  void _showError(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.primary),
    );
  }
}
