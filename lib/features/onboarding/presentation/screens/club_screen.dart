import 'package:emerge_app/core/theme/archetype_theme.dart';
import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/onboarding/presentation/providers/onboarding_state_notifier.dart';
import 'package:emerge_app/features/onboarding/presentation/widgets/club_box_card.dart';
import 'package:emerge_app/features/onboarding/presentation/widgets/club_emblem_images.dart';
import 'package:emerge_app/features/onboarding/presentation/widgets/club_preview_sheet.dart';
import 'package:emerge_app/features/social/domain/models/tribe.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:emerge_app/features/onboarding/presentation/widgets/onboarding_progress_bar.dart';
import 'package:google_fonts/google_fonts.dart';

/// Onboarding step (Milestone 2): pick a single club. Redesigned (Plan 5,
/// Task 6) as a 3-column grid of compact [ClubBoxCard]s (4-column on
/// tablets). Tapping a card opens a [ClubPreviewSheet] with a "JOIN CLUB"
/// button; joining persists the pick on `UserProfile.joinedClubId` and
/// advances. The step is skippable via the "Skip" link in the header.
///
/// The club pool is filtered to clubs whose `archetypeId` matches the user's
/// selected archetype. Initially 6 clubs are shown; "See more clubs →"
/// expands the grid to ~15.
class ClubScreen extends ConsumerStatefulWidget {
  const ClubScreen({super.key});

  @override
  ConsumerState<ClubScreen> createState() => _ClubScreenState();
}

class _ClubScreenState extends ConsumerState<ClubScreen> {
  bool _isSaving = false;
  bool _showAll = false;

  /// Joins [club] (state record + membership), completes the milestone and
  /// advances. Called by the preview sheet's "JOIN CLUB" button.
  Future<void> _joinClub(Tribe club) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      // The state-side record keeps the join eager; actual join happens below.
      await ref.read(enhancedOnboardingProvider.notifier).setClub(club.id);

      // Skip the explicit auto-join guard: we want the user to be a member
      // of the club they just picked.
      final user = ref.read(authStateChangesProvider).value;
      if (user != null && user.isNotEmpty) {
        try {
          await ref
              .read(tribeRepositoryProvider)
              .joinClub(user.id, club.id);
        } catch (e, s) {
          AppLogger.e('ClubScreen: joinClub failed', e, s);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Could not join ${club.name}. Retrying…'),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
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

  /// Skips the club pick entirely: complete the milestone and advance
  /// without joining (mirrors FirstHabitsScreen's skip pattern).
  void _onSkip() {
    if (_isSaving) return;
    ref.read(enhancedOnboardingProvider.notifier).completeMilestone(2);
    context.push('/onboarding/first-habits');
  }

  void _openPreview(Tribe club) {
    HapticFeedback.lightImpact();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ClubPreviewSheet(
        title: club.name,
        description: club.description,
        benefits: _benefitsFor(club),
        onJoin: () => _joinClub(club),
      ),
    );
  }

  List<String> _benefitsFor(Tribe club) {
    return [
      'Join ${club.memberCount} members on the same path',
      'Club challenges and shared XP (Lv ${club.level})',
      if (club.tags.isNotEmpty)
        'Focused on ${club.tags.take(3).join(', ')}'
      else
        'A tribe to anchor your habits',
    ];
  }

  String _activityStatusFor(Tribe club) {
    return club.memberCount >= 10 ? '🔥 Active' : '🌙 Quiet';
  }

  String _typeTagFor(Tribe club) {
    return club.archetypeId != null ? 'ARCHETYPE' : 'CREATOR';
  }

  @override
  Widget build(BuildContext context) {
    final archetype = ref
            .watch(enhancedOnboardingProvider)
            .selectedArchetype ??
        UserArchetype.none;
    final theme = ArchetypeTheme.forArchetype(archetype);
    final poolAsync = ref.watch(archetypeClubsProvider);
    final columns = MediaQuery.of(context).size.width > 600 ? 4 : 3;

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
                        'movers — tap one to preview it.',
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
                          final visible = _showAll
                              ? clubs
                              : clubs.take(6).toList();
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GridView.builder(
                                shrinkWrap: true,
                                physics:
                                    const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columns,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                  childAspectRatio: 0.75,
                                ),
                                itemCount: visible.length,
                                itemBuilder: (context, index) {
                                  final club = visible[index];
                                  return ClubBoxCard(
                                    title: club.name,
                                    imageUrl: clubEmblemImageUrl(
                                      existingImageUrl: club.imageUrl,
                                      archetypeId: club.archetypeId,
                                      clubId: club.id,
                                    ),
                                    memberCount: club.memberCount,
                                    activityStatus:
                                        _activityStatusFor(club),
                                    typeTag: _typeTagFor(club),
                                    onTap: () => _openPreview(club),
                                  );
                                },
                              ),
                              if (!_showAll && clubs.length > 6) ...[
                                const Gap(16),
                                Center(
                                  child: TextButton(
                                    onPressed: () =>
                                        setState(() => _showAll = true),
                                    child: Text(
                                      'See more clubs →',
                                      style: GoogleFonts.splineSans(
                                        color: Colors.cyanAccent,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
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
                      const Gap(40),
                    ],
                  ),
                ),
              ),
              if (_isSaving)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF2BEE79),
                    ),
                  ),
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
/// Returns up to 15 clubs; the screen shows 6 until "See more clubs →".
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
        .take(15)
        .toList();
  } catch (e, s) {
    AppLogger.e('archetypeClubsProvider: failed to load clubs', e, s);
    return const [];
  }
});

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
              style: GoogleFonts.splineSans(
                color: Colors.white54,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
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
      child: Center(
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
