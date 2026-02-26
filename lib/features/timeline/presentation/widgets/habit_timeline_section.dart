import 'dart:ui';

import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:flutter/material.dart';

/// Maps a [HabitAttribute] to its identity color.
/// Each attribute gets a distinct, vibrant accent color for visual identity.
Color attributeColor(HabitAttribute attribute) {
  switch (attribute) {
    case HabitAttribute.strength:
      return const Color(0xFFFF6B6B); // Coral red
    case HabitAttribute.intellect:
      return const Color(0xFF6C63FF); // Indigo purple
    case HabitAttribute.vitality:
      return const Color(0xFF2BEE79); // Emerge green
    case HabitAttribute.creativity:
      return const Color(0xFFE040FB); // Magenta pink
    case HabitAttribute.focus:
      return const Color(0xFFFFB74D); // Amber gold
    case HabitAttribute.spirit:
      return const Color(0xFF4DD0E1); // Cyan teal
  }
}

/// Gets the display label for a [HabitAttribute], matching the Stitch design.
String attributeLabel(HabitAttribute attribute) {
  switch (attribute) {
    case HabitAttribute.strength:
      return 'STRENGTH';
    case HabitAttribute.intellect:
      return 'INTELLECT';
    case HabitAttribute.vitality:
      return 'VITALITY';
    case HabitAttribute.creativity:
      return 'CREATIVITY';
    case HabitAttribute.focus:
      return 'FOCUS';
    case HabitAttribute.spirit:
      return 'SPIRIT';
  }
}

/// Hierarchical timeline with category headers and indented habits
///
/// Uses bullet/circle anchors for time-of-day categories with habits
/// indented underneath. Shows completion count per category and attributes.
class HierarchicalHabitTimeline extends StatelessWidget {
  final Map<String, List<Habit>> groupedHabits;
  final void Function(Habit habit) onHabitTap;
  final void Function(Habit habit) onHabitToggle;

  const HierarchicalHabitTimeline({
    super.key,
    required this.groupedHabits,
    required this.onHabitTap,
    required this.onHabitToggle,
  });

