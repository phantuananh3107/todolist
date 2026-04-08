import 'package:flutter/material.dart';

import '../../models/category_item.dart';
import '../../models/task_item.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_refresh_bus.dart';
import '../../utils/auth_navigation.dart';
import '../../widgets/app_chip.dart';
import '../../widgets/empty_state_card.dart';
import '../../widgets/notification_button.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/section_card.dart';
import '../../widgets/task_card.dart';
import '../tasks/task_detail_screen.dart';
import 'category_management_screen.dart';
import 'task_form_screen.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  List<TaskItem> tasks = [];
  List<CategoryItem> categories = [];
  String selectedCategory = 'All';
  bool loading = true;

  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _priorityFilter;
  String? _statusFilter;
  String _sortMode = 'deadline_asc';

  @override
  void initState() {
    super.initState();
    AppRefreshBus.tasks.addListener(_load);
    AppRefreshBus.categories.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    AppRefreshBus.tasks.removeListener(_load);
    AppRefreshBus.categories.removeListener(_load);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final fetchedTasks = await ApiService.fetchTasks();
      var fetchedCategories = await ApiService.fetchCategories();
      if (!mounted) return;
      fetchedCategories = List.of(fetchedCategories);
      if (fetchedCategories.isEmpty || fetchedCategories.first.name != 'All') {
        fetchedCategories.insert(0, CategoryItem(id: 0, name: 'All', taskCount: fetchedTasks.length));
      }
      setState(() {
        tasks = fetchedTasks;
        categories = fetchedCategories;
        loading = false;
      });
    } catch (e) {
      if (ApiService.isUnauthorized(e)) {
        if (!mounted) return;
        setState(() => loading = false);
        await handleUnauthorized(context);
        return;
      }
      if (!mounted) return;
      setState(() {
        tasks = [];
        categories = [CategoryItem(id: 0, name: 'All', taskCount: 0)];
        loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không kết nối được backend tại ${ApiService.baseUrl}. Hãy kiểm tra backend đang chạy ở cổng 8080.')),
      );
    }
  }

  int get _activeFilterCount =>
      (_priorityFilter != null ? 1 : 0) + (_statusFilter != null ? 1 : 0) + (_sortMode == 'deadline_asc' ? 0 : 1);

  List<TaskItem> get filteredTasks {
    var result = List<TaskItem>.from(tasks);
    if (selectedCategory != 'All') {
      result = result.where((e) => e.category.toLowerCase() == selectedCategory.toLowerCase()).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((e) => e.title.toLowerCase().contains(q) || e.description.toLowerCase().contains(q)).toList();
    }
    if (_priorityFilter != null) {
      result = result.where((e) => e.priority == _priorityFilter).toList();
    }
    if (_statusFilter != null) {
      result = result.where((e) => e.status == _statusFilter).toList();
    }
    switch (_sortMode) {
      case 'deadline_desc':
        result.sort((a, b) => b.dueDate.compareTo(a.dueDate));
        break;
      case 'alpha_asc':
        result.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case 'alpha_desc':
        result.sort((a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
        break;
      default:
        result.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    }
    return result;
  }

  int get _doneCount => tasks.where((e) => e.status == 'DONE').length;
  int get _doingCount => tasks.where((e) => e.status == 'DOING').length;
  int get _todoCount => tasks.where((e) => e.status == 'TODO').length;
  int get _highPriorityCount => tasks.where((e) => e.priority == 'HIGH').length;
  int get _dueTodayCount {
    final now = DateTime.now();
    return tasks.where((e) => e.dueDate.year == now.year && e.dueDate.month == now.month && e.dueDate.day == now.day).length;
  }

  Future<void> _openTaskForm({TaskItem? task}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => TaskFormScreen(existingTask: task)),
    );
    if (result == true) _load();
  }

  Future<void> _openTaskDetail(TaskItem task) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task)),
    );
    if (changed == true) _load();
  }

  Future<void> _cycleTaskStatus(TaskItem task) async {
    final next = switch (task.status) {
      'TODO' => 'DOING',
      'DOING' => 'DONE',
      _ => 'TODO',
    };

    final payload = {
      'title': task.title,
      'description': task.description,
      'priority': task.priority,
      'status': next,
      'dueDate': task.dueDate.toIso8601String(),
      'categoryId': task.categoryId,
    };

    final index = tasks.indexWhere((e) => e.id == task.id);
    if (index == -1) return;

    final optimistic = TaskItem(
      id: task.id,
      title: task.title,
      description: task.description,
      priority: task.priority,
      status: next,
      category: task.category,
      categoryId: task.categoryId,
      dueDate: task.dueDate,
    );

    setState(() => tasks[index] = optimistic);
    try {
      await ApiService.updateTask(task.id, payload);
      AppRefreshBus.bumpTasks();
    } catch (e) {
      setState(() => tasks[index] = task);
      if (ApiService.isUnauthorized(e)) {
        if (!mounted) return;
        await handleUnauthorized(context);
        return;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể cập nhật trạng thái task.')),
      );
    }
  }


  Color _categoryDotColor(String? hex) {
    final value = (hex ?? '').replaceAll('#', '');
    if (value.length == 6) return Color(int.parse('FF$value', radix: 16));
    return AppColors.primary;
  }

  Future<Map<String, String>?> _showQuickCategoryDialog() async {
    const palette = ['#FF5C54', '#3B82F6', '#22C55E', '#F97316', '#A855F7'];
    final controller = TextEditingController();
    String selected = palette.first;
    return showDialog<Map<String, String>>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Thêm category'),
        content: StatefulBuilder(
          builder: (context, setModalState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(hintText: 'Nhập tên category mới'),
              ),
              const SizedBox(height: 16),
              Text('Màu category', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                children: palette.map((hex) {
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
          FilledButton(onPressed: () => Navigator.pop(context, {'name': controller.text.trim(), 'colorHex': selected}), child: const Text('Lưu')),
        ],
      ),
    );
  }

  Future<void> _addCategoryQuick() async {
    final data = await _showQuickCategoryDialog();
    final name = data?['name']?.trim() ?? '';
    final colorHex = data?['colorHex'];
    if (name.isEmpty) return;
    try {
      final category = await ApiService.createCategory(name, colorHex: colorHex);
      if (!mounted) return;
      setState(() {
        categories = [...categories, category];
        selectedCategory = category.name;
      });
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
    }
  }


  Future<void> _openCategoryManagement() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => CategoryManagementScreen(categories: categories)),
    );
    if (result == true) _load();
  }

  Future<void> _openFilterSheet() async {
    String? tempPriority = _priorityFilter;
    String? tempStatus = _statusFilter;
    String tempSortMode = _sortMode;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: AppColors.softShadow,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 56,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text('Bộ lọc công việc', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 18),
                    Text('Trạng thái', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: ['TODO', 'DOING', 'DONE']
                          .map((item) => _FilterChoice(
                                label: item,
                                selected: tempStatus == item,
                                onTap: () => setModalState(() => tempStatus = tempStatus == item ? null : item),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 18),
                    Text('Độ ưu tiên', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: ['LOW', 'MEDIUM', 'HIGH']
                          .map((item) => _FilterChoice(
                                label: item,
                                selected: tempPriority == item,
                                onTap: () => setModalState(() => tempPriority = tempPriority == item ? null : item),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 18),
                    Text('Sắp xếp', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _FilterChoice(
                          label: 'Deadline tăng dần',
                          selected: tempSortMode == 'deadline_asc',
                          onTap: () => setModalState(() => tempSortMode = 'deadline_asc'),
                        ),
                        _FilterChoice(
                          label: 'Deadline giảm dần',
                          selected: tempSortMode == 'deadline_desc',
                          onTap: () => setModalState(() => tempSortMode = 'deadline_desc'),
                        ),
                        _FilterChoice(
                          label: 'A → Z',
                          selected: tempSortMode == 'alpha_asc',
                          onTap: () => setModalState(() => tempSortMode = 'alpha_asc'),
                        ),
                        _FilterChoice(
                          label: 'Z → A',
                          selected: tempSortMode == 'alpha_desc',
                          onTap: () => setModalState(() => tempSortMode = 'alpha_desc'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _priorityFilter = null;
                                _statusFilter = null;
                                _sortMode = 'deadline_asc';
                              });
                              Navigator.pop(context);
                            },
                            child: const Text('Đặt lại'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              setState(() {
                                _priorityFilter = tempPriority;
                                _statusFilter = tempStatus;
                                _sortMode = tempSortMode;
                              });
                              Navigator.pop(context);
                            },
                            child: const Text('Áp dụng'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleTasks = filteredTasks;
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openTaskForm(),
        child: const Icon(Icons.add_rounded),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 130),
          children: [
            ScreenHeader(
              subtitle: 'Quản lý công việc cá nhân',
              title: 'Danh sách công việc',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const NotificationButton(),
                  const SizedBox(width: 10),
                  _IconCircleButton(icon: Icons.add_rounded, onTap: () => _openCategoryManagement()),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SectionCard(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFFBFA), Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Hôm nay bạn có ${visibleTasks.length} công việc cần theo dõi', style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 6),
                            Text(
                              _highPriorityCount > 0
                                  ? 'Có $_highPriorityCount công việc ưu tiên cao cần chú ý.'
                                  : 'Mọi công việc đang được phân bố khá ổn hôm nay.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: AppColors.buttonShadow,
                        ),
                        child: const Icon(Icons.task_alt_rounded, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(child: _MetricCard(label: 'To-do', value: _todoCount, tone: const Color(0xFFF3F4F7), textColor: const Color(0xFF5A6474))),
                      const SizedBox(width: 12),
                      Expanded(child: _MetricCard(label: 'Doing', value: _doingCount, tone: const Color(0xFFFFF3DF), textColor: AppColors.warning)),
                      const SizedBox(width: 12),
                      Expanded(child: _MetricCard(label: 'Done', value: _doneCount, tone: const Color(0xFFE8F8EF), textColor: AppColors.success)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _SoftInfoTile(icon: Icons.event_rounded, label: 'Hôm nay', value: '$_dueTodayCount task')),
                      const SizedBox(width: 10),
                      Expanded(child: _SoftInfoTile(icon: Icons.flag_rounded, label: 'Ưu tiên cao', value: '$_highPriorityCount task')),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SectionCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) => setState(() => _searchQuery = value.trim()),
                          decoration: const InputDecoration(
                            hintText: 'Tìm task theo tên hoặc mô tả',
                            prefixIcon: Icon(Icons.search_rounded),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: AppColors.softShadow,
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            IconButton(onPressed: _openFilterSheet, icon: const Icon(Icons.tune_rounded)),
                            if (_activeFilterCount > 0)
                              Positioned(
                                top: -2,
                                right: -2,
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  alignment: Alignment.center,
                                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                                  child: Text(
                                    '$_activeFilterCount',
                                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ...categories.map((category) {
                          final selected = selectedCategory == category.name;
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: ChoiceChip(
                              selected: selected,
                              avatar: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: _categoryDotColor(category.colorHex),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              label: Text(
                                '${category.name}${category.taskCount > 0 ? ' · ${category.taskCount}' : ''}',
                                style: TextStyle(
                                  color: selected ? (category.colorHex == null ? AppColors.primaryDark : _categoryDotColor(category.colorHex)) : AppColors.text,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              onSelected: (_) => setState(() => selectedCategory = category.name),
                              backgroundColor: category.colorHex == null ? Colors.white : _categoryDotColor(category.colorHex).withOpacity(0.12),
                              selectedColor: category.colorHex == null ? AppColors.primarySoft : _categoryDotColor(category.colorHex).withOpacity(0.18),
                              side: const BorderSide(color: AppColors.border),
                              showCheckmark: selected,
                              checkmarkColor: AppColors.primaryDark,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            ),
                          );
                        }),
                        FilledButton.tonalIcon(
                          onPressed: _addCategoryQuick,
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Category'),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton.icon(
                          onPressed: _openCategoryManagement,
                          icon: const Icon(Icons.edit_note_rounded),
                          label: const Text('Quản lý'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_activeFilterCount > 0 || _searchQuery.isNotEmpty) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (_searchQuery.isNotEmpty)
                    AppChip(label: 'Tìm: $_searchQuery', background: AppColors.surfaceMuted, textColor: AppColors.text),
                  if (_statusFilter != null)
                    AppChip(label: 'Status: $_statusFilter', background: statusBg(_statusFilter!), textColor: statusText(_statusFilter!)),
                  if (_priorityFilter != null)
                    AppChip(label: 'Priority: $_priorityFilter', background: priorityBg(_priorityFilter!), textColor: priorityText(_priorityFilter!)),
                  if (_sortMode != 'deadline_asc')
                    AppChip(
                      label: _sortMode == 'deadline_desc'
                          ? 'Sort: Deadline giảm'
                          : _sortMode == 'alpha_asc'
                              ? 'Sort: A-Z'
                              : 'Sort: Z-A',
                      background: const Color(0xFFF4EEFF),
                      textColor: AppColors.purple,
                    ),
                ],
              ),
            ],
            const SizedBox(height: 18),
            if (loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (visibleTasks.isEmpty)
              EmptyStateCard(
                icon: Icons.task_alt_rounded,
                title: 'Danh sách đang trống',
                message: 'Hãy tạo thêm task mới hoặc điều chỉnh bộ lọc để xem đúng công việc bạn cần.',
                actionLabel: 'Tạo task',
                onAction: _openTaskForm,
              )
            else ...[
              Row(
                children: [
                  Expanded(child: Text('Công việc nổi bật', style: Theme.of(context).textTheme.titleLarge)),
                  Text('${visibleTasks.length} mục', style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
              const SizedBox(height: 14),
              ...visibleTasks.map(
                (task) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: TaskCard(
                    task: task,
                    categoryColorHex: _categoryColorForTask(task),
                    onTap: () => _openTaskDetail(task),
                    onStatusToggle: () => _cycleTaskStatus(task),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  String? _categoryColorForTask(TaskItem task) {
    for (final category in categories) {
      if (category.id == task.categoryId || category.name.toLowerCase() == task.category.toLowerCase()) {
        return category.colorHex;
      }
    }
    return null;
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value, required this.tone, required this.textColor});

  final String label;
  final int value;
  final Color tone;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: tone,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: textColor, fontSize: 12.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('$value', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: textColor)),
        ],
      ),
    );
  }
}

class _SoftInfoTile extends StatelessWidget {
  const _SoftInfoTile({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: AppColors.primaryDark),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 2),
                Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChoice extends StatelessWidget {
  const _FilterChoice({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? AppColors.primary.withOpacity(0.2) : Colors.transparent),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.primaryDark : AppColors.text,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _IconCircleButton extends StatelessWidget {
  const _IconCircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), boxShadow: AppColors.softShadow),
      child: IconButton(onPressed: onTap, icon: Icon(icon)),
    );
  }
}
