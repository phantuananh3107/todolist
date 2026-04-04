import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../controller/task_controller.dart';
import 'create_task_screen.dart';
import 'manage_category_screen.dart';
import 'search_task_screen.dart';
import 'widgets/task_card.dart';
import 'widgets/task_filter_bar.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  bool showFilters = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskController>().fetchTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TaskController>();

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 88,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Task Manager'),
            SizedBox(height: 4),
            Text(
              'Quản lý công việc của bạn mỗi ngày',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          _HeaderAction(
            icon: Icons.category_outlined,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ManageCategoryScreen(),
                ),
              );
            },
          ),
          _HeaderAction(
            icon: Icons.tune_rounded,
            onTap: () {
              setState(() {
                showFilters = !showFilters;
              });
            },
          ),
          _HeaderAction(
            icon: Icons.search,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SearchTaskScreen(),
                ),
              );
            },
          ),
          _HeaderAction(
            icon: Icons.pie_chart_rounded,
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.statistics);
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Hôm nay của bạn',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${controller.tasks.length} công việc đang được theo dõi',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.assignment_turned_in_rounded,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (showFilters)
            TaskFilterBar(
              selectedStatus: controller.selectedStatus,
              selectedPriority: controller.selectedPriority,
              sortType: controller.sortType,
              onStatusChanged: controller.setStatusFilter,
              onPriorityChanged: controller.setPriorityFilter,
              onSortChanged: controller.setSortType,
              onClearFilters: controller.clearFilters,
            ),
          const SizedBox(height: 8),
          Expanded(
            child: Builder(
              builder: (context) {
                if (controller.isLoading) {
                  return const AppLoading(message: 'Đang tải công việc...');
                }

                if (controller.errorMessage != null) {
                  return AppErrorState(
                    message: controller.errorMessage!,
                    onRetry: controller.fetchTasks,
                  );
                }

                if (controller.tasks.isEmpty) {
                  return const AppEmptyState(
                    icon: Icons.task_alt_outlined,
                    title: 'Chưa có công việc nào',
                    subtitle: 'Hãy tạo task đầu tiên của bạn',
                  );
                }

                return RefreshIndicator(
                  onRefresh: controller.refreshTasks,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: controller.tasks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final task = controller.tasks[index];
                      return TaskCard(task: task);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CreateTaskScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderAction({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, color: AppColors.textPrimary, size: 20),
        ),
      ),
    );
  }
}
