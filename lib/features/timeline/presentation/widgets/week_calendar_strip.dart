import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_semantics.dart';
import 'package:emerge_app/core/theme/emerge_dimensions.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Horizontal scrollable calendar strip showing the current week
/// Highlights today and allows selecting a day to view its habits/progress
class WeekCalendarStrip extends StatefulWidget {
  final DateTime? selectedDate;
  final ValueChanged<DateTime>? onDateSelected;

  const WeekCalendarStrip({super.key, this.selectedDate, this.onDateSelected});

  @override
  State<WeekCalendarStrip> createState() => _WeekCalendarStripState();
}

class _WeekCalendarStripState extends State<WeekCalendarStrip> {
  late DateTime _selectedDate;
  late List<DateTime> _weekDays;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate ?? DateTime.now();
    _generateWeekDays();
  }

  void _generateWeekDays() {
    final now = DateTime.now();
    // Start from 6 days ago to today (showing past week + today)
    _weekDays = List.generate(7, (index) {
      return now.subtract(Duration(days: 6 - index));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        border: Border(
          bottom: BorderSide(color: EmergeColors.hexLine, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _weekDays.map((date) => _buildDayItem(date)).toList(),
      ),
    );
  }

  Widget _buildDayItem(DateTime date) {
    final isToday = _isToday(date);
    final isSelected = _isSameDay(date, _selectedDate);
    final dayName = DateFormat('E').format(date).substring(0, 3);
    final dayNumber = date.day.toString();
    final monthName = DateFormat('MMM').format(date);
    final fullDateLabel = '$dayName, $monthName $dayNumber${isToday ? ' (Today)' : ''}';

    return EmergeTappable(
      label: fullDateLabel,
      hint: isSelected ? 'Currently selected' : 'Tap to view this day',
      onTap: () {
        setState(() => _selectedDate = date);
        widget.onDateSelected?.call(date);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 48, // Increased from 44 for better tap target
        height: EmergeDimensions.minTapTarget, // Ensure 44px height
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? EmergeColors.teal
              : isToday
              ? EmergeColors.teal.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isToday && !isSelected
              ? Border.all(color: EmergeColors.teal.withValues(alpha: 0.5))
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              dayName,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textSecondaryDark,
                fontSize: EmergeDimensions.minFontSize, // 12px minimum
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              dayNumber,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : isToday
                    ? EmergeColors.teal
                    : AppTheme.textMainDark,
                fontSize: 16,
                fontWeight: isToday || isSelected
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
