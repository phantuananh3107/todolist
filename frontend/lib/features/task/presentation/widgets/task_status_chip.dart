import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/enums/task_status.dart';

class TaskStatusChip extends StatelessWidget {
  final TaskStatus status;

  const TaskStatusChip({
    super.key,
    required this.status,
  });

  Color get _color {
    switch (status) {
      case TaskStatus.todo:
        return AppColors.todo;
      case TaskStatus.doing:
        return AppColors.warning;
      case TaskStatus.done:
        return AppColors.success;
      case TaskStatus.overdue:
        return AppColors.danger;
    }
  }

  String get _text {
    switch (status) {
      case TaskStatus.todo:
        return 'To-do';
      case TaskStatus.doing:
        return 'Doing';
      case TaskStatus.done:
        return 'Done';
      case TaskStatus.overdue:
        return 'Overdue';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(_text),
      backgroundColor: _color.withOpacity(0.12),
      side: BorderSide.none,
      labelStyle: TextStyle(
        color: _color,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}