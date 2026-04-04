import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/task_model.dart';
import '../../calendar/presentation/task_reminders_screen.dart';
import '../controller/task_controller.dart';
import '../controller/task_form_controller.dart';
import 'edit_task_screen.dart';

class TaskDetailScreen extends StatelessWidget {
  final TaskModel task;

  const TaskDetailScreen({
    super.key,
    required this.task,
  });

  String _priorityText(String value) {
    switch (value.toUpperCase()) {
      case 'LOW':
        return 'Low';
      case 'HIGH':
        return 'High';
      default:
        return 'Medium';
    }
  }

  Future<void> _handleDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Bạn có chắc muốn xoá công việc này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final formController = context.read<TaskFormController>();
    final success = await formController.deleteTask(task.id);

    if (!context.mounted) return;

    if (success) {
      await context.read<TaskController>().fetchTasks();
      if (!context.mounted) return;
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(formController.errorMessage ?? 'Xoá task thất bại'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final formController = context.watch<TaskFormController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Detail'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TaskRemindersScreen(task: task),
                ),
              );
            },
            icon: const Icon(Icons.notifications_active_outlined),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditTaskScreen(task: task),
                ),
              );
            },
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            onPressed: formController.isLoading
                ? null
                : () => _handleDelete(context),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    task.description ?? 'Không có mô tả',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _InfoRow(
                    label: 'Priority',
                    value: _priorityText(task.priority.name),
                  ),
                  _InfoRow(
                    label: 'Status',
                    value: task.status.name.toUpperCase(),
                  ),
                  _InfoRow(
                    label: 'Due date',
                    value: task.dueDate != null
                        ? DateFormat('dd/MM/yyyy').format(task.dueDate!)
                        : 'Chưa có',
                  ),
                  _InfoRow(
                    label: 'Category ID',
                    value: task.categoryId?.toString() ?? 'Chưa có',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}