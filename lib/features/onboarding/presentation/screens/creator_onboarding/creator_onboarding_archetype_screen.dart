import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_app_icon.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/onboarding/presentation/providers/creator_onboarding_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

/// Step 1 of creator onboarding — the creator picks the archetype that
/// best describes the kind of content they create.
///
/// Mirrors the structure of `IdentityStudioScreen` but stripped down:
/// no motive selection, no attribute distribution. Just one decisive
/// identity vote, then move on to bio + tags.
class CreatorOnboardingArchetypeScreen extends ConsumerStatefulWidget {
  const CreatorOnboardingArchetypeScreen({super.key});

  @override
  ConsumerState<CreatorOnboardingArchetypeScreen> createState() =>
      _CreatorArchetypeScreenState();
}

class _CreatorArchetypeScreenState
    extends ConsumerState<CreatorOnboardingArchetypeScreen> {
  UserArchetype? _selected;

  static const List<UserArchetype> _choices = [
    UserArchetype.athlete,
    UserArchetype.scholar,
    UserArchetype.creator,
    UserArchetype.stoic,
    UserArchetype.zealot,
  ];

  Future<void> _next() async {
    if (_selected == null) return;
    ref
        .read(creatorOnboardingDraftControllerProvider.notifier)
        .setArchetype(_selected!);
    try {
      await ref.read(
        saveCreatorOnboardingProgressProvider(progress: 1).future,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save progress: $e')),
      );
      return;
    }
    if (mounted) context.go('/onboarding/creator/profile');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EmergeColors.background,
      body: Stack(
        children: [
          const Positioned.fill(child: HexMeshBackground()),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    Colors.amber.withValues(alpha: 0.12),
                    EmergeColors.violet.withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: EmergeAppIcon(size: 64)),
                  const Gap(16),
                  Text(
                    'Creator Onboarding',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Gap(8),
                  Text(
                    'What kind of creator are you?',
                    style: GoogleFonts.splineSans(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Gap(8),
                  Text(
                    'Pick the identity that best matches the work you want to ship. You can change this later.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white60,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Gap(32),
                  ..._choices.asMap().entries.map(
                        (entry) => _ArchetypeCard(
                          archetype: entry.value,
                          selected: _selected == entry.value,
                          onTap: () => setState(() => _selected = entry.value),
                        ).animate().fadeIn(
                              delay: Duration(
                                milliseconds: 80 * entry.key,
                              ),
                            ).slideY(begin: 0.05),
                      ),
                  const Gap(32),
                  Container(
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: LinearGradient(
                        colors: _selected != null
                            ? const [Colors.amber, Colors.orange]
                            : [Colors.white24, Colors.white12],
                      ),
                    ),
                    child: ElevatedButton(
                      onPressed: _selected != null ? _next : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: const Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const Gap(16),
                  TextButton(
                    onPressed: () => context.go('/onboarding/creator/profile'),
                    child: const Text(
                      'Skip for now',
                      style: TextStyle(color: Colors.white60),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArchetypeCard extends StatelessWidget {
  final UserArchetype archetype;
  final bool selected;
  final VoidCallback onTap;

  const _ArchetypeCard({
    required this.archetype,
    required this.selected,
    required this.onTap,
  });

  String get _label {
    switch (archetype) {
      case UserArchetype.athlete:
        return 'Athlete';
      case UserArchetype.scholar:
        return 'Scholar';
      case UserArchetype.creator:
        return 'Creator';
      case UserArchetype.stoic:
        return 'Stoic';
      case UserArchetype.zealot:
        return 'Zealot';
      case UserArchetype.none:
        return 'None';
    }
  }

  String get _description {
    switch (archetype) {
      case UserArchetype.athlete:
        return 'Discipline, performance, recovery — content that pushes bodies.';
      case UserArchetype.scholar:
        return 'Deep work, learning systems, intellectual rigor.';
      case UserArchetype.creator:
        return 'Craft, studio practice, output-first creative rituals.';
      case UserArchetype.stoic:
        return 'Mindfulness, journaling, equanimity under pressure.';
      case UserArchetype.zealot:
        return 'Devotion, fierce consistency, belief into practice.';
      case UserArchetype.none:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected
                    ? Colors.amber
                    : Colors.white.withValues(alpha: 0.15),
                width: selected ? 2 : 1,
              ),
              color: selected
                  ? Colors.amber.withValues(alpha: 0.08)
                  : Colors.white.withValues(alpha: 0.04),
            ),
            child: Row(
              children: [
                Icon(
                  _iconFor(archetype),
                  color: selected ? Colors.amber : Colors.white60,
                  size: 28,
                ),
                const Gap(16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _label,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Gap(2),
                      Text(
                        _description,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  const Icon(
                    Icons.check_circle,
                    color: Colors.amber,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconFor(UserArchetype a) {
    switch (a) {
      case UserArchetype.athlete:
        return Icons.fitness_center;
      case UserArchetype.scholar:
        return Icons.menu_book;
      case UserArchetype.creator:
        return Icons.brush;
      case UserArchetype.stoic:
        return Icons.self_improvement;
      case UserArchetype.zealot:
        return Icons.local_fire_department;
      case UserArchetype.none:
        return Icons.help_outline;
    }
  }
}
