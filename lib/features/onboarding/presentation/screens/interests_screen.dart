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
import 'package:google_fonts/google_fonts.dart';

/// Onboarding step (Milestone 1): pick 3–5 interests from the curated catalog.
/// These choices are stored on the user profile (Drift + Firestore) and feed
/// the personalization signal for both the starter habit pack on this run
/// and future template-picker recommendations.
class InterestsScreen extends ConsumerStatefulWidget {
  const InterestsScreen({super.key});

  @override
  ConsumerState<InterestsScreen> createState() => _InterestsScreenState();
}

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

    final byCategory = <InterestCategory, List<Interest>>{};
    for (final interest in Interest.catalog) {
      byCategory.putIfAbsent(interest.category, () => []).add(interest);
    }

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
              _Header(
                stepIndex: 1,
                totalSteps: 5,
                onBack: () => context.pop(),
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
                        style: GoogleFonts.splineSans(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ).animate().fadeIn().moveY(begin: 10, end: 0),
                      const Gap(8),
                      Text(
                        'Pick $_minPicks to $_maxPicks to personalize '
                        '${theme.archetypeName}.',
                        style: GoogleFonts.splineSans(
                          color: Colors.white54,
                          fontSize: 16,
                        ),
                      ).animate().fadeIn(delay: 100.ms),
                      const Gap(24),
                      for (final category in InterestCategory.values) ...[
                        _CategoryHeader(
                          label: category.displayName,
                          count: byCategory[category]?.length ?? 0,
                        ),
                        const Gap(8),
                        _InterestGrid(
                          interests: byCategory[category] ?? const [],
                          selected: _selected,
                          onToggle: _toggle,
                        ),
                        const Gap(24),
                      ],
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
  final int stepIndex;
  final int totalSteps;
  final VoidCallback onBack;

  const _Header({
    required this.stepIndex,
    required this.totalSteps,
    required this.onBack,
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
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10),
            ),
            child: Text(
              'STEP $stepIndex OF $totalSteps',
              style: GoogleFonts.splineSans(
                color: Colors.white54,
                fontSize: 10,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  final String label;
  final int count;

  const _CategoryHeader({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.splineSans(
            color: const Color(0xFF2BEE79),
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
        const Gap(8),
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: Color(0xFF2BEE79),
            shape: BoxShape.circle,
          ),
        ),
        const Gap(8),
        Text(
          '$count',
          style: GoogleFonts.splineSans(
            color: Colors.white38,
            fontSize: 11,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

class _InterestGrid extends StatelessWidget {
  final List<Interest> interests;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  const _InterestGrid({
    required this.interests,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final interest in interests)
          _InterestChip(
            interest: interest,
            isSelected: selected.contains(interest.id),
            onTap: () => onToggle(interest.id),
          ),
      ],
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1A2C24)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2BEE79)
                : Colors.white.withValues(alpha: 0.1),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              interest.icon,
              size: 18,
              color: isSelected
                  ? const Color(0xFF2BEE79)
                  : Colors.white70,
            ),
            const Gap(8),
            Text(
              interest.label,
              style: GoogleFonts.splineSans(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected
                    ? FontWeight.w600
                    : FontWeight.w400,
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
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Text(
                  '$pickCount / $maxPicks',
                  style: GoogleFonts.splineSans(
                    color: Colors.white54,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: LinearProgressIndicator(
                    value: pickCount / maxPicks,
                    minHeight: 4,
                    color: const Color(0xFF2BEE79),
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'min $minPicks',
                  style: GoogleFonts.splineSans(
                    color: Colors.white38,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: canContinue ? onContinue : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2BEE79),
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
                      style: GoogleFonts.splineSans(
                        fontSize: 16,
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
