import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:flutter/material.dart';

class AttributeProgressBar extends StatelessWidget {
  final HabitAttribute attribute;
  final double progress;
  final int currentXp;
  final int maxXp;
  final bool showLabel;
  final double height;

  const AttributeProgressBar({
    super.key,
    required this.attribute,
    required this.progress,
    required this.currentXp,
    required this.maxXp,
    this.showLabel = true,
    this.height = 8,
  });

  Color get _attributeColor {
    switch (attribute) {
      case HabitAttribute.vitality:
        return const Color(0xFF00E5FF);
      case HabitAttribute.intellect:
        return const Color(0xFFE040FB);
      case HabitAttribute.creativity:
        return const Color(0xFF76FF03);
      case HabitAttribute.focus:
        return const Color(0xFFFFAB00);
      case HabitAttribute.strength:
        return const Color(0xFFFF5252);
      case HabitAttribute.spirit:
        return const Color(0xFFFFD700);
    }
  }

  IconData get _attributeIcon {
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

  String get _attributeName {
    return attribute.name[0].toUpperCase() + attribute.name.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final clampedProgress = progress.clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLabel)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Icon(
                  _attributeIcon,
                  color: _attributeColor,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  _attributeName,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  '$currentXp / $maxXp XP',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        Container(
          height: height,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(height / 2),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    width: constraints.maxWidth * clampedProgress,
                    height: height,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _attributeColor.withValues(alpha: 0.8),
                          _attributeColor,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(height / 2),
                      boxShadow: clampedProgress > 0
                          ? [
                              BoxShadow(
                                color: _attributeColor.withValues(alpha: 0.4),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                  ),
                  if (clampedProgress >= 1.0)
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: height - 2,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class AttributeProgressGrid extends StatelessWidget {
  final Map<HabitAttribute, double> attributeProgress;
  final Map<HabitAttribute, int> attributeXp;
  final int maxXpPerAttribute;

  const AttributeProgressGrid({
    super.key,
    required this.attributeProgress,
    required this.attributeXp,
    required this.maxXpPerAttribute,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EmergeColors.glassWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EmergeColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.insights,
                color: EmergeColors.teal,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Attribute Progress',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...HabitAttribute.values.map((attr) {
            final progress = attributeProgress[attr] ?? 0.0;
            final xp = attributeXp[attr] ?? 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AttributeProgressBar(
                attribute: attr,
                progress: progress,
                currentXp: xp,
                maxXp: maxXpPerAttribute,
              ),
            );
          }),
        ],
      ),
    );
  }
}