import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../calendar/calendar_screen.dart';
import '../chart/chart_screen.dart';
import '../profile/profile_screen.dart';
import '../tasks/task_form_screen.dart';
import '../tasks/tasks_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;
  // dùng key để ép TasksScreen reload khi tạo task mới từ FAB
  int _refreshKey = 0;

  List<Widget> get pages => [
    TasksScreen(key: ValueKey(_refreshKey)),
    const CalendarScreen(),
    const ChartScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.checklist_rounded), label: 'Tasks'),
          NavigationDestination(icon: Icon(Icons.calendar_month_rounded), label: 'Calendar'),
          NavigationDestination(icon: Icon(Icons.bar_chart_rounded), label: 'Chart'),
          NavigationDestination(icon: Icon(Icons.person_outline_rounded), label: 'Profile'),
        ],
      ),
      // chỉ hiện nút + ở tab Tasks
      floatingActionButton: index == 0
          ? FloatingActionButton(
              backgroundColor: AppColors.primary,
              onPressed: () async {
                final created = await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TaskFormScreen()),
                );
                // tạo task xong thì reload lại danh sách
                if (created == true) {
                  setState(() => _refreshKey++);
                }
              },
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}
