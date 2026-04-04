import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../../task/controller/task_controller.dart';
import '../controller/calendar_controller.dart';
import 'day_tasks_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<dynamic> _getEventsForDay(
    DateTime day,
    TaskController taskController,
  ) {
    return taskController.tasks.where((task) {
      if (task.dueDate == null) return false;
      return _isSameDay(task.dueDate!, day);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final calendarController = context.watch<CalendarController>();
    final taskController = context.watch<TaskController>();

    if (taskController.isLoading) {
      return const Scaffold(
        body: AppLoading(message: 'Đang tải lịch công việc...'),
      );
    }

    if (taskController.tasks.isEmpty) {
      return const Scaffold(
        body: AppEmptyState(
          icon: Icons.calendar_month_outlined,
          title: 'Chưa có công việc để hiển thị trên lịch',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2035, 12, 31),
              focusedDay: calendarController.focusedDay,
              selectedDayPredicate: (day) =>
                  isSameDay(day, calendarController.selectedDay),
              calendarFormat: calendarController.calendarFormat,
              onFormatChanged: calendarController.updateCalendarFormat,
              eventLoader: (day) => _getEventsForDay(day, taskController),
              onDaySelected: (selectedDay, focusedDay) {
                calendarController.updateSelectedDay(selectedDay, focusedDay);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DayTasksScreen(selectedDay: selectedDay),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}