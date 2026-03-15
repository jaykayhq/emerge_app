import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:emerge_app/core/domain/entities/cue.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
import 'package:emerge_app/core/theme/emerge_earthy_theme.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';

/// CUE POPUP WIDGETS - Visual Implementation of "Make It Obvious"
///
/// These widgets implement the psychological principles of effective cues:
/// 1. VISUAL SALIENCE: Cues stand out from the interface
/// 2. CLEAR ACTION: Single, obvious next step
/// 3. EMOTIONAL RESONANCE: Archetype-personalized messaging
/// 4. FRICTIONLESS DISMISSAL: Easy to close but engaging enough to act
///
/// DESIGN PATTERNS:
/// - Modal popups for urgent cues (streak at risk, milestones)
/// - Banner cues for gentle reminders
/// - Toast notifications for quick confirmations
/// - Subtle UI hints for ongoing habits

/// Main Cue Popup Dialog - The primary in-app cue display
///
/// Uses a bottom sheet design that:
/// - Feels natural on mobile (thumb-friendly actions)
/// - Allows partial dismissal (swipe down to dismiss)
/// - Provides clear action buttons
/// - Shows archetype-themed visuals
class CuePopupDialog extends ConsumerStatefulWidget {
  final Cue cue;
  final VoidCallback? onActionTaken;
  final VoidCallback? onDismissed;

  const CuePopupDialog({
    super.key,
    required this.cue,
    this.onActionTaken,
    this.onDismissed,
  });

  @override
  ConsumerState<CuePopupDialog> createState() => _CuePopupDialogState();
}

