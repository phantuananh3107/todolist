import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/task_model.dart';
import '../task_detail_screen.dart';
import 'task_priority_chip.dart';
import 'task_status_chip.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;

  const TaskCard({
    super.key,
    required this.task,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TaskDetailScreen(task: task),
          ),
        );
      },
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (task.description != null && task.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  task.description!,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  TaskStatusChip(status: task.status),
                  TaskPriorityChip(priority: task.priority),
                  if (task.dueDate != null)
                    Chip(
                      label: Text(DateFormat('dd/MM/yyyy').format(task.dueDate!)),
                      backgroundColor: Colors.black.withOpacity(0.04),
                      side: BorderSide.none,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}