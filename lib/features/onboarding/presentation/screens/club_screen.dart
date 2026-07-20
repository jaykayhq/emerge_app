import 'package:emerge_app/core/theme/archetype_theme.dart';
import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/onboarding/presentation/providers/onboarding_state_notifier.dart';
import 'package:emerge_app/features/social/domain/models/tribe.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

/// Onboarding step (Milestone 2): pick a single club. Replaces the previous
/// silent auto-join-by-archetype behavior; the user's explicit pick is
/// authoritative and persisted on `UserProfile.joinedClubId`.
///
/// The club pool is filtered to clubs whose `archetypeId` matches the user's
/// selected archetype. Users can still browse the full `/social/all` list
/// (out-of-band) but cannot advance without an explicit pick here.
class ClubScreen extends ConsumerStatefulWidget {
  const ClubScreen({super.key});

  @override
  ConsumerState<ClubScreen> createState() => _ClubScreenState();
}

class _ClubScreenState extends ConsumerState<ClubScreen> {
  Tribe? _selectedClub;
  bool _isSaving = false;

  bool get _canContinue => _selectedClub != null;

  Future<void> _onContinue() async {
    if (!_canContinue || _isSaving) return;
    final club = _selectedClub!;
    setState(() => _isSaving = true);
    try {
      // The state-side record keeps the join eager; actual join happens below.
      await ref
          .read(enhancedOnboardingProvider.notifier)
          .setClub(club.id);

      // Skip the explicit auto-join guard: we want the user to be a member
      // of the club they just picked.
      final user =
          ref.read(authStateChangesProvider).value;
      if (user != null && user.isNotEmpty) {
        try {
          await ref
              .read(tribeRepositoryProvider)
              .joinClub(user.id, club.id);
        } catch (e, s) {
          AppLogger.e(
            'ClubScreen: joinClub failed (will retry on next launch)',
            e,
            s,
          );
        }
      }

      await ref
          .read(enhancedOnboardingProvider.notifier)
          .completeMilestone(2);

      if (!mounted) return;
      context.push('/onboarding/first-habits');
    } catch (e, s) {
      AppLogger.e('ClubScreen: failed to save', e, s);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final archetype = ref
            .watch(enhancedOnboardingProvider)
            .selectedArchetype ??
        UserArchetype.none;
    final theme = ArchetypeTheme.forArchetype(archetype);
    final poolAsync = ref.watch(archetypeClubsProvider);

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
                stepIndex: 2,
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
                        'Pick your club',
                        style: GoogleFonts.splineSans(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ).animate().fadeIn().moveY(begin: 10, end: 0),
                      const Gap(8),
                      Text(
                        'A club for ${theme.archetypeName.toLowerCase()} '
                        'movers — pick one to anchor your tribe.',
                        style: GoogleFonts.splineSans(
                          color: Colors.white54,
                          fontSize: 16,
                        ),
                      ).animate().fadeIn(delay: 100.ms),
                      const Gap(24),
                      poolAsync.when(
                        data: (clubs) {
                          if (clubs.isEmpty) {
                            return const _EmptyState();
                          }
                          return Column(
                            children: [
                              for (final club in clubs) ...[
                                _ClubCard(
                                  club: club,
                                  isSelected: _selectedClub?.id == club.id,
                                  onTap: () {
                                    setState(() => _selectedClub = club);
                                    HapticFeedback.lightImpact();
                                  },
                                ),
                                const Gap(12),
                              ],
                            ],
                          );
                        },
                        loading: () => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 80),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF2BEE79),
                            ),
                          ),
                        ),
                        error: (err, _) => _ErrorState(
                          message: err.toString(),
                        ),
                      ),
                      const Gap(80),
                    ],
                  ),
                ),
              ),
              _BottomBar(
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

/// Same as the existing `tribesProvider` pool but for any tribe whose
/// archetypeId matches the user's archetype. Falls back to [] on error.
final archetypeClubsProvider = FutureProvider<List<Tribe>>((ref) async {
  final archetype = ref
      .watch(enhancedOnboardingProvider)
      .selectedArchetype;
  if (archetype == null || archetype == UserArchetype.none) {
    return const [];
  }
  try {
    final repo = ref.read(tribeRepositoryProvider);
    final clubs = await repo.getArchetypeClubs();
    return clubs
        .where((c) => c.archetypeId == archetype.name)
        .take(6)
        .toList();
  } catch (e, s) {
    AppLogger.e('archetypeClubsProvider: failed to load clubs', e, s);
    return const [];
  }
});

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

class _ClubCard extends StatelessWidget {
  final Tribe club;
  final bool isSelected;
  final VoidCallback onTap;

  const _ClubCard({
    required this.club,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1A2C24)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2BEE79)
                : Colors.white10,
            width: 1.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF2BEE79).withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.groups,
                color: isSelected
                    ? const Color(0xFF2BEE79)
                    : Colors.white70,
              ),
            ),
            const Gap(16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    club.name,
                    style: GoogleFonts.splineSans(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Gap(4),
                  if (club.description.isNotEmpty)
                    Text(
                      club.description,
                      style: GoogleFonts.splineSans(
                        color: Colors.white54,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  if (club.tags.isNotEmpty) ...[
                    const Gap(8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final tag in club.tags.take(3))
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                            ),
                            child: Text(
                              tag,
                              style: GoogleFonts.splineSans(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(
                  Icons.check_circle,
                  color: Color(0xFF2BEE79),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          const Icon(
            Icons.group_off_outlined,
            color: Colors.white24,
            size: 48,
          ),
          const Gap(16),
          Text(
            'No clubs for this archetype yet.',
            style: GoogleFonts.splineSans(
              color: Colors.white54,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;

  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Text(
        'Could not load clubs: $message',
        style: GoogleFonts.splineSans(
          color: Colors.redAccent,
          fontSize: 13,
        ),
      ),
    );
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
                      'JOIN & CONTINUE',
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
