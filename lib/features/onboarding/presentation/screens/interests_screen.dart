import 'package:emerge_app/core/theme/archetype_theme.dart';
import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/onboarding/domain/models/interest.dart';
import 'package:emerge_app/features/onboarding/presentation/providers/onboarding_state_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:emerge_app/features/onboarding/presentation/widgets/onboarding_progress_bar.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';

/// Onboarding step (Milestone 1): pick 3–5 interests from the curated catalog.
/// These choices are stored on the user profile (Drift + Firestore) and feed
/// the personalization signal for both the starter habit pack on this run
/// and future template-picker recommendations.
class InterestsScreen extends ConsumerStatefulWidget {
  const InterestsScreen({super.key});

  @override
  ConsumerState<InterestsScreen> createState() => _InterestsScreenState();
}

/// Color-coded flat grid: each interest chip is tinted by its category color.
/// Category is communicated purely through color (no section headers).
const _categoryColors = {
  InterestCategory.movement: Color(0xFF2BEE79), // green
  InterestCategory.creativity: Color(0xFF9C27B0), // purple
  InterestCategory.learning: Color(0xFF009688), // teal
  InterestCategory.mindfulness: Color(0xFF2196F3), // blue
  InterestCategory.faith: Color(0xFFFFC107), // amber
  InterestCategory.nutrition: Color(0xFFFF6B6B), // coral
};

class _InterestsScreenState extends ConsumerState<InterestsScreen> {
  final Set<String> _selected = <String>{};
  bool _isSaving = false;

  static const int _minPicks = 3;
  static const int _maxPicks = 5;

  @override
  void initState() {
    super.initState();
    final initial = ref.read(enhancedOnboardingProvider).interests;
    _selected.addAll(initial);
  }

  bool get _canContinue => _selected.length >= _minPicks;

  Future<void> _onContinue() async {
    if (!_canContinue || _isSaving) return;
    setState(() => _isSaving = true);
    try {
      await ref
          .read(enhancedOnboardingProvider.notifier)
          .setInterests(_selected.toList());
      await ref
          .read(enhancedOnboardingProvider.notifier)
          .completeMilestone(1);
      if (!mounted) return;
      context.push('/onboarding/club');
    } catch (e, s) {
      AppLogger.e('InterestsScreen: failed to save', e, s);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
      setState(() => _isSaving = false);
    }
  }

  Future<void> _onSkip() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      await ref
          .read(enhancedOnboardingProvider.notifier)
          .skipMilestone(1);
      if (!mounted) return;
      context.push('/onboarding/club');
    } catch (e, s) {
      AppLogger.e('InterestsScreen: failed to skip', e, s);
      if (!mounted) return;
      setState(() => _isSaving = false);
      context.push('/onboarding/club');
    }
  }

  void _toggle(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        if (_selected.length >= _maxPicks) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Pick up to $_maxPicks — remove one to add another.',
              ),
            ),
          );
          return;
        }
        _selected.add(id);
      }
    });
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final archetype = ref
            .watch(enhancedOnboardingProvider)
            .selectedArchetype ??
        UserArchetype.none;
    final theme = ArchetypeTheme.forArchetype(archetype);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A0A1A),
              Color(0xFF1A0A2A),
              Color(0xFF2A1A3A),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              AnimatedOnboardingProgressBar(
                targetProgress: 0.6,
                label: onboardingLabelFor(0.6),
                accentColor: archetype != UserArchetype.none
                    ? ArchetypeColors.all[archetype.name]?.accent
                    : null,
              ),
              _Header(
                onBack: () => context.pop(),
                onSkip: _onSkip,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Gap(20),
                      Text(
                        'What lights you up?',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ).animate().fadeIn().moveY(begin: 10, end: 0),
                      const Gap(8),
                      Text(
                        'Pick $_minPicks to $_maxPicks to personalize '
                        '${theme.archetypeName}.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white54,
                        ),
                      ).animate().fadeIn(delay: 100.ms),
                      const Gap(24),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final interest in Interest.catalog)
                            _InterestChip(
                              interest: interest,
                              isSelected: _selected.contains(interest.id),
                              onTap: () => _toggle(interest.id),
                            ),
                        ],
                      ),
                      const Gap(80),
                    ],
                  ),
                ),
              ),
              _BottomBar(
                pickCount: _selected.length,
                minPicks: _minPicks,
                maxPicks: _maxPicks,
                canContinue: _canContinue,
                isSaving: _isSaving,
                onContinue: _onContinue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onSkip;

  const _Header({
    required this.onBack,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white70),
            onPressed: onBack,
          ),
          const Spacer(),
          TextButton(
            onPressed: onSkip,
            child: Text(
              'Skip',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Colors.white54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InterestChip extends StatelessWidget {
  final Interest interest;
  final bool isSelected;
  final VoidCallback onTap;

  const _InterestChip({
    required this.interest,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _categoryColors[interest.category] ?? Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? EmergeColors.teal.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.08),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: EmergeColors.teal.withValues(alpha: 0.15),
                    blurRadius: 8,
                    spreadRadius: -2,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Small accent dot in category color
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              interest.icon,
              size: 14,
              color: isSelected ? EmergeColors.teal : color,
            ),
            const SizedBox(width: 6),
            Text(
              interest.label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int pickCount;
  final int minPicks;
  final int maxPicks;
  final bool canContinue;
  final bool isSaving;
  final VoidCallback onContinue;

  const _BottomBar({
    required this.pickCount,
    required this.minPicks,
    required this.maxPicks,
    required this.canContinue,
    required this.isSaving,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Glassmorphic progress container
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Text(
                    '$pickCount / $maxPicks',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Colors.white54,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: pickCount / maxPicks,
                      minHeight: 4,
                      color: EmergeColors.teal,
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'min $minPicks',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white38,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Gap(12),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: canContinue ? onContinue : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: EmergeColors.teal,
                foregroundColor: const Color(0xFF05100B),
                disabledBackgroundColor: Colors.white10,
                disabledForegroundColor: Colors.white38,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF05100B),
                      ),
                    )
                  : Text(
                      'CONTINUE',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF05100B),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
