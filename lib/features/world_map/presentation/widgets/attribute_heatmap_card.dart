import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/world_map/domain/models/world_type_config.dart';
import 'package:emerge_app/features/world_map/presentation/providers/attribute_completions_provider.dart';
import 'package:intl/intl.dart';

class AttributeHeatmapCard extends ConsumerWidget {
  final HabitAttribute attribute;

  const AttributeHeatmapCard({super.key, required this.attribute});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completionsAsync = ref.watch(attributeCompletionsProvider(attribute.name));
    final config = WorldTypeConfig.forAttribute(attribute);

    return Card(
      color: Colors.black.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: config.primaryColor, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Last 7 Days XP',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: completionsAsync.when(
                data: (data) {
                  final maxY = (data.reduce((a, b) => a > b ? a : b) + 50).toDouble();
                  return BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxY,
                      barTouchData: BarTouchData(enabled: false),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final now = DateTime.now();
                              final date = now.subtract(Duration(days: 6 - value.toInt()));
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  DateFormat('E').format(date),
                                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(7, (index) {
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: data[index].toDouble(),
                              color: config.primaryColor,
                              width: 16,
                              borderRadius: BorderRadius.circular(4),
                              backDrawRodData: BackgroundBarChartRodData(
                                show: true,
                                toY: maxY,
                                color: Colors.white12,
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.white54, size: 32),
                      SizedBox(height: 8),
                      Text('Failed to load recent activity.', style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
