import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../controller/statistics_controller.dart';
import '../controller/task_controller.dart';
import 'widgets/statistics_filter_tabs.dart';
import 'widgets/statistics_pie_chart.dart';
import 'widgets/statistics_summary_card.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StatisticsController>().fetchRemoteStatistics();
    });
  }

  @override
  Widget build(BuildContext context) {
    final statisticsController = context.watch<StatisticsController>();
    final taskController = context.watch<TaskController>();

    final stats = statisticsController.remoteStats ??
        statisticsController.buildFromTasks(taskController);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StatisticsFilterTabs(
              value: statisticsController.filterType,
              onChanged: (value) async {
                statisticsController.changeFilter(value);
                await statisticsController.fetchRemoteStatistics();
              },
            ),
            const SizedBox(height: 16),
            if (statisticsController.isLoading)
              const AppLoading(message: 'Đang tải thống kê...')
            else if (statisticsController.errorMessage != null &&
                statisticsController.remoteStats == null)
              AppErrorState(
                message: statisticsController.errorMessage!,
                onRetry: statisticsController.fetchRemoteStatistics,
              )
            else ...[
              Row(
                children: [
                  Expanded(
                    child: StatisticsSummaryCard(
                      title: 'Completed',
                      value: stats.completedTasks.toString(),
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatisticsSummaryCard(
                      title: 'Incomplete',
                      value: stats.incompleteTasks.toString(),
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: StatisticsSummaryCard(
                      title: 'Total',
                      value: stats.totalTasks.toString(),
                      color: AppColors.info,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatisticsSummaryCard(
                      title: 'Overdue',
                      value: stats.overdueTasks.toString(),
                      color: AppColors.danger,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              StatisticsPieChart(stats: stats),
              const SizedBox(height: 20),
              Text(
                'Tỷ lệ hoàn thành: ${stats.completedPercent.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Màn thống kê đang ưu tiên lấy dữ liệu từ backend; nếu chưa có endpoint phù hợp thì sẽ fallback sang dữ liệu task local.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}