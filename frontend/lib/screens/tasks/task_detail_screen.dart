import 'package:flutter/material.dart';

import '../../models/reminder_item.dart';
import '../../models/task_item.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_refresh_bus.dart';
import '../../utils/auth_navigation.dart';
import '../../widgets/app_chip.dart';
import '../../widgets/section_card.dart';
import 'task_form_screen.dart';

class TaskDetailScreen extends StatefulWidget {
  const TaskDetailScreen({super.key, required this.task});

  final TaskItem task;

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late TaskItem _task;
  bool _saving = false;
  List<ReminderItem> _reminders = [];

  @override
  void initState() {
    super.initState();
    _task = widget.task;
    _loadReminders();
  }

  String get _dateText =>
      '${_task.dueDate.day}/${_task.dueDate.month}/${_task.dueDate.year} · ${_task.dueDate.hour.toString().padLeft(2, '0')}:${_task.dueDate.minute.toString().padLeft(2, '0')}';

  bool get _isOverdue => _task.status != 'DONE' && _task.dueDate.isBefore(DateTime.now());

  Future<void> _loadReminders() async {
    try {
      final all = await ApiService.fetchReminders();
      if (!mounted) return;
      setState(() {
        _reminders = all.where((e) => e.taskId == _task.id).toList()..sort((a, b) => a.remindTime.compareTo(b.remindTime));
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _reminders = [
          ReminderItem(id: 1000 + _task.id, taskId: _task.id, taskTitle: _task.title, remindTime: _task.dueDate.subtract(const Duration(hours: 1))),
        ];
      });
    }
  }

  Future<void> _updateStatus(String next) async {
    if (_saving) return;
    setState(() => _saving = true);
    final previous = _task;
    final updated = TaskItem(
      id: _task.id,
      title: _task.title,
      description: _task.description,
      priority: _task.priority,
      status: next,
      category: _task.category,
      categoryId: _task.categoryId,
      dueDate: _task.dueDate,
    );
    setState(() => _task = updated);
    try {
      await ApiService.updateTask(_task.id, {
        'title': _task.title,
        'description': _task.description,
        'priority': _task.priority,
        'status': next,
        'dueDate': _task.dueDate.toIso8601String(),
        'categoryId': _task.categoryId,
      });
      if (!mounted) return;
      AppRefreshBus.bumpTasks();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã cập nhật trạng thái')));
    } catch (e) {
      setState(() => _task = previous);
      if (ApiService.isUnauthorized(e)) {
        if (!mounted) return;
        await handleUnauthorized(context);
        return;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không thể cập nhật task.')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteTask() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa công việc'),
        content: const Text('Bạn có chắc muốn xóa công việc này không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ApiService.deleteTask(_task.id);
      if (!mounted) return;
      AppRefreshBus.bumpTasks();
      Navigator.pop(context, true);
    } catch (e) {
      if (ApiService.isUnauthorized(e)) {
        if (!mounted) return;
        await handleUnauthorized(context);
        return;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không thể xóa task.')));
    }
  }

  String _formatReminder(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year} · ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Hero(
            tag: 'task-${_task.id}',
            child: Material(
              color: Colors.transparent,
              child: SectionCard(
                gradient: const LinearGradient(
                  colors: [Colors.white, Color(0xFFFFFBFA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(_task.title, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 26)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFECE8),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(_task.category, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _task.description.isEmpty ? 'Chưa có mô tả cho công việc này.' : _task.description,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6, color: AppColors.subText),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        AppChip(
                          label: _task.priority,
                          icon: priorityIcon(_task.priority),
                          background: priorityBg(_task.priority),
                          textColor: priorityText(_task.priority),
                        ),
                        AppChip(
                          label: _isOverdue ? 'OVERDUE' : _task.status,
                          icon: statusIcon(_isOverdue ? 'OVERDUE' : _task.status),
                          background: statusBg(_isOverdue ? 'OVERDUE' : _task.status),
                          textColor: statusText(_isOverdue ? 'OVERDUE' : _task.status),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.tonalIcon(
                            onPressed: _saving || _task.status == 'DOING' ? null : () => _updateStatus('DOING'),
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: const Text('Đang làm'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _saving || _task.status == 'DONE' ? null : () => _updateStatus('DONE'),
                            icon: const Icon(Icons.check_rounded),
                            label: const Text('Hoàn thành'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Thông tin công việc', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                _DetailRow(icon: Icons.event_available_rounded, label: 'Hạn hoàn thành', value: _dateText),
                const SizedBox(height: 12),
                _DetailRow(icon: Icons.folder_open_rounded, label: 'Danh mục', value: _task.category),
                const SizedBox(height: 12),
                _DetailRow(icon: Icons.flag_rounded, label: 'Mức ưu tiên', value: _task.priority),
                const SizedBox(height: 12),
                _DetailRow(icon: Icons.track_changes_rounded, label: 'Trạng thái', value: _isOverdue ? 'OVERDUE' : _task.status),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Reminder', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text('Bạn có thể thay đổi reminder trong màn chỉnh sửa công việc.', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 8),
                if (_reminders.isEmpty)
                  Text('Chưa có reminder cho công việc này.', style: Theme.of(context).textTheme.bodyMedium)
                else
                  ..._reminders.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(18)),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(14)),
                              child: const Icon(Icons.notifications_active_rounded, color: AppColors.primary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_formatReminder(item.remindTime), style: Theme.of(context).textTheme.titleMedium),
                                  const SizedBox(height: 4),
                                  Text('Nhắc trước deadline để bạn không bỏ lỡ tiến độ.', style: Theme.of(context).textTheme.bodyMedium),
                                ],
                              ),
                            ),
                            const Icon(Icons.lock_clock_rounded, color: AppColors.subText),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () async {
                    final updated = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(builder: (_) => TaskFormScreen(existingTask: _task)),
                    );
                    if (!context.mounted) return;
                    Navigator.of(context).pop(updated == true);
                  },
                  icon: const Icon(Icons.edit_rounded),
                  label: const Text('Chỉnh sửa'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _deleteTask,
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Xóa task'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 4),
              Text(value, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ],
    );
  }
}
