import 'package:flutter/material.dart';

import '../models/task_item.dart';
import '../theme/app_theme.dart';
import 'app_chip.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.onStatusToggle,
    this.categoryColorHex,
  });

  final TaskItem task;
  final VoidCallback? onTap;
  final VoidCallback? onStatusToggle;
  final String? categoryColorHex;

  String get dateText {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day);
    final diff = dueDay.difference(today).inDays;
    final timeText = '${task.dueDate.hour.toString().padLeft(2, '0')}:${task.dueDate.minute.toString().padLeft(2, '0')}';
    if (diff == 0) return 'Hôm nay · $timeText';
    if (diff == 1) return 'Ngày mai · $timeText';
    return '${task.dueDate.day}/${task.dueDate.month}/${task.dueDate.year} · $timeText';
  }

  Color? _categoryBase() {
    final value = (categoryColorHex ?? '').replaceAll('#', '');
    if (value.length == 6) {
      return Color(int.parse('FF$value', radix: 16));
    }
    return null;
  }

  Color _categoryBackground() {
    final base = _categoryBase();
    if (base != null) return base.withOpacity(0.14);
    final key = task.category.toLowerCase();
    if (key.contains('công') || key.contains('work')) return const Color(0xFFF3EBFF);
    if (key.contains('học') || key.contains('study')) return const Color(0xFFE8F1FF);
    return const Color(0xFFFFEFF4);
  }

  Color _categoryText() {
    final base = _categoryBase();
    if (base != null) return base;
    final key = task.category.toLowerCase();
    if (key.contains('công') || key.contains('work')) return AppColors.purple;
    if (key.contains('học') || key.contains('study')) return AppColors.info;
    return const Color(0xFFD14A7A);
  }

  @override
  Widget build(BuildContext context) {
    final isDone = task.status == 'DONE';
    final isHigh = task.priority == 'HIGH';

    return Hero(
      tag: 'task-${task.id}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          splashColor: AppColors.primary.withOpacity(0.08),
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: AppColors.border),
              boxShadow: AppColors.softShadow,
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: onStatusToggle,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      width: 28,
                      height: 28,
                      margin: const EdgeInsets.only(top: 2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDone ? AppColors.primary : Colors.white,
                        border: Border.all(
                          color: isDone ? AppColors.primary : const Color(0xFFD9DDE6),
                          width: 1.8,
                        ),
                        boxShadow: isDone ? AppColors.buttonShadow : const [],
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 240),
                        child: isDone
                            ? const Icon(Icons.check_rounded, key: ValueKey('done'), size: 16, color: Colors.white)
                            : const SizedBox.shrink(key: ValueKey('todo')),
                      ),
                    ),
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
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontSize: 17,
                                      color: isDone ? AppColors.subText : AppColors.text,
                                      decoration: isDone ? TextDecoration.lineThrough : null,
                                      decorationThickness: 2,
                                    ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: _categoryBackground(),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                task.category,
                                style: TextStyle(
                                  color: _categoryText(),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (task.description.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            task.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: isHigh ? AppColors.primarySoft : AppColors.surfaceMuted,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.schedule_rounded,
                                size: 18,
                                color: isHigh ? AppColors.primary : AppColors.subText,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                dateText,
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: isHigh && !isDone ? AppColors.primaryDark : AppColors.subText,
                                    ),
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, color: AppColors.subText),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            AppChip(
                              label: task.priority,
                              icon: priorityIcon(task.priority),
                              background: priorityBg(task.priority),
                              textColor: priorityText(task.priority),
                            ),
                            AppChip(
                              label: task.status,
                              icon: statusIcon(task.status),
                              background: statusBg(task.status),
                              textColor: statusText(task.status),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
