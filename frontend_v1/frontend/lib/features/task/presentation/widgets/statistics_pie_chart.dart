import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/statistics_model.dart';

class StatisticsPieChart extends StatelessWidget {
  final StatisticsModel stats;

  const StatisticsPieChart({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final total = stats.totalTasks == 0 ? 1 : stats.totalTasks;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Biểu đồ hiệu suất',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 240,
              child: PieChart(
                PieChartData(
                  centerSpaceRadius: 54,
                  sectionsSpace: 3,
                  sections: [
                    PieChartSectionData(
                      value: (stats.completedTasks / total) * 100,
                      title: '${stats.completedTasks}',
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                      radius: 58,
                      color: AppColors.success,
                    ),
                    PieChartSectionData(
                      value: (stats.doingTasks / total) * 100,
                      title: '${stats.doingTasks}',
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                      radius: 58,
                      color: AppColors.warning,
                    ),
                    PieChartSectionData(
                      value: (stats.todoTasks / total) * 100,
                      title: '${stats.todoTasks}',
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                      radius: 58,
                      color: AppColors.todo,
                    ),
                    PieChartSectionData(
                      value: (stats.overdueTasks / total) * 100,
                      title: '${stats.overdueTasks}',
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                      radius: 58,
                      color: AppColors.danger,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _LegendItem(label: 'Done', color: AppColors.success),
                _LegendItem(label: 'Doing', color: AppColors.warning),
                _LegendItem(label: 'To-do', color: AppColors.todo),
                _LegendItem(label: 'Overdue', color: AppColors.danger),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendItem({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
