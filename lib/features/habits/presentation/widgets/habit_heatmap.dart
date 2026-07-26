import 'package:flutter/material.dart';

/// GitHub-style 90-day contribution heatmap. [data] is a list of booleans,
/// index 0 = oldest day. Renders 13 week-columns x 7 day-rows.
class HabitHeatmap extends StatelessWidget {
  final List<bool> data;
  final ValueChanged<int>? onCellTap;

  const HabitHeatmap({
    super.key,
    required this.data,
    this.onCellTap,
  });

  @override
  Widget build(BuildContext context) {
    final completedCount = data.where((d) => d).length;
    final intensity = data.isEmpty ? 0.0 : (completedCount / data.length).clamp(0.0, 1.0);

    final weeks = <List<int>>[]; // store indices
    for (int w = 0; w < 13; w++) {
      final week = <int>[];
      for (int d = 0; d < 7; d++) {
        week.add(w * 7 + d);
      }
      weeks.add(week);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: ['Mon', '', 'Wed', '', 'Fri', '', 'Sun']
              .map((d) => SizedBox(
                    width: 14,
                    child: Text(
                      d,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 8,
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 4),
        Row(
          children: weeks
              .map((week) => Column(
                    children: week.map((index) {
                      final completed = index < data.length && data[index];
                      return GestureDetector(
                        onTap: onCellTap != null ? () => onCellTap!(index) : null,
                        child: Container(
                          width: 10,
                          height: 10,
                          margin: const EdgeInsets.all(1.5),
                          decoration: BoxDecoration(
                            color: completed
                                ? Color.lerp(
                                    const Color(0xFF2BEE79).withValues(alpha: 0.3),
                                    const Color(0xFF2BEE79),
                                    intensity,
                                  )
                                : const Color(0xFF2A2A3E),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }).toList(),
                  ))
              .toList(),
        ),
      ],
    );
  }
}
