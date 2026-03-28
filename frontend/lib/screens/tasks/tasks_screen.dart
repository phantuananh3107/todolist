import 'package:flutter/material.dart';

import '../../models/category_item.dart';
import '../../models/task_item.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/task_card.dart';
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

  // search
  final _searchController = TextEditingController();
  String _searchQuery = '';

  // filter
  String? _priorityFilter; // null = tất cả
  String? _statusFilter;
  bool _sortDateAsc = true; // true = ngày gần nhất lên trước

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final fetchedTasks = await ApiService.fetchTasks();
      var fetchedCategories = await ApiService.fetchCategories();
      if (!mounted) return;

      fetchedCategories = List.of(fetchedCategories);

      // nếu API chưa trả "All" thì thêm vào đầu
      if (fetchedCategories.isEmpty || fetchedCategories[0].name != 'All') {
        fetchedCategories.insert(
          0,
          CategoryItem(id: 0, name: 'All', taskCount: fetchedTasks.length),
        );
      }

      setState(() {
        tasks = fetchedTasks;
        categories = fetchedCategories;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      // backend lỗi → load demo data và báo cho user biết
      setState(() {
        tasks = demoTasks;
        categories = [
          CategoryItem(id: 0, name: 'All', taskCount: demoTasks.length),
          ...demoCategories.where((c) => c.name != 'All'),
        ];
        loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không kết nối được backend — đang dùng dữ liệu demo'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  List<TaskItem> get filteredTasks {
    var result = List<TaskItem>.from(tasks);

    // lọc theo category
    if (selectedCategory != 'All') {
      result = result
          .where((e) =>
              e.category.toLowerCase() == selectedCategory.toLowerCase())
          .toList();
    }

    // lọc theo ô search
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result
          .where((e) =>
              e.title.toLowerCase().contains(q) ||
              e.description.toLowerCase().contains(q))
          .toList();
    }

    // lọc theo priority
    if (_priorityFilter != null) {
      result = result.where((e) => e.priority == _priorityFilter).toList();
    }

    // lọc theo status
    if (_statusFilter != null) {
      result = result.where((e) => e.status == _statusFilter).toList();
    }

    // sắp xếp theo ngày
    result.sort((a, b) => _sortDateAsc
        ? a.dueDate.compareTo(b.dueDate)
        : b.dueDate.compareTo(a.dueDate));

    return result;
  }

  // mở form edit rồi reload khi quay về
  Future<void> _openTaskForm({TaskItem? task}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TaskFormScreen(existingTask: task)),
    );
    if (result == true) _load();
  }

  // cycle qua các giá trị filter
  void _cyclePriority() {
    setState(() {
      if (_priorityFilter == null) {
        _priorityFilter = 'HIGH';
      } else if (_priorityFilter == 'HIGH') {
        _priorityFilter = 'MEDIUM';
      } else if (_priorityFilter == 'MEDIUM') {
        _priorityFilter = 'LOW';
      } else {
        _priorityFilter = null;
      }
    });
  }

  void _cycleStatus() {
    setState(() {
      if (_statusFilter == null) {
        _statusFilter = 'TODO';
      } else if (_statusFilter == 'TODO') {
        _statusFilter = 'DOING';
      } else if (_statusFilter == 'DOING') {
        _statusFilter = 'DONE';
      } else {
        _statusFilter = null;
      }
    });
  }

  void _toggleDateSort() {
    setState(() => _sortDateAsc = !_sortDateAsc);
  }

  @override
  Widget build(BuildContext context) {
    final pending = filteredTasks.where((e) => !e.isCompleted).toList();
    final completed = filteredTasks.where((e) => e.isCompleted).toList();

    return Scaffold(
      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                  children: [
                    Text('Today',
                        style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text('Task Manager',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium),
                        ),
                        const CircleAvatar(
                          radius: 24,
                          backgroundColor: Color(0xFFFAD7C3),
                          child: Icon(Icons.person_outline),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // ô search hoạt động thật
                    TextField(
                      controller: _searchController,
                      onChanged: (val) =>
                          setState(() => _searchQuery = val.trim()),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: 'Search your tasks...',
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                                icon: const Icon(Icons.close),
                              )
                            : const Icon(Icons.tune_rounded),
                      ),
                    ),
                    const SizedBox(height: 18),
                    // thanh chọn category
                    SizedBox(
                      height: 42,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (_, i) {
                          final label = categories[i].name;
                          final selected = selectedCategory == label;
                          return GestureDetector(
                            onTap: () =>
                                setState(() => selectedCategory = label),
                            child: Column(
                              children: [
                                Text(
                                  label,
                                  style: TextStyle(
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: selected
                                        ? AppColors.primary
                                        : AppColors.subText,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: selected ? 22 : 0,
                                  height: 2,
                                  color: AppColors.primary,
                                ),
                              ],
                            ),
                          );
                        },
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: 24),
                        itemCount: categories.length,
                      ),
                    ),
                    const SizedBox(height: 18),
                    // filter pills - bấm vào xoay vòng giá trị
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _FilterPill(
                          label: _sortDateAsc ? 'Date ↑' : 'Date ↓',
                          active: true,
                          onTap: _toggleDateSort,
                        ),
                        _FilterPill(
                          label: _priorityFilter ?? 'Priority',
                          active: _priorityFilter != null,
                          onTap: _cyclePriority,
                        ),
                        _FilterPill(
                          label: _statusFilter ?? 'Status',
                          active: _statusFilter != null,
                          onTap: _cycleStatus,
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    // phần task chưa xong
                    Row(
                      children: [
                        Text('Pending',
                            style: Theme.of(context).textTheme.titleLarge),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFECE8),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${pending.length} Tasks',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    if (pending.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: Text('Không có task nào',
                              style: TextStyle(color: Colors.grey)),
                        ),
                      )
                    else
                      ...pending.map(
                        (task) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: TaskCard(
                            task: task,
                            onTap: () => _openTaskForm(task: task),
                          ),
                        ),
                      ),
                    // phần task đã hoàn thành
                    if (completed.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text('Completed',
                              style: Theme.of(context).textTheme.titleLarge),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${completed.length} Tasks',
                              style: const TextStyle(
                                color: Color(0xFF15803D),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      ...completed.map(
                        (task) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: TaskCard(
                            task: task,
                            onTap: () => _openTaskForm(task: task),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22)),
                        ),
                        onPressed: () => _openTaskForm(),
                        icon: const Icon(Icons.add),
                        label: const Text('Create New Task'),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          // đổi màu khi filter đang bật
          color: active ? const Color(0xFFFFECE8) : const Color(0xFFF8FAFC),
          border: Border.all(
            color: active ? AppColors.primary : AppColors.border,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: active ? AppColors.primary : null,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: active ? AppColors.primary : null,
            ),
          ],
        ),
      ),
    );
  }
}
