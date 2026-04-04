import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/enums/task_priority.dart';
import '../../../../shared/enums/task_status.dart';
import '../../controller/task_controller.dart';

class TaskFilterBar extends StatelessWidget {
  final TaskStatus? selectedStatus;
  final TaskPriority? selectedPriority;
  final TaskSortType sortType;
  final ValueChanged<TaskStatus?> onStatusChanged;
  final ValueChanged<TaskPriority?> onPriorityChanged;
  final ValueChanged<TaskSortType> onSortChanged;
  final VoidCallback onClearFilters;

  const TaskFilterBar({
    super.key,
    required this.selectedStatus,
    required this.selectedPriority,
    required this.sortType,
    required this.onStatusChanged,
    required this.onPriorityChanged,
    required this.onSortChanged,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bộ lọc công việc',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<TaskStatus?>(
              initialValue: selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Lọc theo trạng thái',
              ),
              items: const [
                DropdownMenuItem<TaskStatus?>(
                  value: null,
                  child: Text('Tất cả trạng thái'),
                ),
                DropdownMenuItem(
                  value: TaskStatus.todo,
                  child: Text('To-do'),
                ),
                DropdownMenuItem(
                  value: TaskStatus.doing,
                  child: Text('Doing'),
                ),
                DropdownMenuItem(
                  value: TaskStatus.done,
                  child: Text('Done'),
                ),
                DropdownMenuItem(
                  value: TaskStatus.overdue,
                  child: Text('Overdue'),
                ),
              ],
              onChanged: onStatusChanged,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<TaskPriority?>(
              initialValue: selectedPriority,
              decoration: const InputDecoration(
                labelText: 'Lọc theo mức độ ưu tiên',
              ),
              items: const [
                DropdownMenuItem<TaskPriority?>(
                  value: null,
                  child: Text('Tất cả mức độ'),
                ),
                DropdownMenuItem(
                  value: TaskPriority.low,
                  child: Text('Low'),
                ),
                DropdownMenuItem(
                  value: TaskPriority.medium,
                  child: Text('Medium'),
                ),
                DropdownMenuItem(
                  value: TaskPriority.high,
                  child: Text('High'),
                ),
              ],
              onChanged: onPriorityChanged,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<TaskSortType>(
              initialValue: sortType,
              decoration: const InputDecoration(
                labelText: 'Sắp xếp theo',
              ),
              items: const [
                DropdownMenuItem(
                  value: TaskSortType.newest,
                  child: Text('Mới nhất'),
                ),
                DropdownMenuItem(
                  value: TaskSortType.dueDateAsc,
                  child: Text('Deadline tăng dần'),
                ),
                DropdownMenuItem(
                  value: TaskSortType.dueDateDesc,
                  child: Text('Deadline giảm dần'),
                ),
              ],
              onChanged: (value) {
                if (value != null) onSortChanged(value);
              },
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onClearFilters,
                child: const Text('Xóa bộ lọc'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
