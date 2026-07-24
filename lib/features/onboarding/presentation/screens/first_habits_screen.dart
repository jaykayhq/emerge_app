import 'package:emerge_app/core/theme/archetype_theme.dart';
import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:emerge_app/features/onboarding/domain/models/starter_habit_blueprint.dart';
import 'package:emerge_app/features/onboarding/presentation/providers/onboarding_state_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

/// Onboarding step (Milestone 3): see the three personalized starter habits
/// generated from (archetype, interests, club tags) and persist them as one
/// starter pack. Replaces the legacy single-habit creator.
///
/// All three habits are intentionally simple (≤10 min, no timer, no
/// integration) and titled with imperative verbs. "Skip" goes to world
/// reveal with no starter pack created.
class FirstHabitsScreen extends ConsumerStatefulWidget {
  const FirstHabitsScreen({super.key});

  @override
  ConsumerState<FirstHabitsScreen> createState() =>
      _FirstHabitsScreenState();
}

class _FirstHabitsScreenState extends ConsumerState<FirstHabitsScreen> {
  bool _isSaving = false;

  Future<void> _onStartJourney() async {
    if (_isSaving) return;
    final notifier = ref.read(enhancedOnboardingProvider.notifier);
    final state = ref.read(enhancedOnboardingProvider);
    final archetype = state.selectedArchetype;
    if (archetype == null || archetype == UserArchetype.none) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pick an archetype first.'),
        ),
      );
      return;
    }

    final blueprints = StarterHabitBlueprint.forPersonalization(
      archetype: archetype,
      interestIds: state.interests,
      clubTags: state.joinedClubId != null
          ? [state.joinedClubId!]
          : const [],
    );

    if (blueprints.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No starter habits for this archetype yet.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = ref.read(authStateChangesProvider).value;
      if (user == null || user.isEmpty) {
        throw Exception('Not signed in');
      }
      final repository = ref.read(habitRepositoryProvider);
      final result = await repository.createStarterPack(
        userId: user.id,
        blueprints: blueprints,
        archetypeName: archetype.name,
        interestIds: state.interests,
        clubId: state.joinedClubId,
      );
      result.fold(
        (failure) => throw Exception(failure.message),
        (_) {
          notifier.removeHabitStack('first_habits_screen');
        },
      );
      await notifier.completeMilestone(3);
      if (!mounted) return;
      context.push('/onboarding/world-reveal');
    } catch (e, s) {
      AppLogger.e('FirstHabitsScreen: failed to save starter pack', e, s);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save starter pack: $e')),
      );
      setState(() => _isSaving = false);
    }
  }

  void _onSkip() {
    ref
        .read(enhancedOnboardingProvider.notifier)
        .completeMilestone(3);
    context.push('/onboarding/world-reveal');
  }

  void _onHabitTap(StarterHabitBlueprint blueprint, int index) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _HabitDetailSheet(
        blueprint: blueprint,
        index: index,
        archetype: ref.read(enhancedOnboardingProvider).selectedArchetype ?? UserArchetype.none,
        onSave: (customTitle, customCue) {
          // Navigate to habit editor or update the blueprint locally
          // For now, just show confirmation
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Habit "${customTitle ?? blueprint.title}" saved with cue: ${customCue ?? blueprint.shortCue}')),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final archetype = ref
            .watch(enhancedOnboardingProvider)
            .selectedArchetype ??
        UserArchetype.none;
    final state = ref.watch(enhancedOnboardingProvider);
    final theme = ArchetypeTheme.forArchetype(archetype);
    final blueprints = StarterHabitBlueprint.forPersonalization(
      archetype: archetype,
      interestIds: state.interests,
      clubTags: state.joinedClubId != null
          ? [state.joinedClubId!]
          : const [],
      limit: 3,
    );

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
                stepIndex: 3,
                totalSteps: 5,
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
                        'Your starter pack',
                        style: GoogleFonts.splineSans(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ).animate().fadeIn().moveY(begin: 10, end: 0),
                      const Gap(8),
                      Text(
                        'Three simple habits tuned to '
                        '${theme.archetypeName.toLowerCase()} '
                        '${state.interests.isNotEmpty ? '+ your interests' : ''}.',
                        style: GoogleFonts.splineSans(
                          color: Colors.white54,
                          fontSize: 16,
                        ),
                      ).animate().fadeIn(delay: 100.ms),
                      const Gap(24),
                      for (var i = 0; i < blueprints.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _BlueprintCard(
                            index: i,
                            blueprint: blueprints[i],
                            onTap: () => _onHabitTap(blueprints[i], i),
                          ),
                        ),
                      const Gap(80),
                    ],
                  ),
                ),
              ),
              _BottomBar(
                canContinue: blueprints.isNotEmpty && !_isSaving,
                isSaving: _isSaving,
                onContinue: _onStartJourney,
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
  final VoidCallback onSkip;

  const _Header({
    required this.stepIndex,
    required this.totalSteps,
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
          TextButton(
            onPressed: onSkip,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white54,
            ),
            child: Text(
              'Skip',
              style: GoogleFonts.splineSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlueprintCard extends StatelessWidget {
  final int index;
  final StarterHabitBlueprint blueprint;
  final VoidCallback? onTap;

  const _BlueprintCard({
    required this.index,
    required this.blueprint,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2BEE79).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${index + 1}',
                    style: GoogleFonts.splineSans(
                      color: const Color(0xFF2BEE79),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Gap(16),
                Expanded(
                  child: Text(
                    blueprint.title,
                    style: GoogleFonts.splineSans(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.white38,
                  size: 20,
                ),
              ],
            ),
            const Gap(12),
            Row(
              children: [
                const Icon(
                  Icons.bolt,
                  color: Color(0xFF2BEE79),
                  size: 16,
                ),
                const Gap(6),
                Text(
                  blueprint.shortCue,
                  style: GoogleFonts.splineSans(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const Gap(6),
            Text(
              blueprint.sourceAttribution,
              style: GoogleFonts.splineSans(
                color: Colors.white38,
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 120 * (index + 1)));
  }
}

class _BottomBar extends StatelessWidget {
  final bool canContinue;
  final bool isSaving;
  final VoidCallback onContinue;

  const _BottomBar({
    required this.canContinue,
    required this.isSaving,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(color: Colors.transparent),
      child: SizedBox(
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
                  'START MY JOURNEY',
                  style: GoogleFonts.splineSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      ),
    );
  }
}

class _HabitDetailSheet extends ConsumerStatefulWidget {
  final StarterHabitBlueprint blueprint;
  final int index;
  final UserArchetype archetype;
  final void Function(String? customTitle, String? customCue) onSave;

  const _HabitDetailSheet({
    required this.blueprint,
    required this.index,
    required this.archetype,
    required this.onSave,
  });

  @override
  ConsumerState<_HabitDetailSheet> createState() => _HabitDetailSheetState();
}

class _HabitDetailSheetState extends ConsumerState<_HabitDetailSheet> {
  late TextEditingController _titleController;
  late TextEditingController _cueController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.blueprint.title);
    _cueController = TextEditingController(text: widget.blueprint.shortCue);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _cueController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    
    // Create the habit from the blueprint with customizations
    final user = ref.read(authStateChangesProvider).value;
    if (user != null && user.isNotEmpty) {
      final repository = ref.read(habitRepositoryProvider);
      final now = DateTime.now();
      
      final habit = Habit(
        id: '${widget.blueprint.id}_${widget.index}_${now.millisecondsSinceEpoch}',
        userId: user.id,
        title: _titleController.text.trim().isEmpty ? widget.blueprint.title : _titleController.text.trim(),
        cue: _cueController.text.trim().isEmpty ? widget.blueprint.shortCue : _cueController.text.trim(),
        difficulty: HabitDifficulty.easy,
        attribute: widget.blueprint.attribute,
        identityTags: ['onboarding', widget.archetype.name, widget.blueprint.id],
        frequency: HabitFrequency.daily,
        createdAt: now,
      );
      
      await repository.createHabit(habit);
    }
    
    if (mounted) {
      Navigator.pop(context);
      widget.onSave(
        _titleController.text.trim().isEmpty ? null : _titleController.text.trim(),
        _cueController.text.trim().isEmpty ? null : _cueController.text.trim(),
      );
    }
    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A1A).withValues(alpha: 0.98),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 40,
            spreadRadius: 10,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Gap(32),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2BEE79).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.bolt,
                  color: const Color(0xFF2BEE79),
                  size: 28,
                ),
              ),
              const Gap(16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CUSTOMIZE HABIT',
                      style: GoogleFonts.splineSans(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                      ),
                    ),
                    Text(
                      'Habit ${widget.index + 1} of 3',
                      style: GoogleFonts.splineSans(
                        color: Colors.white54,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Gap(32),
          TextField(
            controller: _titleController,
            style: GoogleFonts.splineSans(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              labelText: 'Habit Title',
              labelStyle: GoogleFonts.splineSans(color: Colors.white54),
              hintText: widget.blueprint.title,
              hintStyle: GoogleFonts.splineSans(color: Colors.white30),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.white10),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.white10),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF2BEE79), width: 2),
              ),
            ),
          ),
          const Gap(16),
          TextField(
            controller: _cueController,
            style: GoogleFonts.splineSans(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              labelText: 'Cue (When will you do this?)',
              labelStyle: GoogleFonts.splineSans(color: Colors.white54),
              hintText: widget.blueprint.shortCue,
              hintStyle: GoogleFonts.splineSans(color: Colors.white30),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.white10),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.white10),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF2BEE79), width: 2),
              ),
              prefixIcon: Icon(Icons.bolt, color: Colors.white38),
            ),
          ),
          const Gap(16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Attribute: ${widget.blueprint.attribute.name.toUpperCase()}',
                  style: GoogleFonts.splineSans(
                    color: Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const Gap(4),
                Text(
                  widget.blueprint.sourceAttribution,
                  style: GoogleFonts.splineSans(
                    color: Colors.white38,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          const Gap(32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSaving ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    'CANCEL',
                    style: GoogleFonts.splineSans(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
              const Gap(12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2BEE79),
                    foregroundColor: const Color(0xFF05100B),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF05100B),
                          ),
                        )
                      : Text(
                          'SAVE HABIT',
                          style: GoogleFonts.splineSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),
            ],
          ),
          const Gap(24),
        ],
      ),
    );
  }
}
