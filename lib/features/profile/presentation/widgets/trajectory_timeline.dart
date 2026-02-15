import 'dart:ui';
import 'package:emerge_app/core/theme/archetype_theme.dart';
import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:flutter/material.dart';

/// Trajectory Timeline widget matching Stitch AI design
/// Shows progression through milestones with glassmorphism cards
class TrajectoryTimeline extends StatelessWidget {
  final UserArchetype archetype;
  final int currentLevel;
  final double currentXp;
  final double xpForNextLevel;

  const TrajectoryTimeline({
    super.key,
    required this.archetype,
    required this.currentLevel,
    required this.currentXp,
    required this.xpForNextLevel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ArchetypeTheme.forArchetype(archetype);
    final primaryColor = theme.primaryColor;

    // Get milestones for the archetype
    final milestones = _getMilestones(archetype, currentLevel);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Icon(Icons.timeline, color: primaryColor, size: 18),
              const SizedBox(width: 8),
              Text(
                'TRAJECTORY TIMELINE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                  color: primaryColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Horizontal scrolling milestone cards
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: milestones.length,
            itemBuilder: (context, index) {
              final milestone = milestones[index];
              return _TrajectoryCard(
                title: milestone.title,
                description: milestone.description,
                status: milestone.status,
                isCompleted: milestone.isCompleted,
                isCurrent: milestone.isCurrent,
                isLocked: milestone.isLocked,
                primaryColor: primaryColor,
              );
            },
          ),
        ),
      ],
    );
  }

  List<_Milestone> _getMilestones(UserArchetype archetype, int level) {
    // Generate archetype-specific milestones
    switch (archetype) {
      case UserArchetype.athlete:
        return [
          _Milestone(
            title: 'First Workout',
            description: 'Foundation established. Core strength activated.',
            status: MilestoneStatus.completed,
            requiredLevel: 1,
            currentLevel: level,
          ),
          _Milestone(
            title: '7-Day Streak',
            description: 'Consistency unlocked. Discipline evolving.',
            status: level >= 3
                ? MilestoneStatus.completed
                : (level >= 1
                      ? MilestoneStatus.current
                      : MilestoneStatus.locked),
            requiredLevel: 3,
            currentLevel: level,
          ),
          _Milestone(
            title: 'Elite Training',
            description: 'Current Focus. Push your limits daily.',
            status: level >= 10
                ? MilestoneStatus.completed
                : (level >= 3
                      ? MilestoneStatus.current
                      : MilestoneStatus.locked),
            requiredLevel: 10,
            currentLevel: level,
          ),
          _Milestone(
            title: 'Peak Performance',
            description: 'Unlock by maintaining 30-day streak.',
            status: level >= 25
                ? MilestoneStatus.completed
                : MilestoneStatus.locked,
            requiredLevel: 25,
            currentLevel: level,
          ),
        ];

      case UserArchetype.scholar:
        return [
          _Milestone(
            title: 'First Study Session',
            description: 'Knowledge pursuit begins. Mind awakened.',
            status: MilestoneStatus.completed,
            requiredLevel: 1,
            currentLevel: level,
          ),
          _Milestone(
            title: 'Daily Learning',
            description: 'Intellectual habits forming. Wisdom grows.',
            status: level >= 3
                ? MilestoneStatus.completed
                : (level >= 1
                      ? MilestoneStatus.current
                      : MilestoneStatus.locked),
            requiredLevel: 3,
            currentLevel: level,
          ),
          _Milestone(
            title: 'Deep Focus',
            description: 'Current Focus. Master concentration skills.',
            status: level >= 10
                ? MilestoneStatus.completed
                : (level >= 3
                      ? MilestoneStatus.current
                      : MilestoneStatus.locked),
            requiredLevel: 10,
            currentLevel: level,
          ),
          _Milestone(
            title: 'Sage Mind',
            description: 'Unlock by reaching intellectual mastery.',
            status: level >= 25
                ? MilestoneStatus.completed
                : MilestoneStatus.locked,
            requiredLevel: 25,
            currentLevel: level,
          ),
        ];

      default:
        return [
          _Milestone(
            title: 'Journey Begins',
            description: 'First steps taken. Potential unlocked.',
            status: MilestoneStatus.completed,
            requiredLevel: 1,
            currentLevel: level,
          ),
          _Milestone(
            title: 'Building Habits',
            description: 'Consistency forming. Identity shaping.',
            status: level >= 5
                ? MilestoneStatus.completed
                : (level >= 1
                      ? MilestoneStatus.current
                      : MilestoneStatus.locked),
            requiredLevel: 5,
            currentLevel: level,
          ),
          _Milestone(
            title: 'Rising Momentum',
            description: 'Current Focus. Strengthen your foundation.',
            status: level >= 15
                ? MilestoneStatus.completed
                : (level >= 5
                      ? MilestoneStatus.current
                      : MilestoneStatus.locked),
            requiredLevel: 15,
            currentLevel: level,
          ),
          _Milestone(
            title: 'Future Self',
            description: 'Unlock by reaching mastery level.',
            status: level >= 30
                ? MilestoneStatus.completed
                : MilestoneStatus.locked,
            requiredLevel: 30,
            currentLevel: level,
          ),
        ];
    }
  }
}

enum MilestoneStatus { completed, current, locked }

class _Milestone {
  final String title;
  final String description;
  final MilestoneStatus status;
  final int requiredLevel;
  final int currentLevel;

  _Milestone({
    required this.title,
    required this.description,
    required this.status,
    required this.requiredLevel,
    required this.currentLevel,
  });

  bool get isCompleted => currentLevel >= requiredLevel;
  bool get isCurrent => status == MilestoneStatus.current;
  bool get isLocked => status == MilestoneStatus.locked && !isCompleted;
}

class _TrajectoryCard extends StatelessWidget {
  final String title;
  final String description;
  final MilestoneStatus status;
  final bool isCompleted;
  final bool isCurrent;
  final bool isLocked;
  final Color primaryColor;

  const _TrajectoryCard({
    required this.title,
    required this.description,
    required this.status,
    required this.isCompleted,
    required this.isCurrent,
    required this.isLocked,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = isCurrent
        ? primaryColor
        : (isCompleted ? EmergeColors.teal : Colors.grey);

    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: isCurrent ? 0.12 : 0.06),
                  Colors.white.withValues(alpha: isCurrent ? 0.05 : 0.02),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isCurrent
                    ? primaryColor.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.1),
                width: isCurrent ? 1.5 : 1,
              ),
              boxShadow: isCurrent
                  ? [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.2),
                        blurRadius: 12,
                        spreadRadius: -2,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isCompleted
                                ? Icons.check_circle
                                : (isCurrent
                                      ? Icons.radio_button_checked
                                      : Icons.lock),
                            size: 12,
                            color: accentColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isCompleted
                                ? 'COMPLETE'
                                : (isCurrent ? 'CURRENT' : 'LOCKED'),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: accentColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Title
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: isLocked
                        ? AppTheme.textSecondaryDark
                        : AppTheme.textMainDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),

                // Description
                Expanded(
                  child: Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isLocked
                          ? AppTheme.textSecondaryDark.withValues(alpha: 0.6)
                          : AppTheme.textSecondaryDark,
                      height: 1.3,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
