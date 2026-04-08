import 'package:flutter/material.dart';

import '../../models/category_item.dart';
import '../../models/task_item.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_refresh_bus.dart';
import '../../utils/auth_navigation.dart';
import '../../widgets/empty_state_card.dart';
import '../../widgets/notification_button.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/section_card.dart';
import '../../widgets/task_card.dart';
import '../tasks/task_detail_screen.dart';
import '../tasks/task_form_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _currentMonth;
  int _selectedDay = 0;
  List<TaskItem> _tasks = [];
  List<CategoryItem> _categories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month);
    _selectedDay = now.day;
    AppRefreshBus.tasks.addListener(_loadTasks);
    _loadTasks();
  }

  @override
  void dispose() {
    AppRefreshBus.tasks.removeListener(_loadTasks);
    super.dispose();
  }

  Future<void> _loadTasks() async {
    try {
      final fetched = await ApiService.fetchTasks();
      final cats = await ApiService.fetchCategories().catchError((_) => <CategoryItem>[]);
      if (!mounted) return;
      setState(() {
        _tasks = fetched;
        _categories = cats;
        _loading = false;
      });
    } catch (e) {
      if (ApiService.isUnauthorized(e)) {
        if (!mounted) return;
        setState(() => _loading = false);
        await handleUnauthorized(context);
        return;
      }
      if (!mounted) return;
      setState(() {
        _tasks = demoTasks;
        _categories = [];
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tải được dữ liệu mới')), 
      );
    }
  }

  int get _daysInMonth => DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
  int get _startOffset => DateTime(_currentMonth.year, _currentMonth.month, 1).weekday - 1;

  String get _monthLabel {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[_currentMonth.month - 1]} ${_currentMonth.year}';
  }

  DateTime get _selectedDate => DateTime(_currentMonth.year, _currentMonth.month, _selectedDay, 9, 0);

  List<TaskItem> get _tasksForSelectedDay {
    return _tasks.where((t) {
      return t.dueDate.year == _currentMonth.year && t.dueDate.month == _currentMonth.month && t.dueDate.day == _selectedDay;
    }).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }

  bool _dayHasTask(int day) {
    return _tasks.any((t) => t.dueDate.year == _currentMonth.year && t.dueDate.month == _currentMonth.month && t.dueDate.day == day);
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
      _selectedDay = 1;
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
      _selectedDay = 1;
    });
  }

  void _jumpToToday() {
    final now = DateTime.now();
    setState(() {
      _currentMonth = DateTime(now.year, now.month);
      _selectedDay = now.day;
    });
  }

  List<TaskItem> get _upcomingWeekTasks {
    final start = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final end = start.add(const Duration(days: 7));
    final items = _tasks.where((task) {
      final due = task.dueDate;
      return !due.isBefore(start) && due.isBefore(end);
    }).toList()..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return items.take(5).toList();
  }

  String? _categoryColorForTask(TaskItem task) {
    for (final category in _categories) {
      if (category.id == task.categoryId || category.name.toLowerCase() == task.category.toLowerCase()) {
        return category.colorHex;
      }
    }
    return null;
  }

  String _dateLabel(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')} · ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _addTaskForSelectedDay() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => TaskFormScreen(initialDate: _selectedDate)),
    );
    if (result == true) {
      AppRefreshBus.bumpTasks();
      _loadTasks();
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isCurrentMonth = _currentMonth.year == now.year && _currentMonth.month == now.month;
    final dayTasks = _tasksForSelectedDay;
    final totalCells = _startOffset + _daysInMonth;
    final doneCount = dayTasks.where((e) => e.status == 'DONE').length;
    final highPriority = dayTasks.where((e) => e.priority == 'HIGH').length;
    final todoCount = dayTasks.where((e) => e.status == 'TODO').length;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addTaskForSelectedDay,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Thêm task'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTasks,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
                children: [
                  ScreenHeader(
                    eyebrow: 'Planner',
                    subtitle: 'Lịch công việc',
                    title: 'Calendar',
                    icon: Icons.calendar_month_rounded,
                    trailing: const NotificationButton(),
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
                                  Text(_monthLabel, style: Theme.of(context).textTheme.titleLarge),
                                  const SizedBox(height: 6),
                                  Text('Theo dõi lịch deadline và chủ động tạo task theo từng ngày.', style: Theme.of(context).textTheme.bodyMedium),
                                ],
                              ),
                            ),
                            FilledButton.tonalIcon(
                              onPressed: _addTaskForSelectedDay,
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Thêm task'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _SummaryPill(label: 'Trong ngày', value: '${dayTasks.length}', tone: AppColors.primarySoft, textColor: AppColors.primaryDark)),
                            const SizedBox(width: 10),
                            Expanded(child: _SummaryPill(label: 'To-do', value: '$todoCount', tone: const Color(0xFFF3F4F7), textColor: const Color(0xFF5A6474))),
                            const SizedBox(width: 10),
                            Expanded(child: _SummaryPill(label: 'Đã xong', value: '$doneCount', tone: const Color(0xFFE8F8EF), textColor: AppColors.success)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(child: _SummaryPill(label: 'Ưu tiên cao', value: '$highPriority', tone: const Color(0xFFFFF3DF), textColor: AppColors.warning)),
                            const SizedBox(width: 10),
                            Expanded(child: _SummaryPill(label: 'Ngày chọn', value: '$_selectedDay/${_currentMonth.month}', tone: AppColors.surfaceMuted, textColor: AppColors.text)),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            FilledButton.tonalIcon(
                              onPressed: _jumpToToday,
                              icon: const Icon(Icons.today_rounded),
                              label: const Text('Hôm nay'),
                            ),
                            const SizedBox(width: 10),
                            _MonthArrow(icon: Icons.chevron_left_rounded, onTap: _previousMonth),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Center(child: Text(_monthLabel, style: Theme.of(context).textTheme.titleMedium)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            _MonthArrow(icon: Icons.chevron_right_rounded, onTap: _nextMonth),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su']
                              .map((d) => SizedBox(
                                    width: 36,
                                    child: Center(
                                      child: Text(d, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
                                    ),
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 10),
                        GridView.builder(
                          itemCount: totalCells,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                          ),
                          itemBuilder: (_, index) {
                            if (index < _startOffset) return const SizedBox.shrink();
                            final day = index - _startOffset + 1;
                            final active = day == _selectedDay;
                            final isToday = isCurrentMonth && day == now.day;
                            final hasTask = _dayHasTask(day);
                            return GestureDetector(
                              onTap: () => setState(() => _selectedDay = day),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                decoration: BoxDecoration(
                                  color: active
                                      ? Theme.of(context).colorScheme.primary
                                      : isToday
                                          ? Theme.of(context).colorScheme.primary.withOpacity(0.12)
                                          : AppColors.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: active
                                        ? Theme.of(context).colorScheme.primary
                                        : isToday
                                            ? Theme.of(context).colorScheme.primary.withOpacity(0.28)
                                            : AppColors.border,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '$day',
                                      style: TextStyle(
                                        color: active ? Colors.white : AppColors.text,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                      ),
                                    ),
                                    if (hasTask)
                                      Container(
                                        margin: const EdgeInsets.only(top: 4),
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: active ? Colors.white : Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text('Agenda 7 ngày tới', style: Theme.of(context).textTheme.titleLarge)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(999)),
                              child: Text(
                                '${_upcomingWeekTasks.length} mục',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Nhìn nhanh các deadline tiếp theo để chủ động sắp xếp tuần làm việc.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 12),
                        if (_upcomingWeekTasks.isEmpty)
                          EmptyStateCard(
                            icon: Icons.event_busy_rounded,
                            title: '7 ngày tới khá trống',
                            message: 'Bạn chưa có deadline gần trong tuần này. Có thể thêm task mới từ lịch để lên kế hoạch trước.',
                            actionLabel: 'Tạo task',
                            onAction: _addTaskForSelectedDay,
                          )
                        else
                          ..._upcomingWeekTasks.map((task) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceMuted,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 42,
                                        height: 42,
                                        decoration: BoxDecoration(
                                          color: task.priority == 'HIGH' ? const Color(0xFFFFE5E1) : task.priority == 'LOW' ? const Color(0xFFEAF3FF) : const Color(0xFFFFF3DF),
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: Icon(
                                          task.priority == 'HIGH' ? Icons.priority_high_rounded : task.priority == 'LOW' ? Icons.south_rounded : Icons.drag_handle_rounded,
                                          color: task.priority == 'HIGH' ? AppColors.danger : task.priority == 'LOW' ? AppColors.info : AppColors.warning,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(task.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium),
                                            const SizedBox(height: 4),
                                            Text(_dateLabel(task.dueDate), style: Theme.of(context).textTheme.bodyMedium),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        task.category,
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.text, fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                                ),
                              )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: Text('Công việc ngày $_selectedDay/${_currentMonth.month}', style: Theme.of(context).textTheme.titleLarge)),
                      TextButton.icon(onPressed: _addTaskForSelectedDay, icon: const Icon(Icons.add_rounded), label: const Text('Thêm task')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (dayTasks.isEmpty)
                    EmptyStateCard(
                      icon: Icons.event_available_rounded,
                      title: 'Không có công việc trong ngày này',
                      message: 'Hãy chọn ngày khác hoặc tạo task mới có deadline trong lịch.',
                      actionLabel: 'Tạo task trong ngày',
                      onAction: _addTaskForSelectedDay,
                    )
                  else
                    ...dayTasks.map(
                      (task) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: TaskCard(
                          task: task,
                          categoryColorHex: _categoryColorForTask(task),
                          onTap: () async {
                            final changed = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task)),
                            );
                            if (changed == true) _loadTasks();
                          },
                          onStatusToggle: null,
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({required this.label, required this.value, required this.tone, required this.textColor});

  final String label;
  final String value;
  final Color tone;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(color: tone, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: textColor)),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: textColor.withOpacity(0.9))),
        ],
      ),
    );
  }
}

class _MonthArrow extends StatelessWidget {
  const _MonthArrow({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: IconButton(onPressed: onTap, icon: Icon(icon)),
    );
  }
}
