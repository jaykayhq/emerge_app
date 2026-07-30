import 'package:emerge_app/core/presentation/widgets/emerge_semantics.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Completion status for a day
enum DayCompletionStatus { none, partial, complete }

/// Horizontal scrollable calendar strip showing the current month.
/// Each day is an individual glassmorphic card with teal accent colors.
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
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scrollToSelectedDate(),
    );
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

    const itemWidth = 56.0; // card width + gap
    final screenWidth = MediaQuery.of(context).size.width;
    final scrollOffset =
        (index * itemWidth) - (screenWidth / 2) + (itemWidth / 2);

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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: _monthDays.length,
        itemExtent: 56,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: SizedBox(
              width: 48,
              child: _buildDayItem(_monthDays[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDayItem(DateTime date) {
    final isToday = _isToday(date);
    final isSelected = _isSameDay(date, _selectedDate);
    final fullDayName = DateFormat('EEEE').format(date);
    final dayName = fullDayName.substring(0, 3);
    final dayNumber = date.day.toString();
    final monthName = DateFormat('MMM').format(date);
    final fullDateLabel =
        '$fullDayName, $monthName $dayNumber${isToday ? ' (Today)' : ''}';

    // Teal accent color matching the HTML template
    const teal = Color(0xFF34D4B8);

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
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? teal.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? teal.withValues(alpha: 0.35)
                : isToday
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.08),
          ),
          boxShadow: isToday && !isSelected
              ? [
                  BoxShadow(
                    color: teal.withValues(alpha: 0.15),
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
            // Day label
            Text(
              dayName,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            // Day number
            Text(
              dayNumber,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : isToday
                        ? teal
                        : Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // Completion dot
            _buildCompletionDot(date, isSelected, teal),
            const SizedBox(height: 6),
            // Percentage text
            _buildPercentageText(date, isSelected, teal),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionDot(
      DateTime date, bool isSelected, Color teal) {
    final dateKey =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final status =
        widget.completionStatus?[dateKey] ?? DayCompletionStatus.none;

    if (status == DayCompletionStatus.none) {
      return Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.18),
        ),
      );
    }

    final dotColor = status == DayCompletionStatus.complete
        ? (isSelected ? Colors.white : teal)
        : teal.withValues(alpha: 0.6);

    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: dotColor,
        boxShadow: [
          BoxShadow(
            color: dotColor.withValues(alpha: 0.5),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
    );
  }

  Widget _buildPercentageText(
      DateTime date, bool isSelected, Color teal) {
    final dateKey =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final status =
        widget.completionStatus?[dateKey] ?? DayCompletionStatus.none;

    String text;
    switch (status) {
      case DayCompletionStatus.none:
        text = '--';
      case DayCompletionStatus.partial:
        text = '~50%';
      case DayCompletionStatus.complete:
        text = '100%';
    }

    return Text(
      text,
      style: TextStyle(
        color: isSelected
            ? teal.withValues(alpha: 0.85)
            : Colors.white.withValues(alpha: 0.6),
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
