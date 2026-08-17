import 'dart:async';

import 'package:emerge_app/core/theme/attribute_colors.dart' as canonical;
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:flutter/material.dart';

import 'habit_progress_math.dart';

/// Maps a [HabitAttribute] to its identity color.
/// Delegates to the canonical palette in `core/theme/attribute_colors.dart`.
Color attributeColor(HabitAttribute attribute) =>
    canonical.attributeColor(attribute);

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

/// Returns the 3–4 letter abbreviation for an attribute tag pill.
String attributeAbbrev(HabitAttribute attribute) {
  switch (attribute) {
    case HabitAttribute.strength:
      return 'STR';
    case HabitAttribute.intellect:
      return 'INT';
    case HabitAttribute.vitality:
      return 'VIT';
    case HabitAttribute.creativity:
      return 'CREA';
    case HabitAttribute.focus:
      return 'FOC';
    case HabitAttribute.spirit:
      return 'SPR';
  }
}

/// Hierarchical timeline with category headers and indented habits.
class HierarchicalHabitTimeline extends StatelessWidget {
  final Map<String, List<Habit>> groupedHabits;
  final DateTime selectedDate;
  final void Function(Habit habit) onHabitTap;
  final void Function(Habit habit) onHabitToggle;
  // Returns the chosen timer duration in minutes (null if cancelled).
  // The card uses this to transition into its running-timer state.
  final Future<int?> Function(Habit habit) onTimerTap;
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
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white.withValues(alpha: 0.06),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Center(
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: const Color(0xFF2BEE79).withValues(alpha: 0.18),
                  ),
                  child: const Icon(
                    Icons.self_improvement,
                    color: Color(0xFF2BEE79),
                    size: 26,
                  ),
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
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final slot in slotsWithHabits)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _HabitCategorySection(
                slot: slot,
                habits: groupedHabits[slot]!,
                selectedDate: selectedDate,
                onHabitTap: onHabitTap,
                onHabitToggle: onHabitToggle,
                onTimerTap: onTimerTap,
                onMenuTap: onMenuTap,
              ),
            ),
        ],
      ),
    );
  }
}

/// Glassmorphic section card for a time-of-day group of habits.
class _HabitCategorySection extends StatelessWidget {
  final String slot;
  final List<Habit> habits;
  final DateTime selectedDate;
  final void Function(Habit) onHabitTap;
  final void Function(Habit) onHabitToggle;
  final Future<int?> Function(Habit) onTimerTap;
  final void Function(Habit) onMenuTap;

  const _HabitCategorySection({
    required this.slot,
    required this.habits,
    required this.selectedDate,
    required this.onHabitTap,
    required this.onHabitToggle,
    required this.onTimerTap,
    required this.onMenuTap,
  });

  String get _categoryTitle {
    switch (slot) {
      case 'morning':
        return 'After I Wake Up';
      case 'afternoon':
        return 'During Lunch';
      case 'evening':
        return 'After Work';
      case 'anytime':
        return 'Before Bed';
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
        return const Color(0xFF2BEE79);
    }
  }

  int get _completedCount =>
      habits.where((h) => h.isCompletedOn(selectedDate)).length;

  int get _sectionXp {
    int total = 0;
    for (final h in habits) {
      if (!h.isCompletedOn(selectedDate)) continue;
      final baseXp = switch (h.difficulty) {
        HabitDifficulty.easy => 10,
        HabitDifficulty.medium => 20,
        HabitDifficulty.hard => 30,
      };
      final streakBonus = (h.currentStreak / 7 * 0.10).clamp(0.0, 0.5);
      total += (baseXp * (1 + streakBonus)).round();
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final completed = _completedCount;
    final total = habits.length;
    final fraction = total > 0 ? completed / total : 0.0;
    final xp = _sectionXp;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              // Colored dot with glow
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _categoryColor,
                  boxShadow: [
                    BoxShadow(
                      color: _categoryColor.withValues(alpha: 0.5),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Title + meta
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      _categoryTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      ' · $completed done · $total total',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // XP badge
              if (xp > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2BEE79).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '+$xp XP',
                    style: const TextStyle(
                      color: Color(0xFF2BEE79),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          // Progress bar
          Container(
            height: 6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: Colors.white.withValues(alpha: 0.06),
            ),
            child: FractionallySizedBox(
              widthFactor: fraction,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: const Color(0xFF2BEE79),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Habit rows
          ...habits.map((habit) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: IndentedHabitItem(
                  habit: habit,
                  selectedDate: selectedDate,
                  onRowBodyTap: () => onHabitTap(habit),
                  onCheckboxTap: () => onHabitToggle(habit),
                  onTimerTap: onTimerTap,
                  onMenuTap: () => onMenuTap(habit),
                ),
              )),
        ],
      ),
    );
  }
}

/// Single habit row — [icon box] [name + meta] [attr tag] [check circle].
///
/// - Tap body → onRowBodyTap
/// - Tap checkbox → onCheckboxTap (toggle complete)
/// - Tap ⏱️ → onTimerTap (open timer dialog)
/// - Tap ⋮ → onMenuTap (open options sheet)
class IndentedHabitItem extends StatefulWidget {
  final Habit habit;
  final DateTime selectedDate;
  final VoidCallback onRowBodyTap;
  final VoidCallback onCheckboxTap;
  final Future<int?> Function(Habit) onTimerTap;
  final VoidCallback onMenuTap;

