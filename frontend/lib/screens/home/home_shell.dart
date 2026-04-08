import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/auth_navigation.dart';
import '../calendar/calendar_screen.dart';
import '../chart/chart_screen.dart';
import '../chat/chat_assistant_screen.dart';
import '../profile/profile_screen.dart';
import '../tasks/tasks_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;

  @override
  void initState() {
    super.initState();
    _ensureUserShell();
  }

  Future<void> _ensureUserShell() async {
    final role = ApiService.normalizeRole(await ApiService.getRole());
    if (!mounted || role != 'ADMIN') return;
    await redirectToRoleShell(context, role);
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const TasksScreen(),
      const CalendarScreen(),
      const ChartScreen(),
      const ChatAssistantScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: AppColors.softShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: NavigationBar(
            height: 78,
            selectedIndex: index,
            onDestinationSelected: (value) => setState(() => index = value),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.checklist_rounded), label: 'Tasks'),
              NavigationDestination(icon: Icon(Icons.calendar_month_rounded), label: 'Calendar'),
              NavigationDestination(icon: Icon(Icons.bar_chart_rounded), label: 'Chart'),
              NavigationDestination(icon: Icon(Icons.auto_awesome_rounded), label: 'AI Assistant'),
              NavigationDestination(icon: Icon(Icons.person_rounded), label: 'Profile'),
            ],
          ),
        ),
      ),
    );
  }
}
