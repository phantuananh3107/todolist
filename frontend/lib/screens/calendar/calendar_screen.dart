import 'package:flutter/material.dart';

import '../../models/task_item.dart';
import '../../services/api_service.dart';
import '../../widgets/task_card.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _currentMonth;
  int _selectedDay = 0;
  List<TaskItem> _tasks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month);
    _selectedDay = now.day;
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    try {
      final fetched = await ApiService.fetchTasks();
      if (!mounted) return;
      setState(() {
        _tasks = fetched;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _tasks = demoTasks;
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không kết nối được backend — đang dùng dữ liệu demo'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  int get _daysInMonth =>
      DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;

  // offset ô trống trước ngày 1 (Mon=0, Tue=1, ..., Sun=6)
  int get _startOffset =>
      DateTime(_currentMonth.year, _currentMonth.month, 1).weekday - 1;

  String get _monthLabel {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[_currentMonth.month - 1]} ${_currentMonth.year}';
  }

  // lọc task đúng ngày đang chọn
  List<TaskItem> get _tasksForSelectedDay {
    return _tasks.where((t) {
      return t.dueDate.year == _currentMonth.year &&
          t.dueDate.month == _currentMonth.month &&
          t.dueDate.day == _selectedDay;
    }).toList();
  }

  bool _dayHasTask(int day) {
    return _tasks.any((t) =>
        t.dueDate.year == _currentMonth.year &&
        t.dueDate.month == _currentMonth.month &&
        t.dueDate.day == day);
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

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isCurrentMonth =
        _currentMonth.year == now.year && _currentMonth.month == now.month;
    final dayTasks = _tasksForSelectedDay;
    final totalCells = _startOffset + _daysInMonth;

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTasks,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              onPressed: _previousMonth,
                              icon: const Icon(Icons.chevron_left_rounded),
                            ),
                            Text(_monthLabel,
                                style:
                                    Theme.of(context).textTheme.titleLarge),
                            IconButton(
                              onPressed: _nextMonth,
                              icon: const Icon(Icons.chevron_right_rounded),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // header thứ trong tuần
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su']
                              .map((d) => SizedBox(
                                    width: 36,
                                    child: Center(
                                      child: Text(
                                        d,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 10),
                        // lưới ngày có offset đầu tuần
                        GridView.builder(
                          itemCount: totalCells,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                          ),
                          itemBuilder: (_, index) {
                            // ô trống trước ngày 1
                            if (index < _startOffset) {
                              return const SizedBox.shrink();
                            }
                            final day = index - _startOffset + 1;
                            final active = day == _selectedDay;
                            final isToday =
                                isCurrentMonth && day == now.day;
                            final hasTask = _dayHasTask(day);
                            return GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedDay = day),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: active
                                      ? Theme.of(context)
                                          .colorScheme
                                          .primary
                                      : isToday
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withOpacity(0.15)
                                          : const Color(0xFFF7F8FC),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                alignment: Alignment.center,
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '$day',
                                      style: TextStyle(
                                        color: active
                                            ? Colors.white
                                            : Colors.black87,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                    if (hasTask)
                                      Container(
                                        margin:
                                            const EdgeInsets.only(top: 2),
                                        width: 5,
                                        height: 5,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: active
                                              ? Colors.white
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .primary,
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
                  const SizedBox(height: 24),
                  Text(
                    'Tasks on $_selectedDay/${_currentMonth.month}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  if (dayTasks.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text(
                          'Không có task nào trong ngày này',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ...dayTasks.map((task) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: TaskCard(task: task),
                        )),
                ],
              ),
            ),
    );
  }
}