  const IndentedHabitItem({
    required this.habit,
    required this.selectedDate,
    required this.onRowBodyTap,
    required this.onCheckboxTap,
    required this.onTimerTap,
    required this.onMenuTap,
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

    // Timer progress gradient fill
    final gradientColors = completed
        ? <Color>[
            const Color(0xFF1A1A2E).withValues(alpha: 0.85),
            const Color(0xFF1A1A2E).withValues(alpha: 0.75),
          ]
        : <Color>[
            color.withValues(alpha: 0.35),
            Colors.white.withValues(alpha: 0.06),
          ];
    final gradientStops = completed
        ? const [0.0, 1.0]
        : _isTimerRunning
            ? [progress, progress]
            : const [0.0, 0.0];

    return GestureDetector(
      onTap: widget.onRowBodyTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradientColors, stops: gradientStops),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: completed ? _buildCompleted(color) : _buildPending(color),
      ),
    );
  }

  Widget _buildPending(Color color) {
    final hasTimer = widget.habit.timerDurationMinutes > 0;
    final attrColor = attributeColor(widget.habit.attribute);

    return Row(
      children: [
        // Icon box
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: widget.habit.imageUrl != null &&
                    widget.habit.imageUrl!.isNotEmpty
                ? Text(
                    widget.habit.imageUrl!,
                    style: const TextStyle(fontSize: 16),
                  )
                : Icon(
                    Icons.bolt,
                    size: 16,
                    color: attrColor,
                  ),
          ),
        ),
        const SizedBox(width: 10),
        // Name + meta column
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '${attributeLabel(widget.habit.attribute)} · ${widget.habit.timerDurationMinutes} min',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        // Attribute tag pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: attrColor.withValues(alpha: 0.25),
            ),
          ),
          child: Text(
            attributeAbbrev(widget.habit.attribute),
            style: TextStyle(
              color: attrColor,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Check circle / timer controls
        if (_isTimerRunning)
          GestureDetector(
            onTap: _cancelTimer,
            child: SizedBox(
              width: 24,
              height: 24,
              child: Icon(Icons.pause, color: color, size: 20),
            ),
          )
        else
          GestureDetector(
            onTap: () {
              if (_isTimerRunning) _cancelTimer();
              widget.onCheckboxTap();
            },
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.18),
                  width: 2,
                ),
              ),
              child: const Center(
                child: Text(
                  '·',
                  style: TextStyle(color: Colors.white54, fontSize: 16),
                ),
              ),
            ),
          ),
        const SizedBox(width: 4),
        // Timer icon
        if (hasTimer && !_isTimerRunning)
          GestureDetector(
            onTap: () async {
              final minutes = await widget.onTimerTap(widget.habit);
              if (minutes != null && minutes > 0 && mounted && !_isTimerRunning) {
                startTimerFromDuration(minutes);
              }
            },
            child: SizedBox(
              width: 28,
              height: 28,
              child: Icon(
                Icons.timer_outlined,
                color: Colors.white.withValues(alpha: 0.7),
                size: 18,
              ),
            ),
          ),
        // Menu icon
        GestureDetector(
          onTap: widget.onMenuTap,
          child: SizedBox(
            width: 28,
            height: 28,
            child: Icon(
              Icons.more_vert,
              color: Colors.white.withValues(alpha: 0.7),
              size: 18,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompleted(Color color) {
    final attrColor = attributeColor(widget.habit.attribute);

    return Row(
      children: [
        // Icon box (dimmed)
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: widget.habit.imageUrl != null &&
                    widget.habit.imageUrl!.isNotEmpty
                ? Text(
                    widget.habit.imageUrl!,
                    style: const TextStyle(fontSize: 16),
                  )
                : Icon(
                    Icons.bolt,
                    size: 16,
                    color: attrColor.withValues(alpha: 0.5),
                  ),
          ),
        ),
        const SizedBox(width: 10),
        // Name with strike-through
        Expanded(
          child: Text(
            widget.habit.title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.lineThrough,
              decorationColor: Colors.white.withValues(alpha: 0.4),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // Attribute tag (dimmed)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: attrColor.withValues(alpha: 0.15),
            ),
          ),
          child: Text(
            attributeAbbrev(widget.habit.attribute),
            style: TextStyle(
              color: attrColor.withValues(alpha: 0.5),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Check circle (filled green)
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF2BCE6B),
            border: Border.all(
              color: const Color(0xFF2BCE6B),
              width: 2,
            ),
          ),
          child: const Icon(
            Icons.check,
            color: Color(0xFF0B0F17),
            size: 16,
          ),
        ),
        const SizedBox(width: 4),
        // Undo button
        GestureDetector(
          onTap: widget.onCheckboxTap,
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: 28,
            height: 28,
            child: Icon(
              Icons.undo,
              size: 18,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ),
      ],
    );
  }
}
