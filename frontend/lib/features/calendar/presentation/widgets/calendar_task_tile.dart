import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/task_model.dart';

class CalendarTaskTile extends StatelessWidget {
  final TaskModel task;
  final VoidCallback? onTap;

  const CalendarTaskTile({
    super.key,
    required this.task,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      title: Text(task.title),
      subtitle: Text(
        task.dueDate != null
            ? DateFormat('HH:mm - dd/MM/yyyy').format(task.dueDate!)
            : 'Chưa có hạn',
      ),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}