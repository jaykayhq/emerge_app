import 'package:emerge_app/core/theme/emerge_earthy_theme.dart';
import 'package:emerge_app/features/gamification/domain/services/gamification_service.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Modal bottom sheet showing habits completed on a specific day
class DayHabitListSheet extends StatelessWidget {
  final DateTime date;
  final List<Habit> allHabits;

  const DayHabitListSheet({
    super.key,
    required this.date,
    required this.allHabits,
  });

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

  @override
  Widget build(BuildContext context) {
    final completedOnDay = allHabits.where((h) {
      final lastCompleted = h.lastCompletedDate;
      if (lastCompleted == null) return false;
      return lastCompleted.year == date.year &&
             lastCompleted.month == date.month &&
             lastCompleted.day == date.day;
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: EmergeEarthyColors.baseBackground.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: EmergeEarthyColors.terracotta.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            DateFormat('MMM d, yyyy').format(date),
            style: TextStyle(
              color: EmergeEarthyColors.terracotta,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${completedOnDay.length} habit${completedOnDay.length != 1 ? 's' : ''} completed',
            style: TextStyle(
              color: EmergeEarthyColors.cream.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          if (completedOnDay.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'No habits were completed on this day',
                style: TextStyle(
                  color: EmergeEarthyColors.cream.withValues(alpha: 0.5),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: completedOnDay.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final habit = completedOnDay[index];
                  final attrColor = EmergeEarthyColors.attributeColors[habit.attribute] ??
                                  EmergeEarthyColors.terracotta;
                  final gamificationService = GamificationService();
                  final xp = gamificationService.calculateXpGain(habit);

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: attrColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: attrColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getAttributeIcon(habit.attribute),
                          size: 28,
                          color: attrColor,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                habit.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: attrColor.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      habit.attribute.name.toUpperCase(),
                                      style: TextStyle(
                                        color: attrColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (habit.currentStreak > 0) ...[
                                    const SizedBox(width: 8),
                                    Row(
                                      children: [
                                        const Text('🔥', style: TextStyle(fontSize: 12)),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${habit.currentStreak} day streak',
                                          style: TextStyle(
                                            color: EmergeEarthyColors.cream.withValues(alpha: 0.7),
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '+$xp',
                              style: TextStyle(
                                color: attrColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'XP',
                              style: TextStyle(
                                color: attrColor.withValues(alpha: 0.7),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 32),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '✕ CLOSE',
              style: TextStyle(
                color: EmergeEarthyColors.terracotta,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
