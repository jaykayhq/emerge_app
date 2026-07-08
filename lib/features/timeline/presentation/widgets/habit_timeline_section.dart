import 'dart:async';

import 'package:emerge_app/core/presentation/widgets/one_tap_completion_zone.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:flutter/material.dart';
import 'package:emerge_app/features/timeline/presentation/widgets/habit_rune_indicator.dart';

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
  final DateTime selectedDate;
  final void Function(Habit habit) onHabitTap;
  final void Function(Habit habit) onHabitToggle;
  final void Function(Habit habit) onHabitDelete;

  const HierarchicalHabitTimeline({
    super.key,
    required this.groupedHabits,
    required this.selectedDate,
    required this.onHabitTap,
    required this.onHabitToggle,
    required this.onHabitDelete,
  });

  @override
  Widget build(BuildContext context) {
    // Order: morning, afternoon, evening, anytime
    final timeSlots = ['morning', 'afternoon', 'evening', 'anytime'];
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
              selectedDate: selectedDate,
              onHabitTap: onHabitTap,
              onHabitToggle: onHabitToggle,
              onHabitDelete: onHabitDelete,
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
  final DateTime selectedDate;
  final void Function(Habit) onHabitTap;
  final void Function(Habit) onHabitToggle;
  final void Function(Habit) onHabitDelete;
  final bool isLast;

  const _HabitCategorySection({
    required this.slot,
    required this.habits,
    required this.selectedDate,
    required this.onHabitTap,
    required this.onHabitToggle,
    required this.onHabitDelete,
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
      case 'anytime':
        return 'Scheduled for Anytime';
      default:
        return slot;
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
      case 'anytime':
        return const Color(0xFF2BEE79); // Emerge green
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
            selectedDate: selectedDate,
            onTap: () => onHabitTap(habit),
            onToggle: () => onHabitToggle(habit),
            onDelete: () => onHabitDelete(habit),
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
  final Color color;
  final int habitCount;

  const _CategoryHeader({
    required this.title,
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

class _IndentedHabitItem extends StatefulWidget {
  final Habit habit;
  final DateTime selectedDate;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback? onDelete;
  final bool showConnector;

  const _IndentedHabitItem({
    required this.habit,
    required this.selectedDate,
    required this.onTap,
    required this.onToggle,
    this.onDelete,
    required this.showConnector,
  });

  @override
  State<_IndentedHabitItem> createState() => _IndentedHabitItemState();
}

class _IndentedHabitItemState extends State<_IndentedHabitItem> {
  bool _isExpanded = false;
  int _remainingSeconds = 0;
  bool _isTimerRunning = false;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.habit.timerDurationMinutes * 60;
  }

  void _startTimer() {
    if (_isTimerRunning) return;
    setState(() => _isTimerRunning = true);
    _tickTimer();
  }

  void _tickTimer() {
    if (!mounted || !_isTimerRunning) return;

    if (_remainingSeconds > 0) {
      _countdownTimer = Timer(const Duration(seconds: 1), () {
        if (!mounted || !_isTimerRunning) return;
        setState(() => _remainingSeconds--);
        _tickTimer();
      });
    } else {
      setState(() => _isTimerRunning = false);
      // Auto-complete the habit
      if (!_isCompletedToday) {
        widget.onToggle();
      }
    }
  }

  void _pauseTimer() {
    _countdownTimer?.cancel();
    setState(() => _isTimerRunning = false);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _isTimerRunning = false;
    super.dispose();
  }

  bool get _isCompletedToday {
    return widget.habit.isCompletedOn(widget.selectedDate);
  }

  String get _timerString {
    final m = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final completed = _isCompletedToday;
    final color = attributeColor(widget.habit.attribute);
    final label = attributeLabel(widget.habit.attribute);

    return Dismissible(
      key: Key('habit_dismiss_${widget.habit.id}'),
      direction: DismissDirection.horizontal,
      background: _buildDeleteBackground(),
      secondaryBackground: _buildCompleteBackground(color),
      confirmDismiss: _confirmDismiss,
      dismissThresholds: const {
        DismissDirection.startToEnd: 0.4,
        DismissDirection.endToStart: 0.4,
      },
      child: Padding(
        padding: const EdgeInsets.only(left: 16, bottom: 8),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Vertical connector line
                if (widget.showConnector)
                  Padding(
                    padding: const EdgeInsets.only(left: 5, top: 0),
                    child: Container(
                      width: 2,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.2),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.1),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 12),
                // Habit item container
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: widget.onTap,
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

                      // Expanding details drawer
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        alignment: Alignment.topCenter,
                        child: (_isExpanded && !completed)
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),
                                  // 2-Minute Version
                                  if (widget.habit.twoMinuteVersion != null &&
                                      widget.habit.twoMinuteVersion!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        left: 16.0,
                                        bottom: 8.0,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.05),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: color.withValues(alpha: 0.2),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '2-MINUTE VERSION',
                                              style: TextStyle(
                                                color: color,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              widget.habit.twoMinuteVersion!,
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                  // Environmental Priming nodes
                                  if (widget
                                      .habit
                                      .environmentPriming
                                      .isNotEmpty) ...[
                                    for (final priming
                                        in widget.habit.environmentPriming)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8.0,
                                          left: 16.0,
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.check_box_outline_blank,
                                              size: 16,
                                              color: color.withValues(
                                                alpha: 0.5,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                priming,
                                                style: TextStyle(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.7),
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ],
                              )
                            : const SizedBox.shrink(),
                      ),

                      // Temptation Bundling (Reward) node
                      if (widget.habit.reward.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.only(left: 16.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: completed
                                  ? color.withValues(alpha: 0.2)
                                  : Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: completed
                                    ? color.withValues(alpha: 0.5)
                                    : Colors.white.withValues(alpha: 0.1),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  completed
                                      ? Icons.card_giftcard
                                      : Icons.lock_outline,
                                  size: 14,
                                  color: completed
                                      ? color
                                      : Colors.white.withValues(alpha: 0.5),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  widget.habit.reward,
                                  style: TextStyle(
                                    color: completed
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: 0.5),
                                    fontSize: 12,
                                    fontWeight: completed
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeleteBackground() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(left: 16),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.delete_outline, color: Colors.white, size: 24),
          SizedBox(width: 8),
          Text(
            'Delete',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompleteBackground(Color color) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2BEE79).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 16),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Complete',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          SizedBox(width: 8),
          Icon(Icons.check_circle_outline, color: Colors.white, size: 24),
        ],
      ),
    );
  }

  Future<bool> _confirmDismiss(DismissDirection direction) async {
    if (direction == DismissDirection.endToStart) {
      widget.onToggle();
      return false;
    } else {
      final confirmed = await _showDeleteConfirmation();
      if (confirmed) {
        widget.onDelete?.call();
        return true;
      }
      return false;
    }
  }

  Future<bool> _showDeleteConfirmation() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'Delete Habit',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to permanently delete this habit and all its history?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Widget _buildPending(Color color, String label) {
    return Row(
      children: [
        // One-tap completion zone
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: OneTapCompletionZone(
            color: color,
            onComplete: widget.onToggle,
          ),
        ),
        // Habit info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.habit.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // Expand details button
        if (widget.habit.environmentPriming.isNotEmpty ||
            (widget.habit.twoMinuteVersion != null &&
                widget.habit.twoMinuteVersion!.isNotEmpty))
          IconButton(
            icon: Icon(
              _isExpanded ? Icons.expand_less : Icons.expand_more,
              color: color.withValues(alpha: 0.7),
              size: 20,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
          ),

        const SizedBox(width: 8),

        // Timer Button
        if (widget.habit.timerDurationMinutes > 0 && _remainingSeconds > 0)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _isTimerRunning ? _pauseTimer : _startTimer,
            child: Container(
              constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: _isTimerRunning
                    ? color.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _isTimerRunning ? color : Colors.transparent,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isTimerRunning ? Icons.pause : Icons.play_arrow,
                    color: _isTimerRunning ? color : Colors.white,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _timerString,
                    style: TextStyle(
                      color: _isTimerRunning ? color : Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ),
        // Attribute indicator & Rune
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            HabitRuneIndicator(habit: widget.habit),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: color.withValues(alpha: 0.5)),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompleted(Color color) {
    // Calculate XP
    final baseXp = switch (widget.habit.difficulty) {
      HabitDifficulty.easy => 10,
      HabitDifficulty.medium => 20,
      HabitDifficulty.hard => 30,
    };
    final xp =
        (baseXp * (1 + (widget.habit.currentStreak * 0.1).clamp(0.0, 0.5)))
            .toInt();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.habit.title,
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

