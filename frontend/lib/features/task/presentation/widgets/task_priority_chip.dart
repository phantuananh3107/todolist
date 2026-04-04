import 'package:flutter/material.dart';

import '../../../../shared/enums/task_priority.dart';

class TaskPriorityChip extends StatelessWidget {
  final TaskPriority priority;

  const TaskPriorityChip({
    super.key,
    required this.priority,
  });

  String get _text {
    switch (priority) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(_text),
      backgroundColor: Colors.black.withOpacity(0.04),
      side: BorderSide.none,
    );
  }
}