class _CuePopupDialogState extends ConsumerState<CuePopupDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _animationController.forward();

    // Haptic feedback on show
    HapticFeedback.mediumImpact();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final archetype = UserArchetype.values.firstWhere(
      (a) => a.name == widget.cue.userArchetype,
      orElse: () => UserArchetype.none,
    );

    final primaryColor = _getArchetypeColor(archetype);

    return GestureDetector(
      onTap: () => _handleDismiss(),
      child: Container(
        color: Colors.black.withValues(alpha: 0.6),
        child: Center(
          child: GestureDetector(
            onTap: () {}, // Prevent tap-through
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF1A1A2E),
                        const Color(0xFF0F0F1A),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: primaryColor.withValues(alpha: 0.5),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.3),
                        blurRadius: 30,
                        spreadRadius: -5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHeader(archetype, primaryColor),
                      const SizedBox(height: 20),
                      _buildContent(archetype, primaryColor),
                      const SizedBox(height: 24),
                      _buildActionButtons(primaryColor),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(UserArchetype archetype, Color primaryColor) {
    return Row(
      children: [
        // Archetype icon
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(
              color: primaryColor.withValues(alpha: 0.5),
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              _getArchetypeEmoji(archetype),
              style: const TextStyle(fontSize: 28),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.cue.personalizedTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _getCategoryLabel(widget.cue.category),
                style: TextStyle(
                  color: primaryColor.withValues(alpha: 0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
        // Dismiss button
        GestureDetector(
          onTap: _handleDismiss,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.close,
              color: Colors.white70,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(UserArchetype archetype, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        widget.cue.personalizedBody,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildActionButtons(Color primaryColor) {
    switch (widget.cue.category) {
      case CueCategory.initiation:
        return _buildInitiationActions(primaryColor);
      case CueCategory.recovery:
        return _buildRecoveryActions(primaryColor);
      case CueCategory.celebration:
        return _buildCelebrationActions(primaryColor);
      case CueCategory.social:
        return _buildSocialActions(primaryColor);
      default:
        return _buildDefaultActions(primaryColor);
    }
  }

  Widget _buildInitiationActions(Color primaryColor) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _handleDismiss,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Later',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: _handleAction,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor, primaryColor.withValues(alpha: 0.8)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Text(
                'Start Now',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecoveryActions(Color primaryColor) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _handleAction,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        EmergeEarthyColors.terracotta,
                        EmergeEarthyColors.terracotta.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.restore, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Recover Streak',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _handleDismiss,
          child: Text(
            'I\'ll do it later',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCelebrationActions(Color primaryColor) {
    return GestureDetector(
      onTap: _handleAction,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              EmergeColors.yellow,
              EmergeEarthyColors.sand,
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🎉', style: TextStyle(fontSize: 20)),
            SizedBox(width: 8),
            Text(
              'Claim Reward',
              style: TextStyle(
                color: Color(0xFF1A1A2E),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialActions(Color primaryColor) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _handleDismiss,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Dismiss',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: _handleAction,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: EmergeColors.teal,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'View Activity',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultActions(Color primaryColor) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _handleAction,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Got It',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _handleAction() {
    HapticFeedback.heavyImpact();
    widget.onActionTaken?.call();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _handleDismiss() {
    HapticFeedback.lightImpact();
    widget.onDismissed?.call();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Color _getArchetypeColor(UserArchetype archetype) {
    switch (archetype) {
      case UserArchetype.athlete:
        return EmergeEarthyColors.sienna;
      case UserArchetype.scholar:
        return const Color(0xFF6B5B95);
      case UserArchetype.creator:
        return const Color(0xFFB76E79);
      case UserArchetype.stoic:
        return const Color(0xFF8B9DC3);
      case UserArchetype.zealot:
        return EmergeEarthyColors.terracotta;
      case UserArchetype.none:
        return EmergeColors.teal;
    }
  }

  String _getArchetypeEmoji(UserArchetype archetype) {
    switch (archetype) {
      case UserArchetype.athlete:
        return '💪';
      case UserArchetype.scholar:
        return '📚';
      case UserArchetype.creator:
        return '🎨';
      case UserArchetype.stoic:
        return '🏛️';
      case UserArchetype.zealot:
        return '🔥';
      case UserArchetype.none:
        return '✨';
    }
  }

  String _getCategoryLabel(CueCategory category) {
    switch (category) {
      case CueCategory.initiation:
        return 'HABIT REMINDER';
      case CueCategory.completion:
        return 'WELL DONE';
      case CueCategory.social:
        return 'SOCIAL UPDATE';
      case CueCategory.celebration:
        return 'MILESTONE';
      case CueCategory.recovery:
        return 'STREAK RECOVERY';
      case CueCategory.discovery:
        return 'SUGGESTION';
      case CueCategory.reflection:
        return 'DAILY REFLECTION';
      case CueCategory.motivation:
        return 'MOTIVATION';
    }
  }
}

/// Cue Banner Widget - Non-modal, dismissible top banner
///
/// Used for:
/// - Gentle reminders
/// - Social proof notifications
/// - Quick updates
/// - Non-urgent information
class CueBanner extends StatelessWidget {
  final Cue cue;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const CueBanner({
    super.key,
    required this.cue,
    this.onTap,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final archetype = UserArchetype.values.firstWhere(
      (a) => a.name == cue.userArchetype,
      orElse: () => UserArchetype.none,
    );

    final primaryColor = _getArchetypeColor(archetype);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor.withValues(alpha: 0.15),
            primaryColor.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _getCategoryEmoji(cue.category),
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cue.personalizedTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  cue.personalizedBody,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Dismiss button
          if (onDismiss != null)
            GestureDetector(
              onTap: onDismiss,
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.close,
                  color: primaryColor.withValues(alpha: 0.6),
                  size: 18,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getArchetypeColor(UserArchetype archetype) {
    switch (archetype) {
      case UserArchetype.athlete:
        return EmergeEarthyColors.sienna;
      case UserArchetype.scholar:
        return const Color(0xFF6B5B95);
      case UserArchetype.creator:
        return const Color(0xFFB76E79);
      case UserArchetype.stoic:
        return const Color(0xFF8B9DC3);
      case UserArchetype.zealot:
        return EmergeEarthyColors.terracotta;
      case UserArchetype.none:
        return EmergeColors.teal;
    }
  }

  String _getCategoryEmoji(CueCategory category) {
    switch (category) {
      case CueCategory.initiation:
        return '⏰';
      case CueCategory.completion:
        return '✅';
      case CueCategory.social:
        return '👥';
      case CueCategory.celebration:
        return '🎉';
      case CueCategory.recovery:
        return '🔄';
      case CueCategory.discovery:
        return '💡';
      case CueCategory.reflection:
        return '🤔';
      case CueCategory.motivation:
        return '🔥';
    }
  }
}

/// Subtle Cue Hint - Small visual indicator for ongoing habits
///
/// Used for:
/// - Habit availability indicators
/// - Progress nudges
/// - Micro-reminders
class SubtleCueHint extends StatefulWidget {
  final Widget child;
  final bool isActive;
  final Color? activeColor;
  final VoidCallback? onTap;

  const SubtleCueHint({
    super.key,
    required this.child,
    this.isActive = false,
    this.activeColor,
    this.onTap,
  });

  @override
  State<SubtleCueHint> createState() => _SubtleCueHintState();
}

class _SubtleCueHintState extends State<SubtleCueHint>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.isActive) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(SubtleCueHint oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.activeColor ?? EmergeColors.teal;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: widget.isActive
                  ? [
                      BoxShadow(
                        color: activeColor.withValues(
                          alpha: 0.3 * _pulseAnimation.value,
                        ),
                        blurRadius: 12 * _pulseAnimation.value,
                        spreadRadius: 2 * _pulseAnimation.value,
                      ),
                    ]
                  : null,
            ),
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

/// Streak Protection Dialog - Special dialog for "Never Miss Twice"
///
/// Implements the recovery cue with:
/// - Compassionate messaging
/// - Clear path to redemption
/// - Reduced friction (two-minute version)
class StreakProtectionDialog extends ConsumerWidget {
  final String habitTitle;
  final int currentStreak;
  final String? twoMinuteVersion;
  final VoidCallback onRecover;

  const StreakProtectionDialog({
    super.key,
    required this.habitTitle,
    required this.currentStreak,
    this.twoMinuteVersion,
    required this.onRecover,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2A1F1A), Color(0xFF1A1512)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: EmergeEarthyColors.terracotta.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Warning icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: EmergeEarthyColors.terracotta.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_rounded,
                color: EmergeEarthyColors.terracotta,
                size: 32,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            const Text(
              'Streak at Risk',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Message
            Text(
              'You missed "$habitTitle" yesterday.\n'
              'Your $currentStreak-day streak is protected.\n\n'
              'Complete it now to keep your momentum alive!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),

            // Two-minute version (if available)
            if (twoMinuteVersion != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: EmergeEarthyColors.sienna.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: EmergeEarthyColors.sienna.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      color: EmergeEarthyColors.sienna,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Quick version: $twoMinuteVersion',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Skip Today',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: () {
                      onRecover();
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            EmergeEarthyColors.terracotta,
                            EmergeEarthyColors.terracotta.withValues(alpha: 0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.restore, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Recover Streak',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Social Proof Toast - Quick notification for friend activity
///
/// Shows brief, non-intrusive updates about:
/// - Friend completing habits
/// - Tribe achievements
/// - Challenge progress
class SocialProofToast extends StatelessWidget {
  final String friendName;
  final String habitTitle;
  final String? friendArchetype;
  final VoidCallback? onTap;

  const SocialProofToast({
    super.key,
    required this.friendName,
    required this.habitTitle,
    this.friendArchetype,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              EmergeColors.teal.withValues(alpha: 0.9),
              EmergeColors.teal.withValues(alpha: 0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: EmergeColors.teal.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  friendName.isNotEmpty ? friendName[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$friendName completed $habitTitle',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Keep the momentum going!',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Colors.white70,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

/// Milestone Celebration Dialog - Special dialog for achievements
///
/// Implements the celebration cue with:
/// - Visual spectacle (confetti, animations)
/// - Social sharing options
/// - Clear acknowledgment of progress
class MilestoneCelebrationDialog extends ConsumerWidget {
  final String habitTitle;
  final int milestoneDays;
  final int xpGained;
  final UserArchetype archetype;
  final VoidCallback onContinue;

  const MilestoneCelebrationDialog({
    super.key,
    required this.habitTitle,
    required this.milestoneDays,
    required this.xpGained,
    required this.archetype,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primaryColor = _getArchetypeColor(archetype);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [
              primaryColor.withValues(alpha: 0.3),
              const Color(0xFF1A1A2E),
            ],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: primaryColor.withValues(alpha: 0.6),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Trophy icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    EmergeColors.yellow,
                    EmergeEarthyColors.sand,
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: EmergeColors.yellow.withValues(alpha: 0.5),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.emoji_events,
                color: Color(0xFF1A1A2E),
                size: 48,
              ),
            ),
            const SizedBox(height: 24),

            // Milestone text
            Text(
              '$milestoneDays Days!',
              style: const TextStyle(
                color: EmergeColors.yellow,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),

            // Habit name
            Text(
              habitTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),

            // XP gained
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: EmergeColors.teal.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: EmergeColors.teal.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bolt, color: EmergeColors.teal, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '+$xpGained XP',
                    style: const TextStyle(
                      color: EmergeColors.teal,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Continue button
            GestureDetector(
              onTap: onContinue,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, primaryColor.withValues(alpha: 0.8)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Continue Journey',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getArchetypeColor(UserArchetype archetype) {
    switch (archetype) {
      case UserArchetype.athlete:
        return EmergeEarthyColors.sienna;
      case UserArchetype.scholar:
        return const Color(0xFF6B5B95);
      case UserArchetype.creator:
        return const Color(0xFFB76E79);
      case UserArchetype.stoic:
        return const Color(0xFF8B9DC3);
      case UserArchetype.zealot:
        return EmergeEarthyColors.terracotta;
      case UserArchetype.none:
        return EmergeColors.teal;
    }
  }
}
