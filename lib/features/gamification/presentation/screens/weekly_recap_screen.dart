import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/features/gamification/domain/services/weekly_recap_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

class WeeklyRecapScreen extends ConsumerStatefulWidget {
  const WeeklyRecapScreen({super.key});

  @override
  ConsumerState<WeeklyRecapScreen> createState() => _WeeklyRecapScreenState();
}

class _WeeklyRecapScreenState extends ConsumerState<WeeklyRecapScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final recapService = ref.read(weeklyRecapServiceProvider);

    final user = ref.watch(authStateChangesProvider).value;

    // If no user logic handled by auth wrapper or router usually, but safety check:
    if (user == null) {
      return const Scaffold(
        backgroundColor: EmergeColors.background,
        body: Center(
          child: CircularProgressIndicator(color: EmergeColors.teal),
        ),
      );
    }

    return Scaffold(
      backgroundColor: EmergeColors.background,
      body: Stack(
        children: [
          const Positioned.fill(child: HexMeshBackground()),
          FutureBuilder(
            future: recapService.generateRecapIfNeeded(user.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: EmergeColors.teal),
                );
              }
              if (snapshot.hasError || !snapshot.hasData) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'No recap available for this week.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.textSecondaryDark,
                        ),
                      ),
                      const Gap(16),
                      ElevatedButton(
                        onPressed: () => context.pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.surfaceDark,
                          foregroundColor: AppTheme.textMainDark,
                        ),
                        child: const Text('Back'),
                      ),
                    ],
                  ),
                );
              }

              final recap = snapshot.data!;
              final pages = [
                _IntroSlide(recap: recap),
                _StatsSlide(recap: recap),
                _WorldGrowthSlide(recap: recap),
                _OutroSlide(recap: recap),
              ];

              return Stack(
                children: [
                  PageView(
                    controller: _pageController,
                    onPageChanged: (index) =>
                        setState(() => _currentPage = index),
                    children: pages,
                  ),
                  // Progress Indicator
                  Positioned(
                    top: 40,
                    left: 16,
                    right: 16,
                    child: Row(
                      children: List.generate(pages.length, (index) {
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              height: 4,
                              decoration: BoxDecoration(
                                color: _currentPage >= index
                                    ? EmergeColors.teal
                                    : EmergeColors.teal.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  // Close Button
                  Positioned(
                    top: 60,
                    right: 16,
                    child: IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: AppTheme.textMainDark,
                      ),
                      onPressed: () => context.pop(),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _IntroSlide extends StatelessWidget {
  final dynamic recap;
  const _IntroSlide({required this.recap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            EmergeColors.background.withValues(alpha: 0.5),
            EmergeColors.background,
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'YOUR WEEKLY',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppTheme.textSecondaryDark,
              letterSpacing: 4,
              fontSize: 16,
            ),
          ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.5, end: 0),
          const Gap(16),
          Text(
            'RECAP',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              color: EmergeColors.teal,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ).animate().fadeIn(delay: 500.ms, duration: 800.ms).scale(),
          const Gap(32),
          Divider(color: EmergeColors.hexLine).animate().scaleXY(
            begin: 0,
            end: 1,
            duration: 600.ms,
            curve: Curves.easeOut,
            alignment: Alignment.centerLeft,
          ),
          const Gap(32),
          Text(
            'You\'ve been busy this week.',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: AppTheme.textMainDark),
          ).animate().fadeIn(delay: 1500.ms),
        ],
      ),
    );
  }
}

class _StatsSlide extends StatelessWidget {
  final dynamic recap;
  const _StatsSlide({required this.recap});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _StatBig(
            label: 'Habits Completed',
            value: '${recap.totalHabitsCompleted}',
            delay: 0,
            color: EmergeColors.teal,
          ),
          const Gap(40),
          _StatBig(
            label: 'Perfect Days',
            value: '${recap.perfectDays}',
            delay: 500,
            color: EmergeColors.violet,
          ),
          const Gap(40),
          _StatBig(
            label: 'XP Earned',
            value: '${recap.totalXpEarned}',
            delay: 1000,
            color: EmergeColors.yellow,
          ),
        ],
      ),
    );
  }
}

class _StatBig extends StatelessWidget {
  final String label;
  final String value;
  final int delay;
  final Color color;

  const _StatBig({
    required this.label,
    required this.value,
    required this.delay,
    this.color = EmergeColors.teal,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
            color: color,
            fontSize: 64,
            fontWeight: FontWeight.bold,
          ),
        ).animate().fadeIn(delay: delay.ms).scale(),
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.textSecondaryDark,
            fontSize: 16,
          ),
        ).animate().fadeIn(delay: (delay + 300).ms),
      ],
    );
  }
}

class _WorldGrowthSlide extends StatelessWidget {
  final dynamic recap;
  const _WorldGrowthSlide({required this.recap});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/forest_stage_${recap.currentLevel.clamp(1, 5)}.png',
          fit: BoxFit.cover,
          color: EmergeColors.background.withValues(alpha: 0.7),
          colorBlendMode: BlendMode.darken,
          errorBuilder: (context, error, stackTrace) =>
              Container(color: EmergeColors.background),
        ).animate().fadeIn(duration: 1000.ms),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.public, size: 80, color: EmergeColors.teal)
                  .animate()
                  .fadeIn()
                  .scale(duration: 1000.ms, curve: Curves.elasticOut),
              const Gap(24),
              Text(
                'YOUR WORLD IS THRIVING',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.textMainDark,
                  fontWeight: FontWeight.bold,
                ),
              ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0),
              const Gap(16),
              Text(
                'Entropy Reduced by ${(recap.worldGrowthPercentage * 100).toInt()}%',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: EmergeColors.teal),
              ).animate().fadeIn(delay: 1000.ms),
            ],
          ),
        ),
      ],
    );
  }
}

class _OutroSlide extends StatelessWidget {
  final dynamic recap;
  const _OutroSlide({required this.recap});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'KEEP IT UP!',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: AppTheme.textMainDark,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ).animate().fadeIn().shimmer(
              duration: 2000.ms,
              color: EmergeColors.yellow,
            ),
            const Gap(32),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [EmergeColors.teal, EmergeColors.violet],
                ),
                boxShadow: [
                  BoxShadow(
                    color: EmergeColors.teal.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () => context.pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Back to World',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ).animate().scale(delay: 1000.ms),
            ),
          ],
        ),
      ),
    );
  }
}
