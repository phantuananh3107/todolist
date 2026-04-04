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
        title: const Text('My Tasks'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ManageCategoryScreen(),
                ),
              );
            },
            icon: const Icon(Icons.category_outlined),
            tooltip: 'Manage Categories',
          ),
          IconButton(
            onPressed: () {
              setState(() {
                showFilters = !showFilters;
              });
            },
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Filter',
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SearchTaskScreen(),
                ),
              );
            },
            icon: const Icon(Icons.search),
            tooltip: 'Search',
          ),
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.statistics);
            },
            icon: const Icon(Icons.pie_chart_rounded),
            tooltip: 'Statistics',
          ),
        ],
      ),
      body: Column(
        children: [
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
                    padding: const EdgeInsets.all(16),
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
        backgroundColor: AppColors.primary,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CreateTaskScreen(),
            ),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}