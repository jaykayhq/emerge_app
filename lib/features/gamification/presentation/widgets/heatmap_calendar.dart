import 'package:flutter/material.dart';

class HeatmapCalendar extends StatelessWidget {
  final Map<DateTime, int> datasets; // Date -> Completion Count (or intensity)

  const HeatmapCalendar({super.key, required this.datasets});

  @override
  Widget build(BuildContext context) {
    // Simple 7-day row for MVP, or a grid for month
    // Let's do a simple row of the last 7 days
    final now = DateTime.now();
    final days = List.generate(
      7,
      (index) => now.subtract(Duration(days: 6 - index)),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: days.map((date) {
        final count = datasets[DateUtils.dateOnly(date)] ?? 0;
        final isToday = DateUtils.isSameDay(date, now);

        Color color = Colors.grey[300]!;
        if (count > 0) {
          // Green intensity based on count
          color = Colors.green.withValues(
            alpha: (0.2 + (count * 0.2)).clamp(0.2, 1.0),
          );
        } else if (!isToday && date.isBefore(now)) {
          // Missed day? Check if previous day was also missed for "Never Miss Twice" logic
          // For simplicity here, just grey. Logic for "Red" would need more history.
        }

        return Column(
          children: [
            Text(
              _getDayName(date.weekday),
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: 4),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
                border: isToday
                    ? Border.all(
                        color: Theme.of(context).primaryColor,
                        width: 2,
                      )
                    : null,
              ),
              child: count > 0
                  ? const Icon(Icons.check, size: 20, color: Colors.white)
                  : null,
            ),
          ],
        );
      }).toList(),
    );
  }

  String _getDayName(int weekday) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return days[weekday - 1];
  }
}
