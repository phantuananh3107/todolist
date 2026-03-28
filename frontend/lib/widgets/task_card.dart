import 'package:flutter/material.dart';

import '../models/task_item.dart';
import '../theme/app_theme.dart';
import 'app_chip.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({super.key, required this.task, this.onTap});

  final TaskItem task;
  final VoidCallback? onTap;

  String get dateText {
    final now = DateTime.now();
    final diff = task.dueDate.difference(DateTime(now.year, now.month, now.day)).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    return '${task.dueDate.day}/${task.dueDate.month}/${task.dueDate.year}';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: task.isCompleted ? AppColors.primary : Colors.transparent,
                  border: Border.all(color: task.isCompleted ? AppColors.primary : const Color(0xFFBFCCDD), width: 2),
                ),
                child: task.isCompleted
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            task.title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: task.isCompleted ? AppColors.subText : AppColors.text,
                              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: task.category == 'Work'
                                ? const Color(0xFFF3E8FF)
                                : task.category == 'Study'
                                    ? const Color(0xFFE0EDFF)
                                    : const Color(0xFFFDE7F3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            task.category.toUpperCase(),
                            style: TextStyle(
                              color: task.category == 'Work'
                                  ? AppColors.purple
                                  : task.category == 'Study'
                                      ? AppColors.info
                                      : const Color(0xFFDB2777),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 15, color: AppColors.subText),
                        const SizedBox(width: 6),
                        Text(
                          dateText,
                          style: TextStyle(
                            color: task.priority == 'HIGH' && !task.isCompleted ? AppColors.primary : AppColors.subText,
                            fontWeight: task.priority == 'HIGH' ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        AppChip(
                          label: task.priority,
                          background: priorityBg(task.priority),
                          textColor: priorityText(task.priority),
                        ),
                        AppChip(
                          label: task.status,
                          background: statusBg(task.status),
                          textColor: statusText(task.status),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
