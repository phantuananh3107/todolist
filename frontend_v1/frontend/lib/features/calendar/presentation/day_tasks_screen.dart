import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_empty_state.dart';
import '../../task/controller/task_controller.dart';
import '../../task/presentation/widgets/task_card.dart';

class DayTasksScreen extends StatelessWidget {
  final DateTime selectedDay;

  const DayTasksScreen({
    super.key,
    required this.selectedDay,
  });

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final taskController = context.watch<TaskController>();

    final dayTasks = taskController.tasks.where((task) {
      if (task.dueDate == null) return false;
      return _isSameDay(task.dueDate!, selectedDay);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Tasks ${DateFormat('dd/MM/yyyy').format(selectedDay)}',
        ),
      ),
      body: dayTasks.isEmpty
          ? const AppEmptyState(
              icon: Icons.event_busy_outlined,
              title: 'Không có công việc nào trong ngày này',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: dayTasks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, index) => TaskCard(task: dayTasks[index]),
            ),
    );
  }
}