  @override
  Widget build(BuildContext context) {
    // Order: morning, afternoon, evening (no 'anytime' category)
    final timeSlots = ['morning', 'afternoon', 'evening'];
    final slotsWithHabits = timeSlots
        .where((slot) => (groupedHabits[slot]?.length ?? 0) > 0)
        .toList();

    if (slotsWithHabits.isEmpty) {
      return _buildEmptyState();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final slot in slotsWithHabits)
            _HabitCategorySection(
              slot: slot,
              habits: groupedHabits[slot]!,
              onHabitTap: onHabitTap,
              onHabitToggle: onHabitToggle,
              isLast: slot == slotsWithHabits.last,
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.self_improvement,
              color: Colors.white.withValues(alpha: 0.3),
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'No habits scheduled today',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Category section with bullet header and indented habits
class _HabitCategorySection extends StatelessWidget {
  final String slot;
  final List<Habit> habits;
  final void Function(Habit) onHabitTap;
  final void Function(Habit) onHabitToggle;
  final bool isLast;

  const _HabitCategorySection({
    required this.slot,
    required this.habits,
    required this.onHabitTap,
    required this.onHabitToggle,
    required this.isLast,
  });

  String get _categoryTitle {
    switch (slot) {
      case 'morning':
        return 'After You Wake Up';
      case 'afternoon':
        return 'During Lunch';
      case 'evening':
        return 'Before Bed';
      default:
        return slot;
    }
  }

  IconData get _categoryIcon {
    switch (slot) {
      case 'morning':
        return Icons.wb_sunny;
      case 'afternoon':
        return Icons.wb_cloudy;
      case 'evening':
        return Icons.bedtime;
      default:
        return Icons.access_time;
    }
  }

  Color get _categoryColor {
    switch (slot) {
      case 'morning':
        return const Color(0xFFFFB74D); // Warm morning orange
      case 'afternoon':
        return const Color(0xFF64B5F6); // Day blue
      case 'evening':
        return const Color(0xFF7E57C2); // Evening purple
      default:
        return const Color(0xFF2BEE79); // Emerge green
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category header with bullet
        _CategoryHeader(
          title: _categoryTitle,
          icon: _categoryIcon,
          color: _categoryColor,
          habitCount: habits.length,
        ),
        const SizedBox(height: 8),
        // Indented habit items
        ...habits.asMap().entries.map((entry) {
          final index = entry.key;
          final habit = entry.value;
          return _IndentedHabitItem(
            habit: habit,
            onTap: () => onHabitTap(habit),
            onToggle: () => onHabitToggle(habit),
            showConnector: index < habits.length - 1,
          );
        }),
        if (!isLast) const SizedBox(height: 16),
      ],
    );
  }
}

/// Category header with bullet/circle icon
class _CategoryHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final int habitCount;

  const _CategoryHeader({
    required this.title,
    required this.icon,
    required this.color,
    required this.habitCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Bullet/circle
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Category title
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        // Habit count badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$habitCount',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

/// Indented habit item with connector line
class _IndentedHabitItem extends StatelessWidget {
  final Habit habit;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final bool showConnector;

  const _IndentedHabitItem({
    required this.habit,
    required this.onTap,
    required this.onToggle,
    required this.showConnector,
  });

  bool get _isCompletedToday {
    final last = habit.lastCompletedDate;
    if (last == null) return false;
    final now = DateTime.now();
    return last.year == now.year &&
        last.month == now.month &&
        last.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final completed = _isCompletedToday;
    final color = attributeColor(habit.attribute);
    final label = attributeLabel(habit.attribute);

    return Padding(
      padding: const EdgeInsets.only(left: 24, bottom: 8),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Vertical connector line
              if (showConnector)
                Padding(
                  padding: const EdgeInsets.only(left: 5, top: 0),
                  child: Container(
                    width: 2,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          color.withValues(alpha: 0.3),
                          color.withValues(alpha: 0.1),
                        ],
                      ),
                    ),
                  ),
                )
              else
                const SizedBox(width: 12),
              // Habit item
              Expanded(
                child: GestureDetector(
                  onTap: onTap,
                  onLongPress: !completed ? onToggle : null,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: completed
                          ? Colors.white.withValues(alpha: 0.04)
                          : Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: completed
                            ? color.withValues(alpha: 0.3)
                            : Colors.white.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    child: completed
                        ? _buildCompleted(color)
                        : _buildPending(color, label),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPending(Color color, String label) {
    return Row(
      children: [
        // Checkbox
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Icon(
            Icons.radio_button_unchecked,
            color: color.withValues(alpha: 0.5),
            size: 20,
          ),
        ),
        // Habit info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                habit.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (habit.cue.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  habit.cue,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
        // Attribute indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompleted(Color color) {
    // Calculate XP
    int baseXp = 10;
    if (habit.difficulty.toString().contains('medium')) baseXp = 20;
    if (habit.difficulty.toString().contains('hard')) baseXp = 30;
    final xp = (baseXp * (1 + (habit.currentStreak * 0.1).clamp(0.0, 0.5)))
        .toInt();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              habit.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.lineThrough,
              ),
            ),
          ),
          Text(
            '+$xp XP',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// A vertical timeline section showing habits grouped by time-of-day.
///
/// Matches the Stitch design: left column with icon node + vertical connector,
/// right column with section title, completion count, and habit list.
/// Each habit item is colored by its attribute for visual identity.
class HabitTimelineSection extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final List<Habit> habits;
  final Color accentColor;
  final void Function(Habit habit) onHabitTap;
  final void Function(Habit habit) onHabitToggle;
  final bool isLast;

  const HabitTimelineSection({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.habits,
    required this.accentColor,
    required this.onHabitTap,
    required this.onHabitToggle,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final completedCount = habits.where((h) {
      final last = h.lastCompletedDate;
      if (last == null) return false;
      final now = DateTime.now();
      return last.year == now.year &&
          last.month == now.month &&
          last.day == now.day;
    }).length;

    final allDone = completedCount == habits.length && habits.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left column: icon node + vertical line
            SizedBox(
              width: 40,
              child: Column(
                children: [
                  // Icon node
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: allDone
                          ? accentColor.withValues(alpha: 0.2)
                          : const Color(0xFF193324),
                      border: allDone
                          ? null
                          : Border.all(
                              color: const Color(0xFF326747),
                              width: 2,
                            ),
                    ),
                    child: Icon(
                      icon,
                      size: 18,
                      color: allDone ? accentColor : Colors.white70,
                    ),
                  ),
                  // Vertical connector line (grows to fill remaining height)
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: const Color(0xFF326747),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Right column: content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section title
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Completion count
                    Text(
                      habits.isEmpty
                          ? 'No habits scheduled'
                          : allDone
                          ? 'Completed $completedCount/$completedCount ✓'
                          : '$completedCount/${habits.length} remaining',
                      style: TextStyle(
                        color: EmergeColors.tealMuted,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Habit items — each colored by attribute
                    ...habits.map(
                      (habit) => _HabitTimelineItem(
                        habit: habit,
                        onTap: () => onHabitTap(habit),
                        onToggle: () => onHabitToggle(habit),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual habit item in the vertical timeline.
/// Colored by its [HabitAttribute] — shows attribute label, check state,
/// and XP badge. Glassmorphism card style matching the Stitch design.
class _HabitTimelineItem extends StatelessWidget {
  final Habit habit;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  const _HabitTimelineItem({
    required this.habit,
    required this.onTap,
    required this.onToggle,
  });

  bool get _isCompletedToday {
    final last = habit.lastCompletedDate;
    if (last == null) return false;
    final now = DateTime.now();
    return last.year == now.year &&
        last.month == now.month &&
        last.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final completed = _isCompletedToday;
    final hasAnchor =
        habit.anchorHabitId != null && habit.anchorHabitId!.isNotEmpty;
    final color = attributeColor(habit.attribute);
    final label = attributeLabel(habit.attribute);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            decoration: BoxDecoration(
              color: completed
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: completed
                    ? color.withValues(alpha: 0.15)
                    : color.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: InkWell(
              onTap: onTap,
              onLongPress: !completed ? onToggle : null,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: completed
                    ? _buildCompletedState(context, color)
                    : Opacity(
                        opacity: 1.0,
                        child: Row(
                          children: [
                            // Checkbox — colored by attribute (non-clickable)
                            Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: Icon(
                                Icons.radio_button_unchecked,
                                color: color.withValues(alpha: 0.5),
                                size: 24,
                              ),
                            ),
                            // Habit info: attribute label + title + anchor
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Attribute label (matches Stitch "STOIC", "SCHOLAR" etc.)
                                  Row(
                                    children: [
                                      Text(
                                        label,
                                        style: TextStyle(
                                          color: color,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                      if (habit.timerDurationMinutes > 0) ...[
                                        Text(
                                          '  •  ${habit.timerDurationMinutes}M',
                                          style: TextStyle(
                                            color: color.withValues(alpha: 0.6),
                                            fontSize: 9,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  // Habit title
                                  Text(
                                    habit.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  // Anchor indicator
                                  if (hasAnchor)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.link,
                                            size: 12,
                                            color: color.withValues(alpha: 0.7),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Anchored habit',
                                            style: TextStyle(
                                              color: color.withValues(
                                                alpha: 0.7,
                                              ),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: Colors.white30,
                              size: 20,
                            ),
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

  Widget _buildCompletedState(BuildContext context, Color color) {
    int baseXp = 10;
    if (habit.difficulty.toString().contains('medium')) baseXp = 20;
    if (habit.difficulty.toString().contains('hard')) baseXp = 30;
    final xp = (baseXp * (1 + (habit.currentStreak * 0.1).clamp(0.0, 0.5)))
        .toInt();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: EmergeColors.teal,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Completed! +$xp XP',
            style: TextStyle(
              color: EmergeColors.background,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          TextButton.icon(
            onPressed: onToggle,
            icon: Icon(Icons.undo, size: 16, color: EmergeColors.background),
            label: Text(
              'Undo',
              style: TextStyle(
                color: EmergeColors.background,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}
