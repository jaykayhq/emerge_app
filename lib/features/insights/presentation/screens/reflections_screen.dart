import 'package:emerge_app/core/presentation/widgets/growth_background.dart';
import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/features/insights/data/repositories/insights_repository.dart';
import 'package:emerge_app/features/monetization/presentation/providers/subscription_provider.dart';
import 'package:emerge_app/features/tutorial/presentation/providers/tutorial_provider.dart';
import 'package:emerge_app/features/tutorial/presentation/widgets/tutorial_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

class ReflectionsScreen extends ConsumerStatefulWidget {
  const ReflectionsScreen({super.key});

  @override
  ConsumerState<ReflectionsScreen> createState() => _ReflectionsScreenState();
}

class _ReflectionsScreenState extends ConsumerState<ReflectionsScreen> {
  final GlobalKey _mirrorKey = GlobalKey();
  final GlobalKey _insightsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _checkTutorial();
  }

  void _checkTutorial() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      final tutorialNotifier = ref.read(tutorialProvider.notifier);
      final tutorialState = ref.watch(tutorialProvider);
      tutorialNotifier.enableTutorialAutoShow();

      if (!tutorialState.isCompleted(TutorialStep.insights) &&
          tutorialNotifier.shouldShowTutorial()) {
        _showTutorial();
      }
    });
  }

  void _showTutorial() {
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => TutorialOverlay(
        steps: [
          TutorialStepInfo(
            title: 'The Mirror of Truth',
            description:
                'These reflections are the crystalized essence of your journey. They show you exactly where you stand.',
            targetKey: _mirrorKey,
          ),
          TutorialStepInfo(
            title: 'Identity Patterns',
            description:
                'Look for recurring themes in your insights to discover your core identity drivers.',
            targetKey: _insightsKey,
          ),
          const TutorialStepInfo(
            title: 'Active Reflection',
            description:
                'Wisdom unapplied is just noise. Use these insights to calibrate your next habits.',
          ),
        ],
        onCompleted: () {
          ref
              .read(tutorialProvider.notifier)
              .completeStep(TutorialStep.insights);
          entry.remove();
        },
      ),
    );
    Overlay.of(context).insert(entry);
  }

  @override
  Widget build(BuildContext context) {
    final reflectionsAsync = ref.watch(reflectionsProvider);
    final isPremium = ref.watch(isPremiumProvider).value ?? false;

    return GrowthBackground(
      appBar: AppBar(
        key: _mirrorKey,
        title: const Text('Reflections ✦ Insights'),
        backgroundColor: Colors.transparent,
      ),
      child: isPremium 
        ? reflectionsAsync.when(
            data: (reflections) => ListView.separated(
              key: _insightsKey,
              padding: const EdgeInsets.all(16),
              itemCount: reflections.length,
              separatorBuilder: (context, index) => const Gap(16),
              itemBuilder: (context, index) {
                final reflection = reflections[index];
                return _ReflectionCard(
                  date: reflection.date,
                  title: reflection.title,
                  content: reflection.content,
                  icon: reflection.type == 'insight'
                      ? Icons.lightbulb
                      : Icons.analytics,
                ).animate().fadeIn(delay: (100 * index).ms).slideX();
              },
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
          )
        : Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.timeline, size: 64, color: Colors.cyanAccent),
                const Gap(16),
                Text(
                  'Deep Time Insights',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Gap(8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32.0),
                  child: Text(
                    'Unlock multi-month identity evolution graphs and deep intelligence tracking.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                const Gap(24),
                FilledButton.icon(
                  onPressed: () {
                    context.push('/paywall');
                  },
                  icon: const Icon(Icons.lock_open),
                  label: const Text('Unlock with Emerge Pro'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.purpleAccent.withValues(alpha: 0.8),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
    );
  }
}

class _ReflectionCard extends StatelessWidget {
  final String date;
  final String title;
  final String content;
  final IconData icon;

  const _ReflectionCard({
    required this.date,
    required this.title,
    required this.content,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppTheme.primary),
                const Gap(8),
                Text(
                  date,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppTheme.textSecondaryDark,
                  ),
                ),
              ],
            ),
            const Gap(12),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Gap(8),
            Text(
              content,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
