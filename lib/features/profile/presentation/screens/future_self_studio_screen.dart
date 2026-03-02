import 'package:emerge_app/core/constants/gamification_constants.dart';
import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/core/theme/archetype_theme.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/avatar/domain/models/avatar_config.dart';
import 'package:emerge_app/features/avatar/presentation/widgets/avatar_renderer.dart';
import 'package:emerge_app/features/gamification/presentation/providers/gamification_providers.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:emerge_app/features/profile/domain/models/silhouette_evolution.dart';
import 'package:emerge_app/features/profile/presentation/widgets/decay_recovery_overlay.dart';
import 'package:emerge_app/features/profile/presentation/widgets/evolving_silhouette_widget.dart';
import 'package:emerge_app/features/profile/presentation/widgets/future_self_cosmic_background.dart';
import 'package:emerge_app/features/profile/presentation/widgets/trajectory_timeline.dart';
import 'package:emerge_app/features/profile/presentation/widgets/synergy_status_card.dart';
import 'package:emerge_app/features/profile/presentation/widgets/synergy_card.dart';
import 'package:emerge_app/features/profile/presentation/widgets/emerge_splash_reveal.dart';
import 'package:emerge_app/features/tutorial/presentation/providers/tutorial_provider.dart';
import 'package:emerge_app/features/tutorial/presentation/widgets/tutorial_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Provider to track recovery animation state
final _recoveryAnimatingProvider = StateProvider<bool>((ref) => false);

/// Provider to enable the new 2D isometric avatar renderer
/// Set to true to use the new AvatarRenderer instead of EvolvingSilhouetteWidget
final _useNewAvatarRendererProvider = StateProvider<bool>((ref) => false);

/// The "Future Self Studio" - the new profile screen
/// Features: Animated background, archetype avatar with glowing attribute auras,
/// milestone timeline, and synergy card with glassmorphism
class FutureSelfStudioScreen extends ConsumerStatefulWidget {
  const FutureSelfStudioScreen({super.key});

  @override
  ConsumerState<FutureSelfStudioScreen> createState() =>
      _FutureSelfStudioScreenState();
}

