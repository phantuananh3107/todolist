import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/category_item.dart';
import '../../models/reminder_item.dart';
import '../../models/task_item.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_refresh_bus.dart';
import '../../utils/auth_navigation.dart';
import '../../widgets/section_card.dart';
import '../../widgets/soft_action_button.dart';

class TaskFormScreen extends StatefulWidget {
  const TaskFormScreen({super.key, this.existingTask, this.initialDate});

  final TaskItem? existingTask;
  final DateTime? initialDate;

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();

  static const _palette = ['#FF5C54', '#3B82F6', '#22C55E', '#F97316', '#A855F7'];

  Color _categoryDotColor(String? hex) {
    final value = (hex ?? '').replaceAll('#', '');
    if (value.length == 6) return Color(int.parse('FF$value', radix: 16));
    return AppColors.primary;
  }

  Future<Map<String, String>?> _showInlineCategoryDialog() async {
    final controller = TextEditingController();
    String selected = _palette.first;
    return showDialog<Map<String, String>>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Thêm category mới'),
        content: StatefulBuilder(
          builder: (context, setModalState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(hintText: 'Ví dụ: Học tập, Công việc'),
              ),
              const SizedBox(height: 16),
              Text('Màu category', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                children: _palette.map((hex) {
                  final color = _categoryDotColor(hex);
                  final active = selected == hex;
                  return GestureDetector(
                    onTap: () => setModalState(() => selected = hex),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(color: active ? Colors.white : Colors.transparent, width: 3),
                        boxShadow: [BoxShadow(color: color.withOpacity(.24), blurRadius: 10)],
                      ),
                      child: active
                          ? Container(
                              margin: const EdgeInsets.all(3),
                              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.primary, width: 2)),
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(context, {'name': controller.text.trim(), 'colorHex': selected}), child: const Text('Thêm')),
        ],
      ),
    );
  }
  late final TextEditingController titleController;
  late final TextEditingController descriptionController;
  String priority = 'MEDIUM';
  String status = 'TODO';
  DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
  bool loading = false;
  bool _addingCategory = false;
  bool _reminderEnabled = false;
  DateTime? _reminderTime;
  int? _existingReminderId;
  List<int> _extraReminderIds = [];
  String? _suggestedCategory;
  String? _suggestedMatch;
  String? _suggestedReason;
  bool _suggestingCategory = false;
  Timer? _suggestionDebounce;

  List<CategoryItem> _categories = [];
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.existingTask?.title ?? '');
    descriptionController = TextEditingController(text: widget.existingTask?.description ?? '');
    priority = widget.existingTask?.priority ?? 'MEDIUM';
    status = widget.existingTask?.status ?? 'TODO';
    selectedDate = widget.existingTask?.dueDate ?? widget.initialDate ?? DateTime.now().add(const Duration(days: 1));
    _reminderTime = selectedDate.subtract(const Duration(minutes: 30));
    titleController.addListener(_scheduleSuggestion);
    descriptionController.addListener(_scheduleSuggestion);
    _loadCategories();
    _loadExistingReminder();
  }

  @override
  void dispose() {
    _suggestionDebounce?.cancel();
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await ApiService.fetchCategories();
      if (!mounted) return;
      _applyCategories(cats);
    } catch (e) {
      if (ApiService.isUnauthorized(e)) {
        if (!mounted) return;
        await handleUnauthorized(context);
        return;
      }
      if (!mounted) return;
      _applyCategories(demoCategories);
    }
  }

  Future<void> _loadExistingReminder() async {
    if (widget.existingTask == null) return;
    try {
      final reminders = await ApiService.fetchReminders();
      if (!mounted) return;
      final matches = reminders.where((item) => item.taskId == widget.existingTask!.id).toList()
        ..sort((a, b) => a.remindTime.compareTo(b.remindTime));
      if (matches.isEmpty) return;
      setState(() {
        _existingReminderId = matches.first.id;
        _extraReminderIds = matches.skip(1).map((e) => e.id).toList();
        _reminderTime = matches.first.remindTime;
        _reminderEnabled = true;
      });
    } catch (_) {}
  }

  Future<void> _syncReminderForTask(int taskId) async {
    if (_reminderEnabled && _reminderTime != null) {
      if (_existingReminderId != null) {
        await ApiService.updateReminder(_existingReminderId!, _reminderTime!);
      } else {
        await ApiService.createReminder(taskId: taskId, remindTime: _reminderTime!);
        try {
          final reminders = await ApiService.fetchReminders();
          final matches = reminders.where((item) => item.taskId == taskId).toList()
            ..sort((a, b) => a.remindTime.compareTo(b.remindTime));
          if (matches.isNotEmpty) {
            _existingReminderId = matches.first.id;
            _extraReminderIds = matches.skip(1).map((e) => e.id).toList();
          }
        } catch (_) {}
      }
      for (final extraId in List<int>.from(_extraReminderIds)) {
        try {
          await ApiService.deleteReminder(extraId);
        } catch (_) {}
      }
      _extraReminderIds = [];
      AppRefreshBus.bumpNotifications();
      return;
    }

    final idsToDelete = [
      if (_existingReminderId != null) _existingReminderId!,
      ..._extraReminderIds,
    ];
    for (final reminderId in idsToDelete) {
      try {
        await ApiService.deleteReminder(reminderId);
      } catch (_) {}
    }
    _existingReminderId = null;
    _extraReminderIds = [];
    AppRefreshBus.bumpNotifications();
  }

  void _applyCategories(List<CategoryItem> cats) {
    _categories = cats.where((c) => c.name != 'All').toList();
    if (widget.existingTask != null) {
      final task = widget.existingTask!;
      if (task.categoryId != null) {
        final byId = _categories.where((c) => c.id == task.categoryId);
        if (byId.isNotEmpty) _selectedCategoryId = byId.first.id;
      }
      if (_selectedCategoryId == null) {
        final byName = _categories.where((c) => c.name.toLowerCase() == task.category.toLowerCase());
        if (byName.isNotEmpty) _selectedCategoryId = byName.first.id;
      }
    }
    _selectedCategoryId ??= _categories.isNotEmpty ? _categories.first.id : null;
    _scheduleSuggestion();
    if (mounted) setState(() {});
  }

  void _scheduleSuggestion() {
    _suggestionDebounce?.cancel();
    final title = titleController.text.trim();
    final description = descriptionController.text.trim();

    if (_categories.isEmpty || (title.isEmpty && description.isEmpty)) {
      if (mounted) {
        setState(() {
          _suggestedCategory = null;
          _suggestedMatch = null;
          _suggestedReason = null;
          _suggestingCategory = false;
        });
      }
      return;
    }

    _suggestionDebounce = Timer(const Duration(milliseconds: 700), () async {
      if (!mounted) return;
      setState(() => _suggestingCategory = true);
      try {
        final apiSuggestion = await ApiService.suggestCategory(
          description: [title, description].where((e) => e.isNotEmpty).join(' - '),
        );
        if (!mounted) return;
        if (apiSuggestion != null) {
          setState(() {
            _suggestedCategory = apiSuggestion['categoryName']?.toString();
            final matchValue = apiSuggestion['matchPercentage'];
            if (matchValue is num) {
              _suggestedMatch = matchValue.toStringAsFixed(0);
            } else {
              _suggestedMatch = matchValue?.toString() ?? '80';
            }
            _suggestedReason = apiSuggestion['reason']?.toString();
            _suggestingCategory = false;
          });
          return;
        }
      } catch (_) {
        // fallback local below
      }

      final local = localAiCategorySuggestion(title, description, _categories);
      if (!mounted) return;
      setState(() {
        _suggestedCategory = local.first;
        _suggestedMatch = local.length > 1 ? local[1] : '80';
        _suggestedReason = 'Gợi ý dự phòng';
        _suggestingCategory = false;
      });
    });
  }

  Future<void> _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (pickedDate == null || !mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(selectedDate),
    );
    if (pickedTime == null) return;
    setState(() {
      selectedDate = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
      _reminderTime ??= selectedDate.subtract(const Duration(minutes: 30));
      if (_reminderTime!.isAfter(selectedDate)) {
        _reminderTime = selectedDate.subtract(const Duration(minutes: 30));
      }
    });
  }

  Future<void> _pickReminderTime() async {
    final initial = _reminderTime ?? selectedDate.subtract(const Duration(minutes: 30));
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: selectedDate,
    );
    if (pickedDate == null || !mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (pickedTime == null) return;
    setState(() {
      _reminderTime = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
      _reminderEnabled = true;
    });
  }

  Future<void> _addCategoryInline() async {
    final data = await _showInlineCategoryDialog();
    final createdName = data?['name']?.trim() ?? '';
    final colorHex = data?['colorHex'];

    if (createdName.isEmpty) return;
    setState(() => _addingCategory = true);
    try {
      final category = await ApiService.createCategory(createdName, colorHex: colorHex);
      if (!mounted) return;
      setState(() {
        _categories = [..._categories, category];
        _selectedCategoryId = category.id;
      });
      _scheduleSuggestion();
      AppRefreshBus.bumpCategories();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã thêm category.')));
    } catch (e) {
      if (ApiService.isUnauthorized(e)) {
        if (!mounted) return;
        await handleUnauthorized(context);
        return;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Không thể thêm category: $e')));
    } finally {
      if (mounted) setState(() => _addingCategory = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn category.')));
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
        final createdTask = await ApiService.createTask(payload);
        await _syncReminderForTask(createdTask.id);
      } else {
        await ApiService.updateTask(widget.existingTask!.id, payload);
        await _syncReminderForTask(widget.existingTask!.id);
      }
      if (!mounted) return;
      AppRefreshBus.bumpTasks();
      AppRefreshBus.bumpNotifications();
      Navigator.pop(context, true);
    } catch (e) {
      if (ApiService.isUnauthorized(e)) {
        if (!mounted) return;
        await handleUnauthorized(context);
        return;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Không thể lưu task: $e')));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _deleteTask() async {
    if (widget.existingTask == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Xóa công việc'),
        content: const Text('Bạn có chắc muốn xóa task này khỏi danh sách không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa')),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await ApiService.deleteTask(widget.existingTask!.id);
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Không thể xóa: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingTask != null;
    final dateText =
        '${selectedDate.day}/${selectedDate.month}/${selectedDate.year} · ${selectedDate.hour.toString().padLeft(2, '0')}:${selectedDate.minute.toString().padLeft(2, '0')}';
    final reminderText = _reminderTime == null
        ? 'Chưa đặt nhắc việc'
        : '${_reminderTime!.day}/${_reminderTime!.month}/${_reminderTime!.year} · ${_reminderTime!.hour.toString().padLeft(2, '0')}:${_reminderTime!.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Chỉnh sửa task' : 'Tạo task mới'),
        actions: [
          if (isEdit)
            IconButton(
              onPressed: _deleteTask,
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
          children: [
            SectionCard(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFFBFA), Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isEdit ? 'Cập nhật thông tin công việc' : 'Thêm công việc mới', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    'Điền thông tin công việc, thời gian và danh mục để lưu vào kế hoạch của bạn.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: titleController,
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Tên task không được để trống' : null,
                    decoration: const InputDecoration(labelText: 'Tên công việc', prefixIcon: Icon(Icons.title_rounded)),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descriptionController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Mô tả công việc',
                      prefixIcon: Icon(Icons.notes_rounded),
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              gradient: const LinearGradient(colors: [Color(0xFFFFFBFF), Color(0xFFFFF4EF)]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(16)),
                        child: const Icon(Icons.auto_awesome_rounded, color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text('AI Suggestion', style: Theme.of(context).textTheme.titleLarge)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _suggestedCategory == null
                        ? 'Nhập tiêu đề hoặc mô tả để AI gợi ý category phù hợp.'
                        : 'AI gợi ý xếp task này vào $_suggestedCategory với độ khớp $_suggestedMatch%.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: SoftActionButton(
                          label: _suggestedCategory == null ? 'Chưa có gợi ý' : 'Apply $_suggestedCategory',
                          icon: Icons.bolt_rounded,
                          onPressed: _suggestedCategory == null
                              ? null
                              : () {
                                  final match = _categories.where((e) => e.name.toLowerCase() == _suggestedCategory!.toLowerCase());
                                  if (match.isNotEmpty) {
                                    setState(() => _selectedCategoryId = match.first.id);
                                  }
                                },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Trạng thái & ưu tiên', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: status,
                    decoration: const InputDecoration(labelText: 'Trạng thái', prefixIcon: Icon(Icons.track_changes_rounded)),
                    items: const [
                      DropdownMenuItem(value: 'TODO', child: Text('To-do')),
                      DropdownMenuItem(value: 'DOING', child: Text('Doing')),
                      DropdownMenuItem(value: 'DONE', child: Text('Done')),
                    ],
                    onChanged: (value) => setState(() => status = value ?? 'TODO'),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: priority,
                    decoration: const InputDecoration(labelText: 'Mức ưu tiên', prefixIcon: Icon(Icons.flag_rounded)),
                    items: const [
                      DropdownMenuItem(value: 'LOW', child: Text('Low')),
                      DropdownMenuItem(value: 'MEDIUM', child: Text('Medium')),
                      DropdownMenuItem(value: 'HIGH', child: Text('High')),
                    ],
                    onChanged: (value) => setState(() => priority = value ?? 'MEDIUM'),
                  ),
                  const SizedBox(height: 14),
                  InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: _pickDateTime,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Ngày & giờ hoàn thành',
                        prefixIcon: Icon(Icons.event_available_rounded),
                        suffixIcon: Icon(Icons.chevron_right_rounded),
                      ),
                      child: Text(dateText, style: Theme.of(context).textTheme.titleMedium),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text('Category', style: Theme.of(context).textTheme.titleLarge)),
                      TextButton.icon(
                        onPressed: _addingCategory ? null : _addCategoryInline,
                        icon: _addingCategory
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.add_circle_outline_rounded),
                        label: const Text('Thêm category'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    value: _selectedCategoryId,
                    decoration: const InputDecoration(labelText: 'Danh mục', prefixIcon: Icon(Icons.folder_open_rounded)),
                    items: _categories
                        .map((category) => DropdownMenuItem<int>(
                              value: category.id,
                              child: Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: _categoryDotColor(category.colorHex),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(category.name),
                                ],
                              ),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() => _selectedCategoryId = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text('Reminder', style: Theme.of(context).textTheme.titleLarge)),
                      Switch.adaptive(
                        value: _reminderEnabled,
                        onChanged: (value) => setState(() => _reminderEnabled = value),
                      ),
                    ],
                  ),
                  Text(
                    isEdit
                        ? 'Chọn thời điểm nhắc việc ngay trong màn chỉnh sửa.'
                        : 'Thiết lập trước thời điểm nhắc việc cùng với công việc mới.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  if (_reminderEnabled)
                    InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: _pickReminderTime,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Thời gian nhắc việc',
                          prefixIcon: Icon(Icons.alarm_rounded),
                          suffixIcon: Icon(Icons.chevron_right_rounded),
                        ),
                        child: Text(reminderText, style: Theme.of(context).textTheme.titleMedium),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: loading ? null : _submit,
              icon: loading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check_circle_outline_rounded),
              label: Text(isEdit ? 'Lưu thay đổi' : 'Tạo công việc'),
            ),
          ],
        ),
      ),
    );
  }
}
