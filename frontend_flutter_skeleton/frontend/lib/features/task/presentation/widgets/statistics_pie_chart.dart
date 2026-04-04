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
          children: [
            SizedBox(
              height: 220,
              child: PieChart(
                PieChartData(
                  centerSpaceRadius: 48,
                  sectionsSpace: 2,
                  sections: [
                    PieChartSectionData(
                      value: (stats.completedTasks / total) * 100,
                      title: '${stats.completedTasks}',
                      radius: 54,
                      color: AppColors.success,
                    ),
                    PieChartSectionData(
                      value: (stats.doingTasks / total) * 100,
                      title: '${stats.doingTasks}',
                      radius: 54,
                      color: AppColors.warning,
                    ),
                    PieChartSectionData(
                      value: (stats.todoTasks / total) * 100,
                      title: '${stats.todoTasks}',
                      radius: 54,
                      color: AppColors.todo,
                    ),
                    PieChartSectionData(
                      value: (stats.overdueTasks / total) * 100,
                      title: '${stats.overdueTasks}',
                      radius: 54,
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
        Text(label),
      ],
    );
  }
}