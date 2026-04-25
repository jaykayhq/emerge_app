import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/core/theme/emerge_earthy_theme.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_semantics.dart';
import 'package:emerge_app/core/theme/emerge_dimensions.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Completion status for a day
enum DayCompletionStatus { none, partial, complete }

/// Horizontal scrollable calendar strip showing the current month
/// Highlights today and allows selecting a day to view its habits/progress
/// Now includes completion dots below each day per Stitch design
class MonthCalendarStrip extends StatefulWidget {
  final DateTime? selectedDate;
  final ValueChanged<DateTime>? onDateSelected;

  /// Map of date (year-month-day string) to completion status
  final Map<String, DayCompletionStatus>? completionStatus;

  const MonthCalendarStrip({
    super.key,
    this.selectedDate,
    this.onDateSelected,
    this.completionStatus,
  });

  @override
  State<MonthCalendarStrip> createState() => _MonthCalendarStripState();
}

class _MonthCalendarStripState extends State<MonthCalendarStrip> {
  late DateTime _selectedDate;
  late List<DateTime> _monthDays;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate ?? DateTime.now();
    _generateMonthDays();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelectedDate());
  }

  void _generateMonthDays() {
    final now = DateTime.now();
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    _monthDays = List.generate(lastDayOfMonth.day, (index) {
      return DateTime(now.year, now.month, index + 1);
    });
  }

  void _scrollToSelectedDate() {
    if (!_scrollController.hasClients) return;
    
    final index = _monthDays.indexWhere((d) => _isSameDay(d, _selectedDate));
    if (index == -1) return;

    const itemWidth = 64.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final scrollOffset = (index * itemWidth) - (screenWidth / 2) + (itemWidth / 2);
    
    _scrollController.animateTo(
      scrollOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: EmergeColors.hexLine.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: _monthDays.length,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemBuilder: (context, index) {
          return SizedBox(
            width: 64,
            child: _buildDayItem(_monthDays[index]),
          );
        },
      ),
    );
  }

  Widget _buildDayItem(DateTime date) {
    final isToday = _isToday(date);
    final isSelected = _isSameDay(date, _selectedDate);
    // Get full day name and create short version (first 3 chars)
    final fullDayName = DateFormat('EEEE').format(date);
    final dayName = fullDayName.substring(0, 3);
    final dayNumber = date.day.toString();
    final monthName = DateFormat('MMM').format(date);
    final fullDateLabel =
        '$fullDayName, $monthName $dayNumber${isToday ? ' (Today)' : ''}';

    return EmergeTappable(
      label: fullDateLabel,
      hint: isSelected ? 'Currently selected' : 'Tap to view this day',
      onTap: () {
        setState(() => _selectedDate = date);
        widget.onDateSelected?.call(date);
        _scrollToSelectedDate();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 80,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? EmergeEarthyColors.terracotta
              : isToday
              ? EmergeEarthyColors.terracotta.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isToday && !isSelected
              ? Border.all(
                  color: EmergeEarthyColors.terracotta.withValues(alpha: 0.5),
                )
              : null,
          // Glow effect for today
          boxShadow: isToday
              ? [
                  BoxShadow(
                    color: EmergeEarthyColors.terracotta.withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: -2,
                  ),
                ]
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
                fontSize: EmergeDimensions.minFontSize,
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
                    ? EmergeEarthyColors.terracotta
                    : AppTheme.textMainDark,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            // Completion indicator dot
            _buildCompletionDot(date, isSelected),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionDot(DateTime date, bool isSelected) {
    final dateKey =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final status =
        widget.completionStatus?[dateKey] ?? DayCompletionStatus.none;

    if (status == DayCompletionStatus.none) {
      return const SizedBox(height: 8);
    }

    final color = status == DayCompletionStatus.complete
        ? (isSelected ? Colors.white : EmergeEarthyColors.terracotta)
        : (isSelected ? Colors.white70 : EmergeEarthyColors.sienna);

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.5),
            blurRadius: 4,
            spreadRadius: 0,
          ),
        ],
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
