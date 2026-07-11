import 'dart:async';

import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:flutter/material.dart';

import 'habit_progress_math.dart';

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

/// Hierarchical timeline with category headers and indented habits.
class HierarchicalHabitTimeline extends StatelessWidget {
  final Map<String, List<Habit>> groupedHabits;
  final DateTime selectedDate;
  final void Function(Habit habit) onHabitTap;
  final void Function(Habit habit) onHabitToggle;
  final void Function(Habit habit) onTimerTap;
  final void Function(Habit habit) onMenuTap;

  const HierarchicalHabitTimeline({
    super.key,
    required this.groupedHabits,
    required this.selectedDate,
    required this.onHabitTap,
    required this.onHabitToggle,
    required this.onTimerTap,
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    // Order: morning, afternoon, evening, anytime
    final timeSlots = ['morning', 'afternoon', 'evening', 'anytime'];
    final slotsWithHabits = timeSlots
        .where((slot) => (groupedHabits[slot]?.length ?? 0) > 0)
        .toList();

    if (slotsWithHabits.isEmpty) {
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
              onTimerTap: onTimerTap,
              onMenuTap: onMenuTap,
              isLast: slot == slotsWithHabits.last,
            ),
        ],
      ),
    );
  }
}

/// Category section with bullet header and indented habits.
class _HabitCategorySection extends StatelessWidget {
  final String slot;
  final List<Habit> habits;
  final DateTime selectedDate;
  final void Function(Habit) onHabitTap;
  final void Function(Habit) onHabitToggle;
  final void Function(Habit) onTimerTap;
  final void Function(Habit) onMenuTap;
  final bool isLast;

  const _HabitCategorySection({
    required this.slot,
    required this.habits,
    required this.selectedDate,
    required this.onHabitTap,
    required this.onHabitToggle,
    required this.onTimerTap,
    required this.onMenuTap,
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
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _categoryColor,
                boxShadow: [
                  BoxShadow(
                    color: _categoryColor.withValues(alpha: 0.5),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _categoryTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _categoryColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${habits.length}',
                style: TextStyle(
                  color: _categoryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Indented habit items
        ...habits.asMap().entries.map((entry) {
          final index = entry.key;
          final habit = entry.value;
          return IndentedHabitItem(
            habit: habit,
            selectedDate: selectedDate,
            onRowBodyTap: () => onHabitTap(habit),
            onCheckboxTap: () => onHabitToggle(habit),
            onTimerTap: () => onTimerTap(habit),
            onMenuTap: () => onMenuTap(habit),
            showConnector: index < habits.length - 1,
          );
        }),
        if (!isLast) const SizedBox(height: 16),
      ],
    );
  }
}

/// Single habit row — Layout B: [title] [☐] [⏱️] [⋮].
///
/// - Tap body → onRowBodyTap
/// - Tap checkbox → onCheckboxTap (toggle complete)
/// - Tap ⏱️ → onTimerTap (open timer dialog)
/// - Tap ⋮ → onMenuTap (open options sheet)
///
/// Card background fills as timer counts down. At 0, auto-fires onCheckboxTap.
class IndentedHabitItem extends StatefulWidget {
  final Habit habit;
  final DateTime selectedDate;
  final VoidCallback onRowBodyTap;
  final VoidCallback onCheckboxTap;
  final VoidCallback onTimerTap;
  final VoidCallback onMenuTap;
  final bool showConnector;

  const IndentedHabitItem({
    required this.habit,
    required this.selectedDate,
    required this.onRowBodyTap,
    required this.onCheckboxTap,
    required this.onTimerTap,
    required this.onMenuTap,
    this.showConnector = true,
    super.key,
  });

  @override
  State<IndentedHabitItem> createState() => _IndentedHabitItemState();
}

class _IndentedHabitItemState extends State<IndentedHabitItem> {
  int _remainingSeconds = 0;
  int _totalSeconds = 0;
  bool _isTimerRunning = false;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _resetTimerToHabitDuration();
    // Timer does NOT auto-start. It only starts when the user taps the timer
    // dialog's "Start" or "Exit & run in background" button (see startTimerFromDuration).
  }

  void _resetTimerToHabitDuration() {
    _totalSeconds = widget.habit.timerDurationMinutes * 60;
    _remainingSeconds = _totalSeconds;
    _isTimerRunning = false;
  }

  void _tick() {
    if (!mounted || !_isTimerRunning) return;
    if (_remainingSeconds > 0) {
      _countdownTimer = Timer(const Duration(seconds: 1), () {
        if (!mounted || !_isTimerRunning) return;
        setState(() => _remainingSeconds--);
        _tick();
      });
    } else {
      setState(() => _isTimerRunning = false);
      widget.onCheckboxTap();
    }
  }

  void _cancelTimer() {
    _countdownTimer?.cancel();
    setState(() {
      _isTimerRunning = false;
      _remainingSeconds = _totalSeconds;
    });
  }

  /// Called externally when the user starts a timer via the dialog.
  /// Resets and begins the countdown for [minutes] duration.
  void startTimerFromDuration(int minutes) {
    _countdownTimer?.cancel();
    setState(() {
      _totalSeconds = minutes * 60;
      _remainingSeconds = _totalSeconds;
      _isTimerRunning = true;
    });
    _tick();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  bool get _isCompletedToday => widget.habit.isCompletedOn(widget.selectedDate);

  @override
  Widget build(BuildContext context) {
    final completed = _isCompletedToday;
    final color = attributeColor(widget.habit.attribute);
    final progress = habitCardFillFraction(
      remainingSeconds: _remainingSeconds,
      totalSeconds: _totalSeconds,
    );

    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Row(
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
          // Habit item card
          Expanded(
            child: GestureDetector(
              onTap: widget.onRowBodyTap,
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.35),
                      Colors.white.withValues(alpha: 0.06),
                    ],
                    stops: _isTimerRunning || completed
                        ? (completed ? const [1.0, 1.0] : [progress, progress])
                        : const [0.0, 0.0],
                  ),
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
                    : _buildPending(color),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPending(Color color) {
    return Row(
      children: [
        // Title (body tap zone)
        Expanded(
          child: Text(
            widget.habit.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        // Checkbox
        IconButton(
          tooltip: 'Mark complete',
          icon: const Icon(
            Icons.radio_button_unchecked,
            color: Colors.white70,
            size: 22,
          ),
          onPressed: () {
            if (_isTimerRunning) _cancelTimer();
            widget.onCheckboxTap();
          },
        ),
        // Timer icon
        IconButton(
          icon: const Icon(Icons.timer_outlined, color: Colors.white, size: 20),
          onPressed: widget.onTimerTap,
        ),
        // Menu icon
        IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.white, size: 22),
          onPressed: widget.onMenuTap,
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

    return Row(
      children: [
        // Title with strike-through
        Expanded(
          child: Text(
            widget.habit.title,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.lineThrough,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        // Checkbox (tappable — allows undo)
        IconButton(
          tooltip: 'Undo completion',
          icon: Icon(Icons.check_circle, color: color, size: 22),
          onPressed: () {
            if (_isTimerRunning) _cancelTimer();
            widget.onCheckboxTap();
          },
        ),
        // Timer icon (tappable)
        IconButton(
          icon: const Icon(Icons.timer_outlined, color: Colors.white, size: 20),
          onPressed: widget.onTimerTap,
        ),
        // Menu icon (tappable)
        IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.white, size: 22),
          onPressed: widget.onMenuTap,
        ),
        // XP badge
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            '+$xp XP',
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
