import 'package:flutter/material.dart';

import '../../models/category_item.dart';
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

  List<CategoryItem> _categories = [];
  int? _selectedCategoryId;

  // AI Suggestion
  Map<String, dynamic>? _suggestion;
  bool _suggestingCategory = false;

  @override
  void initState() {
    super.initState();
    titleController =
        TextEditingController(text: widget.existingTask?.title ?? '');
    descriptionController =
        TextEditingController(text: widget.existingTask?.description ?? '');
    descriptionController.addListener(_onDescriptionChanged);
    priority = widget.existingTask?.priority ?? 'MEDIUM';
    status = widget.existingTask?.status ?? 'TODO';
    selectedDate =
        widget.existingTask?.dueDate ?? DateTime.now().add(const Duration(days: 1));
    _loadCategories();
  }

  /// Gợi ý category khi user nhập description (debounced)
  Future<void> _onDescriptionChanged() async {
    final desc = descriptionController.text.trim();

    // Reset suggestion nếu description rỗng
    if (desc.isEmpty) {
      setState(() => _suggestion = null);
      return;
    }

    // Gợi ý sau 1s không nhập
    Future.delayed(const Duration(seconds: 1), () async {
      if (!mounted || descriptionController.text.trim() != desc) return;

      setState(() => _suggestingCategory = true);
      try {
        final suggestion = await ApiService.suggestCategory(description: desc);
        if (!mounted) return;
        setState(() {
          _suggestion = suggestion;
          _suggestingCategory = false;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() => _suggestingCategory = false);
      }
    });
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await ApiService.fetchCategories();
      if (!mounted) return;
      _applyCategories(cats);
    } catch (e) {
      if (!mounted) return;
      // backend lỗi → dùng demo categories
      _applyCategories(demoCategories);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không load được categories — dùng dữ liệu demo'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _applyCategories(List<CategoryItem> cats) {
    setState(() {
      // bỏ "All" vì không phải category thật
      _categories = cats.where((c) => c.name != 'All').toList();

      // ưu tiên match theo categoryId, rồi fallback theo tên
      if (widget.existingTask != null) {
        final task = widget.existingTask!;
        if (task.categoryId != null) {
          final byId = _categories.where((c) => c.id == task.categoryId);
          if (byId.isNotEmpty) _selectedCategoryId = byId.first.id;
        }
        if (_selectedCategoryId == null) {
          final byName = _categories.where(
              (c) => c.name.toLowerCase() == task.category.toLowerCase());
          if (byName.isNotEmpty) _selectedCategoryId = byName.first.id;
        }
      }

      // chọn cái đầu nếu chưa match được
      _selectedCategoryId ??=
          _categories.isNotEmpty ? _categories.first.id : null;
    });
  }

  Future<void> _submit() async {
    if (titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tên task không được để trống')),
      );
      return;
    }

    // chặn nếu chưa chọn category
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn category')),
      );
      return;
    }

    setState(() => loading = true);
    final payload = {
      'title': titleController.text.trim(),
      'description': descriptionController.text.trim(),
      'priority': priority,
      'status': status,
      'dueDate': selectedDate.toIso8601String(),
      'categoryId': _selectedCategoryId,
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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Không thể lưu task: $e')));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _deleteTask() async {
    if (widget.existingTask == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa task'),
        content: const Text('Bạn chắc chắn muốn xóa task này?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Xóa', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await ApiService.deleteTask(widget.existingTask!.id);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Không thể xóa: $e')));
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.removeListener(_onDescriptionChanged);
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingTask != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Task' : 'Create Task'),
        actions: [
          if (isEdit)
            IconButton(
              onPressed: _deleteTask,
              icon: const Icon(Icons.delete_outline, color: Colors.red),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: titleController,
            decoration: const InputDecoration(labelText: 'Task name'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: descriptionController,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
          const SizedBox(height: 20),
          // AI Suggestion Box
          if (_suggestingCategory)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: Colors.blue[600], size: 20),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('Đang phân tích...', style: TextStyle(fontSize: 13))),
                ],
              ),
            )
          else if (_suggestion != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: Colors.red[600], size: 20),
                      const SizedBox(width: 8),
                      const Text('AI SUGGESTION',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.red),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Suggested Category: ${_suggestion?['categoryName'] ?? 'N/A'}',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${(_suggestion?['matchPercentage'] as num?)?.toStringAsFixed(0) ?? '0'}% Match',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        onPressed: () {
                          setState(() {
                            _selectedCategoryId = _suggestion?['categoryId'] as int?;
                            _suggestion = null;
                          });
                        },
                        child: const Text('Apply', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          if (_suggestion != null) const SizedBox(height: 20),
          const Text('Category',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          if (_categories.isNotEmpty)
            DropdownButtonFormField<int>(
              value: _selectedCategoryId,
              decoration:
                  const InputDecoration(labelText: 'Select category'),
              items: _categories
                  .map((c) => DropdownMenuItem(
                      value: c.id, child: Text(c.name)))
                  .toList(),
              onChanged: (val) =>
                  setState(() => _selectedCategoryId = val),
            )
          else
            const Text('Đang tải danh sách...'),
          const SizedBox(height: 20),
          const Text('Priority',
              style: TextStyle(fontWeight: FontWeight.w700)),
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
          const Text('Status',
              style: TextStyle(fontWeight: FontWeight.w700)),
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
            subtitle: Text(
                '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
            trailing: const Icon(Icons.calendar_month_outlined),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate:
                    DateTime.now().subtract(const Duration(days: 365)),
                lastDate:
                    DateTime.now().add(const Duration(days: 3650)),
              );
              if (picked != null) setState(() => selectedDate = picked);
            },
          ),
          const SizedBox(height: 28),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 18),
            ),
            onPressed: loading || _selectedCategoryId == null ? null : _submit,
            child: Text(loading
                ? 'Saving...'
                : (isEdit ? 'Update Task' : 'Create Task')),
          ),
        ],
      ),
    );
  }
}
