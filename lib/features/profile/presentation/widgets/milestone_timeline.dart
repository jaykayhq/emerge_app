import 'package:emerge_app/core/theme/archetype_theme.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:flutter/material.dart';

/// Horizontal milestone timeline showing the user's evolution journey
/// Displays past achievements and upcoming milestones
class MilestoneTimeline extends StatelessWidget {
  final UserArchetype archetype;
  final int currentLevel;
  final double currentXp;
  final double xpForNextLevel;

  const MilestoneTimeline({
    super.key,
    required this.archetype,
    required this.currentLevel,
    required this.currentXp,
    required this.xpForNextLevel,
  });

  static const _milestones = [1, 5, 10, 15, 25, 35, 50, 75, 100];

  @override
  Widget build(BuildContext context) {
    final theme = ArchetypeTheme.forArchetype(archetype);
    final primaryColor = theme.primaryColor;

    return SizedBox(
      height: 110,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              'EVOLUTION JOURNEY',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
                color: primaryColor.withValues(alpha: 0.8),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _milestones.length,
              separatorBuilder: (context, index) => _buildConnector(
                isCompleted: currentLevel >= _milestones[index + 1],
                primaryColor: primaryColor,
              ),
              itemBuilder: (context, index) {
                final level = _milestones[index];
                final isCompleted = currentLevel >= level;
                final isCurrent = currentLevel == level;
                final isNext =
                    !isCompleted &&
                    (index == 0 || currentLevel >= _milestones[index - 1]);

                return _MilestoneNode(
                  level: level,
                  isCompleted: isCompleted,
                  isCurrent: isCurrent,
                  isNext: isNext,
                  primaryColor: primaryColor,
                  reward: _getRewardForLevel(level),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnector({
    required bool isCompleted,
    required Color primaryColor,
  }) {
    return Container(
      width: 30,
      height: 2,
      margin: const EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        color: isCompleted
            ? primaryColor.withValues(alpha: 0.6)
            : Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }

  String _getRewardForLevel(int level) {
    switch (level) {
      case 1:
        return 'Begin';
      case 5:
        return 'Apprentice';
      case 10:
        return 'Adept';
      case 15:
        return 'Expert';
      case 25:
        return 'Master';
      case 35:
        return 'Legend';
      case 50:
        return 'Mythic';
      case 75:
        return 'Ascended';
      case 100:
        return 'Transcended';
      default:
        return 'Level $level';
    }
  }
}

class _MilestoneNode extends StatelessWidget {
  final int level;
  final bool isCompleted;
  final bool isCurrent;
  final bool isNext;
  final Color primaryColor;
  final String reward;

  const _MilestoneNode({
    required this.level,
    required this.isCompleted,
    required this.isCurrent,
    required this.isNext,
    required this.primaryColor,
    required this.reward,
  });

  @override
  Widget build(BuildContext context) {
    final nodeSize = isCurrent ? 44.0 : 36.0;
    final isActive = isCompleted || isCurrent;

    return SizedBox(
      width: 70,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Milestone node
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: nodeSize,
            height: nodeSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? primaryColor.withValues(alpha: 0.25)
                  : Colors.white.withValues(alpha: 0.05),
              border: Border.all(
                color: isActive
                    ? primaryColor
                    : Colors.white.withValues(alpha: 0.2),
                width: isCurrent ? 2.5 : 1.5,
              ),
              boxShadow: isCurrent
                  ? [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.5),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: isCompleted
                  ? Icon(Icons.check_rounded, size: 18, color: primaryColor)
                  : Text(
                      '$level',
                      style: TextStyle(
                        fontSize: isCurrent ? 14 : 12,
                        fontWeight: FontWeight.bold,
                        color: isActive
                            ? primaryColor
                            : Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 6),
          // Reward label
          Text(
            reward,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
              color: isActive
                  ? Colors.white.withValues(alpha: 0.8)
                  : Colors.white.withValues(alpha: 0.35),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
