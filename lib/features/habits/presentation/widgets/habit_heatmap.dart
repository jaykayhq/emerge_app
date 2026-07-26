import 'package:flutter/material.dart';

/// GitHub-style contribution heatmap. [data] is a list of booleans,
/// index 0 = oldest day and MUST start on a Monday (the provider aligns the
/// window to a week boundary and pads to whole weeks). Renders one column per
/// week, 7 day-rows (row 0 = Monday), exactly [data].length cells.
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

    // Split the flat, Monday-aligned list into week-columns of 7.
    final weeks = <List<int>>[];
    for (int i = 0; i < data.length; i += 7) {
      weeks.add(List<int>.generate(
        (i + 7 <= data.length) ? 7 : data.length - i,
        (d) => i + d,
      ));
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
                      final completed = data[index];
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
