import 'package:flutter/material.dart';

import '../../models/task_item.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class TaskFormScreen extends StatefulWidget {
  const TaskFormScreen({super.key, this.existingTask});

  final TaskItem? existingTask;

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  late final TextEditingController titleController;
  late final TextEditingController descriptionController;
  String priority = 'MEDIUM';
  String status = 'TODO';
  DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
  bool loading = false;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.existingTask?.title ?? '');
    descriptionController = TextEditingController(text: widget.existingTask?.description ?? '');
    priority = widget.existingTask?.priority ?? 'MEDIUM';
    status = widget.existingTask?.status ?? 'TODO';
    selectedDate = widget.existingTask?.dueDate ?? DateTime.now().add(const Duration(days: 1));
  }

  Future<void> _submit() async {
    setState(() => loading = true);
    final payload = {
      'title': titleController.text.trim(),
      'description': descriptionController.text.trim(),
      'priority': priority,
      'status': status,
      'dueDate': selectedDate.toIso8601String(),
      'categoryId': 1,
    };

    try {
      if (widget.existingTask == null) {
        await ApiService.createTask(payload);
      } else {
        await ApiService.updateTask(widget.existingTask!.id, payload);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Không thể lưu task: $e')));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.existingTask == null ? 'Create Task' : 'Edit Task')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Task name')),
          const SizedBox(height: 16),
          TextField(controller: descriptionController, maxLines: 4, decoration: const InputDecoration(labelText: 'Description')),
          const SizedBox(height: 20),
          const Text('Priority', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            children: ['LOW', 'MEDIUM', 'HIGH']
                .map(
                  (e) => ChoiceChip(
                    label: Text(e),
                    selected: priority == e,
                    onSelected: (_) => setState(() => priority = e),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 20),
          const Text('Status', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            children: ['TODO', 'DOING', 'DONE']
                .map(
                  (e) => ChoiceChip(
                    label: Text(e),
                    selected: status == e,
                    onSelected: (_) => setState(() => status = e),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 20),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Due date'),
            subtitle: Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
            trailing: const Icon(Icons.calendar_month_outlined),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now().add(const Duration(days: 3650)),
              );
              if (picked != null) setState(() => selectedDate = picked);
            },
          ),
          const SizedBox(height: 28),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 18)),
            onPressed: loading ? null : _submit,
            child: Text(loading ? 'Saving...' : (widget.existingTask == null ? 'Create Task' : 'Update Task')),
          ),
        ],
      ),
    );
  }
}
