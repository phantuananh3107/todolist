import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../data/models/task_model.dart';
import '../controller/reminder_controller.dart';
import 'widgets/reminder_bottom_sheet.dart';

class TaskRemindersScreen extends StatefulWidget {
  final TaskModel task;

  const TaskRemindersScreen({
    super.key,
    required this.task,
  });

  @override
  State<TaskRemindersScreen> createState() => _TaskRemindersScreenState();
}

class _TaskRemindersScreenState extends State<TaskRemindersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReminderController>().fetchRemindersByTask(widget.task.id);
    });
  }

  void _openCreateReminderSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => ReminderBottomSheet(
        taskId: widget.task.id,
        initialDateTime: widget.task.dueDate,
        onSaved: () {
          context.read<ReminderController>().fetchRemindersByTask(widget.task.id);
        },
      ),
    );
  }

  Future<void> _deleteReminder(int reminderId) async {
    final controller = context.read<ReminderController>();
    final success = await controller.deleteReminder(
      reminderId: reminderId,
      taskId: widget.task.id,
    );

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.errorMessage ?? 'Xoá reminder thất bại'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ReminderController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Reminders'),
      ),
      body: Builder(
        builder: (context) {
          if (controller.isLoading) {
            return const AppLoading(message: 'Đang tải reminder...');
          }

          if (controller.errorMessage != null && controller.reminders.isEmpty) {
            return AppErrorState(
              message: controller.errorMessage!,
              onRetry: () =>
                  controller.fetchRemindersByTask(widget.task.id),
            );
          }

          if (controller.reminders.isEmpty) {
            return const AppEmptyState(
              icon: Icons.notifications_off_outlined,
              title: 'Chưa có reminder nào',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: controller.reminders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, index) {
              final reminder = controller.reminders[index];
              return Card(
                child: ListTile(
                  title: Text(
                    DateFormat('HH:mm - dd/MM/yyyy').format(reminder.remindTime),
                  ),
                  trailing: IconButton(
                    onPressed: controller.isSubmitting
                        ? null
                        : () => _deleteReminder(reminder.id),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: controller.isSubmitting ? null : _openCreateReminderSheet,
        child: const Icon(Icons.add_alert_outlined),
      ),
    );
  }
}