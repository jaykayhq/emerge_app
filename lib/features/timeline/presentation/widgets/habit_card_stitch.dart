import 'dart:ui';
import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:flutter/material.dart';

/// Glassmorphism habit card with neon progress ring
/// Matches Stitch-generated design: frosted glass effect, colored progress rings
class HabitCardStitch extends StatelessWidget {
  final Habit habit;
  final bool isCompleted;
  final bool isChild; // Add isChild parameter
  final VoidCallback? onToggle;
  final VoidCallback? onTap;

  const HabitCardStitch({
    super.key,
    required this.habit,
    this.isCompleted = false,
    this.isChild = false, // Default to false
    this.onToggle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final neonColor = _getAttributeColor(habit.attribute);
    final progress = isCompleted
        ? 1.0
        : (habit.currentStreak / 7).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          // Connector line for child habits
          if (isChild)
            Positioned(
              left: 28,
              top: -6, // Connect to item above
              bottom: 30, // Curve into current item
              child: CustomPaint(
                painter: _ConnectorPainter(
                  color: neonColor.withValues(alpha: 0.3),
                ),
                size: const Size(20, 60),
              ),
            ),

          Container(
            // Indent if child
            margin: EdgeInsets.fromLTRB(isChild ? 48 : 16, 6, 16, 6),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.1),
                        Colors.white.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: neonColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: neonColor.withValues(alpha: 0.1),
                        blurRadius: 20,
                        spreadRadius: -5,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Row(
                        children: [
                          // Neon progress ring
                          _buildProgressRing(progress, neonColor),
                          const SizedBox(width: 16),
                          // Habit info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  habit.title,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: AppTheme.textMainDark,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      _getAttributeIcon(habit.attribute),
                                      size: 14,
                                      color: neonColor.withValues(alpha: 0.8),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _formatTimeOfDay(habit.reminderTime),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppTheme.textSecondaryDark,
                                          ),
                                    ),
                                    if (habit.currentStreak > 0) ...[
                                      const SizedBox(width: 12),
                                      Icon(
                                        Icons.local_fire_department,
                                        size: 14,
                                        color: EmergeColors.coral,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${habit.currentStreak}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: EmergeColors.coral,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Completion checkbox
                          _buildCheckbox(neonColor),
                        ],
                      ),
                      // Anchor badge when habit is linked to another
                      if (habit.anchorHabitId != null)
                        Positioned(
                          top: 0,
                          right: 40,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: neonColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.link, size: 14, color: neonColor),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRing(double progress, Color neonColor) {
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glow effect
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: neonColor.withValues(alpha: 0.4),
                  blurRadius: 12,
                  spreadRadius: -2,
                ),
              ],
            ),
          ),
          // Progress ring
          SizedBox(
            width: 44,
            height: 44,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 4,
              backgroundColor: neonColor.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation(neonColor),
            ),
          ),
          // Percentage
          Text(
            '${(progress * 100).toInt()}%',
            style: TextStyle(
              color: neonColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckbox(Color neonColor) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isCompleted ? neonColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isCompleted ? neonColor : neonColor.withValues(alpha: 0.5),
            width: 2,
          ),
          boxShadow: isCompleted
              ? [
                  BoxShadow(
                    color: neonColor.withValues(alpha: 0.5),
                    blurRadius: 8,
                    spreadRadius: -2,
                  ),
                ]
              : null,
        ),
        child: isCompleted
            ? const Icon(Icons.check, color: Colors.white, size: 20)
            : null,
      ),
    );
  }

  Color _getAttributeColor(HabitAttribute attribute) {
    switch (attribute) {
      case HabitAttribute.vitality:
        return const Color(0xFF00E5FF); // Cyan - health/fitness
      case HabitAttribute.intellect:
        return const Color(0xFFE040FB); // Magenta - learning
      case HabitAttribute.creativity:
        return const Color(0xFF76FF03); // Lime green - creative
      case HabitAttribute.focus:
        return const Color(0xFFFFAB00); // Amber - productivity
      case HabitAttribute.strength:
        return const Color(0xFFFF5252); // Red - strength
      case HabitAttribute.spirit:
        return const Color(0xFFFFD700); // Golden - spirit
    }
  }

  IconData _getAttributeIcon(HabitAttribute attribute) {
    switch (attribute) {
      case HabitAttribute.vitality:
        return Icons.favorite;
      case HabitAttribute.intellect:
        return Icons.menu_book;
      case HabitAttribute.creativity:
        return Icons.palette;
      case HabitAttribute.focus:
        return Icons.center_focus_strong;
      case HabitAttribute.strength:
        return Icons.fitness_center;
      case HabitAttribute.spirit:
        return Icons.auto_awesome;
    }
  }

  String _formatTimeOfDay(TimeOfDay? time) {
    if (time == null) return 'Anytime';
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
}

class _ConnectorPainter extends CustomPainter {
  final Color color;

  const _ConnectorPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final path = Path();
    // Start from top center (connecting from parent)
    path.moveTo(size.width / 2, 0);
    // Go down
    path.lineTo(size.width / 2, size.height * 0.5);
    // Curve to right (towards the card)
    path.quadraticBezierTo(
      size.width / 2,
      size.height * 0.8,
      size.width,
      size.height * 0.8,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
