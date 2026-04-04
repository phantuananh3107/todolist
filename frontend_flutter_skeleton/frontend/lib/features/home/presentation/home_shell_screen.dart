import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../calendar/presentation/calendar_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../task/presentation/task_list_screen.dart';
import '../controller/bottom_nav_controller.dart';
import 'widgets/main_bottom_nav_bar.dart';

class HomeShellScreen extends StatelessWidget {
  const HomeShellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BottomNavController>();

    final screens = const [
      TaskListScreen(),
      CalendarScreen(),
      ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: controller.currentIndex,
        children: screens,
      ),
      bottomNavigationBar: MainBottomNavBar(
        currentIndex: controller.currentIndex,
        onTap: controller.changeTab,
      ),
    );
  }
}