class _FutureSelfStudioScreenState
    extends ConsumerState<FutureSelfStudioScreen> {
  int? _previousStreak;
  final GlobalKey _identityKey = GlobalKey();
  final GlobalKey _avatarKey = GlobalKey();
  final GlobalKey _xpKey = GlobalKey();
  final GlobalKey _timelineKey = GlobalKey();
  final GlobalKey _synergyKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _checkTutorial();
  }

  void _checkTutorial() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tutorialState = ref.read(tutorialProvider);
      if (!tutorialState.isCompleted(TutorialStep.profile)) {
        _showTutorial();
      }
    });
  }

  void _showTutorial() {
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => TutorialOverlay(
        steps: [
          const TutorialStepInfo(
            title: 'Your Future Self',
            description:
                'This is the projection of who you are becoming. Every habit you complete shapes this form.',
          ),
          TutorialStepInfo(
            title: 'Archetype Alignment',
            description:
                'Your chosen archetype defines your unique growth path and visual evolution.',
            targetKey: _identityKey,
          ),
          TutorialStepInfo(
            title: 'The Avatar',
            description:
                'As you level up, your avatar evolves through five distinct phases of emergence.',
            targetKey: _avatarKey,
          ),
          TutorialStepInfo(
            title: 'Evolution XP',
            description:
                'Track your overall level progress. Each level up unlocks new world nodes and avatar features.',
            targetKey: _xpKey,
          ),
          TutorialStepInfo(
            title: 'Trajectory',
            description:
                'See your projected growth over time based on your current consistency.',
            targetKey: _timelineKey,
            alignment: Alignment.topCenter,
          ),
          TutorialStepInfo(
            title: 'Identity Synergy',
            description:
                'Discover how your different habits combine to create unique identity strengths.',
            targetKey: _synergyKey,
            alignment: Alignment.topCenter,
          ),
        ],
        onCompleted: () {
          ref
              .read(tutorialProvider.notifier)
              .completeStep(TutorialStep.profile);
          entry.remove();
        },
      ),
    );
    Overlay.of(context).insert(entry);
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(userStatsStreamProvider);
    final isRecovering = ref.watch(_recoveryAnimatingProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A), // Cosmic void dark
      body: statsAsync.when(
        data: (profile) {
          final stats = profile.avatarStats;

          // Detect recovery: streak was 0 but now > 0
          if (_previousStreak != null &&
              _previousStreak == 0 &&
              stats.streak > 0) {
            // Trigger recovery animation
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(_recoveryAnimatingProvider.notifier).state = true;
            });
          }
          _previousStreak = stats.streak;

          // Calculate attributes from stats
          final attributes = _calculateAttributes(stats);

          // Find top two attributes for synergy
          final sortedAttributes = attributes.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          final primaryAttribute = sortedAttributes.isNotEmpty
              ? sortedAttributes[0].key
              : 'Focus';
          final secondaryAttribute = sortedAttributes.length > 1
              ? sortedAttributes[1].key
              : 'Discipline';

          // Calculate growth multiplier based on consistency
          final effectiveLevel = profile.effectiveLevel;
          final growthMultiplier = 1.0 + (effectiveLevel * 0.05).clamp(0, 1);

          // Get archetype rank
          final archetypeRank = _getArchetypeRank(effectiveLevel);

          // World theme based on archetype
          final worldTheme = _getWorldTheme(profile.archetype);
          final archetypeTheme = ArchetypeTheme.forArchetype(profile.archetype);
          final accentColor = archetypeTheme.primaryColor;

          return Stack(
            children: [
              // Animated Cosmic Background
              Positioned.fill(
                child: FutureSelfCosmicBackground(
                  archetype: profile.archetype,
                  level: effectiveLevel,
                ),
              ),

              // Main content
              CustomScrollView(
                slivers: [
                  // App Bar
                  SliverAppBar(
                    backgroundColor: Colors.transparent,
                    floating: true,
                    actions: [
                      IconButton(
                        icon: const Icon(
                          Icons.settings,
                          color: AppTheme.textMainDark,
                        ),
                        onPressed: () => context.push('/profile/settings'),
                      ),
                    ],
                    title: Column(
                      children: [
                        Text(
                          'FUTURE SELF',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: AppTheme.textMainDark,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '● IDENTITY CALIBRATED',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: accentColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                      ],
                    ),
                    centerTitle: true,
                  ),

                  // Identity header (archetype + level)
                  SliverToBoxAdapter(
                    child: Container(
                      key: _identityKey,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'IDENTITY',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: AppTheme.textSecondaryDark,
                                      letterSpacing: 1,
                                    ),
                              ),
                              Text(
                                '${_getArchetypeName(profile.archetype)} Archetype',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: AppTheme.textMainDark,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: accentColor.withValues(alpha: 0.4),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'LVL $effectiveLevel',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: accentColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 16)),

                  // NEW: Evolving Silhouette with 5-tier system + decay/recovery
                  // OR: New 2D Isometric Avatar Renderer (toggle via _useNewAvatarRendererProvider)
                  SliverToBoxAdapter(
                    child: Center(
                      key: _avatarKey,
                      child: ref.watch(_useNewAvatarRendererProvider)
                          ? _buildAvatarRenderer(
                              context,
                              profile.archetype,
                              effectiveLevel,
                              stats.streak,
                              accentColor,
                              ref,
                              isRecovering,
                            )
                          : DecayRecoveryOverlay(
                              entropyLevel: stats.streak > 0 ? 0.0 : 0.5,
                              daysMissed: stats.streak > 0 ? 0 : 1,
                              primaryColor: accentColor,
                              isRecovering: isRecovering,
                              onRecoveryComplete: () {
                                // Reset recovery state after animation
                                ref
                                        .read(
                                          _recoveryAnimatingProvider.notifier,
                                        )
                                        .state =
                                    false;
                              },
                              child: EvolvingSilhouetteWidget(
                                evolutionState:
                                    SilhouetteEvolutionState.fromUserStats(
                                      level: effectiveLevel,
                                      currentStreak: stats.streak,
                                      // Days missed = 0 if active streak, else estimate based on streak reset
                                      daysMissed: stats.streak > 0 ? 0 : 1,
                                      habitVotes: _calculateHabitVotes(stats),
                                    ),
                                archetype: profile.archetype,
                                attributes: attributes,
                                size: 280,
                                onEvolutionTap: () {
                                  HapticFeedback.lightImpact();
                                  _showEvolutionInfo(
                                    context,
                                    effectiveLevel,
                                    accentColor,
                                  );
                                },
                              ),
                            ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),

                  // XP Progress bar
                  SliverToBoxAdapter(
                    child: Padding(
                      key: _xpKey,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'NEXT LEVEL',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: accentColor.withValues(alpha: 0.8),
                                      fontSize: 10,
                                      letterSpacing: 1,
                                    ),
                              ),
                              Text(
                                '${stats.totalXp % GamificationConstants.xpPerLevel}/${GamificationConstants.xpPerLevel} XP',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: AppTheme.textSecondaryDark,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value:
                                  (stats.totalXp %
                                      GamificationConstants.xpPerLevel) /
                                  GamificationConstants.xpPerLevel,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.08,
                              ),
                              valueColor: AlwaysStoppedAnimation(accentColor),
                              minHeight: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),

                  // NEW: Trajectory Timeline (Stitch design)
                  SliverToBoxAdapter(
                    child: TrajectoryTimeline(
                      key: _timelineKey,
                      archetype: profile.archetype,
                      currentLevel: effectiveLevel,
                      currentXp:
                          (stats.totalXp % GamificationConstants.xpPerLevel)
                              .toDouble(),
                      xpForNextLevel: GamificationConstants.xpPerLevel
                          .toDouble(),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),

                  // NEW: Synergy Status Card (Stitch design)
                  SliverToBoxAdapter(
                    child: _buildSynergyStatusCard(ref, accentColor),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),

                  // Synergy Card with glassmorphism
                  SliverToBoxAdapter(
                    child: SynergyCard(
                      key: _synergyKey,
                      primaryAttribute: primaryAttribute,
                      secondaryAttribute: secondaryAttribute,
                      growthMultiplier: growthMultiplier,
                      archetypeRank: archetypeRank,
                      worldTheme: worldTheme,
                      accentColor: accentColor,
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),

                  // Emerge Button (CTA) or Emerged State Card
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: profile.hasEmerged
                          ? _EmergedStateCard(
                              accentColor: accentColor,
                              phase: SilhouetteEvolutionState.phaseFromLevel(
                                stats.level,
                              ),
                            )
                          : _EmergeButton(
                              level: effectiveLevel,
                              onPressed: () {
                                // Show splash reveal then persist emerge to Firestore
                                EmergeSplashReveal.show(
                                  context,
                                  primaryColor: accentColor,
                                  onComplete: () async {
                                    // Persist emerge state via controller
                                    await ref
                                        .read(userStatsControllerProvider)
                                        .emerge();
                                  },
                                );
                              },
                              accentColor: accentColor,
                            ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 40)),
                ],
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: EmergeColors.teal),
        ),
        error: (e, s) => Center(
          child: Text(
            'Error: $e',
            style: TextStyle(color: AppTheme.textMainDark),
          ),
        ),
      ),
    );
  }

  Map<String, double> _calculateAttributes(UserAvatarStats stats) {
    // Normalize stats to 0-1 range (cap at 500 XP per attribute)
    final maxXp = 500.0;
    return {
      'Strength': (stats.strengthXp / maxXp).clamp(0.0, 1.0),
      'Intellect': (stats.intellectXp / maxXp).clamp(0.0, 1.0),
      'Creativity': (stats.creativityXp / maxXp).clamp(0.0, 1.0),
      'Focus': (stats.focusXp / maxXp).clamp(0.0, 1.0),
      'Vitality': (stats.vitalityXp / maxXp).clamp(0.0, 1.0),
      'Spirit': (stats.spiritXp / maxXp).clamp(0.0, 1.0),
      'Resilience': ((stats.strengthXp + stats.focusXp) / 2 / maxXp).clamp(
        0.0,
        1.0,
      ),
    };
  }

  String _getArchetypeRank(int level) {
    if (level >= 50) return 'Legend';
    if (level >= 30) return 'Master';
    if (level >= 15) return 'Adept';
    return 'Initiate';
  }

  String _getArchetypeName(UserArchetype archetype) {
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
        return 'Explorer';
    }
  }

  String _getWorldTheme(UserArchetype archetype) {
    switch (archetype) {
      case UserArchetype.athlete:
        return 'Mountain Fortress';
      case UserArchetype.scholar:
        return 'Crystal Library';
      case UserArchetype.creator:
        return 'Living Forest';
      case UserArchetype.stoic:
        return 'Ancient Temple';
      case UserArchetype.zealot:
        return 'Ethereal Realm';
      case UserArchetype.none:
        return 'Living Forest';
    }
  }

  /// Calculate habit votes from user XP stats for artifact unlocking
  Map<String, int> _calculateHabitVotes(UserAvatarStats stats) {
    // Convert XP to vote counts (every 50 XP = 1 vote)
    return {
      'cardio': (stats.vitalityXp ~/ 50),
      'strength': (stats.strengthXp ~/ 50),
      'mindfulness': (stats.spiritXp ~/ 50),
      'creativity': (stats.creativityXp ~/ 50),
      'hydration': (stats.vitalityXp ~/ 100), // Less frequent
      'learning': (stats.intellectXp ~/ 50),
    };
  }

  /// Show evolution info dialog when silhouette is tapped
  void _showEvolutionInfo(BuildContext context, int level, Color accentColor) {
    final phase = SilhouetteEvolutionState.phaseFromLevel(level);
    final phaseName = phase.name.toUpperCase();
    final phaseDescription = _getPhaseDescription(phase);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Phase: $phaseName',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    phaseDescription,
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: accentColor.withValues(alpha: 0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _getPhaseDescription(EvolutionPhase phase) {
    switch (phase) {
      case EvolutionPhase.phantom:
        return 'You are forming from the void...';
      case EvolutionPhase.construct:
        return 'Your structure is taking shape.';
      case EvolutionPhase.incarnate:
        return 'You have manifested your form.';
      case EvolutionPhase.radiant:
        return 'Your cracks glow with earned wisdom.';
      case EvolutionPhase.ascended:
        return 'You have transcended into pure energy.';
    }
  }

  /// Build Synergy Status Card showing which habits boost which attributes
  Widget _buildSynergyStatusCard(WidgetRef ref, Color accentColor) {
    final userAsync = ref.watch(userProfileProvider);
    final habitsAsync = ref.watch(habitsProvider);

    return userAsync.when(
      data: (profile) {
        if (profile == null) return const SizedBox.shrink();
        return habitsAsync.when(
          data: (habits) {
            return SynergyStatusCard(
              profile: profile,
              accentColor: accentColor,
              habits: habits,
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  /// Build the new 2D isometric avatar renderer
  Widget _buildAvatarRenderer(
    BuildContext context,
    UserArchetype archetype,
    int level,
    int streak,
    Color accentColor,
    WidgetRef ref,
    bool isRecovering,
  ) {
    final avatarConfig = AvatarConfig.fromUserStats(
      archetype: archetype,
      level: level,
    );

    return DecayRecoveryOverlay(
      entropyLevel: streak > 0 ? 0.0 : 0.5,
      daysMissed: streak > 0 ? 0 : 1,
      primaryColor: accentColor,
      isRecovering: isRecovering,
      onRecoveryComplete: () {
        ref.read(_recoveryAnimatingProvider.notifier).state = false;
      },
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          _showEvolutionInfo(context, level, accentColor);
        },
        child: AvatarRenderer(
          config: avatarConfig,
          size: 280,
          showPhaseLabel: true,
        ),
      ),
    );
  }
}

/// Animated EMERGE button with shimmer effect
/// Locked until user reaches level 5
class _EmergeButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Color accentColor;
  final int level;

  const _EmergeButton({
    required this.onPressed,
    required this.accentColor,
    required this.level,
  });

  bool get isLocked => level < 5;

  @override
  State<_EmergeButton> createState() => _EmergeButtonState();
}

class _EmergeButtonState extends State<_EmergeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    // Only animate shimmer when unlocked
    if (!widget.isLocked) {
      _shimmerController.repeat();
    }
  }

  @override
  void didUpdateWidget(_EmergeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isLocked && !_shimmerController.isAnimating) {
      _shimmerController.repeat();
    } else if (widget.isLocked && _shimmerController.isAnimating) {
      _shimmerController.stop();
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Locked state - grayed out with lock icon
    if (widget.isLocked) {
      return _buildLockedButton(context);
    }
    return _buildUnlockedButton(context);
  }

  Widget _buildLockedButton(BuildContext context) {
    final levelsRemaining = 5 - widget.level;
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade600, width: 1),
      ),
      child: ElevatedButton(
        onPressed: () {
          // Show tooltip explaining the lock
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Reach level 5 to unlock! ($levelsRemaining more levels)',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.grey.shade700,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock, color: Colors.grey.shade400, size: 20),
            const SizedBox(width: 8),
            Text(
              'EMERGE',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey.shade500,
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade600,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'LVL 5',
                style: TextStyle(
                  color: Colors.grey.shade300,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnlockedButton(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1.0 + _shimmerController.value * 3, 0),
              end: Alignment(0.0 + _shimmerController.value * 3, 0),
              colors: [
                EmergeColors.teal,
                EmergeColors.violet,
                EmergeColors.teal,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: widget.accentColor.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: widget.onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.flash_on, color: Colors.white, size: 24),
                const SizedBox(width: 8),
                Text(
                  'EMERGE',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// The card displayed after user has "emerged" - shows transformed state
class _EmergedStateCard extends StatefulWidget {
  final Color accentColor;
  final EvolutionPhase phase;

  const _EmergedStateCard({required this.accentColor, required this.phase});

  @override
  State<_EmergedStateCard> createState() => _EmergedStateCardState();
}

class _EmergedStateCardState extends State<_EmergedStateCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.4, end: 0.8).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  String get _phaseTitle {
    switch (widget.phase) {
      case EvolutionPhase.phantom:
        return 'THE PHANTOM';
      case EvolutionPhase.construct:
        return 'THE CONSTRUCT';
      case EvolutionPhase.incarnate:
        return 'THE INCARNATE';
      case EvolutionPhase.radiant:
        return 'THE RADIANT';
      case EvolutionPhase.ascended:
        return 'THE ASCENDED';
    }
  }

  String get _phaseTagline {
    switch (widget.phase) {
      case EvolutionPhase.phantom:
        return 'You have stepped into the unknown';
      case EvolutionPhase.construct:
        return 'Your foundation grows stronger';
      case EvolutionPhase.incarnate:
        return 'You are taking shape';
      case EvolutionPhase.radiant:
        return 'Your light shines through';
      case EvolutionPhase.ascended:
        return 'You have transcended';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.accentColor.withValues(alpha: 0.2),
                EmergeColors.surface,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.accentColor.withValues(alpha: _glowAnim.value),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.accentColor.withValues(
                  alpha: _glowAnim.value * 0.4,
                ),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            children: [
              // Phase icon
              Icon(Icons.auto_awesome, color: widget.accentColor, size: 40),
              const SizedBox(height: 16),
              // Phase title
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [widget.accentColor, EmergeColors.teal],
                ).createShader(bounds),
                child: Text(
                  _phaseTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Tagline
              Text(
                _phaseTagline,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Status indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: EmergeColors.lime,
                      boxShadow: [
                        BoxShadow(
                          color: EmergeColors.lime.withValues(alpha: 0.6),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'EMERGED',
                    style: TextStyle(
                      color: EmergeColors.lime,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
